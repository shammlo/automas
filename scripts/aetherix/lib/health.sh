#!/usr/bin/env bash

health_ok=0
health_warn=0

health_success() {
    health_ok=$((health_ok + 1))
    success "$*"
}

health_warning() {
    health_warn=$((health_warn + 1))
    warn "$*"
}

check_command_health() {
    local command_name="$1"

    if command_exists "$command_name"; then
        health_success "$command_name is installed"
    else
        health_warning "$command_name is not installed"
    fi
}

check_service_health() {
    local service_name="$1"

    if ! command_exists systemctl; then
        health_warning "systemctl unavailable; cannot check $service_name service"
        return 0
    fi

    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
        health_success "$service_name service is running"
    else
        health_warning "$service_name service is not running"
    fi
}

check_core_health() {
    check_command_health git
    check_command_health curl
    check_command_health wget
}

check_terminal_health() {
    check_command_health fzf
    check_command_health zoxide
    check_command_health rg
    check_command_health btop
}

check_shell_health() {
    check_command_health zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        health_success "Oh My Zsh is installed"
    else
        health_warning "Oh My Zsh is not installed"
    fi
}

check_docker_health() {
    check_command_health docker
    check_service_health docker
    if groups "$USER" | grep -qw docker; then
        health_success "$USER belongs to the docker group"
    else
        health_warning "$USER is not in the docker group yet"
    fi
}

check_nginx_health() {
    check_command_health nginx
    check_service_health nginx
    if command_exists nginx && nginx -t >/dev/null 2>&1; then
        health_success "Nginx configuration test passed"
    else
        health_warning "Nginx configuration test did not pass"
    fi
}

check_postgres_health() {
    check_command_health psql
    if selected_has postgres && [ "$POSTGRES_MODE" = "Full Server" ]; then
        check_service_health postgresql
    fi
}

check_android_health() {
    check_command_health java
    if [ -x "$HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager" ]; then
        health_success "Android SDK command-line tools are installed"
    else
        health_warning "Android SDK command-line tools are not installed"
    fi
}

check_flutter_health() {
    if [ -x "$HOME/development/flutter/bin/flutter" ]; then
        health_success "Flutter SDK is installed"
    else
        health_warning "Flutter SDK is not installed"
    fi
}

check_apps_health() {
    check_command_health code
    check_command_health flameshot
    check_command_health op
}

run_health_check() {
    local category

    section "🏥 Health Check"
    health_ok=0
    health_warn=0

    for category in "${SELECTED[@]}"; do
        case "$category" in
            core) check_core_health ;;
            terminal) check_terminal_health ;;
            shell) check_shell_health ;;
            docker) check_docker_health ;;
            android) check_android_health ;;
            flutter) check_flutter_health ;;
            apps) check_apps_health ;;
            postgres) check_postgres_health ;;
            nginx) check_nginx_health ;;
        esac
    done

    echo
    if [ "$health_warn" -eq 0 ]; then
        success "Health check completed: $health_ok check(s) passed."
    else
        warn "Health check completed: $health_ok passed, $health_warn warning(s)."
    fi
}

write_health_report() {
    local report="$CONFIG_DIR/health-report.txt"
    local category

    [ "$DRY_RUN" = true ] && return 0
    mkdir -p "$CONFIG_DIR"
    {
        echo "Aetherix Alchemy Health Report"
        echo "Generated: $(date)"
        echo
        echo "Selected Categories:"
        for category in "${SELECTED[@]}"; do
            echo "  - ${CATEGORY_LABELS[$category]}"
        done
        echo
        echo "System:"
        echo "  Kernel: $(uname -r)"
        echo "  Architecture: $(uname -m)"
        echo "  Disk Available: $(df -h / | awk 'NR==2 {print $4}')"
        command_exists free && echo "  Memory Available: $(free -h | awk '/^Mem:/ {print $7}')"
    } > "$report"
    success "Health report saved to $report"
}
