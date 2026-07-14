#!/usr/bin/env bash

declare -A PROFILE_DESCRIPTIONS=(
    [minimal]="Small baseline: core tools, terminal tools, and shell"
    [web]="Web workstation: shell, Docker, apps, Nginx, and PostgreSQL"
    [devops]="Operations workstation: Docker, Nginx, PostgreSQL, terminal, and shell"
    [fullstack]="Full-stack workstation with apps, Docker, PostgreSQL, Android, and Flutter"
    [workstation]="Default Aetherix workstation profile"
    [zoth]="Personal Aetherix workstation profile placeholder"
)

profile_categories() {
    case "$1" in
        minimal) echo "core terminal shell" ;;
        web) echo "core terminal shell docker apps nginx postgres" ;;
        devops) echo "core terminal shell docker nginx postgres" ;;
        fullstack) echo "core terminal shell docker gnome android flutter apps postgres nginx" ;;
        workstation) echo "core terminal shell docker gnome apps postgres nginx" ;;
        zoth) echo "core terminal shell docker gnome apps postgres nginx ai" ;;
        *) return 1 ;;
    esac
}

list_profiles() {
    local profile
    local profiles=(minimal web devops fullstack workstation zoth)

    section "🎯 Aetherix Profiles"
    for profile in "${profiles[@]}"; do
        printf '  %-12s %s\n' "$profile" "${PROFILE_DESCRIPTIONS[$profile]}"
    done
}

apply_profile() {
    local profile="$1"
    local categories
    local category

    if ! categories="$(profile_categories "$profile")"; then
        error "Unknown profile: $profile"
        list_profiles
        return 1
    fi

    SELECTED=()
    for category in $categories; do
        select_category "$category"
    done

    NON_INTERACTIVE=true
    success "Applied profile: $profile"
}
