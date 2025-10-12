#!/bin/bash
#
# Description: Test suite for servault.sh script with dependency validation and dry-run testing

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Test configuration
SCRIPT_PATH="$(dirname "$0")/servault.sh"
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
    assert_contains "$output" "ENVIRONMENTS:" "Help shows environments section"
    assert_contains "$output" "EXAMPLES:" "Help shows examples section"

    test_start "Version command shows version"
    local output
    output=$("$SCRIPT_PATH" --version 2>&1) || true
    
    assert_contains "$output" "Servault v" "Version command shows version"
}

test_argument_validation() {
    print_test_header "Argument Validation Tests"
    
    test_start "No arguments shows help"
    local output exit_code
    output=$("$SCRIPT_PATH" 2>&1) || exit_code=$?
    
    assert_exit_code 1 "${exit_code:-0}" "No arguments exits with code 1"
    assert_contains "$output" "Environment not specified" "No arguments shows error"
    
    test_start "Invalid environment shows error"
    local output exit_code
    output=$("$SCRIPT_PATH" invalid 2>&1) || exit_code=$?
    
    assert_exit_code 1 "${exit_code:-0}" "Invalid environment exits with code 1"
    assert_contains "$output" "Unknown option" "Invalid environment shows error"
    
    test_start "Invalid option shows error"
    local output exit_code
    output=$("$SCRIPT_PATH" uat --invalid-option 2>&1) || exit_code=$?
    
    assert_exit_code 1 "${exit_code:-0}" "Invalid option exits with code 1"
    assert_contains "$output" "Unknown option" "Invalid option shows error"
}

test_dependency_checks() {
    print_test_header "Dependency Check Tests"
    
    test_start "Script checks for required dependencies"
    if grep -q "command_exists op" "$SCRIPT_PATH"; then
        test_pass "Script checks for 1Password CLI"
    else
        test_fail "Script checks for 1Password CLI" "No 1Password CLI check found"
    fi
    
    if grep -q "command_exists sshpass" "$SCRIPT_PATH"; then
        test_pass "Script checks for sshpass"
    else
        test_fail "Script checks for sshpass" "No sshpass check found"
    fi
    
    if grep -q "command_exists expect" "$SCRIPT_PATH"; then
        test_pass "Script checks for expect"
    else
        test_fail "Script checks for expect" "No expect check found"
    fi
}

test_environment_support() {
    print_test_header "Environment Support Tests"
    
    test_start "UAT environment is supported"
    if grep -q "uat" "$SCRIPT_PATH"; then
        test_pass "UAT environment supported"
    else
        test_fail "UAT environment supported" "UAT environment not found in script"
    fi
    
    test_start "Production environment is supported"
    if grep -q "prod" "$SCRIPT_PATH"; then
        test_pass "Production environment supported"
    else
        test_fail "Production environment supported" "Production environment not found in script"
    fi
}

test_1password_integration() {
    print_test_header "1Password Integration Tests"
    
    test_start "Script has 1Password signin functionality"
    if grep -q "op signin" "$SCRIPT_PATH"; then
        test_pass "1Password signin functionality present"
    else
        test_fail "1Password signin functionality present" "No 1Password signin found"
    fi
    
    test_start "Script retrieves credentials from 1Password"
    if grep -q "op item get" "$SCRIPT_PATH"; then
        test_pass "1Password credential retrieval present"
    else
        test_fail "1Password credential retrieval present" "No credential retrieval found"
    fi
    
    test_start "Script handles UAT server credentials"
    if grep -q "OP_ITEM_PATTERNS" "$SCRIPT_PATH" && grep -q "uat" "$SCRIPT_PATH"; then
        test_pass "UAT server credentials handling"
    else
        test_fail "UAT server credentials handling" "UAT server credentials configuration not found"
    fi
    
    test_start "Script handles production server credentials"
    if grep -q "OP_ITEM_PATTERNS" "$SCRIPT_PATH" && grep -q "prod" "$SCRIPT_PATH"; then
        test_pass "Production server credentials handling"
    else
        test_fail "Production server credentials handling" "Production server credentials configuration not found"
    fi
}

test_connection_options() {
    print_test_header "Connection Options Tests"
    
    test_start "Script supports database connection option"
    if grep -q "connect_db" "$SCRIPT_PATH"; then
        test_pass "Database connection option supported"
    else
        test_fail "Database connection option supported" "Database connection not found"
    fi
    
    test_start "Script supports main user option"
    if grep -q "use_main" "$SCRIPT_PATH"; then
        test_pass "Main user option supported"
    else
        test_fail "Main user option supported" "Main user option not found"
    fi
    
    test_start "Script supports dry-run mode"
    if grep -q "dry_run" "$SCRIPT_PATH"; then
        test_pass "Dry-run mode supported"
    else
        test_fail "Dry-run mode supported" "Dry-run mode not found"
    fi
    
    test_start "Script supports configuration display"
    if grep -q "show_config" "$SCRIPT_PATH" && grep -q "\-\-config" "$SCRIPT_PATH"; then
        test_pass "Configuration display supported"
    else
        test_fail "Configuration display supported" "Configuration display not found"
    fi
}

test_security_features() {
    print_test_header "Security Features Tests"
    
    test_start "Script uses sshpass for password authentication"
    if grep -q "sshpass" "$SCRIPT_PATH"; then
        test_pass "sshpass authentication present"
    else
        test_fail "sshpass authentication present" "sshpass not found in script"
    fi
    
    test_start "Script disables strict host key checking"
    if grep -q "StrictHostKeyChecking=no" "$SCRIPT_PATH"; then
        test_pass "Host key checking disabled for automation"
    else
        test_fail "Host key checking disabled for automation" "StrictHostKeyChecking not found"
    fi
    
    test_start "Script uses expect for interactive sessions"
    if grep -q "expect -c" "$SCRIPT_PATH"; then
        test_pass "Expect for interactive sessions present"
    else
        test_fail "Expect for interactive sessions present" "Expect usage not found"
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
    
    test_start "Script uses safe error handling"
    if grep -q "set -euo pipefail" "$SCRIPT_PATH"; then
        test_pass "Script uses safe error handling"
    else
        test_fail "Script uses safe error handling" "set -euo pipefail not found"
    fi
    
    test_start "Script has main function"
    if grep -q "^main()" "$SCRIPT_PATH"; then
        test_pass "Script has main function"
    else
        test_fail "Script has main function" "No main function found"
    fi
}

test_output_formatting() {
    print_test_header "Output Formatting Tests"
    
    test_start "Script has colored output support"
    if grep -q "print_color" "$SCRIPT_PATH"; then
        test_pass "Script has colored output"
    else
        test_fail "Script has colored output" "No color output functions found"
    fi
    
    test_start "Script has banner display"
    if grep -q "show_banner" "$SCRIPT_PATH"; then
        test_pass "Script has banner display"
    else
        test_fail "Script has banner display" "No banner function found"
    fi
    
    test_start "Script has progress indicators"
    if grep -q "Loading.*credentials" "$SCRIPT_PATH"; then
        test_pass "Script has progress indicators"
    else
        test_fail "Script has progress indicators" "No progress indicators found"
    fi
}

#######################################
# Test execution
#######################################
run_all_tests() {
    echo -e "${BLUE}🚀 Starting Comprehensive Test Suite for Servault${NC}"
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
    test_environment_support
    test_1password_integration
    test_connection_options
    test_security_features
    test_script_structure
    test_output_formatting
    
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
        echo -e "${GREEN}🎉 All tests passed! The Servault script is working correctly.${NC}"
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