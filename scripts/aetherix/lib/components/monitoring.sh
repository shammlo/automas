#!/bin/bash

# Monitoring Component - System monitoring tools installation

# Install monitoring tools
install_monitoring() {
    print_section_title "📊 Installing System Monitoring Tools"
    update_component_progress "Monitoring Tools" "starting"

    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would install monitoring tools: $MONITOR_TOOLS_SELECTED"
        update_component_progress "Monitoring Tools" "skipped"
        return 0
    fi

    ui_info "📊 Installing system monitoring tools..."
    local tool_count=0
    local total_tools=$(echo "$MONITOR_TOOLS_SELECTED" | wc -w)

    for tool in $MONITOR_TOOLS_SELECTED; do
        tool_count=$((tool_count + 1))
        install_monitoring_tool "$tool" "$tool_count" "$total_tools"
    done

    update_component_progress "Monitoring Tools" "completed"
    print_success_box "Monitoring tools installed successfully"
}

# Install individual monitoring tool
install_monitoring_tool() {
    local tool="$1"
    local current="$2"
    local total="$3"

    if is_installed "$tool"; then
        ui_warning "[$current/$total] $tool already installed. Skipping."
        return 0
    fi

    ui_info "[$current/$total] Installing $tool..."

    case "$tool" in
    "htop")
        sudo apt install -y htop
        ;;
    "NeoHtop")
        install_neohtop
        ;;
    "All")
        # Skip "All" as it's handled in configuration
        return
        ;;
    *)
        sudo apt install -y "$tool"
        ;;
    esac

    ui_success "$tool installed successfully"
}

# Install NeoHtop
install_neohtop() {
    local download_path="$HOME/Downloads/NeoHtop_1.2.0_x86_64.deb"
    
    ui_info "Downloading NeoHtop..."
    curl -L -o "$download_path" \
        https://github.com/Abdenasser/neohtop/releases/download/v1.2.0/NeoHtop_1.2.0_x86_64.deb

    if ! sudo apt install -y "$download_path"; then
        ui_error "Failed to install NeoHtop"
        return 1
    fi
    
    # Clean up downloaded file
    rm -f "$download_path"
}