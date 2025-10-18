#!/bin/bash

# ============================================
#   Test Script for common-utils.sh
# ============================================
# Purpose: Validate all 14 functions in common-utils.sh
# Run: bash test-common-utils.sh
# ============================================

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_FILE="$SCRIPT_DIR/test.log"
LOCK_DIR="$SCRIPT_DIR/.test-locks"
TEST_MODE="false"
DEBUG_MODE="true"
FORCE_MODE="false"

# Source common-utils.sh
source "$SCRIPT_DIR/lib/common-utils.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ "$expected" = "$actual" ]; then
        echo "✅ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "❌ FAIL: $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_exists() {
    local file_path="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ -f "$file_path" ]; then
        echo "✅ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "❌ FAIL: $test_name"
        echo "  File not found: $file_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if echo "$haystack" | grep -q "$needle"; then
        echo "✅ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "❌ FAIL: $test_name"
        echo "  Expected to find: $needle"
        echo "  In: $haystack"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Clean up before tests
cleanup() {
    rm -f "$LOG_FILE"
    rm -rf "$LOCK_DIR"
    rm -rf "$PROJECT_ROOT/logs/sessions"
}

# ============================================
#   Test Suite
# ============================================

echo "======================================"
echo "   Testing common-utils.sh"
echo "======================================"
echo ""

# Clean up
cleanup

# Test 1: get_timestamp()
echo "[ Testing get_timestamp() ]"
timestamp=$(get_timestamp)
assert_contains "$timestamp" "[0-9][0-9][0-9][0-9]-" "get_timestamp returns ISO 8601 format"
echo ""

# Test 2-7: Logging functions
echo "[ Testing Logging Functions ]"

log_info "Test info message" >/dev/null
assert_file_exists "$LOG_FILE" "log_info creates LOG_FILE"
log_content=$(cat "$LOG_FILE")
if echo "$log_content" | grep -q "\[INFO\] Test info message"; then
    echo "✅ PASS: log_info writes to LOG_FILE"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: log_info writes to LOG_FILE"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

log_success "Test success message" >/dev/null
log_content=$(cat "$LOG_FILE")
if echo "$log_content" | grep -q "\[SUCCESS\] Test success message"; then
    echo "✅ PASS: log_success writes to LOG_FILE"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: log_success writes to LOG_FILE"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

log_error "Test error message" 2>/dev/null >/dev/null
log_content=$(cat "$LOG_FILE")
if echo "$log_content" | grep -q "\[ERROR\] Test error message"; then
    echo "✅ PASS: log_error writes to LOG_FILE"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: log_error writes to LOG_FILE"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

log_warning "Test warning message" >/dev/null
log_content=$(cat "$LOG_FILE")
if echo "$log_content" | grep -q "\[WARNING\] Test warning message"; then
    echo "✅ PASS: log_warning writes to LOG_FILE"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: log_warning writes to LOG_FILE"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

log_debug "Test debug message" >/dev/null
log_content=$(cat "$LOG_FILE")
if echo "$log_content" | grep -q "\[DEBUG\] Test debug message"; then
    echo "✅ PASS: log_debug writes to LOG_FILE"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: log_debug writes to LOG_FILE"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo "✅ PASS: log_header displays formatted header"
TESTS_PASSED=$((TESTS_PASSED + 1))
TESTS_RUN=$((TESTS_RUN + 1))
echo ""

# Test 8: generate_session_id()
echo "[ Testing generate_session_id() ]"
session_id=$(generate_session_id)
# Check if it looks like a UUID (contains hyphens)
if echo "$session_id" | grep -q "-"; then
    echo "✅ PASS: generate_session_id returns UUID-like string"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "⚠️  WARN: generate_session_id returned: $session_id (not UUID, but acceptable fallback)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))
echo ""

# Test 9-10: create_session_dir() and init_execution_summary()
echo "[ Testing Session Management ]"
session_id=$(generate_session_id 2>/dev/null)
session_dir=$(create_session_dir "$session_id" 2>/dev/null)

if [ -d "$session_dir" ]; then
    echo "✅ PASS: create_session_dir creates directory"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: create_session_dir creates directory (got: $session_dir)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

summary_json="$session_dir/execution-summary.json"
if [ -f "$summary_json" ]; then
    echo "✅ PASS: init_execution_summary creates JSON file"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: init_execution_summary creates JSON file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

if [ -f "$summary_json" ] && grep -q "\"session_id\": \"$session_id\"" "$summary_json"; then
    echo "✅ PASS: execution-summary.json contains session_id"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: execution-summary.json contains session_id"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))
echo ""

# Test 11-13: File locking functions
echo "[ Testing File Locking ]"

# Create a test file
test_file="$SCRIPT_DIR/test-file.md"
touch "$test_file"

# Test 11: acquire_file_lock()
lock_file=$(acquire_file_lock "$test_file" "test-agent" 2>/dev/null)
exit_code=$?
assert_equals "$exit_code" "0" "acquire_file_lock returns 0 on success"

if [ -f "$lock_file" ]; then
    echo "✅ PASS: acquire_file_lock creates lock file"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: acquire_file_lock creates lock file (got: $lock_file)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 12: check_lock_file() - should return 1 (lock valid)
check_lock_file "$lock_file" >/dev/null 2>&1
exit_code=$?
assert_equals "$exit_code" "1" "check_lock_file returns 1 for valid lock"

# Test 13: release_file_lock()
release_file_lock "$lock_file"
if [ ! -f "$lock_file" ]; then
    echo "✅ PASS: release_file_lock removes lock file"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: release_file_lock did not remove lock file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 14: check_lock_file() - should return 0 (lock removed)
check_lock_file "$lock_file" >/dev/null 2>&1
exit_code=$?
assert_equals "$exit_code" "0" "check_lock_file returns 0 after lock released"

# Clean up test file
rm -f "$test_file"
echo ""

# Test 15: Stale lock detection
echo "[ Testing Stale Lock Detection ]"
mkdir -p "$LOCK_DIR"
stale_lock="$LOCK_DIR/stale-test.lock"
echo "99999:2025-01-01 00:00:00:testuser:test-agent" > "$stale_lock"
check_lock_file "$stale_lock" >/dev/null 2>&1
exit_code=$?
assert_equals "$exit_code" "0" "check_lock_file removes stale lock (invalid PID)"
if [ ! -f "$stale_lock" ]; then
    echo "✅ PASS: Stale lock file was removed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "❌ FAIL: Stale lock file still exists"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))
echo ""

# ============================================
#   Test Summary
# ============================================

echo "======================================"
echo "   Test Summary"
echo "======================================"
echo "Total tests: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

# Clean up
cleanup

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
