#!/bin/bash

# Scripts Component - Development scripts installation

# Install development scripts
install_scripts() {
    print_section_title "📜 Installing Development Scripts"
    update_component_progress "Development Scripts" "starting"

    # Ensure SCRIPT_DIR is defined
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$HOME/dev_scripts"
        mkdir -p "$SCRIPT_DIR"
        setup_nox_script
    fi

    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would install development scripts: $SCRIPTS_SELECTED"
        update_component_progress "Development Scripts" "skipped"
        return 0
    fi

    ui_info "📜 Installing development scripts..."
    local script_count=0
    local total_scripts=$(echo "$SCRIPTS_SELECTED" | wc -w)

    for script in $SCRIPTS_SELECTED; do
        script_count=$((script_count + 1))
        install_dev_script "$script" "$script_count" "$total_scripts"
    done

    update_component_progress "Development Scripts" "completed"
    print_success_box "Development scripts installed successfully"
}

# Install individual development script
install_dev_script() {
    local script="$1"
    local current="$2"
    local total="$3"

    ui_info "[$current/$total] Installing $script script..."

    case "$script" in
    "Nginx")
        "$SCRIPT_DIR/nox.sh" -ngx
        ;;
    "generate_po_file")
        "$SCRIPT_DIR/nox.sh" -gpo
        ;;
    "DB_manager")
        "$SCRIPT_DIR/nox.sh" -dbm
        ;;
    "All")
        "$SCRIPT_DIR/nox.sh" -ngx -gpo -dbm
        ;;
    esac

    if [ $? -ne 0 ]; then
        ui_error "Failed to execute $script"
        update_component_progress "Development Scripts" "failed"
        return 1
    fi

    safe_spin "Installing $script..."
    ui_success "$script installed"
}

# Setup nox.sh script if it doesn't exist
setup_nox_script() {
    if [ ! -f "$SCRIPT_DIR/nox.sh" ]; then
        ui_info "📜 Creating development scripts directory..."
        # This is a placeholder - in a real implementation,
        # you'd download or create the script appropriately
        cat > "$SCRIPT_DIR/nox.sh" << 'EOF'
#!/bin/bash
# NOX Development Scripts Manager

case "$1" in
    -ngx)
        echo "Setting up Nginx development scripts..."
        # Add nginx script setup here
        ;;
    -gpo)
        echo "Setting up generate_po_file script..."
        # Add generate_po_file script setup here
        ;;
    -dbm)
        echo "Setting up DB manager script..."
        # Add DB manager script setup here
        ;;
    *)
        echo "Usage: $0 [-ngx|-gpo|-dbm]"
        exit 1
        ;;
esac
EOF
        chmod +x "$SCRIPT_DIR/nox.sh"
    fi
}