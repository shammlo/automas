#!/bin/bash

# Nginx Component - Installation and configuration

# Configure Nginx
configure_nginx() {
    add_selection "nginx"

    NGINX_AUTO=$(gum confirm "📜 Do you want automatic project setup for Arbela or cardhouzz?" && echo true || echo false)
    gum style --foreground 3 "   └── • Autostart: $([ "$NGINX_AUTO" = true ] && echo True || echo False)"

    if [ "$NGINX_AUTO" = true ]; then
        ui_info "📜 Select the desired project:"
        NGINX_PROJECT=$(gum choose "Arbela" "cardhouzz")
        gum style --foreground 3 "   └── • Project selected: $NGINX_PROJECT"
    fi
}

# Install Nginx
install_nginx() {
    print_section_title "⚙️  Installing Nginx"
    update_component_progress "Nginx" "starting"

    if is_installed nginx; then
        ui_warning "Nginx already installed. Skipping."
        update_component_progress "Nginx" "skipped"
        print_success_box "Nginx already installed"
        return 0
    fi

    ui_info "🕸️  Installing Nginx..."

    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would install Nginx"
        [ "$NGINX_AUTO" = true ] && ui_dry_run "Would configure for project: $NGINX_PROJECT"
        update_component_progress "Nginx" "skipped"
        return 0
    fi

    if ! sudo apt install -y nginx; then
        ui_error "Failed to install Nginx"
        update_component_progress "Nginx" "failed"
        return 1
    fi

    # Configure projects if needed
    if [ "$NGINX_AUTO" = true ]; then
        ui_info "⚙️  Configuring Nginx for $NGINX_PROJECT..."
        safe_spin "Setting up Nginx for $NGINX_PROJECT..."
        configure_nginx_project "$NGINX_PROJECT"
    fi

    # Enable and start nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx

    update_component_progress "Nginx" "completed"
    print_success_box "Nginx installed successfully"
}

# Configure Nginx for specific projects
configure_nginx_project() {
    local project="$1"
    
    case "$project" in
        "Arbela")
            configure_arbela_nginx
            ;;
        "cardhouzz")
            configure_cardhouzz_nginx
            ;;
    esac
}

# Configure Nginx for Arbela project
configure_arbela_nginx() {
    ui_info "Setting up Nginx configuration for Arbela..."
    # Add Arbela-specific nginx configuration here
    # This would typically involve creating server blocks, etc.
}

# Configure Nginx for cardhouzz project
configure_cardhouzz_nginx() {
    ui_info "Setting up Nginx configuration for cardhouzz..."
    # Add cardhouzz-specific nginx configuration here
}