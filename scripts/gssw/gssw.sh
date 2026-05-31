#!/usr/bin/env bash
#
# Description: Git commit signing setup wizard for SSH and GPG key configuration
set -euo pipefail

# -----------------------------
# Colors and Formatting
# -----------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SIGNING_METHOD=""
OS_TYPE=""
IS_MAC=false
IS_WINDOWS=false
IS_LINUX=false
GIT_USERNAME=""
GIT_EMAIL=""
SSH_KEY=""
SSH_KEY_CREATED=false
SSH_AGENT_RC_FILE=""

print_color() {
    local color="$1"
    local message="$2"

    echo -e "${color}${message}${NC}"
}

show_banner() {
    echo -e "\n${BLUE}✨===========================================✨${NC}"
    echo -e "     ${BOLD}🔐  Git Commit Signing Setup Wizard${NC}"
    echo -e "${BLUE}✨===========================================✨${NC}\n"
    echo -e "${YELLOW}This script will configure Git commit signing"
    echo -e "using either SSH or GPG keys.${NC}"
    echo "-------------------------------------------------------"
}

show_help() {
    echo -e "${BOLD}🔐 Git Commit Signing Setup Wizard${NC}"
    echo "----------------------------------"
    echo "This script helps you configure Git commit signing using SSH or GPG."
    echo
    echo "Features:"
    echo "  • Generates a new SSH or GPG key."
    echo "  • Configures your Git username and email."
    echo "  • Enables signed commits globally."
    echo "  • Adds SSH keys to ssh-agent and configures startup."
    echo "  • Uses macOS Keychain integration when available."
    echo "  • Configures SSH allowed signers for local verification."
    echo "  • Prints the public key you need to add to GitHub."
    echo "  • Optionally tests your SSH connection to GitHub."
    echo
    echo "Supported platforms: macOS, Linux, Windows (Git Bash/WSL)"
    echo
    echo "Usage:"
    echo "  $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help   Show this help message and exit."
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_color "$RED" "❌ Unknown option: $1"
                echo
                show_help
                exit 1
                ;;
        esac
    done
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_privileged() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command_exists sudo; then
        sudo "$@"
    else
        print_color "$RED" "❌ sudo is required to install packages. Please install sudo or run this script as root."
        exit 1
    fi
}

get_package_manager() {
    if command_exists apt; then
        echo "apt"
    elif command_exists yum; then
        echo "yum"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists brew; then
        echo "brew"
    else
        echo ""
    fi
}

package_for_manager() {
    local package_group="$1"
    local package_manager="$2"

    case "$package_group:$package_manager" in
        openssh:apt) echo "openssh-client" ;;
        openssh:yum|openssh:dnf) echo "openssh-clients" ;;
        openssh:pacman|openssh:brew) echo "openssh" ;;
        gpg:apt|gpg:pacman|gpg:brew) echo "gnupg" ;;
        gpg:yum|gpg:dnf) echo "gnupg2" ;;
        pgrep:apt|pgrep:pacman) echo "procps" ;;
        pgrep:yum|pgrep:dnf) echo "procps-ng" ;;
        *) echo "$package_group" ;;
    esac
}

install_package_group() {
    local package_group="$1"
    local package_manager
    local package_name

    package_manager="$(get_package_manager)"

    if [[ -z "$package_manager" ]]; then
        print_color "$RED" "❌ No supported package manager found. Please install $package_group manually."
        exit 1
    fi

    package_name="$(package_for_manager "$package_group" "$package_manager")"

    case "$package_manager" in
        apt)
            run_privileged apt update
            run_privileged apt install -y "$package_name"
            ;;
        yum)
            run_privileged yum install -y "$package_name"
            ;;
        dnf)
            run_privileged dnf install -y "$package_name"
            ;;
        pacman)
            run_privileged pacman -S --noconfirm "$package_name"
            ;;
        brew)
            brew install "$package_name"
            ;;
    esac
}

prompt_install_dependency() {
    local display_name="$1"
    local answer

    if [[ ! -t 0 ]]; then
        print_color "$RED" "❌ Cannot prompt to install $display_name in a non-interactive shell."
        print_color "$YELLOW" "Please install $display_name and run this script again."
        exit 1
    fi

    read -rp "📦 Install $display_name now? (y/N): " answer

    if ! echo "$answer" | grep -iq "^y"; then
        print_color "$RED" "❌ Cannot continue without $display_name. Please install it and run this script again."
        exit 1
    fi
}

ensure_dependency() {
    local command_name="$1"
    local package_group="${2:-$command_name}"
    local display_name="${3:-$command_name}"

    if command_exists "$command_name"; then
        return 0
    fi

    print_color "$YELLOW" "⚠️  $display_name is required but not installed."
    prompt_install_dependency "$display_name"

    print_color "$BLUE" "⏳ Installing $display_name..."
    install_package_group "$package_group"

    if ! command_exists "$command_name"; then
        print_color "$RED" "❌ $display_name still was not found after installation. Please install it manually."
        exit 1
    fi

    print_color "$GREEN" "✅ $display_name installed successfully"
}

ensure_ssh_dependencies() {
    local missing=()
    local command_name

    for command_name in ssh-keygen ssh-agent ssh-add ssh; do
        if ! command_exists "$command_name"; then
            missing+=("$command_name")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        return 0
    fi

    print_color "$YELLOW" "⚠️  OpenSSH tools are required but missing: ${missing[*]}"
    prompt_install_dependency "OpenSSH tools"

    print_color "$BLUE" "⏳ Installing OpenSSH tools..."
    install_package_group "openssh"

    for command_name in "${missing[@]}"; do
        if ! command_exists "$command_name"; then
            print_color "$RED" "❌ $command_name still was not found after installation. Please install OpenSSH tools manually."
            exit 1
        fi
    done

    print_color "$GREEN" "✅ OpenSSH tools installed successfully"
}

detect_os() {
    OS_TYPE="$(uname | tr '[:upper:]' '[:lower:]')"

    if [[ "$OS_TYPE" == "darwin" ]]; then
        IS_MAC=true
        print_color "$BLUE" "🍏 macOS detected"
    elif [[ "$OS_TYPE" == *"mingw"* || "$OS_TYPE" == *"cygwin"* || "$OS_TYPE" == *"msys"* ]]; then
        IS_WINDOWS=true
        print_color "$BLUE" "🪟 Windows detected"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        IS_LINUX=true
        print_color "$BLUE" "🐧 Linux detected"
    else
        print_color "$YELLOW" "⚠️  Unknown OS: $OS_TYPE (treating as Linux)"
        IS_LINUX=true
    fi
}

select_signing_method() {
    while true; do
        read -rp "🤔 Do you want to set up SSH or GPG for signing commits? [ssh/gpg] (default: ssh): " SIGNING_METHOD
        SIGNING_METHOD="$(echo "$SIGNING_METHOD" | tr '[:upper:]' '[:lower:]')"
        SIGNING_METHOD="${SIGNING_METHOD:-ssh}"

        if [[ "$SIGNING_METHOD" == "ssh" || "$SIGNING_METHOD" == "gpg" ]]; then
            break
        fi

        print_color "$RED" "❌ Please enter 'ssh' or 'gpg' (or press ENTER for default: ssh)."
    done
}

ensure_required_dependencies() {
    ensure_dependency "git" "git" "Git"

    if [[ "$SIGNING_METHOD" == "ssh" ]]; then
        ensure_ssh_dependencies

        if [[ "$IS_LINUX" == true ]]; then
            ensure_dependency "pgrep" "pgrep" "process tools (pgrep)"
        fi
    else
        ensure_dependency "gpg" "gpg" "GPG"
    fi
}

configure_git_identity() {
    local existing_name
    local existing_email

    existing_name="$(git config --global user.name || echo "")"
    existing_email="$(git config --global user.email || echo "")"

    if [[ -n "$existing_name" ]]; then
        read -rp "👤 Enter your Git username (default: $existing_name): " GIT_USERNAME
        GIT_USERNAME="${GIT_USERNAME:-$existing_name}"
    else
        read -rp "👤 Enter your Git username: " GIT_USERNAME
    fi

    if [[ -n "$existing_email" ]]; then
        read -rp "📧 Enter your Git email (default: $existing_email): " GIT_EMAIL
        GIT_EMAIL="${GIT_EMAIL:-$existing_email}"
    else
        read -rp "📧 Enter your Git email: " GIT_EMAIL
    fi

    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
}

backup_file() {
    local file_path="$1"
    local backup_path

    if [[ ! -f "$file_path" ]]; then
        return 0
    fi

    backup_path="$file_path.bak_$(date +%Y%m%d%H%M%S)"
    cp "$file_path" "$backup_path"
    print_color "$YELLOW" "📝 Backup created: $backup_path"
}

ensure_file() {
    local file_path="$1"
    local mode="$2"

    mkdir -p "$(dirname "$file_path")"

    if [[ ! -e "$file_path" ]]; then
        touch "$file_path"
    fi

    chmod "$mode" "$file_path"
}

ensure_rc_file() {
    local file_path="$1"

    mkdir -p "$(dirname "$file_path")"

    if [[ ! -e "$file_path" ]]; then
        touch "$file_path"
        chmod 644 "$file_path"
    fi
}

choose_ssh_key_path() {
    local default_key="$HOME/.ssh/id_ed25519"
    local selected_key
    local answer

    read -rp "📁 Enter a filename for your SSH key (default: $default_key): " selected_key
    selected_key="${selected_key:-$default_key}"

    while [[ -f "$selected_key" ]]; do
        print_color "$YELLOW" "⚠️  SSH key '$selected_key' already exists."
        echo "   1) Use existing key"
        echo "   2) Choose another path"
        read -rp "   Choose an option (1/2, default: 1): " answer

        case "${answer:-1}" in
            1)
                SSH_KEY="$selected_key"
                SSH_KEY_CREATED=false
                return 0
                ;;
            2)
                read -rp "📁 Enter a new SSH key path: " selected_key
                if [[ -z "$selected_key" ]]; then
                    selected_key="$default_key"
                fi
                ;;
            *)
                print_color "$RED" "❌ Please enter 1 or 2."
                ;;
        esac
    done

    SSH_KEY="$selected_key"
    SSH_KEY_CREATED=true
    return 0
}

generate_ssh_key() {
    local ssh_key="$1"
    local ssh_comment

    read -rp "💬 Enter a comment for your SSH key (default: $GIT_EMAIL): " ssh_comment
    ssh_comment="${ssh_comment:-$GIT_EMAIL}"

    print_color "$YELLOW" "📝 ssh-keygen will prompt you for a passphrase. Use one to protect the private key."
    print_color "$BLUE" "🚀 Generating SSH key..."
    ssh-keygen -t ed25519 -C "$ssh_comment" -f "$ssh_key"
}

add_ssh_key_to_agent() {
    local ssh_key="$1"

    print_color "$BLUE" "🔄 Adding SSH key to agent..."

    if [[ "$IS_MAC" == true ]]; then
        print_color "$BLUE" "🍏 Using macOS Keychain integration..."

        if ! ssh-add --apple-use-keychain "$ssh_key"; then
            print_color "$YELLOW" "⚠️  macOS Keychain add failed; falling back to plain ssh-add."
            ssh-add "$ssh_key"
        fi

        configure_macos_ssh_config "$ssh_key"
    else
        eval "$(ssh-agent -s)"
        ssh-add "$ssh_key"
        configure_ssh_agent_autostart "$ssh_key"
    fi
}

configure_macos_ssh_config() {
    local ssh_key="$1"
    local ssh_config="$HOME/.ssh/config"

    ensure_file "$ssh_config" 600

    if grep -q "### GIT SIGNING SSH-AGENT SETUP" "$ssh_config" 2>/dev/null; then
        print_color "$YELLOW" "ℹ️  SSH config already contains setup"
        return 0
    fi

    backup_file "$ssh_config"

    cat >> "$ssh_config" <<EOF

### GIT SIGNING SSH-AGENT SETUP (Added by setup wizard)
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $ssh_key
### END GIT SIGNING SSH-AGENT SETUP
EOF

    print_color "$GREEN" "✅ SSH config updated with Keychain integration"
}

detect_shell_rc() {
    local current_shell

    if [[ "$IS_WINDOWS" == true ]]; then
        if [[ -f "$HOME/.bashrc" ]]; then
            echo "$HOME/.bashrc"
        else
            echo "$HOME/.bash_profile"
        fi

        return 0
    fi

    current_shell="$(basename "${SHELL:-bash}")"

    case "$current_shell" in
        zsh) echo "$HOME/.zshrc" ;;
        bash) echo "$HOME/.bashrc" ;;
        *) echo "$HOME/.bashrc" ;;
    esac
}

configure_ssh_agent_autostart() {
    local ssh_key="$1"
    local shell_rc

    shell_rc="$(detect_shell_rc)"
    SSH_AGENT_RC_FILE="$shell_rc"
    ensure_rc_file "$shell_rc"

    if grep -q "### GIT SIGNING SSH-AGENT SETUP" "$shell_rc" 2>/dev/null; then
        print_color "$YELLOW" "ℹ️  ssh-agent auto-load already configured"
        return 0
    fi

    backup_file "$shell_rc"

    if [[ "$IS_WINDOWS" == true ]]; then
        cat >> "$shell_rc" <<EOF

### GIT SIGNING SSH-AGENT SETUP (Added by setup wizard)
eval "\$(ssh-agent -s)" > /dev/null
ssh-add "$ssh_key"
### END GIT SIGNING SSH-AGENT SETUP
EOF
    else
        cat >> "$shell_rc" <<EOF

### GIT SIGNING SSH-AGENT SETUP (Added by setup wizard)
if ! pgrep -u "\$USER" ssh-agent > /dev/null; then
    eval "\$(ssh-agent -s)" > /dev/null
    ssh-add "$ssh_key"
fi
### END GIT SIGNING SSH-AGENT SETUP
EOF
    fi

    print_color "$GREEN" "✅ ssh-agent auto-load configured in $shell_rc"
}

configure_ssh_allowed_signers() {
    local ssh_public_key="$1"
    local allowed_signers="$HOME/.config/git/allowed_signers"
    local public_key_content
    local temp_file

    public_key_content="$(cat "$ssh_public_key")"
    ensure_file "$allowed_signers" 600
    backup_file "$allowed_signers"

    temp_file="$(mktemp)"
    trap 'rm -f "$temp_file"' ERR RETURN

    awk -v email="$GIT_EMAIL" '$1 != email' "$allowed_signers" > "$temp_file"
    printf '%s %s\n' "$GIT_EMAIL" "$public_key_content" >> "$temp_file"
    mv "$temp_file" "$allowed_signers"
    trap - ERR RETURN

    git config --global gpg.ssh.allowedSignersFile "$allowed_signers"
    print_color "$GREEN" "✅ SSH allowed signers configured: $allowed_signers"
}

configure_git_ssh_signing() {
    local ssh_key="$1"
    local ssh_public_key="$ssh_key.pub"

    if [[ ! -f "$ssh_public_key" ]]; then
        print_color "$YELLOW" "⚠️  Public key not found: $ssh_public_key"
        print_color "$BLUE" "⏳ Regenerating public key from private key..."
        # Passphrase-protected private keys will prompt here, which is expected.
        ssh-keygen -y -f "$ssh_key" > "$ssh_public_key"
        chmod 644 "$ssh_public_key"
    fi

    git config --global gpg.format ssh
    git config --global user.signingkey "$ssh_public_key"
    git config --global commit.gpgsign true
    configure_ssh_allowed_signers "$ssh_public_key"
}

setup_ssh_signing() {
    echo -e "\n${BLUE}🔑 Setting up SSH commit signing...${NC}"

    choose_ssh_key_path

    if [[ "$SSH_KEY_CREATED" == true ]]; then
        generate_ssh_key "$SSH_KEY"
    fi

    add_ssh_key_to_agent "$SSH_KEY"
    configure_git_ssh_signing "$SSH_KEY"

    echo -e "\n${GREEN}✅ SSH signing key configured.${NC}"

    if [[ "$SSH_KEY_CREATED" == true ]]; then
        echo "📋 Copy the following public key and add it to GitHub as auth and signing key:"
    else
        echo "📋 Ensure the following public key is added to GitHub as auth and signing key:"
    fi

    echo "-------------------------------------------------------"
    cat "$SSH_KEY.pub"
    echo "-------------------------------------------------------"

    echo -e "\n${YELLOW}👉 IMPORTANT: Add your SSH public key to GitHub (${BOLD}Settings → SSH and GPG Keys${NC}${YELLOW}) before testing.${NC}"
    maybe_test_ssh_connection "$SSH_KEY"
}

maybe_test_ssh_connection() {
    local ssh_key="$1"
    local test_ssh

    read -rp "🔎 Do you want to test SSH connection to GitHub now? (y/n): " test_ssh

    if [[ "$test_ssh" =~ ^[Yy]$ ]]; then
        ssh -o StrictHostKeyChecking=accept-new -i "$ssh_key" -T git@github.com || \
            print_color "$YELLOW" "⚠️  SSH connection test failed. Make sure you've added the key to GitHub."
    else
        print_color "$YELLOW" "ℹ️  Skipped SSH connection test. Remember to add your key to GitHub before using it."
        print_color "$YELLOW" "ℹ️  Then manually run: ssh -i $ssh_key -T git@github.com"
    fi
}

setup_gpg_signing() {
    local gpg_name
    local gpg_key_id

    echo -e "\n${BLUE}🔑 Setting up GPG commit signing...${NC}"

    read -rp "👤 Enter real name for GPG key (default: $GIT_USERNAME): " gpg_name
    gpg_name="${gpg_name:-$GIT_USERNAME}"

    print_color "$YELLOW" "📝 GPG will prompt you for a passphrase through pinentry."
    print_color "$BLUE" "🚀 Generating GPG key..."

    gpg --quick-generate-key "$gpg_name <$GIT_EMAIL>" rsa4096 sign 1y

    gpg_key_id="$(gpg --list-secret-keys --keyid-format=long "$GIT_EMAIL" | awk '/sec/ {split($2, parts, "/"); print parts[2]; exit}')"

    if [[ -z "$gpg_key_id" ]]; then
        print_color "$RED" "❌ Could not find the generated GPG key for $GIT_EMAIL."
        exit 1
    fi

    git config --global user.signingkey "$gpg_key_id"
    git config --global commit.gpgsign true

    echo -e "\n${GREEN}✅ GPG signing key ready.${NC}"
    echo "📋 Copy the following GPG public key and add it to GitHub:"
    echo "-------------------------------------------------------"
    gpg --armor --export "$gpg_key_id"
    echo "-------------------------------------------------------"
}

show_final_message() {
    echo -e "\n${GREEN}🎉 Setup complete! Your commits will now be signed.${NC}"
    echo -e "${BLUE}💡 Next Steps:${NC}"
    echo -e "   - Add your SSH/GPG key to GitHub if you haven't already"
    echo -e "   - Push a signed commit to test"
    echo -e "   - Verify with: ${BOLD}git log --show-signature${NC}"

    if [[ "$IS_MAC" == false && "$SIGNING_METHOD" == "ssh" && -n "$SSH_AGENT_RC_FILE" ]]; then
        echo -e "\n${YELLOW}📝 Note: You may need to restart your terminal or run 'source $SSH_AGENT_RC_FILE' for ssh-agent to start automatically.${NC}"
    fi
}

main() {
    parse_args "$@"
    show_banner
    detect_os
    select_signing_method
    ensure_required_dependencies
    configure_git_identity

    if [[ "$SIGNING_METHOD" == "ssh" ]]; then
        setup_ssh_signing
    else
        setup_gpg_signing
    fi

    show_final_message
}

main "$@"
