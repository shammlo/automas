#!/bin/bash

# Vim Component - Installation and configuration

# Install Vim
install_vim() {
    print_section_title "📝 Installing Vim"
    update_component_progress "Vim" "starting"

    if is_installed vim; then
        ui_warning "Vim already installed. Skipping."
        update_component_progress "Vim" "skipped"
        print_success_box "Vim already installed"
        return 0
    fi

    ui_info "📝 Installing Vim..."

    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would install Vim"
        update_component_progress "Vim" "skipped"
        return 0
    fi

    if ! sudo apt install -y vim; then
        ui_error "Failed to install Vim"
        update_component_progress "Vim" "failed"
        return 1
    fi

    update_component_progress "Vim" "completed"
    print_success_box "Vim installed successfully"
}