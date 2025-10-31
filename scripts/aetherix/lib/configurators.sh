#!/bin/bash

# Configurators Library - Component configuration functions

# Configure Vim
configure_vim() {
    add_selection "vim"
}

# Configure apps
configure_apps() {
    add_selection "apps"

    ui_info "📜 Select the apps you want to install - default is all:"

    local app_options=("All" "Postman" "VS_Code" "Teams" "PyCharm" "Figma" "Wifi_Hotspot")
    show_multi_choice "Select applications:" app_options DEV_TOOLS_SELECTED

    gum style --foreground 3 "   └── • Selected tools: $DEV_TOOLS_SELECTED"
}

# Configure development scripts
configure_scripts() {
    add_selection "scripts"

    ui_info "📜 Select the desired scripts - default is all:"

    local script_options=("All" "Nginx" "generate_po_file" "DB_manager")
    show_multi_choice "Select scripts:" script_options SCRIPTS_SELECTED

    gum style --foreground 3 "   └── • Scripts: $SCRIPTS_SELECTED"
}

# Configure Git
configure_git() {
    add_selection "git"

    GIT_CONFIG=$(gum confirm "⚙️ Configure Git with user info?" && echo true || echo false)

    if [ "$GIT_CONFIG" = true ]; then
        # Get name with validation
        while true; do
            GIT_NAME=$(gum input --placeholder "Your Name")
            if [ -n "$GIT_NAME" ]; then
                break
            else
                ui_warning "Name cannot be empty. Please try again."
            fi
        done
        
        # Get email with validation
        while true; do
            GIT_EMAIL=$(gum input --placeholder "Your Email")
            if validate_email "$GIT_EMAIL"; then
                break
            else
                ui_warning "Please enter a valid email address."
            fi
        done
        
        gum style --foreground 3 "   └── • Git config: $GIT_NAME <$GIT_EMAIL>"
    fi
}

# Configure system monitoring tools
configure_monitoring() {
    add_selection "monitoring"

    ui_info "📜 Select the monitoring tools to install:"

    local monitor_options=("All" "htop" "NeoHtop")
    show_multi_choice "Select monitoring tools:" monitor_options MONITOR_TOOLS_SELECTED

    gum style --foreground 3 "   └── • Selected tools: $MONITOR_TOOLS_SELECTED"
}

# Configure development environments
configure_dev_env() {
    add_selection "dev_env"

    ui_info "📜 Select the development environments to install:"

    local dev_env_options=("Node.js" "Python")
    show_multi_choice "Select development environments:" dev_env_options DEV_ENV_SELECTED

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

# Configure Zsh
configure_zsh() {
    add_selection "zsh"

    INSTALL_OH_MY_ZSH=$(gum confirm "✨ Install Oh My Zsh?" && echo true || echo false)

    if [ "$INSTALL_OH_MY_ZSH" = true ]; then
        ui_info "📜 Select the desired theme:"
        ZSH_THEME=$(gum choose "robbyrussell" "agnoster" "avit" "bira" "Default")
        gum style --foreground 3 "   └── • Theme: $ZSH_THEME"
    fi

    ZSH_DEFAULT=$(gum confirm "⚙️ Set Zsh as default shell?" && echo true || echo false)
    gum style --foreground 3 "   └── • Default shell: $([ "$ZSH_DEFAULT" = true ] && echo Yes || echo No)"

    INSTALL_ZSH_PLUGINS=$(gum confirm "🧩 Install Zsh plugins?" && echo true || echo false)
    if [ "$INSTALL_ZSH_PLUGINS" = true ]; then
        ui_info "📜 Select the desired plugins - default is all:"
        local plugin_options=("All" "Auto Suggestions" "zsh-syntax-highlighting" "zsh-fast-syntax-highlighting" "zsh-autocomplete")
        show_multi_choice "Select Zsh plugins:" plugin_options ZSH_PLUGINS_SELECTED
        gum style --foreground 3 "   └── • Plugins: $ZSH_PLUGINS_SELECTED"
    fi
}