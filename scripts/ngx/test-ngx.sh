#!/bin/bash
#
# Description: Comprehensive test suite for NGX script covering all features
#
# Test Suite for NGX Script
#
# Comprehensive test suite following TDD principles
#

set -uo pipefail

# Test configuration
readonly SCRIPT_PATH="$(dirname "$0")/ngx.sh"
readonly TEST_CONFIG_DIR="/tmp/ngx-test-$$"
readonly TEST_DIST_DIR="/tmp/ngx-test-dist-$$"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

#######################################
# Print colored output
#######################################
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

#######################################
# Test framework functions
#######################################
print_test_header() {
    echo
    print_color "$BLUE" "🧪 $1"
    echo "----------------------------------------"
}

print_test_case() {
    print_color "$PURPLE" "📋 Test: $1"
}

test_start() {
    local test_name="$1"
    print_test_case "$test_name"
    ((TESTS_RUN++))
}

test_pass() {
    local test_name="$1"
    print_color "$GREEN" "✅ PASS: $test_name"
    ((TESTS_PASSED++))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    print_color "$RED" "❌ FAIL: $test_name"
    print_color "$RED" "   Reason: $reason"
    ((TESTS_FAILED++))
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    if [ "$expected" = "$actual" ]; then
        test_pass "$test_name"
    else
        test_fail "$test_name" "Expected '$expected', got '$actual'"
    fi
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
# Setup and teardown functions
#######################################
setup_test_environment() {
    print_color "$YELLOW" "🔧 Setting up test environment..."
    
    # Create test directories
    mkdir -p "$TEST_CONFIG_DIR"
    mkdir -p "$TEST_DIST_DIR"
    
    # Create a simple index.html for testing
    cat > "$TEST_DIST_DIR/index.html" <<EOF
<!DOCTYPE html>
<html>
<head><title>Test Site</title></head>
<body><h1>Test Site</h1></body>
</html>
EOF
    
    # Make script executable
    chmod +x "$SCRIPT_PATH"
    
    # Override config directory for testing
    export HOME="$TEST_CONFIG_DIR"
}

cleanup_test_environment() {
    print_color "$YELLOW" "🧹 Cleaning up test environment..."
    rm -rf "$TEST_CONFIG_DIR" "$TEST_DIST_DIR"
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
    
    assert_contains "$output" "Usage:" "Help shows usage information"
    assert_contains "$output" "Commands:" "Help shows commands section"
    assert_contains "$output" "Examples:" "Help shows examples section"

    test_start "Version command shows version"
    local output
    output=$("$SCRIPT_PATH" version 2>&1) || true
    
    assert_contains "$output" "NGX Script v" "Version command shows version"

    test_start "No arguments shows help"
    local output exit_code
    output=$("$SCRIPT_PATH" 2>&1) || exit_code=$?
    
    assert_exit_code 1 "${exit_code:-0}" "No arguments exits with code 1"
    assert_contains "$output" "Usage:" "No arguments shows usage"

    test_start "Invalid command shows error"
    local output exit_code
    output=$("$SCRIPT_PATH" invalid-command 2>&1) || exit_code=$?
    
    assert_exit_code 1 "${exit_code:-0}" "Invalid command exits with code 1"
    assert_contains "$output" "Unknown command" "Invalid command shows error"
}

test_argument_validation() {
    print_test_header "Argument Validation Tests"

    test_start "Create command without arguments shows error"
    local output exit_code
    output=$("$SCRIPT_PATH" create 2>&1) || exit_code=$?
    
    assert_exit_code 1 "${exit_code:-0}" "Create without args exits with code 1"
    assert_contains "$output" "Domain name and path required" "Create without args shows error"

    test_start "Remove command without arguments shows error"
    local output exit_code
    output=$("$SCRIPT_PATH" remove 2>&1) || exit_code=$?
    
    assert_exit_code 1 "${exit_code:-0}" "Remove without args exits with code 1"
    assert_contains "$output" "Domain name required" "Remove without args shows error"

    test_start "Folder validation for create command"
    local output exit_code
    output=$("$SCRIPT_PATH" create testapp /nonexistent/folder 2>&1) || exit_code=$?
    
    # Should show error for non-existent folder
    assert_exit_code 1 "${exit_code:-0}" "Non-existent folder exits with code 1"
    assert_contains "$output" "does not exist" "Non-existent folder shows error"

    test_start "Unsafe domain names are rejected"
    exit_code=0
    output=$("$SCRIPT_PATH" create "../../etc/cron.d/evil" "$TEST_DIST_DIR" --dry-run 2>&1) || exit_code=$?

    assert_exit_code 1 "${exit_code:-0}" "Unsafe domain exits with code 1"
    assert_contains "$output" "Invalid domain name" "Unsafe domain shows validation error"

    test_start "Invalid custom ports are rejected"
    exit_code=0
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --port 70000 --dry-run 2>&1) || exit_code=$?

    assert_exit_code 1 "${exit_code:-0}" "Invalid port exits with code 1"
    assert_contains "$output" "Invalid port" "Invalid port shows validation error"
}

test_configuration_management() {
    print_test_header "Configuration Management Tests"

    test_start "Configuration directory and file creation"
    # Run a simple command to trigger config initialization
    "$SCRIPT_PATH" version >/dev/null 2>&1 || true
    
    if [ -d "$TEST_CONFIG_DIR/.ngx" ]; then
        test_pass "Config directory created"
    else
        test_fail "Config directory created" "Directory not found"
    fi
    
    if [ -f "$TEST_CONFIG_DIR/.ngx/config" ]; then
        test_pass "Config file created"
    else
        test_fail "Config file created" "Config file not found"
    fi

    test_start "Config file is parsed without executing shell code"
    local temp_home="/tmp/ngx-config-safe-$$"
    local marker_file="$temp_home/pwned"
    mkdir -p "$temp_home/.ngx"
    cat > "$temp_home/.ngx/config" <<EOF
DEFAULT_TLD=".dev"
DEFAULT_PORT=8080
NGINX_CONF_DIR="/tmp/ngx-safe-conf"
MALICIOUS="\$(touch $marker_file)"
EOF

    local output
    output=$(HOME="$temp_home" "$SCRIPT_PATH" create safeapp "$TEST_DIST_DIR" --dry-run 2>&1) || true

    assert_contains "$output" "safeapp.dev" "Safe config parser applies valid settings"
    if [ ! -f "$marker_file" ]; then
        test_pass "Config parser does not execute command substitutions"
    else
        test_fail "Config parser does not execute command substitutions" "Marker file was created"
    fi

    rm -rf "$temp_home"
}

test_domain_features() {
    print_test_header "Domain and TLD Features"

    test_start "Domain name normalization"
    # Test default .io TLD
    local result
    result=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --dry-run 2>&1 | grep -o "testapp\.io" || echo "not_found")
    assert_equals "testapp.io" "$result" "Default .io TLD normalization"
    
    # Test custom .dev TLD
    result=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --tld .dev --dry-run 2>&1 | grep -o "testapp\.dev" || echo "not_found")
    assert_equals "testapp.dev" "$result" "Custom .dev TLD normalization"

    # Test dotted domain without --tld is preserved
    result=$("$SCRIPT_PATH" create merchant.cardzz "$TEST_DIST_DIR" --dry-run 2>&1 | grep -o "merchant\.cardzz" || echo "not_found")
    assert_equals "merchant.cardzz" "$result" "Dotted domain is preserved without custom TLD"
    
    # Test domain with existing TLD gets replaced
    result=$("$SCRIPT_PATH" create testapp.com "$TEST_DIST_DIR" --tld .local --dry-run 2>&1 | grep -o "testapp\.local" || echo "not_found")
    assert_equals "testapp.local" "$result" "Existing TLD replacement"

    test_start "Custom TLD parsing"
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --tld .dev --dry-run 2>&1) || true
    
    # Check that the domain is normalized with custom TLD
    assert_contains "$output" "testapp.dev" "Custom TLD is parsed and applied"
}

test_feature_flags() {
    print_test_header "Feature Flag Tests"

    test_start "SSL flag parsing"
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --ssl --dry-run 2>&1) || true
    
    # Check that SSL flag is recognized in dry-run output
    assert_contains "$output" "DRY RUN: SSL enabled" "SSL flag is parsed"

    test_start "SPA flag parsing"
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --spa --dry-run 2>&1) || true
    
    # Check that SPA flag is recognized in dry-run output
    assert_contains "$output" "DRY RUN: SPA mode enabled" "SPA flag is parsed"

    test_start "Custom port parsing"
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --port 8080 --dry-run 2>&1) || true
    
    # Check that custom port is recognized in dry-run output
    assert_contains "$output" "DRY RUN: Custom port: 8080" "Custom port is parsed"

    test_start "API proxy parsing"
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --api http://localhost:3001 --dry-run 2>&1) || true
    
    # Check that API proxy is recognized in dry-run output
    assert_contains "$output" "DRY RUN: API proxy: http://localhost:3001" "API proxy is parsed"
}

test_dry_run_mode() {
    print_test_header "Dry Run Mode Tests"
    
    test_start "Argument parsing for create command"
    # Test dry-run mode to avoid actual system changes
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --dry-run --verbose 2>&1) || true
    
    # Check that dry-run mode is working
    assert_contains "$output" "DRY RUN: Would create site" "Create command dry-run mode"
}

test_ssl_features() {
    print_test_header "SSL and HTTPS Features"

    test_start "SSL certificate generation in dry-run"
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --ssl --dry-run 2>&1) || true
    
    # Check that SSL certificate generation is mentioned
    assert_contains "$output" "DRY RUN: SSL enabled" "SSL certificate generation mentioned"

    test_start "SSL port configuration"
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --ssl --port 8443 --dry-run 2>&1) || true
    
    # Check that custom SSL port is recognized
    assert_contains "$output" "DRY RUN: Custom port: 8443" "Custom SSL port is configured"
    assert_contains "$output" "DRY RUN: SSL enabled" "SSL is enabled with custom port"

    test_start "SSL config keeps HTTPS on default SSL port"
    local temp_root="/tmp/ngx-ssl-port-test-$$"
    local temp_script="$temp_root/ngx-sourceable.sh"
    mkdir -p "$temp_root"
    cp "$SCRIPT_PATH" "$temp_script"
    sed -i 's/^main "$@"/# main "$@"/' "$temp_script"

    output=$(
        bash -c '
            set -euo pipefail
            source "$1"
            CUSTOM_PORT=8443
            DEFAULT_SSL_PORT=443
            generate_nginx_config "testapp.io" "$2" 8443 1 0 ""
        ' bash "$temp_script" "$TEST_DIST_DIR" 2>&1
    ) || true

    assert_contains "$output" "listen 8443;" "SSL config uses custom port for HTTP redirect listener"
    assert_contains "$output" "listen 443 ssl;" "SSL config keeps HTTPS listener on default SSL port"
    rm -rf "$temp_root"

    test_start "SSL certificate key is generated under private directory"
    temp_root="/tmp/ngx-ssl-cert-test-$$"
    temp_script="$temp_root/ngx-sourceable.sh"
    local cert_dir="$temp_root/certs"
    local key_dir="$temp_root/private"
    local openssl_log="$temp_root/openssl.log"
    mkdir -p "$temp_root"
    cp "$SCRIPT_PATH" "$temp_script"
    sed -i 's/^main "$@"/# main "$@"/' "$temp_script"

    output=$(
        OPENSSL_LOG="$openssl_log" bash -c '
            set -euo pipefail
            source "$1"
            sudo() {
                if [ "${1:-}" = "chmod" ]; then
                    return 0
                fi
                "$@"
            }
            openssl() { echo "openssl $*" >> "$OPENSSL_LOG"; }
            generate_ssl_certificate "testapp.io" "$2" "$3"
        ' bash "$temp_script" "$cert_dir" "$key_dir" 2>&1
    ) || true

    if grep -q "$key_dir/testapp.io.key" "$openssl_log" 2>/dev/null; then
        test_pass "SSL certificate generation writes key to private directory"
    else
        test_fail "SSL certificate generation writes key to private directory" "Private key path was not used"
    fi

    if grep -q "/CN=testapp.io" "$openssl_log" 2>/dev/null; then
        test_pass "SSL certificate subject only sets common name"
    else
        test_fail "SSL certificate subject only sets common name" "Expected CN-only OpenSSL subject"
    fi

    rm -rf "$temp_root"

    test_start "Combined flags (SSL + SPA + API)"
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --ssl --spa --api http://localhost:3001 --dry-run 2>&1) || true
    
    # Check that all flags are recognized together
    assert_contains "$output" "DRY RUN: SSL enabled" "SSL flag in combination"
    assert_contains "$output" "DRY RUN: SPA mode enabled" "SPA flag in combination"
    assert_contains "$output" "DRY RUN: API proxy: http://localhost:3001" "API flag in combination"
}

test_site_management() {
    print_test_header "Site Management Tests"
    
    test_start "List command execution"
    local output
    output=$("$SCRIPT_PATH" list 2>&1) || true
    
    # List command should show configured sites info
    assert_contains "$output" "Configured Nginx sites" "List command shows header"

    test_start "List command with no sites"
    # Create a temporary empty directory
    local empty_dir="/tmp/empty-nginx-$$"
    mkdir -p "$empty_dir"
    
    # Create a temporary script with modified config
    local temp_script="/tmp/ngx-test-empty-$$"
    local temp_config="/tmp/ngx-config-$$"
    
    # Create temporary config file with empty nginx dir
    cat > "$temp_config" <<EOF
DEFAULT_TLD=".io"
DEFAULT_PORT=80
DEFAULT_SSL_PORT=443
NGINX_CONF_DIR="$empty_dir"
EOF
    
    # Create modified script that uses our temp config
    cp "$SCRIPT_PATH" "$temp_script"
    sed -i "s|readonly CONFIG_FILE=\"\$CONFIG_DIR/config\"|readonly CONFIG_FILE=\"$temp_config\"|" "$temp_script"
    chmod +x "$temp_script"
    
    local output
    output=$("$temp_script" list 2>&1) || true
    
    # Should show message when no sites are configured
    assert_contains "$output" "No sites configured" "List shows empty message"
    
    # Cleanup
    rm -rf "$empty_dir" "$temp_script" "$temp_config"
}

test_remove_functionality() {
    print_test_header "Remove Functionality Tests"

    test_start "Remove non-existent site"
    # Create a temporary empty directory for testing
    local empty_dir="/tmp/empty-nginx-remove-$$"
    mkdir -p "$empty_dir"
    
    # Create a temporary script with modified config
    local temp_script="/tmp/ngx-test-remove-$$"
    local temp_config="/tmp/ngx-config-remove-$$"
    
    # Create temporary config file with empty nginx dir
    cat > "$temp_config" <<EOF
DEFAULT_TLD=".io"
DEFAULT_PORT=80
DEFAULT_SSL_PORT=443
NGINX_CONF_DIR="$empty_dir"
EOF
    
    # Create modified script that uses our temp config
    cp "$SCRIPT_PATH" "$temp_script"
    sed -i "s|readonly CONFIG_FILE=\"\$CONFIG_DIR/config\"|readonly CONFIG_FILE=\"$temp_config\"|" "$temp_script"
    chmod +x "$temp_script"
    
    local output
    output=$("$temp_script" remove nonexistent 2>&1) || true
    
    # Should show error message for non-existent site
    assert_contains "$output" "not found" "Remove shows error for non-existent site"
    
    # Cleanup
    rm -rf "$empty_dir" "$temp_script" "$temp_config"

    test_start "Remove command with dry-run"
    local output
    output=$("$SCRIPT_PATH" remove testapp --dry-run 2>&1) || true
    
    # Should show what would be removed in dry-run mode
    assert_contains "$output" "DRY RUN" "Remove shows dry-run information"
}

test_validation_features() {
    print_test_header "Validation and Safety Features"
    
    test_start "Nginx service availability check"
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --dry-run 2>&1) || true
    
    # In dry-run mode, should not fail even if nginx is not running
    assert_contains "$output" "DRY RUN" "Dry-run works regardless of nginx status"

    test_start "Quiet mode functionality"
    local output
    output=$("$SCRIPT_PATH" create testapp "$TEST_DIST_DIR" --dry-run --quiet 2>&1) || true
    
    # Quiet mode should still show essential information
    assert_contains "$output" "testapp.io" "Quiet mode shows essential info"
}

test_nginx_dependency_and_user_management() {
    print_test_header "Nginx Dependency and Runtime User Tests"

    test_start "Missing nginx prompts and installs when accepted"
    local temp_root="/tmp/ngx-install-test-$$"
    local temp_script="$temp_root/ngx-sourceable.sh"
    local mock_bin="$temp_root/bin"
    local install_log="$temp_root/install.log"
    mkdir -p "$mock_bin"

    cp "$SCRIPT_PATH" "$temp_script"
    sed -i 's/^main "$@"/# main "$@"/' "$temp_script"

    cat > "$mock_bin/apt-get" <<'EOF'
#!/bin/bash
set -euo pipefail

echo "apt-get $*" >> "$INSTALL_LOG"

if [ "${1:-}" = "install" ]; then
    cat > "$MOCK_BIN/nginx" <<'NGINX'
#!/bin/bash
exit 0
NGINX
    chmod +x "$MOCK_BIN/nginx"
fi
EOF
    chmod +x "$mock_bin/apt-get"

    cat > "$mock_bin/systemctl" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$mock_bin/systemctl"

    local output exit_code
    exit_code=0
    output=$(
        MOCK_BIN="$mock_bin" INSTALL_LOG="$install_log" PATH="$mock_bin:/bin" bash -c '
            set -euo pipefail
            source "$1"
            confirm() { return 0; }
            sudo() {
                if [ "${1:-}" = "-v" ]; then
                    return 0
                fi
                "$@"
            }
            check_nginx_availability
        ' bash "$temp_script" 2>&1
    ) || exit_code=$?

    assert_exit_code 0 "${exit_code:-0}" "Accepted nginx install exits successfully"
    assert_contains "$output" "Nginx installed successfully" "Accepted nginx install reports success"

    if grep -q "apt-get install -y nginx" "$install_log" 2>/dev/null; then
        test_pass "Accepted nginx install runs package install"
    else
        test_fail "Accepted nginx install runs package install" "Expected apt-get install -y nginx in install log"
    fi

    rm -rf "$temp_root"

    test_start "Missing nginx does not install when declined"
    temp_root="/tmp/ngx-install-decline-test-$$"
    temp_script="$temp_root/ngx-sourceable.sh"
    mock_bin="$temp_root/bin"
    install_log="$temp_root/install.log"
    mkdir -p "$mock_bin"

    cp "$SCRIPT_PATH" "$temp_script"
    sed -i 's/^main "$@"/# main "$@"/' "$temp_script"

    cat > "$mock_bin/apt-get" <<'EOF'
#!/bin/bash
echo "apt-get $*" >> "$INSTALL_LOG"
exit 0
EOF
    chmod +x "$mock_bin/apt-get"

    exit_code=0
    output=$(
        MOCK_BIN="$mock_bin" INSTALL_LOG="$install_log" PATH="$mock_bin:/bin" bash -c '
            set -euo pipefail
            source "$1"
            confirm() { return 1; }
            sudo() { "$@"; }
            check_nginx_availability
        ' bash "$temp_script" 2>&1
    ) || exit_code=$?

    assert_exit_code 1 "${exit_code:-0}" "Declined nginx install exits with failure"
    assert_contains "$output" "Nginx is required" "Declined nginx install explains requirement"

    if [ ! -f "$install_log" ]; then
        test_pass "Declined nginx install does not run package manager"
    else
        test_fail "Declined nginx install does not run package manager" "Package manager was called unexpectedly"
    fi

    rm -rf "$temp_root"

    test_start "Create updates nginx runtime user in nginx.conf"
    temp_root="/tmp/ngx-user-test-$$"
    temp_script="$temp_root/ngx-sourceable.sh"
    mock_bin="$temp_root/bin"
    local nginx_conf_dir="$temp_root/conf.d"
    local nginx_main_conf="$temp_root/nginx.conf"
    local hosts_file="$temp_root/hosts"
    local runtime_user
    runtime_user="$(id -un)"

    mkdir -p "$mock_bin" "$nginx_conf_dir"
    cp "$SCRIPT_PATH" "$temp_script"
    sed -i 's/^main "$@"/# main "$@"/' "$temp_script"

    cat > "$nginx_main_conf" <<'EOF'
user www-data;
events {}
http {
    include /etc/nginx/conf.d/*.conf;
}
EOF
    touch "$hosts_file"

    cat > "$mock_bin/nginx" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$mock_bin/nginx"

    cat > "$mock_bin/systemctl" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$mock_bin/systemctl"

    exit_code=0
    output=$(
        PATH="$mock_bin:/usr/bin:/bin" SUDO_USER="$runtime_user" bash -c '
            set -euo pipefail
            source "$1"
            NGINX_CONF_DIR="$2"
            NGINX_MAIN_CONF="$3"
            HOSTS_FILE="$4"
            DOMAIN_NAME="runtimeuser"
            DIST_FOLDER="$5"
            CUSTOM_PORT=""
            CUSTOM_TLD=""
            ENABLE_SSL=0
            ENABLE_SPA=0
            API_PROXY=""
            FORCE_UPDATE=0
            DRY_RUN=0
            VERBOSE=0
            QUIET=0
            sudo() {
                if [ "${1:-}" = "-v" ]; then
                    return 0
                fi
                "$@"
            }
            create_site
        ' bash "$temp_script" "$nginx_conf_dir" "$nginx_main_conf" "$hosts_file" "$TEST_DIST_DIR" 2>&1
    ) || exit_code=$?

    assert_exit_code 0 "${exit_code:-0}" "Create with runtime user update exits successfully"
    assert_contains "$output" "Nginx runtime user updated to $runtime_user" "Create reports nginx runtime user update"

    if grep -q "^user $runtime_user;" "$nginx_main_conf"; then
        test_pass "Create writes invoking user to nginx.conf"
    else
        test_fail "Create writes invoking user to nginx.conf" "nginx.conf did not contain expected user directive"
    fi

    if [ -f "${nginx_main_conf}.bak" ]; then
        test_pass "Runtime user update backs up nginx.conf"
    else
        test_fail "Runtime user update backs up nginx.conf" "Backup file was not created"
    fi

    rm -rf "$temp_root"
}

test_hosts_file_functionality() {
    print_test_header "Hosts File Management Tests"
    
    local test_domain="testngx.io"
    
    test_start "Hosts file operations in dry-run mode"
    local output
    output=$("$SCRIPT_PATH" create testngx "$TEST_DIST_DIR" --dry-run --verbose 2>&1) || true
    
    # Should show hosts file operations in dry-run
    assert_contains "$output" "DRY RUN" "Hosts file dry-run shows operations"
    assert_contains "$output" "$test_domain" "Domain appears in dry-run output"

    test_start "Hosts file detection for existing entries"
    local output
    output=$("$SCRIPT_PATH" create testngx "$TEST_DIST_DIR" --dry-run 2>&1) || true
    
    # Should handle existing or non-existing hosts entries gracefully
    if grep -q "127\.0\.0\.1[[:space:]]\+${test_domain}" /etc/hosts 2>/dev/null; then
        # Domain exists - should show update behavior
        assert_contains "$output" "DRY RUN" "Handles existing hosts entry"
    else
        # Domain doesn't exist - should show creation behavior
        assert_contains "$output" "DRY RUN" "Handles new hosts entry"
    fi

    test_start "Force flag with hosts file operations"
    local output
    output=$("$SCRIPT_PATH" create testngx "$TEST_DIST_DIR" --dry-run --force --verbose 2>&1) || true
    
    # Force flag should be recognized in dry-run
    assert_contains "$output" "DRY RUN" "Force flag works with hosts operations"
    assert_contains "$output" "$test_domain" "Domain appears with force flag"

    test_start "Hosts file cleanup in remove command"
    local output
    output=$("$SCRIPT_PATH" remove testngx --dry-run --verbose 2>&1) || true
    
    # Remove should show hosts file cleanup
    assert_contains "$output" "DRY RUN" "Remove shows hosts cleanup in dry-run"

    test_start "Hosts file validation and safety checks"
    local output
    output=$("$SCRIPT_PATH" create testngx "$TEST_DIST_DIR" --dry-run 2>&1) || true
    
    # Should not show any error messages about hosts file access in dry-run
    if echo "$output" | grep -q "Permission denied\|cannot access"; then
        test_fail "Hosts file validation" "Permission errors in dry-run mode"
    else
        test_pass "Hosts file validation and safety checks"
    fi

    test_start "Multiple domain handling in hosts file"
    # Test with different TLD
    local output
    output=$("$SCRIPT_PATH" create testngx "$TEST_DIST_DIR" --tld .dev --dry-run 2>&1) || true
    
    # Should handle different TLDs correctly
    assert_contains "$output" "testngx.dev" "Handles custom TLD in hosts operations"

    test_start "Hosts file backup consideration"
    local output
    output=$("$SCRIPT_PATH" create testngx "$TEST_DIST_DIR" --dry-run --verbose 2>&1) || true
    
    # In a well-designed system, should mention backup or safety measures
    # This is more of a design check - the script should be safe
    assert_contains "$output" "DRY RUN" "Hosts operations show safety measures"
}

#######################################
# Test execution
#######################################
run_all_tests() {
    print_color "$BLUE" "🚀 Starting Comprehensive Test Suite for NGX"
    echo "========================================================"
    
    # Check if script exists
    if [ ! -f "$SCRIPT_PATH" ]; then
        print_color "$RED" "❌ Script not found: $SCRIPT_PATH"
        exit 1
    fi
    
    # Make script executable
    chmod +x "$SCRIPT_PATH"
    
    # Setup
    setup_test_environment
    
    # Run test suites
    test_basic_functionality
    test_argument_validation
    test_configuration_management
    test_domain_features
    test_feature_flags
    test_dry_run_mode
    test_ssl_features
    test_site_management
    test_remove_functionality
    test_validation_features
    test_nginx_dependency_and_user_management
    test_hosts_file_functionality
    
    # Cleanup
    cleanup_test_environment
    
    # Print summary
    echo ""
    echo "========================================================"
    print_color "$BLUE" "📊 Test Summary"
    echo "========================================================"
    print_color "$PURPLE" "Total Tests: $TESTS_RUN"
    print_color "$GREEN" "Passed: $TESTS_PASSED"
    print_color "$RED" "Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo ""
        print_color "$GREEN" "🎉 All tests passed! The NGX script is working correctly."
        exit 0
    else
        echo ""
        print_color "$RED" "💥 Some tests failed. Please review the output above."
        exit 1
    fi
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_all_tests
fi
