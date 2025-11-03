#!/bin/bash

# Aetherix Enhanced - Feature-Rich Development Environment Orchestrator
# Enhanced version with resume functionality, interactive selection, and analytics

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

# Enhanced features
RESUME_MODE=false
PROGRESS_STATE_FILE="$CONFIG_DIR/progress_state.conf"
ANALYTICS_FILE="$CONFIG_DIR/analytics.json"
INSTALLATION_ID=$(date +%s)_$$ 

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
            --resume)
                RESUME_MODE=true
                ;;
            --analytics)
                source_modules
                show_analytics
                exit 0
                ;;
            --interactive)
                source_modules
                interactive_component_selection
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
    --resume          Resume interrupted installation
    --analytics       Show installation analytics and statistics
    --interactive     Interactive component selection mode

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
        "        "lib/installer.sh"
        "lib/enhanced_installer.sh""
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

# Enhanced Features Functions

# Save progress state for resume functionality
save_progress_state() {
    {
        echo "# Aetherix Progress State"
        echo "# Installation ID: $INSTALLATION_ID"
        echo "# Last updated: $(date)"
        echo "SELECTIONS=(${SELECTIONS[*]})"
        echo "COMPLETED_COMPONENTS=$COMPLETED_COMPONENTS"
        echo "FAILED_COMPONENTS=$FAILED_COMPONENTS"
        echo "SKIPPED_COMPONENTS=$SKIPPED_COMPONENTS"
        echo "FAILED_LIST=(${FAILED_LIST[*]})"
        echo "START_TIME=$START_TIME"
        
        # Save component-specific configurations
        echo "NGINX_AUTO=$NGINX_AUTO"
        echo "NGINX_PROJECT=\"$NGINX_PROJECT\""
        echo "DOCKER_VERSION=\"$DOCKER_VERSION\""
        echo "DOCKER_AUTOSTART=$DOCKER_AUTOSTART"
        echo "PSQL_VERSION=\"$PSQL_VERSION\""
        echo "PSQL_DOCKER=$PSQL_DOCKER"
        echo "DB_NAME=\"$DB_NAME\""
        echo "DB_USER=\"$DB_USER\""
        echo "DB_PORT=\"$DB_PORT\""
        echo "INSTALL_OH_MY_ZSH=$INSTALL_OH_MY_ZSH"
        echo "ZSH_THEME=\"$ZSH_THEME\""
        echo "ZSH_DEFAULT=$ZSH_DEFAULT"
        echo "DEV_ENV_SELECTED=\"$DEV_ENV_SELECTED\""
        echo "NODE_VERSION=\"$NODE_VERSION\""
        echo "PYTHON_VENV=$PYTHON_VENV"
        echo "DEV_TOOLS_SELECTED=\"$DEV_TOOLS_SELECTED\""
        echo "MONITOR_TOOLS_SELECTED=\"$MONITOR_TOOLS_SELECTED\""
        echo "SCRIPTS_SELECTED=\"$SCRIPTS_SELECTED\""
    } > "$PROGRESS_STATE_FILE"
}

# Load progress state for resume
load_progress_state() {
    if [[ -f "$PROGRESS_STATE_FILE" ]]; then
        source "$PROGRESS_STATE_FILE"
        ui_success "Loaded previous installation state"
        ui_info "Previous progress: $COMPLETED_COMPONENTS completed, $FAILED_COMPONENTS failed, $SKIPPED_COMPONENTS skipped"
        return 0
    else
        ui_warning "No previous installation state found"
        return 1
    fi
}

# Interactive component selection with multi-select
interactive_component_selection() {
    ui_info "🎯 Interactive Component Selection"
    echo ""
    
    local components=(
        "docker:🐳 Docker - Container platform"
        "nginx:🌐 Nginx - Web server" 
        "psql:🐘 PostgreSQL - Database system"
        "zsh:🐚 Zsh + Oh My Zsh - Enhanced shell"
        "vim:⚡ Vim - Text editor"
        "apps:📱 Development Apps - VS Code, Postman, etc."
        "monitoring:📊 System Monitoring - Performance tools"
        "dev_env:🔧 Dev Environments - Node.js, Python"
        "scripts:📜 Utility Scripts - Automation tools"
    )
    
    local selected_components=()
    
    # Multi-select interface
    for component_info in "${components[@]}"; do
        local component="${component_info%%:*}"
        local description="${component_info#*:}"
        
        if gum confirm "$description"; then
            selected_components+=("$component")
            
            # Show estimated size and time
            local size=$(get_component_size "$component")
            local time=$(get_component_install_time "$component")
            ui_info "  └── Size: $size, Time: $time"
        fi
    done
    
    if [ ${#selected_components[@]} -eq 0 ]; then
        ui_warning "No components selected. Exiting."
        exit 0
    fi
    
    # Set selections
    SELECTIONS=("${selected_components[@]}")
    
    # Show summary with real-time calculations
    show_interactive_summary
    
    if gum confirm "🚀 Proceed with these selections?"; then
        # Configure selected components
        for component in "${SELECTIONS[@]}"; do
            case "$component" in
                "docker") configure_docker ;;
                "nginx") configure_nginx ;;
                "psql") configure_postgresql ;;
                "zsh") configure_zsh ;;
                "vim") configure_vim ;;
                "apps") configure_apps ;;
                "monitoring") configure_monitoring ;;
                "dev_env") configure_dev_env ;;
                "scripts") configure_scripts ;;
            esac
        done
        
        # Save configuration and proceed
        save_config
        save_progress_state
        
        # Start installation
        install_all_components_enhanced
    else
        ui_info "Installation cancelled"
    fi
}

# Show interactive selection summary
show_interactive_summary() {
    local total_size=$(calculate_total_size)
    local total_time=$(calculate_total_time)
    
    gum style --border double --margin "1 0" --padding "1 2" --foreground 45 \
        "📋 Installation Summary
        
Selected Components: ${#SELECTIONS[@]}
$(printf '  • %s\n' "${SELECTIONS[@]}")

Estimated Download Size: $total_size
Estimated Installation Time: $total_time
Disk Space Required: $(echo "$total_size" | sed 's/MB/MB + 20%/' | sed 's/GB/GB + 20%/')

Network Speed: $(get_network_speed)"
}

# Analytics and statistics tracking
init_analytics() {
    if [[ ! -f "$ANALYTICS_FILE" ]]; then
        echo '{"installations": [], "components": {}, "performance": {}}' > "$ANALYTICS_FILE"
    fi
}

# Record installation analytics
record_analytics() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local success_rate=$(( (COMPLETED_COMPONENTS * 100) / (COMPLETED_COMPONENTS + FAILED_COMPONENTS + SKIPPED_COMPONENTS) ))
    
    # Create analytics entry
    local analytics_entry=$(cat << EOF
{
    "id": "$INSTALLATION_ID",
    "timestamp": "$(date -Iseconds)",
    "duration": $duration,
    "components_selected": ${#SELECTIONS[@]},
    "components_completed": $COMPLETED_COMPONENTS,
    "components_failed": $FAILED_COMPONENTS,
    "components_skipped": $SKIPPED_COMPONENTS,
    "success_rate": $success_rate,
    "selections": $(printf '"%s",' "${SELECTIONS[@]}" | sed 's/,$//' | sed 's/^/[/' | sed 's/$/]/'),
    "failed_components": $(printf '"%s",' "${FAILED_LIST[@]}" | sed 's/,$//' | sed 's/^/[/' | sed 's/$/]/')
}
EOF
    )
    
    # Update analytics file (simplified JSON append)
    local temp_file=$(mktemp)
    jq --argjson entry "$analytics_entry" '.installations += [$entry]' "$ANALYTICS_FILE" > "$temp_file" 2>/dev/null || {
        # Fallback if jq is not available
        echo "Analytics recorded to log file"
        echo "$analytics_entry" >> "$CONFIG_DIR/analytics.log"
        return
    }
    mv "$temp_file" "$ANALYTICS_FILE"
}

# Show analytics dashboard
show_analytics() {
    if [[ ! -f "$ANALYTICS_FILE" ]]; then
        ui_warning "No analytics data available"
        return
    fi
    
    ui_info "📊 Aetherix Installation Analytics"
    echo ""
    
    # Show basic stats (simplified without jq dependency)
    if command -v jq &>/dev/null; then
        local total_installations=$(jq '.installations | length' "$ANALYTICS_FILE")
        local avg_duration=$(jq '[.installations[].duration] | add / length' "$ANALYTICS_FILE")
        local most_popular=$(jq -r '[.installations[].selections[]] | group_by(.) | map({component: .[0], count: length}) | sort_by(.count) | reverse | .[0].component' "$ANALYTICS_FILE")
        
        gum style --border double --margin "1 0" --padding "1 2" --foreground 45 \
            "📈 Analytics Summary
            
Total Installations: $total_installations
Average Duration: ${avg_duration}s ($(( avg_duration / 60 ))m $(( avg_duration % 60 ))s)
Most Popular Component: $most_popular

Recent Installations:"
        
        jq -r '.installations[-5:] | .[] | "  • \(.timestamp) - \(.components_completed)/\(.components_selected) components (\(.success_rate)% success)"' "$ANALYTICS_FILE"
    else
        ui_info "Install 'jq' for detailed analytics"
        ui_info "Basic analytics available in: $CONFIG_DIR/analytics.log"
    fi
}

# Main execution function
main() {
    parse_args "$@"
    source_modules
    
    # Initialize analytics
    init_analytics
    
    # Handle resume mode
    if [ "$RESUME_MODE" = true ]; then
        if load_progress_state; then
            ui_info "🔄 Resuming installation..."
            # Skip to installation phase
            install_all_components_enhanced
            show_installation_summary
            record_analytics
            ui_success "Resume completed successfully!"
            exit 0
        else
            ui_error "Cannot resume - no previous state found"
            exit 1
        fi
    fi
    
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
    
    # Save initial progress state
    save_progress_state
    
    # Install all selected components (enhanced version)
    install_all_components_enhanced
    
    # Show installation summary
    show_installation_summary
    
    # Record analytics
    record_analytics
    
    # Run health check
    echo ""
    if gum confirm "🏥 Run post-installation health check?"; then
        run_health_check
        generate_health_report
    fi
    
    # Show final summary and dashboard
    show_final_summary
    show_post_install_dashboard
    
    # Clean up progress state on successful completion
    rm -f "$PROGRESS_STATE_FILE"
    
    ui_success "Setup completed successfully!"
    ui_info "💡 Tip: Use --analytics to view installation statistics"
}

# Export variables for use in modules
export SCRIPT_DIR CONFIG_DIR CONFIG_FILE LOG_FILE DEBUG DRY_RUN
export SELECTIONS TOTAL_COMPONENTS COMPLETED_COMPONENTS FAILED_COMPONENTS SKIPPED_COMPONENTS
export START_TIME FAILED_LIST

# Run main function
main "$@"