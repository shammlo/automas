#!/bin/bash

# Apps Component - Installation of development applications

# Install apps
install_apps() {
    print_section_title "🛠️  Installing Applications"
    update_component_progress "Apps" "starting"

    # Ensure Snap is available
    if ! is_installed snap; then
        ui_info "📦 Installing Snap package manager..."
        install_if_missing "snapd" "Snap"
        sudo systemctl enable --now snapd.socket
    fi

    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would install applications: $DEV_TOOLS_SELECTED"
        update_component_progress "Apps" "skipped"
        return 0
    fi

    ui_info "🛠️  Installing selected applications..."
    local app_count=0
    local total_apps=$(echo "$DEV_TOOLS_SELECTED" | wc -w)

    for tool in $DEV_TOOLS_SELECTED; do
        app_count=$((app_count + 1))
        install_individual_app "$tool" "$app_count" "$total_apps"
    done

    update_component_progress "Apps" "completed"
    print_success_box "Applications installed successfully"
}

# Install individual application
install_individual_app() {
    local app="$1"
    local current="$2"
    local total="$3"
    
    case "$app" in
    "Postman")
        install_snap_app "Postman" "postman"
        ;;
    "VS_Code")
        install_snap_app "VS Code" "code" "classic"
        ;;
    "Teams")
        install_snap_app "Teams" "teams-for-linux"
        ;;
    "PyCharm")
        install_snap_app "PyCharm" "pycharm-professional" "classic"
        ;;
    "Figma")
        install_snap_app "Figma" "figma-linux"
        ;;
    "Wifi_Hotspot")
        install_wifi_hotspot
        ;;
    "All")
        # Skip "All" as it's handled in the configuration phase
        return
        ;;
    esac
    
    render_progress_bar "$current" "$total"
    show_spacer
}

# Install Wifi Hotspot
install_wifi_hotspot() {
    ui_info "Installing Wifi Hotspot..."
    safe_spin "Installing Wifi Hotspot..."
    ensure_ppa "lakinduakash/lwh"
    sudo apt install -y linux-wifi-hotspot
    ui_success "Wifi Hotspot installed successfully"
}