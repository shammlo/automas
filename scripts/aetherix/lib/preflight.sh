#!/usr/bin/env bash

selected_total_size_mb() {
    local category
    local total=0

    for category in "${SELECTED[@]}"; do
        total=$((total + ${CATEGORY_SIZE_MB[$category]:-0}))
    done

    echo "$total"
}

format_mb() {
    local mb="$1"

    if [ "$mb" -ge 1024 ]; then
        printf '%dGB' $((mb / 1024))
    else
        printf '%dMB' "$mb"
    fi
}

selected_has_any_network_category() {
    local category

    for category in "${SELECTED[@]}"; do
        case "$category" in
            core|terminal|shell|docker|gnome|android|flutter|apps|postgres|nginx)
                return 0
                ;;
        esac
    done

    return 1
}

check_disk_space() {
    local required_mb="$1"
    local available_mb

    available_mb=$(df -Pm / | awk 'NR==2 {print $4}')
    if [ -z "$available_mb" ]; then
        warn "Could not determine available disk space."
        return 0
    fi

    info "Disk estimate: $(format_mb "$required_mb") needed, $(format_mb "$available_mb") available."
    if [ "$available_mb" -lt "$required_mb" ]; then
        error "Insufficient disk space for selected categories."
        return 1
    fi
}

check_internet_access() {
    if [ "$DRY_RUN" = true ]; then
        color "$PURPLE" "🧪 DRY RUN: skipping live internet check"
        return 0
    fi

    if command_exists curl && curl -fsSL --max-time 5 https://archive.ubuntu.com >/dev/null 2>&1; then
        success "Internet access looks good"
        return 0
    fi

    if command_exists ping && ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        success "Internet access looks good"
        return 0
    fi

    error "No internet access detected. Most installers need network access."
    return 1
}

check_port_free() {
    local port="$1"

    if command_exists ss && ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]$port$"; then
        warn "Port $port is already in use."
    elif command_exists netstat && netstat -tuln 2>/dev/null | grep -q ":$port "; then
        warn "Port $port is already in use."
    else
        success "Port $port appears available"
    fi
}

check_service_conflicts() {
    if selected_has nginx && command_exists systemctl && systemctl is-active --quiet apache2 2>/dev/null; then
        warn "Apache2 is running and may conflict with Nginx on ports 80/443."
    fi

    if selected_has nginx; then
        check_port_free 80
        check_port_free 443
    fi
}

run_preflight() {
    local issue_count=0
    local estimated_mb

    section "🔍 Preflight Checks"

    if [ "$(id -u)" -eq 0 ]; then
        error "Do not run Alchemy as root. Run it as your normal user."
        issue_count=$((issue_count + 1))
    fi

    if command_exists lsb_release; then
        info "OS: $(lsb_release -ds)"
    else
        warn "lsb_release is not installed; OS detection is limited."
    fi

    case "$(uname -s)" in
        Linux) success "Linux detected" ;;
        *) warn "Alchemy is designed for Ubuntu/Linux workstations." ;;
    esac

    if command_exists sudo; then
        if sudo -n true 2>/dev/null; then
            success "Sudo is available without an immediate prompt"
        else
            warn "Sudo is available, but you may be prompted for your password."
        fi
    else
        error "sudo is required for system package installs."
        issue_count=$((issue_count + 1))
    fi

    estimated_mb=$(selected_total_size_mb)
    check_disk_space "$((estimated_mb + 1024))" || issue_count=$((issue_count + 1))

    if selected_has_any_network_category; then
        check_internet_access || issue_count=$((issue_count + 1))
    fi

    check_service_conflicts

    if [ "$issue_count" -eq 0 ]; then
        success "Preflight checks passed"
        return 0
    fi

    if [ "$NON_INTERACTIVE" = true ]; then
        error "Preflight found $issue_count issue(s). Use --skip-preflight to bypass."
        return 1
    fi

    warn "Preflight found $issue_count issue(s)."
    gum_confirm "Continue anyway?" false
}
