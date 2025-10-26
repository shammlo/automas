#!/bin/bash

# Help Library - Interactive component descriptions and help system

# Get component description
get_component_description() {
    local component="$1"
    case "$component" in
        "docker") echo "🐳 Docker - Containerization platform for packaging applications" ;;
        "nginx") echo "🕸️ Nginx - High-performance web server and reverse proxy" ;;
        "psql") echo "🐘 PostgreSQL - Advanced open-source relational database" ;;
        "zsh") echo "🐚 Zsh - Modern shell with advanced features" ;;
        "vim") echo "📝 Vim - Powerful text editor for developers" ;;
        "apps") echo "🛠️ Development Apps - Essential development tools" ;;
        "monitoring") echo "📊 Monitoring Tools - System performance monitoring" ;;
        "dev_env") echo "💻 Development Environment - Programming languages and tools" ;;
        "scripts") echo "📜 Development Scripts - Automation and utility scripts" ;;
        *) echo "Unknown component" ;;
    esac
}

# Get component benefits
get_component_benefits() {
    local component="$1"
    case "$component" in
        "docker") echo "• Consistent environments across development/production
• Easy application deployment and scaling
• Isolated application dependencies
• Simplified CI/CD workflows" ;;
        "nginx") echo "• Fast static file serving
• Load balancing capabilities
• SSL/TLS termination
• Reverse proxy for applications" ;;
        "psql") echo "• ACID compliance and reliability
• Advanced SQL features
• JSON support for modern apps
• Excellent performance and scalability" ;;
        "zsh") echo "• Auto-completion and suggestions
• Powerful theming system
• Plugin ecosystem
• Better scripting capabilities" ;;
        "vim") echo "• Efficient text editing
• Extensive plugin system
• Works over SSH
• Highly customizable" ;;
        "apps") echo "• VS Code for modern development
• Postman for API testing
• PyCharm for Python development
• Figma for design collaboration" ;;
        "monitoring") echo "• Real-time system monitoring
• Process management
• Resource usage tracking
• Performance optimization insights" ;;
        "dev_env") echo "• Node.js for JavaScript development
• Python for scripting and apps
• Package managers (npm, pip)
• Virtual environments for isolation" ;;
        "scripts") echo "• Automated common tasks
• Database management utilities
• Nginx configuration helpers
• Development workflow automation" ;;
        *) echo "No benefits information available" ;;
    esac
}

# Get component requirements
get_component_requirements() {
    local component="$1"
    case "$component" in
        "docker") echo "• 4GB RAM minimum
• 64-bit Linux kernel 3.10+
• Internet connection for image downloads" ;;
        "nginx") echo "• 512MB RAM minimum
• Port 80/443 available
• Basic networking knowledge helpful" ;;
        "psql") echo "• 1GB RAM minimum for production
• 100MB+ disk space
• Understanding of SQL basics" ;;
        "zsh") echo "• Basic terminal knowledge
• 50MB disk space
• Compatible with bash scripts" ;;
        "vim") echo "• Learning curve investment
• 30MB disk space
• Basic text editing knowledge" ;;
        "apps") echo "• 4GB RAM minimum
• 2GB+ disk space
• GUI desktop environment" ;;
        "monitoring") echo "• Minimal system impact
• 100MB disk space
• Basic system administration knowledge" ;;
        "dev_env") echo "• 2GB RAM minimum
• 1GB+ disk space
• Programming knowledge helpful" ;;
        "scripts") echo "• Basic scripting knowledge
• 50MB disk space
• Understanding of target tools" ;;
        *) echo "No requirements information available" ;;
    esac
}

# Show component help
show_component_help() {
    local component="$1"
    
    local description=$(get_component_description "$component")
    local benefits=$(get_component_benefits "$component")
    local requirements=$(get_component_requirements "$component")
    
    if [ "$description" = "Unknown component" ]; then
        ui_warning "No help available for component: $component"
        return 1
    fi
    
    gum style --border double --margin "1 0" --padding "1 2" --foreground 45 "$description"
    
    echo ""
    gum style --foreground 2 --bold "✨ Benefits:"
    echo "$benefits"
    
    echo ""
    gum style --foreground 3 --bold "📋 Requirements:"
    echo "$requirements"
    
    echo ""
    gum style --foreground 6 --bold "💾 Estimated Size: $(get_component_size "$component")"
    gum style --foreground 6 --bold "⏱️ Install Time: $(get_component_install_time "$component")"
    echo ""
}

# Interactive help menu
show_interactive_help() {
    while true; do
        local choice=$(gum choose --header="❓ Component Help - Select for details:" \
            "Docker" \
            "Nginx" \
            "PostgreSQL" \
            "Zsh" \
            "Vim" \
            "Development Apps" \
            "Monitoring Tools" \
            "Development Environment" \
            "Development Scripts" \
            "Back to Configuration")
        
        case "$choice" in
            "Docker")
                show_component_help "docker"
                ;;
            "Nginx")
                show_component_help "nginx"
                ;;
            "PostgreSQL")
                show_component_help "psql"
                ;;
            "Zsh")
                show_component_help "zsh"
                ;;
            "Vim")
                show_component_help "vim"
                ;;
            "Development Apps")
                show_component_help "apps"
                ;;
            "Monitoring Tools")
                show_component_help "monitoring"
                ;;
            "Development Environment")
                show_component_help "dev_env"
                ;;
            "Development Scripts")
                show_component_help "scripts"
                ;;
            "Back to Configuration")
                break
                ;;
            *)
                ui_error "Unknown selection: $choice"
                ;;
        esac
        
        if ! gum confirm "View another component?"; then
            break
        fi
    done
}

# Quick help for a component during configuration
show_quick_help() {
    local component="$1"
    
    local description=$(get_component_description "$component")
    if [ "$description" != "Unknown component" ]; then
        gum style --foreground 45 "💡 $description"
        gum style --foreground 6 "Size: $(get_component_size "$component") | Time: $(get_component_install_time "$component")"
    fi
}