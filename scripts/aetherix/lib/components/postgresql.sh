#!/bin/bash

# PostgreSQL Component - Installation and configuration

# Configure PostgreSQL
configure_postgresql() {
    add_selection "psql"

    ui_info "📜 Select the desired version:"
    PSQL_VERSION=$(gum choose "14" "13" "12" "11")
    PSQL_VERSION=${PSQL_VERSION:-14}
    gum style --foreground 3 "   └── • Version selected: $PSQL_VERSION"

    PSQL_DOCKER=$(gum confirm "Run PostgreSQL in Docker container?" && echo true || echo false)
    gum style --foreground 3 "   └── • Containerized: $([ "$PSQL_DOCKER" = true ] && echo Yes || echo No)"

    # If Docker is required but not selected, prompt to add it
    if [ "$PSQL_DOCKER" = true ] && ! is_selected "docker"; then
        if gum confirm "⚠️ Docker is required for containerized PostgreSQL. Add Docker to selections?"; then
            configure_docker
        else
            PSQL_DOCKER=false
            gum style --foreground 3 "   └── • Containerized: No (Docker not selected)"
        fi
    fi

    ui_info "📜 Please set your DB name and username:"
    DB_NAME=$(gum input --placeholder "Database name (default: devdb)" --value "devdb")
    DB_USER=$(gum input --placeholder "Database user (default: devuser)" --value "devuser")
    gum style --foreground 3 "   └── • DB: $DB_NAME, User: $DB_USER"

    if [ "$PSQL_DOCKER" = true ]; then
        while true; do
            DB_PORT=$(gum input --placeholder "Database port (default: 5432)" --value "5432")
            if validate_port "$DB_PORT"; then
                break
            else
                ui_warning "Please enter a valid port number (1-65535)."
            fi
        done
        gum style --foreground 3 "   └── • Port: $DB_PORT"
    fi
}

# Install PostgreSQL
install_postgresql() {
    print_section_title "🐘 Installing PostgreSQL"
    update_component_progress "PostgreSQL" "starting"

    # Check if PostgreSQL is already installed natively (when not using Docker)
    if is_installed psql && [ "$PSQL_DOCKER" = false ]; then
        ui_warning "PostgreSQL already installed natively. Skipping."
        update_component_progress "PostgreSQL" "skipped"
        print_success_box "PostgreSQL already installed"
        return 0
    fi

    ui_info "🐘 Installing PostgreSQL..."

    if [ "$DRY_RUN" = true ]; then
        if [ "$PSQL_DOCKER" = true ]; then
            ui_dry_run "Would create PostgreSQL Docker container"
        else
            ui_dry_run "Would install PostgreSQL $PSQL_VERSION natively"
        fi
        update_component_progress "PostgreSQL" "skipped"
        return 0
    fi

    if [ "$PSQL_DOCKER" = true ]; then
        install_postgresql_docker
    else
        install_postgresql_native
    fi
}

# Install PostgreSQL in Docker
install_postgresql_docker() {
    # Ensure Docker is installed
    if ! is_installed docker; then
        ui_error "Docker is required but not installed. Installing Docker first..."
        install_docker
    fi

    # Check if port is already in use
    if netstat -tuln 2>/dev/null | grep -q ":$DB_PORT "; then
        ui_error "Port $DB_PORT is already in use. Please choose a different port."
        update_component_progress "PostgreSQL" "failed"
        return 1
    fi

    # Check if the container already exists
    if docker ps -a --format '{{.Names}}' | grep -qw "postgres-$PSQL_VERSION"; then
        ui_warning "PostgreSQL Docker container postgres-$PSQL_VERSION already exists. Skipping container creation."
        update_component_progress "PostgreSQL" "skipped"
        return 0
    fi

    ui_info "🐳 Creating PostgreSQL container..."
    safe_spin "Creating PostgreSQL container..."
    
    if ! docker run --name postgres-$PSQL_VERSION \
        -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_USER=$DB_USER \
        -e POSTGRES_DB=$DB_NAME \
        -p $DB_PORT:5432 \
        -d postgres:$PSQL_VERSION; then
        ui_error "Failed to create PostgreSQL container (port $DB_PORT may be in use)"
        update_component_progress "PostgreSQL" "failed"
        return 1
    fi

    update_component_progress "PostgreSQL" "completed"
    print_success_box "PostgreSQL (Docker) installed successfully"
}

# Install PostgreSQL natively
install_postgresql_native() {
    if ! sudo apt install -y postgresql-$PSQL_VERSION; then
        ui_error "Failed to install PostgreSQL"
        update_component_progress "PostgreSQL" "failed"
        return 1
    fi

    # Configure the database user and database
    ui_info "⚙️  Configuring PostgreSQL database..."
    safe_spin "Configuring PostgreSQL..."
    
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD 'password';" || true
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" || true

    update_component_progress "PostgreSQL" "completed"
    print_success_box "PostgreSQL (Native) installed successfully"
}