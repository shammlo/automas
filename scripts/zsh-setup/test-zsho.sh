#!/bin/bash
#
# Description: Test suite for zsho.sh script with validation and dry-run testing

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
    ((TOTAL_TESTS++))
}

test_pass() {
    local test_name="$1"
    echo -e "${GREEN}✅ PASS: $test_name${NC}"
    ((PASSED_TESTS++))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    echo -e "${RED}❌ FAIL: $test_name${NC}"
    echo -e "${RED}   Reason: $reason${NC}"
    ((FAILED_TESTS++))
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"
    
    if echo "$haystack" | grep -q "$needle"; then
        test_pass "$test_name"
    else
        test_fail "$test_name" "Expected to find '$needle' in output"
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
}

test_dependency_checks() {
    print_test_header "Dependency Check Tests"
    
    test_start "Git dependency check"
    if command -v git >/dev/null 2>&1; then
        test_pass "Git is available for testing"
    else
        test_fail "Git is available for testing" "Git not found - required for script functionality"
    fi
    
    test_start "Curl dependency check"
    if command -v curl >/dev/null 2>&1; then
        test_pass "Curl is available for testing"
    else
        test_fail "Curl is available for testing" "Curl not found - required for script functionality"
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
    if grep -q "\.bak" "$SCRIPT_PATH"; then
        test_pass "Script includes backup functionality"
    else
        test_fail "Script includes backup functionality" "No backup functionality found"
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