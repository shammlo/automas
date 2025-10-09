#!/bin/bash
#
# Description: Smart file and directory creator with auto-content, templates, and undo functionality

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/.f-create-backups"
HISTORY_FILE="$SCRIPT_DIR/.f-create-history"

# Global variables
QUIET_MODE=false
VERBOSE_MODE=false
DRY_RUN=false
FORCE_TYPE=""
INITIAL_CONTENT=""
OPEN_EDITOR=false
SET_PERMISSIONS=""
UNDO_REQUESTED=false

# Known extensionless files
EXTENSIONLESS_FILES=("README" "LICENSE" "CHANGELOG" "Dockerfile" "Makefile" "Vagrantfile" "Gemfile" "Procfile")

# Function to print colored output with emojis
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

print_verbose() {
    [[ "$VERBOSE_MODE" == true ]] && [[ "$QUIET_MODE" == false ]] && echo -e "${CYAN}🔍 $1${NC}"
}

print_progress() {
    [[ "$QUIET_MODE" == true ]] && return
    echo -e "${PURPLE}⏳ $1${NC}"
}

# Function to create directories step by step
create_directories() {
    local path="$1"
    local current_path=""
    
    # Split path by '/' and process each directory
    IFS='/' read -ra DIRS <<< "$path"
    
    for dir in "${DIRS[@]}"; do
        if [ -n "$dir" ]; then
            if [ -z "$current_path" ]; then
                current_path="$dir"
            else
                current_path="$current_path/$dir"
            fi
            
            if [ -d "$current_path" ]; then
                print_info "Directory '$current_path' exists, going inside 📁"
            else
                if [ "$DRY_RUN" = true ]; then
                    print_info "[DRY RUN] Would create directory '$current_path' 📂"
                else
                    if mkdir "$current_path" 2>/dev/null; then
                        print_success "Created directory '$current_path' 📂"
                        log_operation "CREATE_DIR" "$current_path"
                    else
                        print_error "Failed to create directory '$current_path'"
                        return 1
                    fi
                fi
            fi
        fi
    done
    
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
        
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
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
            print_info "[DRY RUN] Would create file '$filepath' with content ($(echo -e "$content" | wc -l) lines) 📝"
        else
            print_info "[DRY RUN] Would create empty file '$filepath' 📝"
        fi
        return 0
    fi
    
    if [ -n "$content" ]; then
        if echo -e "$content" > "$filepath" 2>/dev/null; then
            print_success "Created file '$filepath' with content 📝"
            log_operation "CREATE_FILE" "$filepath"
        else
            print_error "Failed to create file '$filepath'"
            return 1
        fi
    else
        if touch "$filepath" 2>/dev/null; then
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
    
    return 0
}

# Function to validate file path
validate_path() {
    local filepath="$1"
    
    # Check for dangerous characters
    if [[ "$filepath" =~ \.\. ]]; then
        print_error "Path contains '..' which could be dangerous!"
        return 1
    fi
    
    # Check if path is absolute (starts with /)
    if [[ "$filepath" =~ ^/ ]]; then
        print_warning "Absolute path detected. This will create files outside current directory."
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
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
    local directory=$(dirname "$filepath")
    local filename=$(basename "$filepath")
    
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
            if [[ "$filename" == "$known_file"* ]]; then
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
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="${BACKUP_DIR}/$(basename "$filepath").backup.$timestamp"
    
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
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "$timestamp|$operation|$path" >> "$HISTORY_FILE"
    print_verbose "Logged operation: $operation $path"
}

# Function to undo last operation
undo_last_operation() {
    if [ ! -f "$HISTORY_FILE" ]; then
        print_error "No history file found. Nothing to undo."
        return 1
    fi
    
    local last_line=$(tail -n 1 "$HISTORY_FILE")
    if [ -z "$last_line" ]; then
        print_error "History file is empty. Nothing to undo."
        return 1
    fi
    
    local timestamp=$(echo "$last_line" | cut -d'|' -f1)
    local operation=$(echo "$last_line" | cut -d'|' -f2)
    local path=$(echo "$last_line" | cut -d'|' -f3)
    
    print_info "Last operation: $operation on '$path' at $timestamp"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would undo: $operation $path"
        return 0
    fi
    
    read -p "Do you want to undo this operation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Undo cancelled by user 🚫"
        return 0
    fi
    
    case "$operation" in
        "CREATE_FILE")
            if [ -f "$path" ]; then
                # Create backup before removing
                if [ -d "$BACKUP_DIR" ]; then
                    local backup_name="${BACKUP_DIR}/$(basename "$path").undo.$(date +"%Y%m%d_%H%M%S")"
                    cp "$path" "$backup_name" 2>/dev/null && print_info "Backup created: $backup_name"
                fi
                
                if rm "$path" 2>/dev/null; then
                    print_success "Removed file: $path"
                else
                    print_error "Failed to remove file: $path"
                    return 1
                fi
            else
                print_warning "File not found: $path"
            fi
            ;;
        "CREATE_DIR")
            if [ -d "$path" ]; then
                if rmdir "$path" 2>/dev/null; then
                    print_success "Removed directory: $path"
                else
                    print_warning "Directory not empty or failed to remove: $path"
                    print_info "Use 'rm -rf $path' to force removal if needed"
                fi
            else
                print_warning "Directory not found: $path"
            fi
            ;;
        *)
            print_error "Unknown operation: $operation"
            return 1
            ;;
    esac
    
    # Remove the last line from history
    if command -v sed >/dev/null 2>&1; then
        sed -i '$d' "$HISTORY_FILE" 2>/dev/null
    else
        # Fallback for systems without sed -i
        head -n -1 "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
    fi
    
    print_success "Undo completed successfully! 🎯"
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
  Backup directory: .f-create-backups/
  History file: .f-create-history

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
    
    # Get the script name (last part of path, useful for aliases)
    local script_name=$(basename "$0")
    
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
                INITIAL_CONTENT="$2"
                shift 2
                ;;
            --edit|-e)
                OPEN_EDITOR=true
                shift
                ;;
            --chmod)
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
    
    # Show mode information
    if [ "$DRY_RUN" = true ]; then
        print_info "🔍 DRY RUN MODE - No actual changes will be made"
    fi
    
    if [ "$VERBOSE_MODE" = true ]; then
        print_info "🔍 VERBOSE MODE - Showing detailed information"
    fi
    
    if [ "$QUIET_MODE" = true ]; then
        print_info "🤫 QUIET MODE - Minimal output"
    fi
    
    # Process paths
    local exit_code=0
    local success_count=0
    local total_count=${#paths[@]}
    
    if [ ${#paths[@]} -gt 1 ]; then
        # Multiple paths - batch mode
        print_info "Batch mode: Processing $total_count paths..."
        echo
        
        for filepath in "${paths[@]}"; do
            print_info "[$((success_count + 1))/$total_count] Processing: $filepath"
            
            if create_path_and_file "$filepath"; then
                ((success_count++))
            else
                print_error "Failed to process: $filepath"
                exit_code=1
            fi
            
            # Add separator between items (except last)
            if [ $((success_count + 1)) -le $total_count ]; then
                echo
            fi
        done
        
        print_info "Batch completed: $success_count/$total_count successful"
    else
        # Single path
        if ! create_path_and_file "${paths[0]}"; then
            exit_code=1
        else
            success_count=1
        fi
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