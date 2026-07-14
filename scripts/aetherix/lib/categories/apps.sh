#!/usr/bin/env bash

install_vscode() {
    if command_exists code; then
        success "VS Code already installed"
        return 0
    fi

    install_core
    info "Installing VS Code"
    if [ "$DRY_RUN" = true ]; then
        color "$PURPLE" "🧪 DRY RUN: would add Microsoft apt repository and install code"
        return 0
    fi

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc |
        gpg --dearmor |
        sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
    printf '%s\n' 'deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' |
        sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    APT_UPDATED=false
    apt_install code
}

install_1password() {
    if command_exists op; then
        success "1Password CLI already installed"
        return 0
    fi

    install_core
    info "Installing 1Password CLI"
    if [ "$DRY_RUN" = true ]; then
        color "$PURPLE" "🧪 DRY RUN: would add 1Password apt repository and install 1password-cli"
        return 0
    fi

    sudo mkdir -p /usr/share/keyrings
    curl -sS https://downloads.1password.com/linux/keys/1password.asc |
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    printf '%s\n' 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' |
        sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
    APT_UPDATED=false
    apt_install 1password-cli
}

install_warp() {
    if command_exists warp-terminal || command_exists warp; then
        success "Warp already installed"
        return 0
    fi

    info "Installing Warp"
    if [ "$DRY_RUN" = true ]; then
        color "$PURPLE" "🧪 DRY RUN: would download and install Warp .deb"
        return 0
    fi

    local deb="/tmp/warp-terminal.deb"
    curl -L -o "$deb" "https://app.warp.dev/download?package=deb"
    run_cmd sudo apt install -y "$deb"
}

install_apps() {
    begin_category apps || return 0
    section "📦 Applications"
    install_core
    install_vscode
    install_warp
    apt_install flameshot
    install_if_available onlyoffice-desktopeditors || warn "OnlyOffice package not available from apt."

    if [ "$DRY_RUN" = true ]; then
        color "$PURPLE" "🧪 DRY RUN: would install Postman via snap if needed"
        install_1password
        return 0
    fi

    if command_exists snap; then
        if snap list postman >/dev/null 2>&1; then
            success "Postman already installed"
        else
            run_cmd sudo snap install postman
        fi
    else
        warn "Snap is not installed; skipping Postman."
    fi

    install_1password
}
