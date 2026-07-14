#!/usr/bin/env bash

choose_postgres_mode() {
    local choice

    [ -n "$POSTGRES_MODE" ] && return 0
    if [ "$USE_GUM" = true ]; then
        POSTGRES_MODE=$(gum choose "Client Only" "Full Server" "Skip")
    elif is_tty && [ "$NON_INTERACTIVE" = false ]; then
        echo "PostgreSQL:"
        echo "  1) Client Only"
        echo "  2) Full Server"
        echo "  3) Skip"
        read -r -p "Choice [1]: " choice
        case "${choice:-1}" in
            1) POSTGRES_MODE="Client Only" ;;
            2) POSTGRES_MODE="Full Server" ;;
            3) POSTGRES_MODE="Skip" ;;
            *) POSTGRES_MODE="Client Only" ;;
        esac
    else
        POSTGRES_MODE="Client Only"
        warn "Non-interactive PostgreSQL mode defaults to Client Only."
    fi
}

install_postgres() {
    begin_category postgres || return 0
    section "🐘 PostgreSQL"
    choose_postgres_mode

    case "$POSTGRES_MODE" in
        "Client Only") apt_install postgresql-client ;;
        "Full Server")
            apt_install postgresql postgresql-contrib
            if command_exists systemctl; then
                run_cmd sudo systemctl enable postgresql || true
                run_cmd sudo systemctl start postgresql || true
            fi
            ;;
        "Skip") warn "Skipping PostgreSQL" ;;
    esac
}
