#!/usr/bin/env bash

install_eza() {
    if command_exists eza; then
        success "eza already installed"
        return 0
    fi

    install_if_available eza || warn "Install eza manually if your Ubuntu release does not provide it."
}

install_bat() {
    apt_install bat
    if command_exists batcat && ! command_exists bat; then
        if [ "$DRY_RUN" = true ]; then
            color "$PURPLE" "🧪 DRY RUN: would link bat -> batcat in ~/.local/bin"
            return 0
        fi
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        success "Linked bat -> batcat in ~/.local/bin"
    fi
}

install_fd() {
    apt_install fd-find
    if command_exists fdfind && ! command_exists fd; then
        if [ "$DRY_RUN" = true ]; then
            color "$PURPLE" "🧪 DRY RUN: would link fd -> fdfind in ~/.local/bin"
            return 0
        fi
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        success "Linked fd -> fdfind in ~/.local/bin"
    fi
}

install_terminal() {
    begin_category terminal || return 0
    section "🧰 Terminal Tools"
    install_core
    install_eza
    install_bat
    apt_install fzf zoxide ripgrep btop
    install_fd
    append_once "$HOME/.zshrc" 'eval "$(zoxide init zsh)"'
    append_once "$HOME/.bashrc" 'eval "$(zoxide init bash)"'
}
