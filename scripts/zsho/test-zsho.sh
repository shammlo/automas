#!/bin/bash
#
# Description: Comprehensive test suite for zsho.sh script with validation, 
#              plugin testing, cross-platform compatibility, and error handling

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Test configuration
SCRIPT_PATH="$(dirname "$0")/zsho.sh"
PASSED_TESTS=0
FAILED_TESTS=0
TOTAL_TESTS=0

#######################################
# Test framework functions
#######################################
print_test_header() {
    echo
    echo -e "${BLUE}🧪 $1${NC}"
    echo "----------------------------------------"
}

print_test_case() {
    echo -e "${PURPLE}📋 Test: $1${NC}"
}

test_start() {
    local test_name="$1"
    print_test_case "$test_name"
}

test_pass() {
    local test_name="$1"
    echo -e "${GREEN}✅ PASS: $test_name${NC}"
    ((TOTAL_TESTS++))
    ((PASSED_TESTS++))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    echo -e "${RED}❌ FAIL: $test_name${NC}"
    echo -e "${RED}   Reason: $reason${NC}"
    ((TOTAL_TESTS++))
    ((FAILED_TESTS++))
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"
    
    if echo "$haystack" | grep -q -- "$needle"; then
        test_pass "$test_name"
    else
        test_fail "$test_name" "Expected to find '$needle' in output"
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"
    
    if echo "$haystack" | grep -q -- "$needle"; then
        test_fail "$test_name" "Did not expect to find '$needle' in output"
    else
        test_pass "$test_name"
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local test_name="$3"
    
    if [ "$expected_code" -eq "$actual_code" ]; then
        test_pass "$test_name"
    else
        test_fail "$test_name" "Expected exit code $expected_code, got $actual_code"
    fi
}

#######################################
# Test Cases
#######################################

test_basic_functionality() {
    print_test_header "Basic Functionality Tests"
    
    test_start "Script file exists and is executable"
    if [ -x "$SCRIPT_PATH" ]; then
        test_pass "Script exists and is executable"
    else
        test_fail "Script exists and is executable" "Script not found or not executable at $SCRIPT_PATH"
        return 1
    fi
    
    test_start "Help command displays usage"
    local output
    output=$("$SCRIPT_PATH" --help 2>&1) || true
    
    assert_contains "$output" "USAGE:" "Help shows usage information"
    assert_contains "$output" "OPTIONS:" "Help shows options section"
    assert_contains "$output" "FEATURES:" "Help shows features section"
    assert_not_contains "$output" "--quiet" "Help does not advertise removed quiet option"

    test_start "Version command shows version"
    local output
    output=$("$SCRIPT_PATH" --version 2>&1) || true
    
    assert_contains "$output" "Zsh Setup Script v" "Version command shows version"
}

test_argument_validation() {
    print_test_header "Argument Validation Tests"
    
    test_start "Invalid option shows error"
    local output exit_code
    output=$("$SCRIPT_PATH" --invalid-option 2>&1) || exit_code=$?
    
    assert_exit_code 1 "${exit_code:-0}" "Invalid option exits with code 1"
    assert_contains "$output" "Unknown option" "Invalid option shows error"

    test_start "Removed quiet option is rejected"
    unset exit_code
    output=$("$SCRIPT_PATH" --quiet 2>&1) || exit_code=$?

    assert_exit_code 1 "${exit_code:-0}" "Quiet option exits with code 1"
    assert_contains "$output" "Unknown option" "Quiet option shows unknown option error"
}

test_dependency_checks() {
    print_test_header "Dependency Check Tests"
    
    test_start "Script prompts for missing Git"
    if grep -q 'ensure_dependency "git" "git" "Git"' "$SCRIPT_PATH"; then
        test_pass "Git dependency is handled by installer prompt"
    else
        test_fail "Git dependency is handled by installer prompt" "Git dependency prompt not found"
    fi
    
    test_start "Script prompts for missing curl"
    if grep -q 'ensure_dependency "curl" "curl" "curl"' "$SCRIPT_PATH"; then
        test_pass "curl dependency is handled by installer prompt"
    else
        test_fail "curl dependency is handled by installer prompt" "curl dependency prompt not found"
    fi

    test_start "Script avoids package install prompts in non-interactive shells"
    if grep -q "Cannot prompt.*non-interactive shell" "$SCRIPT_PATH"; then
        test_pass "Non-interactive dependency handling"
    else
        test_fail "Non-interactive dependency handling" "Non-interactive dependency guard not found"
    fi

    test_start "Script installs dependencies through package manager helper"
    if grep -q "install_package" "$SCRIPT_PATH" && grep -q "run_privileged" "$SCRIPT_PATH"; then
        test_pass "Dependency installation helpers present"
    else
        test_fail "Dependency installation helpers present" "Dependency installation helpers not found"
    fi
}

test_dry_run_mode() {
    print_test_header "Dry Run Mode Tests"
    
    test_start "Dry run mode flag recognition"
    local output
    output=$("$SCRIPT_PATH" --dry-run 2>&1) || true
    
    assert_contains "$output" "DRY RUN MODE" "Dry run mode is recognized"
    assert_contains "$output" "No changes will be made" "Dry run shows warning message"
}

test_os_compatibility() {
    print_test_header "OS Compatibility Tests"
    
    test_start "OS detection"
    local os_type="$OSTYPE"
    
    if [[ "$os_type" == "linux-gnu"* ]] || [[ "$os_type" == "darwin"* ]]; then
        test_pass "Running on supported OS ($os_type)"
    else
        test_fail "Running on supported OS" "Unsupported OS: $os_type"
    fi
}

test_script_structure() {
    print_test_header "Script Structure Tests"
    
    test_start "Script has proper shebang"
    local first_line
    first_line=$(head -n 1 "$SCRIPT_PATH")
    
    if [[ "$first_line" == "#!/bin/bash" ]]; then
        test_pass "Script has correct shebang"
    else
        test_fail "Script has correct shebang" "Expected '#!/bin/bash', got '$first_line'"
    fi
    
    test_start "Script has description comment"
    local description
    description=$(grep -m 1 '^# Description:' "$SCRIPT_PATH" || echo "")
    
    if [[ -n "$description" ]]; then
        test_pass "Script has description comment"
    else
        test_fail "Script has description comment" "No description comment found"
    fi
    
    test_start "Script has main function"
    if grep -q "^main()" "$SCRIPT_PATH"; then
        test_pass "Script has main function"
    else
        test_fail "Script has main function" "No main function found"
    fi
}

test_safety_features() {
    print_test_header "Safety Feature Tests"
    
    test_start "Script uses set -euo pipefail"
    if grep -q "set -euo pipefail" "$SCRIPT_PATH"; then
        test_pass "Script uses safe error handling"
    else
        test_fail "Script uses safe error handling" "set -euo pipefail not found"
    fi
    
    test_start "Script has backup functionality"
    if grep -q "\.backup\." "$SCRIPT_PATH" || grep -q "\.bak" "$SCRIPT_PATH"; then
        test_pass "Script includes backup functionality"
    else
        test_fail "Script includes backup functionality" "No backup functionality found"
    fi

    test_start "Script uses command_exists helper"
    if grep -q "^command_exists()" "$SCRIPT_PATH"; then
        test_pass "Command existence helper present"
    else
        test_fail "Command existence helper present" "command_exists helper not found"
    fi
}

test_interactive_features() {
    print_test_header "Interactive Feature Tests"
    
    test_start "Script has consistent user interface"
    if grep -q "read -p" "$SCRIPT_PATH"; then
        test_pass "Script uses standard bash prompts"
    else
        test_fail "Script uses standard bash prompts" "No standard prompts found"
    fi
    
    test_start "Script has color output support"
    if grep -q "print_color" "$SCRIPT_PATH"; then
        test_pass "Script has colored output"
    else
        test_fail "Script has colored output" "No color output functions found"
    fi
}

test_plugin_support() {
    print_test_header "Plugin Support Tests"
    
    test_start "Script supports zsh-autosuggestions"
    if grep -q "zsh-autosuggestions" "$SCRIPT_PATH"; then
        test_pass "zsh-autosuggestions plugin supported"
    else
        test_fail "zsh-autosuggestions plugin supported" "Plugin not found in script"
    fi
    
    test_start "Script supports syntax highlighting"
    if grep -q "syntax-highlighting" "$SCRIPT_PATH"; then
        test_pass "Syntax highlighting plugins supported"
    else
        test_fail "Syntax highlighting plugins supported" "Syntax highlighting not found"
    fi
    
    test_start "Script supports zsh-autocomplete"
    if grep -q "zsh-autocomplete" "$SCRIPT_PATH"; then
        test_pass "zsh-autocomplete plugin supported"
    else
        test_fail "zsh-autocomplete plugin supported" "Plugin not found in script"
    fi
    
    test_start "Script supports fast-syntax-highlighting"
    if grep -q "fast-syntax-highlighting" "$SCRIPT_PATH"; then
        test_pass "fast-syntax-highlighting plugin supported"
    else
        test_fail "fast-syntax-highlighting plugin supported" "Plugin not found in script"
    fi

    test_start "Script stores selected plugins in an array"
    if grep -Fq "ZSH_PLUGINS_SELECTED=()" "$SCRIPT_PATH" && grep -Fq 'for plugin in "${ZSH_PLUGINS_SELECTED[@]}"' "$SCRIPT_PATH"; then
        test_pass "Plugin selection uses array"
    else
        test_fail "Plugin selection uses array" "Array-based plugin selection not found"
    fi

    test_start "Script warns about syntax highlighter conflicts"
    if grep -q "can conflict when both are enabled" "$SCRIPT_PATH"; then
        test_pass "Syntax highlighter conflict warning"
    else
        test_fail "Syntax highlighter conflict warning" "Conflict warning not found"
    fi
}

test_oh_my_zsh_integration() {
    print_test_header "Oh My Zsh Integration Tests"
    
    test_start "Script includes Oh My Zsh installation"
    if grep -q "ohmyzsh/ohmyzsh" "$SCRIPT_PATH"; then
        test_pass "Oh My Zsh installation URL found"
    else
        test_fail "Oh My Zsh installation URL found" "Installation URL not found"
    fi
    
    test_start "Script uses RUNZSH=no for non-interactive install"
    if grep -q "RUNZSH=no" "$SCRIPT_PATH"; then
        test_pass "Non-interactive Oh My Zsh installation"
    else
        test_fail "Non-interactive Oh My Zsh installation" "RUNZSH=no not found"
    fi
    
    test_start "Script supports theme configuration"
    if grep -q "ZSH_THEME=" "$SCRIPT_PATH"; then
        test_pass "Theme configuration supported"
    else
        test_fail "Theme configuration supported" "Theme configuration not found"
    fi
    
    test_start "Script includes popular themes"
    local themes=("robbyrussell" "agnoster" "avit" "bira")
    local themes_found=0
    
    for theme in "${themes[@]}"; do
        if grep -q "$theme" "$SCRIPT_PATH"; then
            ((themes_found++))
        fi
    done
    
    if [ $themes_found -ge 3 ]; then
        test_pass "Popular themes included (found $themes_found)"
    else
        test_fail "Popular themes included" "Only found $themes_found themes"
    fi
}

test_cross_platform_compatibility() {
    print_test_header "Cross-Platform Compatibility Tests"
    
    test_start "Script handles macOS sed syntax"
    if grep -q "darwin" "$SCRIPT_PATH" && grep -q "sed -i ''" "$SCRIPT_PATH"; then
        test_pass "macOS sed syntax handled"
    else
        test_fail "macOS sed syntax handled" "macOS-specific sed syntax not found"
    fi
    
    test_start "Script handles Linux sed syntax"
    if grep -q "sed -i " "$SCRIPT_PATH"; then
        test_pass "Linux sed syntax handled"
    else
        test_fail "Linux sed syntax handled" "Linux sed syntax not found"
    fi
    
    test_start "Script detects package managers"
    local package_managers=("apt" "yum" "dnf" "pacman" "brew")
    local managers_found=0
    
    for manager in "${package_managers[@]}"; do
        if grep -q "$manager" "$SCRIPT_PATH"; then
            ((managers_found++))
        fi
    done
    
    if [ $managers_found -ge 4 ]; then
        test_pass "Multiple package managers supported (found $managers_found)"
    else
        test_fail "Multiple package managers supported" "Only found $managers_found package managers"
    fi
}

test_backup_and_safety() {
    print_test_header "Backup and Safety Tests"
    
    test_start "Script creates timestamped backups"
    if grep -q "backup_timestamp" "$SCRIPT_PATH" && grep -q "date +%Y%m%d_%H%M%S" "$SCRIPT_PATH"; then
        test_pass "Timestamped backup creation"
    else
        test_fail "Timestamped backup creation" "Timestamped backup not found"
    fi

    test_start "Script reuses exact backup path in output"
    if grep -q 'Backup created: \$backup_path' "$SCRIPT_PATH"; then
        test_pass "Backup message uses stored path"
    else
        test_fail "Backup message uses stored path" "Stored backup path message not found"
    fi
    
    test_start "Script checks for existing installations"
    if grep -q "already installed" "$SCRIPT_PATH"; then
        test_pass "Existing installation checks"
    else
        test_fail "Existing installation checks" "Installation checks not found"
    fi
    
    test_start "Script validates plugin directories"
    if grep -q "mkdir -p.*plugins" "$SCRIPT_PATH"; then
        test_pass "Plugin directory validation"
    else
        test_fail "Plugin directory validation" "Directory validation not found"
    fi
    
    test_start "Script includes error handling for git operations"
    if grep -q "git clone" "$SCRIPT_PATH" && grep -q "if.*-d" "$SCRIPT_PATH"; then
        test_pass "Git operation error handling"
    else
        test_fail "Git operation error handling" "Git error handling not found"
    fi
}

test_verification_features() {
    print_test_header "Verification Feature Tests"
    
    test_start "Script includes installation verification"
    if grep -q "Verifying.*installation" "$SCRIPT_PATH"; then
        test_pass "Installation verification included"
    else
        test_fail "Installation verification included" "Verification not found"
    fi
    
    test_start "Script checks plugin configuration in .zshrc"
    if grep -q "grep.*plugins=" "$SCRIPT_PATH"; then
        test_pass "Plugin configuration verification"
    else
        test_fail "Plugin configuration verification" "Configuration check not found"
    fi
    
    test_start "Script verifies plugin directories exist"
    if grep -q "directory exists" "$SCRIPT_PATH"; then
        test_pass "Plugin directory verification"
    else
        test_fail "Plugin directory verification" "Directory verification not found"
    fi
}

test_user_experience() {
    print_test_header "User Experience Tests"
    
    test_start "Script provides clear progress messages"
    if grep -q "show_progress" "$SCRIPT_PATH"; then
        test_pass "Progress messages included"
    else
        test_fail "Progress messages included" "Progress function not found"
    fi
    
    test_start "Script shows configuration summary"
    if grep -q "Configuration Summary" "$SCRIPT_PATH"; then
        test_pass "Configuration summary displayed"
    else
        test_fail "Configuration summary displayed" "Summary not found"
    fi
    
    test_start "Script provides post-installation instructions"
    if grep -q "restart your terminal" "$SCRIPT_PATH" || grep -q "exec zsh" "$SCRIPT_PATH"; then
        test_pass "Post-installation instructions provided"
    else
        test_fail "Post-installation instructions provided" "Instructions not found"
    fi
    
    test_start "Script includes useful command references"
    if grep -q "Useful.*commands" "$SCRIPT_PATH"; then
        test_pass "Command references included"
    else
        test_fail "Command references included" "Command references not found"
    fi
}

test_plugin_installation_logic() {
    print_test_header "Plugin Installation Logic Tests"
    
    test_start "Script only installs plugins with Oh My Zsh"
    if grep -q "INSTALL_ZSH_PLUGINS.*true.*INSTALL_OH_MY_ZSH.*true" "$SCRIPT_PATH"; then
        test_pass "Plugin installation requires Oh My Zsh"
    else
        test_fail "Plugin installation requires Oh My Zsh" "Dependency check not found"
    fi
    
    test_start "Script handles plugin selection properly"
    if grep -Fq 'ZSH_PLUGINS_SELECTED+=(' "$SCRIPT_PATH"; then
        test_pass "Plugin selection handling"
    else
        test_fail "Plugin selection handling" "Plugin selection not found"
    fi
    
    test_start "Script supports 'all' plugins option"
    if grep -q "all.*plugins" "$SCRIPT_PATH"; then
        test_pass "All plugins option supported"
    else
        test_fail "All plugins option supported" "All plugins option not found"
    fi
    
    test_start "Script updates .zshrc with selected plugins"
    if grep -q "build_plugins_line" "$SCRIPT_PATH"; then
        test_pass ".zshrc plugin configuration"
    else
        test_fail ".zshrc plugin configuration" "Plugin configuration not found"
    fi

    test_start "Script uses safer sed delimiter for plugin line"
    if grep -Fq 'sed_inplace "s|^plugins=.*|$plugins_line|"' "$SCRIPT_PATH"; then
        test_pass "Safer plugin sed delimiter"
    else
        test_fail "Safer plugin sed delimiter" "Safer sed delimiter not found"
    fi
}

test_error_handling() {
    print_test_header "Error Handling Tests"
    
    test_start "Script handles missing dependencies gracefully"
    if grep -q "required but not installed" "$SCRIPT_PATH"; then
        test_pass "Missing dependency error handling"
    else
        test_fail "Missing dependency error handling" "Dependency error messages not found"
    fi
    
    test_start "Script handles unsupported OS gracefully"
    if grep -q "currently supports.*only" "$SCRIPT_PATH"; then
        test_pass "Unsupported OS error handling"
    else
        test_fail "Unsupported OS error handling" "OS error handling not found"
    fi
    
    test_start "Script warns about plugins without Oh My Zsh"
    if grep -q "Plugins require Oh My Zsh" "$SCRIPT_PATH"; then
        test_pass "Plugin dependency warning"
    else
        test_fail "Plugin dependency warning" "Plugin warning not found"
    fi
    
    test_start "Script handles existing installations gracefully"
    if grep -q "already.*skipping" "$SCRIPT_PATH"; then
        test_pass "Existing installation handling"
    else
        test_fail "Existing installation handling" "Existing installation messages not found"
    fi
}

test_configuration_options() {
    print_test_header "Configuration Options Tests"
    
    test_start "Script supports default shell configuration"
    if grep -q "chsh -s" "$SCRIPT_PATH"; then
        test_pass "Default shell configuration"
    else
        test_fail "Default shell configuration" "Shell change command not found"
    fi
    
    test_start "Script checks current shell before changing"
    if grep -q "CURRENT_SHELL" "$SCRIPT_PATH"; then
        test_pass "Current shell detection"
    else
        test_fail "Current shell detection" "Shell detection not found"
    fi
    
    test_start "Script provides interactive theme selection"
    if grep -q "Select.*theme" "$SCRIPT_PATH"; then
        test_pass "Interactive theme selection"
    else
        test_fail "Interactive theme selection" "Theme selection not found"
    fi
    
    test_start "Script provides interactive plugin selection"
    if grep -q "Select plugins" "$SCRIPT_PATH"; then
        test_pass "Interactive plugin selection"
    else
        test_fail "Interactive plugin selection" "Plugin selection not found"
    fi

    test_start "Script uses command -v zsh for shell path"
    if grep -Fq 'chsh -s "$(command -v zsh)"' "$SCRIPT_PATH"; then
        test_pass "Portable zsh path lookup"
    else
        test_fail "Portable zsh path lookup" "command -v zsh not found in chsh call"
    fi

    test_start "Script does not use which for zsh lookup"
    if grep -Fq 'which zsh' "$SCRIPT_PATH"; then
        test_fail "No which zsh usage" "which zsh is still used"
    else
        test_pass "No which zsh usage"
    fi
}

#######################################
# Test execution
#######################################
run_all_tests() {
    echo -e "${BLUE}🚀 Starting Comprehensive Test Suite for Zsh Setup Script${NC}"
    echo "========================================================"
    
    # Check if script exists
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo -e "${RED}❌ Script not found: $SCRIPT_PATH${NC}"
        exit 1
    fi
    
    # Make script executable
    chmod +x "$SCRIPT_PATH"
    
    # Run test suites
    test_basic_functionality
    test_argument_validation
    test_dependency_checks
    test_dry_run_mode
    test_os_compatibility
    test_script_structure
    test_safety_features
    test_interactive_features
    test_plugin_support
    test_oh_my_zsh_integration
    test_cross_platform_compatibility
    test_backup_and_safety
    test_verification_features
    test_user_experience
    test_plugin_installation_logic
    test_error_handling
    test_configuration_options
    
    # Print summary
    echo ""
    echo "========================================================"
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo "========================================================"
    echo -e "${PURPLE}Total Tests: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 All tests passed! The Zsh Setup script is working correctly.${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}💥 Some tests failed. Please review the output above.${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_all_tests
fi
