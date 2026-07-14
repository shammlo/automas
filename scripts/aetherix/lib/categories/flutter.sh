#!/usr/bin/env bash

install_flutter() {
    begin_category flutter || return 0
    section "🦋 Flutter"
    install_android

    local flutter_dir="$HOME/development/flutter"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$HOME/development"
    fi

    if [ -d "$flutter_dir/.git" ]; then
        success "Flutter SDK already installed"
    else
        info "Installing Flutter SDK"
        run_cmd git clone https://github.com/flutter/flutter.git -b stable "$flutter_dir"
    fi

    append_once "$HOME/.zshrc" 'export PATH="$HOME/development/flutter/bin:$PATH"'
    append_once "$HOME/.bashrc" 'export PATH="$HOME/development/flutter/bin:$PATH"'

    if [ "$DRY_RUN" = false ] && [ -x "$flutter_dir/bin/flutter" ]; then
        "$flutter_dir/bin/flutter" config --android-sdk "$HOME/Android/Sdk" || true
        "$flutter_dir/bin/flutter" doctor || true
    fi
}
