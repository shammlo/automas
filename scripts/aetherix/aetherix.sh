#!/bin/bash

# Main Nicronian Setup Script - Refactored Version
# This is the entry point that orchestrates the entire setup process

set -eo pipefail

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/nicronian-setup"
CONFIG_FILE="$CONFIG_DIR/last_config.conf"
LOG_FILE="$CONFIG_DIR/setup.log"

# Initialize logging
mkdir -p "$CONFIG_DIR"
echo "🧾 Setup log initiated at $(date)" >"$LOG_FILE"

# Global variables
DEBUG=false
DRY_RUN=false
SELECTIONS=()

# Initialize component configuration variables
NGINX_AUTO=false
NGINX_PROJECT=""
DOCKER_VERSION="Latest"
DOCKER_AUTOSTART=false
PSQL_VERSION="14"
PSQL_DOCKER=false
DB_NAME="devdb"
DB_USER="devuser"
DB_PORT="5432"
INSTALL_OH_MY_ZSH=false
ZSH_THEME="robbyrussell"
ZSH_DEFAULT=false
INSTALL_ZSH_PLUGINS=false
ZSH_PLUGINS_SELECTED=""
GIT_CONFIG=false
GIT_NAME=""
GIT_EMAIL=""
DEV_ENV_SELECTED=""
NODE_VERSION="LTS"
PYTHON_VENV=false
DEV_TOOLS_SELECTED=""
MONITOR_TOOLS_SELECTED=""
SCRIPTS_SELECTED=""

# Progress tracking
TOTAL_COMPONENTS=0
COMPLETED_COMPONENTS=0
FAILED_COMPONENTS=0
SKIPPED_COMPONENTS=0
START_TIME=$(date +%s)
FAILED_LIST=()

# Parse command line arguments
parse_args() {
    for arg in "$@"; do
        case "$arg" in
            --debug)
                DEBUG=true
                set -x
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --components-help)
                source_modules
                show_interactive_help
                exit 0
                ;;
        esac
    done
}

# Show help message
show_help() {
    cat << EOF
Nicronian System Setup Script

Usage: $0 [OPTIONS]

Options:
    --debug           Enable debug mode with verbose output
    --dry-run         Show what would be installed without actually installing
    --help, -h        Show this help message
    --components-help Show detailed component information and help

Components available for installation:
    - Docker
    - Nginx  
    - PostgreSQL
    - Zsh with Oh My Zsh
    - Vim
    - Development Apps (Postman, VS Code, etc.)
    - System Monitoring Tools
    - Development Environments (Node.js, Python)
    - Development Scripts

Configuration is saved to: $CONFIG_FILE
Logs are saved to: $LOG_FILE
EOF
}

# Source all modules
source_modules() {
    local modules=(
        "lib/utils.sh"
        "lib/ui.sh" 
        "lib/progress.sh"
        "lib/config.sh"
        "lib/dependencies.sh"
        "lib/validation.sh"
        "lib/presets.sh"
        "lib/health_check.sh"
        "lib/rollback.sh"
        "lib/help.sh"
        "lib/templates.sh"
        "lib/enhanced_progress.sh"
        "lib/compatibility.sh"
        "lib/components/docker.sh"
        "lib/components/nginx.sh"
        "lib/components/postgresql.sh"
        "lib/components/zsh.sh"
        "lib/components/vim.sh"
        "lib/components/apps.sh"
        "lib/components/monitoring.sh"
        "lib/components/dev_env.sh"
        "lib/components/scripts.sh"
        "lib/configurators.sh"
        "lib/installer.sh"
    )

    local missing_modules=()
    for module in "${modules[@]}"; do
        if [[ -f "$SCRIPT_DIR/$module" ]]; then
            if ! source "$SCRIPT_DIR/$module"; then
                ui_error "Failed to load module: $module"
                exit 1
            fi
        else
            missing_modules+=("$module")
        fi
    done
    
    if [ ${#missing_modules[@]} -gt 0 ]; then
        ui_error "Critical modules missing:"
        for module in "${missing_modules[@]}"; do
            echo "  - $module"
        done
        ui_error "Please ensure all required modules are present"
        exit 1
    fi
}

# Main execution function
main() {
    parse_args "$@"
    source_modules
    
    # Validate system requirements
    if ! validate_system_requirements; then
        exit 1
    fi
    
    # Run compatibility check
    if gum confirm "🔍 Run advanced system compatibility check?"; then
        if ! check_system_compatibility; then
            if ! gum confirm "⚠️ Compatibility issues found. Continue anyway?"; then
                exit 1
            fi
        fi
    fi
    
    # Ensure required tools are available
    ensure_dependencies
    
    # Display the header
    show_header
    
    # Offer preset configurations
    if gum confirm "🎯 Would you like to use a preset configuration?"; then
        if select_preset; then
            # Preset was selected, skip custom configuration
            echo ""
        else
            # User chose custom configuration
            collect_configurations
        fi
    else
        # User declined presets, go with custom
        collect_configurations
    fi
    
    # Show installation preview
    show_installation_preview
    
    # Final confirmation
    if ! gum confirm "🚀 Proceed with installation?"; then
        ui_error "Installation cancelled."
        exit 0
    fi
    
    # Initialize enhanced progress tracking
    init_progress_tracking
    
    # Install all selected components
    install_all_components
    
    # Show installation summary
    show_installation_summary
    
    # Run health check
    echo ""
    if gum confirm "🏥 Run post-installation health check?"; then
        run_health_check
        generate_health_report
    fi
    
    # Show final summary and dashboard
    show_final_summary
    show_post_install_dashboard
    
    ui_success "Setup completed successfully!"
}

# Export variables for use in modules
export SCRIPT_DIR CONFIG_DIR CONFIG_FILE LOG_FILE DEBUG DRY_RUN
export SELECTIONS TOTAL_COMPONENTS COMPLETED_COMPONENTS FAILED_COMPONENTS SKIPPED_COMPONENTS
export START_TIME FAILED_LIST

# Run main function
main "$@"