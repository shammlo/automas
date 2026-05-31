#!/bin/bash
#
# Description: Enhanced Nginx configuration script with SSL, SPA routing, API proxying, and site management
#
# Nginx Configuration Script v2.0
#
# Enhanced version with SSL, multiple TLDs, port configuration,
# list/remove operations, SPA support, and more features.
#

# Exit on error, undefined variables, and propagate pipe errors
set -euo pipefail

# Version information
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly CONFIG_DIR="$HOME/.ngx"
readonly CONFIG_FILE="$CONFIG_DIR/config"

# Default configuration values
DEFAULT_TLD=".io"
DEFAULT_PORT=80
DEFAULT_SSL_PORT=443
NGINX_CONF_DIR="/etc/nginx/conf.d"
NGINX_MAIN_CONF="/etc/nginx/nginx.conf"
HOSTS_FILE="/etc/hosts"

#######################################
# Strip surrounding double quotes from a config value
# Arguments:
#   $1 - Value
# Outputs:
#   Unquoted value
#######################################
strip_quotes() {
    local value="$1"

    value="${value%\"}"
    value="${value#\"}"
    echo "$value"
}

#######################################
# Prompt for a yes/no confirmation
# Arguments:
#   $1 - Prompt text
# Returns:
#   0 for yes, 1 for no
#######################################
confirm() {
    local prompt="$1"
    local answer=""

    if [ ! -t 0 ]; then
        log_warning "Cannot prompt for confirmation in a non-interactive shell."
        return 1
    fi

    read -r -p "$prompt [y/N]: " answer
    case "$answer" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

#######################################
# Print a formatted log message
# Arguments:
#   $1 - Log level emoji
#   $2 - Message to print
#######################################
log() {
    local emoji="$1"
    local message="$2"
    echo "$emoji $message"
}

#######################################
# Print an informational message
# Arguments:
#   $1 - Message to print
#######################################
log_info() {
    if [ "${QUIET:-0}" -eq 0 ]; then
        log "ℹ️" " $1"
    fi
}

#######################################
# Print a success message
# Arguments:
#   $1 - Message to print
#######################################
log_success() {
    if [ "${QUIET:-0}" -eq 0 ]; then
        log "✅" "$1"
    fi
}

#######################################
# Print a warning message
# Arguments:
#   $1 - Message to print
#######################################
log_warning() {
    if [ "${QUIET:-0}" -eq 0 ]; then
        log "⚠️" "$1"
    fi
}

#######################################
# Print an error message (always shown, even in quiet mode)
# Arguments:
#   $1 - Message to print
#######################################
log_error() {
    log "❌" "$1"
}

#######################################
# Print verbose message (only if verbose mode is enabled)
# Arguments:
#   $1 - Message to print
#######################################
log_verbose() {
    if [ "${VERBOSE:-0}" -eq 1 ]; then
        log "🔍" "$1"
    fi
}

#######################################
# Show script usage information
# Arguments:
#   $1 - Script name
#######################################
show_usage() {
    local script_name="$1"
    local reset="" bold="" dim="" cyan="" green="" yellow="" blue=""

    if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && command -v tput >/dev/null 2>&1; then
        local color_count
        color_count="$(tput colors 2>/dev/null || echo 0)"

        if [ "${color_count:-0}" -ge 8 ]; then
            reset="$(tput sgr0)"
            bold="$(tput bold)"
            dim="$(tput dim)"
            cyan="$(tput setaf 6)"
            green="$(tput setaf 2)"
            yellow="$(tput setaf 3)"
            blue="$(tput setaf 4)"
        fi
    fi

    cat <<EOF
${bold}${cyan}🚀 ngx v${SCRIPT_VERSION}${reset}
${dim}Create and manage local Nginx site configs for dev apps, APIs, and static builds.${reset}

${bold}${cyan}📌 Usage${reset}
  ${green}$script_name${reset} ${yellow}create${reset} ${bold}<domain>${reset} ${bold}<path>${reset} [options]
  ${green}$script_name${reset} ${yellow}remove${reset} ${bold}<domain>${reset} [options]
  ${green}$script_name${reset} ${yellow}list${reset}
  ${green}$script_name${reset} ${yellow}version${reset}

${bold}${cyan}🧭 Commands${reset}
  ${yellow}create${reset} ${bold}<domain>${reset} ${bold}<path>${reset}    Create a site config and hosts entry.
                              ${dim}Example: myapp -> myapp${DEFAULT_TLD}${reset}
  ${yellow}remove${reset} ${bold}<domain>${reset}           Remove the Nginx config and hosts entry.
  ${yellow}list${reset}                      Show configured local sites.
  ${yellow}version${reset}                   Show the installed ngx version.

${bold}${cyan}⚙️  Create Options${reset}
  ${yellow}-p, --port${reset} ${bold}<port>${reset}        Serve or proxy to a custom local port.
                          ${dim}Useful for Vite, Next.js, NestJS, Rails, etc. Default: ${DEFAULT_PORT}${reset}

  ${yellow}-t, --tld${reset} ${bold}<tld>${reset}          Choose the local domain suffix.
                          ${dim}Useful to separate projects: admin.dev, api.test. Default: ${DEFAULT_TLD}${reset}

  ${yellow}-s, --ssl${reset}                Enable HTTPS.
                          ${dim}Useful for secure cookies, OAuth callbacks, service workers, and mixed-content testing.${reset}

  ${yellow}--spa${reset}                    Route unknown paths to index.html.
                          ${dim}Use for React, Vue, Angular, Svelte, or any client-side router.${reset}

  ${yellow}--api${reset} ${bold}<url>${reset}              Proxy /api to a backend service.
                          ${dim}Example: --api http://localhost:3000${reset}

${bold}${cyan}🛡️  Safety & Output${reset}
  ${yellow}-f, --force${reset}              Update an existing domain without stopping for conflict handling.
  ${yellow}--dry-run${reset}                Preview files, hosts changes, and Nginx actions without applying them.
  ${yellow}-v, --verbose${reset}            Show detailed steps while ngx works.
  ${yellow}-q, --quiet${reset}              Keep output minimal; errors still show.
  ${yellow}-h, --help${reset}               Show this help message.

${bold}${cyan}✨ Examples${reset}
  ${blue}$script_name create myapp /path/to/dist${reset}
    ${dim}Serve a static build at myapp${DEFAULT_TLD}.${reset}

  ${blue}$script_name create dashboard /path/to/dist --ssl --spa${reset}
    ${dim}Serve a frontend app over HTTPS with client-side routing.${reset}

  ${blue}$script_name create api /path/to/dist --api http://localhost:3000 --tld .dev${reset}
    ${dim}Serve static files and proxy /api to a local backend at api.dev.${reset}

  ${blue}$script_name remove myapp${reset}
  ${blue}$script_name list${reset}

${dim}Tip: set NO_COLOR=1 to disable colored help output.${reset}
EOF
}

#######################################
# Initialize configuration directory and file
#######################################
init_config() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        log_verbose "Created config directory: $CONFIG_DIR"
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" <<EOF
# NGX Configuration File
DEFAULT_TLD="$DEFAULT_TLD"
DEFAULT_PORT=$DEFAULT_PORT
DEFAULT_SSL_PORT=$DEFAULT_SSL_PORT
NGINX_CONF_DIR="$NGINX_CONF_DIR"
EOF
        log_verbose "Created default config file: $CONFIG_FILE"
    fi
    
    load_config "$CONFIG_FILE"
}

#######################################
# Load the script config without executing arbitrary shell code
# Arguments:
#   $1 - Config file path
#######################################
load_config() {
    local config_file="$1"
    local line key value

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ""|\#*)
                continue
                ;;
        esac

        # Keep config values intentionally simple: paths with spaces are not supported.
        if [[ ! "$line" =~ ^[A-Z_]+=\"?[A-Za-z0-9_./:-]+\"?$ ]]; then
            log_warning "Ignoring invalid config line: $line"
            continue
        fi

        key="${line%%=*}"
        value="${line#*=}"
        value="$(strip_quotes "$value")"

        case "$key" in
            DEFAULT_TLD)
                validate_tld "$value" || { log_warning "Ignoring invalid DEFAULT_TLD in config"; continue; }
                DEFAULT_TLD="$value"
                ;;
            DEFAULT_PORT)
                validate_port "$value" || { log_warning "Ignoring invalid DEFAULT_PORT in config"; continue; }
                DEFAULT_PORT="$value"
                ;;
            DEFAULT_SSL_PORT)
                validate_port "$value" || { log_warning "Ignoring invalid DEFAULT_SSL_PORT in config"; continue; }
                DEFAULT_SSL_PORT="$value"
                ;;
            NGINX_CONF_DIR)
                NGINX_CONF_DIR="$value"
                ;;
            NGINX_MAIN_CONF)
                NGINX_MAIN_CONF="$value"
                ;;
            HOSTS_FILE)
                HOSTS_FILE="$value"
                ;;
            *)
                log_warning "Ignoring unknown config key: $key"
                ;;
        esac
    done < "$config_file"
}

#######################################
# Parse command line arguments
# Arguments:
#   All script arguments
# Outputs:
#   Sets global variables for all options
#######################################
parse_arguments() {
    # Initialize default values
    COMMAND=""
    DOMAIN_NAME=""
    DIST_FOLDER=""
    CUSTOM_PORT=""
    CUSTOM_TLD=""
    ENABLE_SSL=0
    ENABLE_SPA=0
    API_PROXY=""
    FORCE_UPDATE=0
    DRY_RUN=0
    VERBOSE=0
    QUIET=0

    # Check if no arguments provided
    if [ $# -eq 0 ]; then
        show_usage "$SCRIPT_NAME"
        exit 1
    fi

    # Parse command
    COMMAND="$1"
    shift

    case "$COMMAND" in
        create)
            parse_create_arguments "$@"
            ;;
        remove)
            parse_remove_arguments "$@"
            ;;
        list)
            # No additional arguments needed for list
            ;;
        version)
            echo "NGX Script v${SCRIPT_VERSION}"
            exit 0
            ;;
        -h|--help)
            show_usage "$SCRIPT_NAME"
            exit 0
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            show_usage "$SCRIPT_NAME"
            exit 1
            ;;
    esac
}

#######################################
# Parse arguments for remove command
# Arguments:
#   All arguments after 'remove'
#######################################
parse_remove_arguments() {
    local positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -q|--quiet)
                QUIET=1
                shift
                ;;
            -h|--help)
                show_usage "$SCRIPT_NAME"
                exit 0
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    # Restore positional arguments
    set -- "${positional[@]}"

    # Validate required arguments for remove
    if [ $# -lt 1 ]; then
        log_error "Domain name required for remove command"
        exit 1
    fi

    DOMAIN_NAME="$1"
    validate_domain_input "$DOMAIN_NAME"
}

#######################################
# Parse arguments for create command
# Arguments:
#   All arguments after 'create'
#######################################
parse_create_arguments() {
    local positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                if [ $# -lt 2 ]; then
                    log_error "Missing value for $1"
                    exit 1
                fi
                CUSTOM_PORT="$2"
                shift 2
                ;;
            -t|--tld)
                if [ $# -lt 2 ]; then
                    log_error "Missing value for $1"
                    exit 1
                fi
                CUSTOM_TLD="$2"
                shift 2
                ;;
            -s|--ssl)
                ENABLE_SSL=1
                shift
                ;;
            --spa)
                ENABLE_SPA=1
                shift
                ;;
            --api)
                if [ $# -lt 2 ]; then
                    log_error "Missing value for $1"
                    exit 1
                fi
                API_PROXY="$2"
                shift 2
                ;;
            -f|--force)
                FORCE_UPDATE=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -q|--quiet)
                QUIET=1
                shift
                ;;
            -h|--help)
                show_usage "$SCRIPT_NAME"
                exit 0
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    # Restore positional arguments
    set -- "${positional[@]}"

    # Validate required arguments for create
    if [ $# -lt 2 ]; then
        log_error "Domain name and path required for create command"
        show_usage "$SCRIPT_NAME"
        exit 1
    fi

    DOMAIN_NAME="$1"
    DIST_FOLDER="$2"
    validate_domain_input "$DOMAIN_NAME"

    if [ -n "$CUSTOM_TLD" ]; then
        validate_tld "$CUSTOM_TLD"
    fi

    if [ -n "$CUSTOM_PORT" ]; then
        validate_port "$CUSTOM_PORT"
    fi
}

#######################################
# Validate a TCP port number
# Arguments:
#   $1 - Port number
#######################################
validate_port() {
    local port="$1"

    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "Invalid port: $port"
        return 1
    fi

    return 0
}

#######################################
# Validate a TLD suffix
# Arguments:
#   $1 - TLD, including leading dot
#######################################
validate_tld() {
    local tld="$1"

    if [[ ! "$tld" =~ ^\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]]; then
        log_error "Invalid TLD: $tld"
        return 1
    fi

    return 0
}

#######################################
# Validate user-provided domain input before using it in paths/regexes
# Arguments:
#   $1 - Domain name
#######################################
validate_domain_input() {
    local domain="$1"
    local label
    local -a labels

    if [ -z "$domain" ] || [ "${#domain}" -gt 253 ]; then
        log_error "Invalid domain name: $domain"
        return 1
    fi

    if [[ "$domain" == *"/"* ]] || [[ "$domain" == *".."* ]] || [[ "$domain" == .* ]] || [[ "$domain" == *. ]]; then
        log_error "Invalid domain name: $domain"
        return 1
    fi

    IFS='.' read -r -a labels <<< "$domain"
    for label in "${labels[@]}"; do
        if [[ ! "$label" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]]; then
            log_error "Invalid domain name: $domain"
            return 1
        fi
    done

    return 0
}

#######################################
# Normalize domain name with custom TLD
# Arguments:
#   $1 - Domain name to normalize
# Outputs:
#   Normalized domain name
#######################################
normalize_domain_name() {
    local domain="$1"

    if [ -n "${CUSTOM_TLD:-}" ]; then
        if [[ "$domain" == *.* ]]; then
            domain="${domain%.*}"
        fi
        echo "${domain}${CUSTOM_TLD}"
        return 0
    fi

    if [[ "$domain" != *.* ]]; then
        echo "${domain}${DEFAULT_TLD}"
        return 0
    fi

    echo "$domain"
}

#######################################
# Extract config name from domain by replacing dots with underscores
# Arguments:
#   $1 - Domain name
# Outputs:
#   Config name suitable for file naming
#######################################
get_config_name() {
    local domain="$1"
    echo "$domain" | sed 's/\./_/g'
}

#######################################
# Escape a domain for use in grep/sed extended regexes
# Arguments:
#   $1 - Domain name
# Outputs:
#   Regex-safe domain
#######################################
escape_domain_regex() {
    local domain="$1"
    printf '%s' "$domain" | sed 's/[.[\*^$()+?{}|\\]/\\&/g'
}

#######################################
# Verify sudo is available before privileged changes begin
#######################################
ensure_sudo_access() {
    if ! command -v sudo >/dev/null 2>&1; then
        log_error "sudo is required for nginx and hosts file changes."
        return 1
    fi

    if ! sudo -v; then
        log_error "sudo authentication failed. No changes were made."
        return 1
    fi

    return 0
}

#######################################
# Install nginx using the available package manager
# Returns:
#   0 if nginx was installed, 1 otherwise
#######################################
install_nginx() {
    log_info "Installing Nginx..."

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y nginx
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y nginx
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y nginx
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm nginx
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y nginx
    elif command -v apk >/dev/null 2>&1; then
        sudo apk add nginx
    elif command -v brew >/dev/null 2>&1; then
        brew install nginx
    else
        log_error "No supported package manager found. Please install Nginx manually."
        return 1
    fi

    if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files nginx.service >/dev/null 2>&1; then
        sudo systemctl enable nginx >/dev/null 2>&1 || log_warning "Could not enable nginx service automatically."
        sudo systemctl start nginx >/dev/null 2>&1 || log_warning "Could not start nginx service automatically."
    fi

    command -v nginx >/dev/null 2>&1
}

#######################################
# Check if nginx is installed, prompting for installation when missing
# Returns:
#   0 if nginx is available, 1 otherwise
#######################################
check_nginx_availability() {
    # Check if nginx is installed
    if ! command -v nginx >/dev/null 2>&1; then
        log_warning "Nginx is not installed."

        if confirm "Install Nginx now?"; then
            if ! ensure_sudo_access; then
                return 1
            fi

            if ! install_nginx; then
                log_error "Nginx installation failed. Please install Nginx manually and try again."
                return 1
            fi
            log_success "Nginx installed successfully"
        else
            log_error "Nginx is required to create a site. Install it manually and run this command again."
            return 1
        fi
    fi
    
    # Check if nginx service exists
    if command -v systemctl >/dev/null 2>&1 && ! systemctl list-unit-files nginx.service >/dev/null 2>&1; then
        log_warning "Nginx service not found. Manual nginx management may be required."
    fi
    
    return 0
}

#######################################
# Determine which local user nginx should run as
# Outputs:
#   Username
#######################################
get_nginx_runtime_user() {
    local runtime_user="${SUDO_USER:-${USER:-}}"

    if [ -z "$runtime_user" ]; then
        runtime_user="$(id -un)"
    fi

    if [ "$runtime_user" = "root" ] && [ -n "${LOGNAME:-}" ] && [ "$LOGNAME" != "root" ]; then
        runtime_user="$LOGNAME"
    fi

    echo "$runtime_user"
}

#######################################
# Update nginx.conf to run workers as the invoking user
# Arguments:
#   $1 - Username
#######################################
update_nginx_runtime_user() {
    local runtime_user="$1"

    if ! id "$runtime_user" >/dev/null 2>&1; then
        log_error "User '$runtime_user' does not exist on this system."
        return 1
    fi

    if [ ! -f "$NGINX_MAIN_CONF" ]; then
        log_warning "Nginx main config not found at $NGINX_MAIN_CONF. Skipping nginx user update."
        return 0
    fi

    if sudo grep -Eq "^[[:space:]]*user[[:space:]]+$runtime_user;" "$NGINX_MAIN_CONF"; then
        log_verbose "Nginx runtime user already set to $runtime_user"
        return 0
    fi

    log_info "Updating nginx runtime user to $runtime_user in $NGINX_MAIN_CONF"
    sudo cp "$NGINX_MAIN_CONF" "${NGINX_MAIN_CONF}.bak"

    if sudo grep -Eq "^[[:space:]]*user[[:space:]]+" "$NGINX_MAIN_CONF"; then
        sudo sed -i "s/^[[:space:]]*user[[:space:]].*;/user $runtime_user;/" "$NGINX_MAIN_CONF"
    else
        local tmp_file
        tmp_file="$(mktemp)"
        chmod 600 "$tmp_file"
        printf 'user %s;\n' "$runtime_user" > "$tmp_file"
        sudo cat "$NGINX_MAIN_CONF" >> "$tmp_file"
        sudo tee "$NGINX_MAIN_CONF" < "$tmp_file" >/dev/null
        rm -f "$tmp_file"
    fi

    log_success "Nginx runtime user updated to $runtime_user"
}

#######################################
# Validate dist folder and suggest improvements
# Arguments:
#   $1 - Dist folder path
#######################################
validate_dist_folder() {
    local dist_folder="$1"
    
    # Check if folder exists
    if [ ! -d "$dist_folder" ]; then
        log_error "The folder path '$dist_folder' does not exist."
        return 1
    fi
    
    # Check if folder contains web files
    local has_index=0
    local has_html=0
    
    if [ -f "$dist_folder/index.html" ]; then
        has_index=1
        log_verbose "Found index.html"
    fi
    
    if find "$dist_folder" -name "*.html" -type f | head -1 | grep -q .; then
        has_html=1
        log_verbose "Found HTML files"
    fi
    
    # Suggest SPA mode if package.json exists but no index.html
    if [ -f "$dist_folder/package.json" ] && [ $has_index -eq 0 ]; then
        log_warning "Found package.json but no index.html. Consider using --spa flag for Single Page Applications."
    fi
    
    # Warn if no web files found
    if [ $has_index -eq 0 ] && [ $has_html -eq 0 ]; then
        log_warning "No HTML files found in $dist_folder. Make sure this is the correct directory."
    fi
    
    return 0
}

#######################################
# Check if SSL port conflicts with the HTTP port
# Arguments:
#   $1 - HTTP port
#   $2 - SSL enabled (0 or 1)
#######################################
validate_port_combination() {
    local port="$1"
    local ssl_enabled="${2:-0}"

    if ! validate_port "$port"; then
        return 1
    fi

    if [ "$ssl_enabled" -eq 1 ]; then
        if ! validate_port "$DEFAULT_SSL_PORT"; then
            return 1
        fi
        if [ "$port" -eq "$DEFAULT_SSL_PORT" ]; then
            log_error "HTTP port cannot match SSL port $DEFAULT_SSL_PORT when SSL is enabled."
            return 1
        fi
    fi

    return 0
}

#######################################
# Check if port is currently in use
# Arguments:
#   $1 - Port number
#######################################
check_single_port_availability() {
    local port="$1"

    if command -v ss >/dev/null 2>&1; then
        if ss -tuln 2>/dev/null | grep -Eq "[:.]$port[[:space:]]"; then
            log_warning "Port $port appears to be in use. This may cause conflicts."
            return 1
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln 2>/dev/null | grep -Eq "[:.]$port[[:space:]]"; then
            log_warning "Port $port appears to be in use. This may cause conflicts."
            return 1
        fi
    else
        log_verbose "Neither ss nor netstat found; skipping port availability check."
    fi

    return 0
}

#######################################
# Check for port conflicts
# Arguments:
#   $1 - HTTP port
#   $2 - SSL enabled (0 or 1)
#######################################
check_port_availability() {
    local port="$1"
    local ssl_enabled="${2:-0}"

    check_single_port_availability "$port" || return 1

    if [ "$ssl_enabled" -eq 1 ]; then
        check_single_port_availability "$DEFAULT_SSL_PORT" || return 1
    fi

    return 0
}

#######################################
# Check whether nginx appears to be managed by Homebrew
#######################################
is_brew_nginx() {
    local brew_prefix
    local nginx_path

    if [[ "$(uname -s)" != "Darwin" ]] || ! command -v brew >/dev/null 2>&1 || ! command -v nginx >/dev/null 2>&1; then
        return 1
    fi

    brew_prefix="$(brew --prefix 2>/dev/null || true)"
    nginx_path="$(command -v nginx)"

    [[ -n "$brew_prefix" && "$nginx_path" == "$brew_prefix"/* ]]
}

#######################################
# Generate SSL certificate for domain
# Arguments:
#   $1 - Domain name
#   $2 - Certificate directory
#   $3 - Private key directory
#######################################
generate_ssl_certificate() {
    local domain="$1"
    local cert_dir="$2"
    local key_dir="$3"
    local cert_path="$cert_dir/$domain.crt"
    local key_path="$key_dir/$domain.key"
    local csr_file
    
    log_verbose "Generating SSL certificate for $domain"
    
    # Create certificate and private key directories
    sudo mkdir -p "$cert_dir"
    sudo mkdir -p "$key_dir"
    csr_file="$(mktemp)"
    trap 'rm -f "$csr_file"' ERR RETURN
    
    # Generate private key
    sudo openssl genrsa -out "$key_path" 2048
    
    # Generate certificate signing request
    sudo openssl req -new -key "$key_path" -out "$csr_file" -subj "/CN=$domain"
    
    # Generate self-signed certificate
    sudo openssl x509 -req -days 365 -in "$csr_file" -signkey "$key_path" -out "$cert_path"
    
    # Set proper permissions
    sudo chmod 600 "$key_path"
    sudo chmod 644 "$cert_path"
    
    rm -f "$csr_file"
    trap - ERR RETURN
    
    log_success "SSL certificate generated for $domain"
}

#######################################
# Reload nginx using the available service manager
#######################################
reload_nginx() {
    if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files nginx.service >/dev/null 2>&1; then
        sudo systemctl reload nginx
        return $?
    fi

    if is_brew_nginx && brew services list 2>/dev/null | grep -Eq '^nginx[[:space:]]+started'; then
        if brew services help 2>/dev/null | grep -q '^ *reload'; then
            brew services reload nginx
        else
            brew services restart nginx
        fi
        return $?
    fi

    sudo nginx -s reload
}

#######################################
# Test nginx configuration using the available nginx command
#######################################
test_nginx_config() {
    if is_brew_nginx; then
        nginx -t
        return $?
    fi

    sudo nginx -t
}

#######################################
# Check if domain exists in hosts file with exact match
# Arguments:
#   $1 - Domain name
#   $2 - Hosts file path
# Returns:
#   0 if domain exists, 1 if it doesn't
#######################################
domain_exists_in_hosts() {
    local domain="$1"
    local hosts_file="$2"
    local domain_regex
    domain_regex="$(escape_domain_regex "$domain")"
    
    # Use grep with word boundaries and anchoring to ensure exact match
    if grep -Eq "127\.0\.0\.1[[:space:]]+${domain_regex}($|[[:space:]])" "$hosts_file"; then
        return 0  # Domain exists
    else
        return 1  # Domain doesn't exist
    fi
}

#######################################
# Remove a local hosts entry with an exact domain match
# Arguments:
#   $1 - Domain name
#   $2 - Hosts file path
#######################################
remove_domain_from_hosts() {
    local domain="$1"
    local hosts_file="$2"
    local tmp_file

    tmp_file="$(mktemp)"
    trap 'rm -f "$tmp_file"' ERR RETURN

    awk -v domain="$domain" '
        {
            remove_line = 0
            if ($1 == "127.0.0.1") {
                for (i = 2; i <= NF; i++) {
                    if ($i == domain) {
                        remove_line = 1
                        break
                    }
                }
            }
            if (!remove_line) {
                print
            }
        }
    ' "$hosts_file" > "$tmp_file"

    sudo tee "$hosts_file" < "$tmp_file" >/dev/null
    rm -f "$tmp_file"
    trap - ERR RETURN
}

#######################################
# Update hosts file with domain
# Arguments:
#   $1 - Domain name
#   $2 - Hosts file path
#   $3 - Force update flag (0 or 1)
# Returns:
#   0 if successful
#######################################
update_hosts_file() {
    local domain="$1"
    local hosts_file="$2"
    local force_update="${3:-0}"
    
    # Check if domain already exists in hosts file
    if domain_exists_in_hosts "$domain" "$hosts_file"; then
        if [ "$force_update" -eq 1 ]; then
            log_info "Domain ${domain} exists in hosts file. Forcing update as requested."
            # Remove existing entry (match exact domain)
            remove_domain_from_hosts "$domain" "$hosts_file"
            # Add the domain to /etc/hosts
            echo "127.0.0.1 ${domain}" | sudo tee -a "$hosts_file" >/dev/null
            log_success "Updated ${domain} in hosts file."
        else
            log_info "Domain ${domain} already exists in hosts file. Skipping... (use --force to override)"
        fi
    else
        # Add the domain to /etc/hosts
        echo "127.0.0.1 ${domain}" | sudo tee -a "$hosts_file" >/dev/null
        log_success "Added ${domain} to hosts file."
    fi
    
    return 0
}

#######################################
# Create Nginx configuration content
# Arguments:
#   $1 - Domain name
#   $2 - Document root
#   $3 - Port (optional)
#   $4 - SSL enabled (0 or 1)
#   $5 - SPA mode (0 or 1)
#   $6 - API proxy URL (optional)
#######################################
generate_nginx_config() {
    local domain="$1"
    local doc_root="$2"
    local port="${3:-80}"
    local ssl_enabled="${4:-0}"
    local spa_mode="${5:-0}"
    local api_proxy="${6:-}"
    
    local config_content=""
    
    # HTTP server block (always present)
    if [ "$ssl_enabled" -eq 1 ]; then
        # If SSL is enabled, redirect HTTP to HTTPS
        config_content+="server {
    listen $port;
    server_name $domain www.$domain;
    return 301 https://\$server_name\$request_uri;
}

"
        # HTTPS server block
        local ssl_port="$DEFAULT_SSL_PORT"
        config_content+="server {
    listen $ssl_port ssl;
    server_name $domain www.$domain;
    
    ssl_certificate /etc/ssl/certs/$domain.crt;
    ssl_certificate_key /etc/ssl/private/$domain.key;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    root $doc_root;
    index index.html index.htm index.nginx-debian.html;
"
    else
        # HTTP only server block.
        # Nginx listens on port 80 by default, so the listen directive is only needed for custom ports.
        config_content+="server {
"
        if [ "$port" != "80" ]; then
            config_content+="    listen $port;
"
        fi
        config_content+="    root $doc_root;
    index index.html index.htm index.nginx-debian.html;
    
    server_name $domain www.$domain;
"
    fi
    
    # Add API proxy configuration if specified
    if [ -n "$api_proxy" ]; then
        config_content+="    
    location /api/ {
        proxy_pass $api_proxy/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
"
    fi
    
    # Add location block for static files
    if [ "$spa_mode" -eq 1 ]; then
        # SPA configuration - try files then fallback to index.html
        config_content+="    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
"
    else
        # Standard static file serving. Use --spa to enable index.html fallback for client-side routing.
        config_content+="    
    location / {
        try_files \$uri \$uri/ =404;
    }
"
    fi
    
    config_content+="}"
    
    echo "$config_content"
}

#######################################
# Create a new site configuration
#######################################
create_site() {
    local normalized_domain
    normalized_domain=$(normalize_domain_name "$DOMAIN_NAME")
    validate_domain_input "$normalized_domain"
    
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        # Always show the main action, even in quiet mode
        echo "DRY RUN: Would create site for $normalized_domain"
        
        if [ "${QUIET:-0}" -eq 0 ]; then
            log_info "DRY RUN: Dist folder: $DIST_FOLDER"
            [ "${ENABLE_SSL:-0}" -eq 1 ] && log_info "DRY RUN: SSL enabled"
            [ "${ENABLE_SPA:-0}" -eq 1 ] && log_info "DRY RUN: SPA mode enabled"
            [ -n "${CUSTOM_PORT:-}" ] && log_info "DRY RUN: Custom port: $CUSTOM_PORT"
            [ -n "${API_PROXY:-}" ] && log_info "DRY RUN: API proxy: $API_PROXY"
            log_info "DRY RUN: Would ensure Nginx is installed"
            log_info "DRY RUN: Would update nginx runtime user in $NGINX_MAIN_CONF"
            
            if [ "${ENABLE_SSL:-0}" -eq 1 ]; then
                log_info "DRY RUN: Would generate SSL certificate"
                log_info "DRY RUN: Would configure HTTPS redirect"
            fi
            
            # Check if domain would be added to hosts file
            if domain_exists_in_hosts "$normalized_domain" "$HOSTS_FILE"; then
                if [ "${FORCE_UPDATE:-0}" -eq 1 ]; then
                    log_info "DRY RUN: Would update existing hosts file entry"
                else
                    log_info "DRY RUN: Domain already exists in hosts file (would skip)"
                fi
            else
                log_info "DRY RUN: Would add domain to hosts file"
            fi
        fi
        
        return 0
    fi
    
    # Convert relative path to absolute path if needed
    if [[ ! "$DIST_FOLDER" = /* ]]; then
        DIST_FOLDER="$(pwd)/$DIST_FOLDER"
        log_verbose "Using absolute path: $DIST_FOLDER"
    fi
    
    # Validate dist folder
    if ! validate_dist_folder "$DIST_FOLDER"; then
        exit 1
    fi

    # Check nginx availability
    if ! check_nginx_availability; then
        exit 1
    fi

    # Verify sudo before any privileged command can partially configure the system
    if ! ensure_sudo_access; then
        exit 1
    fi

    local runtime_user
    runtime_user="$(get_nginx_runtime_user)"
    if ! update_nginx_runtime_user "$runtime_user"; then
        exit 1
    fi
    
    local config_name
    config_name=$(get_config_name "$normalized_domain")
    local config_file="$NGINX_CONF_DIR/${config_name}.conf"
    local port="${CUSTOM_PORT:-$DEFAULT_PORT}"

    if ! validate_port_combination "$port" "${ENABLE_SSL:-0}"; then
        exit 1
    fi
    
    # Check port availability
    check_port_availability "$port" "${ENABLE_SSL:-0}" || true
    
    log_info "Creating site configuration for $normalized_domain"
    
    # Generate SSL certificate if needed
    if [ "${ENABLE_SSL:-0}" -eq 1 ]; then
        generate_ssl_certificate "$normalized_domain" "/etc/ssl/certs" "/etc/ssl/private"
    fi
    
    # Generate nginx configuration
    local nginx_config
    nginx_config=$(generate_nginx_config "$normalized_domain" "$DIST_FOLDER" "$port" "${ENABLE_SSL:-0}" "${ENABLE_SPA:-0}" "${API_PROXY:-}")
    
    # Write configuration file
    echo "$nginx_config" | sudo tee "$config_file" > /dev/null
    
    log_success "Nginx configuration created: $config_file"
    
    # Update hosts file
    log_info "Updating hosts file for $normalized_domain"
    update_hosts_file "$normalized_domain" "$HOSTS_FILE" "${FORCE_UPDATE:-0}"
    
    # Test and reload nginx
    if test_nginx_config; then
        reload_nginx
        log_success "Nginx reloaded successfully"
        
        local protocol="http"
        [ "${ENABLE_SSL:-0}" -eq 1 ] && protocol="https"
        
        log_success "Site created successfully!"
        log "🌍" "Access your site at: $protocol://$normalized_domain"
    else
        log_error "Nginx configuration test failed!"
        sudo rm -f "$config_file"
        exit 1
    fi
}

#######################################
# Remove a site configuration
#######################################
remove_site() {
    local normalized_domain
    normalized_domain=$(normalize_domain_name "$DOMAIN_NAME")
    validate_domain_input "$normalized_domain"
    
    local config_name
    config_name=$(get_config_name "$normalized_domain")
    local config_file="$NGINX_CONF_DIR/${config_name}.conf"
    
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        echo "DRY RUN: Would remove site for $normalized_domain"
        
        if [ -f "$config_file" ]; then
            log_info "DRY RUN: Would remove config file: $config_file"
            
            # Check if SSL certificates exist
            if [ -f "/etc/ssl/certs/$normalized_domain.crt" ]; then
                log_info "DRY RUN: Would remove SSL certificate"
            fi
            
            # Check hosts file entry
            if domain_exists_in_hosts "$normalized_domain" "$HOSTS_FILE"; then
                log_info "DRY RUN: Would remove hosts file entry"
            fi
        else
            log_warning "DRY RUN: Configuration file not found: $config_file"
        fi
        
        return 0
    fi

    # Check if configuration file exists
    if [ ! -f "$config_file" ]; then
        log_error "Site configuration for '$normalized_domain' not found"
        log_info "Available sites:"
        list_sites
        exit 1
    fi

    if ! ensure_sudo_access; then
        exit 1
    fi
    
    log_info "Removing site configuration for $normalized_domain"
    
    # Remove nginx configuration file
    log_verbose "Removing nginx configuration: $config_file"
    sudo rm -f "$config_file"
    
    # Remove SSL certificates if they exist
    if [ -f "/etc/ssl/certs/$normalized_domain.crt" ]; then
        log_verbose "Removing SSL certificate"
        sudo rm -f "/etc/ssl/certs/$normalized_domain.crt"
        sudo rm -f "/etc/ssl/private/$normalized_domain.key"
    fi
    
    # Remove hosts file entry
    if domain_exists_in_hosts "$normalized_domain" "$HOSTS_FILE"; then
        log_verbose "Removing hosts file entry"
        remove_domain_from_hosts "$normalized_domain" "$HOSTS_FILE"
    fi
    
    # Test and reload nginx
    if test_nginx_config; then
        reload_nginx
        log_success "Nginx reloaded successfully"
    else
        log_warning "Nginx configuration test failed after removal"
    fi
    
    log_success "Site '$normalized_domain' removed successfully"
}

#######################################
# List all configured sites
#######################################
list_sites() {
    local count=0
    local config_file
    local doc_root
    local server_name
    local ssl_status
    
    log_info "Configured Nginx sites:"
    echo
    
    # Find all .conf files in the nginx conf.d directory
    if [ -d "$NGINX_CONF_DIR" ]; then
        while IFS= read -r config_file; do
            if [ -f "$config_file" ]; then
                # Extract document root from config file
                doc_root=$(grep -E "^\s*root\s+" "$config_file" | head -1 | awk '{print $2}' | sed 's/;//' || echo "Unknown")
                
                # Extract server_name from config file
                server_name=$(grep -E "^\s*server_name\s+" "$config_file" | head -1 | sed 's/^\s*server_name\s*//' | sed 's/;//' || echo "Unknown")
                
                # Check if SSL is configured
                ssl_status=""
                if grep -q "ssl_certificate" "$config_file" 2>/dev/null; then
                    ssl_status=" (SSL)"
                fi
                
                echo "  📁 $server_name$ssl_status"
                echo "     Path: $doc_root"
                echo "     Config: $config_file"
                echo
                
                count=$((count + 1))
            fi
        done < <(find "$NGINX_CONF_DIR" -name "*.conf" -type f 2>/dev/null)
    fi
    
    if [ $count -eq 0 ]; then
        log_info "No sites configured"
        echo "  Use '$SCRIPT_NAME create <domain> <path>' to create a new site"
    else
        log_success "Found $count configured site(s)"
    fi
}

#######################################
# Main function
#######################################
main() {
    # Initialize configuration
    init_config
    
    # Parse arguments
    parse_arguments "$@"
    
    # Execute command
    case "$COMMAND" in
        create)
            create_site
            ;;
        remove)
            remove_site
            ;;
        list)
            list_sites
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
