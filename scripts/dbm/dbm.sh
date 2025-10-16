#!/bin/bash

# Location of the external config file (relative to script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_CONFIG_FILE="$SCRIPT_DIR/.dbmrc"
DEBUG_MODE=false # Set to true to enable debug logs

# Supported config formats:
# Format 1: user:port:database (password via PGPASSWORD env var)
# Format 2: user:password:port:database (password in config - less secure)
# Format 3: user:port:database:host (custom host)
# Format 4: user:password:port:database:host (full config)
# Format 5: connection_string (full PostgreSQL connection URI)
# Format 6: user:port:database:host:ssl_mode (with SSL configuration)
# Format 7: user:port:database:host:ssl_mode:cert_path (with client certificates)

# Error handling
error_exit() {
    echo "🚨 Error: $1" >&2
    exit 1
}

# Check if debug is enabled at the start
if [[ "$1" == "--debug" ]]; then
    DEBUG_MODE=true
    shift
fi

# Load projects config from file into associative array
declare -A PROJECT_CONFIGS=()

load_project_configs() {
    if [[ -f "$PROJECT_CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            # Ignore empty lines and comments
            [[ -z "$key" || "$key" =~ ^\s*# ]] && continue
            
            # Validate format - support multiple formats including URIs and legacy format
            if ! [[ "$value" =~ ^[^:]+:[^:]*:[0-9]+:[^:]+(:.*)*$ ]] && ! [[ "$value" =~ ^[^:]+:[0-9]+:[^:]+$ ]] && ! [[ "$value" =~ ^postgres(ql)?:// ]]; then
                echo "⚠️  Skipping invalid config line: $key=$value"
                echo "   Expected formats: user:password:port:db[:host[:ssl[:cert]]], user:port:db (legacy), or postgres://..."
                continue
            fi
            
            PROJECT_CONFIGS["$key"]="$value"
        done <"$PROJECT_CONFIG_FILE"
    else
        echo "⚠️  Config file $PROJECT_CONFIG_FILE not found — will fallback to environment variables."
    fi
}

# Try to get project config: first from file, then from environment variables
get_project_config() {
    local project_name="$1"
    [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 get_project_config called with project_name: '$project_name'"
    
    local config="${PROJECT_CONFIGS[$project_name]}"
    [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 PROJECT_CONFIGS[$project_name] = '$config'"
    
    if [[ -z "$config" ]]; then
        local p_upper
        p_upper=$(echo "$project_name" | tr '[:lower:]' '[:upper:]')
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Looking for env vars using prefix: '$p_upper'"
        
        local user_var="${p_upper}_USER"
        local password_var="${p_upper}_PASSWORD"
        local port_var="${p_upper}_PORT"
        local db_var="${p_upper}_DB"
        local host_var="${p_upper}_HOST"
        
        local user="${!user_var}"
        local password="${!password_var}"
        local port="${!port_var}"
        local db="${!db_var}"
        local host="${!host_var:-localhost}"
        
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Values found: $user_var=$user, $password_var=[HIDDEN], $port_var=$port, $db_var=$db, $host_var=$host"
        
        if [[ -n "$user" && -n "$port" && -n "$db" ]]; then
            config="$user:$password:$port:$db:$host"
            [[ "$DEBUG_MODE" == true ]] && echo >&2 "✅ Final fallback config: $user:[HIDDEN]:$port:$db:$host"
        else
            error_exit "🔍 Missing config for '$project_name'. Define it in env or $PROJECT_CONFIG_FILE"
        fi
    else
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "✅ Loaded config from file: $config"
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
    Format 1: user::port:database (password via PGPASSWORD env var)
    Format 2: user:password:port:database (password in config)
    Format 3: user:password:port:database:host (custom host)
    Format 4: user:password:port:database:host:sslmode (with SSL)
    Format 5: user:password:port:database:host:sslmode:cert_path (with client cert)
    Format 6: postgres://user:pass@host:port/db?sslmode=require (full URI)
    Format 7: postgres://user:pass@host:port/db?sslmode=require&sslcert=/path/cert (URI with SSL cert)
    Format 8: postgres://username%40server:password@server.postgres.database.azure.com:5432/database?sslmode=require (Azure PostgreSQL)
  
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
            password="${parts[0]}"  # Use username as password for legacy compatibility
            port="${parts[1]}"
            database="${parts[2]}"
            host="localhost"
            ssl_mode=""
            cert_path=""
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
        if [[ -n "$PGPASSWORD" ]]; then
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
    local user_pass_host_port_db="${uri%%\?*}"
    local query_params="${uri#*\?}"
    
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

# Build PostgreSQL connection command with all options
build_psql_command() {
    local base_cmd="$1"  # psql or pg_dump
    local extra_args="$2"  # Additional arguments like -f for psql or --clean for pg_dump
    
    local cmd="$base_cmd"
    
    # Add user
    [[ -n "$username" ]] && cmd="$cmd -U $username"
    
    # Add database
    [[ -n "$database" ]] && cmd="$cmd -d $database"
    
    # Add host (always add -h to force TCP/IP connections)
    [[ -n "$host" ]] && cmd="$cmd -h $host"
    
    # Add port
    [[ -n "$port" ]] && cmd="$cmd -p $port"
    
    # Add SSL mode
    if [[ -n "$ssl_mode" ]]; then
        case "$ssl_mode" in
            "disable"|"allow"|"prefer"|"require"|"verify-ca"|"verify-full")
                cmd="$cmd --set=sslmode=$ssl_mode"
                ;;
            *)
                echo "⚠️  Warning: Invalid SSL mode '$ssl_mode', using default" >&2
                ;;
        esac
    fi
    
    # Add client certificate path
    if [[ -n "$cert_path" ]]; then
        if [[ -f "$cert_path" ]]; then
            cmd="$cmd --set=sslcert=$cert_path"
        else
            echo "⚠️  Warning: SSL certificate file not found: $cert_path" >&2
        fi
    fi
    
    # Add extra arguments
    [[ -n "$extra_args" ]] && cmd="$cmd $extra_args"
    
    echo "$cmd"
}

# Check for .pgpass file and use it if available
check_pgpass() {
    local pgpass_file="$HOME/.pgpass"
    
    if [[ -f "$pgpass_file" ]]; then
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Found .pgpass file at $pgpass_file"
        
        # Check if there's a matching entry in .pgpass
        # Format: hostname:port:database:username:password
        if grep -q "^$host:$port:$database:$username:" "$pgpass_file" 2>/dev/null; then
            [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Found matching .pgpass entry"
            return 0
        fi
    fi
    
    return 1
}

# Reset database
reset_database() {
    local project_name="$1"
    local file_path="$2"
    
    [[ -z "$file_path" ]] && error_exit "📂 Reset requires a SQL file path."
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
    local use_pgpass=false
    if check_pgpass; then
        use_pgpass=true
        echo "🔐 Using .pgpass for authentication"
    elif [[ -n "$password" ]]; then
        export PGPASSWORD="$password"
        echo "🔑 Using password from configuration"
    else
        echo "🔍 No password found - will prompt for authentication"
    fi
    
    # Build and execute the command
    local psql_cmd
    psql_cmd=$(build_psql_command "psql" "-f $file_path")
    
    [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Executing: $psql_cmd"
    
    eval "$psql_cmd"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Database reset successfully for $project_name"
    else
        error_exit "❌ Failed to reset database for $project_name"
    fi
    
    # Clean up password from environment if we set it
    if [[ "$use_pgpass" == false && -n "$password" ]]; then
        unset PGPASSWORD
    fi
}

# Backup database
backup_database() {
    local project_name="$1"
    local file_path=""
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
    local use_pgpass=false
    if check_pgpass; then
        use_pgpass=true
        echo "🔐 Using .pgpass for authentication"
    elif [[ -n "$password" ]]; then
        export PGPASSWORD="$password"
        echo "🔑 Using password from configuration"
    else
        echo "🔍 No password found - will prompt for authentication"
    fi
    
    # Build and execute the command
    local pg_dump_cmd
    pg_dump_cmd=$(build_psql_command "pg_dump" "--clean")
    
    [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Executing: $pg_dump_cmd > $file_path"
    
    eval "$pg_dump_cmd" >"$file_path"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Database backed up successfully to $file_path"
    else
        error_exit "❌ Failed to backup database for $project_name"
    fi
    
    # Clean up password from environment if we set it
    if [[ "$use_pgpass" == false && -n "$password" ]]; then
        unset PGPASSWORD
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
    local use_pgpass=false
    if check_pgpass; then
        use_pgpass=true
        echo "🔐 Using .pgpass for authentication"
    elif [[ -n "$password" ]]; then
        export PGPASSWORD="$password"
        echo "🔑 Using password from configuration"
    else
        echo "🔍 No password found - will prompt for authentication"
    fi
    
    # Build and execute the command
    local psql_cmd
    psql_cmd=$(build_psql_command "psql" "")
    
    [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Executing: $psql_cmd"
    
    eval "$psql_cmd"
    
    # Clean up password from environment if we set it
    if [[ "$use_pgpass" == false && -n "$password" ]]; then
        unset PGPASSWORD
    fi
}

# List projects available in config file
list_projects() {
    if [[ ${#PROJECT_CONFIGS[@]} -eq 0 ]]; then
        echo "ℹ️  No projects loaded from $PROJECT_CONFIG_FILE"
    else
        echo 
        echo "📚 Projects from $PROJECT_CONFIG_FILE:"
        for key in "${!PROJECT_CONFIGS[@]}"; do
            echo " - $key -> ${PROJECT_CONFIGS[$key]}"
        done
    fi
    
    echo
    echo "⚠️  You can also define projects by setting environment variables:"
    echo "    <PROJECT>_USER, <PROJECT>_PASSWORD, <PROJECT>_PORT, <PROJECT>_DB, <PROJECT>_HOST"
    echo "    (HOST defaults to localhost if not specified)"
}

# Check database connection
check_database() {
    local project_name="$1"
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
            ((total++))
            echo "📋 Checking project: $project"
            
            if check_single_database "$project"; then
                ((success++))
            else
                ((failed++))
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
    local use_pgpass=false
    if check_pgpass; then
        use_pgpass=true
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Using .pgpass for authentication"
    elif [[ -n "$password" ]]; then
        export PGPASSWORD="$password"
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Using password from configuration"
    else
        [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 No password found - will prompt for authentication"
    fi
    
    # Build connection test command
    local psql_cmd
    psql_cmd=$(build_psql_command "psql" "-c 'SELECT version();' -t")
    
    [[ "$DEBUG_MODE" == true ]] && echo >&2 "🧪 Executing connection test: $psql_cmd"
    
    # Test connection with timeout
    local result
    if timeout 10 bash -c "$psql_cmd" >/dev/null 2>&1; then
        echo "   ✅ Connection successful to $database@$host:$port"
        result=0
    else
        echo "   ❌ Connection failed to $database@$host:$port"
        result=1
    fi
    
    # Clean up password from environment if we set it
    if [[ "$use_pgpass" == false && -n "$password" ]]; then
        unset PGPASSWORD
    fi
    
    return $result
}

# Get database information
info_database() {
    local project_name="$1"
    local show_tables=false
    local show_size=false
    
    shift # Drop project name
    
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
    local use_pgpass=false
    if check_pgpass; then
        use_pgpass=true
        echo "🔐 Using .pgpass for authentication"
    elif [[ -n "$password" ]]; then
        export PGPASSWORD="$password"
        echo "🔑 Using password from configuration"
    else
        echo "🔍 No password found - will prompt for authentication"
    fi
    
    # Get basic database info
    echo "📋 Basic Information:"
    
    # PostgreSQL version
    local version_cmd
    version_cmd=$(build_psql_command "psql" "-c 'SELECT version();' -t")
    local version
    version=$(eval "$version_cmd" 2>/dev/null | head -1 | xargs)
    if [[ -n "$version" ]]; then
        echo "   📦 Version: $version"
    else
        echo "   ❌ Could not retrieve version (connection failed)"
        return 1
    fi
    
    # Database size
    local size_cmd
    size_cmd=$(build_psql_command "psql" "-c \"SELECT pg_size_pretty(pg_database_size('$database'));\" -t")
    local db_size
    db_size=$(eval "$size_cmd" 2>/dev/null | head -1 | xargs)
    if [[ -n "$db_size" ]]; then
        echo "   💾 Database Size: $db_size"
    fi
    
    # Connection count
    local conn_cmd
    conn_cmd=$(build_psql_command "psql" "-c 'SELECT count(*) FROM pg_stat_activity;' -t")
    local connections
    connections=$(eval "$conn_cmd" 2>/dev/null | head -1 | xargs)
    if [[ -n "$connections" ]]; then
        echo "   🔗 Active Connections: $connections"
    fi
    
    # Table count
    local table_cmd
    table_cmd=$(build_psql_command "psql" "-c \"SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';\" -t")
    local table_count
    table_count=$(eval "$table_cmd" 2>/dev/null | head -1 | xargs)
    if [[ -n "$table_count" ]]; then
        echo "   📋 Tables: $table_count"
    fi
    
    # Show tables if requested
    if [[ "$show_tables" == true ]]; then
        echo
        echo "📋 Tables in database '$database':"
        local tables_cmd
        tables_cmd=$(build_psql_command "psql" "-c \"SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;\"")
        eval "$tables_cmd" 2>/dev/null || echo "   ❌ Could not retrieve table list"
    fi
    
    # Show size details if requested
    if [[ "$show_size" == true ]]; then
        echo
        echo "💾 Size Details:"
        local size_details_cmd
        size_details_cmd=$(build_psql_command "psql" "-c \"SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;\"")
        eval "$size_details_cmd" 2>/dev/null || echo "   ❌ Could not retrieve size details"
    fi
    
    # Clean up password from environment if we set it
    if [[ "$use_pgpass" == false && -n "$password" ]]; then
        unset PGPASSWORD
    fi
}

# Configuration management functions
config_add() {
    local project_name="$1"
    local config_string="$2"
    
    [[ -z "$project_name" ]] && error_exit "❌ 'config add' requires <project_name> <config_string>"
    [[ -z "$config_string" ]] && error_exit "❌ 'config add' requires <project_name> <config_string>"
    
    # Validate config string format
    if ! [[ "$config_string" =~ ^[^:]+:[^:]*:[0-9]+:[^:]+(:.*)*$ ]] && ! [[ "$config_string" =~ ^postgres(ql)?:// ]]; then
        error_exit "❌ Invalid config format. Expected: user:password:port:db[:host[:ssl[:cert]]] or postgres://..."
    fi
    
    # Check if project already exists
    if [[ -n "${PROJECT_CONFIGS[$project_name]}" ]]; then
        echo "⚠️  Project '$project_name' already exists with config: ${PROJECT_CONFIGS[$project_name]}"
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
    if grep -q "^$project_name=" "$PROJECT_CONFIG_FILE" 2>/dev/null; then
        sed -i "/^$project_name=/d" "$PROJECT_CONFIG_FILE"
    fi
    
    # Add new entry with proper newline
    echo >> "$PROJECT_CONFIG_FILE"  # Ensure there's a newline before our entry
    echo "$project_name=$config_string" >> "$PROJECT_CONFIG_FILE"
    
    echo "✅ Added project '$project_name' to configuration"
    echo "   Config: $config_string"
}

config_remove() {
    local project_name="$1"
    
    [[ -z "$project_name" ]] && error_exit "❌ 'config remove' requires <project_name>"
    
    if [[ ! -f "$PROJECT_CONFIG_FILE" ]]; then
        error_exit "❌ Config file not found: $PROJECT_CONFIG_FILE"
    fi
    
    # Check if project exists
    if ! grep -q "^$project_name=" "$PROJECT_CONFIG_FILE" 2>/dev/null; then
        error_exit "❌ Project '$project_name' not found in configuration"
    fi
    
    # Show current config
    local current_config
    current_config=$(grep "^$project_name=" "$PROJECT_CONFIG_FILE" | cut -d'=' -f2-)
    echo "⚠️  About to remove project '$project_name' with config: $current_config"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Operation cancelled"
        return 1
    fi
    
    # Remove the entry
    sed -i "/^$project_name=/d" "$PROJECT_CONFIG_FILE"
    
    echo "✅ Removed project '$project_name' from configuration"
}

config_edit() {
    local project_name="$1"
    
    [[ -z "$project_name" ]] && error_exit "❌ 'config edit' requires <project_name>"
    
    if [[ ! -f "$PROJECT_CONFIG_FILE" ]]; then
        error_exit "❌ Config file not found: $PROJECT_CONFIG_FILE"
    fi
    
    # Check if project exists
    if ! grep -q "^$project_name=" "$PROJECT_CONFIG_FILE" 2>/dev/null; then
        error_exit "❌ Project '$project_name' not found in configuration"
    fi
    
    # Show current config
    local current_config
    current_config=$(grep "^$project_name=" "$PROJECT_CONFIG_FILE" | cut -d'=' -f2-)
    echo "📋 Current config for '$project_name': $current_config"
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
    if ! [[ "$new_config" =~ ^[^:]+:[^:]*:[0-9]+:[^:]+(:.*)*$ ]] && ! [[ "$new_config" =~ ^postgres(ql)?:// ]]; then
        error_exit "❌ Invalid config format"
    fi
    
    # Update the config
    sed -i "s|^$project_name=.*|$project_name=$new_config|" "$PROJECT_CONFIG_FILE"
    
    echo "✅ Updated project '$project_name' configuration"
    echo "   New config: $new_config"
}

# Configuration management dispatcher
config_management() {
    local action="$1"
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

# Main dispatcher function
dbm() {
    load_project_configs
    
    [[ "$1" == "-h" || "$1" == "--help" ]] && show_help
    
    if [[ $# -lt 1 ]]; then
        show_help
        error_exit "❌ No action provided"
    fi
    
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
        *)
            error_exit "❌ Invalid action '$action'. Use -h for help."
            ;;
    esac
}

# Run main function with all script args
dbm "$@"