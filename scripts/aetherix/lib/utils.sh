#!/bin/bash

# Utilities Library - Common helper functions

# Display spinner with message
safe_spin() {
    if [ "$DEBUG" = true ]; then
        echo "$1"
        sleep 1
    else
        gum spin --spinner dot --title "$1" -- sleep 2
    fi
}

# Check if a package is already installed
is_installed() {
    command -v "$1" &>/dev/null
}

# Install package with apt if not already installed
install_if_missing() {
    local package="$1"
    local display_name="${2:-$package}"
    
    if ! is_installed "$package"; then
        ui_warning "$display_name not found. Installing..."
        if [ "$DRY_RUN" = true ]; then
            ui_dry_run "Would install: $package"
            return 0
        fi
        
        if sudo apt install -y "$package"; then
            ui_success "$display_name installed successfully"
            return 0
        else
            ui_error "Failed to install $display_name"
            return 1
        fi
    else
        ui_info "$display_name already installed"
        return 0
    fi
}

# Add item to selections array
add_selection() {
    SELECTIONS+=("$1")
    ui_success "$1 will be installed"
}

# Check if item is in selections
is_selected() {
    [[ " ${SELECTIONS[*]} " =~ " $1 " ]]
}

# Execute command or simulate in dry run mode
run_or_simulate() {
    local name="$1"
    local command="$2"

    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would execute: $command"
        update_component_progress "$name" "skipped"
        return 0
    else
        if eval "$command"; then
            update_component_progress "$name" "completed"
            return 0
        else
            update_component_progress "$name" "failed"
            return 1
        fi
    fi
}

# Log message to file
log_message() {
    local level="$1"
    local message="$2"
    echo "$(date) [$level] $message" >> "$LOG_FILE"
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    ui_error "Error occurred at line $line_number (exit code: $exit_code)"
    log_message "ERROR" "Script failed at line $line_number with exit code $exit_code"
    exit $exit_code
}

# Ensure PPA is added
ensure_ppa() {
    local ppa_name="$1"
    local ppa_slug="${ppa_name//\//-}"
    local list_file="/etc/apt/sources.list.d/${ppa_slug}-ubuntu-*.list"

    if ls $list_file &>/dev/null 2>&1; then
        ui_info "PPA already added: $ppa_name"
    else
        ui_info "Adding PPA: $ppa_name"
        if [ "$DRY_RUN" = false ]; then
            sudo add-apt-repository -y "ppa:$ppa_name"
            sudo apt update
        fi
    fi
}

# Install snap package
install_snap_app() {
    local name="$1"
    local snap_package="$2"
    local classic_flag="$3"

    ui_info "Installing $name..."
    safe_spin "Installing $name..."
    
    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would install snap: $snap_package"
        return 0
    fi
    
    if [ "$classic_flag" = "classic" ]; then
        sudo snap install "$snap_package" --classic
    else
        sudo snap install "$snap_package"
    fi
    
    ui_success "$name installed successfully"
}

# Get current progress count
get_current_count() {
    echo $((COMPLETED_COMPONENTS + SKIPPED_COMPONENTS + FAILED_COMPONENTS))
}

# Set up error handling
trap 'handle_error $LINENO' ERR