#!/bin/bash
#
# Description: Simplified version of f-create with basic file and directory creation functionality

# Colors and emojis for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${RED}❌ $1${NC}"
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
                if mkdir "$current_path" 2>/dev/null; then
                    print_success "Created directory '$current_path' 📂"
                else
                    print_error "Failed to create directory '$current_path'"
                    return 1
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
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "File creation cancelled by user 🚫"
            return 0
        fi
    fi
    
    # Attempt to create the file
    if touch "$filepath" 2>/dev/null; then
        print_success "Created file '$filepath' 📝"
        
        # Show file info
        if command -v ls &> /dev/null; then
            print_info "File details: $(ls -lh "$filepath" | awk '{print $5, $6, $7, $8, $9}')"
        fi
    else
        print_error "Failed to create file '$filepath'"
        return 1
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
        print_info "No extension detected, treating '$filename' as a directory 📁"
        # Create all directories including the last one
        if ! create_directories "$filepath"; then
            print_error "Failed to create directory structure"
            return 1
        fi
        print_success "All done! Directory structure is ready! 🎉"
        return 0
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

# Display help
show_help() {
    echo "🧘‍♂️ The Zen Master - Simple File and Directory Creator"
    echo ""
    echo "Usage: create <filepath>"
    echo ""
    echo "Examples:"
    echo "  create demo/demo.txt                    # Creates file"
    echo "  create projects/production/alex/text.txt # Creates file"
    echo "  create deep/nested/structure/config.json # Creates file"
    echo "  create demo/test/first                   # Creates folders (no extension)"
    echo "  create projects/backend/                 # Creates folders (ends with /)"
    echo ""
    echo "Features:"
    echo "  📁 Creates nested directories safely"
    echo "  📝 Creates files with safety checks"
    echo "  📂 Auto-detects folders (no extension or ends with /)"
    echo "  ⚠️  Warns about overwriting existing files"
    echo "  🔒 Validates paths for security"
    echo ""
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
    
    # Smart argument handling based on how script is called
    if [ $# -eq 1 ]; then
        # Single argument - treat as filepath
        filepath="$1"
    elif [ $# -eq 2 ] && [ "$1" = "create" ]; then
        # Two arguments with "create" first - legacy format
        filepath="$2"
    else
        print_error "Invalid arguments!"
        echo ""
        show_help
        exit 1
    fi
    
    # Validate filepath is not empty
    if [ -z "$filepath" ]; then
        print_error "Filepath cannot be empty!"
        exit 1
    fi
    
    # Execute the main function
    if create_path_and_file "$filepath"; then
        print_success "Operation completed successfully! 🎯"
        exit 0
    else
        print_error "Operation failed! 💥"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"