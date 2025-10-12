#!/bin/bash
#
# Description: Enhanced Secure server login manager with 1Password integration and multi-user support

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
readonly SCRIPT_VERSION="2.1.0"

# Configuration file path
readonly CONFIG_DIR="$HOME/.servault"
readonly CONFIG_FILE="$CONFIG_DIR/config"

# Configuration - Multi-user support with vault mapping
# Format: environment -> vault_name OR environment:user -> vault_name
declare -A OP_ITEM_PATTERNS=(
    ["uat"]="ch UAT server"
    ["prod"]="ch prod server"
    ["uat:alex"]="ch UAT server"
    ["staging"]="staging server"
    ["dev"]="dev server"
)

# Global configuration storage for setup
declare -A CONFIGURED_ENVIRONMENTS=()

#######################################
# Print colored output
#######################################
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

#######################################
# Print script banner
#######################################
show_banner() {
    clear
    print_color "$CYAN" "
╔═════════════════════════════════════════════════════════════════════════╗
║                                                                         ║
║    ███████╗███████╗██████╗ ██╗   ██╗ █████╗ ██╗   ██╗██╗   ████████╗    ║
║    ██╔════╝██╔════╝██╔══██╗██║   ██║██╔══██╗██║   ██║██║   ╚══██╔══╝    ║
║    ███████╗█████╗  ██████╔╝██║   ██║███████║██║   ██║██║      ██║       ║
║    ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══██║██║   ██║██║      ██║       ║
║    ███████║███████╗██║  ██║ ╚████╔╝ ██║  ██║╚██████╔╝███████╗ ██║       ║
║    ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝ ╚═╝       ║
║                                                                         ║
║               🔐 Secure Server Access Manager v${SCRIPT_VERSION} 🔐                   ║
║                                                                         ║
╚═════════════════════════════════════════════════════════════════════════╝
"
    print_color "$YELLOW" "Enhanced server login manager with multi-user 1Password integration"
    print_color "$BLUE" "Connect to servers with user-specific credentials and vault support"
    echo
}

#######################################
# Check if command exists
#######################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# Create config directory if it doesn't exist
#######################################
ensure_config_dir() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
}

#######################################
# Read configuration file
#######################################
read_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Source the config file to load variables
        . "$CONFIG_FILE"
    fi
}

#######################################
# Write configuration file
#######################################
write_config() {
    local password_manager="$1"
    
    ensure_config_dir
    
    cat > "$CONFIG_FILE" << EOF
# SERVAULT Configuration
# Generated on $(date)
PASSWORD_MANAGER=$password_manager
EOF
    
    print_color "$GREEN" "✅ Configuration saved to $CONFIG_FILE"
}

#######################################
# Detect available password managers
#######################################
detect_available_password_managers() {
    local available=()
    
    if command_exists op; then
        available+=("1password")
    fi
    
    if command_exists bw; then
        available+=("bitwarden")
    fi
    
    echo "${available[@]}"
}

#######################################
# Get configured password manager
#######################################
get_password_manager() {
    local override="$1"
    
    # Check for command line override first
    if [ -n "$override" ]; then
        case "$override" in
            "op"|"1password")
                echo "1password"
                return
                ;;
            "bw"|"bitwarden")
                echo "bitwarden"
                return
                ;;
            *)
                print_color "$RED" "❌ Invalid password manager: $override"
                print_color "$YELLOW" "💡 Valid options: 1password, bitwarden, op, bw"
                exit 1
                ;;
        esac
    fi
    
    # Read from config file
    read_config
    
    if [ -n "${PASSWORD_MANAGER:-}" ]; then
        echo "$PASSWORD_MANAGER"
        return
    fi
    
    # Auto-detect if no config
    local available
    available=($(detect_available_password_managers))
    
    if [ ${#available[@]} -eq 0 ]; then
        print_color "$RED" "❌ No password manager found"
        print_color "$YELLOW" "💡 Please install 1Password CLI or Bitwarden CLI"
        exit 1
    elif [ ${#available[@]} -eq 1 ]; then
        echo "${available[0]}"
    else
        # Both available, prefer 1Password
        echo "1password"
    fi
}

#######################################
# Detect operating system
#######################################
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt >/dev/null 2>&1; then
            echo "ubuntu"
        elif command -v yum >/dev/null 2>&1; then
            echo "rhel"
        elif command -v pacman >/dev/null 2>&1; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

#######################################
# Show installation commands for missing dependencies
#######################################
show_installation_commands() {
    local os_type
    os_type=$(detect_os)
    
    print_color "$YELLOW" "💡 To install missing dependencies, run:"
    echo
    
    case "$os_type" in
        "ubuntu")
            print_color "$CYAN" "   sudo apt update"
            print_color "$CYAN" "   sudo apt install sshpass expect"
            ;;
        "rhel")
            print_color "$CYAN" "   sudo yum install sshpass expect"
            print_color "$CYAN" "   # or for newer versions:"
            print_color "$CYAN" "   sudo dnf install sshpass expect"
            ;;
        "arch")
            print_color "$CYAN" "   sudo pacman -S sshpass expect"
            ;;
        "macos")
            print_color "$CYAN" "   brew install sshpass expect"
            ;;
        *)
            print_color "$CYAN" "   Please install sshpass and expect using your system's package manager"
            ;;
    esac
    
    echo
    print_color "$YELLOW" "For Password Manager CLIs:"
    case "$os_type" in
        "ubuntu")
            print_color "$CYAN" "   # 1Password CLI"
            print_color "$CYAN" "   curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg"
            print_color "$CYAN" "   echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list"
            print_color "$CYAN" "   sudo apt update && sudo apt install 1password-cli"
            echo
            print_color "$CYAN" "   # Bitwarden CLI"
            print_color "$CYAN" "   sudo apt install nodejs npm jq"
            print_color "$CYAN" "   npm install -g @bitwarden/cli"
            ;;
        "macos")
            print_color "$CYAN" "   # 1Password CLI"
            print_color "$CYAN" "   brew install 1password-cli"
            echo
            print_color "$CYAN" "   # Bitwarden CLI"
            print_color "$CYAN" "   brew install bitwarden-cli jq"
            ;;
        *)
            print_color "$CYAN" "   # 1Password CLI"
            print_color "$CYAN" "   Visit: https://developer.1password.com/docs/cli/get-started/"
            echo
            print_color "$CYAN" "   # Bitwarden CLI"
            print_color "$CYAN" "   npm install -g @bitwarden/cli"
            ;;
    esac
}

#######################################
# Auto-install dependencies
#######################################
auto_install_dependencies() {
    local os_type
    os_type=$(detect_os)
    
    print_color "$BLUE" "🚀 Installing dependencies automatically..."
    
    case "$os_type" in
        "ubuntu")
            sudo apt update
            sudo apt install -y sshpass expect
            ;;
        "rhel")
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y sshpass expect
            else
                sudo yum install -y sshpass expect
            fi
            ;;
        "arch")
            sudo pacman -S --noconfirm sshpass expect
            ;;
        "macos")
            if ! command -v brew >/dev/null 2>&1; then
                print_color "$RED" "❌ Homebrew not found. Please install Homebrew first:"
                print_color "$CYAN" "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                return 1
            fi
            brew install sshpass expect
            ;;
        *)
            print_color "$RED" "❌ Automatic installation not supported for your OS"
            print_color "$YELLOW" "Please install sshpass and expect manually"
            return 1
            ;;
    esac
    
    print_color "$GREEN" "✅ Dependencies installed successfully!"
}

#######################################
# Prompt user for auto-installation
#######################################
prompt_auto_install() {
    echo
    print_color "$YELLOW" "🤖 Would you like me to automatically install the missing dependencies?"
    print_color "$CYAN" "   This will run the installation commands shown above."
    echo
    read -p "Install automatically? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if auto_install_dependencies; then
            print_color "$GREEN" "🎉 Installation complete! Continuing with script execution..."
            echo
            return 0
        else
            print_color "$RED" "❌ Auto-installation failed. Please install manually."
            exit 1
        fi
    else
        print_color "$YELLOW" "👍 No problem! Install the dependencies manually and run the script again."
        exit 1
    fi
}

#######################################
# Validate dependencies
#######################################
validate_dependencies() {
    local use_main="$1"
    local connect_db="$2"
    local pm="$3"
    local missing_deps=()
    local missing_optional=()
    
    # Check password manager dependency
    case "$pm" in
        "1password")
            if ! command_exists op; then
                missing_deps+=("1Password CLI (op)")
            fi
            ;;
        "bitwarden")
            if ! command_exists bw; then
                missing_deps+=("Bitwarden CLI (bw)")
            fi
            if ! command_exists jq; then
                missing_deps+=("jq (JSON processor)")
            fi
            ;;
    esac
    
    if ! command_exists sshpass; then
        missing_deps+=("sshpass")
    fi
    
    # Check expect only if needed (main user + database combination)
    if ! command_exists expect; then
        if [ "$use_main" = true ] && [ "$connect_db" = true ]; then
            missing_deps+=("expect")
        else
            missing_optional+=("expect")
        fi
    fi
    
    # Handle missing core dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_color "$RED" "❌ Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            print_color "$RED" "   • $dep"
        done
        echo
        show_installation_commands
        
        # Only prompt for auto-install if it's not password manager CLI (more complex install)
        local has_pm_missing=false
        for dep in "${missing_deps[@]}"; do
            if [[ "$dep" == *"1Password CLI"* ]] || [[ "$dep" == *"Bitwarden CLI"* ]]; then
                has_pm_missing=true
                break
            fi
        done
        
        if [ "$has_pm_missing" = true ]; then
            echo
            print_color "$YELLOW" "Note: Password manager CLIs require manual installation. Please install them first, then run the script again."
            exit 1
        else
            prompt_auto_install
        fi
    fi
    
    # Show optional dependency warnings
    if [ ${#missing_optional[@]} -gt 0 ]; then
        print_color "$YELLOW" "⚠️  Optional dependencies missing:"
        for dep in "${missing_optional[@]}"; do
            print_color "$YELLOW" "   • $dep (needed for main user + database access)"
        done
        print_color "$CYAN" "💡 Install expect if you plan to use: ./servault.sh <env> main db"
        echo
    fi
}

#######################################
# Sign in to 1Password (optimized)
#######################################
signin_1password() {
    print_color "$BLUE" "🔐 Checking 1Password authentication..."
    
    # Check if already signed in by testing a simple command
    if op account list >/dev/null 2>&1; then
        print_color "$GREEN" "✅ Already authenticated to 1Password"
        return 0
    fi
    
    print_color "$BLUE" "🔐 Signing in to 1Password..."
    if ! eval "$(op signin)" 2>/dev/null; then
        print_color "$RED" "❌ 1Password sign-in failed."
        print_color "$YELLOW" "💡 Make sure you have 1Password CLI configured and try again."
        exit 1
    fi
    
    print_color "$GREEN" "✅ 1Password authentication successful"
}

#######################################
# Sign in to Bitwarden
#######################################
signin_bitwarden() {
    print_color "$BLUE" "🔐 Checking Bitwarden authentication..."
    
    # Check if already authenticated
    local status
    status=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unauthenticated")
    
    if [ "$status" = "unlocked" ]; then
        print_color "$GREEN" "✅ Already authenticated to Bitwarden"
        return 0
    elif [ "$status" = "locked" ]; then
        print_color "$BLUE" "🔐 Unlocking Bitwarden vault..."
        local session
        session=$(bw unlock --raw 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$session" ]; then
            export BW_SESSION="$session"
            print_color "$GREEN" "✅ Bitwarden vault unlocked"
            return 0
        else
            print_color "$RED" "❌ Failed to unlock Bitwarden vault"
            exit 1
        fi
    else
        print_color "$RED" "❌ Not logged in to Bitwarden"
        print_color "$YELLOW" "💡 Please run 'bw login' first, then try again"
        exit 1
    fi
}

#######################################
# Universal password manager authentication
#######################################
signin_password_manager() {
    local pm="$1"
    
    case "$pm" in
        "1password")
            signin_1password
            ;;
        "bitwarden")
            signin_bitwarden
            ;;
        *)
            print_color "$RED" "❌ Unknown password manager: $pm"
            exit 1
            ;;
    esac
}

#######################################
# Get credentials from 1Password
#######################################
get_op_credentials() {
    local vault_name="$1"
    local field_name="$2"
    
    # Try to get credential from individual field first, then fall back to notes
    local value
    value=$(op item get "$vault_name" --field "$field_name" 2>/dev/null)
    
    if [ -z "$value" ]; then
        # Fall back to parsing from notes field
        local credentials
        credentials=$(op item get "$vault_name" --field notesPlain 2>/dev/null)
        
        if [ -z "$credentials" ]; then
            print_color "$RED" "❌ Failed to retrieve credentials from vault '$vault_name'"
            print_color "$YELLOW" "💡 Make sure the 1Password item '$vault_name' exists and contains the required fields"
            exit 1
        fi
        
        # Parse from notes in key=value format
        value=$(echo "$credentials" | grep "^${field_name}=" | cut -d'=' -f2-)
    fi
    
    if [ -z "$value" ]; then
        print_color "$RED" "❌ Credential '$field_name' not found in vault '$vault_name'"
        print_color "$YELLOW" "💡 Check that '$vault_name' contains field '$field_name'"
        exit 1
    fi
    
    echo "$value"
}

#######################################
# Get credentials from Bitwarden
#######################################
get_bw_credentials() {
    local vault_name="$1"
    local field_name="$2"
    
    # Get the item from Bitwarden
    local item_json
    item_json=$(bw get item "$vault_name" 2>/dev/null)
    
    if [ -z "$item_json" ]; then
        print_color "$RED" "❌ Failed to retrieve item '$vault_name' from Bitwarden"
        print_color "$YELLOW" "💡 Make sure the Bitwarden item '$vault_name' exists"
        exit 1
    fi
    
    # Try to get from custom fields first
    local value
    value=$(echo "$item_json" | jq -r ".fields[]? | select(.name==\"$field_name\") | .value" 2>/dev/null)
    
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        # Try to get from notes field (key=value format)
        local notes
        notes=$(echo "$item_json" | jq -r '.notes // ""' 2>/dev/null)
        
        if [ -n "$notes" ]; then
            value=$(echo "$notes" | grep "^${field_name}=" | cut -d'=' -f2-)
        fi
    fi
    
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        print_color "$RED" "❌ Credential '$field_name' not found in Bitwarden item '$vault_name'"
        print_color "$YELLOW" "💡 Check that '$vault_name' contains field '$field_name' in custom fields or notes"
        exit 1
    fi
    
    echo "$value"
}

#######################################
# Universal credential retrieval
#######################################
get_credentials() {
    local vault_name="$1"
    local field_name="$2"
    local pm="$3"
    
    case "$pm" in
        "1password")
            get_op_credentials "$vault_name" "$field_name"
            ;;
        "bitwarden")
            get_bw_credentials "$vault_name" "$field_name"
            ;;
        *)
            print_color "$RED" "❌ Unknown password manager: $pm"
            exit 1
            ;;
    esac
}

#######################################
# Fast credential loading (universal approach)
#######################################
load_credentials() {
    local vault_name="$1"
    local pm="$2"
    
    if [ "${fast_mode:-false}" = false ]; then
        print_color "$BLUE" "📋 Loading credentials from '$vault_name' using $pm..."
    fi
    
    # Load server credentials
    USER=$(get_credentials "$vault_name" "SERVER_USER" "$pm")
    HOST=$(get_credentials "$vault_name" "SERVER_IP" "$pm")
    SERVER_PASSWORD=$(get_credentials "$vault_name" "SERVER_PASSWORD" "$pm")
    
    # Load database credentials
    DB_USER=$(get_credentials "$vault_name" "DB_USER" "$pm")
    DB_NAME=$(get_credentials "$vault_name" "DB_NAME" "$pm")
    DB_PASSWORD=$(get_credentials "$vault_name" "DB_PASSWORD" "$pm")
    DB_PORT=$(get_credentials "$vault_name" "DB_PORT" "$pm")
    DB_HOST=$(get_credentials "$vault_name" "DB_HOST" "$pm")
    
    # Load main user credentials
    MAIN_USER=$(get_credentials "$vault_name" "MAIN_USER" "$pm")
    MAIN_PASSWORD=$(get_credentials "$vault_name" "MAIN_PASSWORD" "$pm")
    
    # Set database system user (hardcoded for backward compatibility)
    DB_SYSTEM_USER="cardhouzz"
    
    # Validate that we got the essential credentials
    if [ -z "$USER" ] || [ -z "$HOST" ] || [ -z "$SERVER_PASSWORD" ]; then
        print_color "$RED" "❌ Missing essential server credentials in vault '$vault_name'"
        print_color "$YELLOW" "💡 Required fields: SERVER_USER, SERVER_IP, SERVER_PASSWORD"
        exit 1
    fi
    
    if [ "${fast_mode:-false}" = false ]; then
        print_color "$GREEN" "✅ Credentials loaded successfully"
    fi
}

#######################################
# Show connection details (dry-run)
#######################################
show_connection_details() {
    local env="$1"
    local user="$2"
    local vault_name="$3"
    local use_main="$4"
    local connect_db="$5"
    
    print_color "$CYAN" "🔍 Connection Details for $env environment:"
    if [ -n "$user" ]; then
        print_color "$YELLOW" "   👤 User: $user"
    else
        print_color "$YELLOW" "   👤 User: default"
    fi
    print_color "$YELLOW" "   🗂️  Vault: '$vault_name'"
    
    if [ "$use_main" = true ]; then
        print_color "$YELLOW" "   🔑 Using main user credentials"
        print_color "$YELLOW" "   👤 Server User: $MAIN_USER"
    else
        print_color "$YELLOW" "   🔑 Using standard server credentials"
        print_color "$YELLOW" "   👤 Server User: $USER"
    fi
    
    print_color "$YELLOW" "   🖥️  Host: $HOST"
    
    if [ "$connect_db" = true ]; then
        echo
        print_color "$PURPLE" "   📊 Database Connection:"
        print_color "$PURPLE" "   └── Host: $DB_HOST"
        print_color "$PURPLE" "   └── Port: $DB_PORT"
        print_color "$PURPLE" "   └── Database: $DB_NAME"
        print_color "$PURPLE" "   └── User: $DB_USER"
        if [ -n "$DB_SYSTEM_USER" ]; then
            print_color "$PURPLE" "   └── System User: $DB_SYSTEM_USER"
        fi
    fi
    
    echo
    print_color "$BLUE" "🚀 Ready to connect!"
    print_color "$CYAN" "💡 Remove --dry-run to actually connect"
}

#######################################
# Connect to server
#######################################
connect_server() {
    local env="$1"
    local user="$2"
    local vault_name="$3"
    local use_main="$4"
    local connect_db="$5"
    
    local connection_user="$USER"
    local connection_password="$SERVER_PASSWORD"
    
    if [ "$use_main" = true ]; then
        connection_user="$MAIN_USER"
        connection_password="$MAIN_PASSWORD"
    fi
    
    if [ "$connect_db" = true ] && [ "$use_main" = true ]; then
        print_color "$GREEN" "🔗 Connecting to $env server using $connection_user and accessing PostgreSQL database..."
        
        if [ -n "$DB_SYSTEM_USER" ]; then
            # Check if expect is available for interactive session
            if ! command_exists expect; then
                print_color "$RED" "❌ 'expect' is required for main user + database access with system user switching"
                print_color "$YELLOW" "💡 Install expect or use: ./servault.sh $env db (without main)"
                exit 1
            fi
            
            # Connect to server, switch to database system user, and execute psql commands
            sshpass -p "$connection_password" ssh -o StrictHostKeyChecking=no "$connection_user@$HOST" -t \
            "expect -c '
                spawn sudo su - $DB_SYSTEM_USER
                expect \"password for $connection_user:\"
                send \"${connection_password}\r\"
                expect \"$DB_SYSTEM_USER@\"
                send \"PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME\r\"
                interact
            '"
        else
            # Direct database connection without user switching
            sshpass -p "$connection_password" ssh -o StrictHostKeyChecking=no "$connection_user@$HOST" -t \
            "PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
        fi
        
    elif [ "$connect_db" = true ]; then
        print_color "$GREEN" "🔗 Connecting to $env server and accessing PostgreSQL database..."
        
        # Connect to server and execute psql commands
        sshpass -p "$connection_password" ssh -o StrictHostKeyChecking=no "$connection_user@$HOST" -t \
        "PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
        
    else
        print_color "$GREEN" "🔗 Connecting to $env server..."
        if [ -n "$user" ]; then
            print_color "$CYAN" "Using user: $user (vault: '$vault_name')"
        else
            print_color "$CYAN" "Using default user (vault: '$vault_name')"
        fi
        
        # Simple SSH connection
        sshpass -p "$connection_password" ssh -tt -o StrictHostKeyChecking=no "$connection_user@$HOST"
    fi
}

#######################################
# Get available users for an environment
#######################################
get_available_users() {
    local env="$1"
    local users=()
    
    # Check for default user
    if [ -n "${OP_ITEM_PATTERNS[$env]:-}" ]; then
        users+=("default")
    fi
    
    # Check for named users
    for key in "${!OP_ITEM_PATTERNS[@]}"; do
        if [[ "$key" == "$env:"* ]]; then
            local user="${key#$env:}"
            users+=("$user")
        fi
    done
    
    echo "${users[@]}"
}

#######################################
# Check if environment has existing configurations
#######################################
has_existing_config() {
    local env="$1"
    
    # Check for default configuration
    if [ -n "${OP_ITEM_PATTERNS[$env]:-}" ]; then
        return 0
    fi
    
    # Check for user-specific configurations
    for key in "${!OP_ITEM_PATTERNS[@]}"; do
        if [[ "$key" == "$env:"* ]]; then
            return 0
        fi
    done
    
    return 1
}

#######################################
# Show available stages for selection
#######################################
show_stage_menu() {
    local available_stages=("dev" "uat" "prod" "staging")
    local counter=1
    
    print_color "$CYAN" "Available stages:"
    for stage in "${available_stages[@]}"; do
        print_color "$YELLOW" "  [$counter] $stage"
        ((counter++))
    done
    echo
}

#######################################
# Configure a single environment
#######################################
configure_environment() {
    local env="$1"
    local user_name=""
    local vault_name=""
    local project_name=""
    
    if has_existing_config "$env"; then
        local existing_users
        existing_users=$(get_available_users "$env")
        
        echo
        print_color "$YELLOW" "⚠️  You already have $env configurations for: $existing_users"
        print_color "$BLUE" "What would you like to do?"
        print_color "$CYAN" "  [1] Override existing configuration"
        print_color "$CYAN" "  [2] Add another user for $env"
        print_color "$CYAN" "  [3] Skip $env"
        echo
        read -p "Select option (1-3): " existing_choice
        
        case "$existing_choice" in
            1)
                print_color "$YELLOW" "📝 Overriding existing $env configuration..."
                ;;
            2)
                print_color "$YELLOW" "📝 Adding another user for $env..."
                echo
                print_color "$BLUE" "User name for this $env configuration:"
                read -p "User name: " user_name
                ;;
            3)
                print_color "$YELLOW" "⏭️  Skipping $env configuration"
                return 0
                ;;
            *)
                print_color "$RED" "Invalid option. Skipping $env."
                return 0
                ;;
        esac
    else
        print_color "$YELLOW" "📝 Configuring $env environment..."
    fi
    
    echo
    print_color "$BLUE" "Project name (used as label/reference):"
    print_color "$CYAN" "Example: 'ch', 'mycompany', 'project-alpha'"
    read -p "Project name: " project_name
    
    echo
    print_color "$BLUE" "1Password vault item name for $env$([ -n "$user_name" ] && echo " ($user_name)"):"
    print_color "$CYAN" "Example: 'ch UAT server', 'mycompany uat env', 'project-uat-server'"
    read -p "Vault item name: " vault_name
    
    # Store the configuration
    if [ -n "$user_name" ]; then
        OP_ITEM_PATTERNS["$env:$user_name"]="$vault_name"
        print_color "$GREEN" "✅ Configured: $env ($user_name) → \"$vault_name\""
    else
        OP_ITEM_PATTERNS["$env"]="$vault_name"
        print_color "$GREEN" "✅ Configured: $env (default) → \"$vault_name\""
    fi
    
    # Store project name for reference
    CONFIGURED_ENVIRONMENTS["$env$([ -n "$user_name" ] && echo ":$user_name")"]="$project_name"
}

#######################################
# Interactive configuration setup
#######################################
interactive_config() {
    show_banner
    print_color "$BOLD" "🔧 INTERACTIVE CONFIGURATION SETUP"
    echo
    print_color "$CYAN" "Let's configure SERVAULT for your project!"
    echo
    
    # Password Manager Selection
    print_color "$YELLOW" "🔐 Password Manager Configuration:"
    echo
    
    local available
    available=($(detect_available_password_managers))
    
    if [ ${#available[@]} -eq 0 ]; then
        print_color "$RED" "❌ No password manager found!"
        print_color "$YELLOW" "💡 Please install 1Password CLI or Bitwarden CLI first:"
        print_color "$CYAN" "   • 1Password CLI: https://developer.1password.com/docs/cli/get-started/"
        print_color "$CYAN" "   • Bitwarden CLI: npm install -g @bitwarden/cli"
        exit 1
    elif [ ${#available[@]} -eq 1 ]; then
        local pm="${available[0]}"
        print_color "$BLUE" "🔍 Found: ${pm^} CLI"
        print_color "$GREEN" "✅ Using ${pm^} for credential storage"
        write_config "$pm"
    else
        # Both available - let user choose
        print_color "$BLUE" "🔍 Found multiple password managers:"
        for pm in "${available[@]}"; do
            print_color "$CYAN" "   ✅ ${pm^} CLI"
        done
        echo
        print_color "$BLUE" "💡 Default: Using 1Password (recommended for best experience)"
        read -p "Would you like to use Bitwarden instead? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_color "$GREEN" "✅ Using Bitwarden for credential storage"
            write_config "bitwarden"
        else
            print_color "$GREEN" "✅ Using 1Password for credential storage"
            write_config "1password"
        fi
    fi
    
    echo
    
    # Show existing 1Password items if possible
    if command_exists op; then
        print_color "$YELLOW" "🔍 Your existing 1Password server items:"
        echo
        if op item list --format=json 2>/dev/null | jq -r '.[].title' | grep -i -E "(server|uat|prod|staging|dev)" | head -10; then
            echo
        else
            print_color "$YELLOW" "Could not retrieve 1Password items. Make sure you're signed in: op signin"
            echo
        fi
    fi
    
    # Configuration loop
    while true; do
        show_stage_menu
        read -p "Select a stage to configure (1-4) or 'q' to quit: " stage_choice
        
        case "$stage_choice" in
            1) configure_environment "dev" ;;
            2) configure_environment "uat" ;;
            3) configure_environment "prod" ;;
            4) configure_environment "staging" ;;
            q|Q) break ;;
            *) 
                print_color "$RED" "Invalid option. Please select 1-4 or 'q' to quit."
                continue
                ;;
        esac
        
        echo
        read -p "Configure another stage? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            break
        fi
    done
    
    # Show final configuration
    echo
    print_color "$CYAN" "📋 Final Configuration Summary:"
    for key in "${!OP_ITEM_PATTERNS[@]}"; do
        if [[ "$key" == *":"* ]]; then
            local env="${key%:*}"
            local user="${key#*:}"
            print_color "$YELLOW" "  • $env ($user): '${OP_ITEM_PATTERNS[$key]}'"
        else
            print_color "$YELLOW" "  • $key (default): '${OP_ITEM_PATTERNS[$key]}'"
        fi
    done
    
    echo
    read -p "Save this configuration? (Y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_color "$YELLOW" "👍 Configuration not saved. Run './servault.sh --setup' again to reconfigure."
        exit 0
    fi
    
    # Update the script file
    print_color "$BLUE" "💾 Updating script configuration..."
    
    # Create backup
    cp "$0" "$0.backup"
    
    # Build the new OP_ITEM_PATTERNS declaration
    local new_patterns="declare -A OP_ITEM_PATTERNS=("
    for key in "${!OP_ITEM_PATTERNS[@]}"; do
        new_patterns+="\n    [\"$key\"]=\"${OP_ITEM_PATTERNS[$key]}\""
    done
    new_patterns+="\n)"
    
    # Update the script using a more reliable method
    local temp_file=$(mktemp)
    awk -v patterns="$new_patterns" '
        /^declare -A OP_ITEM_PATTERNS=/ {
            print patterns
            # Skip until the closing parenthesis
            while (getline > 0 && !/^\)/) continue
            next
        }
        { print }
    ' "$0" > "$temp_file"
    
    mv "$temp_file" "$0"
    chmod +x "$0"
    
    print_color "$GREEN" "✅ Configuration updated successfully!"
    echo
    print_color "$CYAN" "📋 Next steps:"
    print_color "$YELLOW" "1. Create 1Password items with the names shown above (if they don't exist)"
    print_color "$YELLOW" "2. Add the required credential fields to each item:"
    print_color "$PURPLE" "   • SERVER_USER, SERVER_IP, SERVER_PASSWORD"
    print_color "$PURPLE" "   • DB_USER, DB_NAME, DB_PASSWORD, DB_PORT, DB_HOST"
    print_color "$PURPLE" "   • MAIN_USER, MAIN_PASSWORD"
    print_color "$PURPLE" "   • DB_SYSTEM_USER (optional)"
    print_color "$YELLOW" "3. Test your setup:"
    print_color "$CYAN" "   ./servault.sh uat --dry-run                    # Test default user"
    print_color "$CYAN" "   ./servault.sh uat --user alex --dry-run        # Test specific user"
    echo
    print_color "$GREEN" "🎉 You're all set! Happy server hopping!"
}

#######################################
# Show current configuration
#######################################
show_config() {
    show_banner
    print_color "$BOLD" "CURRENT CONFIGURATION:"
    echo
    
    # Group configurations by environment
    local environments=()
    for key in "${!OP_ITEM_PATTERNS[@]}"; do
        if [[ "$key" != *":"* ]]; then
            environments+=("$key")
        fi
    done
    
    # Sort environments
    IFS=$'\n' environments=($(sort <<<"${environments[*]}"))
    unset IFS
    
    for env in "${environments[@]}"; do
        print_color "$CYAN" "${env^} Environment:"
        
        # Show default user
        if [ -n "${OP_ITEM_PATTERNS[$env]:-}" ]; then
            print_color "$YELLOW" "  • default: '${OP_ITEM_PATTERNS[$env]}'"
        fi
        
        # Show named users
        for key in "${!OP_ITEM_PATTERNS[@]}"; do
            if [[ "$key" == "$env:"* ]]; then
                local user="${key#$env:}"
                print_color "$YELLOW" "  • $user: '${OP_ITEM_PATTERNS[$key]}'"
            fi
        done
        echo
    done
    
    print_color "$CYAN" "Available Users per Environment:"
    for env in "${environments[@]}"; do
        local users
        users=$(get_available_users "$env")
        if [ -n "$users" ]; then
            print_color "$YELLOW" "  • $env: $users"
        fi
    done
    
    echo
    print_color "$CYAN" "Required Credential Fields:"
    print_color "$PURPLE" "  Server Credentials:"
    print_color "$PURPLE" "    └── SERVER_USER, SERVER_IP, SERVER_PASSWORD"
    print_color "$PURPLE" "  Database Credentials:"
    print_color "$PURPLE" "    └── DB_USER, DB_NAME, DB_PASSWORD, DB_PORT, DB_HOST"
    print_color "$PURPLE" "  Main User Credentials:"
    print_color "$PURPLE" "    └── MAIN_USER, MAIN_PASSWORD"
    print_color "$PURPLE" "  Optional:"
    print_color "$PURPLE" "    └── DB_SYSTEM_USER (for sudo su - <user> before psql)"
    echo
    print_color "$BLUE" "💡 To change configuration interactively, run: ./servault.sh --setup"
    echo
}

#######################################
# Show help information
#######################################
show_help() {
    show_banner
    print_color "$BOLD" "USAGE:"
    echo "  $0 <environment> [options]"
    echo
    print_color "$BOLD" "ENVIRONMENTS:"
    echo "  uat            Connect to UAT server"
    echo "  prod           Connect to production server"
    echo "  staging        Connect to staging server"
    echo "  dev            Connect to development server"
    echo
    print_color "$BOLD" "OPTIONS:"
    echo "  --user <name>  Use specific user credentials (e.g., alex, sarah)"
    echo "  db             Connect to database after server login"
    echo "  main           Use main user credentials"
    echo "  main db        Use main user and connect to database"
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Show version information"
    echo "  --dry-run      Show connection details without connecting"
    echo "  --config       Show current configuration and 1Password item names"
    echo "  --setup        Interactive configuration setup (change project prefix, etc.)"
    echo "  --list-users   Show available users for an environment"
    echo "  --fast         Fast mode (skip banner and extra output)"
    echo "  --password-manager <pm>  Override password manager (1password, bitwarden, op, bw)"
    echo
    print_color "$BOLD" "EXAMPLES:"
    echo "  $0 uat                           # Connect to UAT server (default user)"
    echo "  $0 uat --user alex               # Connect to UAT server as alex"
    echo "  $0 prod --user sarah db          # Connect to prod as sarah + database"
    echo "  $0 uat --user admin main         # Connect to UAT as admin with main credentials"
    echo "  $0 uat --dry-run                 # Show UAT connection details"
    echo "  $0 --setup                       # Interactive setup (first-time configuration)"
    echo "  $0 uat --list-users              # Show available users for UAT"
    echo "  $0 uat --password-manager bitwarden  # Use Bitwarden for this connection"
    echo
    print_color "$BOLD" "REQUIREMENTS:"
    echo "  • Password Manager CLI: 1Password (op) OR Bitwarden (bw)"
    echo "  • sshpass installed for password authentication"
    echo "  • expect installed for interactive sessions (main user db access)"
    echo "  • jq installed (required for Bitwarden support)"
    echo "  • Valid password manager items configured via --setup"
    echo "  • Credentials stored as individual fields OR in notes as key=value pairs"
    echo
    print_color "$BOLD" "MULTI-USER SUPPORT:"
    echo "  Configure multiple users per environment using --setup"
    echo "  Each user can have their own password manager vault item"
    echo "  Use --user <name> to specify which user credentials to use"
    echo
    print_color "$BOLD" "PASSWORD MANAGER SUPPORT:"
    echo "  Supports both 1Password and Bitwarden"
    echo "  Auto-detects available password managers"
    echo "  Use --password-manager to override saved preference"
    echo
}

#######################################
# Resolve vault name for environment and user
#######################################
get_vault_name() {
    local env="$1"
    local user="${2:-}"
    
    if [ -n "$user" ]; then
        local vault_key="${env}:${user}"
        if [ -n "${OP_ITEM_PATTERNS[$vault_key]:-}" ]; then
            echo "${OP_ITEM_PATTERNS[$vault_key]}"
        else
            print_color "$RED" "❌ User '$user' not configured for $env environment"
            local available_users
            available_users=$(get_available_users "$env")
            if [ -n "$available_users" ]; then
                print_color "$YELLOW" "💡 Available users for $env: $available_users"
            else
                print_color "$YELLOW" "💡 No users configured for $env. Run --setup to configure."
            fi
            exit 1
        fi
    else
        # Use default user
        if [ -n "${OP_ITEM_PATTERNS[$env]:-}" ]; then
            echo "${OP_ITEM_PATTERNS[$env]}"
        else
            print_color "$RED" "❌ Environment '$env' not configured"
            print_color "$YELLOW" "💡 Run --setup to configure environments"
            exit 1
        fi
    fi
}

#######################################
# List users for an environment
#######################################
list_users() {
    local env="$1"
    
    if [ -z "$env" ]; then
        print_color "$RED" "❌ Please specify an environment"
        print_color "$YELLOW" "Usage: $0 <environment> --list-users"
        exit 1
    fi
    
    local users
    users=$(get_available_users "$env")
    
    if [ -n "$users" ]; then
        print_color "$CYAN" "Available users for $env environment:"
        for user in $users; do
            local vault_name
            if [ "$user" = "default" ]; then
                vault_name="${OP_ITEM_PATTERNS[$env]}"
            else
                vault_name="${OP_ITEM_PATTERNS[$env:$user]}"
            fi
            print_color "$YELLOW" "  • $user: '$vault_name'"
        done
    else
        print_color "$YELLOW" "No users configured for $env environment"
        print_color "$BLUE" "Run --setup to configure users for this environment"
    fi
}

#######################################
# Main function
#######################################
main() {
    local environment=""
    local user=""
    local use_main=false
    local connect_db=false
    local dry_run=false
    local list_users_flag=false
    local fast_mode=false
    local password_manager_override=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "Enhanced Servault v${SCRIPT_VERSION}"
                exit 0
                ;;
            --config)
                show_config
                exit 0
                ;;
            --setup)
                interactive_config
                exit 0
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --user)
                if [ -n "${2:-}" ]; then
                    user="$2"
                    shift 2
                else
                    print_color "$RED" "❌ --user requires a username"
                    exit 1
                fi
                ;;
            --list-users)
                list_users_flag=true
                shift
                ;;
            --fast)
                fast_mode=true
                shift
                ;;
            --password-manager|--pm)
                if [ -n "${2:-}" ]; then
                    password_manager_override="$2"
                    shift 2
                else
                    print_color "$RED" "❌ --password-manager requires a value"
                    print_color "$YELLOW" "💡 Valid options: 1password, bitwarden, op, bw"
                    exit 1
                fi
                ;;
            uat|prod|staging|dev)
                environment="$1"
                shift
                ;;
            main)
                use_main=true
                shift
                ;;
            db)
                connect_db=true
                shift
                ;;
            *)
                print_color "$RED" "❌ Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Handle list users
    if [ "$list_users_flag" = true ]; then
        list_users "$environment"
        exit 0
    fi
    
    # Validate arguments
    if [ -z "$environment" ]; then
        print_color "$RED" "❌ Environment not specified"
        echo
        show_help
        exit 1
    fi
    
    # Show banner (unless in fast mode)
    if [ "$fast_mode" = false ]; then
        show_banner
    fi
    
    # Get vault name for user
    local vault_name
    vault_name=$(get_vault_name "$environment" "$user")
    
    # Determine which password manager to use
    local password_manager
    password_manager=$(get_password_manager "$password_manager_override")
    
    # Validate dependencies (pass use_main, connect_db, and password manager for smart checking)
    validate_dependencies "$use_main" "$connect_db" "$password_manager"
    
    # Sign in to password manager
    signin_password_manager "$password_manager"
    
    # Load credentials from vault
    fast_mode="$fast_mode" load_credentials "$vault_name" "$password_manager"
    
    if [ "$dry_run" = true ]; then
        show_connection_details "$environment" "$user" "$vault_name" "$use_main" "$connect_db"
    else
        connect_server "$environment" "$user" "$vault_name" "$use_main" "$connect_db"
    fi
}

# Execute main function with all arguments
main "$@"
