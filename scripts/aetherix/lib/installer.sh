#!/bin/bash

# Main installer orchestration

# Install all selected components
install_all_components() {
    # Count total components first
    count_total_components

    # Run apt update once before starting installation
    ui_info "🔄 Updating package lists..."
    if [ "$DRY_RUN" = false ]; then
        if ! sudo apt update; then
            ui_error "Failed to update package lists"
            exit 1
        fi
    fi

    # Installation Phase
    show_spacer
    ui_info "⚙️ Installing components..."
    show_spacer

    # Install components in dependency order
    local -A component_installers=(
        ["docker"]="install_docker"
        ["nginx"]="install_nginx"
        ["psql"]="install_postgresql"
        ["zsh"]="install_zsh"
        ["vim"]="install_vim"
        ["apps"]="install_apps"
        ["monitoring"]="install_monitoring"
        ["dev_env"]="install_dev_env"
        ["scripts"]="install_scripts"
    )

    # Install in order, respecting dependencies
    for component in docker nginx psql zsh vim apps monitoring dev_env scripts; do
        if is_selected "$component"; then
            local installer_func="${component_installers[$component]}"
            if declare -f "$installer_func" > /dev/null; then
                run_or_simulate "$component" "$installer_func"
            else
                ui_error "Installer function $installer_func not found for $component"
                update_component_progress "$component" "failed"
            fi
        fi
    done

    # Show final progress summary
    show_spacer
    ui_success "🎯 Installation Summary: $COMPLETED_COMPONENTS/$TOTAL_COMPONENTS components completed"
}