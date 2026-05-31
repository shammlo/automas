#!/bin/bash
set -euo pipefail

# Location of the external config file (relative to script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_CONFIG_FILE="$SCRIPT_DIR/.dbmrc"
DEBUG_MODE=false # Set to true to enable debug logs

# Supported config formats:
# Format 1: user:port:database (legacy, password via .pgpass/PGPASSWORD/prompt)
# Format 2: user::port:database (password via .pgpass/PGPASSWORD/prompt)
# Format 3: user:password:port:database (password in config - less secure)
# Format 4: user:password:port:database:host (custom host)
# Format 5: user:password:port:database:host:sslmode (with SSL)
# Format 6: user:password:port:database:host:sslmode:cert_path (with client cert)
# Format 7: postgres://user:pass@host:port/db?sslmode=require (full URI)
# Format 8: postgres://user:pass@host:port/db?sslmode=require&sslcert=/path/cert

# Error handling
error_exit() {
    echo "🚨 Error: $1" >&2
    exit 1
}

# Check if debug is enabled at the start
if [[ "${1:-}" == "--debug" ]]; then
    DEBUG_MODE=true
    shift
fi

# Load projects config from file into associative array
declare -A PROJECT_CONFIGS=()
declare -a PG_CMD=()

validate_project_name() {
    local project_name="$1"

    if [[ ! "$project_name" =~ ^[A-Za-z0-9_-]+$ ]]; then
        error_exit "❌ Invalid project name '$project_name'. Use letters, numbers, hyphens, and underscores only."
    fi
}

validate_config_string() {
    local config_string="$1"

    [[ "$config_string" =~ ^[^:]+:[^:]*:[0-9]+:[^:]+(:.*)*$ ]] || [[ "$config_string" =~ ^[^:]+:[0-9]+:[^:]+$ ]] || [[ "$config_string" =~ ^postgres(ql)?:// ]]
}

mask_config() {
    local config="$1"
    local parts

    if [[ "$config" =~ ^postgres(ql)?:// ]]; then
        printf '%s\n' "$config" | sed -E 's#^(postgres(ql)?://[^:/@]+:)[^@]*@#\1****@#'
        return 0
    fi

    IFS=':' read -r -a parts <<< "$config"
    if [ "${#parts[@]}" -ge 4 ]; then
        parts[1]="****"
        (IFS=':'; echo "${parts[*]}")
    else
        echo "$config"
    fi
}

read_project_config_value() {
    local project_name="$1"
    local line key value

    if [[ ! -f "$PROJECT_CONFIG_FILE" ]]; then
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"

        if [[ "$key" == "$project_name" ]]; then
            echo "$value"
            return 0
        fi
    done < "$PROJECT_CONFIG_FILE"

    return 1
}

project_config_exists() {
    local project_name="$1"

    read_project_config_value "$project_name" >/dev/null
}

remove_project_config_entry() {
    local project_name="$1"
    local temp_file
    local line key

    temp_file="$(mktemp)"
    trap 'rm -f "$temp_file"' ERR RETURN

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *=* ]]; then
            key="${line%%=*}"
            if [[ "$key" == "$project_name" ]]; then
                continue
            fi
        fi
        printf '%s\n' "$line"
    done < "$PROJECT_CONFIG_FILE" > "$temp_file"

    mv "$temp_file" "$PROJECT_CONFIG_FILE"
    trap - ERR RETURN
}

load_project_configs() {
    if [[ -f "$PROJECT_CONFIG_FILE" ]]; then
        local line key value
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" != *=* ]] && continue
            key="${line%%=*}"
            value="${line#*=}"

            # Ignore empty lines and comments
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

            if [[ ! "$key" =~ ^[A-Za-z0-9_-]+$ ]]; then
                echo "⚠️  Skipping invalid project name in config: $key"
                continue
            fi
            
            # Validate format - support multiple formats including URIs and legacy format
            if ! validate_config_string "$value"; then
                echo "⚠️  Skipping invalid config line: $key=$(mask_config "$value")"
                echo "   Expected formats: user:password:port:db[:host[:ssl[:cert]]], user:port:db (legacy), or postgres://..."
                continue
            fi
            
            PROJECT_CONFIGS["$key"]="$value"
        done <"$PROJECT_CONFIG_FILE"
    else
        echo "⚠️  Config file $PROJECT_CONFIG_FILE not found — will fallback to environment variables."
        
        # Check if template exists and offer to create config file
        local template_file="$SCRIPT_DIR/.dbmrc.template"
        if [[ -f "$template_file" ]] && [[ -t 0 ]]; then  # Only prompt if running interactively
            echo
            echo "💡 Found template file. Would you like to create a config file from the template?"
            echo "   This will copy .dbmrc.template to .dbmrc for you to customize."
            read -p "Create config file? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cp "$template_file" "$PROJECT_CONFIG_FILE"
                echo "✅ Created $PROJECT_CONFIG_FILE from template"
                echo "📝 Please edit $PROJECT_CONFIG_FILE with your actual database credentials"
                echo "   Example: nano $PROJECT_CONFIG_FILE"
                echo
            fi
        fi
    fi
}

# Try to get project config: first from file, then from environment variables
get_project_config() {
    local project_name="$1"
    validate_project_name "$project_name"
    [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 get_project_config called with project_name: '$project_name'"
    
    local config="${PROJECT_CONFIGS[$project_name]:-}"
    [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 PROJECT_CONFIGS[$project_name] = '$(mask_config "$config")'"
    
    if [[ -z "$config" ]]; then
        local p_upper
        p_upper=$(echo "$project_name" | tr '[:lower:]-' '[:upper:]_')
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Looking for env vars using prefix: '$p_upper'"
        
        local user_var="${p_upper}_USER"
        local password_var="${p_upper}_PASSWORD"
        local port_var="${p_upper}_PORT"
        local db_var="${p_upper}_DB"
        local host_var="${p_upper}_HOST"
        
        local user="${!user_var:-}"
        local password="${!password_var:-}"
        local port="${!port_var:-}"
        local db="${!db_var:-}"
        local host="${!host_var:-localhost}"
        
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Values found: $user_var=$user, $password_var=[HIDDEN], $port_var=$port, $db_var=$db, $host_var=$host"
        
        if [[ -n "$user" && -n "$port" && -n "$db" ]]; then
            config="$user:$password:$port:$db:$host"
            [[ "$DEBUG_MODE" == true ]] && echo >&2 "✅ Final fallback config: $user:[HIDDEN]:$port:$db:$host"
        else
            error_exit "🔍 Missing config for '$project_name'. Define it in env or $PROJECT_CONFIG_FILE"
        fi
    else
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "✅ Loaded config from file: $(mask_config "$config")"
    fi
    
    echo "$config"
}

# Show help message
show_help() {
    cat <<EOF
📋 Database Manager (DBM) Usage:

Syntax: dbm [--debug] <action> <project_name> [<file_path>] [options]

🛠️  Actions:
  reset, r, -r     🔄 Reset the database for the given project (requires SQL file)
  backup, b, -b    💾 Backup the database (requires output file)
  start, s, -s     🚀 Start interactive psql shell for the project
  list, l, -l      📚 List all configured database projects
  check, c, -c     🔍 Test database connection (use --all for all projects)
  info, i, -i      📊 Show database information and statistics
  config           ⚙️  Manage project configurations (add/remove/edit)
  init             🚀 Initialize configuration file from template

📋 Global Options:
  --debug          🧪 Enable detailed debug output (shows connection details)
  -h, --help       ℹ️  Display this help message

📋 Action Options:
  -o, --overwrite  🔃 Overwrite existing backup file (for backup action only)
  --all            🌐 Apply action to all configured projects (for check action)
  --tables         📋 Show table list (for info action)
  --size           💾 Show size details (for info action)

🏗️  Configuration Methods:

  📁 Config File (.dbmrc in script directory):
    Format 1: user:port:database (legacy, password via .pgpass/PGPASSWORD/prompt)
    Format 2: user::port:database (password via .pgpass/PGPASSWORD/prompt)
    Format 3: user:password:port:database (password in config)
    Format 4: user:password:port:database:host (custom host)
    Format 5: user:password:port:database:host:sslmode (with SSL)
    Format 6: user:password:port:database:host:sslmode:cert_path (with client cert)
    Format 7: postgres://user:pass@host:port/db?sslmode=require (full URI)
    Format 8: postgres://user:pass@host:port/db?sslmode=require&sslcert=/path/cert (URI with SSL cert)
  
  🌍 Environment Variables:
    PROJECT_USER, PROJECT_PASSWORD, PROJECT_PORT, PROJECT_DB, PROJECT_HOST
    (Replace PROJECT with your actual project name in uppercase)
  
  🔐 Authentication Methods (in order of preference):
    1. .pgpass file (most secure - ~/.pgpass)
    2. Password in config file
    3. PGPASSWORD environment variable
    4. Interactive prompt (fallback)

🔒 SSL Modes Supported:
  disable, allow, prefer, require, verify-ca, verify-full

💡 Examples:

  📚 List available projects:
    dbm list
    dbm l

  🚀 Start interactive shell:
    dbm start duck
    dbm s dragon

  💾 Backup database:
    dbm backup phoenix ~/backups/phoenix-backup.psql
    dbm b duck ~/duck.psql --overwrite

  🔄 Reset/restore database:
    dbm reset dragon ~/schema.sql
    dbm r phoenix /path/to/restore.sql

  🔍 Check database connections:
    dbm check duck
    dbm check --all
    dbm c dragon

  📊 Get database information:
    dbm info phoenix
    dbm info duck --tables
    dbm info dragon --size
    dbm i phoenix --tables --size

  ⚙️  Manage configurations:
    dbm config add newdb user:pass:5432:database:host
    dbm config remove olddb
    dbm config edit mydb

  🧪 Debug mode (see connection details):
    dbm --debug start duck
    dbm --debug check --all
    dbm --debug info phoenix

  🌐 Environment variable setup:
    export DUCK_USER=duck_user
    export DUCK_PASSWORD=secret123
    export DUCK_PORT=5432
    export DUCK_DB=duck_database
    export DUCK_HOST=localhost

🎯 Quick Start:
  0. Initialize config: 'dbm init' (creates .dbmrc from template)
  1. Add database projects: 'dbm config add mydb user:pass:5432:database'
  2. List available projects: 'dbm list'
  3. Test connections: 'dbm check --all'
  4. Get database info: 'dbm info mydb'
  5. Connect interactively: 'dbm start mydb'
  6. Backup database: 'dbm backup mydb ~/backup.psql'
  7. Restore database: 'dbm reset mydb ~/backup.sql'

EOF
    exit 0
}

# Parse config string into connection parameters
parse_config() {
    local config="$1"
    
    # Check if it's a full connection string/URI
    if [[ "$config" =~ ^postgres:// || "$config" =~ ^postgresql:// ]]; then
        parse_connection_string "$config"
        return
    fi
    
    local parts
    IFS=':' read -ra parts <<<"$config"
    
    # Support multiple formats
    case ${#parts[@]} in
        3) # user:port:database (legacy format - password same as username)
            username="${parts[0]}"
            password=""
            port="${parts[1]}"
            database="${parts[2]}"
            host="localhost"
            ssl_mode=""
            cert_path=""
            echo "⚠️  Legacy config format for '$username' has no password; using .pgpass, PGPASSWORD, or interactive prompt." >&2
            ;;
        4) # user:password:port:database
            username="${parts[0]}"
            password="${parts[1]}"
            port="${parts[2]}"
            database="${parts[3]}"
            host="localhost"
            ssl_mode=""
            cert_path=""
            ;;
        5) # user:password:port:database:host
            username="${parts[0]}"
            password="${parts[1]}"
            port="${parts[2]}"
            database="${parts[3]}"
            host="${parts[4]}"
            ssl_mode=""
            cert_path=""
            ;;
        6) # user:password:port:database:host:ssl_mode
            username="${parts[0]}"
            password="${parts[1]}"
            port="${parts[2]}"
            database="${parts[3]}"
            host="${parts[4]}"
            ssl_mode="${parts[5]}"
            cert_path=""
            ;;
        7) # user:password:port:database:host:ssl_mode:cert_path
            username="${parts[0]}"
            password="${parts[1]}"
            port="${parts[2]}"
            database="${parts[3]}"
            host="${parts[4]}"
            ssl_mode="${parts[5]}"
            cert_path="${parts[6]}"
            ;;
        *) 
            error_exit "❌ Invalid config format: $config"
            ;;
    esac
    
    # If no password in config, try PGPASSWORD env var
    if [[ -z "$password" ]]; then
        if [[ -n "${PGPASSWORD:-}" ]]; then
            password="$PGPASSWORD"
        fi
    fi
}

# Parse PostgreSQL connection string/URI
parse_connection_string() {
    local uri="$1"
    
    # Extract components from PostgreSQL URI
    # Format: postgres://user:password@host:port/database?sslmode=require
    
    # Remove protocol
    uri="${uri#postgres://}"
    uri="${uri#postgresql://}"
    
    # Extract user:password@host:port/database
    local user_pass_host_port_db="$uri"
    local query_params=""
    if [[ "$uri" == *\?* ]]; then
        user_pass_host_port_db="${uri%%\?*}"
        query_params="${uri#*\?}"
    fi
    
    # Parse user:password@host:port/database
    if [[ "$user_pass_host_port_db" =~ ^([^:]+):([^@]+)@(.+)$ ]]; then
        username="${BASH_REMATCH[1]}"
        password="${BASH_REMATCH[2]}"
        local host_port_db="${BASH_REMATCH[3]}"
        
        # Parse host:port/database
        if [[ "$host_port_db" =~ ^([^:]+):([0-9]+)/(.+)$ ]]; then
            host="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
            database="${BASH_REMATCH[3]}"
        else
            error_exit "❌ Invalid connection string format: $1"
        fi
    elif [[ "$user_pass_host_port_db" =~ ^([^@]+)@(.+)$ ]]; then
        # No password
        username="${BASH_REMATCH[1]}"
        password=""
        local host_port_db="${BASH_REMATCH[2]}"
        
        if [[ "$host_port_db" =~ ^([^:]+):([0-9]+)/(.+)$ ]]; then
            host="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
            database="${BASH_REMATCH[3]}"
        else
            error_exit "❌ Invalid connection string format: $1"
        fi
    else
        error_exit "❌ Invalid connection string format: $1"
    fi
    
    # Parse query parameters for SSL mode
    ssl_mode=""
    cert_path=""
    if [[ -n "$query_params" ]]; then
        IFS='&' read -ra params <<<"$query_params"
        for param in "${params[@]}"; do
            if [[ "$param" =~ ^sslmode=(.+)$ ]]; then
                ssl_mode="${BASH_REMATCH[1]}"
            elif [[ "$param" =~ ^sslcert=(.+)$ ]]; then
                cert_path="${BASH_REMATCH[1]}"
            fi
        done
    fi
    
    [[ "$DEBUG_MODE" == true ]] && {
        echo >&2 "🧪 Parsed URI: user='$username', host='$host', port='$port', db='$database', ssl='$ssl_mode'"
    }
}

# Build PostgreSQL connection command with all options into PG_CMD.
# PG_CMD is intentionally global because Bash cannot return arrays directly.
# Call build_pg_command immediately before run_pg_command/run_pg_command_timeout.
build_pg_command() {
    local base_cmd="$1"  # psql or pg_dump
    shift

    PG_CMD=("$base_cmd")
    
    # Add user
    [[ -n "$username" ]] && PG_CMD+=("-U" "$username")
    
    # Add database
    [[ -n "$database" ]] && PG_CMD+=("-d" "$database")
    
    # Add host (always add -h to force TCP/IP connections)
    [[ -n "$host" ]] && PG_CMD+=("-h" "$host")
    
    # Add port
    [[ -n "$port" ]] && PG_CMD+=("-p" "$port")
    
    if [[ -n "$ssl_mode" ]]; then
        case "$ssl_mode" in
            "disable"|"allow"|"prefer"|"require"|"verify-ca"|"verify-full") ;;
            *)
                echo "⚠️  Warning: Invalid SSL mode '$ssl_mode', using default" >&2
                ssl_mode=""
                ;;
        esac
    fi
    
    # Add client certificate path
    if [[ -n "$cert_path" ]]; then
        if [[ ! -f "$cert_path" ]]; then
            echo "⚠️  Warning: SSL certificate file not found: $cert_path" >&2
            cert_path=""
        fi
    fi
    
    # Add extra arguments
    [[ $# -gt 0 ]] && PG_CMD+=("$@")
}

build_pg_env() {
    PG_ENV=()

    [[ -n "${ssl_mode:-}" ]] && PG_ENV+=("PGSSLMODE=$ssl_mode")
    [[ -n "${cert_path:-}" ]] && PG_ENV+=("PGSSLCERT=$cert_path")
    [[ -n "${password:-}" ]] && PG_ENV+=("PGPASSWORD=$password")
}

debug_command() {
    local arg

    for arg in "$@"; do
        printf '%q ' "$arg" >&2
    done
    echo >&2
}

run_pg_command() {
    local PG_ENV=()
    build_pg_env

    if [[ ${#PG_ENV[@]} -gt 0 ]]; then
        env "${PG_ENV[@]}" "$@"
    else
        "$@"
    fi
}

run_pg_command_timeout() {
    local seconds="$1"
    shift
    local PG_ENV=()
    build_pg_env
    
    if [[ ${#PG_ENV[@]} -gt 0 ]]; then
        timeout "$seconds" env "${PG_ENV[@]}" "$@"
    else
        timeout "$seconds" "$@"
    fi
}

# Check for .pgpass file and use it if available
check_pgpass() {
    local pgpass_file="$HOME/.pgpass"
    local pg_host pg_port pg_db pg_user
    local perms

    if [[ -f "$pgpass_file" ]]; then
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Found .pgpass file at $pgpass_file"

        perms="$(stat -c '%a' "$pgpass_file" 2>/dev/null || stat -f '%A' "$pgpass_file" 2>/dev/null || echo "")"
        if [[ "$perms" != "600" ]]; then
            [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Ignoring .pgpass because permissions are '$perms' instead of 600"
            return 1
        fi
        
        # Check if there's a matching entry in .pgpass
        # Format: hostname:port:database:username:password
        while IFS=':' read -r pg_host pg_port pg_db pg_user _ || [[ -n "${pg_host:-}" ]]; do
            [[ -z "${pg_host:-}" || "$pg_host" =~ ^# ]] && continue
            if [[ ("$pg_host" == "*" || "$pg_host" == "$host") &&
                  ("$pg_port" == "*" || "$pg_port" == "$port") &&
                  ("$pg_db" == "*" || "$pg_db" == "$database") &&
                  ("$pg_user" == "*" || "$pg_user" == "$username") ]]; then
                [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Found matching .pgpass entry"
                return 0
            fi
        done < "$pgpass_file"
    fi
    
    return 1
}

# Reset database
reset_database() {
    local project_name="$1"
    local file_path="$2"
    
    [[ -z "$file_path" ]] && error_exit "📂 Reset requires a SQL file path."
    [[ "$file_path" == "~"* ]] && file_path="${file_path/#\~/$HOME}"
    [[ ! -f "$file_path" ]] && error_exit "📂 SQL file not found: $file_path"
    
    local config username password port database host ssl_mode cert_path
    config=$(get_project_config "$project_name")
    parse_config "$config"
    
    [[ "$DEBUG_MODE" == true ]] && {
        echo >&2 "🧪 reset_database() project_name='$project_name'"
        echo >&2 "🧪 Parsed config: user='$username', port='$port', db='$database', host='$host', ssl='$ssl_mode'"
    }
    
    echo "🔄 Resetting database '$database' for project '$project_name'..."
    
    # Check for .pgpass first (most secure)
    if check_pgpass; then
        password=""
        echo "🔐 Using .pgpass for authentication"
    elif [[ -n "$password" ]]; then
        echo "🔑 Using password from configuration"
    else
        echo "🔍 No password found - will prompt for authentication"
    fi
    
    # Build and execute the command
    build_pg_command "psql" "-f" "$file_path"
    
    [[ "$DEBUG_MODE" == true ]] && { echo >&2 "🧪 Executing:"; debug_command "${PG_CMD[@]}"; }
    
    if run_pg_command "${PG_CMD[@]}"; then
        echo "✅ Database reset successfully for $project_name"
    else
        error_exit "❌ Failed to reset database for $project_name"
    fi
}

# Backup database
backup_database() {
    local project_name="$1"
    local file_path=""
    local tmp_out=""
    local overwrite=false
    
    shift # Drop project name
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o | --overwrite)
                overwrite=true
                shift
                ;;
            *)
                if [[ -z "$file_path" ]]; then
                    file_path="$1"
                else
                    echo "⚠️ Ignoring extra argument: $1"
                fi
                shift
                ;;
        esac
    done
    
    [[ -z "$file_path" ]] && error_exit "📂 Backup requires a file path."
    
    # Expand ~ to home directory
    [[ "$file_path" == "~"* ]] && file_path="${file_path/#\~/$HOME}"
    [[ "$file_path" != *.psql ]] && error_exit "📂 Backup file must have a .psql extension."
    [[ -f "$file_path" && "$overwrite" != true ]] && error_exit "📂 File already exists: $file_path. Use -o to overwrite."
    
    local config username password port database host ssl_mode cert_path
    config=$(get_project_config "$project_name")
    parse_config "$config"
    
    [[ "$DEBUG_MODE" == true ]] && {
        echo >&2 "🧪 backup_database() project_name='$project_name'"
        echo >&2 "🧪 Parsed config: user='$username', port='$port', db='$database', host='$host', ssl='$ssl_mode'"
    }
    
    [[ "$overwrite" == true && -f "$file_path" ]] && echo "⚠️  Overwriting existing backup file: $file_path"
    
    echo "💾 Backing up database '$database' for project '$project_name'..."
    
    # Check for .pgpass first (most secure)
    if check_pgpass; then
        password=""
        echo "🔐 Using .pgpass for authentication"
    elif [[ -n "$password" ]]; then
        echo "🔑 Using password from configuration"
    else
        echo "🔍 No password found - will prompt for authentication"
    fi
    
    # Build and execute the command
    build_pg_command "pg_dump" "--clean"
    
    [[ "$DEBUG_MODE" == true ]] && { echo >&2 "🧪 Executing backup command to $file_path:"; debug_command "${PG_CMD[@]}"; }
    
    tmp_out="$(mktemp)"
    trap 'rm -f "$tmp_out"' ERR RETURN

    if run_pg_command "${PG_CMD[@]}" >"$tmp_out"; then
        mv "$tmp_out" "$file_path"
        trap - ERR RETURN
        echo "✅ Database backed up successfully to $file_path"
    else
        error_exit "❌ Failed to backup database for $project_name"
    fi
}

# Start database interactive shell
start_database() {
    local project_name="$1"
    [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 start_database() received project_name='$project_name'"
    
    local config username password port database host ssl_mode cert_path
    config=$(get_project_config "$project_name")
    parse_config "$config"
    
    [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Parsed values: username='$username', port='$port', database='$database', host='$host', ssl='$ssl_mode'"
    
    echo "🚀 Starting psql shell for database '$database' (project '$project_name')..."
    
    # Check for .pgpass first (most secure)
    if check_pgpass; then
        password=""
        echo "🔐 Using .pgpass for authentication"
    elif [[ -n "$password" ]]; then
        echo "🔑 Using password from configuration"
    else
        echo "🔍 No password found - will prompt for authentication"
    fi
    
    # Build and execute the command
    build_pg_command "psql"
    
    [[ "$DEBUG_MODE" == true ]] && { echo >&2 "🧪 Executing:"; debug_command "${PG_CMD[@]}"; }
    
    run_pg_command "${PG_CMD[@]}"
}

# List projects available in config file
list_projects() {
    if [[ ${#PROJECT_CONFIGS[@]} -eq 0 ]]; then
        echo "ℹ️  No projects loaded from $PROJECT_CONFIG_FILE"
    else
        echo 
        echo "📚 Projects from $PROJECT_CONFIG_FILE:"
        for key in "${!PROJECT_CONFIGS[@]}"; do
            echo " - $key -> $(mask_config "${PROJECT_CONFIGS[$key]}")"
        done
    fi
    
    echo
    echo "⚠️  You can also define projects by setting environment variables:"
    echo "    <PROJECT>_USER, <PROJECT>_PASSWORD, <PROJECT>_PORT, <PROJECT>_DB, <PROJECT>_HOST"
    echo "    (HOST defaults to localhost if not specified)"
}

# Check database connection
check_database() {
    local project_name="${1:-}"
    local check_all=false
    
    if [[ "$project_name" == "--all" ]]; then
        check_all=true
    fi
    
    if [[ "$check_all" == true ]]; then
        echo "🔍 Checking all configured database connections..."
        echo
        
        local total=0
        local success=0
        local failed=0
        
        for project in "${!PROJECT_CONFIGS[@]}"; do
            total=$((total + 1))
            echo "📋 Checking project: $project"
            
            if check_single_database "$project"; then
                success=$((success + 1))
            else
                failed=$((failed + 1))
            fi
            echo
        done
        
        echo "📊 Connection Check Summary:"
        echo "   Total: $total"
        echo "   ✅ Success: $success"
        echo "   ❌ Failed: $failed"
        
        if [[ $failed -eq 0 ]]; then
            echo "🎉 All database connections are healthy!"
        else
            echo "⚠️  Some database connections failed. Check the details above."
        fi
    else
        [[ -z "$project_name" ]] && error_exit "❌ 'check' action requires <project> or --all"
        echo "🔍 Checking database connection for project '$project_name'..."
        check_single_database "$project_name"
    fi
}

# Check single database connection
check_single_database() {
    local project_name="$1"
    
    local config username password port database host ssl_mode cert_path
    config=$(get_project_config "$project_name")
    parse_config "$config"
    
    [[ "$DEBUG_MODE" == true ]] && {
        echo >&2 "🧪 check_single_database() project_name='$project_name'"
        echo >&2 "🧪 Parsed config: user='$username', port='$port', db='$database', host='$host', ssl='$ssl_mode'"
    }
    
    # Check for .pgpass first (most secure)
    if check_pgpass; then
        password=""
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Using .pgpass for authentication"
    elif [[ -n "$password" ]]; then
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Using password from configuration"
    else
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 No password found - will prompt for authentication"
    fi
    
    # Build connection test command
    build_pg_command "psql" "-c" "SELECT version();" "-t"
    
    [[ "$DEBUG_MODE" == true ]] && { echo >&2 "🧪 Executing connection test:"; debug_command "${PG_CMD[@]}"; }
    
    # Test connection with timeout
    local result
    if run_pg_command_timeout 10 "${PG_CMD[@]}" >/dev/null 2>&1; then
        echo "   ✅ Connection successful to $database@$host:$port"
        result=0
    else
        echo "   ❌ Connection failed to $database@$host:$port"
        result=1
    fi
    
    return $result
}

# Get database information
info_database() {
    local project_name="${1:-}"
    local show_tables=false
    local show_size=false
    
    [[ $# -gt 0 ]] && shift # Drop project name
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tables)
                show_tables=true
                shift
                ;;
            --size)
                show_size=true
                shift
                ;;
            *)
                echo "⚠️ Unknown option: $1"
                shift
                ;;
        esac
    done
    
    [[ -z "$project_name" ]] && error_exit "❌ 'info' action requires <project>"
    
    local config username password port database host ssl_mode cert_path
    config=$(get_project_config "$project_name")
    parse_config "$config"
    
    [[ "$DEBUG_MODE" == true ]] && {
        echo >&2 "🧪 info_database() project_name='$project_name'"
        echo >&2 "🧪 Parsed config: user='$username', port='$port', db='$database', host='$host', ssl='$ssl_mode'"
    }
    
    echo "📊 Database Information for project '$project_name':"
    echo "   🏷️  Database: $database"
    echo "   🌐 Host: $host:$port"
    echo "   👤 User: $username"
    echo "   🔒 SSL: ${ssl_mode:-none}"
    echo
    
    # Check for .pgpass first (most secure)
    if check_pgpass; then
        password=""
        echo "🔐 Using .pgpass for authentication"
    elif [[ -n "$password" ]]; then
        echo "🔑 Using password from configuration"
    else
        echo "🔍 No password found - will prompt for authentication"
    fi
    
    # Get basic database info
    echo "📋 Basic Information:"
    
    # PostgreSQL version
    local version
    build_pg_command "psql" "-c" "SELECT version();" "-t"
    if ! version=$(run_pg_command "${PG_CMD[@]}" 2>/dev/null | head -1 | xargs); then
        version=""
    fi
    if [[ -n "$version" ]]; then
        echo "   📦 Version: $version"
    else
        echo "   ❌ Could not retrieve version (connection failed)"
        return 1
    fi
    
    # Database size
    local db_size
    build_pg_command "psql" "-c" "SELECT pg_size_pretty(pg_database_size(current_database()));" "-t"
    if ! db_size=$(run_pg_command "${PG_CMD[@]}" 2>/dev/null | head -1 | xargs); then
        db_size=""
    fi
    if [[ -n "$db_size" ]]; then
        echo "   💾 Database Size: $db_size"
    fi
    
    # Connection count
    local connections
    build_pg_command "psql" "-c" "SELECT count(*) FROM pg_stat_activity;" "-t"
    if ! connections=$(run_pg_command "${PG_CMD[@]}" 2>/dev/null | head -1 | xargs); then
        connections=""
    fi
    if [[ -n "$connections" ]]; then
        echo "   🔗 Active Connections: $connections"
    fi
    
    # Table count
    local table_count
    build_pg_command "psql" "-c" "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" "-t"
    if ! table_count=$(run_pg_command "${PG_CMD[@]}" 2>/dev/null | head -1 | xargs); then
        table_count=""
    fi
    if [[ -n "$table_count" ]]; then
        echo "   📋 Tables: $table_count"
    fi
    
    # Show tables if requested
    if [[ "$show_tables" == true ]]; then
        echo
        echo "📋 Tables in database '$database':"
        build_pg_command "psql" "-c" "SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;"
        run_pg_command "${PG_CMD[@]}" 2>/dev/null || echo "   ❌ Could not retrieve table list"
    fi
    
    # Show size details if requested
    if [[ "$show_size" == true ]]; then
        echo
        echo "💾 Size Details:"
        build_pg_command "psql" "-c" "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;"
        run_pg_command "${PG_CMD[@]}" 2>/dev/null || echo "   ❌ Could not retrieve size details"
    fi
}

# Configuration management functions
init_config() {
    local template_file="$SCRIPT_DIR/.dbmrc.template"
    
    if [[ -f "$PROJECT_CONFIG_FILE" ]]; then
        echo "⚠️  Config file already exists: $PROJECT_CONFIG_FILE"
        echo "   Use 'dbm config add <project> <config>' to add new projects"
        echo "   Or remove the existing file first if you want to start fresh"
        return 0
    fi
    
    if [[ ! -f "$template_file" ]]; then
        echo "❌ Template file not found: $template_file"
        echo "   Creating a basic config file instead..."
        echo "# DBM Configuration File" > "$PROJECT_CONFIG_FILE"
        echo "# Format: project_name=user:password:port:database[:host[:ssl[:cert]]]" >> "$PROJECT_CONFIG_FILE"
        echo "# Example: mydb=myuser:mypass:5432:mydatabase" >> "$PROJECT_CONFIG_FILE"
        echo >> "$PROJECT_CONFIG_FILE"
        echo "✅ Created basic config file: $PROJECT_CONFIG_FILE"
        echo "📝 Please edit it with your database credentials"
        return 0
    fi
    
    echo "🚀 Initializing DBM configuration..."
    echo "   Template: $template_file"
    echo "   Config:   $PROJECT_CONFIG_FILE"
    echo
    
    if [[ -t 0 ]]; then  # Interactive mode
        read -p "Create config file from template? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "❌ Initialization cancelled"
            return 1
        fi
    fi
    
    cp "$template_file" "$PROJECT_CONFIG_FILE"
    echo "✅ Created $PROJECT_CONFIG_FILE from template"
    echo
    echo "📝 Next steps:"
    echo "   1. Edit the config file: nano $PROJECT_CONFIG_FILE"
    echo "   2. Replace template values with your actual database credentials"
    echo "   3. Test connection: dbm check <project_name>"
    echo "   4. List projects: dbm list"
    echo
    echo "💡 Tip: Use 'dbm config add <name> <config>' to add projects via command line"
}

config_add() {
    local project_name="${1:-}"
    local config_string="${2:-}"
    
    [[ -z "$project_name" ]] && error_exit "❌ 'config add' requires <project_name> <config_string>"
    [[ -z "$config_string" ]] && error_exit "❌ 'config add' requires <project_name> <config_string>"
    validate_project_name "$project_name"
    
    # Validate config string format
    if ! validate_config_string "$config_string"; then
        error_exit "❌ Invalid config format. Expected: user:password:port:db[:host[:ssl[:cert]]] or postgres://..."
    fi
    
    # Check if project already exists
    if project_config_exists "$project_name"; then
        local existing_config
        existing_config="$(read_project_config_value "$project_name")"
        echo "⚠️  Project '$project_name' already exists with config: $(mask_config "$existing_config")"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Operation cancelled"
            return 1
        fi
    fi
    
    # Add to config file
    if [[ ! -f "$PROJECT_CONFIG_FILE" ]]; then
        echo "# DBM Configuration File" > "$PROJECT_CONFIG_FILE"
        echo "# Format: project_name=user:password:port:database[:host[:ssl[:cert]]]" >> "$PROJECT_CONFIG_FILE"
        echo >> "$PROJECT_CONFIG_FILE"
    fi
    
    # Remove existing entry if it exists
    if project_config_exists "$project_name"; then
        remove_project_config_entry "$project_name"
    fi
    
    # Add new entry with proper newline
    echo >> "$PROJECT_CONFIG_FILE"  # Ensure there's a newline before our entry
    echo "$project_name=$config_string" >> "$PROJECT_CONFIG_FILE"
    
    echo "✅ Added project '$project_name' to configuration"
    echo "   Config: $(mask_config "$config_string")"
}

config_remove() {
    local project_name="${1:-}"
    
    [[ -z "$project_name" ]] && error_exit "❌ 'config remove' requires <project_name>"
    validate_project_name "$project_name"
    
    if [[ ! -f "$PROJECT_CONFIG_FILE" ]]; then
        error_exit "❌ Config file not found: $PROJECT_CONFIG_FILE"
    fi
    
    # Check if project exists
    if ! project_config_exists "$project_name"; then
        error_exit "❌ Project '$project_name' not found in configuration"
    fi
    
    # Show current config
    local current_config
    current_config="$(read_project_config_value "$project_name")"
    echo "⚠️  About to remove project '$project_name' with config: $(mask_config "$current_config")"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Operation cancelled"
        return 1
    fi
    
    # Remove the entry
    remove_project_config_entry "$project_name"
    
    echo "✅ Removed project '$project_name' from configuration"
}

config_edit() {
    local project_name="${1:-}"
    
    [[ -z "$project_name" ]] && error_exit "❌ 'config edit' requires <project_name>"
    validate_project_name "$project_name"
    
    if [[ ! -f "$PROJECT_CONFIG_FILE" ]]; then
        error_exit "❌ Config file not found: $PROJECT_CONFIG_FILE"
    fi
    
    # Check if project exists
    if ! project_config_exists "$project_name"; then
        error_exit "❌ Project '$project_name' not found in configuration"
    fi
    
    # Show current config
    local current_config
    current_config="$(read_project_config_value "$project_name")"
    echo "📋 Current config for '$project_name': $(mask_config "$current_config")"
    echo
    echo "📝 Enter new configuration (or press Enter to cancel):"
    echo "   Formats: user:password:port:db[:host[:ssl[:cert]]]"
    echo "           postgres://user:pass@host:port/db?sslmode=require"
    echo
    read -p "New config: " -r new_config
    
    if [[ -z "$new_config" ]]; then
        echo "❌ Operation cancelled"
        return 1
    fi
    
    # Validate new config
    if ! validate_config_string "$new_config"; then
        error_exit "❌ Invalid config format"
    fi
    
    # Update the config
    remove_project_config_entry "$project_name"
    echo "$project_name=$new_config" >> "$PROJECT_CONFIG_FILE"
    
    echo "✅ Updated project '$project_name' configuration"
    echo "   New config: $(mask_config "$new_config")"
}

# Configuration management dispatcher
config_management() {
    local action="${1:-}"
    shift
    
    case "$action" in
        add)
            config_add "$@"
            ;;
        remove | rm)
            config_remove "$@"
            ;;
        edit)
            config_edit "$@"
            ;;
        *)
            error_exit "❌ Invalid config action '$action'. Use: add, remove, edit"
            ;;
    esac
}

# Main dispatcher function. Named dbm intentionally so sourcing the script exposes the same command name.
dbm() {
    if [[ $# -lt 1 ]]; then
        show_help
        error_exit "❌ No action provided"
    fi

    [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && show_help

    load_project_configs
    
    local action="$1"
    shift
    
    case "$action" in
        reset | r | -r)
            [[ $# -lt 2 ]] && error_exit "❌ 'reset' action requires <project> and <sql file>"
            reset_database "$@"
            ;;
        backup | b | -b)
            [[ $# -lt 1 ]] && error_exit "❌ 'backup' action requires <project> [file_path] [-o]"
            backup_database "$@"
            ;;
        start | s | -s)
            [[ $# -lt 1 ]] && error_exit "❌ 'start' action requires <project>"
            local project_name="$1"
            start_database "$project_name"
            ;;
        list | l | -l)
            list_projects
            ;;
        check | c | -c)
            check_database "$@"
            ;;
        info | i | -i)
            info_database "$@"
            ;;
        config)
            [[ $# -lt 1 ]] && error_exit "❌ 'config' action requires subcommand: add, remove, edit"
            config_management "$@"
            ;;
        init)
            init_config
            ;;
        *)
            error_exit "❌ Invalid action '$action'. Use -h for help."
            ;;
    esac
}

# Run main function with all script args
dbm "$@"
