#!/usr/bin/env bash

install_shell_plugin() {
    local name="$1"
    local repo="$2"
    local dest="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$name"

    if [ -d "$dest/.git" ]; then
        success "$name already installed"
        return 0
    fi

    info "Installing Zsh plugin: $name"
    run_cmd git clone "$repo" "$dest"
}

write_clean_zshrc() {
    local zshrc="$HOME/.zshrc"

    if [ "$DRY_RUN" = true ]; then
        color "$PURPLE" "🧪 DRY RUN: would write clean $zshrc"
        return 0
    fi

    backup_file "$zshrc"
    cat > "$zshrc" << 'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

export PATH="$HOME/.local/bin:$PATH"

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
EOF
    success "Wrote clean ~/.zshrc"
}

install_shell() {
    begin_category shell || return 0
    section "🐚 Shell"
    apt_install zsh git curl

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing Oh My Zsh"
        if [ "$DRY_RUN" = true ]; then
            color "$PURPLE" "🧪 DRY RUN: would install Oh My Zsh"
        else
            RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
                "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        fi
    else
        success "Oh My Zsh already installed"
    fi

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    fi
    install_shell_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
    install_shell_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
    write_clean_zshrc
}
