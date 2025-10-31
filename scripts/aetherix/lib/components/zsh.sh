#!/bin/bash

# Zsh Component - Installation and configuration

# Install Zsh
install_zsh() {
    print_section_title "🐚 Installing Zsh"
    update_component_progress "Zsh" "starting"

    # Install Zsh if not already installed
    if ! is_installed zsh; then
        ui_info "🐚 Installing Zsh..."
        if [ "$DRY_RUN" = true ]; then
            ui_dry_run "Would install Zsh"
        else
            if ! sudo apt install -y zsh; then
                ui_error "Failed to install Zsh"
                update_component_progress "Zsh" "failed"
                return 1
            fi
        fi
    else
        ui_warning "Zsh is already installed, skipping installation."
    fi

    if [ "$DRY_RUN" = true ]; then
        ui_dry_run "Would configure Zsh with Oh My Zsh: $INSTALL_OH_MY_ZSH"
        ui_dry_run "Would set as default shell: $ZSH_DEFAULT"
        update_component_progress "Zsh" "skipped"
        return 0
    fi

    # Install Oh My Zsh if requested
    if [ "$INSTALL_OH_MY_ZSH" = true ]; then
        install_oh_my_zsh
    fi

    # Set as default shell if requested
    if [ "$ZSH_DEFAULT" = true ]; then
        set_zsh_as_default
    fi

    # Install Zsh plugins
    if [ "$INSTALL_ZSH_PLUGINS" = true ]; then
        install_zsh_plugins
    fi

    update_component_progress "Zsh" "completed"
    print_success_box "Zsh installed successfully"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        ui_info "✨ Installing Oh My Zsh..."
        safe_spin "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        # Set theme if specified
        if [ -n "$ZSH_THEME" ] && [ "$ZSH_THEME" != "Default" ]; then
            ui_info "🎨 Setting Zsh theme to $ZSH_THEME..."
            sed -i "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"$ZSH_THEME\"/" "$HOME/.zshrc"
        fi
    else
        ui_warning "Oh My Zsh already installed, skipping."
    fi
}

# Set Zsh as default shell
set_zsh_as_default() {
    local current_shell=$(basename "$SHELL")
    if [ "$current_shell" != "zsh" ]; then
        ui_info "🔧 Setting Zsh as default shell..."
        chsh -s "$(which zsh)"
        safe_spin "Setting Zsh as default shell..."
        ui_success "Zsh is now your default shell"
    else
        ui_warning "Zsh is already your default shell."
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    ui_info "🧩 Installing Zsh plugins..."
    declare -a plugins_to_add=()
    local zsh_custom=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

    for plugin in $ZSH_PLUGINS_SELECTED; do
        case "$plugin" in
        "Auto-Suggestions"|"Auto Suggestions")
            install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git" plugins_to_add
            ;;
        "zsh-syntax-highlighting")
            install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git" plugins_to_add
            ;;
        "zsh-fast-syntax-highlighting")
            install_zsh_plugin "fast-syntax-highlighting" "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" plugins_to_add
            ;;
        "zsh-autocomplete")
            install_zsh_plugin "zsh-autocomplete" "https://github.com/marlonrichert/zsh-autocomplete.git" plugins_to_add
            ;;
        esac
    done

    # Update .zshrc with plugins
    if [ ${#plugins_to_add[@]} -gt 0 ]; then
        update_zshrc_plugins plugins_to_add
    fi
}

# Install individual Zsh plugin
install_zsh_plugin() {
    local plugin_name="$1"
    local plugin_url="$2"
    local -n plugins_array=$3
    local zsh_custom=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
    local plugin_path="$zsh_custom/plugins/$plugin_name"

    if [ ! -d "$plugin_path" ]; then
        ui_info "📥 Installing $plugin_name plugin..."
        git clone "$plugin_url" "$plugin_path"
    fi
    
    plugins_array+=("$plugin_name")
}

# Update .zshrc with plugins
update_zshrc_plugins() {
    local -n plugins_ref=$1
    
    ui_info "⚙️  Updating .zshrc with plugins..."
    # Create a backup of .zshrc
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"

    # Modify the plugins line in .zshrc
    sed -i "/^plugins=/c\plugins=(git ${plugins_ref[*]})" "$HOME/.zshrc"

    ui_success "Added plugins to .zshrc: ${plugins_ref[*]}"
    ui_warning "You will need to restart your terminal or run 'zsh' to use the new plugins"
}