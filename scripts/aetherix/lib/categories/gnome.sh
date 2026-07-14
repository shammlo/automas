#!/usr/bin/env bash

install_gnome_extension_hint() {
    local name="$1"
    local uuid="$2"

    if command_exists gnome-extensions && gnome-extensions list 2>/dev/null | grep -Fxq "$uuid"; then
        success "$name extension already installed"
    else
        warn "$name may need installation/enabling via Extension Manager ($uuid)."
    fi
}

install_gnome() {
    begin_category gnome || return 0
    section "🖥️  GNOME Enhancements"
    install_core
    install_if_available extension-manager || true
    install_if_available gnome-shell-extension-appindicator || true
    install_if_available gnome-shell-extension-caffeine || true
    install_gnome_extension_hint "Pano" "pano@elhan.io"
    install_gnome_extension_hint "Unblank Lock Screen" "unblank@sun.wxg@gmail.com"
    warn "GNOME extensions usually require logout/login or Extension Manager to enable."
}
