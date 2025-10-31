#!/bin/bash

# UI Library - User interface and display functions

# Color and styling functions
ui_success() {
    gum style --foreground 2 "✅ $1"
}

ui_error() {
    gum style --foreground 1 "❌ $1"
}

ui_warning() {
    gum style --foreground 3 "⚠️  $1"
}

ui_info() {
    gum style --foreground 45 "$1"
}

ui_dry_run() {
    gum style --foreground 3 "🧪 [DRY RUN] $1"
}

# Display header
show_header() {
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 80 --margin "1 2" --padding "1 2" \
        "👽 AWAKENING THE ALTARS: NICRONIAN SYSTEM PREPARATION 🌠"

    gum style --foreground 7 "👽🪐🌌 Welcome, traveler. You have arrived on Nicron, a sacred planet where the ancient race of the Nicronians will guide you in preparing your environment. Through the essence of the Creator's light, we shall install Docker, PostgreSQL, Nginx, Zsh, and other tools essential for your path ahead."
    echo ""
}

# Show configuration summary
show_summary() {
    ui_info "📝 Components selected:"
    for item in "${SELECTIONS[@]}"; do
        ui_success "   └── • $item"
    done
}

# Show installation preview
show_installation_preview() {
    echo ""
    gum style --border double --margin "1 0" --padding "1 2" --foreground 45 "📋 Detailed Installation Preview"
    
    # Component details table
    ui_info "📦 Components to install: ${#SELECTIONS[@]}"
    echo ""
    gum style --foreground 6 --bold "Component                Size      Time      Description"
    gum style --foreground 7 "─────────────────────────────────────────────────────────────────"
    
    for component in "${SELECTIONS[@]}"; do
        local size=$(get_component_size "$component")
        local time=$(get_component_install_time "$component")
        local desc=""
        
        case "$component" in
            "docker") desc="Container platform" ;;
            "nginx") desc="Web server" ;;
            "psql") desc="Database system" ;;
            "zsh") desc="Modern shell" ;;
            "vim") desc="Text editor" ;;
            "apps") desc="Development tools" ;;
            "monitoring") desc="System monitoring" ;;
            "dev_env") desc="Programming languages" ;;
            "scripts") desc="Automation scripts" ;;
        esac
        
        printf "%-20s %-9s %-9s %s\n" "$component" "$size" "$time" "$desc" | gum style --foreground 2
    done
    
    echo ""
    gum style --foreground 7 "─────────────────────────────────────────────────────────────────"
    
    # Summary information
    local total_size=$(calculate_total_size)
    local total_time=$(calculate_total_time)
    local network_speed=$(get_network_speed)
    
    ui_info "📊 Installation Summary:"
    gum style --foreground 45 "  • Total Size: $total_size"
    gum style --foreground 45 "  • Estimated Time: $total_time"
    gum style --foreground 45 "  • Network Speed: $network_speed"
    gum style --foreground 45 "  • Installation Log: $LOG_FILE"
    
    # System requirements check
    echo ""
    ui_info "🖥️  System Requirements:"
    local available_space=$(df / | awk 'NR==2 {printf "%.1fGB", $4/1024/1024}')
    local available_memory=$(free -h | awk '/^Mem:/ {print $7}')
    
    gum style --foreground 3 "  • Available Disk Space: $available_space"
    gum style --foreground 3 "  • Available Memory: $available_memory"
    
    # Warnings and recommendations
    echo ""
    ui_info "⚠️  Important Notes:"
    gum style --foreground 3 "  • Installation requires sudo privileges"
    gum style --foreground 3 "  • Some components may require logout/login"
    gum style --foreground 3 "  • Network connection required for downloads"
    
    if [[ " ${SELECTIONS[*]} " =~ "docker" ]]; then
        gum style --foreground 3 "  • Docker requires user group changes (logout needed)"
    fi
    
    if [[ " ${SELECTIONS[*]} " =~ "zsh" ]] && [ "$ZSH_DEFAULT" = true ]; then
        gum style --foreground 3 "  • Zsh will become your default shell"
    fi
    
    echo ""
}

# Show spacer
show_spacer() {
    gum style --foreground 7 "        "
}

# Print section title
print_section_title() {
    local title="$1"
    gum style --border double --margin "1 0" --padding "0 2" --foreground 212 "🔹 $title"
}

# Print success box
print_success_box() {
    local message="$1"
    gum style --border normal --margin "1 0" --padding "0 2" --foreground 2 "✅ $message"
}

# Print error box
print_error_box() {
    local message="$1"
    gum style --border normal --margin "1 0" --padding "0 2" --foreground 1 "❌ $message"
}

# Show multi-choice selection with formatting
show_multi_choice() {
    local title="$1"
    local -n options_ref=$2
    local -n selected_ref=$3
    
    ui_info "$title"
    
    # Store the output in an array
    readarray -t selected_array < <(gum choose --no-limit "${options_ref[@]}")
    
    # Convert the array to a space-separated string
    selected_ref=$(printf "%s " "${selected_array[@]}")
    
    # Handle the "All" option
    if [[ "$selected_ref" == *"All"* ]]; then
        # Remove "All" from the array and add all other options
        local all_options=""
        for option in "${options_ref[@]}"; do
            if [ "$option" != "All" ]; then
                all_options+="$option "
            fi
        done
        selected_ref="$all_options"
    fi
}

# Show component configuration details (deprecated - now shown inline)
show_component_details() {
    # This function is kept for backward compatibility but is no longer used
    # Details are now shown inline during configuration
    return 0
}

# Show final summary
show_final_summary() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - START_TIME))

    echo ""
    gum style --foreground 6 --bold "📦 Installation Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Completed:  $COMPLETED_COMPONENTS / $TOTAL_COMPONENTS"
    echo "❌ Failed:     $FAILED_COMPONENTS"
    echo "⏭️  Skipped:    $SKIPPED_COMPONENTS"
    echo "🕒 Duration:   ${elapsed}s"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ ${#FAILED_LIST[@]} -gt 0 ]; then
        echo "Failed components:"
        for failed in "${FAILED_LIST[@]}"; do
            echo "  - $failed"
        done
    fi
}

# Show post-install dashboard
show_post_install_dashboard() {
    local choices=(
        "🔁 Retry Failed Components" 
        "🏥 Run Health Check" 
        "📊 Generate Report"
        "📋 Manage Templates"
        "🔙 Rollback Installation"
        "📂 Open Config Folder" 
        "📄 View Log File" 
        "❌ Exit"
    )
    local choice

    while true; do
        choice=$(gum choose --header="🎛️ What would you like to do next?" "${choices[@]}")

        case "$choice" in
        "🔁 Retry Failed Components")
            retry_failed_components
            ;;
        "🏥 Run Health Check")
            run_health_check
            ;;
        "📊 Generate Report")
            generate_health_report
            ui_info "Report generated successfully!"
            ;;
        "📋 Manage Templates")
            manage_templates
            ;;
        "🔙 Rollback Installation")
            show_rollback_menu
            ;;
        "📂 Open Config Folder")
            xdg-open "$CONFIG_DIR" >/dev/null 2>&1 || echo "📂 Config path: $CONFIG_DIR"
            ;;
        "📄 View Log File")
            gum pager <"$LOG_FILE"
            ;;
        "❌ Exit")
            echo "👋 Exiting. May the Source be with you!"
            break
            ;;
        esac
    done
}

# Retry failed components
retry_failed_components() {
    if [ ${#FAILED_LIST[@]} -eq 0 ]; then
        ui_info "No failed components to retry"
        return
    fi
    
    ui_info "Retrying failed components..."
    for component in "${FAILED_LIST[@]}"; do
        ui_info "Retrying $component..."
        # This would call the appropriate installer function
        # install_${component,,}
    done
}