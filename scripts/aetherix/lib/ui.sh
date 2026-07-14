#!/usr/bin/env bash

usage() {
    cat << EOF
🚀 Aetherix Alchemy

Transform a fresh Ubuntu machine into a ready development workstation.

Usage:
  alchemy [options]
  aetherix.sh [options]

Interactive mode is the default.

Options:
  --all          Install all workstation categories
  --core         Install core development tools
  --terminal     Install terminal tools and shell setup
  --docker       Install Docker and Docker Compose
  --android      Install Android development tooling
  --flutter      Install Flutter and Android integration
  --apps         Install workstation applications
  --postgres     Install PostgreSQL client/server flow
  --nginx        Install and enable Nginx
  --gnome        Install GNOME enhancements
  --profile NAME Use a predefined profile
  --list-profiles
                 Show available profiles
  --no-gum       Use native Bash prompts even if Gum is installed
  --dry-run      Print actions without changing the system
  --skip-preflight
                 Skip system checks before installation
  --health       Run post-install health checks in non-interactive mode
  -h, --help     Show this help

Profiles:
  minimal, web, devops, fullstack, workstation, zoth

Example:
  alchemy --profile zoth

Logs:
  $LOG_FILE
EOF
}

confirm_native() {
    local prompt="$1"
    local default_yes="${2:-true}"
    local answer
    local suffix="[Y/n]"

    [ "$default_yes" = false ] && suffix="[y/N]"
    if ! is_tty; then
        [ "$default_yes" = true ]
        return $?
    fi

    read -r -p "$prompt $suffix " answer
    case "$answer" in
        y|Y|yes|YES) return 0 ;;
        n|N|no|NO) return 1 ;;
        "") [ "$default_yes" = true ] ;;
        *) return 1 ;;
    esac
}

gum_confirm() {
    local prompt="$1"
    local default_yes="${2:-true}"

    if [ "$USE_GUM" = true ]; then
        if [ "$default_yes" = true ]; then
            gum confirm "$prompt"
        else
            gum confirm --default=false "$prompt"
        fi
    else
        confirm_native "$prompt" "$default_yes"
    fi
}

install_gum() {
    if command_exists gum; then
        success "Gum already installed"
        USE_GUM=true
        return 0
    fi

    section "🍬 Installing Gum"
    apt_install curl ca-certificates gnupg
    run_cmd sudo mkdir -p /etc/apt/keyrings

    if [ "$DRY_RUN" = true ]; then
        color "$PURPLE" "🧪 DRY RUN: would add Charm apt repository and install gum"
        return 0
    fi

    curl -fsSL https://repo.charm.sh/apt/gpg.key |
        sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *' |
        sudo tee /etc/apt/sources.list.d/charm.list >/dev/null
    APT_UPDATED=false
    apt_install gum

    if command_exists gum; then
        USE_GUM=true
        success "Gum installed"
    else
        warn "Gum installation did not complete; continuing with native prompts"
        USE_GUM=false
    fi
}

setup_gum() {
    if [ "$NO_GUM" = true ]; then
        USE_GUM=false
        return 0
    fi

    if command_exists gum; then
        USE_GUM=true
        return 0
    fi

    color "$CYAN" "🚀 Welcome to Aetherix Alchemy"
    echo
    echo "Gum was not found."

    if ! is_tty || [ "$NON_INTERACTIVE" = true ]; then
        warn "Continuing with native Bash prompts."
        USE_GUM=false
        return 0
    fi

    if confirm_native "Install Gum for a better interactive UI?" true; then
        install_gum
    else
        warn "Continuing with native Bash prompts."
        USE_GUM=false
    fi
}

selected_has() {
    local wanted="$1"
    local item

    for item in "${SELECTED[@]}"; do
        [ "$item" = "$wanted" ] && return 0
    done
    return 1
}

select_category() {
    local category="$1"

    selected_has "$category" && return 0
    SELECTED+=("$category")
}

select_all_categories() {
    local category

    SELECTED=()
    for category in "${CATEGORY_ORDER[@]}"; do
        select_category "$category"
    done
}

select_defaults() {
    SELECTED=()
    select_category core
    select_category terminal
    select_category shell
    select_category docker
    select_category gnome
}

interactive_menu_gum() {
    local labels=()
    local selected_args=()
    local category
    local label

    for category in "${CATEGORY_ORDER[@]}"; do
        label="${CATEGORY_LABELS[$category]}"
        labels+=("$label")
        if [ "${DEFAULT_SELECTED[$category]:-false}" = true ]; then
            selected_args+=(--selected "$label")
        fi
    done

    labels=$(gum choose --no-limit --cursor="→ " --selected-prefix="[✓] " --unselected-prefix="[ ] " "${selected_args[@]}" "${labels[@]}")
    SELECTED=()
    while IFS= read -r label; do
        [ -n "$label" ] || continue
        for category in "${CATEGORY_ORDER[@]}"; do
            [ "${CATEGORY_LABELS[$category]}" = "$label" ] && select_category "$category"
        done
    done <<< "$labels"
}

interactive_menu_native() {
    local category
    local index=1
    local answer
    local choice
    local choices=()

    color "$CYAN" "What would you like to install?"
    echo
    for category in "${CATEGORY_ORDER[@]}"; do
        local checked="[ ]"
        [ "${DEFAULT_SELECTED[$category]:-false}" = true ] && checked="[✓]"
        printf "%2d) %s %s\n" "$index" "$checked" "${CATEGORY_LABELS[$category]}"
        index=$((index + 1))
    done

    echo
    echo "Enter numbers separated by commas, 'all', or press Enter for defaults."
    read -r -p "Selection: " answer

    case "$answer" in
        "") select_defaults; return 0 ;;
        all|ALL) select_all_categories; return 0 ;;
    esac

    IFS=',' read -r -a choices <<< "$answer"
    SELECTED=()
    for choice in "${choices[@]}"; do
        choice="${choice//[[:space:]]/}"
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#CATEGORY_ORDER[@]}" ]; then
            select_category "${CATEGORY_ORDER[$((choice - 1))]}"
        else
            warn "Ignoring invalid selection: $choice"
        fi
    done
}

interactive_menu() {
    color "$CYAN" "🚀 Aetherix Alchemy"
    echo
    echo "Transform this fresh Ubuntu machine into a ready development workstation."
    echo

    if [ "$USE_GUM" = true ]; then
        interactive_menu_gum
    else
        interactive_menu_native
    fi

    if [ ${#SELECTED[@]} -eq 0 ]; then
        warn "No categories selected."
        exit 0
    fi

    echo
    color "$BLUE" "Selected:"
    local category
    for category in "${SELECTED[@]}"; do
        echo "  ✓ ${CATEGORY_LABELS[$category]}"
    done
    echo

    if ! gum_confirm "Continue?" true; then
        warn "Alchemy cancelled."
        exit 0
    fi
}
