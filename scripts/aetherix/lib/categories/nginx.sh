#!/usr/bin/env bash

install_nginx() {
    begin_category nginx || return 0
    section "🌐 Nginx"
    apt_install nginx

    if command_exists systemctl; then
        run_cmd sudo systemctl enable nginx || true
        run_cmd sudo systemctl start nginx || true
    fi

    success "Nginx is installed and enabled"
}
