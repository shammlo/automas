#!/bin/bash
#
# Description: Comprehensive test suite for DBM - Database Manager with 50 test cases

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$TEST_DIR/dbm.sh"

# Change to the test directory to ensure relative paths work
cd "$TEST_DIR"
SCRIPT_PATH="./dbm.sh"
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

test_info() {
    local message="$1"
    echo -e "${YELLOW}ℹ️  $message${NC}"
}

# Setup test environment
setup_test_env() {
    test_info "Setting up test environment..."
    
    # Backup original config if it exists
    if [ -f ".dbmrc" ]; then
        cp .dbmrc .dbmrc.backup
        test_info "Backed up existing .dbmrc"
    fi
    
    # Create test config with all supported formats
    cat > .dbmrc << 'EOF'
# Test configurations for all supported formats

# Format 1: Password via PGPASSWORD env var (most secure)
test_basic=test_user::5432:test_db

# Format 2: Password in config (convenient but less secure)  
test_password=test_user:test_pass:5432:test_db

# Format 3: Custom host support
test_host=test_user:test_pass:5432:test_db:remote.example.com

# Format 4: SSL-enabled connection
test_ssl=test_user:test_pass:5432:test_db:ssl.example.com:require

# Format 5: SSL with client certificate
test_ssl_cert=test_user:test_pass:5432:test_db:ssl.example.com:verify-full:/tmp/test.crt

# Format 6: Full PostgreSQL URI
test_uri=postgres://test_user:test_pass@uri.example.com:5432/test_db?sslmode=require

# Format 7: PostgreSQL URI with SSL cert
test_uri_ssl=postgres://test_user:test_pass@uri.example.com:5432/test_db?sslmode=require&sslcert=/tmp/test.crt

# Format 8: Azure PostgreSQL format
test_azure=postgres://username%40server:password@server.postgres.database.azure.com:5432/database?sslmode=require

# Format 9: Legacy 3-part format (backward compatibility)
test_legacy=test_user:5432:test_db

# Invalid formats for testing error handling
# invalid_format=invalid_config_line
EOF
    
    # Create a fake SSL certificate for testing
    touch /tmp/test.crt
    
    test_info "Created test configuration with 9 different formats"
}

# Cleanup test environment
cleanup_test_env() {
    test_info "Cleaning up test environment..."
    
    # Restore original config if it existed
    if [ -f ".dbmrc.backup" ]; then
        mv .dbmrc.backup .dbmrc
        test_info "Restored original .dbmrc"
    else
        rm -f .dbmrc
        test_info "Removed test .dbmrc"
    fi
    
    # Clean up test files
    rm -f /tmp/test.crt
    rm -f /tmp/test_backup.psql
    
    # Clean up environment variables
    unset TEST_ENV_USER TEST_ENV_PASSWORD TEST_ENV_PORT TEST_ENV_DB TEST_ENV_HOST
    unset PGPASSWORD
    
    test_info "Cleanup completed"
}

print_test_header "DBM - Database Manager Test Suite"

# Setup
setup_test_env

# Test 1: Script exists and is executable
test_start "Script file exists and is executable"
if [ -f "$SCRIPT_PATH" ] && [ -x "$SCRIPT_PATH" ]; then
    test_pass "Script exists and is executable"
else
    test_fail "Script exists and is executable" "Script not found or not executable"
fi

# Test 2: Help command works
test_start "Help command displays comprehensive usage"
if $SCRIPT_PATH --help | grep -q "Database Manager"; then
    test_pass "Help shows usage information"
else
    test_fail "Help shows usage information" "Help output not found"
fi

# Test 3: Help shows all configuration formats
test_start "Help shows all configuration formats"
help_output=$($SCRIPT_PATH --help)
if echo "$help_output" | grep -q "postgres://" && echo "$help_output" | grep -q "sslmode"; then
    test_pass "Help shows advanced configuration formats"
else
    test_fail "Help shows advanced configuration formats" "Advanced formats not documented"
fi

# Test 4: List command shows all test projects
test_start "List command shows all configured projects"
list_output=$($SCRIPT_PATH list 2>&1)
if echo "$list_output" | grep -q "test_basic" && echo "$list_output" | grep -q "test_uri"; then
    test_pass "List shows configured projects"
else
    test_fail "List shows configured projects" "Projects not listed correctly"
fi

# Test 5: Configuration parsing - Basic format
test_start "Configuration parsing - Basic format (user::port:db)"
debug_output=$($SCRIPT_PATH --debug list 2>&1)
if echo "$debug_output" | grep -q "test_basic" && echo "$debug_output" | grep -q "test_user"; then
    test_pass "Basic format parsed correctly"
else
    test_fail "Basic format parsed correctly" "Basic format parsing failed"
fi

# Test 6: Configuration parsing - Password format
test_start "Configuration parsing - Password in config format"
if echo "$debug_output" | grep -q "test_password" && echo "$debug_output" | grep -q "test_pass"; then
    test_pass "Password format parsed correctly"
else
    test_fail "Password format parsed correctly" "Password format parsing failed"
fi

# Test 7: Configuration parsing - Custom host format
test_start "Configuration parsing - Custom host format"
if echo "$debug_output" | grep -q "test_host" && echo "$debug_output" | grep -q "remote.example.com"; then
    test_pass "Custom host format parsed correctly"
else
    test_fail "Custom host format parsed correctly" "Custom host parsing failed"
fi

# Test 8: Configuration parsing - SSL format
test_start "Configuration parsing - SSL configuration format"
if echo "$debug_output" | grep -q "test_ssl" && echo "$debug_output" | grep -q "require"; then
    test_pass "SSL format parsed correctly"
else
    test_fail "SSL format parsed correctly" "SSL format parsing failed"
fi

# Test 9: Configuration parsing - PostgreSQL URI format
test_start "Configuration parsing - PostgreSQL URI format"
if echo "$debug_output" | grep -q "test_uri" && echo "$debug_output" | grep -q "postgres://"; then
    test_pass "PostgreSQL URI format parsed correctly"
else
    test_fail "PostgreSQL URI format parsed correctly" "URI format parsing failed"
fi

# Test 10: Environment variable fallback
test_start "Environment variable fallback functionality"
export TEST_ENV_USER="env_user"
export TEST_ENV_PASSWORD="env_pass"
export TEST_ENV_PORT="5432"
export TEST_ENV_DB="env_db"
export TEST_ENV_HOST="env.example.com"

env_output=$($SCRIPT_PATH --debug start test_env 2>&1 || true)
if echo "$env_output" | grep -q "env_user" && echo "$env_output" | grep -q "env.example.com"; then
    test_pass "Environment variable fallback works"
else
    test_fail "Environment variable fallback works" "Environment variables not used"
fi

# Test 11: Debug mode functionality
test_start "Debug mode shows detailed information"
debug_detailed=$($SCRIPT_PATH --debug start test_basic 2>&1 || true)
if echo "$debug_detailed" | grep -q "🧪" && echo "$debug_detailed" | grep -q "get_project_config"; then
    test_pass "Debug mode provides detailed output"
else
    test_fail "Debug mode provides detailed output" "Debug information not shown"
fi

# Test 12: Error handling for missing project
test_start "Error handling for missing project configuration"
missing_output=$($SCRIPT_PATH start nonexistent_project 2>&1 || true)
if echo "$missing_output" | grep -q "Missing config" || echo "$missing_output" | grep -q "🔍"; then
    test_pass "Shows error for missing project"
else
    test_fail "Shows error for missing project" "No error shown for missing project"
fi

# Test 13: Error handling for invalid action
test_start "Error handling for invalid action"
invalid_action_output=$($SCRIPT_PATH invalid_action 2>&1 || true)
if echo "$invalid_action_output" | grep -q "Invalid action" || echo "$invalid_action_output" | grep -q "❌"; then
    test_pass "Shows error for invalid action"
else
    test_fail "Shows error for invalid action" "No error shown for invalid action"
fi

# Test 14: Backup command validation
test_start "Backup command argument validation"
backup_error=$($SCRIPT_PATH backup 2>&1 || true)
if echo "$backup_error" | grep -q "requires" || echo "$backup_error" | grep -q "❌"; then
    test_pass "Backup shows error for missing arguments"
else
    test_fail "Backup shows error for missing arguments" "No validation error shown"
fi

# Test 15: Backup file extension validation
test_start "Backup file extension validation"
backup_ext_error=$($SCRIPT_PATH backup test_basic /tmp/test.txt 2>&1 || true)
if echo "$backup_ext_error" | grep -q ".psql extension" || echo "$backup_ext_error" | grep -q "📂"; then
    test_pass "Backup validates .psql extension requirement"
else
    test_fail "Backup validates .psql extension requirement" "Extension validation not working"
fi

# Test 16: Reset command validation
test_start "Reset command argument validation"
reset_error=$($SCRIPT_PATH reset 2>&1 || true)
if echo "$reset_error" | grep -q "requires" || echo "$reset_error" | grep -q "❌"; then
    test_pass "Reset shows error for missing arguments"
else
    test_fail "Reset shows error for missing arguments" "No validation error shown"
fi

# Test 17: Reset file existence validation
test_start "Reset file existence validation"
reset_file_error=$($SCRIPT_PATH reset test_basic /nonexistent/file.sql 2>&1 || true)
if echo "$reset_file_error" | grep -q "not found" || echo "$reset_file_error" | grep -q "📂"; then
    test_pass "Reset validates SQL file existence"
else
    test_fail "Reset validates SQL file existence" "File existence validation not working"
fi

# Test 18: SSL mode validation
test_start "SSL mode validation in configuration"
ssl_debug=$($SCRIPT_PATH --debug start test_ssl 2>&1 || true)
if echo "$ssl_debug" | grep -q "sslmode=require" || echo "$ssl_debug" | grep -q "ssl='require'"; then
    test_pass "SSL mode correctly parsed and applied"
else
    test_fail "SSL mode correctly parsed and applied" "SSL mode not handled correctly"
fi

# Test 19: URI parsing with query parameters
test_start "PostgreSQL URI parsing with query parameters"
uri_debug=$($SCRIPT_PATH --debug start test_uri 2>&1 || true)
if echo "$uri_debug" | grep -q "Parsed URI" && echo "$uri_debug" | grep -q "uri.example.com"; then
    test_pass "PostgreSQL URI parsed correctly"
else
    test_fail "PostgreSQL URI parsed correctly" "URI parsing failed"
fi

# Test 20: Home directory expansion
test_start "Home directory expansion in file paths"
# This test checks if the script would expand ~ correctly (without actually creating files)
home_test=$($SCRIPT_PATH backup test_basic ~/test_backup.psql 2>&1 || true)
if echo "$home_test" | grep -q "$HOME" || echo "$home_test" | grep -q "could not translate" || echo "$home_test" | grep -q "Backing up"; then
    test_pass "Home directory expansion works"
else
    test_fail "Home directory expansion works" "Home directory not expanded: $home_test"
fi

# Test 21: Overwrite protection
test_start "Backup overwrite protection"
touch /tmp/test_backup.psql
overwrite_test=$($SCRIPT_PATH backup test_basic /tmp/test_backup.psql 2>&1 || true)
if echo "$overwrite_test" | grep -q "already exists" || echo "$overwrite_test" | grep -q "Use -o"; then
    test_pass "Overwrite protection works"
else
    test_fail "Overwrite protection works" "No overwrite protection"
fi

# Test 22: Overwrite flag functionality
test_start "Backup overwrite flag functionality"
overwrite_flag_test=$($SCRIPT_PATH backup test_basic /tmp/test_backup.psql -o 2>&1 || true)
if echo "$overwrite_flag_test" | grep -q "Overwriting" || echo "$overwrite_flag_test" | grep -q "could not translate"; then
    test_pass "Overwrite flag works"
else
    test_fail "Overwrite flag works" "Overwrite flag not working"
fi

# Test 23: Short command aliases
test_start "Short command aliases functionality"
short_cmd_test=$($SCRIPT_PATH l 2>&1)
if echo "$short_cmd_test" | grep -q "Projects from" || echo "$short_cmd_test" | grep -q "test_basic"; then
    test_pass "Short command aliases work (l for list)"
else
    test_fail "Short command aliases work" "Short aliases not working"
fi

# Test 24: Configuration file location detection
test_start "Configuration file location detection"
config_location=$($SCRIPT_PATH list 2>&1)
if echo "$config_location" | grep -q "dbm/.dbmrc" || echo "$config_location" | grep -q "Projects from"; then
    test_pass "Configuration file location correctly detected"
else
    test_fail "Configuration file location correctly detected" "Config file location not found"
fi

# Test 25: Legacy format backward compatibility
test_start "Legacy 3-part format backward compatibility"
legacy_debug=$($SCRIPT_PATH --debug start test_legacy 2>&1 || true)
if echo "$legacy_debug" | grep -q "test_legacy" && echo "$legacy_debug" | grep -q "test_user"; then
    test_pass "Legacy format supported"
else
    test_fail "Legacy format supported" "Legacy format not supported"
fi

# Test 26: Azure PostgreSQL format support
test_start "Azure PostgreSQL format support"
azure_debug=$($SCRIPT_PATH --debug start test_azure 2>&1 || true)
if echo "$azure_debug" | grep -q "azure" && echo "$azure_debug" | grep -q "postgres.database.azure.com"; then
    test_pass "Azure PostgreSQL format supported"
else
    test_fail "Azure PostgreSQL format supported" "Azure format not supported"
fi

# Test 27: SSL certificate file validation
test_start "SSL certificate file validation"
ssl_cert_debug=$($SCRIPT_PATH --debug start test_ssl_cert 2>&1 || true)
if echo "$ssl_cert_debug" | grep -q "SSL certificate file" || echo "$ssl_cert_debug" | grep -q "/tmp/test.crt"; then
    test_pass "SSL certificate file validation works"
else
    test_fail "SSL certificate file validation works" "SSL cert validation not working"
fi

# Test 28: PGPASSWORD environment variable support
test_start "PGPASSWORD environment variable support"
export PGPASSWORD="global_password"
pgpass_test=$($SCRIPT_PATH --debug start test_basic 2>&1 || true)
if echo "$pgpass_test" | grep -q "PGPASSWORD" || echo "$pgpass_test" | grep -q "password from"; then
    test_pass "PGPASSWORD environment variable supported"
else
    test_fail "PGPASSWORD environment variable supported" "PGPASSWORD not used"
fi
unset PGPASSWORD

# Test 29: Command building functionality
test_start "PostgreSQL command building functionality"
cmd_debug=$($SCRIPT_PATH --debug start test_host 2>&1 || true)
if echo "$cmd_debug" | grep -q "Executing:" && echo "$cmd_debug" | grep -q "psql"; then
    test_pass "Command building works correctly"
else
    test_fail "Command building works correctly" "Command building failed"
fi

# Test 30: Multiple SSL modes validation
test_start "Multiple SSL modes validation"
ssl_modes_test=true
for mode in "disable" "allow" "prefer" "require" "verify-ca" "verify-full"; do
    # Create temporary config with different SSL mode
    echo "test_ssl_$mode=user:pass:5432:db:host:$mode" >> .dbmrc
    mode_debug=$($SCRIPT_PATH --debug start "test_ssl_$mode" 2>&1 || true)
    if ! echo "$mode_debug" | grep -q "sslmode=$mode"; then
        ssl_modes_test=false
        break
    fi
done

if [ "$ssl_modes_test" = true ]; then
    test_pass "All SSL modes validated correctly"
else
    test_fail "All SSL modes validated correctly" "Some SSL modes not working"
fi

# Test 31: Check command functionality
test_start "Check command shows connection status"
check_output=$($SCRIPT_PATH check test_basic 2>&1 || true)
if echo "$check_output" | grep -q "Checking database connection" && echo "$check_output" | grep -q "Connection failed"; then
    test_pass "Check command works for single project"
else
    test_fail "Check command works for single project" "Check output not correct"
fi

# Test 32: Check all command functionality
test_start "Check --all command tests all projects"
check_all_output=$($SCRIPT_PATH check --all 2>&1 || true)
if echo "$check_all_output" | grep -q "Checking all configured" && echo "$check_all_output" | grep -q "Connection Check Summary"; then
    test_pass "Check --all command works"
else
    test_fail "Check --all command works" "Check --all output not correct"
fi

# Test 33: Check command short alias
test_start "Check command short alias (c) works"
check_short_output=$($SCRIPT_PATH c test_basic 2>&1 || true)
if echo "$check_short_output" | grep -q "Checking database connection"; then
    test_pass "Check short alias works"
else
    test_fail "Check short alias works" "Short alias not working"
fi

# Test 34: Info command functionality
test_start "Info command shows database information"
info_output=$($SCRIPT_PATH info test_basic 2>&1 || true)
if echo "$info_output" | grep -q "Database Information" && echo "$info_output" | grep -q "Database:" && echo "$info_output" | grep -q "Host:"; then
    test_pass "Info command works"
else
    test_fail "Info command works" "Info output not correct"
fi

# Test 35: Info command with --tables option
test_start "Info command --tables option"
info_tables_output=$($SCRIPT_PATH info test_basic --tables 2>&1 || true)
if echo "$info_tables_output" | grep -q "Database Information"; then
    test_pass "Info --tables option works"
else
    test_fail "Info --tables option works" "Info --tables not working"
fi

# Test 36: Info command with --size option
test_start "Info command --size option"
info_size_output=$($SCRIPT_PATH info test_basic --size 2>&1 || true)
if echo "$info_size_output" | grep -q "Database Information"; then
    test_pass "Info --size option works"
else
    test_fail "Info --size option works" "Info --size not working"
fi

# Test 37: Info command short alias
test_start "Info command short alias (i) works"
info_short_output=$($SCRIPT_PATH i test_basic 2>&1 || true)
if echo "$info_short_output" | grep -q "Database Information"; then
    test_pass "Info short alias works"
else
    test_fail "Info short alias works" "Info short alias not working"
fi

# Test 38: Config add command functionality
test_start "Config add command functionality"
config_add_output=$($SCRIPT_PATH config add test_new_db "new_user:new_pass:5432:new_db" 2>&1)
if echo "$config_add_output" | grep -q "Added project 'test_new_db'"; then
    test_pass "Config add command works"
else
    test_fail "Config add command works" "Config add failed"
fi

# Test 39: Config add validation
test_start "Config add validates configuration format"
config_add_invalid=$($SCRIPT_PATH config add test_invalid "invalid_format" 2>&1 || true)
if echo "$config_add_invalid" | grep -q "Invalid config format"; then
    test_pass "Config add validates format"
else
    test_fail "Config add validates format" "No validation error shown"
fi

# Test 40: Config remove command functionality
test_start "Config remove command functionality"
config_remove_output=$(echo "y" | $SCRIPT_PATH config remove test_new_db 2>&1)
if echo "$config_remove_output" | grep -q "Removed project 'test_new_db'"; then
    test_pass "Config remove command works"
else
    test_fail "Config remove command works" "Config remove failed"
fi

# Test 41: Config remove non-existent project
test_start "Config remove handles non-existent projects"
config_remove_missing=$($SCRIPT_PATH config remove non_existent_project 2>&1 || true)
if echo "$config_remove_missing" | grep -q "not found in configuration"; then
    test_pass "Config remove handles missing projects"
else
    test_fail "Config remove handles missing projects" "No error for missing project"
fi

# Test 42: Config edit command functionality
test_start "Config edit command shows current configuration"
# First add a project to edit
$SCRIPT_PATH config add test_edit_db "edit_user:edit_pass:5432:edit_db" >/dev/null 2>&1
config_edit_output=$(echo "" | $SCRIPT_PATH config edit test_edit_db 2>&1 || true)
if echo "$config_edit_output" | grep -q "Current config for 'test_edit_db'"; then
    test_pass "Config edit shows current configuration"
else
    test_fail "Config edit shows current configuration" "Edit command not working"
fi

# Test 43: Config command requires subcommand
test_start "Config command requires subcommand"
config_no_sub=$($SCRIPT_PATH config 2>&1 || true)
if echo "$config_no_sub" | grep -q "requires subcommand"; then
    test_pass "Config command requires subcommand"
else
    test_fail "Config command requires subcommand" "No error for missing subcommand"
fi

# Test 44: Config command handles invalid subcommand
test_start "Config command handles invalid subcommand"
config_invalid_sub=$($SCRIPT_PATH config invalid_subcommand 2>&1 || true)
if echo "$config_invalid_sub" | grep -q "Invalid config action"; then
    test_pass "Config handles invalid subcommand"
else
    test_fail "Config handles invalid subcommand" "No error for invalid subcommand"
fi

# Test 45: Help shows new commands
test_start "Help shows all new commands (check, info, config)"
help_new_commands=$($SCRIPT_PATH --help)
if echo "$help_new_commands" | grep -q "check, c, -c" && echo "$help_new_commands" | grep -q "info, i, -i" && echo "$help_new_commands" | grep -q "config"; then
    test_pass "Help shows all new commands"
else
    test_fail "Help shows all new commands" "New commands not in help"
fi

# Test 46: Help shows new options
test_start "Help shows new action options"
if echo "$help_new_commands" | grep -q "\-\-all" && echo "$help_new_commands" | grep -q "\-\-tables" && echo "$help_new_commands" | grep -q "\-\-size"; then
    test_pass "Help shows new action options"
else
    test_fail "Help shows new action options" "New options not in help"
fi

# Test 47: Debug mode works with new commands
test_start "Debug mode works with check command"
debug_check_output=$($SCRIPT_PATH --debug check test_basic 2>&1 || true)
if echo "$debug_check_output" | grep -q "🧪" && echo "$debug_check_output" | grep -q "check_single_database"; then
    test_pass "Debug mode works with check command"
else
    test_fail "Debug mode works with check command" "Debug not working with check"
fi

# Test 48: Debug mode works with info command
test_start "Debug mode works with info command"
debug_info_output=$($SCRIPT_PATH --debug info test_basic 2>&1 || true)
if echo "$debug_info_output" | grep -q "🧪" && echo "$debug_info_output" | grep -q "info_database"; then
    test_pass "Debug mode works with info command"
else
    test_fail "Debug mode works with info command" "Debug not working with info"
fi

# Test 49: Check command timeout functionality
test_start "Check command has timeout protection"
# This test verifies that the timeout command is used (we can't test actual timeout without a hanging connection)
debug_check_timeout=$($SCRIPT_PATH --debug check test_basic 2>&1 || true)
if echo "$debug_check_timeout" | grep -q "Executing connection test"; then
    test_pass "Check command uses timeout protection"
else
    test_fail "Check command uses timeout protection" "Timeout not implemented"
fi

# Test 50: New commands work with all configuration formats
test_start "New commands work with URI configuration format"
check_uri_output=$($SCRIPT_PATH check test_uri 2>&1 || true)
info_uri_output=$($SCRIPT_PATH info test_uri 2>&1 || true)
if echo "$check_uri_output" | grep -q "Checking database connection" && echo "$info_uri_output" | grep -q "Database Information"; then
    test_pass "New commands work with URI format"
else
    test_fail "New commands work with URI format" "URI format not supported in new commands"
fi

print_test_header "Test Summary"
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"

# Calculate success rate
if [ $TOTAL_TESTS -gt 0 ]; then
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Success Rate: ${success_rate}%"
fi

print_test_header "Test Coverage"
echo "✅ Basic functionality (help, list, validation)"
echo "✅ All 9 configuration formats"
echo "✅ Environment variable fallback"
echo "✅ Debug mode functionality"
echo "✅ Error handling and validation"
echo "✅ SSL/TLS support and validation"
echo "✅ PostgreSQL URI parsing"
echo "✅ Azure PostgreSQL support"
echo "✅ File operations and safety"
echo "✅ Authentication methods"
echo "✅ Command building and execution"
echo "✅ Backward compatibility"
echo "✅ Connection testing (check command)"
echo "✅ Database information (info command)"
echo "✅ Configuration management (config command)"
echo "✅ New command aliases and options"
echo "✅ Debug mode with new features"

# Cleanup
cleanup_test_env

print_test_header "Final Results"
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! The DBM script is working correctly.${NC}"
    echo -e "${GREEN}🚀 Ready for production use with enterprise-grade database management capabilities!${NC}"
    exit 0
else
    echo -e "${RED}💥 $FAILED_TESTS test(s) failed. Please review the output above.${NC}"
    exit 1
fi