#!/bin/bash

# Templates Library - Pre-configured setup templates

# Export current configuration as template
export_template() {
    local template_name="$1"
    local template_file="$CONFIG_DIR/templates/${template_name}.template"
    
    mkdir -p "$CONFIG_DIR/templates"
    
    {
        echo "# Nicronian Setup Template: $template_name"
        echo "# Created: $(date)"
        echo "# Description: Custom configuration template"
        echo ""
        echo "SELECTIONS=(${SELECTIONS[*]})"
        
        # Export all configuration variables
        for var in NGINX_AUTO NGINX_PROJECT DOCKER_VERSION DOCKER_AUTOSTART \
                   PSQL_VERSION PSQL_DOCKER DB_NAME DB_USER DB_PORT \
                   INSTALL_OH_MY_ZSH ZSH_THEME ZSH_DEFAULT INSTALL_ZSH_PLUGINS ZSH_PLUGINS_SELECTED \
                   GIT_CONFIG GIT_NAME GIT_EMAIL DEV_ENV_SELECTED NODE_VERSION PYTHON_VENV \
                   DEV_TOOLS_SELECTED MONITOR_TOOLS_SELECTED SCRIPTS_SELECTED; do
            if [ -n "${!var:-}" ]; then
                echo "$var=\"${!var}\""
            fi
        done
    } > "$template_file"
    
    ui_success "Template saved: $template_file"
}

# Import template
import_template() {
    local template_file="$1"
    
    if [[ -f "$template_file" ]]; then
        source "$template_file"
        ui_success "Template loaded: $template_file"
        return 0
    else
        ui_error "Template not found: $template_file"
        return 1
    fi
}

# List available templates
list_templates() {
    local template_dir="$CONFIG_DIR/templates"
    
    if [[ -d "$template_dir" ]]; then
        ui_info "Available templates:"
        for template in "$template_dir"/*.template; do
            if [[ -f "$template" ]]; then
                local name=$(basename "$template" .template)
                local desc=$(grep "# Description:" "$template" | cut -d: -f2- | xargs)
                gum style --foreground 2 "  • $name - $desc"
            fi
        done
    else
        ui_info "No templates found"
    fi
}

# Interactive template management
manage_templates() {
    while true; do
        local choice=$(gum choose --header="📋 Template Management" \
            "List Templates" \
            "Export Current Config" \
            "Import Template" \
            "Delete Template" \
            "Back")
        
        case "$choice" in
            "List Templates")
                list_templates
                ;;
            "Export Current Config")
                local name=$(gum input --placeholder "Template name")
                if [ -n "$name" ]; then
                    export_template "$name"
                fi
                ;;
            "Import Template")
                local template_dir="$CONFIG_DIR/templates"
                if [[ -d "$template_dir" ]]; then
                    local templates=($(ls "$template_dir"/*.template 2>/dev/null | xargs -n1 basename -s .template))
                    if [ ${#templates[@]} -gt 0 ]; then
                        local selected=$(gum choose "${templates[@]}")
                        import_template "$template_dir/$selected.template"
                    else
                        ui_info "No templates available"
                    fi
                fi
                ;;
            "Delete Template")
                # Implementation for deleting templates
                ui_info "Delete functionality would go here"
                ;;
            "Back")
                break
                ;;
        esac
    done
}