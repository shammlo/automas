#!/bin/bash
#
# Description: Smart file and directory creator with auto-content, templates, and undo functionality
set -euo pipefail

# Colors and emojis for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
MAX_DEPTH=20
MIN_DISK_SPACE_MB=100
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/f-create"
BACKUP_DIR="$DATA_DIR/backups"
HISTORY_FILE="$DATA_DIR/history"

# Global variables
QUIET_MODE=false
VERBOSE_MODE=false
DRY_RUN=false
FORCE_TYPE=""
INITIAL_CONTENT=""
OPEN_EDITOR=false
SET_PERMISSIONS=""
UNDO_REQUESTED=false
BATCH_ID=""

# Known extensionless files
EXTENSIONLESS_FILES=("README" "LICENSE" "CHANGELOG" "Dockerfile" "Makefile" "Vagrantfile" "Gemfile" "Procfile")

# Function to print colored output with emojis
print_info() {
    [[ "$QUIET_MODE" == true ]] && return
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    [[ "$QUIET_MODE" == true ]] && return
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    [[ "$QUIET_MODE" == true ]] && return
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

print_verbose() {
    if [[ "$VERBOSE_MODE" == true ]] && [[ "$QUIET_MODE" == false ]]; then
        echo -e "${CYAN}🔍 $1${NC}"
    fi

    return 0
}

print_progress() {
    [[ "$QUIET_MODE" == true ]] && return 0
    echo -e "${PURPLE}⏳ $1${NC}"
}

# Function to prompt for confirmation
confirm() {
    local prompt="$1"
    local answer=""

    if [ ! -t 0 ]; then
        print_warning "Cannot prompt in a non-interactive shell."
        return 1
    fi

    read -r -p "$prompt (y/N): " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Function to shell-expand escaped content passed with --content
expand_content() {
    printf '%b' "$1"
}

# Function to create data directory for backups/history
ensure_data_dir() {
    mkdir -p "$DATA_DIR"
}

# Function to check path depth
check_path_depth() {
    local path="$1"
    local normalized="${path#/}"
    local depth=0

    [[ -z "$normalized" ]] && return 0

    IFS='/' read -r -a parts <<< "$normalized"
    for part in "${parts[@]}"; do
        [[ -n "$part" ]] && depth=$((depth + 1))
    done

    if [ "$depth" -gt "$MAX_DEPTH" ]; then
        print_error "Path exceeds max depth of $MAX_DEPTH levels: $path"
        return 1
    fi

    return 0
}

# Function to check available disk space
check_disk_space() {
    local target_path="$1"
    local check_path="$target_path"
    local available_kb
    local required_kb=$((MIN_DISK_SPACE_MB * 1024))

    while [ ! -e "$check_path" ] && [ "$check_path" != "." ] && [ "$check_path" != "/" ]; do
        check_path="$(dirname "$check_path")"
    done

    available_kb="$(df -Pk "$check_path" | awk 'NR==2 {print $4}')"

    if [[ -n "$available_kb" && "$available_kb" -lt "$required_kb" ]]; then
        print_error "Insufficient disk space: need at least ${MIN_DISK_SPACE_MB}MB available"
        return 1
    fi

    return 0
}

# Function to create directories step by step
create_directories() {
    local path="$1"
    local display_path="$path"
    local current_path=""
    local prefix=""
    local part
    local created_any=false
    local -a parts

    if [ -d "$path" ]; then
        print_info "Directory '$path' already exists 📁"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would create directory '$path' 📂"
        return 0
    fi

    if [[ "$path" == /* ]]; then
        prefix="/"
        current_path="/"
        path="${path#/}"
    fi

    IFS='/' read -r -a parts <<< "$path"
    for part in "${parts[@]}"; do
        [[ -z "$part" ]] && continue

        if [[ "$prefix" == "/" && "$current_path" == "/" ]]; then
            current_path="/$part"
        elif [[ -z "$current_path" ]]; then
            current_path="$part"
        else
            current_path="$current_path/$part"
        fi

        if [ ! -d "$current_path" ]; then
            if mkdir "$current_path"; then
                print_success "Created directory '$current_path' 📂"
                log_operation "CREATE_DIR" "$current_path"
                created_any=true
            elif [ -d "$current_path" ]; then
                print_info "Directory '$current_path' was created by another process 📁"
            else
                print_error "Failed to create directory '$current_path'"
                return 1
            fi
        fi
    done

    if [ "$created_any" = false ]; then
        print_info "Directory '$display_path' already exists 📁"
    fi
    
    return 0
}

# Function to create the file safely
create_file() {
    local filepath="$1"
    
    # Check if file already exists
    if [ -f "$filepath" ]; then
        print_warning "File '$filepath' already exists! 📄"
        
        if [ "$DRY_RUN" = true ]; then
            print_info "[DRY RUN] Would prompt for overwrite"
            return 0
        fi
        
        if ! confirm "Do you want to overwrite it?"; then
            print_info "File creation cancelled by user 🚫"
            return 0
        fi
        
        # Create backup before overwriting
        create_backup "$filepath"
    fi
    
    # Get default content
    local content=""
    if [ -n "$INITIAL_CONTENT" ]; then
        content="$INITIAL_CONTENT"
    else
        local extension="${filepath##*.}"
        case "$extension" in
            "sh"|"bash")
                content="#!/bin/bash"
                ;;
            "py")
                content="#!/usr/bin/env python3"
                ;;
            "js")
                content="// JavaScript file"
                ;;
            "md")
                content="# $(basename "$filepath" .md)"
                ;;
        esac
    fi
    
    # Create the file with content
    if [ "$DRY_RUN" = true ]; then
        if [ -n "$content" ]; then
            print_info "[DRY RUN] Would create file '$filepath' with content ($(expand_content "$content" | wc -l) lines) 📝"
        else
            print_info "[DRY RUN] Would create empty file '$filepath' 📝"
        fi
        return 0
    fi
    
    if [ -n "$content" ]; then
        if expand_content "$content" > "$filepath"; then
            print_success "Created file '$filepath' with content 📝"
            log_operation "CREATE_FILE" "$filepath"
        else
            print_error "Failed to create file '$filepath'"
            return 1
        fi
    else
        if touch "$filepath"; then
            print_success "Created empty file '$filepath' 📝"
            log_operation "CREATE_FILE" "$filepath"
        else
            print_error "Failed to create file '$filepath'"
            return 1
        fi
    fi
    
    # Set permissions if specified
    if [ -n "$SET_PERMISSIONS" ]; then
        if chmod "$SET_PERMISSIONS" "$filepath" 2>/dev/null; then
            print_info "Set permissions to $SET_PERMISSIONS"
        else
            print_warning "Failed to set permissions to $SET_PERMISSIONS"
        fi
    fi
    
    # Show file info
    if command -v ls &> /dev/null && [ "$VERBOSE_MODE" = true ]; then
        print_info "File details: $(ls -lh "$filepath" | awk '{print $1, $5, $6, $7, $8, $9}')"
    fi

    if [ "$OPEN_EDITOR" = true ]; then
        open_in_editor "$filepath"
    fi
    
    return 0
}

# Function to open a file in the user's editor
open_in_editor() {
    local filepath="$1"
    local editor="${EDITOR:-${VISUAL:-}}"

    if [ -z "$editor" ]; then
        print_warning "No EDITOR or VISUAL configured; skipping editor open."
        return 0
    fi

    print_info "Opening '$filepath' in editor: $editor"
    "$editor" "$filepath"
}

# Function to validate file path
validate_path() {
    local filepath="$1"
    
    check_path_depth "$filepath" || return 1
    check_disk_space "$filepath" || return 1

    if [[ "$filepath" =~ ^/ ]]; then
        print_warning "Absolute path detected. This will create files outside current directory."
        if [ "$DRY_RUN" = true ]; then
            print_info "[DRY RUN] Would require confirmation for absolute path."
            return 0
        fi

        if ! confirm "Are you sure you want to continue?"; then
            print_info "Operation cancelled by user 🚫"
            return 1
        fi
    fi

    if [[ "$filepath" =~ (^|/)\.\.(/|$) ]]; then
        print_warning "Parent directory traversal detected. This may create files outside the current tree."
        if [ "$DRY_RUN" = true ]; then
            print_info "[DRY RUN] Would require confirmation for parent directory traversal."
            return 0
        fi

        if ! confirm "Are you sure you want to continue?"; then
            print_info "Operation cancelled by user 🚫"
            return 1
        fi
    fi
    
    return 0
}

# Main function
create_path_and_file() {
    local filepath="$1"
    
    print_info "Starting creation process for: '$filepath' 🚀"
    
    # Validate the path first
    if ! validate_path "$filepath"; then
        return 1
    fi
    
    # Get the directory part of the path
    local directory
    local filename
    directory=$(dirname "$filepath")
    filename=$(basename "$filepath")
    
    # Check force type first
    if [ "$FORCE_TYPE" = "dir" ]; then
        print_info "Forced to treat as directory 📁"
        if ! create_directories "$filepath"; then
            print_error "Failed to create directory structure"
            return 1
        fi
        print_success "All done! Directory structure is ready! 🎉"
        return 0
    fi
    
    # Check if it's a file (has extension) or directory (ends with / or no extension after last /)
    if [[ "$filepath" == */ ]]; then
        print_info "Path ends with '/', treating as directory only 📁"
        # Create all directories including the last one
        if ! create_directories "$filepath"; then
            print_error "Failed to create directory structure"
            return 1
        fi
        print_success "All done! Directory structure is ready! 🎉"
        return 0
    elif [[ ! "$filename" == *.* ]]; then
        # Check if it's a known extensionless file
        local is_known_file=false
        for known_file in "${EXTENSIONLESS_FILES[@]}"; do
            if [[ "$filename" == "$known_file" ]]; then
                print_verbose "Detected known extensionless file: $filename"
                is_known_file=true
                break
            fi
        done
        
        if [ "$is_known_file" = true ] || [ "$FORCE_TYPE" = "file" ]; then
            print_info "Treating '$filename' as a file (known extensionless file or forced)"
            # Continue to file creation below
        else
            print_info "No extension detected, treating '$filename' as a directory 📁"
            # Create all directories including the last one
            if ! create_directories "$filepath"; then
                print_error "Failed to create directory structure"
                return 1
            fi
            print_success "All done! Directory structure is ready! 🎉"
            return 0
        fi
    fi
    
    # Create directories if needed (unless it's current directory)
    if [ "$directory" != "." ]; then
        print_info "Processing directory structure... 🏗️"
        if ! create_directories "$directory"; then
            print_error "Failed to create directory structure"
            return 1
        fi
    fi
    
    # Create the file
    print_info "Creating file... ✨"
    if ! create_file "$filepath"; then
        return 1
    fi
    
    print_success "All done! Your file structure is ready! 🎉"
    return 0
}

# Function to create backup of existing file
create_backup() {
    local filepath="$1"
    
    if [ ! -f "$filepath" ]; then
        return 0
    fi
    
    ensure_data_dir
    
    local timestamp
    local backup_name
    timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_name="${BACKUP_DIR}/$(basename "$filepath").backup.$timestamp"
    
    if cp "$filepath" "$backup_name" 2>/dev/null; then
        print_info "Backup created: $backup_name"
        return 0
    else
        print_warning "Failed to create backup for $filepath"
        return 1
    fi
}

# Function to log operation for undo
log_operation() {
    local operation="$1"
    local path="$2"
    local timestamp

    ensure_data_dir
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "$timestamp|$BATCH_ID|$operation|$path" >> "$HISTORY_FILE"
    print_verbose "Logged operation: $operation $path (batch: $BATCH_ID)"
}

# Function to log batch start
log_batch_start() {
    local timestamp
    local paths_count="$1"

    ensure_data_dir
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "$timestamp|$BATCH_ID|BATCH_START|$paths_count" >> "$HISTORY_FILE"
    print_verbose "Started batch $BATCH_ID with $paths_count paths"
}

# Function to log batch end
log_batch_end() {
    local timestamp
    local success_count="$1"
    local total_count="$2"

    ensure_data_dir
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "$timestamp|$BATCH_ID|BATCH_END|$success_count/$total_count" >> "$HISTORY_FILE"
    print_verbose "Ended batch $BATCH_ID: $success_count/$total_count successful"
}

# Function to undo last batch operation
undo_last_operation() {
    if [ ! -f "$HISTORY_FILE" ]; then
        print_error "No history file found. Nothing to undo."
        return 1
    fi
    
    # Find the last batch by looking for the most recent BATCH_END
    local last_batch_id=""
    local timestamp batch_id operation path line
    
    # Read the file in reverse to find the last completed batch
    if command -v tac >/dev/null 2>&1; then
        # Use tac if available (reverse cat)
        while IFS='|' read -r timestamp batch_id operation path; do
            if [ "$operation" = "BATCH_END" ]; then
                last_batch_id="$batch_id"
                break
            fi
        done < <(tac "$HISTORY_FILE")
    else
        # Fallback: read entire file and process in reverse order
        local lines=()
        while IFS= read -r line; do
            lines=("$line" "${lines[@]}")
        done < "$HISTORY_FILE"
        
        for line in "${lines[@]}"; do
            IFS='|' read -r timestamp batch_id operation path <<< "$line"

            if [ "$operation" = "BATCH_END" ]; then
                last_batch_id="$batch_id"
                break
            fi
        done
    fi
    
    if [ -z "$last_batch_id" ]; then
        print_error "No completed batch found. Nothing to undo."
        return 1
    fi
    
    print_info "Found last batch: $last_batch_id"
    
    # Collect all operations from this batch (in reverse order for proper undo)
    local operations_to_undo=()
    local batch_info=""
    
    if command -v tac >/dev/null 2>&1; then
        while IFS='|' read -r timestamp batch_id operation path; do
            if [ "$batch_id" = "$last_batch_id" ]; then
                if [ "$operation" = "BATCH_START" ]; then
                    batch_info="$path"
                    break
                elif [ "$operation" = "CREATE_FILE" ] || [ "$operation" = "CREATE_DIR" ]; then
                    operations_to_undo+=("$operation|$path")
                fi
            fi
        done < <(tac "$HISTORY_FILE")
    else
        # Fallback method
        local lines=()
        while IFS= read -r line; do
            lines=("$line" "${lines[@]}")
        done < "$HISTORY_FILE"
        
        for line in "${lines[@]}"; do
            IFS='|' read -r timestamp batch_id operation path <<< "$line"

            if [ "$batch_id" = "$last_batch_id" ]; then
                if [ "$operation" = "BATCH_START" ]; then
                    batch_info="$path"
                    break
                elif [ "$operation" = "CREATE_FILE" ] || [ "$operation" = "CREATE_DIR" ]; then
                    operations_to_undo+=("$operation|$path")
                fi
            fi
        done
    fi
    
    if [ ${#operations_to_undo[@]} -eq 0 ]; then
        print_warning "No operations found in batch $last_batch_id to undo."
        return 0
    fi
    
    print_info "Batch contains ${#operations_to_undo[@]} operations (originally $batch_info paths)"
    
    # Show what will be undone
    print_info "Operations to undo:"
    for op_info in "${operations_to_undo[@]}"; do
        IFS='|' read -r operation path <<< "$op_info"
        echo "  - $operation: $path"
    done
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would undo entire batch $last_batch_id"
        return 0
    fi
    
    if ! confirm "Do you want to undo this entire batch?"; then
        print_info "Undo cancelled by user 🚫"
        return 0
    fi
    
    # Perform undo operations
    local undo_success=0
    local undo_total=${#operations_to_undo[@]}
    
    for op_info in "${operations_to_undo[@]}"; do
        IFS='|' read -r operation path <<< "$op_info"
        
        print_progress "Undoing: $operation $path"
        
        case "$operation" in
            "CREATE_FILE")
                if [ -f "$path" ]; then
                    # Create backup before removing
                    if [ -d "$BACKUP_DIR" ]; then
                        local backup_name
                        timestamp=$(date +"%Y%m%d_%H%M%S")
                        backup_name="${BACKUP_DIR}/$(basename "$path").undo.$timestamp"
                        cp "$path" "$backup_name" 2>/dev/null && print_verbose "Backup created: $backup_name"
                    fi
                    
                    if rm "$path" 2>/dev/null; then
                        print_success "Removed file: $path"
                        undo_success=$((undo_success + 1))
                    else
                        print_error "Failed to remove file: $path"
                    fi
                else
                    print_warning "File not found: $path"
                    undo_success=$((undo_success + 1))  # Count as success since it's already gone
                fi
                ;;
            "CREATE_DIR")
                if [ -d "$path" ]; then
                    if rmdir "$path" 2>/dev/null; then
                        print_success "Removed directory: $path"
                        undo_success=$((undo_success + 1))
                    else
                        print_warning "Directory not empty or failed to remove: $path"
                        print_info "Use 'rm -rf $path' to force removal if needed"
                    fi
                else
                    print_warning "Directory not found: $path"
                    undo_success=$((undo_success + 1))  # Count as success since it's already gone
                fi
                ;;
        esac
    done
    
    # Remove all lines belonging to this batch from history
    local temp_file
    temp_file="$(mktemp)"
    trap 'rm -f "$temp_file"' ERR RETURN

    awk -F'|' -v batch_id="$last_batch_id" '$2 != batch_id' "$HISTORY_FILE" > "$temp_file"
    mv "$temp_file" "$HISTORY_FILE"
    trap - ERR RETURN
    
    print_success "Batch undo completed: $undo_success/$undo_total operations successful! 🎯"
    return 0
}

# Display help
show_help() {
    cat << 'EOF'
🚀 The Rocket - Enhanced File and Directory Creator

Usage: f-create [OPTIONS] <path1> [path2] [path3] ...

OPTIONS:
  -h, --help          Show this help message
  -q, --quiet         Quiet mode (no emojis/colors)
  -v, --verbose       Verbose mode (show detailed info)
  -n, --dry-run       Show what would be done without doing it
  -f, --file          Force treat as file (even without extension)
  -d, --dir           Force treat as directory (even with extension)
  -c, --content TEXT  Add initial content to files
  -e, --edit          Open file in editor after creation
  --chmod PERMS       Set file permissions (e.g., 755, 644)
  -u, --undo          Undo the last operation

EXAMPLES:
  # Basic usage
  f-create demo/demo.txt
  f-create demo/test/first                    # Creates folders
  f-create projects/backend/                  # Creates folders (ends with /)
  
  # Force type
  f-create README --file                      # Force as file
  f-create script.backup --dir               # Force as directory
  
  # With content and permissions
  f-create script.sh --content '#!/bin/bash\necho "Hello"' --chmod 755
  f-create index.html --edit                 # Open in editor after creation
  
  # Batch mode
  f-create file1.txt file2.js folder1/ folder2/
  
  # Dry run
  f-create complex/structure/file.txt --dry-run
  
  # Quiet/Verbose modes
  f-create file.txt --quiet
  f-create file.txt --verbose
  
  # Undo last operation
  f-create --undo

FEATURES:
  📁 Creates nested directories safely
  📝 Creates files with smart content detection
  📂 Auto-detects files vs folders intelligently
  🔧 Supports common extensionless files (README, Dockerfile, etc.)
  ⚠️  Warns about overwriting with backup creation
  🔒 Enhanced security and validation
  📊 Batch processing support
  🎯 Dry-run mode to preview changes
  🔍 Verbose and quiet modes
  ✨ Smart default content for common file types

EXTENSIONLESS FILES DETECTED AS FILES:
  README, LICENSE, CHANGELOG, Dockerfile, Makefile, Vagrantfile,
  Gemfile, Procfile

CONFIGURATION:
  Max path depth: 20 levels
  Min disk space: 100MB
  Backup directory: $XDG_DATA_HOME/f-create/backups or ~/.local/share/f-create/backups
  History file: $XDG_DATA_HOME/f-create/history or ~/.local/share/f-create/history

EOF
}

# Main script execution
main() {
    # Check arguments
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    local filepath
    
    # Parse arguments
    local paths=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --quiet|-q)
                QUIET_MODE=true
                shift
                ;;
            --verbose|-v)
                VERBOSE_MODE=true
                shift
                ;;
            --dry-run|-n)
                DRY_RUN=true
                shift
                ;;
            --file|-f)
                FORCE_TYPE="file"
                shift
                ;;
            --dir|-d)
                FORCE_TYPE="dir"
                shift
                ;;
            --content|-c)
                if [ $# -lt 2 ]; then
                    print_error "Missing value for $1"
                    exit 1
                fi
                INITIAL_CONTENT="$2"
                shift 2
                ;;
            --edit|-e)
                OPEN_EDITOR=true
                shift
                ;;
            --chmod)
                if [ $# -lt 2 ]; then
                    print_error "Missing value for $1"
                    exit 1
                fi
                SET_PERMISSIONS="$2"
                shift 2
                ;;
            --undo|-u)
                # Set flag to call undo after parsing all arguments
                UNDO_REQUESTED=true
                shift
                ;;
            --*)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                paths+=("$1")
                shift
                ;;
        esac
    done
    
    # Handle undo request after parsing all arguments
    if [ "$UNDO_REQUESTED" = true ]; then
        undo_last_operation
        exit $?
    fi
    
    # Check if we have any paths to process
    if [ ${#paths[@]} -eq 0 ]; then
        print_error "No paths specified!"
        echo ""
        show_help
        exit 1
    fi
    
    # Generate unique batch ID for this operation
    BATCH_ID="batch_$(date +%Y%m%d_%H%M%S)_$$"
    
    # Show mode information
    if [ "$DRY_RUN" = true ]; then
        print_info "🔍 DRY RUN MODE - No actual changes will be made"
    fi
    
    if [ "$VERBOSE_MODE" = true ]; then
        print_info "🔍 VERBOSE MODE - Showing detailed information"
    fi
    
    # Process paths
    local exit_code=0
    local success_count=0
    local total_count=${#paths[@]}
    
    # Log batch start (only if not dry run)
    if [ "$DRY_RUN" != true ]; then
        log_batch_start "$total_count"
    fi
    
    if [ ${#paths[@]} -gt 1 ]; then
        # Multiple paths - batch mode
        print_info "Batch mode: Processing $total_count paths... (batch: $BATCH_ID)"
        echo
        
        local item_index=0
        for filepath in "${paths[@]}"; do
            item_index=$((item_index + 1))
            print_info "[$item_index/$total_count] Processing: $filepath"
            
            if create_path_and_file "$filepath"; then
                success_count=$((success_count + 1))
            else
                print_error "Failed to process: $filepath"
                exit_code=1
            fi
            
            # Add separator between items (except last)
            if [ "$item_index" -lt "$total_count" ]; then
                echo
            fi
        done
        
        print_info "Batch completed: $success_count/$total_count successful"
    else
        # Single path (still treated as a batch for undo consistency)
        print_verbose "Single path mode (batch: $BATCH_ID)"
        if ! create_path_and_file "${paths[0]}"; then
            exit_code=1
        else
            success_count=1
        fi
    fi
    
    # Log batch end (only if not dry run)
    if [ "$DRY_RUN" != true ]; then
        log_batch_end "$success_count" "$total_count"
    fi
    
    # Final message
    if [ $exit_code -eq 0 ]; then
        print_success "Operation completed successfully! 🎯"
    else
        print_error "Operation completed with errors! 💥"
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@"
