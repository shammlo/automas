#!/usr/bin/env bash

install_docker() {
    begin_category docker || return 0
    section "🐳 Docker"
    install_core

    if command_exists docker; then
        success "Docker already installed"
    else
        info "Installing Docker Engine from Ubuntu packages"
        apt_install docker.io docker-compose-plugin
    fi

    if groups "$USER" | grep -qw docker; then
        success "$USER already belongs to docker group"
    else
        info "Adding $USER to docker group"
        run_cmd sudo usermod -aG docker "$USER"
        warn "Log out and back in for docker group permissions to apply."
    fi

    if command_exists systemctl; then
        run_cmd sudo systemctl enable docker || true
        run_cmd sudo systemctl start docker || true
    fi
}
