#!/bin/bash

# Presets Library - Predefined configuration sets for different use cases

# Define preset configurations
declare -A PRESETS
declare -A PRESET_DESCRIPTIONS

# Web Developer preset
PRESETS["web_developer"]="nginx,zsh,vim,dev_env,apps"
PRESET_DESCRIPTIONS["web_developer"]="Perfect for web development with Nginx, Node.js, modern shell, and essential apps"

# DevOps Engineer preset  
PRESETS["devops"]="docker,nginx,psql,zsh,monitoring,scripts"
PRESET_DESCRIPTIONS["devops"]="Complete DevOps toolkit with containers, databases, monitoring, and automation scripts"

# Full Stack Developer preset
PRESETS["fullstack"]="docker,nginx,psql,zsh,vim,dev_env,apps,monitoring"
PRESET_DESCRIPTIONS["fullstack"]="Everything you need for full-stack development including databases, containers, and tools"

# Minimal Developer preset
PRESETS["minimal"]="zsh,vim,dev_env"
PRESET_DESCRIPTIONS["minimal"]="Lightweight setup with just the essentials: modern shell, editor, and development environment"

# System Administrator preset
PRESETS["sysadmin"]="docker,nginx,psql,monitoring,scripts"
PRESET_DESCRIPTIONS["sysadmin"]="System administration tools with containers, web server, database, and monitoring"

# Show available presets
show_presets() {
    ui_info "📋 Available Configuration Presets:"
    echo ""
    
    local presets=("web_developer" "devops" "fullstack" "minimal" "sysadmin" "custom")
    local descriptions=(
        "🌐 Web Developer - Nginx, Node.js, Zsh, Apps"
        "🔧 DevOps Engineer - Docker, Nginx, PostgreSQL, Monitoring"  
        "🚀 Full Stack - Complete development environment"
        "⚡ Minimal - Just the essentials"
        "🖥️  System Admin - Server management tools"
        "🎛️  Custom - Choose your own components"
    )
    
    for i in "${!presets[@]}"; do
        gum style --foreground 45 "  ${descriptions[$i]}"
    done
    echo ""
}

# Apply preset configuration
apply_preset() {
    local preset_name="$1"
    
    if [[ -z "${PRESETS[$preset_name]:-}" ]]; then
        ui_error "Unknown preset: $preset_name"
        return 1
    fi
    
    # Clear existing selections
    SELECTIONS=()
    
    # Parse preset components
    IFS=',' read -ra COMPONENTS <<< "${PRESETS[$preset_name]}"
    
    # Apply preset-specific configurations
    case "$preset_name" in
        "web_developer")
            apply_web_developer_preset
            ;;
        "devops")
            apply_devops_preset
            ;;
        "fullstack")
            apply_fullstack_preset
            ;;
        "minimal")
            apply_minimal_preset
            ;;
        "sysadmin")
            apply_sysadmin_preset
            ;;
    esac
    
    # Add components to selections
    for component in "${COMPONENTS[@]}"; do
        SELECTIONS+=("$component")
    done
    
    ui_success "Applied preset: $preset_name"
    show_preset_summary "$preset_name"
}

# Web Developer preset configuration
apply_web_developer_preset() {
    # Nginx configuration
    NGINX_AUTO=false
    
    # Development environment
    DEV_ENV_SELECTED="Node.js"
    NODE_VERSION="LTS"
    
    # Zsh configuration
    INSTALL_OH_MY_ZSH=true
    ZSH_THEME="agnoster"
    ZSH_DEFAULT=true
    INSTALL_ZSH_PLUGINS=true
    ZSH_PLUGINS_SELECTED="Auto Suggestions zsh-syntax-highlighting"
    
    # Apps
    DEV_TOOLS_SELECTED="VS_Code Postman Figma"
}

# DevOps preset configuration
apply_devops_preset() {
    # Docker configuration
    DOCKER_VERSION="Latest"
    DOCKER_AUTOSTART=true
    
    # PostgreSQL configuration
    PSQL_VERSION="14"
    PSQL_DOCKER=true
    DB_NAME="devdb"
    DB_USER="devuser"
    DB_PORT="5432"
    
    # Nginx configuration
    NGINX_AUTO=false
    
    # Zsh configuration
    INSTALL_OH_MY_ZSH=true
    ZSH_THEME="robbyrussell"
    ZSH_DEFAULT=true
    INSTALL_ZSH_PLUGINS=true
    ZSH_PLUGINS_SELECTED="Auto Suggestions zsh-syntax-highlighting"
    
    # Monitoring tools
    MONITOR_TOOLS_SELECTED="htop NeoHtop"
    
    # Scripts
    SCRIPTS_SELECTED="Nginx DB_manager"
}

# Full Stack preset configuration
apply_fullstack_preset() {
    # Combine web developer and devops configurations
    apply_web_developer_preset
    
    # Add DevOps components
    DOCKER_VERSION="Latest"
    DOCKER_AUTOSTART=true
    PSQL_VERSION="14"
    PSQL_DOCKER=true
    DB_NAME="devdb"
    DB_USER="devuser"
    DB_PORT="5432"
    MONITOR_TOOLS_SELECTED="htop"
    
    # Enhanced development environment
    DEV_ENV_SELECTED="Node.js Python"
    PYTHON_VENV=true
}

# Minimal preset configuration
apply_minimal_preset() {
    # Zsh configuration
    INSTALL_OH_MY_ZSH=true
    ZSH_THEME="robbyrussell"
    ZSH_DEFAULT=true
    INSTALL_ZSH_PLUGINS=false
    
    # Development environment
    DEV_ENV_SELECTED="Node.js"
    NODE_VERSION="LTS"
}

# System Admin preset configuration
apply_sysadmin_preset() {
    # Docker configuration
    DOCKER_VERSION="Latest"
    DOCKER_AUTOSTART=true
    
    # PostgreSQL configuration
    PSQL_VERSION="14"
    PSQL_DOCKER=false  # Native installation for production
    DB_NAME="admindb"
    DB_USER="admin"
    
    # Nginx configuration
    NGINX_AUTO=false
    
    # Monitoring tools
    MONITOR_TOOLS_SELECTED="htop NeoHtop"
    
    # Scripts
    SCRIPTS_SELECTED="Nginx DB_manager"
}

# Show preset summary
show_preset_summary() {
    local preset_name="$1"
    
    ui_info "📋 Preset Configuration Summary:"
    ui_info "Selected: $preset_name"
    ui_info "Components: $(IFS=', '; echo "${SELECTIONS[*]}")"
    ui_info "Estimated size: $(calculate_total_size)"
    echo ""
}

# Interactive preset selection
select_preset() {
    show_presets
    
    local preset_choice=$(gum choose \
        "🌐 Web Developer" \
        "🔧 DevOps Engineer" \
        "🚀 Full Stack Developer" \
        "⚡ Minimal Setup" \
        "🖥️  System Administrator" \
        "🎛️  Custom Configuration")
    
    case "$preset_choice" in
        "🌐 Web Developer") apply_preset "web_developer" ;;
        "🔧 DevOps Engineer") apply_preset "devops" ;;
        "🚀 Full Stack Developer") apply_preset "fullstack" ;;
        "⚡ Minimal Setup") apply_preset "minimal" ;;
        "🖥️  System Administrator") apply_preset "sysadmin" ;;
        "🎛️  Custom Configuration") return 1 ;;  # Continue with custom configuration
    esac
    
    return 0
}