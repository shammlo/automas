#!/bin/bash

# Enhanced Progress Library - Advanced progress tracking with ETA

# Progress tracking variables
INSTALL_START_TIME=0
CURRENT_COMPONENT_START=0
ESTIMATED_TOTAL_TIME=0

# Initialize progress tracking
init_progress_tracking() {
    INSTALL_START_TIME=$(date +%s)
    ESTIMATED_TOTAL_TIME=$(calculate_total_time_seconds)
    
    ui_info "🚀 Starting installation of ${#SELECTIONS[@]} components"
    ui_info "📊 Estimated total time: $(format_seconds $ESTIMATED_TOTAL_TIME)"
}

# Calculate total time in seconds
calculate_total_time_seconds() {
    local total_seconds=0
    
    for component in "${SELECTIONS[@]}"; do
        case "$component" in
            "docker") total_seconds=$((total_seconds + 240)) ;;  # 4 min
            "nginx") total_seconds=$((total_seconds + 90)) ;;    # 1.5 min
            "psql") total_seconds=$((total_seconds + 180)) ;;    # 3 min
            "zsh") total_seconds=$((total_seconds + 150)) ;;     # 2.5 min
            "vim") total_seconds=$((total_seconds + 60)) ;;      # 1 min
            "apps") total_seconds=$((total_seconds + 450)) ;;    # 7.5 min
            "monitoring") total_seconds=$((total_seconds + 90)) ;; # 1.5 min
            "dev_env") total_seconds=$((total_seconds + 360)) ;; # 6 min
            "scripts") total_seconds=$((total_seconds + 60)) ;;  # 1 min
        esac
    done
    
    echo $total_seconds
}

# Format seconds to human readable
format_seconds() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    
    if [ $minutes -gt 0 ]; then
        echo "${minutes}m ${remaining_seconds}s"
    else
        echo "${seconds}s"
    fi
}

# Start component installation
start_component_progress() {
    local component="$1"
    CURRENT_COMPONENT_START=$(date +%s)
    
    local current_time=$(date +%s)
    local elapsed=$((current_time - INSTALL_START_TIME))
    local remaining=$((ESTIMATED_TOTAL_TIME - elapsed))
    
    if [ $remaining -lt 0 ]; then
        remaining=0
    fi
    
    ui_info "🔧 Installing $component..."
    ui_info "⏱️  ETA: $(format_seconds $remaining) remaining"
    
    # Show progress bar
    local progress=$((elapsed * 100 / ESTIMATED_TOTAL_TIME))
    if [ $progress -gt 100 ]; then
        progress=100
    fi
    
    show_progress_bar $progress
}

# Show progress bar
show_progress_bar() {
    local percentage=$1
    local filled=$((percentage / 5))
    local empty=$((20 - filled))
    
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    gum style --foreground 45 "Progress: [$percentage%] $bar"
}

# Complete component installation
complete_component_progress() {
    local component="$1"
    local current_time=$(date +%s)
    local component_time=$((current_time - CURRENT_COMPONENT_START))
    
    ui_success "✅ $component completed in $(format_seconds $component_time)"
}

# Show final installation summary
show_installation_summary() {
    local end_time=$(date +%s)
    local total_time=$((end_time - INSTALL_START_TIME))
    
    echo ""
    gum style --border double --margin "1 0" --padding "1 2" --foreground 2 "🎉 Installation Complete!"
    
    ui_info "📊 Installation Summary:"
    ui_info "  • Total components: ${#SELECTIONS[@]}"
    ui_info "  • Completed: $COMPLETED_COMPONENTS"
    ui_info "  • Failed: $FAILED_COMPONENTS"
    ui_info "  • Total time: $(format_seconds $total_time)"
    ui_info "  • Average per component: $(format_seconds $((total_time / ${#SELECTIONS[@]})))"
    
    if [ $total_time -lt $ESTIMATED_TOTAL_TIME ]; then
        local saved=$((ESTIMATED_TOTAL_TIME - total_time))
        ui_success "⚡ Finished $(format_seconds $saved) faster than estimated!"
    fi
}