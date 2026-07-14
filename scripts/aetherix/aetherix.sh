#!/usr/bin/env bash
#
# Aetherix Alchemy - modular workstation bootstrapper.
# Aetherix is the toolkit/project identity; Alchemy is the setup command.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALCHEMY_LIB_DIR="$SCRIPT_DIR/lib"

source "$ALCHEMY_LIB_DIR/core.sh"
source "$ALCHEMY_LIB_DIR/ui.sh"
source "$ALCHEMY_LIB_DIR/profiles.sh"
source "$ALCHEMY_LIB_DIR/preflight.sh"
source "$ALCHEMY_LIB_DIR/health.sh"

source "$ALCHEMY_LIB_DIR/categories/core.sh"
source "$ALCHEMY_LIB_DIR/categories/terminal.sh"
source "$ALCHEMY_LIB_DIR/categories/shell.sh"
source "$ALCHEMY_LIB_DIR/categories/docker.sh"
source "$ALCHEMY_LIB_DIR/categories/gnome.sh"
source "$ALCHEMY_LIB_DIR/categories/android.sh"
source "$ALCHEMY_LIB_DIR/categories/flutter.sh"
source "$ALCHEMY_LIB_DIR/categories/apps.sh"
source "$ALCHEMY_LIB_DIR/categories/postgres.sh"
source "$ALCHEMY_LIB_DIR/categories/nginx.sh"
source "$ALCHEMY_LIB_DIR/categories/ai.sh"

parse_args() {
    local explicit=false
    local extra_selected=()
    local category

    while [ $# -gt 0 ]; do
        case "$1" in
            --all) explicit=true; select_all_categories; shift ;;
            --core) explicit=true; select_category core; shift ;;
            --terminal) explicit=true; select_category terminal; select_category shell; shift ;;
            --docker) explicit=true; select_category docker; shift ;;
            --android) explicit=true; select_category android; shift ;;
            --flutter) explicit=true; select_category flutter; shift ;;
            --apps) explicit=true; select_category apps; shift ;;
            --postgres) explicit=true; select_category postgres; shift ;;
            --nginx) explicit=true; select_category nginx; shift ;;
            --gnome) explicit=true; select_category gnome; shift ;;
            --no-gum) NO_GUM=true; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --skip-preflight) RUN_PREFLIGHT=false; shift ;;
            --health) RUN_HEALTH=true; shift ;;
            --list-profiles) list_profiles; exit 0 ;;
            --profile)
                PROFILE="${2:-}"
                [ -n "$PROFILE" ] || { error "--profile requires a name"; exit 1; }
                shift 2
                ;;
            -h|--help) usage; exit 0 ;;
            *) error "Unknown option: $1"; usage; exit 1 ;;
        esac
    done

    if [ -n "$PROFILE" ]; then
        extra_selected=("${SELECTED[@]}")
        apply_profile "$PROFILE"
        for category in "${extra_selected[@]}"; do
            select_category "$category"
        done
    fi

    if [ "$explicit" = true ] || [ -n "$PROFILE" ]; then
        NON_INTERACTIVE=true
    fi
}

run_selected_installers() {
    local category

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$CONFIG_DIR" "$LOG_DIR"
    fi

    for category in "${SELECTED[@]}"; do
        case "$category" in
            core) install_core ;;
            terminal) install_terminal ;;
            shell) install_shell ;;
            docker) install_docker ;;
            gnome) install_gnome ;;
            android) install_android ;;
            flutter) install_flutter ;;
            apps) install_apps ;;
            postgres) install_postgres ;;
            nginx) install_nginx ;;
            ai) install_ai ;;
        esac
    done
}

main() {
    parse_args "$@"
    setup_gum

    if [ "$NON_INTERACTIVE" = false ]; then
        interactive_menu
    fi

    if [ ${#SELECTED[@]} -eq 0 ]; then
        interactive_menu
    fi

    if [ "$RUN_PREFLIGHT" = true ]; then
        run_preflight
    fi

    run_selected_installers

    if [ "$RUN_HEALTH" = true ]; then
        run_health_check
        write_health_report
    elif [ "$NON_INTERACTIVE" = false ] && gum_confirm "Run a post-install health check?" true; then
        run_health_check
        write_health_report
    fi

    echo
    success "Aetherix Alchemy completed."
}

main "$@"
