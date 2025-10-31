#!/bin/bash

# Development Environment Component - Node.js, Python, etc.

# Install development environments
install_dev_env() {
    print_section_title "💻 Installing Development Environments"
    update_component_progress "Development Environments" "starting"

    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would install development environments: $DEV_ENV_SELECTED"
        update_component_progress "Development Environments" "skipped"
        return 0
    fi

    ui_info "💻 Installing development environments..."

    for env in $DEV_ENV_SELECTED; do
        install_dev_environment "$env"
    done

    update_component_progress "Development Environments" "completed"
    print_success_box "Development environments installed successfully"
}

# Install individual development environment
install_dev_environment() {
    local env="$1"
    
    case "$env" in
    "Node.js")
        install_nodejs
        ;;
    "Python")
        install_python
        ;;
    esac
}

# Install Node.js
install_nodejs() {
    if is_installed node; then
        ui_warning "Node.js already installed. Skipping."
        return 0
    fi

    ui_info "📦 Installing Node.js ($NODE_VERSION)..."
    
    if [ "$NODE_VERSION" = "LTS" ]; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    else
        curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
    fi
    
    sudo apt install -y nodejs
    
    ui_info "📦 Updating npm to latest version..."
    sudo npm install -g npm@latest
    
    ui_success "Node.js ($NODE_VERSION) installed successfully"
}

# Install Python
install_python() {
    if is_installed python3; then
        ui_warning "Python already installed. Skipping."
    else
        ui_info "🐍 Installing Python 3 and pip..."
        sudo apt install -y python3 python3-pip python3-venv
        ui_success "Python installed successfully"
    fi

    if [ "$PYTHON_VENV" = true ]; then
        setup_python_venv
    fi
}

# Setup Python virtual environment
setup_python_venv() {
    ui_info "🐍 Setting up Python virtual environment..."
    
    if [ ! -d "$HOME/.venv" ]; then
        python3 -m venv "$HOME/.venv"
        
        # Add alias to shell configs
        local alias_line='alias activate="source $HOME/.venv/bin/activate"'
        
        if [ -f "$HOME/.bashrc" ]; then
            echo "$alias_line" >> "$HOME/.bashrc"
        fi
        
        if [ -f "$HOME/.zshrc" ]; then
            echo "$alias_line" >> "$HOME/.zshrc"
        fi
        
        ui_success "Python virtual environment created at $HOME/.venv"
        ui_info "Use 'activate' command to activate the virtual environment"
    else
        ui_warning "Python virtual environment already exists at $HOME/.venv"
    fi
}