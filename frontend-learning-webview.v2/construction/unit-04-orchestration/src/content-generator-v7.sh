#!/bin/bash
set -e

# ============================================
#   Content Generator V7 - Enhanced Orchestration
# ============================================
# Purpose: Orchestrate 7 specialized agents with enhanced features
# - Improved restart mechanism (5-step priority)
# - Contract validation (Precondition/Postcondition)
# - Enhanced error handling and logging
# - execution-summary.json generation
# - Modular architecture
#
# Reference: logical_design.md
# Version: 7.0
# ============================================

# ============================================
#   Environment Setup
# ============================================

# Determine project root (5 levels up from src/ to reach frontend-learning-webview/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

# Change to project root for consistent path resolution
cd "$PROJECT_ROOT"

# UTF-8 locale settings (preserve v6 pattern)
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PYTHONIOENCODING=utf-8
export LC_CTYPE=en_US.UTF-8
export LESSCHARSET=utf-8
export LC_COLLATE=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8

# ============================================
#   Configuration
# ============================================

# Paths
export PATH="/Users/mzc01-swlee/.nvm/versions/node/v22.19.0/bin:$PATH"
export HOME="/Users/mzc01-swlee"
export USER="mzc01-swlee"
CLAUDE_PATH="/Users/mzc01-swlee/.nvm/versions/node/v22.19.0/bin/claude"
LOCK_DIR="$PROJECT_ROOT/.locks"
CONTENT_DIR="$PROJECT_ROOT/public/content/ko"
TEST_DIR="$PROJECT_ROOT/test"
LOG_FILE="$PROJECT_ROOT/logs/content-generator-v7.log"

# Import common utilities
source "$SCRIPT_DIR/lib/common-utils.sh"

# Quality thresholds (preserve v6 values)
PERFECT_SCORE=100
PASS_THRESHOLD=90
MAX_ATTEMPTS=3
MAX_RETRIES=3
PASSING_SCORE=100

# ============================================
#   Command Line Options (Default Values)
# ============================================

DEBUG_MODE=false
TEST_MODE=false
AUTO_MODE=false
INTERACTIVE_MODE=false
DIRECT_MODE=false
FORCE_MODE=false
RESUME_MODE=false
VALIDATE_ONLY_MODE=false
SKIP_VALIDATION=false
VERBOSE_MODE=false
JSON_SUMMARY=true  # Always generate execution-summary.json

AUTO_CATEGORY=""
AUTO_SUBCATEGORY=""
DIRECT_FILE=""
FROM_AGENT=""
LOG_DIR="$PROJECT_ROOT/logs"

SKIP_AGENTS=()
ONLY_AGENT=""

# ============================================
#   CLI Option Parsing
# ============================================

show_help() {
    cat << 'EOF'
Content Generator V7 - Enhanced Orchestration System

Usage: content-generator-v7.sh [OPTIONS]

Execution Modes (mutually exclusive):
  -a, --auto              Auto mode (process incomplete files automatically)
  -i, --interactive       Interactive mode (manual category/subcategory selection)
  --direct=FILE           Direct mode (work on specific file)

Restart Options:
  --resume                Auto-detect restart point (5-step priority algorithm)
  --from=AGENT            Start from specific agent (skips PC-1 validation)

Validation Options:
  --validate-only         Validate contracts only (no agent execution)
  --skip-validation       Skip contract validation (faster execution)

Logging Options:
  --verbose               Enable verbose output
  --debug                 Enable debug mode (detailed logging)
  --log-dir=PATH          Custom log directory (default: logs/)
  --json-summary          Generate execution-summary.json (default: true)

Other Options:
  -f, --force             Force mode (ignore locks, override COMPLETE status)
  -t, --test              Test mode (mock execution, no actual Claude calls)
  --category=NAME         Auto-select category (with --auto or --interactive)
  --subcategory=NAME      Auto-select subcategory (with --auto or --interactive)
  --skip-AGENT            Skip specific agent (e.g., --skip-visualization)
  --only=AGENT            Run only specific agent
  -h, --help              Show this help message

Examples:
  # Auto mode with category selection
  ./content-generator-v7.sh -a --category=javascript-core-concepts --subcategory=01-variables

  # Direct mode with resume
  ./content-generator-v7.sh --direct=public/content/ko/.../topic.md --resume

  # Validate only mode
  ./content-generator-v7.sh --direct=file.md --validate-only

  # From specific agent
  ./content-generator-v7.sh --direct=file.md --from=quiz-writer

  # Test mode
  ./content-generator-v7.sh -t -a

Notes:
  - v7 uses 5-step priority restart mechanism
  - Precondition/Postcondition validation enabled by default
  - execution-summary.json generated for all runs
  - Compatible with v6 (preserves claude -p execution pattern)

EOF
}

# Parse command line arguments
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--auto)
            AUTO_MODE=true
            ;;
        -i|--interactive)
            INTERACTIVE_MODE=true
            ;;
        --direct=*)
            DIRECT_MODE=true
            DIRECT_FILE="${arg#--direct=}"
            ;;
        --resume)
            RESUME_MODE=true
            ;;
        --from=*)
            FROM_AGENT="${arg#--from=}"
            ;;
        --validate-only)
            VALIDATE_ONLY_MODE=true
            ;;
        --skip-validation)
            SKIP_VALIDATION=true
            ;;
        --verbose)
            VERBOSE_MODE=true
            ;;
        -d|--debug)
            DEBUG_MODE=true
            ;;
        --log-dir=*)
            LOG_DIR="${arg#--log-dir=}"
            ;;
        --json-summary)
            JSON_SUMMARY=true
            ;;
        -f|--force)
            FORCE_MODE=true
            ;;
        -t|--test)
            TEST_MODE=true
            ;;
        --category=*)
            AUTO_CATEGORY="${arg#--category=}"
            ;;
        --subcategory=*)
            AUTO_SUBCATEGORY="${arg#--subcategory=}"
            ;;
        --skip-*)
            agent_name="${arg#--skip-}"
            SKIP_AGENTS+=("$agent_name")
            ;;
        --only=*)
            ONLY_AGENT="${arg#--only=}"
            ;;
        *)
            log_error "Unknown option: $arg"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# ============================================
#   Option Validation (Section 10.2)
# ============================================

# Count execution modes
mode_count=0
[ "$AUTO_MODE" = "true" ] && ((mode_count++))
[ "$INTERACTIVE_MODE" = "true" ] && ((mode_count++))
[ "$DIRECT_MODE" = "true" ] && ((mode_count++))

if [ $mode_count -eq 0 ]; then
    log_error "Please specify an execution mode (--auto, --interactive, or --direct)"
    echo "Use -h for help"
    exit 1
elif [ $mode_count -gt 1 ]; then
    log_error "Only one execution mode can be specified"
    echo "Use -h for help"
    exit 1
fi

# Validate option combinations (mutually exclusive)
if [ "$RESUME_MODE" = "true" ] && [ -n "$FROM_AGENT" ]; then
    log_error "Cannot use --resume and --from together"
    exit 1
fi

if [ "$VALIDATE_ONLY_MODE" = "true" ] && [ "$RESUME_MODE" = "true" ]; then
    log_error "Cannot use --validate-only and --resume together"
    exit 1
fi

# ============================================
#   Global Variables
# ============================================

SESSION_ID=""
SESSION_DIR=""
LOCK_FILE=""

# ============================================
#   Restart Mechanism Functions (Section 2.2.1)
# ============================================

# Agent order for pipeline
AGENT_ORDER=(
    "content-initiator"
    "overview-writer"
    "concepts-writer"
    "visualization-writer"
    "practice-writer"
    "quiz-writer"
    "content-validator"
)

# get_next_agent() - Get next agent in pipeline
# Parameters:
#   $1 (current_agent): Current agent name (required)
# Returns: 0 (always success)
# Side effects: Outputs next agent name or "COMPLETE" to stdout
get_next_agent() {
    local current_agent="$1"

    for i in "${!AGENT_ORDER[@]}"; do
        if [ "${AGENT_ORDER[$i]}" = "$current_agent" ]; then
            local next_index=$((i + 1))
            if [ $next_index -ge ${#AGENT_ORDER[@]} ]; then
                echo "COMPLETE"
            else
                echo "${AGENT_ORDER[$next_index]}"
            fi
            return 0
        fi
    done

    # Not found - default to content-initiator
    echo "content-initiator"
}

# parse_work_status_markers() - Parse Work Status Markers from file
# Parameters:
#   $1 (file_path): Markdown file path (required)
# Returns: 0 (always success)
# Side effects: Outputs key=value pairs to stdout
parse_work_status_markers() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "CURRENT_AGENT="
        echo "PROGRESS="
        echo "VALIDATION_SCORE="
        echo "LAST_STATUS="
        echo "LAST_AGENT="
        echo "IMPROVEMENT_TARGET="
        return 0
    fi

    # Extract CURRENT_AGENT (inside HTML comment)
    local current_agent=$(grep "^CURRENT_AGENT:" "$file_path" 2>/dev/null | sed 's/CURRENT_AGENT: *//' | sed 's/ *-->.*//' | xargs)

    # Extract PROGRESS
    local progress=$(grep "^PROGRESS:" "$file_path" 2>/dev/null | sed 's/PROGRESS: *//' | sed 's/ *-->.*//' | xargs)

    # Extract VALIDATION_SCORE
    local validation_score=$(grep "^VALIDATION_SCORE:" "$file_path" 2>/dev/null | sed 's/VALIDATION_SCORE: *//' | sed 's/\/100//' | sed 's/ *-->.*//' | xargs)

    # Parse HANDOFF LOG - last entry
    local last_handoff=$(grep -A 50 "^HANDOFF LOG:" "$file_path" 2>/dev/null | grep "^\[" | tail -1)
    local last_status=$(echo "$last_handoff" | sed 's/^\[\([A-Z]*\)\].*/\1/')
    local last_agent=$(echo "$last_handoff" | sed 's/.*\] \([a-z-]*\) .*/\1/')

    # Parse IMPROVEMENT_NEEDED
    local improvement_target=""
    if grep -q "^IMPROVEMENT_NEEDED:" "$file_path" 2>/dev/null; then
        improvement_target=$(grep -A 5 "^IMPROVEMENT_NEEDED:" "$file_path" 2>/dev/null | grep "^  - " | head -1 | sed 's/.*- \([a-z-]*\):.*/\1/')
    fi

    # Output
    echo "CURRENT_AGENT=$current_agent"
    echo "PROGRESS=$progress"
    echo "VALIDATION_SCORE=$validation_score"
    echo "LAST_STATUS=$last_status"
    echo "LAST_AGENT=$last_agent"
    echo "IMPROVEMENT_TARGET=$improvement_target"
}

# auto_determine_restart_point() - Determine restart point (5-step priority)
# Parameters:
#   $1 (file_path): Markdown file path (required)
# Returns: 0 (always success)
# Side effects: Outputs restart point identifier to stdout
auto_determine_restart_point() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "START:content-initiator"
        return 0
    fi

    # Parse markers - direct extraction for reliability
    local improvement_target=""
    if grep -q "^IMPROVEMENT_NEEDED:" "$file_path" 2>/dev/null; then
        improvement_target=$(grep -A 5 "^IMPROVEMENT_NEEDED:" "$file_path" 2>/dev/null | grep "^  - " | head -1 | sed 's/.*- \([a-z-]*\):.*/\1/')
    fi

    local current_agent=$(grep "^CURRENT_AGENT:" "$file_path" 2>/dev/null | sed 's/CURRENT_AGENT: *//' | sed 's/ *-->.*//' | xargs)

    # Priority 1: IMPROVEMENT_NEEDED exists
    if [ -n "$improvement_target" ] && [ "$improvement_target" != "" ]; then
        log_debug "Priority 1: IMPROVEMENT_NEEDED detected -> $improvement_target"
        echo "IMPROVEMENT:$improvement_target"
        return 0
    fi

    # Priority 2: CURRENT_AGENT not empty
    if [ -n "$current_agent" ] && [ "$current_agent" != "" ]; then
        log_debug "Priority 2: CURRENT_AGENT detected -> $current_agent"
        echo "RESUME:$current_agent"
        return 0
    fi

    # Priority 3: Last [FAILURE] in HANDOFF LOG
    if grep -q "HANDOFF LOG:" "$file_path" 2>/dev/null; then
        local last_failure=$(grep -A 50 "HANDOFF LOG:" "$file_path" 2>/dev/null | grep "^\[FAILURE\]" | tail -1)
        if [ -n "$last_failure" ]; then
            local failed_agent=$(echo "$last_failure" | sed 's/.*\] \([a-z-]*\) .*/\1/')
            log_debug "Priority 3: Last FAILURE detected -> $failed_agent"
            echo "RETRY:$failed_agent"
            return 0
        fi
    fi

    # Priority 4: [COMPLETE] marker exists
    if grep -q "\[COMPLETE\]" "$file_path" 2>/dev/null; then
        log_debug "Priority 4: COMPLETE marker detected"
        echo "COMPLETE"
        return 0
    fi

    # Priority 5: Last [DONE] or [IMPROVE] -> next agent
    if grep -q "HANDOFF LOG:" "$file_path" 2>/dev/null; then
        local last_done=$(grep -A 50 "HANDOFF LOG:" "$file_path" 2>/dev/null | grep -E "^\[(DONE|IMPROVE)\]" | tail -1)
        if [ -n "$last_done" ]; then
            local completed_agent=$(echo "$last_done" | sed 's/.*\] \([a-z-]*\) .*/\1/')
            local next_agent=$(get_next_agent "$completed_agent")
            log_debug "Priority 5: Last DONE/IMPROVE detected -> $completed_agent, next -> $next_agent"
            if [ "$next_agent" = "COMPLETE" ]; then
                echo "COMPLETE"
            else
                echo "RESUME:$next_agent"
            fi
            return 0
        fi
    fi

    # Default: START from beginning
    log_debug "No restart point found, starting from content-initiator"
    echo "START:content-initiator"
}

# determine_next_agent() - Determine next agent from markers (v6 compatible)
# Parameters:
#   $1 (file_path): Markdown file path (required)
# Returns: 0 (always success)
# Side effects: Outputs next agent name or "COMPLETE" to stdout
determine_next_agent() {
    local file_path="$1"

    # Parse markers
    local markers=$(parse_work_status_markers "$file_path")
    local improvement_target=$(echo "$markers" | grep "^IMPROVEMENT_TARGET=" | cut -d= -f2)
    local current_agent=$(echo "$markers" | grep "^CURRENT_AGENT=" | cut -d= -f2)

    # Priority 1: IMPROVEMENT_NEEDED exists
    if [ -n "$improvement_target" ] && [ "$improvement_target" != "" ]; then
        echo "$improvement_target"
        return 0
    fi

    # Priority 2: CURRENT_AGENT empty -> COMPLETE
    if [ -z "$current_agent" ] || [ "$current_agent" = "" ]; then
        echo "COMPLETE"
        return 0
    fi

    # Priority 3: CURRENT_AGENT set -> return that agent
    echo "$current_agent"
}

# ============================================
#   Contract Validation Functions (Section 2.2.2)
# ============================================

# validate_preconditions() - Validate agent preconditions
# Parameters:
#   $1 (agent_name): Agent name (required)
#   $2 (file_path): Markdown file path (required)
# Returns:
#   0: All preconditions passed
#   1: One or more preconditions failed
# Side effects:
#   - Logs validation results
validate_preconditions() {
    local agent_name="$1"
    local file_path="$2"

    log_debug "Validating preconditions for $agent_name"

    # PC-1: Work Status Markers exist (all agents except content-initiator)
    if [ "$agent_name" != "content-initiator" ]; then
        if ! grep -q "^CURRENT_AGENT:" "$file_path" 2>/dev/null; then
            log_error "PC-1 failed: Work Status Markers not found"
            log_info "💡 Suggestion: Run content-initiator first to initialize markers"
            return 1
        fi
    fi

    # PC-2: STATUS == "IN_PROGRESS" or "PENDING" (all agents except content-initiator)
    if [ "$agent_name" != "content-initiator" ]; then
        local status=$(grep "^STATUS:" "$file_path" 2>/dev/null | sed 's/STATUS: *//' | sed 's/ *-->.*//' | xargs)
        if [ "$status" != "IN_PROGRESS" ] && [ "$status" != "PENDING" ]; then
            log_error "PC-2 failed: STATUS is '$status', expected IN_PROGRESS or PENDING"
            return 1
        fi
    fi

    # PC-3: Agent-specific preconditions
    case "$agent_name" in
        "content-initiator")
            # No special preconditions
            ;;
        "overview-writer")
            # Check that content-initiator has run
            if ! grep -q "\[START\].*content-initiator" "$file_path" 2>/dev/null && \
               ! grep -q "\[DONE\].*content-initiator" "$file_path" 2>/dev/null; then
                log_error "PC-3 failed: content-initiator has not run"
                return 1
            fi
            ;;
        "concepts-writer")
            # Check that overview-writer has completed
            if ! grep -q "^# Overview" "$file_path" 2>/dev/null; then
                log_error "PC-3 failed: Overview section not found"
                log_info "💡 Suggestion: Run overview-writer first"
                return 1
            fi
            ;;
        "visualization-writer")
            # Check that concepts-writer has completed
            if ! grep -q "^# Core Concepts" "$file_path" 2>/dev/null; then
                log_error "PC-3 failed: Core Concepts section not found"
                return 1
            fi
            ;;
        "practice-writer")
            # Check that concepts-writer has completed
            if ! grep -q "^# Core Concepts" "$file_path" 2>/dev/null; then
                log_error "PC-3 failed: Core Concepts section not found"
                return 1
            fi
            ;;
        "quiz-writer")
            # Check that practice-writer has completed
            if ! grep -q "^# Code Patterns" "$file_path" 2>/dev/null && \
               ! grep -q "^# Experiments" "$file_path" 2>/dev/null; then
                log_error "PC-3 failed: Code Patterns or Experiments section not found"
                return 1
            fi
            ;;
        "content-validator")
            # Check that quiz-writer has completed
            if ! grep -q "^# Quiz" "$file_path" 2>/dev/null; then
                log_error "PC-3 failed: Quiz section not found"
                return 1
            fi
            ;;
    esac

    log_debug "Preconditions passed for $agent_name"
    return 0
}

# validate_postconditions() - Validate agent postconditions
# Parameters:
#   $1 (agent_name): Agent name (required)
#   $2 (file_path): Markdown file path (required)
# Returns:
#   0: All postconditions passed
#   1: One or more postconditions failed
# Side effects:
#   - Logs validation results
validate_postconditions() {
    local agent_name="$1"
    local file_path="$2"

    log_debug "Validating postconditions for $agent_name"

    # PO-1: Agent-specific output validation
    case "$agent_name" in
        "content-initiator")
            if ! grep -q "^CURRENT_AGENT:" "$file_path" 2>/dev/null; then
                log_error "PO-1 failed: Work Status Markers not created"
                log_info "💡 Suggestion: Check if agent created output sections"
                log_info "   Run: grep '^#' \"$file_path\" | head -10"
                return 1
            fi
            ;;
        "overview-writer")
            if ! grep -q "^# Overview" "$file_path" 2>/dev/null; then
                log_error "PO-1 failed: Overview section not created"
                log_info "💡 Suggestion: Check if agent created output sections"
                return 1
            fi
            ;;
        "concepts-writer")
            if ! grep -q "^# Core Concepts" "$file_path" 2>/dev/null; then
                log_error "PO-1 failed: Core Concepts section not created"
                return 1
            fi
            ;;
        "visualization-writer")
            # Visualization is optional, only warn
            if ! grep -q "Visualization" "$file_path" 2>/dev/null; then
                log_warning "PO-1 warning: No visualization components found (optional)"
            fi
            ;;
        "practice-writer")
            if ! grep -q "^# Code Patterns" "$file_path" 2>/dev/null && \
               ! grep -q "^# Experiments" "$file_path" 2>/dev/null; then
                log_error "PO-1 failed: Code Patterns or Experiments section not created"
                return 1
            fi
            ;;
        "quiz-writer")
            if ! grep -q "^# Quiz" "$file_path" 2>/dev/null; then
                log_error "PO-1 failed: Quiz section not created"
                return 1
            fi
            ;;
        "content-validator")
            if ! grep -q "^VALIDATION_SCORE:" "$file_path" 2>/dev/null; then
                log_error "PO-1 failed: VALIDATION_SCORE not set"
                return 1
            fi
            ;;
    esac

    # PO-2: HANDOFF LOG has [DONE] entry
    local last_handoff=$(grep -A 50 "^HANDOFF LOG:" "$file_path" 2>/dev/null | grep "^\[" | tail -1)
    if ! echo "$last_handoff" | grep -q "\[DONE\].*$agent_name" && \
       ! echo "$last_handoff" | grep -q "\[IMPROVE\].*$agent_name"; then
        log_error "PO-2 failed: HANDOFF LOG missing [DONE] or [IMPROVE] entry for $agent_name"
        log_info "💡 Suggestion: Check HANDOFF LOG"
        log_info "   Run: grep -A 20 'HANDOFF LOG' \"$file_path\" | tail -5"
        return 1
    fi

    # PO-3: CURRENT_AGENT updated to next agent (or empty for content-validator)
    local current_agent=$(grep "^CURRENT_AGENT:" "$file_path" 2>/dev/null | sed 's/CURRENT_AGENT: *//' | sed 's/ *-->.*//' | xargs)
    local next_agent=$(get_next_agent "$agent_name")

    if [ "$next_agent" = "COMPLETE" ]; then
        # Last agent - CURRENT_AGENT should be empty
        if [ -n "$current_agent" ] && [ "$current_agent" != "" ]; then
            log_error "PO-3 failed: CURRENT_AGENT should be empty after $agent_name"
            log_info "   Current value: '$current_agent'"
            return 1
        fi
    else
        # Not last agent - CURRENT_AGENT should be next agent
        if [ "$current_agent" != "$next_agent" ]; then
            log_error "PO-3 failed: CURRENT_AGENT not updated to next agent"
            log_info "   Expected: '$next_agent', Got: '$current_agent'"
            log_info "💡 Suggestion: Check CURRENT_AGENT field"
            log_info "   Run: grep 'CURRENT_AGENT' \"$file_path\""
            return 1
        fi
    fi

    log_debug "Postconditions passed for $agent_name"
    return 0
}

# ============================================
#   Error Handling Functions (Section 2.2.4)
# ============================================

# generate_recovery_suggestion() - Generate error-specific recovery suggestions
# Parameters:
#   $1 (error_type): Error type (PRECONDITION_FAILED, POSTCONDITION_FAILED, etc.)
#   $2 (agent_name): Agent name (required)
#   $3 (file_path): Markdown file path (required)
#   $4 (error_message): Error message (optional)
# Returns: 0 (always success)
# Side effects: Outputs recovery suggestion to stdout
generate_recovery_suggestion() {
    local error_type="$1"
    local agent_name="$2"
    local file_path="$3"
    local error_message="$4"

    echo ""
    echo "💡 Recovery Suggestions:"
    echo ""

    case "$error_type" in
        "PRECONDITION_FAILED")
            echo "   Diagnosis:"
            echo "   1. Check Work Status Markers:"
            echo "      grep -A 10 'CURRENT_AGENT' \"$file_path\""
            echo "   2. Check STATUS field:"
            echo "      grep 'STATUS:' \"$file_path\""
            echo "   3. Check required input sections:"
            echo "      grep '^#' \"$file_path\" | head -10"
            echo ""
            echo "   Recovery Options:"
            echo "   1. Fix Work Status Markers manually"
            echo "   2. Use --from=$agent_name to skip PC-1 validation"
            echo "   3. Use --skip-validation (not recommended)"
            ;;

        "POSTCONDITION_FAILED")
            echo "   Diagnosis:"
            echo "   1. Check if output sections were created:"
            echo "      grep '^#' \"$file_path\" | tail -5"
            echo "   2. Check HANDOFF LOG:"
            echo "      grep -A 20 'HANDOFF LOG' \"$file_path\" | tail -5"
            echo "   3. Check CURRENT_AGENT field:"
            echo "      grep 'CURRENT_AGENT' \"$file_path\""
            echo ""
            echo "   Recovery Options:"
            echo "   1. Check agent prompt: .claude/agents/$agent_name.md"
            echo "   2. Re-run with --from=$agent_name after fixing prompt"
            echo "   3. Use --skip-validation temporarily (not recommended)"
            ;;

        "EXECUTION_FAILED")
            echo "   Diagnosis:"
            echo "   1. Check agent prompt file:"
            echo "      ls .claude/agents/$agent_name.md"
            echo "   2. Check agent log:"
            echo "      tail -n 50 $SESSION_DIR/$agent_name.log"
            echo "   3. Check Claude CLI version:"
            echo "      $CLAUDE_PATH --version"
            echo ""
            echo "   Recovery Options:"
            echo "   1. Use --resume to retry with same session"
            echo "   2. Start fresh (remove file and re-run)"
            echo "   3. Use --debug for more detailed logs"
            ;;

        "PARSING_ERROR")
            echo "   Diagnosis:"
            echo "   1. Check file encoding:"
            echo "      file -I \"$file_path\""
            echo "   2. Verify Work Status Markers format:"
            echo "      grep -A 30 '<!--' \"$file_path\" | head -30"
            echo ""
            echo "   Recovery Options:"
            echo "   1. Fix file encoding to UTF-8"
            echo "   2. Restore from backup if available"
            echo "   3. Re-initialize with content-initiator"
            ;;

        "LOCK_CONFLICT")
            echo "   Diagnosis:"
            echo "   1. Check running processes:"
            echo "      ps aux | grep content-generator-v"
            echo "   2. Check lock file:"
            echo "      cat \"$LOCK_DIR/$(basename \"$file_path\" .md).lock\""
            echo ""
            echo "   Recovery Options:"
            echo "   1. Wait for other process to complete"
            echo "   2. Use --force to override lock (dangerous)"
            echo "   3. Kill stale process (use PID from lock file)"
            ;;

        "TIMEOUT")
            echo "   Diagnosis:"
            echo "   1. Check agent log for infinite loops:"
            echo "      tail -n 100 $SESSION_DIR/$agent_name.log"
            echo "   2. Check agent prompt for logic errors:"
            echo "      cat .claude/agents/$agent_name.md"
            echo ""
            echo "   Recovery Options:"
            echo "   1. Fix agent prompt logic"
            echo "   2. Increase timeout value (export AGENT_TIMEOUT=3600)"
            echo "   3. Use --resume to retry"
            ;;

        *)
            echo "   Unknown error type: $error_type"
            echo "   Please check logs for details"
            ;;
    esac

    echo ""
}

# handle_agent_failure() - Handle agent execution failures
# Parameters:
#   $1 (file_path): Markdown file path (required)
#   $2 (agent_name): Agent name (required)
#   $3 (error_type): Error type (required)
#   $4 (error_message): Error message (required)
#   $5 (attempt_num): Attempt number (default: 1)
#   $6 (exit_code): Exit code (optional, for EXECUTION_FAILED)
# Returns: 1 (always failure)
# Side effects:
#   - Logs error
#   - Updates HANDOFF LOG (if possible)
#   - Updates execution-summary.json
#   - Outputs recovery suggestions
handle_agent_failure() {
    local file_path="$1"
    local agent_name="$2"
    local error_type="$3"
    local error_message="$4"
    local attempt_num="${5:-1}"
    local exit_code="${6:-1}"

    local timestamp=$(get_timestamp)

    # Log error
    log_error "Agent failure: $agent_name"
    log_error "Error type: $error_type"
    log_error "Message: $error_message"
    log_error "Attempt: $attempt_num"

    # Update HANDOFF LOG (if file exists and is writable)
    if [ -f "$file_path" ] && [ -w "$file_path" ] && [ "$error_type" != "PARSING_ERROR" ]; then
        # Find HANDOFF LOG section
        if grep -q "^HANDOFF LOG:" "$file_path" 2>/dev/null; then
            # Prepare failure entry
            local failure_entry="[FAILURE] $agent_name | $error_type"

            # Add detail based on error type
            case "$error_type" in
                "EXECUTION_FAILED")
                    failure_entry="$failure_entry (exit code $exit_code, attempt $attempt_num)"
                    ;;
                "LOCK_CONFLICT"|"TIMEOUT")
                    failure_entry="$failure_entry (attempt $attempt_num)"
                    ;;
                *)
                    failure_entry="$failure_entry (attempt $attempt_num)"
                    ;;
            esac

            failure_entry="$failure_entry | $timestamp"

            # Create temp file with updated HANDOFF LOG
            local temp_file=$(mktemp)
            local in_handoff_section=false
            local handoff_updated=false

            while IFS= read -r line; do
                echo "$line" >> "$temp_file"

                # Detect HANDOFF LOG section start
                if [[ "$line" =~ ^HANDOFF\ LOG: ]]; then
                    in_handoff_section=true
                fi

                # Insert failure entry before closing --> if in handoff section
                if [ "$in_handoff_section" = true ] && [[ "$line" =~ ^--\> ]] && [ "$handoff_updated" = false ]; then
                    # Insert failure entry before -->
                    sed -i.bak '$ d' "$temp_file"  # Remove the --> line we just added
                    echo "$failure_entry" >> "$temp_file"
                    echo "$line" >> "$temp_file"  # Add --> back
                    handoff_updated=true
                    in_handoff_section=false
                fi
            done < "$file_path"

            # Replace original file
            mv "$temp_file" "$file_path"
            rm -f "${temp_file}.bak"

            log_debug "Updated HANDOFF LOG with [FAILURE] entry"
        fi
    fi

    # Update execution-summary.json
    if [ -n "$SESSION_DIR" ] && [ -f "$SESSION_DIR/execution-summary.json" ]; then
        update_execution_summary "$SESSION_DIR/execution-summary.json" "agent_error" "$agent_name" "$error_type" "$error_message" "$attempt_num" "$exit_code"
        log_debug "Updated execution-summary.json with error entry"
    fi

    # Generate and output recovery suggestions
    generate_recovery_suggestion "$error_type" "$agent_name" "$file_path" "$error_message"

    return 1
}

# ============================================
#   Agent Execution Functions (Section 2.2.3)
# ============================================

# generate_agent_prompt() - Generate prompt for agent
# Parameters:
#   $1 (agent_name): Agent name (required)
#   $2 (target_file): Target file path (optional)
#   $3 (topic_name): Topic name (optional)
# Returns: 0 (always success)
# Side effects: Outputs prompt to stdout
generate_agent_prompt() {
    local agent_name="$1"
    local target_file="$2"
    local topic_name="$3"

    local prompt=""

    case "$agent_name" in
        "content-initiator")
            if [ -n "$target_file" ] && [ -n "$topic_name" ]; then
                prompt="content-initiator agent로 $topic_name 토픽의 Work Status Markers 초기화. 파일 경로: $target_file"
            else
                prompt="content-initiator agent로 Work Status Markers 초기화"
            fi
            ;;
        "overview-writer")
            if [ -n "$target_file" ] && [ -n "$topic_name" ]; then
                prompt="overview-writer agent로 $topic_name 토픽의 Overview 섹션 작성. 파일 경로: $target_file"
            else
                prompt="overview-writer agent로 Overview 섹션 작성"
            fi
            ;;
        "concepts-writer")
            if [ -n "$target_file" ] && [ -n "$topic_name" ]; then
                prompt="concepts-writer agent로 $topic_name 토픽의 Core Concepts 섹션 작성. 파일 경로: $target_file"
            else
                prompt="concepts-writer agent로 Core Concepts 섹션 작성"
            fi
            ;;
        "visualization-writer")
            if [ -n "$target_file" ] && [ -n "$topic_name" ]; then
                prompt="visualization-writer agent로 $topic_name 토픽의 시각화 컴포넌트 생성. 파일 경로: $target_file"
            else
                prompt="visualization-writer agent로 시각화 컴포넌트 생성"
            fi
            ;;
        "practice-writer")
            if [ -n "$target_file" ] && [ -n "$topic_name" ]; then
                prompt="practice-writer agent로 $topic_name 토픽의 Code Patterns 및 Experiments 섹션 작성. 파일 경로: $target_file"
            else
                prompt="practice-writer agent로 Code Patterns 및 Experiments 섹션 작성"
            fi
            ;;
        "quiz-writer")
            if [ -n "$target_file" ] && [ -n "$topic_name" ]; then
                prompt="quiz-writer agent로 $topic_name 토픽의 Quiz 섹션 작성. 파일 경로: $target_file"
            else
                prompt="quiz-writer agent로 Quiz 섹션 작성"
            fi
            ;;
        "content-validator")
            prompt="content-validator agent로 전체 콘텐츠 품질 검증"
            ;;
        *)
            prompt="$agent_name agent 실행"
            ;;
    esac

    echo "$prompt"
}

# execute_claude_agent() - Execute Claude agent (preserve v6 pattern!)
# Parameters:
#   $1 (agent_name): Agent name (required)
#   $2 (session_id): Claude CLI session ID (required)
#   $3 (is_first_section): First execution? "true"|"false" (required)
#   $4 (target_file): Target file path (optional)
#   $5 (topic_name): Topic name (optional)
# Environment:
#   CLAUDE_PATH: Claude CLI executable path
#   TEST_MODE: Test mode flag
#   DEBUG_MODE: Debug mode flag
# Returns:
#   0: Success
#   1: Failure (Claude CLI exit code)
# Side effects:
#   - Executes Claude CLI
#   - Creates agent log file
execute_claude_agent() {
    local agent_name="$1"
    local session_id="$2"
    local is_first_section="$3"
    local target_file="$4"
    local topic_name="$5"

    # Generate prompt
    local prompt=$(generate_agent_prompt "$agent_name" "$target_file" "$topic_name")

    # Agent log file
    local agent_log="$SESSION_DIR/${agent_name}.log"

    # TEST_MODE: only show what would be executed
    if [ "$TEST_MODE" = "true" ]; then
        if [ "$is_first_section" = "true" ]; then
            log_info "[TEST] Would execute: claude -p \"$prompt\" --session-id \"$session_id\""
        else
            log_info "[TEST] Would execute: claude -p \"$prompt\" --resume \"$session_id\""
        fi
        return 0
    fi

    # DEBUG_MODE: show command
    if [ "$DEBUG_MODE" = "true" ]; then
        log_debug "Executing: $prompt"
    fi

    # Execute Claude with proper UTF-8 environment (CRITICAL: preserve v6 pattern!)
    local exit_code=0

    if [ "$is_first_section" = "true" ]; then
        # First section: create new session with specific ID
        env PYTHONIOENCODING=utf-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
            "$CLAUDE_PATH" -p "$prompt" \
            --session-id "$session_id" \
            --permission-mode bypassPermissions \
            2>&1 | tee "$agent_log"
        exit_code=${PIPESTATUS[0]}
    else
        # Subsequent sections: resume existing session
        env PYTHONIOENCODING=utf-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
            "$CLAUDE_PATH" -p "$prompt" \
            --resume "$session_id" \
            --permission-mode bypassPermissions \
            2>&1 | tee "$agent_log"
        exit_code=${PIPESTATUS[0]}
    fi

    return $exit_code
}

# execute_agent_with_validation() - Execute agent with Pre/Post condition validation
# Parameters:
#   $1 (agent_name): Agent name (required)
#   $2 (file_path): Markdown file path (required)
#   $3 (session_id): Claude CLI session ID (required)
#   $4 (is_first): First execution? "true"|"false" (required)
# Environment:
#   SKIP_VALIDATION: Skip validation flag
# Returns:
#   0: Success
#   1: Failure
# Side effects:
#   - Lock acquisition/release
#   - Logging
#   - execution-summary.json update
execute_agent_with_validation() {
    local agent_name="$1"
    local file_path="$2"
    local session_id="$3"
    local is_first="$4"

    local topic_name=$(basename "$file_path" .md)
    local start_time=$(date +%s)

    log_info "▶️  Executing agent: $agent_name"

    # Step 1: Precondition validation
    if [ "$SKIP_VALIDATION" = "false" ]; then
        log_info "🔍 Validating preconditions..."
        if ! validate_preconditions "$agent_name" "$file_path"; then
            log_error "❌ Precondition validation failed for $agent_name"
            handle_agent_failure "$file_path" "$agent_name" "PRECONDITION_FAILED" "Precondition validation failed" 1
            return 1
        fi
        log_success "✅ Preconditions passed"
    fi

    # Step 2: Lock acquisition
    LOCK_FILE=$(acquire_file_lock "$file_path" "$agent_name")
    if [ $? -ne 0 ]; then
        log_error "Failed to acquire lock for $file_path"
        return 1
    fi

    # Step 3: Agent execution
    local execution_result=0
    execute_claude_agent "$agent_name" "$session_id" "$is_first" "$file_path" "$topic_name" || execution_result=$?

    # Step 4: Lock release
    release_file_lock "$LOCK_FILE"

    # Step 5: Check execution result
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ $execution_result -ne 0 ]; then
        log_error "❌ $agent_name failed (exit code: $execution_result, duration: ${duration}s)"
        handle_agent_failure "$file_path" "$agent_name" "EXECUTION_FAILED" "Claude CLI returned exit code $execution_result" 1 "$execution_result"
        return 1
    fi

    # Step 6: Postcondition validation
    if [ "$SKIP_VALIDATION" = "false" ]; then
        log_info "🔍 Validating postconditions..."
        if ! validate_postconditions "$agent_name" "$file_path"; then
            log_error "❌ Postcondition validation failed for $agent_name"
            log_warning "Agent execution completed but output validation failed"
            log_info "💡 This may indicate an agent prompt issue or unexpected behavior"
            handle_agent_failure "$file_path" "$agent_name" "POSTCONDITION_FAILED" "Postcondition validation failed" 1
            return 1
        fi
        log_success "✅ Postconditions passed"
    fi

    # Step 7: Success logging
    log_success "✅ $agent_name completed (${duration}s)"

    # Update execution-summary.json
    if [ -n "$SESSION_DIR" ] && [ -f "$SESSION_DIR/execution-summary.json" ]; then
        update_execution_summary "$SESSION_DIR/execution-summary.json" "agent_success" "$agent_name" "$duration" "$execution_result"
        log_debug "Updated execution-summary.json with agent success"
    fi

    return 0
}

# ============================================
#   Execution Mode Functions (Section 2.2.5)
# ============================================

# execute_direct_mode() - Execute Direct Mode (Section 9.1)
# Parameters:
#   $1 (file_path): Target file path (required)
# Environment:
#   RESUME_MODE, FROM_AGENT, VALIDATE_ONLY_MODE
# Returns:
#   0: Success
#   1: Failure
# Side effects:
#   - Validates file path
#   - Executes pipeline from restart point
execute_direct_mode() {
    local file_path="$1"

    log_header "Direct Mode Execution"
    log_info "Target file: $file_path"

    # Step 1: FILE 경로 검증
    if [ ! -f "$file_path" ]; then
        log_error "File not found: $file_path"
        return 1
    fi

    if [ ! -r "$file_path" ]; then
        log_error "File not readable: $file_path"
        return 1
    fi

    # Step 2: VALIDATE_ONLY_MODE (Section 9.4)
    if [ "$VALIDATE_ONLY_MODE" = "true" ]; then
        execute_validate_only_mode "$file_path"
        return $?
    fi

    # Update execution-summary.json with file_path
    if [ -n "$SESSION_DIR" ] && [ -f "$SESSION_DIR/execution-summary.json" ]; then
        update_execution_summary "$SESSION_DIR/execution-summary.json" "set_file" "$file_path"
        log_debug "Updated execution-summary.json with file_path"
    fi

    # Step 3: Work Status Markers 확인
    if ! grep -q "^CURRENT_AGENT:" "$file_path" 2>/dev/null && \
       ! grep -q "^HANDOFF LOG:" "$file_path" 2>/dev/null; then
        log_warning "Work Status Markers not found - file may not be initialized"
        log_info "Will attempt to start from content-initiator"
    fi

    # Step 4: Restart point 결정
    local restart_point=""
    local start_agent=""

    if [ -n "$FROM_AGENT" ]; then
        # --from=AGENT option
        log_info "Restart option: --from=$FROM_AGENT"
        restart_point="FROM:$FROM_AGENT"
        start_agent="$FROM_AGENT"
    elif [ "$RESUME_MODE" = "true" ]; then
        # --resume option: auto-detect using 5-step priority
        log_info "Restart option: --resume (auto-detect)"
        restart_point=$(auto_determine_restart_point "$file_path")
        local restart_type=$(echo "$restart_point" | cut -d: -f1)
        start_agent=$(echo "$restart_point" | cut -d: -f2)

        log_info "Auto-detected restart point: $restart_type → $start_agent"

        # COMPLETE check (unless FORCE_MODE)
        if [ "$restart_type" = "COMPLETE" ]; then
            if [ "$FORCE_MODE" = "true" ]; then
                log_warning "⚠️  File is COMPLETE, but FORCE mode enabled - re-running from content-initiator"
                start_agent="content-initiator"
            else
                log_success "✅ File already COMPLETE"
                return 0
            fi
        fi
    else
        # Default: auto-detect
        restart_point=$(auto_determine_restart_point "$file_path")
        local restart_type=$(echo "$restart_point" | cut -d: -f1)
        start_agent=$(echo "$restart_point" | cut -d: -f2)

        log_info "Auto-detected restart point: $restart_type → $start_agent"

        # COMPLETE check (unless FORCE_MODE)
        if [ "$restart_type" = "COMPLETE" ]; then
            if [ "$FORCE_MODE" = "true" ]; then
                log_warning "⚠️  File is COMPLETE, but FORCE mode enabled - re-running from content-initiator"
                start_agent="content-initiator"
            else
                log_success "✅ File already COMPLETE"
                return 0
            fi
        fi
    fi

    # Step 5: Execute pipeline from restart point
    log_header "Executing Pipeline"
    log_info "Starting from agent: $start_agent"

    # Find agent index in AGENT_ORDER
    local start_index=0
    for i in "${!AGENT_ORDER[@]}"; do
        if [ "${AGENT_ORDER[$i]}" = "$start_agent" ]; then
            start_index=$i
            break
        fi
    done

    # Execute agents from start_index
    local is_first="true"  # First agent in this session
    for ((i=start_index; i<${#AGENT_ORDER[@]}; i++)); do
        local current_agent="${AGENT_ORDER[$i]}"

        log_header "Agent: $current_agent"

        # Execute agent with validation
        if ! execute_agent_with_validation "$current_agent" "$file_path" "$SESSION_ID" "$is_first"; then
            log_error "❌ Pipeline failed at: $current_agent"
            return 1
        fi

        is_first="false"  # Subsequent agents resume session

        # Check if next agent is needed
        local next_agent=$(determine_next_agent "$file_path")
        if [ "$next_agent" = "COMPLETE" ]; then
            log_success "✅ Pipeline COMPLETE"

            # Extract validation score for summary
            local validation_score=0
            if grep -q "^VALIDATION_SCORE:" "$file_path" 2>/dev/null; then
                validation_score=$(grep "^VALIDATION_SCORE:" "$file_path" 2>/dev/null | sed 's/VALIDATION_SCORE: *//' | sed 's/\/100//' | sed 's/ *-->.*//' | xargs)
            fi

            # Update execution-summary.json with completion
            if [ -n "$SESSION_DIR" ] && [ -f "$SESSION_DIR/execution-summary.json" ]; then
                update_execution_summary "$SESSION_DIR/execution-summary.json" "complete" "$validation_score"
                log_debug "Updated execution-summary.json with completion status"
            fi

            return 0
        fi
    done

    log_success "✅ Pipeline execution completed"

    # Extract validation score for summary
    local validation_score=0
    if grep -q "^VALIDATION_SCORE:" "$file_path" 2>/dev/null; then
        validation_score=$(grep "^VALIDATION_SCORE:" "$file_path" 2>/dev/null | sed 's/VALIDATION_SCORE: *//' | sed 's/\/100//' | sed 's/ *-->.*//' | xargs)
    fi

    # Update execution-summary.json with completion
    if [ -n "$SESSION_DIR" ] && [ -f "$SESSION_DIR/execution-summary.json" ]; then
        update_execution_summary "$SESSION_DIR/execution-summary.json" "complete" "$validation_score"
        log_debug "Updated execution-summary.json with completion status"
    fi

    return 0
}

# find_incomplete_file() - Find incomplete file from category.yaml (Section 9.2.1)
# Parameters:
#   $1 (category_yaml): Path to category.yaml (required)
#   $2 (content_dir): Content directory path (required)
# Returns:
#   0: Found incomplete file (outputs file path to stdout)
#   1: All files are COMPLETE
# Side effects:
#   - Parses category.yaml
#   - Checks file status
find_incomplete_file() {
    local category_yaml="$1"
    local content_dir="$2"

    log_debug "Searching for incomplete files in: $category_yaml"

    # Step 1: YAML에서 토픽 ID 추출 (순서대로)
    local topic_list=$(grep "^  - id:" "$category_yaml" | sed 's/.*id: *//')

    if [ -z "$topic_list" ]; then
        log_debug "No topics found in category.yaml"
        return 1
    fi

    # Step 2: 각 토픽 파일 순회
    while IFS= read -r topic_id; do
        local file_path="$content_dir/${topic_id}.md"

        log_debug "Checking topic: $topic_id → $file_path"

        # Step 3: 파일 상태 확인 - 파일 없음
        if [ ! -f "$file_path" ]; then
            log_debug "  ❌ File not found (needs creation)"
            echo "$file_path"
            return 0
        fi

        # Step 4: Work Status Markers 확인 - CURRENT_AGENT 존재
        if grep -q "^CURRENT_AGENT:" "$file_path" 2>/dev/null; then
            local current_agent=$(grep "^CURRENT_AGENT:" "$file_path" 2>/dev/null | sed 's/CURRENT_AGENT: *//' | sed 's/ *-->.*//' | xargs)
            log_debug "  ⏸️  In progress (CURRENT_AGENT: $current_agent)"
            echo "$file_path"
            return 0
        fi

        # Step 5: COMPLETE 상태 확인
        if ! grep -q "\[COMPLETE\]" "$file_path" 2>/dev/null; then
            log_debug "  ⏳ Incomplete (no COMPLETE marker)"
            echo "$file_path"
            return 0
        fi

        log_debug "  ✅ COMPLETE"
    done <<< "$topic_list"

    # Step 6: 모든 파일 COMPLETE
    log_debug "All files are COMPLETE"
    return 1
}

# execute_auto_mode() - Execute Auto Mode (Section 9.2)
# Parameters: None
# Environment:
#   AUTO_CATEGORY, AUTO_SUBCATEGORY
# Returns:
#   0: Success
#   1: Failure
# Side effects:
#   - Finds incomplete file in category.yaml
#   - Executes Direct Mode on found file
execute_auto_mode() {
    log_header "Auto Mode Execution"

    # Validate category/subcategory options
    if [ -z "$AUTO_CATEGORY" ] || [ -z "$AUTO_SUBCATEGORY" ]; then
        log_error "Auto mode requires --category and --subcategory options"
        return 1
    fi

    log_info "Category: $AUTO_CATEGORY"
    log_info "Subcategory: $AUTO_SUBCATEGORY"

    # Step 1: category.yaml 읽기
    local category_yaml="$CONTENT_DIR/$AUTO_CATEGORY/$AUTO_SUBCATEGORY/category.yaml"
    if [ ! -f "$category_yaml" ]; then
        log_error "category.yaml not found: $category_yaml"
        return 1
    fi

    local content_dir="$CONTENT_DIR/$AUTO_CATEGORY/$AUTO_SUBCATEGORY"

    # Step 2: 불완전 파일 찾기
    log_info "Searching for incomplete files..."
    local target_file=$(find_incomplete_file "$category_yaml" "$content_dir")
    local find_result=$?

    if [ $find_result -eq 0 ] && [ -n "$target_file" ]; then
        # 불완전 파일 찾음
        local topic_id=$(basename "$target_file" .md)
        log_success "Found incomplete file: $topic_id"
        log_info "Target file: $target_file"
    else
        # 모든 파일 COMPLETE → 첫 번째 토픽 사용
        log_info "All files are COMPLETE - using first topic"
        local first_topic=$(grep "^  - id:" "$category_yaml" | head -1 | sed 's/.*id: *//')

        if [ -z "$first_topic" ]; then
            log_error "No topics found in category.yaml"
            return 1
        fi

        target_file="$content_dir/${first_topic}.md"
        log_info "Selected topic: $first_topic"
        log_info "Target file: $target_file"
    fi

    # Step 3: Direct Mode로 실행
    execute_direct_mode "$target_file"
}

# select_category() - Select category interactively (Section 9.3.1)
# Parameters: None
# Environment:
#   CONTENT_DIR, AUTO_CATEGORY (optional pre-selection)
# Returns:
#   0: Selection completed (outputs category name to stdout)
#   1: Selection cancelled or error
# Side effects:
#   - Displays category list
#   - Prompts for user input
select_category() {
    # If AUTO_CATEGORY is set, use it directly
    if [ -n "$AUTO_CATEGORY" ]; then
        log_debug "Using pre-selected category: $AUTO_CATEGORY"
        echo "$AUTO_CATEGORY"
        return 0
    fi

    # Step 1: Get category list from CONTENT_DIR
    local categories=$(find "$CONTENT_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

    if [ -z "$categories" ]; then
        log_error "No categories found in $CONTENT_DIR"
        return 1
    fi

    # Step 2: Display category list with numbers
    echo ""
    echo "Available categories:"
    echo "===================="
    local i=1
    local category_array=()
    while IFS= read -r category_path; do
        local category_name=$(basename "$category_path")
        category_array+=("$category_name")
        echo "  $i) $category_name"
        ((i++))
    done <<< "$categories"

    # Step 3: Prompt for user input
    echo ""
    read -p "Select category (1-$((i-1)) or 'q' to quit): " choice

    # Step 4: Validate input
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
        log_info "Selection cancelled"
        return 1
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$i" ]; then
        log_error "Invalid choice: $choice"
        return 1
    fi

    # Step 5: Return selected category
    local selected="${category_array[$((choice-1))]}"
    echo "$selected"
    return 0
}

# select_subcategory() - Select subcategory interactively (Section 9.3.2)
# Parameters:
#   $1 (category): Category name (required)
# Environment:
#   CONTENT_DIR, AUTO_SUBCATEGORY (optional pre-selection)
# Returns:
#   0: Selection completed (outputs subcategory name to stdout)
#   1: Selection cancelled or error
# Side effects:
#   - Displays subcategory list
#   - Prompts for user input
select_subcategory() {
    local category="$1"

    # If AUTO_SUBCATEGORY is set, use it directly
    if [ -n "$AUTO_SUBCATEGORY" ]; then
        log_debug "Using pre-selected subcategory: $AUTO_SUBCATEGORY"
        echo "$AUTO_SUBCATEGORY"
        return 0
    fi

    local category_path="$CONTENT_DIR/$category"

    # Step 1: Get subcategory list
    local subcategories=$(find "$category_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

    if [ -z "$subcategories" ]; then
        log_error "No subcategories found in $category_path"
        return 1
    fi

    # Step 2: Display subcategory list
    echo ""
    echo "Available subcategories in '$category':"
    echo "========================================"
    local i=1
    local subcat_array=()
    while IFS= read -r subcat_path; do
        local subcat_name=$(basename "$subcat_path")
        subcat_array+=("$subcat_name")
        echo "  $i) $subcat_name"
        ((i++))
    done <<< "$subcategories"

    # Step 3: Prompt for input
    echo ""
    read -p "Select subcategory (1-$((i-1)) or 'q' to quit): " choice

    # Step 4: Validate input
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
        log_info "Selection cancelled"
        return 1
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$i" ]; then
        log_error "Invalid choice: $choice"
        return 1
    fi

    # Step 5: Return selected subcategory
    local selected="${subcat_array[$((choice-1))]}"
    echo "$selected"
    return 0
}

# select_topic() - Select topic interactively (Section 9.3.3)
# Parameters:
#   $1 (category_yaml): Path to category.yaml (required)
#   $2 (content_dir): Content directory path (required)
# Returns:
#   0: Selection completed (outputs file path to stdout)
#   1: Selection cancelled or error
# Side effects:
#   - Displays topic list with status
#   - Prompts for user input
select_topic() {
    local category_yaml="$1"
    local content_dir="$2"

    # Step 1: Parse topic list from YAML
    local topic_list=$(grep "^  - id:" "$category_yaml" | sed 's/.*id: *//')

    if [ -z "$topic_list" ]; then
        log_error "No topics found in category.yaml"
        return 1
    fi

    # Step 2: Display topic list with status
    echo ""
    echo "Available topics:"
    echo "================="
    local i=1
    local topic_array=()
    while IFS= read -r topic_id; do
        topic_array+=("$topic_id")
        local file_path="$content_dir/${topic_id}.md"
        local status="❌ Not created"

        # Determine status
        if [ -f "$file_path" ]; then
            if grep -q "\[COMPLETE\]" "$file_path" 2>/dev/null; then
                status="✅ COMPLETE"
            elif grep -q "^CURRENT_AGENT:" "$file_path" 2>/dev/null; then
                local current_agent=$(grep "^CURRENT_AGENT:" "$file_path" 2>/dev/null | sed 's/CURRENT_AGENT: *//' | sed 's/ *-->.*//' | xargs)
                status="⏸️  In progress ($current_agent)"
            else
                status="⏳ Incomplete"
            fi
        fi

        # Extract title from YAML
        local title=$(grep -A 1 "  - id: $topic_id" "$category_yaml" | grep "title:" | sed 's/.*title: *//')

        echo "  $i) $topic_id"
        echo "     Title: $title"
        echo "     Status: $status"
        echo ""
        ((i++))
    done <<< "$topic_list"

    # Step 3: Prompt for input
    read -p "Select topic (1-$((i-1)) or 'q' to quit): " choice

    # Step 4: Validate input
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
        log_info "Selection cancelled"
        return 1
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$i" ]; then
        log_error "Invalid choice: $choice"
        return 1
    fi

    # Step 5: Return selected file path
    local selected_topic="${topic_array[$((choice-1))]}"
    local selected_file="$content_dir/${selected_topic}.md"
    echo "$selected_file"
    return 0
}

# execute_interactive_mode() - Execute Interactive Mode (Section 9.3)
# Parameters: None
# Returns:
#   0: Success
#   1: Failure
# Side effects:
#   - Prompts user for category/subcategory/topic
#   - Executes Direct Mode on selected file
execute_interactive_mode() {
    log_header "Interactive Mode Execution"

    # Step 1: Select category
    log_info "Step 1: Select Category"
    local selected_category=$(select_category)
    if [ $? -ne 0 ] || [ -z "$selected_category" ]; then
        log_error "Category selection failed"
        return 1
    fi
    log_success "Selected category: $selected_category"

    # Step 2: Select subcategory
    log_info "Step 2: Select Subcategory"
    local selected_subcategory=$(select_subcategory "$selected_category")
    if [ $? -ne 0 ] || [ -z "$selected_subcategory" ]; then
        log_error "Subcategory selection failed"
        return 1
    fi
    log_success "Selected subcategory: $selected_subcategory"

    # Step 3: Read category.yaml
    local category_yaml="$CONTENT_DIR/$selected_category/$selected_subcategory/category.yaml"
    if [ ! -f "$category_yaml" ]; then
        log_error "category.yaml not found: $category_yaml"
        return 1
    fi

    local content_dir="$CONTENT_DIR/$selected_category/$selected_subcategory"

    # Step 4: Select topic
    log_info "Step 3: Select Topic"
    local target_file=$(select_topic "$category_yaml" "$content_dir")
    if [ $? -ne 0 ] || [ -z "$target_file" ]; then
        log_error "Topic selection failed"
        return 1
    fi
    log_success "Selected file: $target_file"

    # Step 5: Execute Direct Mode
    execute_direct_mode "$target_file"
}

# execute_validate_only_mode() - Execute Validate-Only Mode (Section 9.4)
# Parameters:
#   $1 (file_path): Target file path (required)
# Returns:
#   0: All validations passed
#   1: One or more validations failed
# Side effects:
#   - Validates Work Status Markers
#   - Validates Precondition/Postcondition
#   - Outputs validation results
execute_validate_only_mode() {
    local file_path="$1"

    log_header "Validate-Only Mode"
    log_info "Target file: $file_path"

    # Step 1: FILE 읽기
    if [ ! -f "$file_path" ]; then
        log_error "File not found: $file_path"
        return 1
    fi

    # Step 2: Work Status Markers 파싱
    log_info "Parsing Work Status Markers..."
    local markers=$(parse_work_status_markers "$file_path")

    echo ""
    echo "Work Status Markers:"
    echo "$markers" | sed 's/^/  /'
    echo ""

    # Step 3: 각 에이전트별 Precondition/Postcondition 검증
    local validation_failed=false

    for agent_name in "${AGENT_ORDER[@]}"; do
        echo ""
        log_info "Validating: $agent_name"

        # Check if agent has run
        if ! grep -q "\[DONE\].*$agent_name" "$file_path" 2>/dev/null && \
           ! grep -q "\[IMPROVE\].*$agent_name" "$file_path" 2>/dev/null; then
            log_warning "  Agent has not run yet - skipping"
            continue
        fi

        # Precondition
        echo "  Preconditions:"
        if validate_preconditions "$agent_name" "$file_path" >/dev/null 2>&1; then
            echo "    ✅ PASS"
        else
            echo "    ❌ FAIL"
            validation_failed=true
        fi

        # Postcondition
        echo "  Postconditions:"
        if validate_postconditions "$agent_name" "$file_path" >/dev/null 2>&1; then
            echo "    ✅ PASS"
        else
            echo "    ❌ FAIL"
            validation_failed=true
        fi
    done

    echo ""

    # Step 4: 검증 결과 출력
    if [ "$validation_failed" = true ]; then
        log_error "❌ Validation FAILED"
        return 1
    else
        log_success "✅ All validations PASSED"
        return 0
    fi
}

# ============================================
#   Main Function
# ============================================

main() {
    log_header "Content Generator V7 - Enhanced Orchestration"

    # Show configuration
    log_info "Version: 7.0"
    log_info "Project Root: $PROJECT_ROOT"

    if [ "$DEBUG_MODE" = "true" ]; then
        log_info "Debug mode enabled"
    fi
    if [ "$TEST_MODE" = "true" ]; then
        log_info "Test mode enabled"
    fi
    if [ "$FORCE_MODE" = "true" ]; then
        log_warning "Force mode enabled (ignoring locks)"
    fi
    if [ "$VERBOSE_MODE" = "true" ]; then
        log_info "Verbose mode enabled"
    fi

    # Show execution mode
    if [ "$AUTO_MODE" = "true" ]; then
        log_info "Execution Mode: Auto"
    elif [ "$INTERACTIVE_MODE" = "true" ]; then
        log_info "Execution Mode: Interactive"
    elif [ "$DIRECT_MODE" = "true" ]; then
        log_info "Execution Mode: Direct (file: $DIRECT_FILE)"
    fi

    # Show restart/validation options
    if [ "$RESUME_MODE" = "true" ]; then
        log_info "Restart: Auto-detect (5-step priority)"
    elif [ -n "$FROM_AGENT" ]; then
        log_info "Restart: From agent '$FROM_AGENT'"
    fi

    if [ "$VALIDATE_ONLY_MODE" = "true" ]; then
        log_info "Mode: Validate Only (no execution)"
    elif [ "$SKIP_VALIDATION" = "true" ]; then
        log_warning "Contract validation disabled"
    fi

    # Generate session ID
    SESSION_ID=$(generate_session_id)
    log_info "Session ID: $SESSION_ID"

    # Create session directory
    SESSION_DIR=$(create_session_dir "$SESSION_ID")
    log_debug "Session directory: $SESSION_DIR"

    # ============================================
    #   Execution Mode Logic (Section 9)
    # ============================================

    # DIRECT MODE (Section 9.1)
    if [ "$DIRECT_MODE" = "true" ]; then
        execute_direct_mode "$DIRECT_FILE"
        exit $?
    fi

    # AUTO MODE (Section 9.2)
    if [ "$AUTO_MODE" = "true" ]; then
        execute_auto_mode
        exit $?
    fi

    # INTERACTIVE MODE (Section 9.3)
    if [ "$INTERACTIVE_MODE" = "true" ]; then
        execute_interactive_mode
        exit $?
    fi

    # Unreachable (option validation ensures one mode is selected)
    log_error "No execution mode selected"
    exit 1
}

# ============================================
#   Cleanup on Exit
# ============================================

cleanup() {
    if [ -n "$LOCK_FILE" ] && [ -f "$LOCK_FILE" ]; then
        release_file_lock "$LOCK_FILE"
    fi
}

trap cleanup EXIT

# ============================================
#   Run Main Function
# ============================================

main
