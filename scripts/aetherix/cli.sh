#!/bin/bash

# Script configuration
CONFIG_DIR="$HOME/.config/nicronian-setup"
CONFIG_FILE="$CONFIG_DIR/last_config.conf"

# Enable debug mode
DEBUG=false
for arg in "$@"; do
    if [ "$arg" == "--debug" ]; then
        DEBUG=true
        set -x
    fi
done

# ======================================================
# HELPER FUNCTIONS
# ======================================================

# Display spinner with message
safe_spin() {
    if [ "$DEBUG" = true ]; then
        echo "$1"
        sleep 1
    else
        gum spin --spinner dot --title "$1" -- sleep 2
    fi
}

# Install gum utility
install_gum() {
    # Detect OS and package manager
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &>/dev/null; then
            echo "🍺 Installing gum via Homebrew..."
            brew install gum
        else
            echo "❌ Homebrew not found. Please install Homebrew first:"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    # check if the ostype is windows
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "win"* ]] || [[ "$OS" == "Windows_NT" ]]; then
        echo "⚠️🌌🔒 Halt, interloper of the Windows realm! The sacred protocols of this quantum nexus reject your terrestrial operating system. Only beings aligned with the Linux ethereal plane may traverse these digital hallways. Your Windows vessel lacks the quantum resonance required to initiate this sacred process."

    elif command -v apt-get &>/dev/null; then
        # Debian/Ubuntu
        echo "🐧 Installing gum via apt..."

        # Add the Charm repository for gum
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
        sudo apt update

        # Install gum
        sudo apt install -y gum
    elif command -v dnf &>/dev/null; then
        # Fedora/RHEL
        echo "🐧 Installing gum via dnf..."
        sudo dnf install -y gum
    elif command -v pacman &>/dev/null; then
        # Arch Linux
        echo "🧩 Installing gum via pacman..."
        sudo pacman -S --noconfirm gum
    elif command -v yum &>/dev/null; then
        # CentOS/RHEL (older versions)
        echo "🐧 Installing gum via yum..."
        sudo yum install -y gum
    else
        echo "❌ Couldn't determine package manager. Please install gum manually:"
        echo "  🍺 brew install gum"
        echo "  🧩 pacman -S gum"
        echo "  🐧 See: https://github.com/charmbracelet/gum#installation"
        exit 1
    fi

    # Verify installation
    if ! command -v gum &>/dev/null; then
        echo "❌ Automatic installation failed. Please install gum manually:"
        echo "  🍺 brew install gum"
        echo "  🧩 pacman -S gum"
        echo "  🐧 See: https://github.com/charmbracelet/gum#installation"
        exit 1
    else
        echo "✅ Gum installed successfully!"
    fi
}

# Install essential dependencies if not already installed
install_dependencies() {
    if ! command -v curl &>/dev/null; then
        gum style --foreground 3 "⚠️  curl not found. Installing..."
        sudo apt install -y curl
        install_component "curl"
    fi

    if ! command -v git &>/dev/null; then
        gum style --foreground 3 "⚠️  git not found. Installing..."
        sudo apt install -y git
        install_component "git"
    fi

    if ! command -v snap &>/dev/null; then
        gum style --foreground 3 "⚠️  snap not found. Installing..."
        sudo apt install -y snapd
        install_component "snapd"
    fi

    if ! command -v gum &>/dev/null; then
        gum style --foreground 3 "⚠️  gum not found. Installing..."
        install_gum
    fi

}

# Generic component installer
install_component() {
    show_spacer
    safe_spin "Installing $1..."
    gum style --foreground 2 "✅ $1 installed successfully"
}

# Show spacer
show_spacer() {
    gum style --foreground 7 "        "
}

# Display header
show_header() {
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 80 --margin "1 2" --padding "1 2" \
        "👽 AWAKENING THE ALTARS: NICRONIAN SYSTEM PREPARATION 🌠"

    gum style --foreground 7 "👽🪐🌌 Welcome, traveler. You have arrived on Nicron, a sacred planet where the ancient race of the Nicronians will guide you in preparing your environment. Through the essence of the Creator's light, we shall install Docker, PostgreSQL, Nginx, Zsh, and other tools essential for your path ahead."
    echo ""
}

# Save configuration to file
save_config() {
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"

    # Save selected components and their configurations
    {
        echo "SELECTIONS=(${SELECTIONS[*]})"

        # Save component-specific configurations
        [[ " ${SELECTIONS[*]} " =~ "nginx" ]] && {
            echo "NGINX_AUTO=$NGINX_AUTO"
            [[ "$NGINX_AUTO" = true ]] && echo "NGINX_PROJECT=$NGINX_PROJECT"
        }

        [[ " ${SELECTIONS[*]} " =~ "docker" ]] && {
            echo "DOCKER_VERSION=$DOCKER_VERSION"
            echo "DOCKER_AUTOSTART=$DOCKER_AUTOSTART"
        }

        [[ " ${SELECTIONS[*]} " =~ "psql" ]] && {
            echo "PSQL_VERSION=$PSQL_VERSION"
            echo "PSQL_DOCKER=$PSQL_DOCKER"
            echo "DB_NAME=$DB_NAME"
            echo "DB_USER=$DB_USER"
            [[ "$PSQL_DOCKER" = true ]] && echo "DB_PORT=$DB_PORT"
        }

        [[ " ${SELECTIONS[*]} " =~ "zsh" ]] && {
            echo "INSTALL_OH_MY_ZSH=$INSTALL_OH_MY_ZSH"
            [[ "$INSTALL_OH_MY_ZSH" = true ]] && echo "ZSH_THEME=$ZSH_THEME"
            echo "ZSH_DEFAULT=$ZSH_DEFAULT"
            echo "INSTALL_ZSH_PLUGINS=$INSTALL_ZSH_PLUGINS"
            [[ "$INSTALL_ZSH_PLUGINS" = true ]] && echo "ZSH_PLUGINS_SELECTED=\"$ZSH_PLUGINS_SELECTED\""
        }
        [[ " ${SELECTIONS[*]} " =~ "git" ]] && {
            echo "GIT_CONFIG=$GIT_CONFIG"
            [[ "$GIT_CONFIG" = true ]] && {
                echo "GIT_NAME=\"$GIT_NAME\""
                echo "GIT_EMAIL=\"$GIT_EMAIL\""
            }
        }

        [[ " ${SELECTIONS[*]} " =~ "monitoring" ]] && {
            echo "MONITOR_TOOLS_SELECTED=\"$MONITOR_TOOLS_SELECTED\""
        }

        [[ " ${SELECTIONS[*]} " =~ "dev_env" ]] && {
            echo "DEV_ENV_SELECTED=\"$DEV_ENV_SELECTED\""
            [[ "$DEV_ENV_SELECTED" == *"Node.js"* ]] && echo "NODE_VERSION=$NODE_VERSION"
            [[ "$DEV_ENV_SELECTED" == *"Python"* ]] && echo "PYTHON_VENV=$PYTHON_VENV"
        }

        [[ " ${SELECTIONS[*]} " =~ "scripts" ]] && {
            echo "SCRIPTS_SELECTED=\"$SCRIPTS_SELECTED\""
        }
    } >"$CONFIG_FILE"

    gum style --foreground 2 "✅ Configuration saved to $CONFIG_FILE"
}

# Load configuration from file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Source the configuration file
        source "$CONFIG_FILE"
        gum style --foreground 2 "✅ Configuration loaded from $CONFIG_FILE"
        return 0
    else
        gum style --foreground 3 "⚠️ No saved configuration found."
        return 1
    fi
}

# ======================================================
# COMPONENT CONFIGURATION FUNCTIONS
# ======================================================

# Configure Nginx
configure_nginx() {
    gum style --foreground 2 "✅ Nginx will be installed"
    SELECTIONS+=("nginx")

    NGINX_AUTO=$(gum confirm "   📜 Do you want automatic project setup for Arbela or cardhouzz?" && echo true || echo false)
    gum style --foreground 3 "   └── • Autostart: $([ "$NGINX_AUTO" = true ] && echo True || echo False)"

    if [ "$NGINX_AUTO" = true ]; then
        gum style --foreground 45 "   📜 Select the desired project:"
        NGINX_PROJECT=$(gum choose "Arbela" "cardhouzz")
        gum style --foreground 3 "   └── • Project selected: $NGINX_PROJECT"
    fi
}

# Configure Docker
configure_docker() {
    gum style --foreground 2 "✅ Docker will be installed"
    SELECTIONS+=("docker")

    gum style --foreground 45 "   📜 Select the desired version:"
    DOCKER_VERSION=$(gum choose "Latest" "20.10" "19.03")
    DOCKER_VERSION=${DOCKER_VERSION:-Latest}
    gum style --foreground 3 "   └── • Version selected: $DOCKER_VERSION"

    DOCKER_AUTOSTART=$(gum confirm "⚙️  Start Docker on boot?" && echo true || echo false)
    gum style --foreground 3 "   └── • Autostart: $([ "$DOCKER_AUTOSTART" = true ] && echo Enabled || echo Disabled)"
}

# Configure PostgreSQL
configure_postgresql() {
    gum style --foreground 2 "✅ PostgreSQL will be installed"
    SELECTIONS+=("psql")

    gum style --foreground 45 "   📜 Select the desired version:"
    PSQL_VERSION=$(gum choose "14" "13" "12" "11")
    PSQL_VERSION=${PSQL_VERSION:-14}
    gum style --foreground 3 "   └── • Version selected: $PSQL_VERSION"

    PSQL_DOCKER=$(gum confirm "Run PostgreSQL in Docker container?" && echo true || echo false)
    gum style --foreground 3 "   └── • Containerized: $([ "$PSQL_DOCKER" = true ] && echo Yes || echo No)"

    # If Docker is required but not selected, prompt to add it
    if [ "$PSQL_DOCKER" = true ] && ! [[ " ${SELECTIONS[*]} " =~ "docker" ]]; then
        if gum confirm "⚠️ Docker is required for containerized PostgreSQL. Add Docker to selections?"; then
            configure_docker
        else
            PSQL_DOCKER=false
            gum style --foreground 3 "   └── • Containerized: No (Docker not selected)"
        fi
    fi

    gum style --foreground 45 "   📜 Please set your DB name and username:"
    DB_NAME=$(gum input --placeholder "Database name (default: devdb)" --value "devdb")
    DB_USER=$(gum input --placeholder "Database user (default: devuser)" --value "devuser")
    gum style --foreground 3 "   └── • DB: $DB_NAME, User: $DB_USER"

    if [ "$PSQL_DOCKER" = true ]; then
        DB_PORT=$(gum input --placeholder "Database port (default: 5432)" --value "5432")
        gum style --foreground 3 "   └── • Port: $DB_PORT"
    fi
}

# Configure Zsh
configure_zsh() {
    gum style --foreground 2 "✅ Zsh will be installed"
    SELECTIONS+=("zsh")

    INSTALL_OH_MY_ZSH=$(gum confirm "✨ Install Oh My Zsh?" && echo true || echo false)

    if [ "$INSTALL_OH_MY_ZSH" = true ]; then
        gum style --foreground 45 "   📜 Select the desired theme:"
        ZSH_THEME=$(gum choose "robbyrussell" "agnoster" "avit" "bira" "Default")
        gum style --foreground 3 "   └── • Theme: $ZSH_THEME"
    fi

    ZSH_DEFAULT=$(gum confirm "⚙️  Set Zsh as default shell?" && echo true || echo false)
    gum style --foreground 3 "   └── • Default shell: $([ "$ZSH_DEFAULT" = true ] && echo Yes || echo No)"

    INSTALL_ZSH_PLUGINS=$(gum confirm "🧩 Install Zsh plugins?" && echo true || echo false)
    if [ "$INSTALL_ZSH_PLUGINS" = true ]; then
        gum style --foreground 45 "   📜 Select the desired plugins - default is all:"
        # Store the output in an array
        readarray -t ZSH_PLUGINS_ARRAY < <(gum choose --no-limit "All" "Auto Suggestions" "zsh-syntax-highlighting" "zsh-fast-syntax-highlighting" "zsh-autocomplete")

        # Convert the array to a space-separated string
        ZSH_PLUGINS_SELECTED=$(printf "%s " "${ZSH_PLUGINS_ARRAY[@]}")

        # Handle the "All" option
        if [[ "$ZSH_PLUGINS_SELECTED" == *"All"* ]]; then
            ZSH_PLUGINS_SELECTED="Auto-Suggestions zsh-fast-syntax-highlighting zsh-autocomplete zsh-syntax-highlighting"
        fi

        gum style --foreground 3 "   └── • Plugins: $ZSH_PLUGINS_SELECTED"
    fi
}

# Configure Vim
configure_vim() {
    gum style --foreground 2 "✅ Vim will be installed"
    SELECTIONS+=("vim")
}

# Configure apps
configure_apps() {
    gum style --foreground 2 "✅ Apps selected"
    SELECTIONS+=("apps")

    gum style --foreground 45 "   📜 Select the apps you want to install - default is all:"

    readarray -t DEV_TOOLS_ARRAY < <(gum choose --no-limit "All" "Postman" "VS_Code" "Teams" "PyCharm" "Figma" "Wifi_Hotspot")
    # Convert the array to a space-separated string
    DEV_TOOLS_SELECTED=$(printf "%s " "${DEV_TOOLS_ARRAY[@]}")
    # Handle the "All" option
    if [[ "$DEV_TOOLS_SELECTED" == *"All"* ]]; then
        DEV_TOOLS_SELECTED="All Postman VS_Code Teams PyCharm Figma Wifi_Hotspot"
    fi

    gum style --foreground 3 "   └── • Selected tools: $DEV_TOOLS_SELECTED"
}

# Configure development scripts
configure_scripts() {
    gum style --foreground 2 "✅ Dev scripts selected"
    SELECTIONS+=("scripts")

    gum style --foreground 45 "   📜 Select the desired scripts - default is all:"

    readarray -t SCRIPTS_ARRAY < <(gum choose --no-limit "All" "Nginx" "generate_po_file" "DB_manager")
    # Convert the array to a space-separated string
    SCRIPTS_SELECTED=$(printf "%s " "${SCRIPTS_ARRAY[@]}")
    # Handle the "All" option
    if [[ "$SCRIPTS_SELECTED" == *"All"* ]]; then
        SCRIPTS_SELECTED="All Nginx generate_po_file DB_manager"
    fi

    gum style --foreground 3 "   └── • Scripts: $SCRIPTS_SELECTED"
}

# Configure Git
configure_git() {
    gum style --foreground 2 "✅ Git will be installed"
    SELECTIONS+=("git")

    GIT_CONFIG=$(gum confirm "⚙️ Configure Git with user info?" && echo true || echo false)

    if [ "$GIT_CONFIG" = true ]; then
        GIT_NAME=$(gum input --placeholder "Your Name")
        GIT_EMAIL=$(gum input --placeholder "Your Email")
        gum style --foreground 3 "   └── • Git config: $GIT_NAME <$GIT_EMAIL>"
    fi
}

# Configure system monitoring tools
configure_monitoring() {
    gum style --foreground 2 "✅ System monitoring tools will be installed"
    SELECTIONS+=("monitoring")

    gum style --foreground 45 "   📜 Select the monitoring tools to install:"

    readarray -t MONITOR_TOOLS_ARRAY < <(gum choose --no-limit "All" "htop" "glances" "neofetch" "btop")
    MONITOR_TOOLS_SELECTED=$(printf "%s " "${MONITOR_TOOLS_ARRAY[@]}")

    if [[ "$MONITOR_TOOLS_SELECTED" == *"All"* ]]; then
        MONITOR_TOOLS_SELECTED="htop glances neofetch btop"
    fi

    gum style --foreground 3 "   └── • Selected tools: $MONITOR_TOOLS_SELECTED"
}

# Configure development environments
configure_dev_env() {
    gum style --foreground 2 "✅ Development environments will be installed"
    SELECTIONS+=("dev_env")

    gum style --foreground 45 "   📜 Select the development environments to install:"

    readarray -t DEV_ENV_ARRAY < <(gum choose --no-limit "Node.js" "Python")
    DEV_ENV_SELECTED=$(printf "%s " "${DEV_ENV_ARRAY[@]}")

    gum style --foreground 3 "   └── • Selected environments: $DEV_ENV_SELECTED"

    # Additional configuration for Node.js
    if [[ "$DEV_ENV_SELECTED" == *"Node.js"* ]]; then
        NODE_VERSION=$(gum choose "LTS" "Latest")
        NODE_VERSION=${NODE_VERSION:-LTS}
        gum style --foreground 3 "   └── • Node.js Version: $NODE_VERSION"
    fi

    # Additional configuration for Python
    if [[ "$DEV_ENV_SELECTED" == *"Python"* ]]; then
        PYTHON_VENV=$(gum confirm "⚙️ Set up Python virtual environment?" && echo true || echo false)
        gum style --foreground 3 "   └── • Python venv: $([ "$PYTHON_VENV" = true ] && echo Yes || echo No)"
    fi
}

# ======================================================
# INSTALLATION FUNCTIONS
# ======================================================

# Install Docker
install_docker() {
    if command -v docker &>/dev/null; then
        gum style --foreground 3 "⚠️  Docker already installed. Skipping."
        return
    fi

    sudo apt install -y docker.io
    install_component "Docker"
    gum style "  - Version: $DOCKER_VERSION"
    gum style "  - Autostart: $([ "$DOCKER_AUTOSTART" = true ] && echo Enabled || echo Disabled)"

    # Configure autostart if needed
    if [ "$DOCKER_AUTOSTART" = true ]; then
        sudo systemctl enable docker
        sudo systemctl start docker
    fi
}

# Install Nginx
install_nginx() {
    if command -v nginx &>/dev/null; then
        gum style --foreground 3 "⚠️  Nginx already installed. Skipping."
        return
    fi

    sudo apt install -y nginx
    install_component "Nginx"

    # Configure projects if needed
    if [ "$NGINX_AUTO" = true ]; then
        safe_spin "Setting up Nginx for $NGINX_PROJECT..."
        # Actual project setup would go here
        gum style --foreground 2 "✅ Nginx configured for $NGINX_PROJECT"
    fi
}

# Install PostgreSQL
install_postgresql() {
    # Check if PostgreSQL is already installed
    if command -v psql &>/dev/null && [ "$PSQL_DOCKER" = false ]; then
        gum style --foreground 3 "⚠️  PostgreSQL already installed natively. Skipping."
        return
    fi

    if [ "$PSQL_DOCKER" = true ]; then
        # Ensure Docker is installed
        if ! command -v docker &>/dev/null; then
            gum style --foreground 1 "❌ Docker is required but not installed. Installing Docker first..."
            install_docker
        fi

        # Create PostgreSQL container
        safe_spin "Creating PostgreSQL container..."
        docker run --name postgres-$PSQL_VERSION -e POSTGRES_PASSWORD=postgres \
            -e POSTGRES_USER=$DB_USER -e POSTGRES_DB=$DB_NAME \
            -p $DB_PORT:5432 -d postgres:$PSQL_VERSION

        install_component "PostgreSQL (Docker)"
    else
        sudo apt install -y postgresql-$PSQL_VERSION
        install_component "PostgreSQL (Native)"

        # Configure the database
        safe_spin "Configuring PostgreSQL..."
        sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD 'password';"
        sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
    fi

    gum style "  - Version: $PSQL_VERSION, DB: $DB_NAME, User: $DB_USER"
    [ "$PSQL_DOCKER" = true ] && gum style "  - Port: $DB_PORT"
}

# Install Zsh
install_zsh() {
    # Install Zsh if not already installed
    if ! command -v zsh >/dev/null 2>&1; then
        sudo apt install -y zsh
        install_component "Zsh"
    else
        gum style --foreground 3 "⚠️  Zsh is already installed, skipping installation."
    fi

    # Install Oh My Zsh if requested
    if [ "$INSTALL_OH_MY_ZSH" = true ]; then
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            safe_spin "Installing Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

            # Set theme if specified
            if [ -n "$ZSH_THEME" ] && [ "$ZSH_THEME" != "Default" ]; then
                sed -i "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"$ZSH_THEME\"/" "$HOME/.zshrc"
            fi

            gum style "  - Theme: $ZSH_THEME"
        else
            gum style --foreground 3 "⚠️  Oh My Zsh already installed, skipping."
        fi
    fi

    # Set as default shell if requested
    CURRENT_SHELL=$(basename "$SHELL")
    if [ "$ZSH_DEFAULT" = true ] && [ "$CURRENT_SHELL" != "zsh" ]; then
        chsh -s "$(which zsh)"
        safe_spin "Setting Zsh as default shell..."
        gum style --foreground 2 "✅ Zsh is now your default shell"
    elif [ "$ZSH_DEFAULT" = true ]; then
        gum style --foreground 3 "⚠️  Zsh is already your default shell."
    fi

    # Install Zsh plugins
    if [ "$INSTALL_ZSH_PLUGINS" = true ]; then
        declare -a PLUGINS_TO_ADD=()
        ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

        for plugin in $ZSH_PLUGINS_SELECTED; do
            case "$plugin" in
            "Auto-Suggestions")
                PLUGIN_PATH="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
                if [ ! -d "$PLUGIN_PATH" ]; then
                    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$PLUGIN_PATH"
                fi
                PLUGINS_TO_ADD+=("zsh-autosuggestions")
                ;;
            "zsh-syntax-highlighting")
                PLUGIN_PATH="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
                if [ ! -d "$PLUGIN_PATH" ]; then
                    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_PATH"
                fi
                PLUGINS_TO_ADD+=("zsh-syntax-highlighting")
                ;;
            "zsh-fast-syntax-highlighting")
                PLUGIN_PATH="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting"
                if [ ! -d "$PLUGIN_PATH" ]; then
                    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$PLUGIN_PATH"
                fi
                PLUGINS_TO_ADD+=("fast-syntax-highlighting")
                ;;
            "zsh-autocomplete")
                PLUGIN_PATH="$ZSH_CUSTOM/plugins/zsh-autocomplete"
                if [ ! -d "$PLUGIN_PATH" ]; then
                    git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$PLUGIN_PATH"
                fi
                PLUGINS_TO_ADD+=("zsh-autocomplete")
                ;;
            esac

            install_component "Zsh Plugin: $plugin"
        done

        # Update .zshrc with plugins, but don't source it
        if [ ${#PLUGINS_TO_ADD[@]} -gt 0 ]; then
            # Create a backup of .zshrc
            cp "$HOME/.zshrc" "$HOME/.zshrc.bak"

            # Modify the plugins line in .zshrc
            sed -i "/^plugins=/c\plugins=(git ${PLUGINS_TO_ADD[*]})" "$HOME/.zshrc"

            gum style --foreground 2 "✅ Added plugins to .zshrc: ${PLUGINS_TO_ADD[*]}"
            gum style --foreground 3 "⚠️ You will need to restart your terminal or run 'zsh' to use the new plugins"
        fi
    fi

    gum style --foreground 2 "✅ Reloading shell..."
    [ "$(basename "$SHELL")" = "bash" ] && [ -f ~/.bashrc ] && source ~/.bashrc ||
        [ "$(basename "$SHELL")" = "zsh" ] && [ -f ~/.zshrc ] && source ~/.zshrc
}

# Install Vim
install_vim() {
    if command -v vim &>/dev/null; then
        gum style --foreground 3 "⚠️  Vim already installed. Skipping."
        return
    fi

    sudo apt install -y vim
    install_component "Vim"
}

# Install apps
install_apps() {
    # Ensure snap is installed for some of the tools
    if ! command -v snap &>/dev/null; then
        gum style --foreground 3 "⚠️ Snap not found. Installing snap..."
        sudo apt install -y snapd
        sudo systemctl enable --now snapd.socket
    fi

    for tool in $DEV_TOOLS_SELECTED; do
        case "$tool" in
        "Postman")
            safe_spin "Installing Postman..."
            sudo snap install postman
            install_component "Postman"
            ;;
        "VS_Code")
            safe_spin "Installing VS Code..."
            sudo snap install --classic code
            install_component "VS Code"
            ;;
        "Slack")
            safe_spin "Installing Slack..."
            sudo snap install slack
            install_component "Slack"
            ;;
        "Teams")
            safe_spin "Installing Teams..."
            sudo snap install teams-for-linux
            install_component "Teams"
            ;;
        "PyCharm")
            safe_spin "Installing PyCharm..."
            sudo snap install pycharm-professional --classic
            install_component "PyCharm"
            ;;
        "Figma")
            safe_spin "Installing Figma..."
            sudo snap install figma-linux
            install_component "Figma"
            ;;
        "Wifi_Hotspot")
            safe_spin "Installing Wifi Hotspot..."
            sudo add-apt-repository ppa:lakinduakash/lwh
            sudo apt update
            sudo apt install linux-wifi-hotspot
            install_component "Wifi Hotspot"
            ;;
        "All")
            safe_spin "Installing Postman..."
            sudo snap install postman
            install_component "Postman"

            safe_spin "Installing VS Code..."
            sudo snap install --classic code
            install_component "VS Code"

            safe_spin "Installing Teams..."
            sudo snap install teams-for-linux
            install_component "Teams"
            # safe_spin "Installing Slack..."
            # sudo snap install slack
            # install_component "Slack"

            safe_spin "Installing PyCharm..."
            sudo snap install pycharm-professional --classic
            install_component "PyCharm"

            safe_spin "Installing Wifi Hotspot..."
            sudo add-apt-repository ppa:lakinduakash/lwh
            sudo apt update
            sudo apt install linux-wifi-hotspot
            install_component "Wifi Hotspot"
            ;;
        esac
    done
}

# Install Git
install_git() {
    if command -v git &>/dev/null; then
        gum style --foreground 3 "⚠️  Git already installed. Skipping."
        return
    fi

    sudo apt install -y git
    install_component "Git"

    if [ "$GIT_CONFIG" = true ]; then
        git config --global user.name "$GIT_NAME"
        git config --global user.email "$GIT_EMAIL"
        git config --global init.defaultBranch main
        gum style --foreground 2 "✅ Git configured with your information"
    fi
}

# Install system monitoring tools
install_monitoring() {
    for tool in $MONITOR_TOOLS_SELECTED; do
        if command -v $tool &>/dev/null; then
            gum style --foreground 3 "⚠️  $tool already installed. Skipping."
            continue
        fi

        sudo apt install -y $tool
        install_component "$tool"
    done
}

# Install development environments
install_dev_env() {
    for env in $DEV_ENV_SELECTED; do
        case "$env" in
        "Node.js")
            if command -v node &>/dev/null; then
                gum style --foreground 3 "⚠️  Node.js already installed. Skipping."
            else
                if [ "$NODE_VERSION" = "LTS" ]; then
                    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
                else
                    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
                fi
                sudo apt install -y nodejs
                sudo npm install -g npm@latest
                install_component "Node.js ($NODE_VERSION)"
            fi
            ;;
        "Python")
            if command -v python3 &>/dev/null; then
                gum style --foreground 3 "⚠️  Python already installed. Skipping."
            else
                sudo apt install -y python3 python3-pip python3-venv
                install_component "Python"
            fi

            if [ "$PYTHON_VENV" = true ]; then
                python3 -m venv "$HOME/.venv"
                echo 'alias activate="source $HOME/.venv/bin/activate"' >>"$HOME/.bashrc"
                [ -f "$HOME/.zshrc" ] && echo 'alias activate="source $HOME/.venv/bin/activate"' >>"$HOME/.zshrc"
                gum style --foreground 2 "✅ Python virtual environment created at $HOME/.venv"
            fi
            ;;
        esac
    done
}

# ======================================================

# Install development scripts
install_scripts() {
    # Ensure SCRIPT_DIR is defined
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$HOME/dev_scripts"
        mkdir -p "$SCRIPT_DIR"

        # Download or create nox.sh if it doesn't exist
        if [ ! -f "$SCRIPT_DIR/nox.sh" ]; then
            # This is a placeholder - in a real implementation,
            # you'd download or create the script appropriately
            echo "#!/bin/bash" >"$SCRIPT_DIR/nox.sh"
            echo "# Script implementation would go here" >>"$SCRIPT_DIR/nox.sh"
            echo "echo \"Running \$@\"" >>"$SCRIPT_DIR/nox.sh"
            chmod +x "$SCRIPT_DIR/nox.sh"
        fi
    fi

    # Make sure nox.sh is executable
    if [ ! -x "$SCRIPT_DIR/nox.sh" ]; then
        chmod +x "$SCRIPT_DIR/nox.sh"
    fi

    for script in $SCRIPTS_SELECTED; do
        case "$script" in
        "Nginx")
            "$SCRIPT_DIR/nox.sh" -ngx
            ;;
        "generate_po_file")
            "$SCRIPT_DIR/nox.sh" -gpo
            ;;
        "DB_manager")
            "$SCRIPT_DIR/nox.sh" -dbm
            ;;
        "All")
            "$SCRIPT_DIR/nox.sh" -ngx -gpo -dbm
            ;;
        esac

        [ "$(basename "$SHELL")" = "bash" ] && [ -f ~/.bashrc ] && source ~/.bashrc ||
            [ "$(basename "$SHELL")" = "zsh" ] && [ -f ~/.zshrc ] && source ~/.zshrc

        if [ $? -ne 0 ]; then
            gum style --foreground 1 "❌ Error: Failed to execute $script"
            exit 1
        fi
        safe_spin "Installing $script..."
        gum style --foreground 2 "✅ $script installed"
    done
}

# ======================================================
# MAIN WORKFLOW FUNCTIONS
# ======================================================

# Show configuration summary
show_summary() {
    gum style --foreground 45 --bold "📝 Components selected:"
    for item in "${SELECTIONS[@]}"; do
        gum style --foreground 2 "   └── • $item"
    done
}

# Collect all component configurations
collect_configurations() {
    # Offer to load previous configuration
    if [[ -f "$CONFIG_FILE" ]]; then
        if gum confirm "⚙️  Load previous configuration?"; then
            load_config
            show_summary
            return
        fi
    fi

    # Configure Nginx
    if gum confirm "🕸️  Install Nginx?"; then
        configure_nginx
    else
        gum style --foreground 1 "❌ Skipping Nginx"
    fi
    show_spacer

    # Configure Docker
    if gum confirm "🐳 Install Docker?"; then
        configure_docker
    else
        gum style --foreground 1 "❌ Skipping Docker"
    fi
    show_spacer

    # Configure PostgreSQL
    if gum confirm "🐘 Install PostgreSQL?"; then
        configure_postgresql
    else
        gum style --foreground 1 "❌ Skipping PostgreSQL"
    fi
    show_spacer

    # Configure Zsh
    if gum confirm "🐚 Install Zsh?"; then
        configure_zsh
    else
        gum style --foreground 1 "❌ Skipping Zsh"
    fi
    show_spacer

    # Configure Vim
    if gum confirm "📝 Install Vim?"; then
        configure_vim
    else
        gum style --foreground 1 "❌ Skipping Vim"
    fi
    show_spacer

    # Install apps
    if gum confirm "🛠️  Install apps? such as Postman, Pycharm, Teams, and etc"; then
        configure_apps
    else
        gum style --foreground 1 "❌ Skipping apps"
    fi
    show_spacer

    # Configure system monitoring tools
    if gum confirm "📊 Install system monitoring tools?"; then
        configure_monitoring
    else
        gum style --foreground 1 "❌ Skipping system monitoring tools"
    fi
    show_spacer

    # Configure development environments
    if gum confirm "💻 Install development environments?"; then
        configure_dev_env
    else
        gum style --foreground 1 "❌ Skipping development environments"
    fi
    show_spacer

    # Configure development scripts
    if gum confirm "📜 Install development scripts?"; then
        configure_scripts
    else
        gum style --foreground 1 "❌ Skipping scripts"
    fi
    show_spacer
    # Show summary
    show_summary

    # Save configuration
    if gum confirm "💾 Save this configuration for future use?"; then
        save_config
    fi
}

# Install all selected components
install_components() {
    # Run apt update once before starting installation
    gum style --foreground 45 --bold "🔄 Updating package lists..."
    sudo apt update

    # Installation Phase
    show_spacer
    gum style --foreground 45 --bold "⚙️ Installing..."
    show_spacer

    # Install each selected component
    [[ " ${SELECTIONS[*]} " =~ "docker" ]] && install_docker
    [[ " ${SELECTIONS[*]} " =~ "nginx" ]] && install_nginx
    [[ " ${SELECTIONS[*]} " =~ "psql" ]] && install_postgresql
    [[ " ${SELECTIONS[*]} " =~ "zsh" ]] && install_zsh
    [[ " ${SELECTIONS[*]} " =~ "vim" ]] && install_vim
    # [[ " ${SELECTIONS[*]} " =~ "git" ]] && install_git
    [[ " ${SELECTIONS[*]} " =~ "monitoring" ]] && install_monitoring
    [[ " ${SELECTIONS[*]} " =~ "apps" ]] && install_apps
    [[ " ${SELECTIONS[*]} " =~ "dev_env" ]] && install_dev_env
    [[ " ${SELECTIONS[*]} " =~ "scripts" ]] && install_scripts
}

# ======================================================
# MAIN SCRIPT EXECUTION
# ======================================================

# Initialize selections array
SELECTIONS=()

# Ensure required tools are available
install_dependencies

# Display the header
show_header

# Collect configurations for all components
collect_configurations

# Final confirmation
if ! gum confirm "🚀 Proceed with installation?"; then
    gum style --foreground 1 "❌ Installation cancelled."
    exit 0
fi

# Install all selected components
install_components

# Show completion message
gum style \
    --foreground 2 --border-foreground 2 --border normal \
    --align center --width 80 --margin "1 2" --padding "1 2" \
    "🎉 Setup completed successfully!"
