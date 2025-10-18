#!/bin/bash

# Test script for restart mechanism functions
# Step 2.1 테스트

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source the v7 script to test functions
source "$SCRIPT_DIR/lib/common-utils.sh"

# Mock environment
LOG_FILE="/dev/null"
DEBUG_MODE="true"

# Define AGENT_ORDER
AGENT_ORDER=(
    "content-initiator"
    "overview-writer"
    "concepts-writer"
    "visualization-writer"
    "practice-writer"
    "quiz-writer"
    "content-validator"
)

# Source restart functions from v7
source <(grep -A 200 "^# get_next_agent()" "$SCRIPT_DIR/content-generator-v7.sh" | sed '/^# ============================================/,$d')

echo "======================================"
echo "  Testing Restart Mechanism Functions"
echo "======================================"
echo ""

# Test 1: get_next_agent()
echo "[ Test 1: get_next_agent() ]"
result=$(get_next_agent "content-initiator")
echo "get_next_agent('content-initiator') = $result"
[ "$result" = "overview-writer" ] && echo "✅ PASS" || echo "❌ FAIL"

result=$(get_next_agent "quiz-writer")
echo "get_next_agent('quiz-writer') = $result"
[ "$result" = "content-validator" ] && echo "✅ PASS" || echo "❌ FAIL"

result=$(get_next_agent "content-validator")
echo "get_next_agent('content-validator') = $result"
[ "$result" = "COMPLETE" ] && echo "✅ PASS" || echo "❌ FAIL"
echo ""

# Test 2: auto_determine_restart_point() with real file
echo "[ Test 2: auto_determine_restart_point() ]"
TEST_FILE="$PROJECT_ROOT/public/content/ko/react-core-concepts/01-react-basics/02-virtual-dom.md"

if [ -f "$TEST_FILE" ]; then
    result=$(auto_determine_restart_point "$TEST_FILE")
    echo "auto_determine_restart_point('$TEST_FILE') = $result"
    echo "Expected: RESUME:overview-writer (Priority 2: CURRENT_AGENT set)"
    [[ "$result" == RESUME:* ]] && echo "✅ PASS (RESUME detected)" || echo "⚠️  Result: $result"
else
    echo "⚠️  Test file not found, skipping"
fi
echo ""

# Test 3: determine_next_agent()
echo "[ Test 3: determine_next_agent() ]"
if [ -f "$TEST_FILE" ]; then
    result=$(determine_next_agent "$TEST_FILE")
    echo "determine_next_agent('$TEST_FILE') = $result"
    echo "Expected: overview-writer (CURRENT_AGENT value)"
    [ "$result" = "overview-writer" ] && echo "✅ PASS" || echo "⚠️  Result: $result"
else
    echo "⚠️  Test file not found, skipping"
fi
echo ""

echo "======================================"
echo "  Test Summary"
echo "======================================"
echo "Manual verification required for real file tests"
echo "Check debug output above for Priority detection"
