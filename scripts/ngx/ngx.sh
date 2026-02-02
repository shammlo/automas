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
    cat <<EOF
🚀 Nginx Configuration Script v${SCRIPT_VERSION}

Usage: $script_name <command> [options]

Commands:
  create <domain> <path>    Create new site configuration
  remove <domain>           Remove site configuration
  list                      List all configured sites
  version                   Show version information

Create Options:
  -p, --port <port>         Custom port (default: 80)
  -t, --tld <tld>          Custom TLD (default: .io)
  -s, --ssl                Enable SSL/HTTPS
  --spa                    Configure for Single Page Application
  --api <url>              Add API proxy configuration
  -f, --force              Force update if domain exists
  --dry-run                Show what would be done without executing
  -v, --verbose            Enable verbose logging
  -q, --quiet              Minimal output
  -h, --help               Show this help message

Examples:
  $script_name create myapp /path/to/dist
  $script_name create myapp /path/to/dist --ssl --spa
  $script_name create api /path/to/dist --port 3000 --tld .dev
  $script_name remove myapp
  $script_name list
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
    
    # Source the config file
    source "$CONFIG_FILE"
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
        show_usage "$(basename "$0")"
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
            show_usage "$(basename "$0")"
            exit 0
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            show_usage "$(basename "$0")"
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
                show_usage "$(basename "$0")"
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
                CUSTOM_PORT="$2"
                shift 2
                ;;
            -t|--tld)
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
                show_usage "$(basename "$0")"
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
        show_usage "$(basename "$0")"
        exit 1
    fi

    DOMAIN_NAME="$1"
    DIST_FOLDER="$2"
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
    local tld="${CUSTOM_TLD:-$DEFAULT_TLD}"
    
    # Remove any existing TLD, then add the specified one
    domain=$(echo "$domain" | sed 's/\.[a-z]\+$//')
    echo "${domain}${tld}"
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
# Check if nginx is installed and running
# Returns:
#   0 if nginx is available, 1 otherwise
#######################################
check_nginx_availability() {
    # Check if nginx is installed
    if ! command -v nginx >/dev/null 2>&1; then
        log_error "Nginx is not installed. Please install nginx first."
        return 1
    fi
    
    # Check if nginx service exists
    if ! systemctl list-unit-files nginx.service >/dev/null 2>&1; then
        log_warning "Nginx service not found. Manual nginx management may be required."
    fi
    
    return 0
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
# Check for port conflicts
# Arguments:
#   $1 - Port number
#######################################
check_port_availability() {
    local port="$1"
    
    # Check if port is in use
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        log_warning "Port $port appears to be in use. This may cause conflicts."
        return 1
    fi
    
    return 0
}

#######################################
# Generate SSL certificate for domain
# Arguments:
#   $1 - Domain name
#   $2 - Certificate directory
#######################################
generate_ssl_certificate() {
    local domain="$1"
    local cert_dir="$2"
    
    log_verbose "Generating SSL certificate for $domain"
    
    # Create certificate directory
    sudo mkdir -p "$cert_dir"
    
    # Generate private key
    sudo openssl genrsa -out "$cert_dir/$domain.key" 2048
    
    # Generate certificate signing request
    sudo openssl req -new -key "$cert_dir/$domain.key" -out "$cert_dir/$domain.csr" -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
    
    # Generate self-signed certificate
    sudo openssl x509 -req -days 365 -in "$cert_dir/$domain.csr" -signkey "$cert_dir/$domain.key" -out "$cert_dir/$domain.crt"
    
    # Set proper permissions
    sudo chmod 600 "$cert_dir/$domain.key"
    sudo chmod 644 "$cert_dir/$domain.crt"
    
    # Clean up CSR file
    sudo rm -f "$cert_dir/$domain.csr"
    
    log_success "SSL certificate generated for $domain"
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
    
    # Use grep with word boundaries and anchoring to ensure exact match
    if grep -q "127\.0\.0\.1[[:space:]]\+${domain}$\|127\.0\.0\.1[[:space:]]\+${domain}[[:space:]]\+" "$hosts_file"; then
        return 0  # Domain exists
    else
        return 1  # Domain doesn't exist
    fi
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
            sudo sed -i "/127\.0\.0\.1[[:space:]]\+${domain}$/d" "$hosts_file"
            sudo sed -i "/127\.0\.0\.1[[:space:]]\+${domain}[[:space:]]\+/d" "$hosts_file"
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
        local ssl_port="${CUSTOM_PORT:-443}"
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
        # HTTP only server block - only add listen directive if custom port is specified
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
        # Check if this looks like a SPA by examining the dist folder
        if [ -f "$doc_root/index.html" ] && [ -d "$doc_root/assets" ]; then
            # Likely a SPA build (has index.html and assets folder)
            config_content+="    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
"
        else
            # Standard static file serving
            config_content+="    
    location / {
        try_files \$uri \$uri/ =404;
    }
"
        fi
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
    
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        # Always show the main action, even in quiet mode
        echo "DRY RUN: Would create site for $normalized_domain"
        
        if [ "${QUIET:-0}" -eq 0 ]; then
            log_info "DRY RUN: Dist folder: $DIST_FOLDER"
            [ "${ENABLE_SSL:-0}" -eq 1 ] && log_info "DRY RUN: SSL enabled"
            [ "${ENABLE_SPA:-0}" -eq 1 ] && log_info "DRY RUN: SPA mode enabled"
            [ -n "${CUSTOM_PORT:-}" ] && log_info "DRY RUN: Custom port: $CUSTOM_PORT"
            [ -n "${API_PROXY:-}" ] && log_info "DRY RUN: API proxy: $API_PROXY"
            
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
    
    local config_name
    config_name=$(get_config_name "$normalized_domain")
    local config_file="$NGINX_CONF_DIR/${config_name}.conf"
    local port="${CUSTOM_PORT:-$DEFAULT_PORT}"
    
    # Check port availability
    check_port_availability "$port"
    
    log_info "Creating site configuration for $normalized_domain"
    
    # Generate SSL certificate if needed
    if [ "${ENABLE_SSL:-0}" -eq 1 ]; then
        generate_ssl_certificate "$normalized_domain" "/etc/ssl/certs"
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
    if sudo nginx -t; then
        sudo systemctl reload nginx
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
    
    local config_name
    config_name=$(get_config_name "$normalized_domain")
    local config_file="$NGINX_CONF_DIR/${config_name}.conf"
    
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log_info "DRY RUN: Would remove site for $normalized_domain"
        
        if [ -f "$config_file" ]; then
            log_info "DRY RUN: Would remove config file: $config_file"
            
            # Check if SSL certificates exist
            if [ -f "/etc/ssl/certs/$normalized_domain.crt" ]; then
                log_info "DRY RUN: Would remove SSL certificate"
            fi
            
            # Check hosts file entry
            if grep -q "127\.0\.0\.1[[:space:]]\+${normalized_domain}" "$HOSTS_FILE" 2>/dev/null; then
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
    if grep -q "127\.0\.0\.1[[:space:]]\+${normalized_domain}" "$HOSTS_FILE" 2>/dev/null; then
        log_verbose "Removing hosts file entry"
        sudo sed -i "/127\.0\.0\.1[[:space:]]\+${normalized_domain}/d" "$HOSTS_FILE"
    fi
    
    # Test and reload nginx
    if sudo nginx -t; then
        sudo systemctl reload nginx
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
    local config_files
    local count=0
    
    log_info "Configured Nginx sites:"
    echo
    
    # Find all .conf files in the nginx conf.d directory
    if [ -d "$NGINX_CONF_DIR" ]; then
        config_files=$(find "$NGINX_CONF_DIR" -name "*.conf" -type f 2>/dev/null || true)
        
        if [ -n "$config_files" ]; then
            while IFS= read -r config_file; do
                if [ -f "$config_file" ]; then
                    local filename
                    filename=$(basename "$config_file" .conf)
                    
                    # Convert underscores back to dots for display
                    local domain_name
                    domain_name=$(echo "$filename" | sed 's/_/\./g')
                    
                    # Extract document root from config file
                    local doc_root
                    doc_root=$(grep -E "^\s*root\s+" "$config_file" | head -1 | awk '{print $2}' | sed 's/;//' || echo "Unknown")
                    
                    # Extract server_name from config file
                    local server_name
                    server_name=$(grep -E "^\s*server_name\s+" "$config_file" | head -1 | sed 's/^\s*server_name\s*//' | sed 's/;//' || echo "Unknown")
                    
                    # Check if SSL is configured
                    local ssl_status=""
                    if grep -q "ssl_certificate" "$config_file" 2>/dev/null; then
                        ssl_status=" (SSL)"
                    fi
                    
                    echo "  📁 $server_name$ssl_status"
                    echo "     Path: $doc_root"
                    echo "     Config: $config_file"
                    echo
                    
                    ((count++))
                fi
            done <<< "$config_files"
        fi
    fi
    
    if [ $count -eq 0 ]; then
        log_info "No sites configured"
        echo "  Use '$0 create <domain> <path>' to create a new site"
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