#!/bin/bash

# Dependencies Library - Handles system dependencies and gum installation

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
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "win"* ]] || [[ "$OS" == "Windows_NT" ]]; then
        echo "⚠️🌌🔒 Halt, interloper of the Windows realm! The sacred protocols of this quantum nexus reject your terrestrial operating system. Only beings aligned with the Linux ethereal plane may traverse these digital hallways. Your Windows vessel lacks the quantum resonance required to initiate this sacred process."
        exit 1
    elif command -v apt-get &>/dev/null; then
        # Debian/Ubuntu
        echo "🐧 Installing gum via apt..."
        # Add the Charm repository for gum
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
        sudo apt update
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

# Ensure essential dependencies are installed
ensure_dependencies() {
    local dependencies=("curl:curl" "git:git" "snap:snapd")
    
    for dep in "${dependencies[@]}"; do
        local command="${dep%%:*}"
        local package="${dep##*:}"
        install_if_missing "$command" "$package"
    done

    # Install gum if not available
    if ! is_installed gum; then
        ui_warning "gum not found. Installing..."
        install_gum
    fi
}