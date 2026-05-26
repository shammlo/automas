#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SCRIPT_DIR="$ROOT_DIR/scripts"
ZSHRC="$HOME/.zshrc"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

OVERRIDE=false
COMMAND=""

print() {
  echo -e "$1$2${NC}"
}

divider() {
  echo -e "${DIM}────────────────────────────────────────${NC}"
}

usage() {
  print "$CYAN" "🚀 Automas Installer"
  divider
  echo
  echo "📘 Usage:"
  echo "  automas-install"
  echo "  automas-install list"
  echo "  automas-install all"
  echo "  automas-install <script>"
  echo "  automas-install -o <script>"
  echo "  automas-install -o all"
  echo
  echo "⚙️  Options:"
  echo "  -o, --override    Remove conflicting alias from ~/.zshrc automatically"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--override)
        OVERRIDE=true
        shift
        ;;
      -h|--help|help)
        COMMAND="help"
        shift
        ;;
      *)
        COMMAND="$1"
        shift
        ;;
    esac
  done
}

get_available_scripts() {
  for dir in "$SCRIPT_DIR"/*; do
    [[ -d "$dir" ]] || continue

    local name
    name="$(basename "$dir")"

    [[ -f "$dir/$name.sh" ]] && echo "$name"
  done | sort
}

list_scripts() {
  print "$BLUE" "📦 Available scripts:"
  echo

  local found=false

  while IFS= read -r name; do
    found=true
    echo "  • $name"
  done < <(get_available_scripts)

  if [[ "$found" == false ]]; then
    print "$YELLOW" "⚠️  No installable scripts found."
    echo
    echo "Expected structure:"
    echo "  scripts/ngx/ngx.sh"
    echo "  scripts/dbm/dbm.sh"
  fi
}

script_exists() {
  local target="$1"

  while IFS= read -r name; do
    [[ "$name" == "$target" ]] && return 0
  done < <(get_available_scripts)

  return 1
}

get_alias_line() {
  local name="$1"

  [[ -f "$ZSHRC" ]] || return 0

  grep -E "^[[:space:]]*alias[[:space:]]+$name=" "$ZSHRC" || true
}

remove_alias_from_zshrc() {
  local name="$1"

  [[ -f "$ZSHRC" ]] || return 0

  local backup="$ZSHRC.bak.$(date +%Y%m%d%H%M%S)"
  cp "$ZSHRC" "$backup"

  sed -i "/^[[:space:]]*alias[[:space:]]\+$name=/d" "$ZSHRC"

  print "$GREEN" "🧹 Removed alias '$name' from ~/.zshrc"
  print "$YELLOW" "📝 Backup created: $backup"
}

confirm_continue() {
  local name="$1"
  local alias_line="$2"

  echo
  print "$YELLOW" "⚠️  Alias conflict detected in ~/.zshrc"
  echo
  echo "Existing alias:"
  echo "  $alias_line"
  echo
  print "$YELLOW" "Aliases override PATH commands."
  echo "Even if ~/.local/bin/$name is installed, typing '$name' may still use the alias."
  echo
  echo "Choose:"
  echo "  y) ✅ Continue install but keep alias"
  echo "  n) ❌ Cancel"
  echo "  o) 🧹 Remove alias from ~/.zshrc, then install"
  echo

  read -r -p "Continue? [y/n/o]: " answer

  case "$answer" in
    y|Y)
      return 0
      ;;
    o|O)
      remove_alias_from_zshrc "$name"
      return 0
      ;;
    *)
      print "$RED" "🛑 Cancelled."
      exit 1
      ;;
  esac
}

handle_alias_conflict() {
  local name="$1"
  local alias_line

  alias_line="$(get_alias_line "$name")"

  [[ -z "$alias_line" ]] && return 0

  if [[ "$OVERRIDE" == true ]]; then
    remove_alias_from_zshrc "$name"
    return 0
  fi

  confirm_continue "$name" "$alias_line"
}

install_one() {
  local name="$1"
  local source="$SCRIPT_DIR/$name/$name.sh"
  local target="$BIN_DIR/$name"

  if ! script_exists "$name"; then
    print "$RED" "❌ Script not found: $name"
    echo
    list_scripts
    echo
    echo "Try:"
    echo "  automas-install list"
    echo "  automas-install all"
    exit 1
  fi

  handle_alias_conflict "$name"

  mkdir -p "$BIN_DIR"
  chmod +x "$source"
  ln -sf "$source" "$target"

  print "$GREEN" "✅ Installed: $name"
  echo -e "  ${DIM}$target -> $source${NC}"
}

install_all() {
  local count=0

  while IFS= read -r name; do
    install_one "$name"
    count=$((count + 1))
  done < <(get_available_scripts)

  echo
  divider
  print "$GREEN" "🚀 Done. Installed $count script(s)."
}

show_help() {
  usage
  echo
  list_scripts
}

parse_args "$@"

case "${COMMAND:-}" in
  ""|list|ls)
    show_help
    ;;
  help)
    show_help
    ;;
  all)
    install_all
    ;;
  *)
    install_one "$COMMAND"
    ;;
esac