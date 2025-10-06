#!/bin/bash

# Script Navigator CLI
# Navigate and execute scripts organized in folders

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory (assumes this script is in the root of your repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}


print_banner() {
    cat << "EOF"
    █████╗  ██╗   ██╗████████╗ ██████╗ ███╗   ███╗ █████╗ ███████╗
    ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗████╗ ████║██╔══██╗██╔════╝
    ███████║██║   ██║   ██║   ██║   ██║██╔████╔██║███████║███████╗
    ██╔══██║██║   ██║   ██║   ██║   ██║██║╚██╔╝██║██╔══██║╚════██║
    ██║  ██║╚██████╔╝   ██║   ╚██████╔╝██║ ╚═╝ ██║██║  ██║███████║
    ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝
    
                    🚀 Automas Navigator 🚀
                ==============================
EOF
}

# Function to show header
show_header() {
    clear
    echo
    print_banner
    # print_color $CYAN "====================================================================="
    local user_name=$(get_user_display_name)
    echo
    print_color $GREEN "Welcome, $user_name 👋"
    echo
}




get_user_display_name() {
    local git_name
    git_name=$(git config --get user.name 2>/dev/null)

    if [[ -n "$git_name" ]]; then
        echo "$git_name"
    else
        echo "$(whoami)"
    fi
}

# Function to get available categories
get_categories() {
    find "$SCRIPT_DIR" -maxdepth 1 -type d -not -path "$SCRIPT_DIR" -not -name ".*" -not -name "node_modules" -not -name "__pycache__" | sort | while read -r dir; do
        basename "$dir"
    done
}

# Function to get scripts in a category
get_scripts() {
    local category=$1
    local category_path="$SCRIPT_DIR/$category"

    if [[ -d "$category_path" ]]; then
        find "$category_path" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.sql" -o -name "*.ts" -o -name "*.js" \) | sort | while read -r script; do
            # Get relative path from category directory
            echo "${script#$category_path/}"
        done
    fi
}

# Function to get script extension
get_script_extension() {
    local script=$1
    echo "${script##*.}"
}

# Function to execute script
execute_script() {
    local category=$1
    local script=$2
    local script_path="$SCRIPT_DIR/$category/$script"
    local ext=$(get_script_extension "$script")

    if [[ ! -f "$script_path" ]]; then
        print_color $RED "Error: Script not found: $script_path"
        return 1
    fi

    print_color $YELLOW "Executing: $category/$script"
    echo "----------------------------------------"

    case $ext in
    sh)
        bash "$script_path"
        ;;
    py)
        python3 "$script_path"
        ;;
    sql)
        print_color $BLUE "SQL Script detected. Please specify database connection:"
        echo "Example: psql -d mydb -f \"$script_path\""
        echo "Or copy the path: $script_path"
        ;;
    ts)
        if command -v ts-node &>/dev/null; then
            ts-node "$script_path"
        else
            print_color $RED "ts-node not found. Install with: npm install -g ts-node"
            echo "Script path: $script_path"
        fi
        ;;
    js)
        node "$script_path"
        ;;
    *)
        print_color $YELLOW "Unknown script type. Opening in default editor..."
        ${EDITOR:-nano} "$script_path"
        ;;
    esac
}

# Function to show script content
show_script_content() {
    local category=$1
    local script=$2
    local script_path="$SCRIPT_DIR/$category/$script"

    if [[ -f "$script_path" ]]; then
        print_color $CYAN "Content of $category/$script:"
        echo "----------------------------------------"
        cat "$script_path"
        echo "----------------------------------------"
    else
        print_color $RED "Script not found: $script_path"
    fi
}

# Function to show category menu
show_category_menu() {
    local category=$1
    local scripts=()

    # Populate scripts array properly
    while IFS= read -r script; do
        [[ -n "$script" ]] && scripts+=("$script")
    done < <(get_scripts "$category")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        print_color $RED "No scripts found in $category folder"
        read -p "Press Enter to continue..."
        return
    fi

    while true; do
        show_header
        print_color $GREEN "Category: $category"
        echo
        print_color $BLUE "Available scripts:"

        for i in "${!scripts[@]}"; do
            local ext=$(get_script_extension "${scripts[$i]}")
            local ext_color=$YELLOW
            case $ext in
            sh) ext_color=$GREEN ;;
            py) ext_color=$BLUE ;;
            sql) ext_color=$PURPLE ;;
            ts | js) ext_color=$CYAN ;;
            esac
            desc=$(get_script_description "$SCRIPT_DIR/$category/${scripts[$i]}")
            printf "%2d) %s [%s]\n    → %s\n" $((i + 1)) "${scripts[$i]}" "$(print_color $ext_color "$ext")" "${desc:-No description}"
        done

        echo
        print_color $YELLOW "Options:"
        echo "  o) Open script (in default editor)"
        echo "  r) Open README/docs (in default app)"
        echo "  f) View script directory (in file explorer)"
        echo "  b) Back to categories"
        echo "  q) Quit"
        echo

        read -p "Enter your choice: " choice

        case $choice in
        o | O)
            read -p "Enter script number to open: " script_num
            if [[ "$script_num" =~ ^[0-9]+$ ]] && [[ $script_num -ge 1 ]] && [[ $script_num -le ${#scripts[@]} ]]; then
                script_path="$SCRIPT_DIR/$category/${scripts[$((script_num - 1))]}"
                print_color $GREEN "Opening script: ${scripts[$((script_num - 1))]}"
                open_in_file_explorer "$script_path"
            else
                print_color $RED "Invalid script number"
                read -p "Press Enter to continue..."
            fi
            ;;
        r | R)
            print_color $GREEN "Opening README for category: $category"
            open_readme_in_explorer "$category" ""
            ;;
        f | F)
            read -p "Enter script number to view directory: " script_num
            if [[ "$script_num" =~ ^[0-9]+$ ]] && [[ $script_num -ge 1 ]] && [[ $script_num -le ${#scripts[@]} ]]; then
                script_path="$SCRIPT_DIR/$category/${scripts[$((script_num - 1))]}"
                dir_path=$(dirname "$script_path")
                print_color $GREEN "Opening directory: $dir_path"
                open_in_file_explorer "$dir_path"
            else
                print_color $RED "Invalid script number"
                read -p "Press Enter to continue..."
            fi
            ;;
        b | B)
            return
            ;;
        q | Q)
            echo
            print_color $GREEN "Goodbye! 👋"
            exit 0
            ;;
        *)
            print_color $RED "Invalid choice"
            read -p "Press Enter to continue..."
            ;;
        esac
    done
}

get_script_description() {
    local script_path="$1"
    # Grep first line starting with # Description:
    local desc
    desc=$(grep -m 1 '^# *Description:' "$script_path" 2>/dev/null | sed 's/^# *Description: *//')
    echo "$desc"
}

open_in_file_explorer() {
    local target_path="$1"

    if [[ ! -e "$target_path" ]]; then
        print_color $RED "Error: Path does not exist: $target_path"
        return 1
    fi

    case "$(uname)" in
    Linux*)
        xdg-open "$target_path" >/dev/null 2>&1 &
        ;;
    Darwin*)
        open "$target_path" >/dev/null 2>&1 &
        ;;
    MINGW* | MSYS* | CYGWIN*)
        explorer.exe "$(wslpath -w "$target_path")"
        ;;
    *)
        print_color $YELLOW "Unsupported OS: cannot open file explorer"
        return 1
        ;;
    esac
}

open_readme_in_explorer() {
    local category=$1
    local script=$2
    local script_dir="$SCRIPT_DIR/$category"

    # Look for README.md or README in category folder
    local readme_file=""
    for candidate in "README.md" "README" "readme.md" "readme"; do
        if [[ -f "$script_dir/$candidate" ]]; then
            readme_file="$script_dir/$candidate"
            break
        fi
    done

    if [[ -n "$readme_file" ]]; then
        print_color $GREEN "Opening README: $readme_file"
        open_in_file_explorer "$readme_file"
    else
        print_color $YELLOW "No README found in $category folder."
        read -p "Press Enter to continue..."
    fi
}

# Main menu function
main_menu() {
    local categories=($(get_categories))

    if [[ ${#categories[@]} -eq 0 ]]; then
        show_header
        print_color $YELLOW "🔍 No script categories found yet!"
        echo
        print_color $CYAN "To get started:"
        echo "  • Create folders in this directory for your script categories"
        echo "  • Add .sh, .py, .sql, .ts, or .js files to those folders"
        echo "  • Example: mkdir automation && echo '#!/bin/bash' > automation/hello.sh"
        echo
        print_color $GREEN "Current directory: $SCRIPT_DIR"
        echo
        read -p "Press Enter to exit..."
        exit 0
    fi

    while true; do
        local total_count=0
        show_header
        print_color $GREEN "Available categories:"
        echo

        for i in "${!categories[@]}"; do
            local script_count
            script_count=$(get_scripts "${categories[$i]}" | wc -l)
            total_count=$((total_count + script_count))
            echo -e "$(printf "%2d) %-15s (%s%d%s scripts)" \
                $((i + 1)) "${categories[$i]}" "${BLUE}" "$script_count" "${NC}")"
        done

        echo
        print_color $CYAN "Total scripts: $total_count"

        echo
        print_color $YELLOW "Options:"
        echo "  s) Search scripts"
        echo "  q) Quit"
        echo

        read -p "Enter category number or option: " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#categories[@]} ]]; then
            show_category_menu "${categories[$((choice - 1))]}"
        elif [[ "$choice" == "s" || "$choice" == "S" ]]; then
            search_scripts
        elif [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            print_color $GREEN "Goodbye!"
            exit 0
        else
            print_color $RED "Invalid choice"
            read -p "Press Enter to continue..."
        fi
    done
}

# Function to search scripts
search_scripts() {
    local categories=($(get_categories))
    
    read -p "Enter search term (fuzzy): " term
    if [[ -z "$term" ]]; then
        print_color $RED "Empty search term"
        return
    fi

    show_header
    print_color $GREEN "Search results for: $term"
    echo

    local found=false
    for category in "${categories[@]}"; do
        while IFS= read -r script; do
            if [[ "$script" == *"$term"* ]]; then
                local ext=$(get_script_extension "$script")
                print_color $BLUE "$category/$script [$ext]"
                found=true
            fi
        done < <(get_scripts "$category")
    done

    if [[ "$found" == false ]]; then
        print_color $YELLOW "No scripts found matching: $term"
    fi

    read -p "Press Enter to continue..."
}

# Start the CLI
main_menu
