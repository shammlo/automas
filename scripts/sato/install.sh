#!/bin/bash

# 🛰️ Sato Enhanced Monitoring System Installation Script
# This script helps you install and manage Sato startup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SATO_PATH="$SCRIPT_DIR/sato.py"
SATO_LAUNCHER="$SATO_PATH"
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/sato-monitoring.desktop"
APPLICATIONS_DIR="$HOME/.local/share/applications"
APPLICATIONS_FILE="$APPLICATIONS_DIR/sato-monitoring.desktop"
DESKTOP_DIR="$HOME/Desktop"
DESKTOP_ICON_FILE="$DESKTOP_DIR/sato-monitoring.desktop"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}🛰️  Sato Enhanced Monitoring System${NC}"
    echo -e "${CYAN}======================================${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_feature() {
    echo -e "${PURPLE}[FEATURE]${NC} $1"
}

create_desktop_file() {
    local output_file="$1"
    cat > "$output_file" << EOF
[Desktop Entry]
Name=Sato Enhanced Monitoring
Comment=🛰️ Advanced infrastructure monitoring with self-healing capabilities
Exec=$SATO_PATH
Icon=applications-system
Type=Application
Categories=Network;System;Monitor;
StartupNotify=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Keywords=monitoring;server;status;health;infrastructure;sato;
EOF
}

show_help() {
    print_header
    echo ""
    echo "🛰️ Sato Enhanced Monitoring System Manager"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install       Install Sato and enable autostart"
    echo "  uninstall     Remove Sato from autostart and applications"
    echo "  enable        Enable autostart (without reinstalling)"
    echo "  disable       Disable autostart (keeps Sato installed)"
    echo "  desktop-icon  Create/remove desktop icon"
    echo "  status        Show current installation status"
    echo "  run           Run Sato once (for testing)"
    echo "  test          Run system tests"
    echo "  check-deps    Check dependencies only"
    echo "  help          Show this help message"
    echo ""
    echo "Features:"
    echo "  ⚡ Parallel processing with immediate results"
    echo "  🔄 Auto-restart failed services"
    echo "  🧠 Intelligent retry logic with backoff"
    echo "  🔧 Maintenance mode scheduling"
    echo "  🔍 Auto-discovery of services"
    echo "  🏥 Self-healing infrastructure"
    echo "  📊 Alert grouping and acknowledgment"
    echo "  🎨 Animated backgrounds"
    echo ""
}

check_dependencies() {
    print_status "Checking dependencies..."
    local deps_ok=true
    
    # Check Python 3
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is not installed"
        print_status "Install with: sudo apt install python3"
        deps_ok=false
    else
        local python_version=$(python3 --version | cut -d' ' -f2)
        print_success "Python3 found: $python_version"
    fi
    
    # Check GTK3 Python bindings
    if ! python3 -c "import gi; gi.require_version('Gtk', '3.0')" 2>/dev/null; then
        print_error "GTK3 Python bindings are not installed"
        print_status "Install with: sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0"
        deps_ok=false
    else
        print_success "GTK3 Python bindings found"
    fi
    
    # Check requests library
    if ! python3 -c "import requests" 2>/dev/null; then
        print_warning "Python requests library not found"
        print_status "Install with: pip3 install requests"
        print_status "Sato will work but HTTP checks may be limited"
    else
        print_success "Python requests library found"
    fi
    
    # Check Docker (optional)
    if command -v docker &> /dev/null; then
        print_success "Docker found - container monitoring available"
    else
        print_warning "Docker not found - container monitoring disabled"
    fi
    
    # Check systemctl (optional)
    if command -v systemctl &> /dev/null; then
        print_success "systemctl found - service restart available"
    else
        print_warning "systemctl not found - service restart limited"
    fi
    
    if [ "$deps_ok" = true ]; then
        print_success "All required dependencies are installed"
        return 0
    else
        print_error "Some required dependencies are missing"
        return 1
    fi
}

install_sato() {
    print_header
    print_status "Installing Sato Enhanced Monitoring System..."
    
    # Check dependencies
    if ! check_dependencies; then
        print_error "Please install missing dependencies before continuing"
        return 1
    fi
    
    # Make script executable
    chmod +x "$SATO_PATH"
    print_success "Made Sato script executable"
    
    # Create directories
    mkdir -p "$AUTOSTART_DIR"
    mkdir -p "$APPLICATIONS_DIR"
    
    # Create desktop files
    create_desktop_file "$APPLICATIONS_FILE"
    create_desktop_file "$AUTOSTART_FILE"
    
    print_success "Installed desktop entries"
    print_success "Sato will now start automatically on login"
    print_status "You can also find it in your applications menu"
    
    # Show features
    echo ""
    print_feature "Auto-restart failed services with intelligent backoff"
    print_feature "Parallel processing for fast status updates"
    print_feature "Maintenance mode scheduling"
    print_feature "Alert grouping and acknowledgment system"
    print_feature "Docker container monitoring"
    print_feature "Self-healing infrastructure capabilities"
    
    echo ""
    print_status "Installation complete! 🎉"
    print_status "Run '$0 run' to test Sato now"
}

uninstall_sato() {
    print_status "Uninstalling Sato Enhanced Monitoring System..."
    
    # Remove autostart
    if [ -f "$AUTOSTART_FILE" ]; then
        rm "$AUTOSTART_FILE"
        print_success "Removed from autostart"
    fi
    
    # Remove from applications menu
    if [ -f "$APPLICATIONS_FILE" ]; then
        rm "$APPLICATIONS_FILE"
        print_success "Removed from applications menu"
    fi
    
    # Remove desktop icon if exists
    if [ -f "$DESKTOP_ICON_FILE" ]; then
        rm "$DESKTOP_ICON_FILE"
        print_success "Removed desktop icon"
    fi
    
    print_success "Sato uninstalled"
    print_status "Configuration files in $SCRIPT_DIR are preserved"
}

toggle_desktop_icon() {
    if [ -f "$DESKTOP_ICON_FILE" ]; then
        print_status "Removing desktop icon..."
        rm "$DESKTOP_ICON_FILE"
        print_success "Desktop icon removed"
    else
        if [ ! -f "$APPLICATIONS_FILE" ]; then
            print_warning "Sato not installed. Installing first..."
            install_sato
        fi
        
        print_status "Creating desktop icon..."
        mkdir -p "$DESKTOP_DIR"
        create_desktop_file "$DESKTOP_ICON_FILE"
        chmod +x "$DESKTOP_ICON_FILE"
        print_success "Desktop icon created"
    fi
}

enable_autostart() {
    if [ ! -f "$APPLICATIONS_FILE" ]; then
        print_warning "Sato not installed. Installing first..."
        install_sato
        return
    fi
    
    print_status "Enabling autostart..."
    mkdir -p "$AUTOSTART_DIR"
    create_desktop_file "$AUTOSTART_FILE"
    print_success "Autostart enabled"
}

disable_autostart() {
    print_status "Disabling autostart..."
    if [ -f "$AUTOSTART_FILE" ]; then
        rm "$AUTOSTART_FILE"
        print_success "Autostart disabled"
    else
        print_warning "Autostart was not enabled"
    fi
}

show_status() {
    print_header
    echo ""
    echo "🛰️ Sato Enhanced Monitoring System - Installation Status"
    echo "========================================================"
    
    if [ -f "$APPLICATIONS_FILE" ]; then
        print_success "Sato is installed in applications menu"
    else
        print_warning "Sato is not installed in applications menu"
    fi
    
    if [ -f "$AUTOSTART_FILE" ]; then
        print_success "Autostart is enabled"
    else
        print_warning "Autostart is disabled"
    fi
    
    if [ -f "$DESKTOP_ICON_FILE" ]; then
        print_success "Desktop icon is created"
    else
        print_warning "Desktop icon is not created"
    fi
    
    if [ -x "$SATO_PATH" ]; then
        print_success "Sato script is executable"
    else
        print_warning "Sato script is not executable"
    fi
    

    
    echo ""
    echo "📁 File Locations:"
    echo "   Main script: $SATO_PATH"
    echo "   Config: $SCRIPT_DIR/config/"
    echo "   Documentation: $SCRIPT_DIR/docs/"
    echo "   Tests: $SCRIPT_DIR/tests/"
    
    echo ""
    echo "🚀 Features Available:"
    if command -v docker &> /dev/null; then
        print_success "Docker container monitoring"
    else
        print_warning "Docker container monitoring (Docker not installed)"
    fi
    
    if command -v systemctl &> /dev/null; then
        print_success "Service auto-restart capabilities"
    else
        print_warning "Service auto-restart capabilities (systemctl not available)"
    fi
    
    if python3 -c "import requests" 2>/dev/null; then
        print_success "HTTP/HTTPS monitoring"
    else
        print_warning "HTTP/HTTPS monitoring (requests library not installed)"
    fi
    
    print_success "Parallel processing and immediate results"
    print_success "Alert grouping and acknowledgment"
    print_success "Maintenance mode scheduling"
    print_success "Self-healing infrastructure"
}

run_sato() {
    print_status "Running Sato for testing..."
    if [ -x "$SATO_PATH" ]; then
        "$SATO_PATH"
    else
        print_error "Sato is not executable. Run: chmod +x $SATO_PATH"
    fi
}

run_tests() {
    print_status "Running Sato system tests..."
    
    if [ ! -f "$SCRIPT_DIR/tests/test_enhanced_features.py" ]; then
        print_warning "Test files not found. Running basic dependency check..."
        check_dependencies
        return
    fi
    
    print_status "Running enhanced features test..."
    python3 "$SCRIPT_DIR/tests/test_enhanced_features.py"
    
    if [ -f "$SCRIPT_DIR/tests/test_responsiveness.py" ]; then
        echo ""
        print_status "Running responsiveness test..."
        python3 "$SCRIPT_DIR/tests/test_responsiveness.py"
    fi
    
    if [ -f "$SCRIPT_DIR/tests/test_immediate_results.py" ]; then
        echo ""
        print_status "Running immediate results test..."
        python3 "$SCRIPT_DIR/tests/test_immediate_results.py"
    fi
}

# Main script logic
case "${1:-help}" in
    install)
        install_sato
        ;;
    uninstall)
        uninstall_sato
        ;;
    enable)
        enable_autostart
        ;;
    disable)
        disable_autostart
        ;;
    desktop-icon)
        toggle_desktop_icon
        ;;
    status)
        show_status
        ;;
    run)
        run_sato
        ;;
    test)
        run_tests
        ;;
    check-deps)
        print_header
        echo ""
        check_dependencies
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac