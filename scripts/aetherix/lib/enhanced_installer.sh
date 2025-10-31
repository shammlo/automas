#!/bin/bash

# Enhanced Installer - Installation orchestration with resume support

# Enhanced component installation with resume support
install_all_components_enhanced() {
    # Count total components first
    count_total_components

    # Check if we're resuming and load completed components
    local completed_components_list=()
    if [ "$RESUME_MODE" = true ] && [[ -f "$PROGRESS_STATE_FILE" ]]; then
        # Parse completed components from progress state
        local completed_line=$(grep "^COMPLETED_COMPONENTS=" "$PROGRESS_STATE_FILE" | cut -d'=' -f2)
        local failed_line=$(grep "^FAILED_COMPONENTS=" "$PROGRESS_STATE_FILE" | cut -d'=' -f2)
        local skipped_line=$(grep "^SKIPPED_COMPONENTS=" "$PROGRESS_STATE_FILE" | cut -d'=' -f2)
        
        COMPLETED_COMPONENTS=${completed_line:-0}
        FAILED_COMPONENTS=${failed_line:-0}
        SKIPPED_COMPONENTS=${skipped_line:-0}
        
        ui_info "🔄 Resuming from previous state:"
        ui_info "  • Completed: $COMPLETED_COMPONENTS"
        ui_info "  • Failed: $FAILED_COMPONENTS" 
        ui_info "  • Skipped: $SKIPPED_COMPONENTS"
    fi

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
        ["docker"]="install_docker_enhanced"
        ["nginx"]="install_nginx_enhanced"
        ["psql"]="install_postgresql_enhanced"
        ["zsh"]="install_zsh_enhanced"
        ["vim"]="install_vim_enhanced"
        ["apps"]="install_apps_enhanced"
        ["monitoring"]="install_monitoring_enhanced"
        ["dev_env"]="install_dev_env_enhanced"
        ["scripts"]="install_scripts_enhanced"
    )

    # Install in order, respecting dependencies
    for component in docker nginx psql zsh vim apps monitoring dev_env scripts; do
        if is_selected "$component"; then
            # Check if component was already completed (for resume)
            if is_component_completed "$component"; then
                ui_info "✅ $component already completed, skipping..."
                continue
            fi
            
            local installer_func="${component_installers[$component]}"
            if declare -f "$installer_func" > /dev/null; then
                # Save progress before each component
                save_progress_state
                
                # Run the installer
                if run_or_simulate_enhanced "$component" "$installer_func"; then
                    # Component succeeded, save progress
                    save_progress_state
                else
                    # Component failed, save progress and continue or abort based on user choice
                    save_progress_state
                    if ! gum confirm "⚠️ $component installation failed. Continue with remaining components?"; then
                        ui_error "Installation aborted by user"
                        exit 1
                    fi
                fi
            else
                ui_error "Installer function $installer_func not found for $component"
                update_component_progress "$component" "failed"
                save_progress_state
            fi
        fi
    done

    # Show final progress summary
    show_enhanced_progress_summary
}

# Check if a component was already completed
is_component_completed() {
    local component="$1"
    
    # For resume mode, check if component is in a completed state
    if [ "$RESUME_MODE" = true ]; then
        case "$component" in
            "docker") is_installed docker && return 0 ;;
            "nginx") is_installed nginx && return 0 ;;
            "psql") 
                if [ "${PSQL_DOCKER:-false}" = true ]; then
                    docker ps -a --format '{{.Names}}' | grep -qw "postgres-$PSQL_VERSION" && return 0
                else
                    is_installed psql && return 0
                fi
                ;;
            "zsh") is_installed zsh && return 0 ;;
            "vim") is_installed vim && return 0 ;;
            "apps") 
                # Check if at least one app from the selection is installed
                for app in $DEV_TOOLS_SELECTED; do
                    case "$app" in
                        "VS_Code") snap list code &>/dev/null && return 0 ;;
                        "Postman") snap list postman &>/dev/null && return 0 ;;
                    esac
                done
                ;;
            "monitoring") is_installed htop && return 0 ;;
            "dev_env")
                if [[ "${DEV_ENV_SELECTED:-}" == *"Node.js"* ]]; then
                    is_installed node && return 0
                fi
                ;;
            "scripts") return 1 ;; # Scripts are always re-run
        esac
    fi
    
    return 1
}

# Enhanced run or simulate with better error handling
run_or_simulate_enhanced() {
    local component="$1"
    local installer_func="$2"

    ui_info "🔧 Processing $component..."
    
    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would execute: $installer_func"
        update_component_progress "$component" "skipped"
        return 0
    else
        # Set up error handling for this component
        local start_time=$(date +%s)
        
        if eval "$installer_func"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            update_component_progress "$component" "completed"
            ui_success "$component completed in ${duration}s"
            return 0
        else
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            update_component_progress "$component" "failed"
            ui_error "$component failed after ${duration}s"
            return 1
        fi
    fi
}

# Enhanced progress summary
show_enhanced_progress_summary() {
    local total_time=$(($(date +%s) - START_TIME))
    local success_rate=0
    
    if [ $((COMPLETED_COMPONENTS + FAILED_COMPONENTS + SKIPPED_COMPONENTS)) -gt 0 ]; then
        success_rate=$(( (COMPLETED_COMPONENTS * 100) / (COMPLETED_COMPONENTS + FAILED_COMPONENTS + SKIPPED_COMPONENTS) ))
    fi
    
    gum style --border double --margin "1 0" --padding "1 2" --foreground 45 \
        "📊 Installation Summary
        
Total Time: ${total_time}s ($(( total_time / 60 ))m $(( total_time % 60 ))s)
Success Rate: ${success_rate}%

✅ Completed: $COMPLETED_COMPONENTS
❌ Failed: $FAILED_COMPONENTS  
⏭️  Skipped: $SKIPPED_COMPONENTS"

    if [ ${#FAILED_LIST[@]} -gt 0 ]; then
        ui_warning "Failed components:"
        for failed in "${FAILED_LIST[@]}"; do
            echo "  • $failed"
        done
        echo ""
        ui_info "💡 Use --resume to retry failed components"
    fi
}

# Enhanced component installers (wrappers that add tracking)
install_docker_enhanced() {
    track_installation_start "docker"
    install_docker
    track_installation_end "docker" $?
}

install_nginx_enhanced() {
    track_installation_start "nginx"
    install_nginx
    track_installation_end "nginx" $?
}

install_postgresql_enhanced() {
    track_installation_start "postgresql"
    install_postgresql
    track_installation_end "postgresql" $?
}

install_zsh_enhanced() {
    track_installation_start "zsh"
    install_zsh
    track_installation_end "zsh" $?
}

install_vim_enhanced() {
    track_installation_start "vim"
    install_vim
    track_installation_end "vim" $?
}

install_apps_enhanced() {
    track_installation_start "apps"
    install_apps
    track_installation_end "apps" $?
}

install_monitoring_enhanced() {
    track_installation_start "monitoring"
    install_monitoring
    track_installation_end "monitoring" $?
}

install_dev_env_enhanced() {
    track_installation_start "dev_env"
    install_dev_env
    track_installation_end "dev_env" $?
}

install_scripts_enhanced() {
    track_installation_start "scripts"
    install_scripts
    track_installation_end "scripts" $?
}

# Track installation start
track_installation_start() {
    local component="$1"
    echo "$(date +%s):$component:start" >> "$CONFIG_DIR/install_tracking.log"
}

# Track installation end
track_installation_end() {
    local component="$1"
    local exit_code="$2"
    local status="success"
    
    if [ "$exit_code" -ne 0 ]; then
        status="failed"
    fi
    
    echo "$(date +%s):$component:$status:$exit_code" >> "$CONFIG_DIR/install_tracking.log"
    return $exit_code
}