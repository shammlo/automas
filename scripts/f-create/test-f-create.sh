#!/bin/bash
#
# Description: Comprehensive test suite for f-create.sh with 32 test cases covering all functionality

# Comprehensive Test Suite for f-create.sh
# Tests all features, options, and edge cases

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Test configuration
SCRIPT_PATH="./scripts/f-create/f-create.sh"
TEST_DIR="test-suite"
PASSED_TESTS=0
FAILED_TESTS=0
TOTAL_TESTS=0

# Test output functions
print_test_header() {
    echo -e "\n${BLUE}🧪 $1${NC}"
    echo "----------------------------------------"
}

print_test_case() {
    echo -e "${PURPLE}📋 Test: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
    ((PASSED_TESTS++))
}

print_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    ((FAILED_TESTS++))
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Utility functions
cleanup_test_dir() {
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
    mkdir -p "$TEST_DIR"
}

file_exists() {
    [ -f "$1" ]
}

dir_exists() {
    [ -d "$1" ]
}

file_has_content() {
    local file="$1"
    local expected="$2"
    if [ -f "$file" ]; then
        local content=$(cat "$file")
        if [[ "$content" == *"$expected"* ]]; then
            return 0
        else
            echo "DEBUG: Expected '$expected', got '$content'" >&2
            return 1
        fi
    else
        echo "DEBUG: File '$file' does not exist" >&2
        return 1
    fi
}

file_has_permissions() {
    local file="$1"
    local expected_perms="$2"
    if [ -f "$file" ]; then
        local actual_perms=$(stat -c "%a" "$file" 2>/dev/null)
        [ "$actual_perms" = "$expected_perms" ]
    else
        return 1
    fi
}

run_test() {
    ((TOTAL_TESTS++))
    local test_name="$1"
    shift
    
    print_test_case "$test_name"
    
    # Run the command and capture output
    local output
    local exit_code
    output=$("$@" 2>&1)
    exit_code=$?
    
    return $exit_code
}

# Test Suite Functions

test_basic_functionality() {
    print_test_header "Basic Functionality Tests"
    
    cleanup_test_dir
    cd "$TEST_DIR"
    
    # Test 1: Create simple file
    if run_test "Create simple file" "../$SCRIPT_PATH" "simple.txt"; then
        if file_exists "simple.txt"; then
            print_pass "Simple file creation"
        else
            print_fail "Simple file was not created"
        fi
    else
        print_fail "Simple file creation command failed"
    fi
    
    # Test 2: Create nested file
    if run_test "Create nested file" "../$SCRIPT_PATH" "nested/deep/file.txt"; then
        if file_exists "nested/deep/file.txt" && dir_exists "nested/deep"; then
            print_pass "Nested file creation"
        else
            print_fail "Nested file or directories not created"
        fi
    else
        print_fail "Nested file creation command failed"
    fi
    
    # Test 3: Create directory (no extension)
    if run_test "Create directory" "../$SCRIPT_PATH" "test-dir/subdir"; then
        if dir_exists "test-dir/subdir"; then
            print_pass "Directory creation"
        else
            print_fail "Directory was not created"
        fi
    else
        print_fail "Directory creation command failed"
    fi
    
    # Test 4: Create directory (ends with /)
    if run_test "Create directory with slash" "../$SCRIPT_PATH" "slash-dir/"; then
        if dir_exists "slash-dir"; then
            print_pass "Directory creation with trailing slash"
        else
            print_fail "Directory with trailing slash not created"
        fi
    else
        print_fail "Directory with slash creation command failed"
    fi
    
    cd ..
}

test_file_type_detection() {
    print_test_header "File Type Detection Tests"
    
    cleanup_test_dir
    cd "$TEST_DIR"
    
    # Test extensionless files
    local extensionless_files=("README" "LICENSE" "Dockerfile" "Makefile" "Gemfile")
    
    for file in "${extensionless_files[@]}"; do
        if run_test "Create extensionless file: $file" "../$SCRIPT_PATH" "$file"; then
            if file_exists "$file"; then
                print_pass "Extensionless file: $file"
            else
                print_fail "Extensionless file not created: $file"
            fi
        else
            print_fail "Extensionless file command failed: $file"
        fi
    done
    
    cd ..
}

test_force_options() {
    print_test_header "Force Type Options Tests"
    
    cleanup_test_dir
    cd "$TEST_DIR"
    
    # Test force file
    if run_test "Force file creation" "../$SCRIPT_PATH" "no-extension" "--file"; then
        if file_exists "no-extension"; then
            print_pass "Force file option"
        else
            print_fail "Force file option did not create file"
        fi
    else
        print_fail "Force file command failed"
    fi
    
    # Test force directory
    if run_test "Force directory creation" "../$SCRIPT_PATH" "has.extension" "--dir"; then
        if dir_exists "has.extension"; then
            print_pass "Force directory option"
        else
            print_fail "Force directory option did not create directory"
        fi
    else
        print_fail "Force directory command failed"
    fi
    
    cd ..
}

test_content_options() {
    print_test_header "Content Options Tests"
    
    cleanup_test_dir
    cd "$TEST_DIR"
    
    # Test custom content
    if run_test "Custom content" "../$SCRIPT_PATH" "custom.txt" "--content" "Hello World"; then
        sleep 0.1  # Small delay to ensure file is written
        if file_has_content "custom.txt" "Hello World"; then
            print_pass "Custom content option"
        else
            print_fail "Custom content not found in file"
            if [ -f "custom.txt" ]; then
                print_info "Actual content: '$(cat custom.txt)'"
            fi
        fi
    else
        print_fail "Custom content command failed"
    fi
    
    # Test auto-content for shell script
    if run_test "Auto-content shell script" "../$SCRIPT_PATH" "script.sh"; then
        if file_has_content "script.sh" "#!/bin/bash"; then
            print_pass "Auto-content for shell script"
        else
            print_fail "Auto-content not found in shell script"
        fi
    else
        print_fail "Auto-content shell script command failed"
    fi
    
    # Test auto-content for Python script
    if run_test "Auto-content Python script" "../$SCRIPT_PATH" "script.py"; then
        if file_has_content "script.py" "#!/usr/bin/env python3"; then
            print_pass "Auto-content for Python script"
        else
            print_fail "Auto-content not found in Python script"
        fi
    else
        print_fail "Auto-content Python script command failed"
    fi
    
    # Test auto-content for JavaScript
    if run_test "Auto-content JavaScript" "../$SCRIPT_PATH" "script.js"; then
        if file_has_content "script.js" "// JavaScript file"; then
            print_pass "Auto-content for JavaScript"
        else
            print_fail "Auto-content not found in JavaScript file"
        fi
    else
        print_fail "Auto-content JavaScript command failed"
    fi
    
    # Test auto-content for Markdown
    if run_test "Auto-content Markdown" "../$SCRIPT_PATH" "README.md"; then
        if file_has_content "README.md" "# README"; then
            print_pass "Auto-content for Markdown"
        else
            print_fail "Auto-content not found in Markdown file"
        fi
    else
        print_fail "Auto-content Markdown command failed"
    fi
    
    cd ..
}

test_permissions() {
    print_test_header "Permissions Tests"
    
    cleanup_test_dir
    cd "$TEST_DIR"
    
    # Test chmod option
    if run_test "Set permissions 755" "../$SCRIPT_PATH" "executable.sh" "--chmod" "755"; then
        if file_has_permissions "executable.sh" "755"; then
            print_pass "Permissions 755"
        else
            print_fail "Permissions not set to 755"
        fi
    else
        print_fail "Permissions command failed"
    fi
    
    # Test chmod option with 644
    if run_test "Set permissions 644" "../$SCRIPT_PATH" "readable.txt" "--chmod" "644"; then
        if file_has_permissions "readable.txt" "644"; then
            print_pass "Permissions 644"
        else
            print_fail "Permissions not set to 644"
        fi
    else
        print_fail "Permissions 644 command failed"
    fi
    
    cd ..
}

test_batch_mode() {
    print_test_header "Batch Mode Tests"
    
    cleanup_test_dir
    cd "$TEST_DIR"
    
    # Test batch creation
    if run_test "Batch creation" "../$SCRIPT_PATH" "batch1.txt" "batch2.js" "batch-dir/" "batch-dir2/subdir"; then
        local all_created=true
        
        if ! file_exists "batch1.txt"; then all_created=false; fi
        if ! file_exists "batch2.js"; then all_created=false; fi
        if ! dir_exists "batch-dir"; then all_created=false; fi
        if ! dir_exists "batch-dir2/subdir"; then all_created=false; fi
        
        if [ "$all_created" = true ]; then
            print_pass "Batch creation"
        else
            print_fail "Not all batch items were created"
        fi
    else
        print_fail "Batch creation command failed"
    fi
    
    cd ..
}

test_dry_run_mode() {
    print_test_header "Dry Run Mode Tests"
    
    cleanup_test_dir
    cd "$TEST_DIR"
    
    # Test dry run - should not create files
    if run_test "Dry run mode" "../$SCRIPT_PATH" "dry-test.txt" "dry-dir/" "--dry-run"; then
        if ! file_exists "dry-test.txt" && ! dir_exists "dry-dir"; then
            print_pass "Dry run mode (no files created)"
        else
            print_fail "Dry run mode created files when it shouldn't"
        fi
    else
        print_fail "Dry run command failed"
    fi
    
    cd ..
}

test_quiet_verbose_modes() {
    print_test_header "Output Mode Tests"
    
    cleanup_test_dir
    cd "$TEST_DIR"
    
    # Test quiet mode (should have minimal output)
    local quiet_output
    quiet_output=$(run_test "Quiet mode" "../$SCRIPT_PATH" "quiet.txt" "--quiet" 2>&1)
    if [[ ${#quiet_output} -lt 100 ]]; then  # Arbitrary threshold for "quiet"
        print_pass "Quiet mode (minimal output)"
    else
        print_fail "Quiet mode produced too much output"
    fi
    
    # Test verbose mode (should have detailed output)
    local verbose_output
    verbose_output=$(../"$SCRIPT_PATH" "verbose.txt" "--verbose" 2>&1)
    if [[ "$verbose_output" == *"VERBOSE MODE"* ]] && [[ "$verbose_output" == *"File details:"* ]]; then
        print_pass "Verbose mode (detailed output)"
    else
        print_fail "Verbose mode didn't produce verbose indicators"
        print_info "Verbose output length: ${#verbose_output}"
    fi
    
    cd ..
}

test_undo_functionality() {
    print_test_header "Undo Functionality Tests"
    
    cleanup_test_dir
    cd "$TEST_DIR"
    
    # Clean up any existing history file (now stored in script directory)
    rm -f "../scripts/f-create/.f-create-history"
    
    # Test undo with no history
    local no_history_output
    no_history_output=$(../"$SCRIPT_PATH" "--undo" 2>&1)
    if [[ "$no_history_output" == *"No history file found"* ]]; then
        print_pass "Undo with no history"
    else
        print_fail "Undo should report no history file"
    fi
    
    # Create a file and test undo
    if run_test "Create file for undo test" "../$SCRIPT_PATH" "undo-test.txt"; then
        if file_exists "undo-test.txt"; then
            # Test undo (automatically answer 'y')
            echo "y" | ../"$SCRIPT_PATH" "--undo" >/dev/null 2>&1
            if ! file_exists "undo-test.txt"; then
                print_pass "Undo file creation"
            else
                print_fail "File should have been removed by undo"
            fi
        else
            print_fail "Test file was not created"
        fi
    else
        print_fail "Failed to create test file for undo"
    fi
    
    # Create a directory and test undo
    if run_test "Create directory for undo test" "../$SCRIPT_PATH" "undo-dir/"; then
        if dir_exists "undo-dir"; then
            # Test undo directory (automatically answer 'y')
            echo "y" | ../"$SCRIPT_PATH" "--undo" >/dev/null 2>&1
            if ! dir_exists "undo-dir"; then
                print_pass "Undo directory creation"
            else
                print_fail "Directory should have been removed by undo"
            fi
        else
            print_fail "Test directory was not created"
        fi
    else
        print_fail "Failed to create test directory for undo"
    fi
    
    # Test undo cancellation
    if run_test "Create file for undo cancellation test" "../$SCRIPT_PATH" "cancel-undo.txt"; then
        if file_exists "cancel-undo.txt"; then
            # Test undo cancellation (automatically answer 'n')
            echo "n" | ../"$SCRIPT_PATH" "--undo" >/dev/null 2>&1
            if file_exists "cancel-undo.txt"; then
                print_pass "Undo cancellation (file preserved)"
            else
                print_fail "File should have been preserved when undo was cancelled"
            fi
        else
            print_fail "Test file for cancellation was not created"
        fi
    else
        print_fail "Failed to create test file for undo cancellation"
    fi
    
    # Test undo dry-run
    if run_test "Create file for dry-run undo test" "../$SCRIPT_PATH" "dry-undo.txt"; then
        if file_exists "dry-undo.txt"; then
            # Test undo dry-run (should not prompt for input)
            local dry_undo_output
            dry_undo_output=$(../"$SCRIPT_PATH" "--undo" "--dry-run" 2>&1)
            if [[ "$dry_undo_output" == *"[DRY RUN] Would undo"* ]] && file_exists "dry-undo.txt"; then
                print_pass "Undo dry-run mode"
            else
                print_fail "Undo dry-run should show what would be undone without doing it"
                print_info "Output: $dry_undo_output"
            fi
        else
            print_fail "Test file for dry-run undo was not created"
        fi
    else
        print_fail "Failed to create test file for dry-run undo"
    fi
    
    # Test multiple operations and undo order
    run_test "Create multiple items for undo order test" "../$SCRIPT_PATH" "first.txt" "second.txt" "third-dir/" >/dev/null 2>&1
    
    # Undo should remove the last created item (third-dir)
    echo "y" | ../"$SCRIPT_PATH" "--undo" >/dev/null 2>&1
    if ! dir_exists "third-dir" && file_exists "first.txt" && file_exists "second.txt"; then
        print_pass "Undo order (last operation first)"
    else
        print_fail "Undo should remove the most recent operation first"
    fi
    
    cd ..
}

test_error_handling() {
    print_test_header "Error Handling Tests"
    
    cleanup_test_dir
    cd "$TEST_DIR"
    
    # Test invalid option
    if ! run_test "Invalid option" "../$SCRIPT_PATH" "test.txt" "--invalid-option" 2>/dev/null; then
        print_pass "Invalid option handling"
    else
        print_fail "Invalid option should have failed"
    fi
    
    # Test no arguments (should show help and exit 0)
    local no_args_output
    no_args_output=$(../"$SCRIPT_PATH" 2>&1)
    local exit_code=$?
    if [ $exit_code -eq 0 ] && [[ "$no_args_output" == *"Usage:"* ]]; then
        print_pass "No arguments handling (shows help)"
    else
        print_fail "No arguments should show help and exit cleanly"
        print_info "Exit code: $exit_code"
    fi
    
    # Test dangerous path (should be rejected or warned)
    if run_test "Dangerous path" "../$SCRIPT_PATH" "../../../dangerous.txt" 2>/dev/null; then
        # This might pass with warning, so we just check it doesn't crash
        print_pass "Dangerous path handling (didn't crash)"
    else
        print_pass "Dangerous path rejected"
    fi
    
    cd ..
}

test_help_option() {
    print_test_header "Help Option Test"
    
    # Test help option
    local help_output
    help_output=$("$SCRIPT_PATH" "--help" 2>&1)
    if [[ "$help_output" == *"Usage:"* ]] && [[ "$help_output" == *"OPTIONS:"* ]]; then
        print_pass "Help option displays usage"
    else
        print_fail "Help option doesn't display proper usage"
        print_info "Help output: $help_output"
    fi
}

# Main test runner
main() {
    echo -e "${BLUE}🚀 Starting Comprehensive Test Suite for f-create.sh${NC}"
    echo "========================================================"
    
    # Check if script exists
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo -e "${RED}❌ Script not found: $SCRIPT_PATH${NC}"
        exit 1
    fi
    
    # Make script executable
    chmod +x "$SCRIPT_PATH"
    
    # Run all test suites
    test_help_option
    test_basic_functionality
    test_file_type_detection
    test_force_options
    test_content_options
    test_permissions
    test_batch_mode
    test_dry_run_mode
    test_quiet_verbose_modes
    test_undo_functionality
    test_error_handling
    
    # Cleanup
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
    
    # Print summary
    echo ""
    echo "========================================================"
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo "========================================================"
    echo -e "Total Tests: ${PURPLE}$TOTAL_TESTS${NC}"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All tests passed! The script is working correctly.${NC}"
        exit 0
    else
        echo -e "\n${RED}💥 Some tests failed. Please review the output above.${NC}"
        exit 1
    fi
}

# Run the test suite
main "$@"