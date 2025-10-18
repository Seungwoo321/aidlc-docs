#!/bin/bash

# ============================================
#   Common Utilities Module - v7
# ============================================
# Purpose: Shared utility functions for content-generator-v7.sh
# - Logging functions (6 functions)
# - File locking functions (3 functions)
# - Session management functions (4 functions)
# - Timestamp function (1 function)
#
# Total: 14 functions
#
# Reference: logical_design.md Section 2.1
# ============================================

# ============================================
#   2.1.1 Logging Functions
# ============================================

# ANSI Color Codes
COLOR_RESET='\033[0m'
COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_GRAY='\033[0;90m'

# log_info() - Log informational message
# Parameters:
#   $1 (message): Message to log (required)
# Returns: 0 (always success)
# Side effects:
#   - Outputs colored message to stdout
#   - Appends timestamped message to LOG_FILE
log_info() {
    local message="$1"
    local timestamp=$(get_timestamp)

    # stdout: blue color with info icon
    echo -e "${COLOR_BLUE}ℹ️  ${message}${COLOR_RESET}"

    # LOG_FILE: timestamped entry
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [INFO] $message" >> "$LOG_FILE"
    fi
}

# log_success() - Log success message
# Parameters:
#   $1 (message): Message to log (required)
# Returns: 0 (always success)
# Side effects:
#   - Outputs colored message to stdout
#   - Appends timestamped message to LOG_FILE
log_success() {
    local message="$1"
    local timestamp=$(get_timestamp)

    # stdout: green color with checkmark
    echo -e "${COLOR_GREEN}✅ ${message}${COLOR_RESET}"

    # LOG_FILE: timestamped entry
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [SUCCESS] $message" >> "$LOG_FILE"
    fi
}

# log_error() - Log error message
# Parameters:
#   $1 (message): Message to log (required)
# Returns: 0 (always success)
# Side effects:
#   - Outputs colored message to stderr
#   - Appends timestamped message to LOG_FILE
log_error() {
    local message="$1"
    local timestamp=$(get_timestamp)

    # stderr: red color with X mark
    echo -e "${COLOR_RED}❌ ${message}${COLOR_RESET}" >&2

    # LOG_FILE: timestamped entry
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [ERROR] $message" >> "$LOG_FILE"
    fi
}

# log_warning() - Log warning message
# Parameters:
#   $1 (message): Message to log (required)
# Returns: 0 (always success)
# Side effects:
#   - Outputs colored message to stdout
#   - Appends timestamped message to LOG_FILE
log_warning() {
    local message="$1"
    local timestamp=$(get_timestamp)

    # stdout: yellow color with warning icon
    echo -e "${COLOR_YELLOW}⚠️  ${message}${COLOR_RESET}"

    # LOG_FILE: timestamped entry
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [WARNING] $message" >> "$LOG_FILE"
    fi
}

# log_debug() - Log debug message (conditional)
# Parameters:
#   $1 (message): Message to log (required)
# Environment:
#   DEBUG_MODE: Set to "true" to enable debug output
# Returns: 0 (always success)
# Side effects:
#   - Conditionally outputs colored message to stderr (DEBUG_MODE=true)
#   - Always appends timestamped message to LOG_FILE
log_debug() {
    local message="$1"
    local timestamp=$(get_timestamp)

    # stderr: only if DEBUG_MODE is true (prevents stdout contamination)
    if [ "$DEBUG_MODE" = "true" ]; then
        echo -e "${COLOR_GRAY}🔍 ${message}${COLOR_RESET}" >&2
    fi

    # LOG_FILE: always log
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [DEBUG] $message" >> "$LOG_FILE"
    fi
}

# log_header() - Log section header
# Parameters:
#   $1 (message): Header message (required)
# Returns: 0 (always success)
# Side effects:
#   - Outputs formatted header to stdout
log_header() {
    local message="$1"

    echo ""
    echo "======================================"
    echo "   $message"
    echo "======================================"
    echo ""
}

# ============================================
#   2.1.2 File Locking Functions
# ============================================

# check_lock_file() - Check if lock file is valid
# Parameters:
#   $1 (lock_file): Path to lock file (required)
# Returns:
#   0: Lock is invalid/removed (safe to proceed)
#   1: Lock is valid (another process is working)
# Side effects:
#   - Removes stale lock files
#   - Logs warnings for stale locks
check_lock_file() {
    local lock_file="$1"

    # No lock file → safe to proceed
    if [ ! -f "$lock_file" ]; then
        return 0
    fi

    # Read lock file contents: "PID:timestamp:username:agent_name"
    local lock_content=$(cat "$lock_file" 2>/dev/null)
    local pid=$(echo "$lock_content" | cut -d: -f1)

    # Invalid format → remove stale lock
    if [ -z "$pid" ] || ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        log_warning "Invalid lock file format, removing: $lock_file"
        rm -f "$lock_file"
        return 0
    fi

    # Check if process exists (macOS/Linux compatible)
    if ps -p "$pid" >/dev/null 2>&1; then
        # Process exists → lock is valid
        log_debug "Lock file is valid (PID: $pid)"
        return 1
    else
        # Process doesn't exist → remove stale lock
        log_warning "Stale lock detected (PID: $pid no longer exists), removing"
        rm -f "$lock_file"
        return 0
    fi
}

# acquire_file_lock() - Acquire lock on a file
# Parameters:
#   $1 (file_path): Path to markdown file (required)
#   $2 (agent_name): Name of agent acquiring lock (required)
# Environment:
#   LOCK_DIR: Directory for lock files
#   FORCE_MODE: Set to "true" to force remove existing locks
#   TEST_MODE: Set to "true" to skip actual lock creation
# Returns:
#   0: Lock acquired successfully (outputs lock_file path to stdout)
#   1: Failed to acquire lock (timeout or error)
# Side effects:
#   - Creates LOCK_DIR if needed
#   - Creates lock file with PID:timestamp:username:agent_name
#   - Logs lock acquisition
acquire_file_lock() {
    local file_path="$1"
    local agent_name="$2"
    local lock_file="$LOCK_DIR/$(basename "$file_path" .md).lock"
    local max_wait=300  # 5 minutes
    local waited=0

    # Create LOCK_DIR
    mkdir -p "$LOCK_DIR" 2>/dev/null

    # FORCE_MODE: remove existing lock
    if [ "$FORCE_MODE" = "true" ]; then
        rm -f "$lock_file"
        log_warning "Force mode: removed existing lock" >/dev/null
    fi

    # Wait for lock to become available
    while [ $waited -lt $max_wait ]; do
        # Check if lock is valid (suppress output)
        if check_lock_file "$lock_file" >/dev/null 2>&1; then
            # Lock is available → acquire it
            if [ "$TEST_MODE" != "true" ]; then
                echo "$$:$(get_timestamp):$(whoami):$agent_name" > "$lock_file"
            fi

            # Suppress debug log for return value purity
            if [ "$DEBUG_MODE" = "true" ]; then
                log_debug "Lock acquired: $lock_file (agent: $agent_name)" >/dev/null
            fi

            # Only output lock file path to stdout
            echo "$lock_file"
            return 0
        fi

        # Lock is valid → wait
        if [ "$TEST_MODE" = "true" ]; then
            log_info "[TEST] Would wait for lock: $lock_file" >/dev/null
            return 1
        fi

        log_info "Waiting for lock on $(basename "$file_path")... ($waited/$max_wait seconds)" >/dev/null
        sleep 5
        waited=$((waited + 5))
    done

    # Timeout
    log_error "Timeout waiting for lock on $(basename "$file_path")" >/dev/null
    return 1
}

# release_file_lock() - Release acquired lock
# Parameters:
#   $1 (lock_file): Path to lock file (required)
# Environment:
#   TEST_MODE: Set to "true" to skip actual lock removal
# Returns: 0 (always success)
# Side effects:
#   - Removes lock file
#   - Logs lock release
release_file_lock() {
    local lock_file="$1"

    if [ "$TEST_MODE" != "true" ] && [ -f "$lock_file" ]; then
        rm -f "$lock_file"
        log_debug "Lock released: $lock_file"
    fi
}

# ============================================
#   2.1.3 Session Management Functions
# ============================================

# generate_session_id() - Generate UUID session ID
# Parameters: None
# Returns: 0 (always success)
# Side effects:
#   - Outputs UUID to stdout
generate_session_id() {
    # Priority 1: uuidgen (macOS/Linux)
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
        return 0
    fi

    # Priority 2: /proc/sys/kernel/random/uuid (Linux)
    if [ -f /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
        return 0
    fi

    # Priority 3: Python uuid module
    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import uuid; print(str(uuid.uuid4()))' 2>/dev/null && return 0
    fi

    # Fallback: timestamp + PID + random
    echo "$(date +%s)-$$-$RANDOM"
}

# create_session_dir() - Create session directory
# Parameters:
#   $1 (session_id): Session ID (required)
# Environment:
#   PROJECT_ROOT: Project root directory
# Returns:
#   0: Success (outputs session_dir path to stdout)
#   1: Failure
# Side effects:
#   - Creates session directory
#   - Initializes execution-summary.json
create_session_dir() {
    local session_id="$1"
    local session_dir="$PROJECT_ROOT/logs/sessions/$session_id"

    # Create directory
    mkdir -p "$session_dir" 2>/dev/null
    if [ $? -ne 0 ]; then
        log_error "Failed to create session directory: $session_dir" >/dev/null
        return 1
    fi

    # Initialize execution summary (suppress log output for return value)
    local summary_file="$session_dir/execution-summary.json"
    local saved_debug="$DEBUG_MODE"
    DEBUG_MODE="false"
    init_execution_summary "$summary_file" "$session_id"
    DEBUG_MODE="$saved_debug"

    # Output session directory path (only thing on stdout)
    echo "$session_dir"
    return 0
}

# init_execution_summary() - Initialize execution-summary.json
# Parameters:
#   $1 (summary_file): Path to execution-summary.json (required)
#   $2 (session_id): Session ID (required)
# Returns: 0 (always success)
# Side effects:
#   - Creates execution-summary.json with initial structure
init_execution_summary() {
    local summary_file="$1"
    local session_id="$2"
    local timestamp=$(get_timestamp)

    cat > "$summary_file" << EOF
{
  "session_id": "$session_id",
  "started_at": "$timestamp",
  "completed_at": "",
  "total_duration": 0,
  "file_path": "",
  "agents": [],
  "errors": [],
  "final_validation_score": 0
}
EOF

    log_debug "Initialized execution summary: $summary_file"
}

# update_execution_summary() - Update execution-summary.json
# Parameters:
#   $1 (summary_file): Path to execution-summary.json (required)
#   $2 (update_type): Type of update (set_file|agent_success|agent_error|complete) (required)
#   $3+: Additional parameters based on update_type
# Returns: 0 (always success)
# Side effects:
#   - Updates execution-summary.json using pure Shell (sed/awk/grep)
# Update types:
#   - set_file <file_path>: Set target file path
#   - agent_success <agent_name> <duration> <exit_code>: Add successful agent execution
#   - agent_error <agent_name> <error_type> <error_message> <attempt> [exit_code]: Add error entry
#   - complete <validation_score>: Mark session as complete
update_execution_summary() {
    local summary_file="$1"
    local update_type="$2"
    shift 2

    # Check if summary file exists
    if [ ! -f "$summary_file" ]; then
        log_debug "Summary file not found - skipping update"
        return 0
    fi

    # Update based on type
    case "$update_type" in
        "set_file")
            local file_path="$1"
            # Escape forward slashes for sed
            local escaped_path=$(echo "$file_path" | sed 's/\//\\\//g')
            sed -i '' "s/\"file_path\": \".*\"/\"file_path\": \"$escaped_path\"/" "$summary_file" 2>/dev/null || {
                log_debug "Failed to update file_path"
                return 0
            }
            ;;

        "agent_success")
            local agent_name="$1"
            local duration="$2"
            local exit_code="${3:-0}"
            local timestamp=$(get_timestamp)

            # Check if agents array is empty (match from start of line)
            local is_empty=$(grep '^  "agents": \[\],' "$summary_file")

            if [ -n "$is_empty" ]; then
                # Empty array → add entry directly (use sed with actual newlines), preserve comma
                sed -i '' '/^  \"agents\": \[\],/c\
  "agents": [\
    {\
      "name": "'"$agent_name"'",\
      "completed_at": "'"$timestamp"'",\
      "status": "SUCCESS",\
      "exit_code": '"$exit_code"',\
      "duration": '"$duration"'\
    }\
  ],' "$summary_file" 2>/dev/null || {
                    log_debug "Failed to add agent to empty array"
                    return 0
                }
            else
                # Non-empty array → insert new entry before closing bracket with leading comma
                local agents_end_line=$(grep -n '"agents":' "$summary_file" | head -1 | cut -d: -f1)
                local closing_bracket_line=$(awk -v start="$agents_end_line" 'NR > start && /^  \]/ {print NR; exit}' "$summary_file")

                if [ -n "$closing_bracket_line" ]; then
                    # Insert new entry before closing bracket (with leading comma on same line)
                    sed -i '' "${closing_bracket_line}i\\
    , {\\
      \"name\": \"$agent_name\",\\
      \"completed_at\": \"$timestamp\",\\
      \"status\": \"SUCCESS\",\\
      \"exit_code\": $exit_code,\\
      \"duration\": $duration\\
    }
" "$summary_file" 2>/dev/null || {
                        log_debug "Failed to add agent to non-empty array"
                        return 0
                    }
                fi
            fi
            ;;

        "agent_error")
            local agent_name="$1"
            local error_type="$2"
            local error_message="$3"
            local attempt="$4"
            local exit_code="${5:-1}"
            local timestamp=$(get_timestamp)

            # Escape quotes in error message
            error_message=$(echo "$error_message" | sed 's/"/\\"/g')

            # Check if errors array is empty (match anywhere on line, not just start)
            local is_empty=$(grep '"errors": \[\],' "$summary_file")

            if [ -n "$is_empty" ]; then
                # Empty array → add entry directly, preserve comma and preceding content
                # Pattern matches both standalone and inline (after agents array closing bracket)
                sed -i '' 's/\"errors\": \[\],/\"errors\": [\
    {\
      \"agent\": \"'"$agent_name"'\",\
      \"error_type\": \"'"$error_type"'\",\
      \"error_message\": \"'"$error_message"'\",\
      \"timestamp\": \"'"$timestamp"'\",\
      \"attempt\": '"$attempt"',\
      \"exit_code\": '"$exit_code"'\
    }\
  ],/' "$summary_file" 2>/dev/null || {
                    log_debug "Failed to add error to empty array (sed failed)"
                    return 0
                }
            else
                # Non-empty array → (rest of code remains the same)
                # Skip the old empty array replacement code
                false
            fi

            # Check if we handled empty array case
            if [ $? -eq 0 ]; then
                # Empty array case was handled, return
                return 0
            fi

            # Non-empty array case
            {
                # Non-empty array → insert new entry before closing bracket with leading comma
                local errors_end_line=$(grep -n '"errors":' "$summary_file" | head -1 | cut -d: -f1)
                local closing_bracket_line=$(awk -v start="$errors_end_line" 'NR > start && /^  \]/ {print NR; exit}' "$summary_file")

                if [ -n "$closing_bracket_line" ]; then
                    # Insert new entry before closing bracket (with leading comma on same line)
                    sed -i '' "${closing_bracket_line}i\\
    , {\\
      \"agent\": \"$agent_name\",\\
      \"error_type\": \"$error_type\",\\
      \"error_message\": \"$error_message\",\\
      \"timestamp\": \"$timestamp\",\\
      \"attempt\": $attempt,\\
      \"exit_code\": $exit_code\\
    }
" "$summary_file" 2>/dev/null || {
                        log_debug "Failed to add error to non-empty array"
                        return 0
                    }
                fi
            }
            ;;

        "complete")
            local validation_score="${1:-0}"
            local timestamp=$(get_timestamp)

            # Extract started_at to calculate duration
            local started_at=$(grep '"started_at":' "$summary_file" | sed 's/.*"started_at": "\(.*\)".*/\1/')
            local duration=0

            if [ -n "$started_at" ]; then
                # Convert timestamps to epoch (macOS compatible)
                local start_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$started_at" "+%s" 2>/dev/null || echo "0")
                local end_epoch=$(date "+%s")
                duration=$((end_epoch - start_epoch))
            fi

            # Update completed_at, total_duration, final_validation_score
            sed -i '' "s/\"completed_at\": \".*\"/\"completed_at\": \"$timestamp\"/" "$summary_file" 2>/dev/null
            sed -i '' "s/\"total_duration\": [0-9]*/\"total_duration\": $duration/" "$summary_file" 2>/dev/null
            sed -i '' "s/\"final_validation_score\": [0-9]*/\"final_validation_score\": $validation_score/" "$summary_file" 2>/dev/null || {
                log_debug "Failed to update completion fields"
                return 0
            }
            ;;

        *)
            log_debug "Unknown update type: $update_type"
            ;;
    esac

    log_debug "Execution summary updated: $update_type"
}

# ============================================
#   2.1.4 Timestamp Function
# ============================================

# get_timestamp() - Get current timestamp
# Parameters: None
# Returns: 0 (always success)
# Side effects:
#   - Outputs ISO 8601 timestamp to stdout
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# ============================================
#   Module Initialization
# ============================================

# Export functions (not needed in bash, but documented for clarity)
# Functions available:
# - log_info, log_success, log_error, log_warning, log_debug, log_header
# - check_lock_file, acquire_file_lock, release_file_lock
# - generate_session_id, create_session_dir, init_execution_summary, update_execution_summary
# - get_timestamp
