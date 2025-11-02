#!/bin/bash

# Validation Library - Input validation and system checks

# Validate email format
validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate port number
validate_port() {
    local port="$1"
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

# Check available disk space (in GB)
check_disk_space() {
    local required_gb="$1"
    local available_gb=$(df / | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
    
    if [ "$available_gb" -ge "$required_gb" ]; then
        return 0
    else
        ui_warning "Insufficient disk space. Required: ${required_gb}GB, Available: ${available_gb}GB"
        return 1
    fi
}

# Check internet connectivity
check_internet() {
    if ping -c 1 google.com &> /dev/null || ping -c 1 8.8.8.8 &> /dev/null; then
        return 0
    else
        ui_error "No internet connection detected. Please check your network."
        return 1
    fi
}

# Validate system requirements
validate_system_requirements() {
    local requirements_met=true
    
    # Check OS
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        ui_error "This script is designed for Linux systems only"
        requirements_met=false
    fi
    
    # Check if running as root (should not be)
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        ui_error "Please do not run this script as root"
        requirements_met=false
    fi
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        ui_warning "This script requires sudo access. You may be prompted for your password."
    fi
    
    # Check disk space (minimum 5GB)
    if ! check_disk_space 5; then
        requirements_met=false
    fi
    
    # Check internet connectivity
    if ! check_internet; then
        requirements_met=false
    fi
    
    if [ "$requirements_met" = false ]; then
        ui_error "System requirements not met. Please resolve the issues above."
        return 1
    fi
    
    ui_success "System requirements validated"
    return 0
}

# Estimate installation size for components
get_component_size() {
    local component="$1"
    case "$component" in
        "docker") echo "500MB" ;;
        "nginx") echo "50MB" ;;
        "psql") echo "200MB" ;;
        "zsh") echo "50MB" ;;
        "vim") echo "30MB" ;;
        "apps") echo "2GB" ;;
        "monitoring") echo "100MB" ;;
        "dev_env") echo "1GB" ;;
        "scripts") echo "10MB" ;;
        *) echo "Unknown" ;;
    esac
}

# Estimate installation time for components (in minutes)
get_component_install_time() {
    local component="$1"
    case "$component" in
        "docker") echo "3-5 min" ;;
        "nginx") echo "1-2 min" ;;
        "psql") echo "2-4 min" ;;
        "zsh") echo "2-3 min" ;;
        "vim") echo "1 min" ;;
        "apps") echo "5-10 min" ;;
        "monitoring") echo "1-2 min" ;;
        "dev_env") echo "4-8 min" ;;
        "scripts") echo "1 min" ;;
        *) echo "Unknown" ;;
    esac
}

# Calculate total installation time
calculate_total_time() {
    local total_min=0
    local max_total_min=0
    
    for component in "${SELECTIONS[@]}"; do
        case "$component" in
            "docker") total_min=$((total_min + 3)); max_total_min=$((max_total_min + 5)) ;;
            "nginx") total_min=$((total_min + 1)); max_total_min=$((max_total_min + 2)) ;;
            "psql") total_min=$((total_min + 2)); max_total_min=$((max_total_min + 4)) ;;
            "zsh") total_min=$((total_min + 2)); max_total_min=$((max_total_min + 3)) ;;
            "vim") total_min=$((total_min + 1)); max_total_min=$((max_total_min + 1)) ;;
            "apps") total_min=$((total_min + 5)); max_total_min=$((max_total_min + 10)) ;;
            "monitoring") total_min=$((total_min + 1)); max_total_min=$((max_total_min + 2)) ;;
            "dev_env") total_min=$((total_min + 4)); max_total_min=$((max_total_min + 8)) ;;
            "scripts") total_min=$((total_min + 1)); max_total_min=$((max_total_min + 1)) ;;
        esac
    done
    
    echo "${total_min}-${max_total_min} minutes"
}

# Get network speed estimate
get_network_speed() {
    local test_url="http://speedtest.ftp.otenet.gr/files/test1Mb.db"
    local start_time=$(date +%s.%N)
    
    if curl -s --max-time 5 "$test_url" > /dev/null 2>&1; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "5")
        local speed=$(echo "scale=1; 1 / $duration" | bc 2>/dev/null || echo "0.2")
        echo "${speed} MB/s"
    else
        echo "Unknown"
    fi
}

# Calculate total installation size
calculate_total_size() {
    local total_mb=0
    
    for component in "${SELECTIONS[@]}"; do
        case "$component" in
            "docker") total_mb=$((total_mb + 500)) ;;
            "nginx") total_mb=$((total_mb + 50)) ;;
            "psql") total_mb=$((total_mb + 200)) ;;
            "zsh") total_mb=$((total_mb + 20)) ;;
            "vim") total_mb=$((total_mb + 30)) ;;
            "apps") total_mb=$((total_mb + 2000)) ;;
            "monitoring") total_mb=$((total_mb + 100)) ;;
            "dev_env") total_mb=$((total_mb + 1000)) ;;
            "scripts") total_mb=$((total_mb + 10)) ;;
        esac
    done
    
    if [ $total_mb -gt 1024 ]; then
        echo "$((total_mb / 1024))GB"
    else
        echo "${total_mb}MB"
    fi
}