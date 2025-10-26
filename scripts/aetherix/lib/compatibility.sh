#!/bin/bash

# Compatibility Library - Advanced system compatibility checking

# Check system compatibility
check_system_compatibility() {
    ui_info "🔍 Running comprehensive system compatibility check..."
    
    local issues=0
    local warnings=0
    local optimizations=()
    
    # Check OS version
    if ! check_os_compatibility; then
        issues=$((issues + 1))
    fi
    
    # Check hardware resources
    if ! check_hardware_resources; then
        warnings=$((warnings + 1))
    fi
    
    # Check network configuration
    if ! check_network_config; then
        warnings=$((warnings + 1))
    fi
    
    # Check existing software conflicts
    if ! check_software_conflicts; then
        warnings=$((warnings + 1))
    fi
    
    # Generate optimization suggestions
    local optimization_suggestions=$(generate_optimization_suggestions)
    
    # Show compatibility report
    show_compatibility_report $issues $warnings "$optimization_suggestions"
    
    return $issues
}

# Check OS compatibility
check_os_compatibility() {
    local os_info=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
    local kernel_version=$(uname -r)
    
    ui_info "Operating System: $os_info"
    ui_info "Kernel Version: $kernel_version"
    
    # Check for supported distributions
    if [[ "$os_info" =~ Ubuntu|Debian|CentOS|RHEL|Fedora ]]; then
        ui_success "✅ Supported operating system detected"
        return 0
    else
        ui_warning "⚠️ Unsupported OS. Some components may not work correctly."
        return 1
    fi
}

# Check hardware resources
check_hardware_resources() {
    local ram_gb=$(free -g | awk '/^Mem:/ {print $2}')
    local disk_gb=$(df / | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
    local cpu_cores=$(nproc)
    
    ui_info "System Resources:"
    ui_info "  • RAM: ${ram_gb}GB"
    ui_info "  • Available Disk: ${disk_gb}GB"
    ui_info "  • CPU Cores: $cpu_cores"
    
    local issues=0
    
    # Check RAM requirements
    local required_ram=$(calculate_required_ram)
    if [ $ram_gb -lt $required_ram ]; then
        ui_warning "⚠️ Low RAM: ${ram_gb}GB available, ${required_ram}GB recommended"
        issues=$((issues + 1))
    fi
    
    # Check disk space
    local required_disk=$(calculate_required_disk)
    if [ $disk_gb -lt $required_disk ]; then
        ui_warning "⚠️ Low disk space: ${disk_gb}GB available, ${required_disk}GB required"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Calculate required RAM based on selections
calculate_required_ram() {
    local required=2  # Base requirement
    
    for component in "${SELECTIONS[@]}"; do
        case "$component" in
            "docker") required=$((required + 2)) ;;
            "apps") required=$((required + 4)) ;;
            "dev_env") required=$((required + 2)) ;;
            "psql") required=$((required + 1)) ;;
        esac
    done
    
    echo $required
}

# Calculate required disk space
calculate_required_disk() {
    local required=5  # Base requirement in GB
    
    for component in "${SELECTIONS[@]}"; do
        case "$component" in
            "docker") required=$((required + 1)) ;;
            "apps") required=$((required + 3)) ;;
            "dev_env") required=$((required + 2)) ;;
            "psql") required=$((required + 1)) ;;
        esac
    done
    
    echo $required
}

# Check network configuration
check_network_config() {
    ui_info "🌐 Checking network configuration..."
    
    # Check internet connectivity
    if ! ping -c 1 google.com &>/dev/null; then
        ui_error "❌ No internet connection"
        return 1
    fi
    
    # Check DNS resolution
    if ! nslookup google.com &>/dev/null; then
        ui_warning "⚠️ DNS resolution issues detected"
        return 1
    fi
    
    # Check if ports are available
    check_port_availability
    
    ui_success "✅ Network configuration looks good"
    return 0
}

# Check port availability
check_port_availability() {
    local ports_to_check=()
    
    # Add ports based on selected components
    [[ " ${SELECTIONS[*]} " =~ "nginx" ]] && ports_to_check+=(80 443)
    [[ " ${SELECTIONS[*]} " =~ "psql" ]] && [[ "$PSQL_DOCKER" = true ]] && ports_to_check+=($DB_PORT)
    
    for port in "${ports_to_check[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            ui_warning "⚠️ Port $port is already in use"
        else
            ui_success "✅ Port $port is available"
        fi
    done
}

# Check for software conflicts
check_software_conflicts() {
    ui_info "🔍 Checking for software conflicts..."
    
    local conflicts=0
    
    # Check for conflicting web servers
    if [[ " ${SELECTIONS[*]} " =~ "nginx" ]]; then
        if systemctl is-active --quiet apache2 2>/dev/null; then
            ui_warning "⚠️ Apache2 is running. May conflict with Nginx."
            conflicts=$((conflicts + 1))
        fi
    fi
    
    # Check for existing Docker installations
    if [[ " ${SELECTIONS[*]} " =~ "docker" ]]; then
        if command -v docker &>/dev/null; then
            local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1)
            ui_info "ℹ️ Docker $docker_version is already installed"
        fi
    fi
    
    return $conflicts
}

# Generate optimization suggestions
generate_optimization_suggestions() {
    # Return suggestions as a string, one per line
    echo "Consider running 'sudo apt update && sudo apt upgrade' before installation"
    
    # Suggest memory optimizations
    local ram_gb=$(free -g | awk '/^Mem:/ {print $2}')
    if [ $ram_gb -lt 8 ]; then
        echo "Consider closing unnecessary applications to free up memory"
    fi
    
    # Suggest disk optimizations
    echo "Run 'sudo apt autoremove && sudo apt autoclean' to free up disk space"
    
    # Component-specific suggestions
    if [[ " ${SELECTIONS[*]} " =~ "docker" ]]; then
        echo "Consider adding your user to the docker group to avoid sudo requirements"
    fi
    
    if [[ " ${SELECTIONS[*]} " =~ "zsh" ]] && [ "$ZSH_DEFAULT" = true ]; then
        echo "You'll need to logout and login again after setting Zsh as default shell"
    fi
}

# Show compatibility report
show_compatibility_report() {
    local issues=$1
    local warnings=$2
    local optimizations="$3"
    
    echo ""
    gum style --border double --margin "1 0" --padding "1 2" --foreground 45 "📋 System Compatibility Report"
    
    if [ $issues -eq 0 ]; then
        ui_success "✅ No critical compatibility issues found"
    else
        ui_error "❌ Found $issues critical compatibility issues"
    fi
    
    if [ $warnings -gt 0 ]; then
        ui_warning "⚠️ Found $warnings warnings that may affect performance"
    fi
    
    if [ -n "$optimizations" ]; then
        echo ""
        ui_info "💡 Optimization Suggestions:"
        while IFS= read -r suggestion; do
            if [ -n "$suggestion" ]; then
                gum style --foreground 6 "  • $suggestion"
            fi
        done <<< "$optimizations"
    fi
    
    echo ""
}