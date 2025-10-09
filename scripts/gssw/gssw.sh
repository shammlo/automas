#!/usr/bin/env bash
#
# Description: Git commit signing setup wizard for SSH and GPG key configuration
set -e

# -----------------------------
# Colors and Formatting
# -----------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# -----------------------------
# Pretty Header
# -----------------------------
echo -e "\n${BLUE}✨===========================================✨${NC}"
echo -e "     ${BOLD}🔐  Git Commit Signing Setup Wizard${NC}"
echo -e "${BLUE}✨===========================================✨${NC}\n"
echo -e "${YELLOW}This script will configure Git commit signing"
echo -e "using either SSH or GPG keys.${NC}"
echo "-------------------------------------------------------"

# -----------------------------
# Help Option
# -----------------------------
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo -e "${BOLD}🔐 Git Commit Signing Setup Wizard${NC}"
    echo "----------------------------------"
    echo "This script helps you configure Git commit signing using SSH or GPG."
    echo
    echo "Features:"
    echo "  • Generates a new SSH or GPG key (with passphrase)."
    echo "  • Configures your Git username and email (if not already set)."
    echo "  • Automatically enables signed commits globally."
    echo "  • Adds your SSH key to the ssh-agent and configures it to start automatically."
    echo "  • Uses macOS Keychain integration when available."
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
    exit 0
fi

# -----------------------------
# OS Detection
# -----------------------------
OS_TYPE=$(uname | tr '[:upper:]' '[:lower:]')
IS_MAC=false
IS_WINDOWS=false
IS_LINUX=false

if [[ "$OS_TYPE" == "darwin" ]]; then
    IS_MAC=true
    echo -e "${BLUE}🍏 macOS detected${NC}"
elif [[ "$OS_TYPE" == *"mingw"* || "$OS_TYPE" == *"cygwin"* || "$OS_TYPE" == *"msys"* ]]; then
    IS_WINDOWS=true
    echo -e "${BLUE}🪟 Windows detected${NC}"
elif [[ "$OS_TYPE" == "linux" ]]; then
    IS_LINUX=true
    echo -e "${BLUE}🐧 Linux detected${NC}"
else
    echo -e "${YELLOW}⚠️  Unknown OS: $OS_TYPE (treating as Linux)${NC}"
    IS_LINUX=true
fi

# -----------------------------
# Select Signing Method
# -----------------------------
while true; do
    read -rp "🤔 Do you want to set up SSH or GPG for signing commits? [ssh/gpg] (default: ssh): " SIGNING_METHOD
    SIGNING_METHOD=$(echo "$SIGNING_METHOD" | tr '[:upper:]' '[:lower:]')
    SIGNING_METHOD=${SIGNING_METHOD:-ssh}  # default to ssh
    if [[ "$SIGNING_METHOD" == "ssh" || "$SIGNING_METHOD" == "gpg" ]]; then
        break
    else
        echo -e "${RED}❌ Please enter 'ssh' or 'gpg' (or press ENTER for default: ssh).${NC}"
    fi
done

# -----------------------------
# Detect existing global Git username/email
# -----------------------------
EXISTING_NAME=$(git config --global user.name || echo "")
EXISTING_EMAIL=$(git config --global user.email || echo "")

if [[ -n "$EXISTING_NAME" ]]; then
  read -rp "👤 Enter your Git username (default: $EXISTING_NAME): " GIT_USERNAME
  GIT_USERNAME=${GIT_USERNAME:-$EXISTING_NAME}
else
  read -rp "👤 Enter your Git username: " GIT_USERNAME
fi

if [[ -n "$EXISTING_EMAIL" ]]; then
  read -rp "📧 Enter your Git email (default: $EXISTING_EMAIL): " GIT_EMAIL
  GIT_EMAIL=${GIT_EMAIL:-$EXISTING_EMAIL}
else
  read -rp "📧 Enter your Git email: " GIT_EMAIL
fi

git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"

# ============================================================
# SSH Key Setup
# ============================================================
if [[ "$SIGNING_METHOD" == "ssh" ]]; then
    echo -e "\n${BLUE}🔑 Setting up SSH commit signing...${NC}"
    DEFAULT_SSH_KEY="$HOME/.ssh/id_ed25519"

    read -rp "📁 Enter a filename for your SSH key (default: $DEFAULT_SSH_KEY): " SSH_KEY
    SSH_KEY=${SSH_KEY:-$DEFAULT_SSH_KEY}

    # Auto-increment filename if it already exists
    COUNTER=1
    while [[ -f "$SSH_KEY" ]]; do
        echo -e "${YELLOW}⚠️  SSH key '$SSH_KEY' already exists.${NC}"
        SSH_KEY="${DEFAULT_SSH_KEY}_${COUNTER}"
        COUNTER=$((COUNTER + 1))
        echo -e "🔄 Trying new filename: ${BOLD}$SSH_KEY${NC}"
    done

    read -rp "💬 Enter a comment for your SSH key (default: $GIT_EMAIL): " SSH_COMMENT
    SSH_COMMENT=${SSH_COMMENT:-$GIT_EMAIL}

    # Mandatory passphrase prompt
    while true; do
        read -rsp "📝 Enter SSH passphrase: " SSH_PASSPHRASE
        echo
        read -rsp "🔄 Confirm SSH passphrase: " CONFIRM_PASSPHRASE
        echo
        if [[ -z "$SSH_PASSPHRASE" ]]; then
            echo -e "${RED}❌ Passphrase cannot be empty. Please try again.${NC}"
        elif [[ "$SSH_PASSPHRASE" != "$CONFIRM_PASSPHRASE" ]]; then
            echo -e "${RED}❌ Passphrases do not match. Please try again.${NC}"
        else
            break
        fi
    done

    echo -e "🚀 ${BOLD}Generating SSH key...${NC}"
    ssh-keygen -t ed25519 -C "$SSH_COMMENT" -f "$SSH_KEY" -N "$SSH_PASSPHRASE"

    echo -e "🔄 ${BOLD}Adding SSH key to agent...${NC}"

    # Platform-specific SSH agent configuration
    if [[ "$IS_MAC" == true ]]; then
        echo -e "${BLUE}🍏 Using macOS Keychain integration...${NC}"
        ssh-add --apple-use-keychain "$SSH_KEY"

        # Configure SSH config for macOS
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        touch ~/.ssh/config
        chmod 600 ~/.ssh/config

        if ! grep -q "### GIT SIGNING SSH-AGENT SETUP" ~/.ssh/config 2>/dev/null; then
            cat >> ~/.ssh/config <<EOF

### GIT SIGNING SSH-AGENT SETUP (Added by setup wizard)
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $SSH_KEY
### END GIT SIGNING SSH-AGENT SETUP
EOF
            echo -e "${GREEN}✅ SSH config updated with Keychain integration${NC}"
        else
            echo -e "${YELLOW}ℹ️  SSH config already contains setup${NC}"
        fi

    else
        # Linux/Windows: Standard ssh-agent approach
        eval "$(ssh-agent -s)"
        ssh-add "$SSH_KEY"

        # Configure shell RC files for auto-start
        if [[ "$IS_WINDOWS" == true ]]; then
            WIN_RC="$HOME/.bash_profile"
            cp "$WIN_RC" "$WIN_RC.bak_$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
            if ! grep -q "### GIT SIGNING SSH-AGENT SETUP" "$WIN_RC" 2>/dev/null; then
                echo "

### GIT SIGNING SSH-AGENT SETUP (Added by setup wizard)
eval \"\$(ssh-agent -s)\" > /dev/null
ssh-add $SSH_KEY
### END GIT SIGNING SSH-AGENT SETUP
" >> "$WIN_RC"
                echo -e "${GREEN}✅ ssh-agent auto-load configured in $WIN_RC${NC}"
            else
                echo -e "${YELLOW}ℹ️  ssh-agent auto-load already configured${NC}"
            fi
        else
            # Linux
            CURRENT_SHELL=$(basename "$SHELL")
            case "$CURRENT_SHELL" in
              zsh) SHELL_RC="$HOME/.zshrc" ;;
              bash) SHELL_RC="$HOME/.bashrc" ;;
              *) SHELL_RC="$HOME/.bashrc" ;;  # fallback
            esac

            cp "$SHELL_RC" "$SHELL_RC.bak_$(date +%Y%m%d%H%M%S)" 2>/dev/null || true

            if ! grep -q "### GIT SIGNING SSH-AGENT SETUP" "$SHELL_RC" 2>/dev/null; then
                echo "

### GIT SIGNING SSH-AGENT SETUP (Added by setup wizard)
if ! pgrep -u \"\$USER\" ssh-agent > /dev/null; then
    eval \"\$(ssh-agent -s)\" > /dev/null
    ssh-add $SSH_KEY
fi
### END GIT SIGNING SSH-AGENT SETUP
" >> "$SHELL_RC"
                echo -e "${GREEN}✅ ssh-agent auto-load configured in $SHELL_RC${NC}"
            else
                echo -e "${YELLOW}ℹ️  ssh-agent auto-load already configured${NC}"
            fi
        fi
    fi

    # Configure Git for SSH signing
    git config --global gpg.format ssh
    git config --global user.signingkey "$SSH_KEY"
    git config --global commit.gpgsign true

    echo -e "\n${GREEN}✅ SSH signing key generated and configured.${NC}"
    echo "📋 Copy the following public key and add it to GitHub as auth and signing key:"
    echo "-------------------------------------------------------"
    cat "$SSH_KEY.pub"
    echo "-------------------------------------------------------"

    echo -e "\n${YELLOW}👉 IMPORTANT: Add your SSH public key to GitHub (${BOLD}Settings → SSH and GPG Keys${NC}${YELLOW}) before testing.${NC}"

    read -rp "🔎 Do you want to test SSH connection to GitHub now? (y/n): " TEST_SSH
    if [[ "$TEST_SSH" =~ ^[Yy]$ ]]; then
        ssh -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" -T git@github.com || \
        echo -e "${YELLOW}⚠️  SSH connection test failed. Make sure you've added the key to GitHub.${NC}"
    else
        echo -e "${YELLOW}ℹ️  Skipped SSH connection test. Remember to add your key to GitHub before using it.${NC}"
        echo -e "${YELLOW}ℹ️  Then manually run: ssh -i $SSH_KEY -T git@github.com${NC}"
    fi

# ============================================================
# GPG Key Setup
# ============================================================
elif [[ "$SIGNING_METHOD" == "gpg" ]]; then
    echo -e "\n${BLUE}🔑 Setting up GPG commit signing...${NC}"

    read -rp "👤 Enter real name for GPG key (default: $GIT_USERNAME): " GPG_NAME
    GPG_NAME=${GPG_NAME:-$GIT_USERNAME}

    # Mandatory passphrase prompt
    while true; do
        read -rsp "📝 Enter GPG passphrase (mandatory): " GPG_PASSPHRASE
        echo
        read -rsp "🔄 Confirm GPG passphrase: " CONFIRM_PASSPHRASE
        echo
        if [[ -z "$GPG_PASSPHRASE" ]]; then
            echo -e "${RED}❌ Passphrase cannot be empty. Please try again.${NC}"
        elif [[ "$GPG_PASSPHRASE" != "$CONFIRM_PASSPHRASE" ]]; then
            echo -e "${RED}❌ Passphrases do not match. Please try again.${NC}"
        else
            break
        fi
    done

    echo -e "🚀 ${BOLD}Generating GPG key...${NC}"

    # Create batch file for GPG key generation
    cat > gpg_batch <<EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Name-Real: $GPG_NAME
Name-Email: $GIT_EMAIL
Expire-Date: 1y
Passphrase: $GPG_PASSPHRASE
%commit
%echo done
EOF

    gpg --batch --gen-key gpg_batch
    rm gpg_batch

    # Fetch GPG key ID safely
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$GIT_EMAIL" | grep 'sec' | head -n1 | awk '{print $2}' | cut -d'/' -f2)

    git config --global user.signingkey "$GPG_KEY_ID"
    git config --global commit.gpgsign true

    echo -e "\n${GREEN}✅ GPG signing key ready.${NC}"
    echo "📋 Copy the following GPG public key and add it to GitHub:"
    echo "-------------------------------------------------------"
    gpg --armor --export "$GPG_KEY_ID"
    echo "-------------------------------------------------------"
fi

# ============================================================
# Final Message
# ============================================================
echo -e "\n${GREEN}🎉 Setup complete! Your commits will now be signed.${NC}"
echo -e "${BLUE}💡 Next Steps:${NC}"
echo -e "   - Add your SSH/GPG key to GitHub if you haven't already"
echo -e "   - Push a signed commit to test"
echo -e "   - Verify with: ${BOLD}git log --show-signature${NC}"

if [[ "$IS_MAC" == false && "$SIGNING_METHOD" == "ssh" ]]; then
    echo -e "\n${YELLOW}📝 Note: You may need to restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc) for ssh-agent to start automatically.${NC}"
fi