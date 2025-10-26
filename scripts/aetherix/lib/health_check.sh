#!/bin/bash

# Health Check Library - Post-installation verification and monitoring

# Check if a service is running
check_service_status() {
    local service_name="$1"
    if systemctl is-active --quiet "$service_name"; then
        ui_success "$service_name is running"
        return 0
    else
        ui_error "$service_name is not running"
        return 1
    fi
}

# Check if a command/binary is available and working
check_command_health() {
    local command_name="$1"
    local test_command="$2"
    
    if command -v "$command_name" &> /dev/null; then
        if [ -n "$test_command" ]; then
            if eval "$test_command" &> /dev/null; then
                ui_success "$command_name is installed and working"
                return 0
            else
                ui_warning "$command_name is installed but may not be working correctly"
                return 1
            fi
        else
            ui_success "$command_name is installed"
            return 0
        fi
    else
        ui_error "$command_name is not installed"
        return 1
    fi
}

# Check Docker health
check_docker_health() {
    ui_info "🐳 Checking Docker health..."
    
    check_command_health "docker" "docker --version"
    check_service_status "docker"
    
    # Check if user is in docker group
    if groups $USER | grep -qw docker; then
        ui_success "User is in docker group"
    else
        ui_warning "User is not in docker group. You may need to logout and login again."
    fi
    
    # Test docker functionality
    if docker ps &> /dev/null; then
        ui_success "Docker is functional"
    else
        ui_warning "Docker may not be fully functional"
    fi
}

# Check Nginx health
check_nginx_health() {
    ui_info "🕸️ Checking Nginx health..."
    
    check_command_health "nginx" "nginx -t"
    check_service_status "nginx"
    
    # Check if nginx is listening on port 80
    if netstat -tuln | grep -q ":80 "; then
        ui_success "Nginx is listening on port 80"
    else
        ui_warning "Nginx may not be listening on port 80"
    fi
}

# Check PostgreSQL health
check_postgresql_health() {
    ui_info "🐘 Checking PostgreSQL health..."
    
    if [ "${PSQL_DOCKER:-false}" = true ]; then
        # Check Docker container
        if docker ps | grep -q "postgres-$PSQL_VERSION"; then
            ui_success "PostgreSQL container is running"
            
            # Test connection
            if docker exec "postgres-$PSQL_VERSION" pg_isready &> /dev/null; then
                ui_success "PostgreSQL is accepting connections"
            else
                ui_warning "PostgreSQL may not be accepting connections"
            fi
        else
            ui_error "PostgreSQL container is not running"
        fi
    else
        # Check native installation
        check_service_status "postgresql"
        check_command_health "psql" "psql --version"
        
        # Test connection
        if sudo -u postgres psql -c "SELECT 1;" &> /dev/null; then
            ui_success "PostgreSQL is accepting connections"
        else
            ui_warning "PostgreSQL may not be accepting connections"
        fi
    fi
}

# Check Zsh health
check_zsh_health() {
    ui_info "🐚 Checking Zsh health..."
    
    check_command_health "zsh" "zsh --version"
    
    # Check if zsh is default shell
    if [ "$(basename "$SHELL")" = "zsh" ]; then
        ui_success "Zsh is the default shell"
    else
        ui_info "Zsh is installed but not the default shell"
    fi
    
    # Check Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        ui_success "Oh My Zsh is installed"
    else
        ui_info "Oh My Zsh is not installed"
    fi
}

# Check development environment health
check_dev_env_health() {
    ui_info "💻 Checking development environment health..."
    
    if [[ "${DEV_ENV_SELECTED:-}" == *"Node.js"* ]]; then
        check_command_health "node" "node --version"
        check_command_health "npm" "npm --version"
    fi
    
    if [[ "${DEV_ENV_SELECTED:-}" == *"Python"* ]]; then
        check_command_health "python3" "python3 --version"
        check_command_health "pip3" "pip3 --version"
        
        if [ "${PYTHON_VENV:-false}" = true ] && [ -d "$HOME/.venv" ]; then
            ui_success "Python virtual environment is set up"
        fi
    fi
}

# Run comprehensive health check
run_health_check() {
    ui_info "🏥 Running post-installation health check..."
    echo ""
    
    local health_issues=0
    
    # Check each installed component
    for component in "${SELECTIONS[@]}"; do
        case "$component" in
            "docker")
                if ! check_docker_health; then
                    health_issues=$((health_issues + 1))
                fi
                ;;
            "nginx")
                if ! check_nginx_health; then
                    health_issues=$((health_issues + 1))
                fi
                ;;
            "psql")
                if ! check_postgresql_health; then
                    health_issues=$((health_issues + 1))
                fi
                ;;
            "zsh")
                if ! check_zsh_health; then
                    health_issues=$((health_issues + 1))
                fi
                ;;
            "vim")
                check_command_health "vim" "vim --version"
                ;;
            "dev_env")
                if ! check_dev_env_health; then
                    health_issues=$((health_issues + 1))
                fi
                ;;
        esac
        echo ""
    done
    
    # Summary
    if [ $health_issues -eq 0 ]; then
        ui_success "🎉 All components are healthy!"
    else
        ui_warning "⚠️ Found $health_issues potential issues. Check the details above."
    fi
    
    return $health_issues
}

# Generate health report
generate_health_report() {
    local report_file="$CONFIG_DIR/health_report.txt"
    
    {
        echo "Nicronian Setup Health Report"
        echo "Generated: $(date)"
        echo "================================"
        echo ""
        echo "Installed Components:"
        for component in "${SELECTIONS[@]}"; do
            echo "  - $component"
        done
        echo ""
        echo "System Information:"
        echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
        echo "  Kernel: $(uname -r)"
        echo "  Architecture: $(uname -m)"
        echo "  Available Memory: $(free -h | awk '/^Mem:/ {print $7}')"
        echo "  Available Disk: $(df -h / | awk 'NR==2 {print $4}')"
        echo ""
    } > "$report_file"
    
    ui_success "Health report saved to: $report_file"
}