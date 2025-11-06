#!/bin/bash
#
# Description: Interactive Zsh installation and configuration script with Oh My Zsh and popular plugins

# Exit on error, undefined variables, and propagate pipe errors
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script version
readonly SCRIPT_VERSION="1.1.0"

# Global variables
INSTALL_OH_MY_ZSH=false
ZSH_THEME="robbyrussell"
ZSH_DEFAULT=false
INSTALL_ZSH_PLUGINS=false
ZSH_PLUGINS_SELECTED=""
SELECTIONS=()

# OS Detection - set once at startup
IS_MACOS=false
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MACOS=true
fi

#######################################
# Print colored output
#######################################
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

#######################################
# Cross-platform sed in-place editing
#######################################
sed_inplace() {
    local pattern="$1"
    local file="$2"
    
    if [ "$IS_MACOS" = true ]; then
        sed -i '' "$pattern" "$file"
    else
        sed -i "$pattern" "$file"
    fi
}

#######################################
# Print script banner
#######################################
show_banner() {
    clear
    print_color "$CYAN" "
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║              ███████╗███████╗██╗  ██╗ ██████╗              ║
║              ╚══███╔╝██╔════╝██║  ██║██╔═══██╗             ║
║                ███╔╝ ███████╗███████║██║   ██║             ║
║               ███╔╝  ╚════██║██╔══██║██║   ██║             ║
║              ███████╗███████║██║  ██║╚██████╔╝             ║
║              ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝              ║
║                                                            ║
║              🚀 Zsh Setup Wizard v${SCRIPT_VERSION} 🚀                 ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
"
    print_color "$YELLOW" "Interactive Zsh installation and configuration script"
    print_color "$BLUE" "Automates Oh My Zsh setup with popular plugins and themes"
    echo
}

#######################################
# Show help information
#######################################
show_help() {
    show_banner
    print_color "$BOLD" "USAGE:"
    echo "  $0 [OPTIONS]"
    echo
    print_color "$BOLD" "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Show version information"
    echo "  --dry-run      Show what would be installed without executing"
    echo "  --quiet        Minimal output"
    echo
    print_color "$BOLD" "FEATURES:"
    echo "  • Automatic Zsh installation"
    echo "  • Oh My Zsh framework setup"
    echo "  • Popular theme selection"
    echo "  • Essential plugin installation"
    echo "  • Default shell configuration"
    echo "  • Backup and rollback support"
    echo
    print_color "$BOLD" "SUPPORTED PLUGINS:"
    echo "  • zsh-autosuggestions     - Command suggestions based on history"
    echo "  • zsh-syntax-highlighting - Syntax highlighting for commands"
    echo "  • fast-syntax-highlighting - Faster syntax highlighting"
    echo "  • zsh-autocomplete        - Real-time autocomplete"
    echo
    print_color "$BOLD" "EXAMPLES:"
    echo "  $0                        # Interactive setup"
    echo "  $0 --dry-run             # Preview changes"
    echo
}

#######################################
# Check if command exists
#######################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# Show progress message
#######################################
show_progress() {
    local message="$1"
    print_color "$BLUE" "⏳ $message"
}

#######################################
# Install component with feedback
#######################################
install_component() {
    local component="$1"
    print_color "$GREEN" "✅ $component installed successfully"
}

#######################################
# Install Zsh and configure it
#######################################
install_zsh() {
    # Install Zsh if not already installed
    if ! command_exists zsh; then
        print_color "$BLUE" "📦 Installing Zsh..."
        
        # Detect package manager and install
        if command_exists apt; then
            sudo apt update && sudo apt install -y zsh
        elif command_exists yum; then
            sudo yum install -y zsh
        elif command_exists dnf; then
            sudo dnf install -y zsh
        elif command_exists pacman; then
            sudo pacman -S --noconfirm zsh
        elif command_exists brew; then
            brew install zsh
        else
            print_color "$RED" "❌ No supported package manager found. Please install Zsh manually."
            exit 1
        fi
        
        install_component "Zsh"
    else
        print_color "$YELLOW" "⚠️  Zsh is already installed, skipping installation."
    fi

    # Install Oh My Zsh if requested
    if [ "$INSTALL_OH_MY_ZSH" = true ]; then
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            show_progress "Installing Oh My Zsh..."
            # Use RUNZSH=no to prevent automatic zsh execution
            RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
            install_component "Oh My Zsh"
            
            # Set theme if specified
            if [ -n "$ZSH_THEME" ] && [ "$ZSH_THEME" != "Default" ] && [ -f "$HOME/.zshrc" ]; then
                sed_inplace "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"$ZSH_THEME\"/" "$HOME/.zshrc"
                print_color "$CYAN" "  - Theme set to: $ZSH_THEME"
            fi
        else
            print_color "$YELLOW" "⚠️  Oh My Zsh already installed, skipping."
        fi
    fi

    # Set as default shell if requested
    CURRENT_SHELL=$(basename "$SHELL")
    if [ "$ZSH_DEFAULT" = true ] && [ "$CURRENT_SHELL" != "zsh" ]; then
        chsh -s "$(which zsh)"
        show_progress "Setting Zsh as default shell..."
        print_color "$GREEN" "✅ Zsh is now your default shell"
    elif [ "$ZSH_DEFAULT" = true ]; then
        print_color "$YELLOW" "⚠️  Zsh is already your default shell."
    fi

    # Install Zsh plugins (only if Oh My Zsh is installed)
    if [ "$INSTALL_ZSH_PLUGINS" = true ] && [ "$INSTALL_OH_MY_ZSH" = true ]; then
        declare -a PLUGINS_TO_ADD=()
        ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
        
        # Ensure Oh My Zsh custom plugins directory exists
        mkdir -p "$ZSH_CUSTOM/plugins"
        
        for plugin in $ZSH_PLUGINS_SELECTED; do
            case "$plugin" in
                "Auto-Suggestions")
                    PLUGIN_PATH="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
                    if [ ! -d "$PLUGIN_PATH" ]; then
                        show_progress "Installing zsh-autosuggestions..."
                        git clone https://github.com/zsh-users/zsh-autosuggestions.git "$PLUGIN_PATH"
                        install_component "zsh-autosuggestions"
                    else
                        print_color "$YELLOW" "⚠️  zsh-autosuggestions already installed"
                    fi
                    PLUGINS_TO_ADD+=("zsh-autosuggestions")
                    ;;
                "zsh-syntax-highlighting")
                    PLUGIN_PATH="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
                    if [ ! -d "$PLUGIN_PATH" ]; then
                        show_progress "Installing zsh-syntax-highlighting..."
                        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_PATH"
                        install_component "zsh-syntax-highlighting"
                    else
                        print_color "$YELLOW" "⚠️  zsh-syntax-highlighting already installed"
                    fi
                    PLUGINS_TO_ADD+=("zsh-syntax-highlighting")
                    ;;
                "zsh-fast-syntax-highlighting")
                    PLUGIN_PATH="$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
                    if [ ! -d "$PLUGIN_PATH" ]; then
                        show_progress "Installing fast-syntax-highlighting..."
                        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$PLUGIN_PATH"
                        install_component "fast-syntax-highlighting"
                    else
                        print_color "$YELLOW" "⚠️  fast-syntax-highlighting already installed"
                    fi
                    PLUGINS_TO_ADD+=("fast-syntax-highlighting")
                    ;;
                "zsh-autocomplete")
                    PLUGIN_PATH="$ZSH_CUSTOM/plugins/zsh-autocomplete"
                    if [ ! -d "$PLUGIN_PATH" ]; then
                        show_progress "Installing zsh-autocomplete..."
                        git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$PLUGIN_PATH"
                        install_component "zsh-autocomplete"
                    else
                        print_color "$YELLOW" "⚠️  zsh-autocomplete already installed"
                    fi
                    PLUGINS_TO_ADD+=("zsh-autocomplete")
                    ;;
            esac
        done

        # Update .zshrc with plugins
        if [ ${#PLUGINS_TO_ADD[@]} -gt 0 ] && [ -f "$HOME/.zshrc" ]; then
            # Create a backup of .zshrc
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
            
            # Check if plugins line exists and update it
            if grep -q "^plugins=" "$HOME/.zshrc"; then
                # Replace existing plugins line
                sed_inplace "s/^plugins=.*/plugins=(git ${PLUGINS_TO_ADD[*]})/" "$HOME/.zshrc"
            else
                # Add plugins line if it doesn't exist
                echo "plugins=(git ${PLUGINS_TO_ADD[*]})" >> "$HOME/.zshrc"
            fi
            
            print_color "$GREEN" "✅ Added plugins to .zshrc: git ${PLUGINS_TO_ADD[*]}"
            print_color "$CYAN" "💾 Backup created: ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
            print_color "$YELLOW" "⚠️  You will need to restart your terminal or run 'exec zsh' to use the new plugins"
        fi
    elif [ "$INSTALL_ZSH_PLUGINS" = true ] && [ "$INSTALL_OH_MY_ZSH" = false ]; then
        print_color "$YELLOW" "⚠️  Plugins require Oh My Zsh. Skipping plugin installation."
    fi

    # Verify installation
    if [ "$INSTALL_ZSH_PLUGINS" = true ] && [ "$INSTALL_OH_MY_ZSH" = true ]; then
        echo
        print_color "$BLUE" "🔍 Verifying plugin installation..."
        
        # Check if plugins are in .zshrc
        if [ -f "$HOME/.zshrc" ] && grep -q "plugins=" "$HOME/.zshrc"; then
            CONFIGURED_PLUGINS=$(grep "^plugins=" "$HOME/.zshrc" | sed 's/plugins=(//' | sed 's/)//')
            print_color "$GREEN" "✅ Plugins configured in .zshrc: $CONFIGURED_PLUGINS"
        else
            print_color "$RED" "❌ No plugins found in .zshrc"
        fi
        
        # Check if plugin directories exist
        ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
        for plugin in $ZSH_PLUGINS_SELECTED; do
            case "$plugin" in
                "Auto-Suggestions")
                    [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && print_color "$GREEN" "✅ zsh-autosuggestions directory exists" || print_color "$RED" "❌ zsh-autosuggestions directory missing"
                    ;;
                "zsh-syntax-highlighting")
                    [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && print_color "$GREEN" "✅ zsh-syntax-highlighting directory exists" || print_color "$RED" "❌ zsh-syntax-highlighting directory missing"
                    ;;
                "zsh-fast-syntax-highlighting")
                    [ -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ] && print_color "$GREEN" "✅ fast-syntax-highlighting directory exists" || print_color "$RED" "❌ fast-syntax-highlighting directory missing"
                    ;;
                "zsh-autocomplete")
                    [ -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ] && print_color "$GREEN" "✅ zsh-autocomplete directory exists" || print_color "$RED" "❌ zsh-autocomplete directory missing"
                    ;;
            esac
        done
    fi

    print_color "$GREEN" "✅ Zsh setup completed successfully!"
}

#######################################
# Configure Zsh interactively
#######################################
configure_zsh() {
    print_color "$GREEN" "✅ Zsh will be installed"
    SELECTIONS+=("zsh")
    
    echo
    # Ask about Oh My Zsh
    read -p "✨ Install Oh My Zsh? (y/N): " -r
    INSTALL_OH_MY_ZSH=$(echo "$REPLY" | grep -iq "^y" && echo true || echo false)
    
    if [ "$INSTALL_OH_MY_ZSH" = true ]; then
        echo
        print_color "$PURPLE" "   📜 Select the desired theme:"
        echo "   1) robbyrussell (default)"
        echo "   2) agnoster"
        echo "   3) avit"
        echo "   4) bira"
        echo "   5) Default"
        read -p "   Enter choice (1-5): " theme_choice
        case $theme_choice in
            1) ZSH_THEME="robbyrussell" ;;
            2) ZSH_THEME="agnoster" ;;
            3) ZSH_THEME="avit" ;;
            4) ZSH_THEME="bira" ;;
            5) ZSH_THEME="Default" ;;
            *) ZSH_THEME="robbyrussell" ;;
        esac
        print_color "$YELLOW" "   └── • Theme: $ZSH_THEME"
    fi
    
    echo
    # Ask about default shell
    read -p "⚙️  Set Zsh as default shell? (y/N): " -r
    ZSH_DEFAULT=$(echo "$REPLY" | grep -iq "^y" && echo true || echo false)
    print_color "$YELLOW" "   └── • Default shell: $([ "$ZSH_DEFAULT" = true ] && echo Yes || echo No)"
    
    echo
    # Ask about plugins (default to yes)
    read -p "🧩 Install Zsh plugins? (Y/n): " -r
    INSTALL_ZSH_PLUGINS=$(echo "$REPLY" | grep -iq "^n" && echo false || echo true)
    
    if [ "$INSTALL_ZSH_PLUGINS" = true ]; then
        echo
        print_color "$PURPLE" "   📜 Select plugins (enter numbers separated by spaces, or 'all'):"
        echo "   1) Auto-Suggestions"
        echo "   2) zsh-syntax-highlighting"
        echo "   3) zsh-fast-syntax-highlighting"
        echo "   4) zsh-autocomplete"
        echo "   all) All plugins (default)"
        read -p "   Enter choices [all]: " plugin_choices
        
        # Default to "all" if no input provided
        plugin_choices=${plugin_choices:-all}
        
        if [[ "$plugin_choices" == *"all"* ]]; then
            ZSH_PLUGINS_SELECTED="Auto-Suggestions zsh-syntax-highlighting zsh-fast-syntax-highlighting zsh-autocomplete"
        else
            ZSH_PLUGINS_SELECTED=""
            for choice in $plugin_choices; do
                case $choice in
                    1) ZSH_PLUGINS_SELECTED+="Auto-Suggestions " ;;
                    2) ZSH_PLUGINS_SELECTED+="zsh-syntax-highlighting " ;;
                    3) ZSH_PLUGINS_SELECTED+="zsh-fast-syntax-highlighting " ;;
                    4) ZSH_PLUGINS_SELECTED+="zsh-autocomplete " ;;
                esac
            done
        fi
        print_color "$YELLOW" "   └── • Plugins: $ZSH_PLUGINS_SELECTED"
    fi
}

#######################################
# Main function
#######################################
main() {
    local DRY_RUN=false
    local QUIET_MODE=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "Zsh Setup Script v${SCRIPT_VERSION}"
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                print_color "$YELLOW" "🧪 DRY RUN MODE - No changes will be made"
                ;;
            --quiet)
                QUIET_MODE=true
                ;;
            *)
                print_color "$RED" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done

    # Show banner
    show_banner

    # Check if running on supported system
    if [[ "$OSTYPE" != "linux-gnu"* ]] && [[ "$OSTYPE" != "darwin"* ]]; then
        print_color "$RED" "❌ This script currently supports Linux and macOS only."
        exit 1
    fi

    # Check for required dependencies
    if ! command_exists git; then
        print_color "$RED" "❌ Git is required but not installed. Please install Git first."
        exit 1
    fi

    if ! command_exists curl; then
        print_color "$RED" "❌ curl is required but not installed. Please install curl first."
        exit 1
    fi

    # Handle dry-run mode
    if [ "$DRY_RUN" = true ]; then
        print_color "$CYAN" "🧪 DRY RUN: Would perform the following actions:"
        print_color "$YELLOW" "   • Check and install Zsh if not present"
        print_color "$YELLOW" "   • Install Oh My Zsh framework"
        print_color "$YELLOW" "   • Configure theme and plugins"
        print_color "$YELLOW" "   • Optionally set Zsh as default shell"
        print_color "$YELLOW" "   • Create backup of existing .zshrc"
        echo
        print_color "$GREEN" "✅ Dry run completed - no actual changes made"
        exit 0
    fi

    # Start interactive configuration
    print_color "$BLUE" "🚀 Starting Zsh setup wizard..."
    echo

    configure_zsh
    
    echo
    echo
    print_color "$CYAN" "📋 Configuration Summary:"
    print_color "$YELLOW" "   • Install Zsh: Yes"
    print_color "$YELLOW" "   • Install Oh My Zsh: $([ "$INSTALL_OH_MY_ZSH" = true ] && echo "Yes ($ZSH_THEME theme)" || echo "No")"
    print_color "$YELLOW" "   • Set as default shell: $([ "$ZSH_DEFAULT" = true ] && echo "Yes" || echo "No")"
    print_color "$YELLOW" "   • Install plugins: $([ "$INSTALL_ZSH_PLUGINS" = true ] && echo "Yes ($ZSH_PLUGINS_SELECTED)" || echo "No")"
    echo
    echo

    # Confirm installation
    read -p "🚀 Proceed with installation? (y/N): " -r
    if ! echo "$REPLY" | grep -iq "^y"; then
        print_color "$YELLOW" "Installation cancelled."
        exit 0
    fi

    # Install Zsh and configure
    install_zsh

    echo
    print_color "$GREEN" "🎉 Zsh setup completed successfully!"
    print_color "$CYAN" "💡 To start using Zsh:"
    print_color "$YELLOW" "   • Restart your terminal, or"
    print_color "$YELLOW" "   • Run: exec zsh"
    echo
    print_color "$BLUE" "📚 Useful Zsh commands:"
    print_color "$YELLOW" "   • zsh --version    - Check Zsh version"
    print_color "$YELLOW" "   • echo \$SHELL      - Check current shell"
    print_color "$YELLOW" "   • omz update       - Update Oh My Zsh"
    echo
}

# Execute main function with all arguments
main "$@"