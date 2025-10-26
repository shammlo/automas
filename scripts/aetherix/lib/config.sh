#!/bin/bash

# Configuration Library - Handles saving and loading configurations

# Save configuration to file
save_config() {
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"

    # Save selected components and their configurations
    {
        echo "SELECTIONS=(${SELECTIONS[*]})"

        # Save component-specific configurations
        is_selected "nginx" && save_nginx_config
        is_selected "docker" && save_docker_config
        is_selected "psql" && save_postgresql_config
        is_selected "zsh" && save_zsh_config
        is_selected "git" && save_git_config
        is_selected "monitoring" && save_monitoring_config
        is_selected "dev_env" && save_dev_env_config
        is_selected "apps" && save_apps_config
        is_selected "scripts" && save_scripts_config
    } >"$CONFIG_FILE"

    ui_success "Configuration saved to $CONFIG_FILE"
    log_message "INFO" "Configuration saved to $CONFIG_FILE"
}

# Individual component config savers
save_nginx_config() {
    echo "NGINX_AUTO=$NGINX_AUTO"
    [[ "$NGINX_AUTO" = true ]] && echo "NGINX_PROJECT=$NGINX_PROJECT"
}

save_docker_config() {
    echo "DOCKER_VERSION=$DOCKER_VERSION"
    echo "DOCKER_AUTOSTART=$DOCKER_AUTOSTART"
}

save_postgresql_config() {
    echo "PSQL_VERSION=$PSQL_VERSION"
    echo "PSQL_DOCKER=$PSQL_DOCKER"
    echo "DB_NAME=$DB_NAME"
    echo "DB_USER=$DB_USER"
    [[ "$PSQL_DOCKER" = true ]] && echo "DB_PORT=$DB_PORT"
}

save_zsh_config() {
    echo "INSTALL_OH_MY_ZSH=$INSTALL_OH_MY_ZSH"
    [[ "$INSTALL_OH_MY_ZSH" = true ]] && echo "ZSH_THEME=$ZSH_THEME"
    echo "ZSH_DEFAULT=$ZSH_DEFAULT"
    echo "INSTALL_ZSH_PLUGINS=$INSTALL_ZSH_PLUGINS"
    [[ "$INSTALL_ZSH_PLUGINS" = true ]] && echo "ZSH_PLUGINS_SELECTED=\"$ZSH_PLUGINS_SELECTED\""
}

save_git_config() {
    echo "GIT_CONFIG=$GIT_CONFIG"
    [[ "$GIT_CONFIG" = true ]] && {
        echo "GIT_NAME=\"$GIT_NAME\""
        echo "GIT_EMAIL=\"$GIT_EMAIL\""
    }
}

save_monitoring_config() {
    echo "MONITOR_TOOLS_SELECTED=\"$MONITOR_TOOLS_SELECTED\""
}

save_dev_env_config() {
    echo "DEV_ENV_SELECTED=\"$DEV_ENV_SELECTED\""
    [[ "$DEV_ENV_SELECTED" == *"Node.js"* ]] && echo "NODE_VERSION=$NODE_VERSION"
    [[ "$DEV_ENV_SELECTED" == *"Python"* ]] && echo "PYTHON_VENV=$PYTHON_VENV"
}

save_apps_config() {
    echo "DEV_TOOLS_SELECTED=\"$DEV_TOOLS_SELECTED\""
}

save_scripts_config() {
    echo "SCRIPTS_SELECTED=\"$SCRIPTS_SELECTED\""
}

# Load configuration from file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Source the configuration file
        source "$CONFIG_FILE"
        ui_success "Configuration loaded from $CONFIG_FILE"
        log_message "INFO" "Configuration loaded from $CONFIG_FILE"
        return 0
    else
        ui_warning "No saved configuration found."
        return 1
    fi
}

# Collect all component configurations
collect_configurations() {
    # Offer to load previous configuration
    if [[ -f "$CONFIG_FILE" ]]; then
        if gum confirm "⚙️  Load previous configuration?"; then
            load_config
            show_summary
            return
        fi
    fi

    # Define component configuration mapping
    local -A component_configs=(
        ["🕸️  Install Nginx?"]="configure_nginx"
        ["🐳 Install Docker?"]="configure_docker"
        ["🐘 Install PostgreSQL?"]="configure_postgresql"
        ["🐚 Install Zsh?"]="configure_zsh"
        ["📝 Install Vim?"]="configure_vim"
        ["🛠️  Install apps?"]="configure_apps"
        ["📊 Install system monitoring tools?"]="configure_monitoring"
        ["💻 Install development environments?"]="configure_dev_env"
        ["📜 Install development scripts?"]="configure_scripts"
    )

    # Configure each component
    for question in "${!component_configs[@]}"; do
        local config_func="${component_configs[$question]}"
        
        if gum confirm "$question"; then
            $config_func
        else
            local component_name=$(echo "$question" | sed 's/.*Install \([^?]*\).*/\1/')
            ui_error "Skipping $component_name"
        fi
        show_spacer
    done
    
    # Offer help system after configuration
    if [ ${#SELECTIONS[@]} -gt 0 ] && gum confirm "❓ Would you like to learn more about the selected components?"; then
        show_interactive_help
    fi

    # Show summary
    show_summary

    # Save configuration
    if gum confirm "💾 Save this configuration for future use?"; then
        save_config
    fi
}