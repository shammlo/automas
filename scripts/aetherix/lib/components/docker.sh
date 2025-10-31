#!/bin/bash

# Docker Component - Installation and configuration

# Configure Docker
configure_docker() {
    add_selection "docker"
    
    # Show quick help
    show_quick_help "docker"

    ui_info "📜 Select the desired version:"
    DOCKER_VERSION=$(gum choose "Latest" "20.10" "19.03")
    DOCKER_VERSION=${DOCKER_VERSION:-Latest}
    gum style --foreground 3 "   └── • Version selected: $DOCKER_VERSION"
    
    DOCKER_AUTOSTART=$(gum confirm "⚙️ Start Docker on boot?" && echo true || echo false)
    gum style --foreground 3 "   └── • Autostart: $([ "$DOCKER_AUTOSTART" = true ] && echo Enabled || echo Disabled)"
}

# Install Docker
install_docker() {
    print_section_title "🐳 Installing Docker"
    update_component_progress "Docker" "starting"

    if is_installed docker; then
        ui_warning "Docker already installed. Skipping."
        update_component_progress "Docker" "skipped"
        print_success_box "Docker already installed"
        return 0
    fi

    ui_info "🐳 Installing Docker..."

    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would install Docker version $DOCKER_VERSION"
        update_component_progress "Docker" "skipped"
        return 0
    fi

    if ! sudo apt install -y docker.io; then
        ui_error "Failed to install Docker"
        update_component_progress "Docker" "failed"
        return 1
    fi

    # Add user to docker group
    if ! groups $USER | grep -qw docker; then
        sudo usermod -aG docker $USER
        ui_warning "Added user to 'docker' group. Please logout and log back in to apply changes."
    fi

    # Configure autostart if needed
    if [ "$DOCKER_AUTOSTART" = true ]; then
        ui_info "⚙️  Configuring Docker autostart..."
        sudo systemctl enable docker
        sudo systemctl start docker
    fi

    update_component_progress "Docker" "completed"
    print_success_box "Docker installed successfully"
}