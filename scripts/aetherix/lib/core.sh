#!/usr/bin/env bash

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/aetherix"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/aetherix"
LOG_FILE="$LOG_DIR/alchemy.log"
PROFILE=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

USE_GUM=false
NO_GUM=false
DRY_RUN=false
NON_INTERACTIVE=false
APT_UPDATED=false
POSTGRES_MODE=""
RUN_PREFLIGHT=true
RUN_HEALTH=false

declare -a SELECTED=()
declare -a CATEGORY_ORDER=(core terminal shell docker gnome android flutter apps postgres nginx ai)
declare -A CATEGORY_DONE=()
declare -A CATEGORY_LABELS=(
    [core]="Core Development Tools"
    [terminal]="Terminal Tools"
    [shell]="Shell"
    [docker]="Docker"
    [gnome]="GNOME Enhancements"
    [android]="Android Development"
    [flutter]="Flutter"
    [apps]="Applications"
    [postgres]="PostgreSQL"
    [nginx]="Nginx"
    [ai]="AI Coding Tools"
)
declare -A DEFAULT_SELECTED=(
    [core]=true
    [terminal]=true
    [shell]=true
    [docker]=true
    [gnome]=true
)

declare -A CATEGORY_SIZE_MB=(
    [core]=250
    [terminal]=180
    [shell]=120
    [docker]=600
    [gnome]=250
    [android]=6500
    [flutter]=2500
    [apps]=2500
    [postgres]=500
    [nginx]=80
    [ai]=0
)

log() {
    mkdir -p "$LOG_DIR" 2>/dev/null || return 0
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

color() {
    local color="$1"
    local message="$2"
    printf '%b%s%b\n' "$color" "$message" "$NC"
}

info() { color "$BLUE" "ℹ️  $*"; log "INFO $*"; }
success() { color "$GREEN" "✅ $*"; log "OK $*"; }
warn() { color "$YELLOW" "⚠️  $*"; log "WARN $*"; }
error() { color "$RED" "❌ $*" >&2; log "ERROR $*"; }
section() { printf '\n%b%s%b\n' "$BOLD$CYAN" "$*" "$NC"; log "SECTION $*"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_tty() {
    [ -t 0 ] && [ -t 1 ]
}

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        color "$PURPLE" "🧪 DRY RUN: $*"
        return 0
    fi

    "$@"
}

begin_category() {
    local category="$1"

    if [ "${CATEGORY_DONE[$category]:-false}" = true ]; then
        success "${CATEGORY_LABELS[$category]} already processed"
        return 1
    fi

    CATEGORY_DONE["$category"]=true
    return 0
}

ensure_apt_updated() {
    if [ "$APT_UPDATED" = false ]; then
        info "Updating apt package index..."
        run_cmd sudo apt update
        APT_UPDATED=true
    fi
}

apt_has_package() {
    apt-cache show "$1" >/dev/null 2>&1
}

apt_install() {
    local package
    local missing=()

    for package in "$@"; do
        if dpkg -s "$package" >/dev/null 2>&1; then
            success "$package already installed"
        else
            missing+=("$package")
        fi
    done

    [ ${#missing[@]} -eq 0 ] && return 0
    ensure_apt_updated
    info "Installing: ${missing[*]}"
    run_cmd sudo apt install -y "${missing[@]}"
}

install_if_available() {
    local package="$1"

    ensure_apt_updated
    if apt_has_package "$package"; then
        apt_install "$package"
    else
        warn "Package not available from apt: $package"
        return 1
    fi
}

backup_file() {
    local file="$1"
    local backup

    [ -f "$file" ] || return 0
    backup="$file.aetherix.$(date '+%Y%m%d%H%M%S').bak"
    cp "$file" "$backup"
    success "Backed up $file to $backup"
}

append_once() {
    local file="$1"
    local line="$2"

    if [ "$DRY_RUN" = true ]; then
        if [ -f "$file" ] && grep -Fqx "$line" "$file"; then
            success "Already configured in $file: $line"
        else
            color "$PURPLE" "🧪 DRY RUN: would add to $file: $line"
        fi
        return 0
    fi

    mkdir -p "$(dirname "$file")"
    touch "$file"
    if grep -Fqx "$line" "$file"; then
        success "Already configured in $file: $line"
    else
        backup_file "$file"
        printf '%s\n' "$line" >> "$file"
        success "Added to $file: $line"
    fi
}
