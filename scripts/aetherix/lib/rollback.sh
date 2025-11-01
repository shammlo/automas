#!/bin/bash

# Rollback Library - Undo installations and restore system state

# Track installed packages for rollback
INSTALLED_PACKAGES=()
INSTALLED_SERVICES=()
CREATED_USERS=()
CREATED_DIRECTORIES=()

# Add package to rollback tracking
track_package() {
    local package="$1"
    INSTALLED_PACKAGES+=("$package")
    log_message "TRACK" "Added package to rollback list: $package"
}

# Add service to rollback tracking
track_service() {
    local service="$1"
    INSTALLED_SERVICES+=("$service")
    log_message "TRACK" "Added service to rollback list: $service"
}

# Add user to rollback tracking
track_user() {
    local user="$1"
    CREATED_USERS+=("$user")
    log_message "TRACK" "Added user to rollback list: $user"
}

# Add directory to rollback tracking
track_directory() {
    local directory="$1"
    CREATED_DIRECTORIES+=("$directory")
    log_message "TRACK" "Added directory to rollback list: $directory"
}

# Save rollback state
save_rollback_state() {
    local rollback_file="$CONFIG_DIR/rollback_state.conf"
    
    {
        echo "# Rollback state for Nicronian setup"
        echo "# Generated: $(date)"
        echo "INSTALLED_PACKAGES=(${INSTALLED_PACKAGES[*]})"
        echo "INSTALLED_SERVICES=(${INSTALLED_SERVICES[*]})"
        echo "CREATED_USERS=(${CREATED_USERS[*]})"
        echo "CREATED_DIRECTORIES=(${CREATED_DIRECTORIES[*]})"
    } > "$rollback_file"
    
    log_message "INFO" "Rollback state saved to $rollback_file"
}

# Load rollback state
load_rollback_state() {
    local rollback_file="$CONFIG_DIR/rollback_state.conf"
    
    if [[ -f "$rollback_file" ]]; then
        source "$rollback_file"
        ui_success "Rollback state loaded"
        return 0
    else
        ui_warning "No rollback state found"
        return 1
    fi
}

# Rollback Docker installation
rollback_docker() {
    ui_info "🐳 Rolling back Docker installation..."
    
    # Stop and disable service
    sudo systemctl stop docker 2>/dev/null || true
    sudo systemctl disable docker 2>/dev/null || true
    
    # Remove packages
    sudo apt remove --purge -y docker.io docker-ce docker-ce-cli containerd.io 2>/dev/null || true
    
    # Remove user from docker group
    sudo deluser $USER docker 2>/dev/null || true
    
    # Remove docker directories
    sudo rm -rf /var/lib/docker /etc/docker
    
    ui_success "Docker rollback completed"
}

# Rollback Nginx installation
rollback_nginx() {
    ui_info "🕸️ Rolling back Nginx installation..."
    
    # Stop and disable service
    sudo systemctl stop nginx 2>/dev/null || true
    sudo systemctl disable nginx 2>/dev/null || true
    
    # Remove package
    sudo apt remove --purge -y nginx nginx-common 2>/dev/null || true
    
    # Remove configuration directories
    sudo rm -rf /etc/nginx /var/log/nginx /var/www/html
    
    ui_success "Nginx rollback completed"
}

# Rollback PostgreSQL installation
rollback_postgresql() {
    ui_info "🐘 Rolling back PostgreSQL installation..."
    
    if [ "${PSQL_DOCKER:-false}" = true ]; then
        # Remove Docker container
        docker stop "postgres-$PSQL_VERSION" 2>/dev/null || true
        docker rm "postgres-$PSQL_VERSION" 2>/dev/null || true
        docker rmi "postgres:$PSQL_VERSION" 2>/dev/null || true
    else
        # Stop and remove native installation
        sudo systemctl stop postgresql 2>/dev/null || true
        sudo systemctl disable postgresql 2>/dev/null || true
        sudo apt remove --purge -y postgresql-* 2>/dev/null || true
        sudo rm -rf /var/lib/postgresql /etc/postgresql
        sudo deluser postgres 2>/dev/null || true
    fi
    
    ui_success "PostgreSQL rollback completed"
}

# Rollback Zsh installation
rollback_zsh() {
    ui_info "🐚 Rolling back Zsh installation..."
    
    # Restore original shell
    if [ "$(basename "$SHELL")" = "zsh" ]; then
        chsh -s /bin/bash
        ui_info "Restored bash as default shell"
    fi
    
    # Remove Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        rm -rf "$HOME/.oh-my-zsh"
        ui_info "Removed Oh My Zsh"
    fi
    
    # Remove Zsh configuration
    if [ -f "$HOME/.zshrc" ]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)"
        ui_info "Backed up .zshrc"
    fi
    
    # Remove package
    sudo apt remove --purge -y zsh 2>/dev/null || true
    
    ui_success "Zsh rollback completed"
}

# Rollback development environment
rollback_dev_env() {
    ui_info "💻 Rolling back development environment..."
    
    if [[ "${DEV_ENV_SELECTED:-}" == *"Node.js"* ]]; then
        # Remove Node.js
        sudo apt remove --purge -y nodejs npm 2>/dev/null || true
        sudo rm -rf /etc/apt/sources.list.d/nodesource.list
    fi
    
    if [[ "${DEV_ENV_SELECTED:-}" == *"Python"* ]]; then
        # Remove Python virtual environment
        if [ -d "$HOME/.venv" ]; then
            rm -rf "$HOME/.venv"
            ui_info "Removed Python virtual environment"
        fi
        
        # Remove Python packages (be careful here)
        # sudo apt remove --purge -y python3-pip python3-venv 2>/dev/null || true
    fi
    
    ui_success "Development environment rollback completed"
}

# Perform complete rollback
perform_rollback() {
    ui_warning "⚠️ This will remove all components installed by this script!"
    
    if ! gum confirm "Are you sure you want to proceed with rollback?"; then
        ui_info "Rollback cancelled"
        return 0
    fi
    
    if ! load_rollback_state; then
        ui_error "Cannot perform rollback without state information"
        return 1
    fi
    
    ui_info "🔄 Starting rollback process..."
    
    # Rollback each component
    for component in "${SELECTIONS[@]}"; do
        case "$component" in
            "docker") rollback_docker ;;
            "nginx") rollback_nginx ;;
            "psql") rollback_postgresql ;;
            "zsh") rollback_zsh ;;
            "vim") sudo apt remove --purge -y vim 2>/dev/null || true ;;
            "dev_env") rollback_dev_env ;;
            "apps") 
                # Remove snap packages
                for app in ${DEV_TOOLS_SELECTED:-}; do
                    case "$app" in
                        "Postman") sudo snap remove postman 2>/dev/null || true ;;
                        "VS_Code") sudo snap remove code 2>/dev/null || true ;;
                        "Teams") sudo snap remove teams-for-linux 2>/dev/null || true ;;
                        "PyCharm") sudo snap remove pycharm-professional 2>/dev/null || true ;;
                        "Figma") sudo snap remove figma-linux 2>/dev/null || true ;;
                    esac
                done
                ;;
            "monitoring")
                sudo apt remove --purge -y htop 2>/dev/null || true
                sudo apt remove --purge -y neohtop 2>/dev/null || true
                ;;
        esac
    done
    
    # Clean up package cache
    sudo apt autoremove -y
    sudo apt autoclean
    
    # Remove configuration directory
    if gum confirm "Remove configuration directory ($CONFIG_DIR)?"; then
        rm -rf "$CONFIG_DIR"
        ui_info "Configuration directory removed"
    fi
    
    ui_success "🎉 Rollback completed successfully!"
}

# Show rollback menu
show_rollback_menu() {
    local choices=("🔄 Complete Rollback" "📋 Show Installed Components" "❌ Cancel")
    local choice
    
    choice=$(gum choose --header="🔙 Rollback Options" "${choices[@]}")
    
    case "$choice" in
        "🔄 Complete Rollback")
            perform_rollback
            ;;
        "📋 Show Installed Components")
            if load_rollback_state; then
                ui_info "Installed components:"
                for component in "${SELECTIONS[@]}"; do
                    echo "  - $component"
                done
            fi
            ;;
        "❌ Cancel")
            ui_info "Rollback cancelled"
            ;;
    esac
}