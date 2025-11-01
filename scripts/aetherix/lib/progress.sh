#!/bin/bash

# Progress tracking and display functions

# Show progress bar for operations
show_progress() {
    local message="$1"
    local current="$2"
    local total="$3"

    if [ "$DEBUG" = true ]; then
        echo "[$current/$total] $message"
    else
        local percentage=$((current * 100 / total))
        gum style --foreground 45 "[$current/$total] $message"
        gum style --foreground 2 "$(printf '█%.0s' $(seq 1 $((percentage / 5))))$(printf '░%.0s' $(seq 1 $((20 - percentage / 5))))" --width 20
    fi
}

# Render progress bar
render_progress_bar() {
    local current=$1
    local total=$2
    local width=25 # Total width of bar

    local filled=$((current * width / total))
    local empty=$((width - filled))

    local bar=""
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = 0; i < empty; i++)); do bar+="░"; done

    gum style --foreground 45 "Progress: [$current/$total] $bar"
}

# Update component progress
update_component_progress() {
    local component="$1"
    local status="$2" # "starting", "completed", "skipped", "failed"

    case "$status" in
    "starting")
        CURRENT_OPERATION="$component"
        show_progress "Installing $component..." "$COMPLETED_COMPONENTS" "$TOTAL_COMPONENTS"
        log_message "INFO" "Starting installation of $component"
        ;;
    "completed")
        COMPLETED_COMPONENTS=$((COMPLETED_COMPONENTS + 1))
        gum style --foreground 2 "✅ [$(get_current_count)/$TOTAL_COMPONENTS] $component completed"
        log_message "SUCCESS" "$component completed"
        ;;
    "skipped")
        SKIPPED_COMPONENTS=$((SKIPPED_COMPONENTS + 1))
        gum style --foreground 3 "⏭️  [$(get_current_count)/$TOTAL_COMPONENTS] $component skipped"
        log_message "SKIP" "$component skipped"
        ;;
    "failed")
        FAILED_COMPONENTS=$((FAILED_COMPONENTS + 1))
        gum style --foreground 1 "❌ [$(get_current_count)/$TOTAL_COMPONENTS] $component failed"
        FAILED_LIST+=("$component")
        log_message "ERROR" "$component failed"
        ;;
    esac
}

# Count total components to install
count_total_components() {
    TOTAL_COMPONENTS=0
    
    local components=("docker" "nginx" "psql" "zsh" "vim" "apps" "monitoring" "dev_env" "scripts")
    
    for component in "${components[@]}"; do
        if is_selected "$component"; then
            TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + 1))
        fi
    done

    gum style --foreground 45 --bold "📊 Total components to install: $TOTAL_COMPONENTS"
}