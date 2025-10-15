# 오케스트레이션 스크립트 개선 설계

**Created**: 2025-10-14
**Status**: In Progress
**Version**: 1.0.0

---

## 목차

1. [현재 스크립트 분석](#현재-스크립트-분석)
2. [개선 아키텍처](#개선-아키텍처)
3. [주요 알고리즘](#주요-알고리즘)
4. [구현 계획](#구현-계획)
5. [로깅 및 모니터링](#로깅-및-모니터링)
6. [테스트 전략](#테스트-전략)

---

## 현재 스크립트 분석

### 기본 정보

**파일**: `scripts/content-generator-v6.sh`
**라인 수**: 1,048 lines
**버전**: V6 (Comprehensive System)

### 주요 기능

#### 1. 실행 모드 (3가지)
- **Auto Mode** (`-a`): content-initiator가 파일 선택
- **Interactive Mode** (`-i`): 수동 카테고리/서브카테고리 선택
- **Direct Mode** (`--direct=FILE`): 특정 파일 작업

#### 2. 검증 모드 (3가지)
- **Immediate**: 섹션별 즉시 검증 (v4/v5 스타일)
- **Comprehensive**: Work Request Marker 오케스트레이션
- **Hybrid**: 즉시 검증 + 최종 종합 검증

#### 3. 핵심 기능
- ✅ 세션 ID 관리 (`generate_session_id()`)
- ✅ 파일 잠금 메커니즘 (`acquire_lock()`, `release_lock()`)
- ✅ UTF-8 인코딩 지원 (전역 환경 변수)
- ✅ 섹션별 재시도 로직 (`process_section()`)
- ✅ 품질 점수 계산 (`calculate_section_score()`)
- ✅ 미완성 파일 탐지 (`find_incomplete_file()`)

### 강점 (Preserve)

1. **잘 구조화된 코드**
   - 명확한 섹션 구분 (Helper Functions, Execution Modes, Main)
   - 일관된 함수 네이밍
   - 컬러 출력 함수 (`print_*`)

2. **견고한 락 메커니즘**
   - 파일별 락으로 병렬 실행 가능성 확보
   - 타임아웃 및 Force 모드 지원
   - 프로세스 정보 기록 (PID, 타임스탬프, 사용자)

3. **UTF-8 완벽 지원**
   - 다중 환경 변수 설정
   - Python/Node 인코딩 통합

4. **유연한 실행 모드**
   - 3가지 실행 모드로 다양한 시나리오 커버
   - 3가지 검증 모드로 사용자 선택 가능

5. **세션 컨텍스트 관리**
   - UUID 세션 ID로 에이전트 간 컨텍스트 공유
   - `--session-id` 및 `--resume` 지원

### 개선 필요 영역 (Critical Issues)

#### 1. ❌ Work Status Markers 기반 실행 부족

**현재 상태**:
```bash
# Line 666-675: 하드코딩된 에이전트 순서
local content_agents=("content-initiator" "overview-writer" "concepts-writer"
                      "visualization-writer" "practice-writer" "quiz-writer")

for agent in "${content_agents[@]}"; do
    execute_claude_agent "$agent" "$session_id" "$is_first"
    is_first=false
done
```

**문제점**:
- CURRENT_AGENT 마커를 읽지 않음
- 완료된 에이전트를 건너뛰지 않음
- 항상 모든 에이전트를 순차 실행
- 재시작 시 중복 작업 발생

**영향**:
- 재시작 불가능 → 실패 시 처음부터 다시 시작
- 시간 낭비 → 이미 완료된 섹션 재생성
- 비용 증가 → Claude API 호출 중복

#### 2. ❌ 재시작 메커니즘 불명확

**현재 상태**:
```bash
# Line 310-387: find_incomplete_file()은 미완성 파일만 탐지
# 어떤 에이전트부터 재시작할지는 결정하지 않음
```

**문제점**:
- 미완성 파일은 찾지만 재시작 지점은 모름
- HANDOFF LOG를 파싱하지 않음
- 마지막 완료 에이전트 식별 안 됨

**시나리오**:
```
파일 상태:
- Overview: 완료 ✅
- Core Concepts: 완료 ✅
- Visualization: 실패 ❌ (index.ts export 누락)
- Practice: 미완성 ⏳
- Quiz: 미완성 ⏳

현재 동작: content-initiator부터 다시 시작 (Overview/Concepts 재생성)
원하는 동작: visualization-writer부터 재시작 (실패 지점부터)
```

#### 3. ❌ 실패 정보 로깅 부족

**현재 상태**:
```bash
# Line 479-523: process_section()
# 실패 시 print_error만 출력, 마커에 기록하지 않음

print_error "Failed to complete $section_name after $MAX_RETRIES attempts"
return 1
```

**문제점**:
- 실패 이유가 파일에 기록되지 않음
- 다음 실행 시 실패 이력 모름
- 디버깅 어려움

**필요한 정보**:
```markdown
<!-- FAILURE LOG:
[2025-10-14 10:30] visualization-writer: index.ts export missing
[2025-10-14 10:35] quiz-writer: difficulty distribution error
-->
```

#### 4. ❌ 조건부 실행 불가능

**문제점**:
- `--skip-visualization` 같은 옵션 없음
- 특정 에이전트만 다시 실행 불가
- SKIP 케이스 처리 안 됨

**필요한 기능**:
```bash
# 시각화 건너뛰기
./content-generator-v6.sh -a --skip-visualization

# 특정 에이전트만 재실행
./content-generator-v6.sh -a --only=quiz-writer

# IMPROVEMENT_NEEDED에서 지정된 에이전트만 실행
# (자동으로 개선 대상 파악)
```

#### 5. ❌ 성능 로깅 부족

**문제점**:
- 각 에이전트 실행 시간 측정 안 됨
- 병목 지점 파악 어려움
- 성능 개선 근거 부족

**필요한 데이터**:
```
Agent                    | Time      | Status
-------------------------|-----------|--------
content-initiator        | 5s        | ✅
overview-writer          | 45s       | ✅
concepts-writer          | 120s      | ✅  (병목!)
visualization-writer     | 60s       | ✅
practice-writer          | 90s       | ✅
quiz-writer              | 75s       | ✅
content-validator        | 30s       | ✅

Total: 425s (7분 5초)
```

### 코드 구조 분석

#### 함수 분류

**Helper Functions** (Line 128-208):
- 출력: `print_header`, `print_info`, `print_success`, `print_error`, `print_warning`
- 세션: `generate_session_id`
- 락: `acquire_lock`, `release_lock`

**Quality Testing** (Line 209-308):
- `test_section`: 섹션 테스트 실행
- `calculate_section_score`: 섹션 점수 계산
- `find_incomplete_file`: 미완성 파일 탐지 ⚠️ (개선 필요)

**Execution** (Line 389-523):
- `execute_claude_agent`: Claude 에이전트 실행
- `process_section`: 섹션 처리 + 재시도

**File Selection** (Line 528-653):
- `select_category`: 카테고리 선택
- `select_subcategory`: 서브카테고리 선택
- `validate_direct_file`: 직접 파일 검증

**Execution Modes** (Line 659-819):
- `execute_comprehensive_mode`: 종합 모드 ⚠️ (개선 필요)
- `execute_immediate_mode`: 즉시 모드
- `execute_hybrid_mode`: 하이브리드 모드

**Main** (Line 825-1048):
- 설정, 모드 선택, 실행

#### 개선 영향도 분석

| 함수 | 현재 상태 | 개선 필요 | 영향도 | 우선순위 |
|------|----------|----------|--------|---------|
| `find_incomplete_file` | 부분 구현 | ✅ 마커 파싱 추가 | High | P0 |
| `execute_comprehensive_mode` | 하드코딩 | ✅ 마커 기반 실행 | High | P0 |
| `execute_claude_agent` | 동작함 | ✅ 성능 로깅 추가 | Medium | P1 |
| `process_section` | 동작함 | ✅ 실패 로깅 추가 | Medium | P1 |
| 새 함수 필요 | - | ✅ `determine_next_agent` | High | P0 |
| 새 함수 필요 | - | ✅ `parse_work_status_markers` | High | P0 |
| 새 함수 필요 | - | ✅ `handle_agent_failure` | Medium | P1 |

---

## 개선 아키텍처

### 2.1 Work Status Markers 기반 실행

#### 핵심 원칙

**현재 (하드코딩)**:
```bash
agents=("initiator" "overview" "concepts" "viz" "practice" "quiz")
for agent in "${agents[@]}"; do
    run $agent
done
```

**개선 (마커 기반)**:
```bash
while true; do
    current_agent=$(read_current_agent_from_marker $file)
    [ -z "$current_agent" ] && break  # Complete

    run $current_agent
done
```

#### 새로운 함수: `parse_work_status_markers()`

**목적**: 마크다운 파일에서 Work Status Markers 읽기

**입력**: 파일 경로
**출력**: JSON-like bash associative array

```bash
parse_work_status_markers() {
    local file_path="$1"

    # Extract markers
    local current_agent=$(grep "^<!-- CURRENT_AGENT:" "$file_path" | sed 's/.*CURRENT_AGENT: \(.*\) -->.*/\1/' | xargs)
    local progress=$(grep "^<!-- PROGRESS:" "$file_path" | sed 's/.*PROGRESS: \(.*\) -->.*/\1/' | xargs)
    local validation_score=$(grep "^<!-- VALIDATION_SCORE:" "$file_path" | sed 's/.*VALIDATION_SCORE: \([0-9]*\).*/\1/')

    # Parse HANDOFF LOG (last entry)
    local last_handoff=$(grep -A 20 "^<!-- HANDOFF LOG:" "$file_path" | grep "^\[" | tail -1)
    local last_status=$(echo "$last_handoff" | sed 's/^\[\([A-Z]*\)\].*/\1/')
    local last_agent=$(echo "$last_handoff" | sed 's/.*\] \([a-z-]*\):.*/\1/')

    # Parse IMPROVEMENT_NEEDED
    local improvement_needed=$(grep -A 10 "^<!-- IMPROVEMENT_NEEDED:" "$file_path" | grep "^  -" | head -1)
    local target_agent=""
    if [ -n "$improvement_needed" ]; then
        target_agent=$(echo "$improvement_needed" | sed 's/.*- \([a-z-]*\):.*/\1/')
    fi

    # Return as formatted string (bash array simulation)
    echo "CURRENT_AGENT=$current_agent"
    echo "PROGRESS=$progress"
    echo "VALIDATION_SCORE=$validation_score"
    echo "LAST_STATUS=$last_status"
    echo "LAST_AGENT=$last_agent"
    echo "IMPROVEMENT_TARGET=$target_agent"
}
```

**사용 예시**:
```bash
markers=$(parse_work_status_markers "$file")
current_agent=$(echo "$markers" | grep "^CURRENT_AGENT=" | cut -d= -f2)
```

#### 새로운 함수: `determine_next_agent()`

**목적**: 마커를 읽고 다음 실행할 에이전트 결정

**입력**: 파일 경로
**출력**: 에이전트 이름 (또는 "COMPLETE")

```bash
determine_next_agent() {
    local file_path="$1"

    # Parse markers
    local markers=$(parse_work_status_markers "$file_path")
    local current_agent=$(echo "$markers" | grep "^CURRENT_AGENT=" | cut -d= -f2)
    local progress=$(echo "$markers" | grep "^PROGRESS=" | cut -d= -f2)
    local improvement_target=$(echo "$markers" | grep "^IMPROVEMENT_TARGET=" | cut -d= -f2)

    # Case 1: IMPROVEMENT_NEEDED exists → run improvement target
    if [ -n "$improvement_target" ]; then
        echo "$improvement_target"
        return 0
    fi

    # Case 2: CURRENT_AGENT is empty → complete
    if [ -z "$current_agent" ] || [ "$current_agent" = "" ]; then
        echo "COMPLETE"
        return 0
    fi

    # Case 3: CURRENT_AGENT is set → run that agent
    echo "$current_agent"
    return 0
}
```

**동작 예시**:
```bash
# 시나리오 1: 정상 진행
<!-- CURRENT_AGENT: concepts-writer -->
→ determine_next_agent → "concepts-writer"

# 시나리오 2: 완료
<!-- CURRENT_AGENT: -->
→ determine_next_agent → "COMPLETE"

# 시나리오 3: 개선 필요
<!-- IMPROVEMENT_NEEDED:
  - quiz-writer: Difficulty distribution error
-->
→ determine_next_agent → "quiz-writer"
```

#### 개선된 `execute_comprehensive_mode()`

**Before** (하드코딩):
```bash
execute_comprehensive_mode() {
    local session_id="$1"

    local content_agents=("content-initiator" "overview-writer" ...)
    for agent in "${content_agents[@]}"; do
        execute_claude_agent "$agent" "$session_id" "$is_first"
        is_first=false
    done
}
```

**After** (마커 기반):
```bash
execute_comprehensive_mode() {
    local session_id="$1"
    local target_file="$2"  # NEW: file required for marker reading

    local is_first=true
    local max_iterations=20  # Safety limit
    local iteration=0

    while [ $iteration -lt $max_iterations ]; do
        # Determine next agent from markers
        local next_agent=$(determine_next_agent "$target_file")

        # Check if complete
        if [ "$next_agent" = "COMPLETE" ]; then
            print_success "Content generation complete!"
            break
        fi

        # Execute agent
        print_info "Executing agent: $next_agent (iteration $((iteration + 1)))"
        local start_time=$(date +%s)

        execute_claude_agent "$next_agent" "$session_id" "$is_first" "$target_file"

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # Log performance
        log_agent_performance "$next_agent" "$duration" "$target_file"

        is_first=false
        iteration=$((iteration + 1))

        # Safety check
        sleep 1  # Brief pause between agents
    done

    if [ $iteration -ge $max_iterations ]; then
        print_error "Max iterations reached. Possible infinite loop."
        return 1
    fi

    return 0
}
```

**Key Changes**:
- ✅ 마커 기반 다음 에이전트 결정
- ✅ 완료 조건 자동 감지
- ✅ 무한 루프 방지 (max_iterations)
- ✅ 성능 로깅 추가
- ✅ `target_file` 파라미터 필수

### 2.2 재시작 메커니즘

#### 핵심 시나리오

**시나리오 A: 중간 실패 후 재시작**
```
초기 실행:
✅ content-initiator
✅ overview-writer
✅ concepts-writer
❌ visualization-writer (실패: index.ts export 누락)
⏳ practice-writer (미실행)
⏳ quiz-writer (미실행)

파일 상태:
<!-- CURRENT_AGENT: visualization-writer -->
<!-- HANDOFF LOG:
[DONE] concepts-writer: 완료 - ...
[WAITING] visualization-writer: 진행중 - ...
-->

재시작:
./content-generator-v6.sh --direct=file.md --restart

동작:
→ determine_next_agent() → "visualization-writer"
→ visualization-writer부터 재실행
→ (Overview/Concepts는 건너뜀)
```

**시나리오 B: 개선 사이클**
```
초기 실행: 모든 섹션 완료, 검증 93/100
파일 상태:
<!-- CURRENT_AGENT: quiz-writer -->
<!-- VALIDATION_SCORE: 93/100 -->
<!-- IMPROVEMENT_NEEDED:
  - quiz-writer: Difficulty distribution 30/40/30 위반 (-5점)
  - concepts-writer: Expert 섹션 불충분 (-2점)
-->

재시작:
./content-generator-v6.sh --direct=file.md --restart

동작:
→ determine_next_agent() → "quiz-writer" (첫 번째 개선 대상)
→ quiz-writer 실행
→ concepts-writer 실행 (IMPROVEMENT_NEEDED에서 제거되면 자동 진행)
→ content-validator 실행
→ 100/100 달성 시 완료
```

#### 새로운 함수: `identify_restart_point()`

**목적**: 재시작 시 어디서부터 시작할지 결정

```bash
identify_restart_point() {
    local file_path="$1"

    # Parse markers
    local markers=$(parse_work_status_markers "$file_path")
    local current_agent=$(echo "$markers" | grep "^CURRENT_AGENT=" | cut -d= -f2)
    local improvement_target=$(echo "$markers" | grep "^IMPROVEMENT_TARGET=" | cut -d= -f2)
    local last_status=$(echo "$markers" | grep "^LAST_STATUS=" | cut -d= -f2)

    # Priority 1: IMPROVEMENT_NEEDED exists → restart from improvement target
    if [ -n "$improvement_target" ]; then
        echo "IMPROVEMENT:$improvement_target"
        return 0
    fi

    # Priority 2: CURRENT_AGENT set + PROGRESS != "완료" → restart from current
    if [ -n "$current_agent" ]; then
        echo "RESUME:$current_agent"
        return 0
    fi

    # Priority 3: Already complete
    echo "COMPLETE"
    return 0
}
```

**사용 예시**:
```bash
restart_point=$(identify_restart_point "$file")
case "$restart_point" in
    IMPROVEMENT:*)
        agent="${restart_point#IMPROVEMENT:}"
        print_info "Restarting from improvement target: $agent"
        ;;
    RESUME:*)
        agent="${restart_point#RESUME:}"
        print_info "Resuming from: $agent"
        ;;
    COMPLETE)
        print_success "File already complete"
        exit 0
        ;;
esac
```

#### 새로운 커맨드라인 옵션: `--restart`

```bash
# Parse command line options 섹션에 추가
RESTART_MODE=false

for arg in "$@"; do
    case "$arg" in
        --restart|-r) RESTART_MODE=true ;;
        # ... existing options ...
    esac
done
```

**동작 변경**:
```bash
# main() 함수 내
if [ "$RESTART_MODE" = "true" ]; then
    print_info "Restart mode enabled"

    # Identify restart point
    restart_point=$(identify_restart_point "$target_file")

    case "$restart_point" in
        IMPROVEMENT:*)
            agent="${restart_point#IMPROVEMENT:}"
            print_info "🔄 Restarting from improvement target: $agent"
            ;;
        RESUME:*)
            agent="${restart_point#RESUME:}"
            print_info "▶️  Resuming from: $agent"
            ;;
        COMPLETE)
            print_success "✅ File already complete, nothing to restart"
            exit 0
            ;;
    esac
fi
```

### 2.3 실패 처리

#### 새로운 함수: `handle_agent_failure()`

**목적**: 에이전트 실패 시 정보를 마커에 기록

```bash
handle_agent_failure() {
    local file_path="$1"
    local agent_name="$2"
    local error_message="$3"
    local attempt_num="$4"

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log to file markers (insert after HANDOFF LOG)
    local failure_entry="[FAILURE] $agent_name: $error_message (attempt $attempt_num) - $timestamp"

    # Create temp file with failure log
    local temp_file=$(mktemp)

    # Insert failure log after HANDOFF LOG:
    awk -v entry="$failure_entry" '
        /^<!-- HANDOFF LOG:/ {
            print
            print entry
            next
        }
        { print }
    ' "$file_path" > "$temp_file"

    mv "$temp_file" "$file_path"

    print_warning "Failure logged: $failure_entry"
}
```

**process_section() 개선**:
```bash
process_section() {
    local section_name="$1"
    local target_file="$2"
    local session_id="$3"
    local topic_name="$4"
    local is_first_section="$5"

    local attempt=1
    local score=0
    local current_is_first="$is_first_section"

    while [ $attempt -le $MAX_RETRIES ]; do
        print_info "Attempt $attempt/$MAX_RETRIES for $section_name"

        # Execute agent
        if ! execute_claude_agent "$section_name" "$session_id" "$current_is_first" "$target_file" "$topic_name"; then
            # NEW: Log execution failure
            handle_agent_failure "$target_file" "$section_name" "Execution failed" "$attempt"
        fi

        current_is_first="false"

        # Calculate score
        score=$(calculate_section_score "$target_file" "$section_name")
        print_info "Score for $section_name: $score/$PASSING_SCORE"

        if [ -n "$score" ] && [ "$score" -ge "$PASSING_SCORE" ]; then
            print_success "$section_name section completed successfully!"
            return 0
        else
            # NEW: Log quality failure
            local error_msg="Quality check failed: score $score/$PASSING_SCORE"
            handle_agent_failure "$target_file" "$section_name" "$error_msg" "$attempt"

            if [ $attempt -lt $MAX_RETRIES ]; then
                print_warning "Score below threshold, retrying..."
                sleep 2
            fi
        fi

        attempt=$((attempt + 1))
    done

    # NEW: Final failure log
    handle_agent_failure "$target_file" "$section_name" "Failed after $MAX_RETRIES attempts (score: $score)" "$MAX_RETRIES"

    print_error "Failed to complete $section_name after $MAX_RETRIES attempts (final score: $score)"
    return 1
}
```

#### 실패 로그 포맷

```markdown
<!-- HANDOFF LOG:
[WAITING] overview-writer: 대기중 - 2025-10-14 10:00
[DONE] overview-writer: 완료 - 2025-10-14 10:05
[WAITING] concepts-writer: 대기중 - 2025-10-14 10:05
[DONE] concepts-writer: 완료 - 2025-10-14 10:08
[WAITING] visualization-writer: 대기중 - 2025-10-14 10:08
[FAILURE] visualization-writer: index.ts export missing (attempt 1) - 2025-10-14 10:10
[FAILURE] visualization-writer: index.ts export missing (attempt 2) - 2025-10-14 10:12
[FAILURE] visualization-writer: Failed after 3 attempts (score: 60) - 2025-10-14 10:14
-->
```

### 2.4 조건부 실행

#### 새로운 커맨드라인 옵션

```bash
# Parse options
SKIP_AGENTS=()
ONLY_AGENT=""

for arg in "$@"; do
    case "$arg" in
        --skip-*)
            agent_name="${arg#--skip-}"
            SKIP_AGENTS+=("$agent_name")
            ;;
        --only=*)
            ONLY_AGENT="${arg#--only=}"
            ;;
        # ... existing options ...
    esac
done
```

#### 새로운 함수: `should_run_agent()`

**목적**: 에이전트를 실행해야 하는지 판단

```bash
should_run_agent() {
    local agent_name="$1"

    # Check --only option
    if [ -n "$ONLY_AGENT" ]; then
        if [ "$agent_name" = "$ONLY_AGENT" ]; then
            return 0  # Run only this agent
        else
            return 1  # Skip all others
        fi
    fi

    # Check --skip-* options
    for skip_agent in "${SKIP_AGENTS[@]}"; do
        if [ "$agent_name" = "$skip_agent" ] || [ "$agent_name" = "${skip_agent}-writer" ]; then
            print_info "Skipping $agent_name (--skip-$skip_agent)"
            return 1
        fi
    done

    # Default: run agent
    return 0
}
```

**execute_comprehensive_mode() 수정**:
```bash
# In the main loop
while [ $iteration -lt $max_iterations ]; do
    local next_agent=$(determine_next_agent "$target_file")

    if [ "$next_agent" = "COMPLETE" ]; then
        break
    fi

    # NEW: Check if agent should run
    if ! should_run_agent "$next_agent"; then
        # Update marker to skip this agent
        mark_agent_as_skipped "$target_file" "$next_agent"
        iteration=$((iteration + 1))
        continue
    fi

    # Execute agent
    execute_claude_agent "$next_agent" "$session_id" "$is_first" "$target_file"

    # ...
done
```

#### 사용 예시

```bash
# 시각화 건너뛰기
./content-generator-v6.sh -a --category=test --skip-visualization

# 퀴즈만 재생성
./content-generator-v6.sh --direct=file.md --only=quiz-writer

# 여러 에이전트 건너뛰기
./content-generator-v6.sh -a --skip-visualization --skip-practice
```

### 2.5 확장성

#### Filter 목록 관리

**현재**: 하드코딩된 배열
```bash
local content_agents=("content-initiator" "overview-writer" ...)
```

**개선 옵션 A**: Bash 배열 (단순)
```bash
# Global configuration
declare -a AGENT_PIPELINE=(
    "content-initiator"
    "overview-writer"
    "concepts-writer"
    "visualization-writer"
    "practice-writer"
    "quiz-writer"
    "content-validator"
)

# Agent metadata (associative array)
declare -A AGENT_METADATA=(
    ["content-initiator:required"]="true"
    ["content-initiator:skippable"]="false"
    ["visualization-writer:required"]="false"
    ["visualization-writer:skippable"]="true"
    # ...
)
```

**개선 옵션 B**: YAML 설정 파일 (고급, P2)
```yaml
# config/agents.yaml
agents:
  - name: content-initiator
    required: true
    skippable: false
    description: Initialize Work Status Markers

  - name: overview-writer
    required: true
    skippable: false
    description: Write Overview section

  - name: visualization-writer
    required: false
    skippable: true
    description: Create visualization components

  # ...
```

**결정**: 옵션 A 채택 (P1), 옵션 B는 향후 검토 (P2)

#### 새 Filter 추가 프로토콜

**Step 1**: `.claude/agents/` 에 새 에이전트 프롬프트 추가
```bash
.claude/agents/new-agent.md
```

**Step 2**: `content-generator-v6.sh`에서 배열에 추가
```bash
declare -a AGENT_PIPELINE=(
    "content-initiator"
    # ... existing agents ...
    "new-agent"  # NEW
    "content-validator"
)
```

**Step 3**: 에이전트 메타데이터 추가
```bash
declare -A AGENT_METADATA=(
    # ... existing ...
    ["new-agent:required"]="false"
    ["new-agent:skippable"]="true"
)
```

**Step 4**: `execute_claude_agent()`에 프롬프트 추가
```bash
case "$agent_name" in
    # ... existing cases ...
    "new-agent")
        prompt="new-agent로 새 기능 실행"
        ;;
esac
```

**최소 수정**: 3개 위치 (배열, 메타데이터, 프롬프트)

---

## 주요 알고리즘

### 3.1 다음 Filter 결정 알고리즘

```bash
determine_next_agent() {
    local file_path="$1"

    # Step 1: Parse Work Status Markers
    local markers=$(parse_work_status_markers "$file_path")
    local current_agent=$(echo "$markers" | grep "^CURRENT_AGENT=" | cut -d= -f2)
    local improvement_target=$(echo "$markers" | grep "^IMPROVEMENT_TARGET=" | cut -d= -f2)

    # Step 2: Priority-based decision
    # Priority 1: IMPROVEMENT_NEEDED exists → improvement target
    if [ -n "$improvement_target" ]; then
        echo "$improvement_target"
        return 0
    fi

    # Priority 2: CURRENT_AGENT is empty → complete
    if [ -z "$current_agent" ]; then
        echo "COMPLETE"
        return 0
    fi

    # Priority 3: CURRENT_AGENT is set → run that agent
    echo "$current_agent"
    return 0
}
```

**플로우차트**:
```
START
  ↓
Parse Markers
  ↓
IMPROVEMENT_TARGET exists? → YES → Return improvement_target
  ↓ NO
CURRENT_AGENT empty? → YES → Return "COMPLETE"
  ↓ NO
Return CURRENT_AGENT
  ↓
END
```

### 3.2 재시작 알고리즘

```bash
restart_from_last_checkpoint() {
    local file_path="$1"
    local session_id="$2"

    # Step 1: Identify restart point
    local restart_point=$(identify_restart_point "$file_path")

    # Step 2: Handle restart scenario
    case "$restart_point" in
        IMPROVEMENT:*)
            # Improvement cycle
            local agent="${restart_point#IMPROVEMENT:}"
            print_info "🔄 Restarting improvement cycle from: $agent"

            # Run improvement loop
            execute_comprehensive_mode "$session_id" "$file_path"
            ;;

        RESUME:*)
            # Resume from last incomplete agent
            local agent="${restart_point#RESUME:}"
            print_info "▶️  Resuming from: $agent"

            # Continue from this agent
            execute_comprehensive_mode "$session_id" "$file_path"
            ;;

        COMPLETE)
            print_success "✅ File already complete"
            return 0
            ;;
    esac
}
```

**시나리오별 동작**:

| 파일 상태 | CURRENT_AGENT | IMPROVEMENT_NEEDED | restart_point | 동작 |
|----------|---------------|-------------------|---------------|------|
| 초기 | content-initiator | (없음) | RESUME:content-initiator | 처음부터 |
| 중간 실패 | visualization-writer | (없음) | RESUME:visualization-writer | viz부터 |
| 개선 필요 | quiz-writer | quiz-writer: ... | IMPROVEMENT:quiz-writer | quiz부터 |
| 완료 | (빈 문자열) | (없음) | COMPLETE | 건너뜀 |

### 3.3 실패 처리 알고리즘

```bash
execute_agent_with_failure_handling() {
    local agent_name="$1"
    local session_id="$2"
    local target_file="$3"
    local max_retries=3

    local attempt=1

    while [ $attempt -le $max_retries ]; do
        print_info "Executing $agent_name (attempt $attempt/$max_retries)"

        # Execute agent
        local start_time=$(date +%s)
        local execution_result=0

        execute_claude_agent "$agent_name" "$session_id" "false" "$target_file" || execution_result=$?

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # Check result
        if [ $execution_result -eq 0 ]; then
            # Success
            log_agent_performance "$agent_name" "$duration" "SUCCESS" "$target_file"
            return 0
        else
            # Failure
            local error_msg="Execution failed with exit code $execution_result"
            handle_agent_failure "$target_file" "$agent_name" "$error_msg" "$attempt"
            log_agent_performance "$agent_name" "$duration" "FAILURE" "$target_file"

            if [ $attempt -lt $max_retries ]; then
                print_warning "Retrying in 5 seconds..."
                sleep 5
            fi
        fi

        attempt=$((attempt + 1))
    done

    # All retries failed
    print_error "$agent_name failed after $max_retries attempts"
    return 1
}
```

**플로우차트**:
```
START
  ↓
attempt = 1
  ↓
  ┌─────────────────┐
  │ Execute Agent   │
  └────────┬────────┘
           ↓
    Success? → YES → Log Success → Return 0
           ↓ NO
    Log Failure
           ↓
    attempt < max? → YES → Sleep 5s → attempt++ → LOOP
           ↓ NO
    Return 1 (Failed)
```

---

## 구현 계획

### 4.1 우선순위별 구현

#### Phase 1: P0 기능 (필수) - Day 1

**목표**: 기본 안정성 확보

1. **Work Status Markers 기반 실행** (4시간)
   - [ ] `parse_work_status_markers()` 구현
   - [ ] `determine_next_agent()` 구현
   - [ ] `execute_comprehensive_mode()` 개선
   - [ ] 테스트: 마커 읽기 정상 동작 확인

2. **재시작 메커니즘** (3시간)
   - [ ] `identify_restart_point()` 구현
   - [ ] `--restart` 옵션 추가
   - [ ] `find_incomplete_file()` 개선 (마커 파싱 통합)
   - [ ] 테스트: 중간 실패 후 재시작 시나리오

3. **실패 처리 및 로깅** (3시간)
   - [ ] `handle_agent_failure()` 구현
   - [ ] `process_section()` 개선 (실패 로깅)
   - [ ] `execute_agent_with_failure_handling()` 구현
   - [ ] 테스트: 실패 로그 기록 확인

**완료 기준**:
- ✅ 마커를 읽고 다음 에이전트 자동 결정
- ✅ 재시작 시 마지막 완료 지점부터 재개
- ✅ 실패 정보가 HANDOFF LOG에 기록

#### Phase 2: P1 기능 (권장) - Day 2

4. **조건부 Filter 실행** (3시간)
   - [ ] `--skip-{agent}` 옵션 추가
   - [ ] `--only={agent}` 옵션 추가
   - [ ] `should_run_agent()` 구현
   - [ ] `mark_agent_as_skipped()` 구현
   - [ ] 테스트: 시각화 건너뛰기 시나리오

5. **성능 로깅** (2시간)
   - [ ] `log_agent_performance()` 구현
   - [ ] 실행 시간 측정 추가
   - [ ] 성능 로그 파일 생성 (`logs/performance.log`)
   - [ ] 테스트: 성능 데이터 수집 확인

6. **Filter 목록 설정** (2시간)
   - [ ] `AGENT_PIPELINE` 배열 정의
   - [ ] `AGENT_METADATA` 메타데이터 정의
   - [ ] 배열 기반 실행 로직 통합
   - [ ] 테스트: 새 에이전트 추가 프로토콜 검증

**완료 기준**:
- ✅ `--skip-visualization` 동작
- ✅ `--only=quiz-writer` 동작
- ✅ 각 에이전트 실행 시간이 로그에 기록
- ✅ 새 에이전트 추가 시 3개 위치만 수정

#### Phase 3: 통합 테스트 및 검증 - Day 3

7. **통합 테스트** (4시간)
   - [ ] 정상 실행 시나리오 (전체 파이프라인)
   - [ ] 재시작 시나리오 (중간 실패 후)
   - [ ] 개선 사이클 시나리오 (IMPROVEMENT_NEEDED)
   - [ ] 조건부 실행 시나리오 (--skip, --only)
   - [ ] 파일럿 콘텐츠 생성 및 파서 테스트

8. **문서화** (2시간)
   - [ ] README 업데이트 (새로운 옵션 설명)
   - [ ] 설계 문서 최종화
   - [ ] 사용 예시 추가

9. **롤백 계획** (1시간)
   - [ ] v6 스크립트 백업 (`content-generator-v6.sh.backup`)
   - [ ] 롤백 절차 문서화

**완료 기준**:
- ✅ 모든 시나리오 테스트 통과
- ✅ 파일럿 콘텐츠 생성 성공 (파서 테스트 통과)
- ✅ 문서 완료
- ✅ 백업 존재

### 4.2 단계별 코드 수정

#### 파일 수정 위치

| 영역 | 현재 라인 | 수정 내용 | 우선순위 |
|------|----------|----------|---------|
| Helper Functions | 128-208 | 새 함수 추가 | P0 |
| Quality Testing | 209-308 | `find_incomplete_file` 개선 | P0 |
| Execution | 389-523 | 실패 처리 추가 | P0 |
| Execution Modes | 659-819 | `execute_comprehensive_mode` 개선 | P0 |
| Command Options | 52-106 | 새 옵션 추가 | P1 |
| Main | 825-1048 | 재시작 로직 통합 | P0 |

#### 백업 전략

```bash
# Before modification
cp scripts/content-generator-v6.sh scripts/content-generator-v6.sh.backup-$(date +%Y%m%d)

# After each phase
git add scripts/content-generator-v6.sh
git commit -m "Unit 4: Phase X - [feature description]"
```

### 4.3 기대 효과

| 개선 항목 | Before | After | 개선율 |
|----------|--------|-------|--------|
| 재시작 지점 | 항상 처음부터 | 실패 지점부터 | 50-80% 시간 절감 |
| 실패 디버깅 | 로그 없음 | HANDOFF LOG에 기록 | 100% 개선 |
| 조건부 실행 | 불가능 | `--skip-*` 지원 | 새 기능 |
| 성능 분석 | 불가능 | 실행 시간 로깅 | 새 기능 |
| 확장성 | 4개 위치 수정 | 3개 위치 수정 | 25% 개선 |

---

## 로깅 및 모니터링

### 5.1 성능 로그

#### 로그 파일 구조

```
logs/
  ├── performance.log        # 성능 데이터
  ├── execution.log          # 실행 로그
  └── errors.log             # 에러 로그
```

#### `log_agent_performance()` 구현

```bash
log_agent_performance() {
    local agent_name="$1"
    local duration="$2"
    local status="$3"  # SUCCESS or FAILURE
    local target_file="$4"

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_dir="$PROJECT_ROOT/logs"
    local log_file="$log_dir/performance.log"

    mkdir -p "$log_dir"

    # Log format: timestamp | agent | duration | status | file
    echo "$timestamp | $agent_name | ${duration}s | $status | $(basename "$target_file")" >> "$log_file"

    if [ "$DEBUG_MODE" = "true" ]; then
        print_info "[PERF] $agent_name: ${duration}s ($status)"
    fi
}
```

#### 성능 로그 예시

```
2025-10-14 10:00:00 | content-initiator | 5s | SUCCESS | 01-what-is-react.md
2025-10-14 10:00:05 | overview-writer | 45s | SUCCESS | 01-what-is-react.md
2025-10-14 10:00:50 | concepts-writer | 120s | SUCCESS | 01-what-is-react.md
2025-10-14 10:02:50 | visualization-writer | 60s | SUCCESS | 01-what-is-react.md
2025-10-14 10:03:50 | practice-writer | 90s | SUCCESS | 01-what-is-react.md
2025-10-14 10:05:20 | quiz-writer | 75s | SUCCESS | 01-what-is-react.md
2025-10-14 10:06:35 | content-validator | 30s | SUCCESS | 01-what-is-react.md
```

#### 성능 분석 스크립트

```bash
#!/bin/bash
# scripts/analyze-performance.sh

LOG_FILE="logs/performance.log"

echo "=== Performance Analysis ==="
echo

echo "Average duration by agent:"
awk -F' \\| ' '{
    agent=$2
    duration=$3
    gsub("s", "", duration)
    sum[agent] += duration
    count[agent]++
}
END {
    for (agent in sum) {
        avg = sum[agent] / count[agent]
        printf "  %-25s: %.1fs\n", agent, avg
    }
}' "$LOG_FILE" | sort -k2 -n -r

echo
echo "Failure rate by agent:"
awk -F' \\| ' '{
    agent=$2
    status=$4
    total[agent]++
    if (status ~ /FAILURE/) failures[agent]++
}
END {
    for (agent in total) {
        rate = (failures[agent] / total[agent]) * 100
        printf "  %-25s: %.1f%% (%d/%d)\n", agent, rate, failures[agent], total[agent]
    }
}' "$LOG_FILE" | sort -k2 -n -r
```

### 5.2 실행 로그

#### `log_execution()` 구현

```bash
log_execution() {
    local level="$1"  # INFO, WARNING, ERROR
    local message="$2"

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_dir="$PROJECT_ROOT/logs"
    local log_file="$log_dir/execution.log"

    mkdir -p "$log_dir"

    echo "[$timestamp] [$level] $message" >> "$log_file"

    # Also log errors to separate file
    if [ "$level" = "ERROR" ]; then
        echo "[$timestamp] $message" >> "$log_dir/errors.log"
    fi
}
```

**통합**:
```bash
# 기존 print_* 함수들 수정
print_info() {
    echo "ℹ️  $1"
    log_execution "INFO" "$1"
}

print_error() {
    echo "❌ $1"
    log_execution "ERROR" "$1"
}

print_warning() {
    echo "⚠️  $1"
    log_execution "WARNING" "$1"
}
```

### 5.3 진행 상황 표시

#### 프로그레스 바 구현

```bash
show_progress() {
    local current="$1"
    local total="$2"
    local agent_name="$3"

    local percent=$((current * 100 / total))
    local completed=$((current * 50 / total))
    local remaining=$((50 - completed))

    printf "\r["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %3d%% - %s" "$percent" "$agent_name"

    if [ $current -eq $total ]; then
        echo  # New line at completion
    fi
}
```

**사용**:
```bash
# In execute_comprehensive_mode
local total_agents=7
local current_agent_num=0

while ...; do
    current_agent_num=$((current_agent_num + 1))
    show_progress "$current_agent_num" "$total_agents" "$next_agent"

    execute_claude_agent "$next_agent" ...
done
```

**출력 예시**:
```
[████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 43% - visualization-writer
```

---

## 테스트 전략

### 6.1 단위 테스트 (함수별)

#### Test Suite 1: Marker Parsing

```bash
#!/bin/bash
# test/test-marker-parsing.sh

source scripts/content-generator-v6.sh

# Test parse_work_status_markers
test_parse_markers() {
    local test_file="test/fixtures/sample-with-markers.md"

    local result=$(parse_work_status_markers "$test_file")

    # Assert CURRENT_AGENT
    local current_agent=$(echo "$result" | grep "^CURRENT_AGENT=" | cut -d= -f2)
    if [ "$current_agent" != "concepts-writer" ]; then
        echo "❌ FAIL: Expected 'concepts-writer', got '$current_agent'"
        return 1
    fi

    echo "✅ PASS: parse_work_status_markers"
    return 0
}

# Test determine_next_agent
test_determine_next_agent() {
    local test_file="test/fixtures/sample-with-markers.md"

    local next_agent=$(determine_next_agent "$test_file")

    if [ "$next_agent" != "concepts-writer" ]; then
        echo "❌ FAIL: Expected 'concepts-writer', got '$next_agent'"
        return 1
    fi

    echo "✅ PASS: determine_next_agent"
    return 0
}

# Run tests
test_parse_markers
test_determine_next_agent
```

#### Test Suite 2: Restart Logic

```bash
#!/bin/bash
# test/test-restart-logic.sh

# Test identify_restart_point - IMPROVEMENT case
test_restart_improvement() {
    local test_file="test/fixtures/sample-improvement-needed.md"

    local result=$(identify_restart_point "$test_file")

    if [ "$result" != "IMPROVEMENT:quiz-writer" ]; then
        echo "❌ FAIL: Expected 'IMPROVEMENT:quiz-writer', got '$result'"
        return 1
    fi

    echo "✅ PASS: identify_restart_point (IMPROVEMENT)"
    return 0
}

# Test identify_restart_point - RESUME case
test_restart_resume() {
    local test_file="test/fixtures/sample-incomplete.md"

    local result=$(identify_restart_point "$test_file")

    if [ "$result" != "RESUME:visualization-writer" ]; then
        echo "❌ FAIL: Expected 'RESUME:visualization-writer', got '$result'"
        return 1
    fi

    echo "✅ PASS: identify_restart_point (RESUME)"
    return 0
}

# Test identify_restart_point - COMPLETE case
test_restart_complete() {
    local test_file="test/fixtures/sample-complete.md"

    local result=$(identify_restart_point "$test_file")

    if [ "$result" != "COMPLETE" ]; then
        echo "❌ FAIL: Expected 'COMPLETE', got '$result'"
        return 1
    fi

    echo "✅ PASS: identify_restart_point (COMPLETE)"
    return 0
}

# Run tests
test_restart_improvement
test_restart_resume
test_restart_complete
```

### 6.2 통합 테스트 (시나리오별)

#### Scenario 1: 정상 실행 (전체 파이프라인)

```bash
#!/bin/bash
# test/scenarios/test-full-pipeline.sh

echo "=== Scenario 1: Full Pipeline ==="

# Setup
TEST_FILE="test/fixtures/test-topic.md"
rm -f "$TEST_FILE"

# Execute
./scripts/content-generator-v6.sh --direct="$TEST_FILE" --test

# Verify
if ! grep -q "^# Overview" "$TEST_FILE"; then
    echo "❌ FAIL: Overview section missing"
    exit 1
fi

if ! grep -q "^# Core Concepts" "$TEST_FILE"; then
    echo "❌ FAIL: Core Concepts section missing"
    exit 1
fi

if ! grep -q "^# Code Patterns" "$TEST_FILE"; then
    echo "❌ FAIL: Code Patterns section missing"
    exit 1
fi

if ! grep -q "^# Experiments" "$TEST_FILE"; then
    echo "❌ FAIL: Experiments section missing"
    exit 1
fi

if ! grep -q "^# Quiz" "$TEST_FILE"; then
    echo "❌ FAIL: Quiz section missing"
    exit 1
fi

echo "✅ PASS: Full pipeline completed"
```

#### Scenario 2: 중간 실패 후 재시작

```bash
#!/bin/bash
# test/scenarios/test-restart-from-failure.sh

echo "=== Scenario 2: Restart from Failure ==="

# Setup: Create file with partial content
TEST_FILE="test/fixtures/test-restart.md"
cat > "$TEST_FILE" << 'EOF'
---
---

<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: visualization-writer -->
<!-- PROGRESS: 진행중 -->
<!-- HANDOFF LOG:
[DONE] overview-writer: 완료
[DONE] concepts-writer: 완료
[WAITING] visualization-writer: 진행중
-->

# Overview
[Content here]

# Core Concepts
[Content here]
EOF

# Execute with restart
./scripts/content-generator-v6.sh --direct="$TEST_FILE" --restart --test

# Verify: Should start from visualization-writer
log_content=$(cat logs/execution.log | tail -20)
if ! echo "$log_content" | grep -q "Resuming from: visualization-writer"; then
    echo "❌ FAIL: Did not restart from correct agent"
    exit 1
fi

echo "✅ PASS: Restart from failure point"
```

#### Scenario 3: 개선 사이클

```bash
#!/bin/bash
# test/scenarios/test-improvement-cycle.sh

echo "=== Scenario 3: Improvement Cycle ==="

# Setup: Create file with improvement needed
TEST_FILE="test/fixtures/test-improvement.md"
cat > "$TEST_FILE" << 'EOF'
---
---

<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: quiz-writer -->
<!-- VALIDATION_SCORE: 93/100 -->
<!-- IMPROVEMENT_NEEDED:
  - quiz-writer: Difficulty distribution error (-5점)
  - concepts-writer: Expert section insufficient (-2점)
-->

# Overview
[Complete content]

# Core Concepts
[Complete content]

# Code Patterns
[Complete content]

# Experiments
[Complete content]

# Quiz
[Incomplete - needs improvement]
EOF

# Execute
./scripts/content-generator-v6.sh --direct="$TEST_FILE" --restart --test

# Verify: Should run quiz-writer first
log_content=$(cat logs/execution.log | tail -20)
if ! echo "$log_content" | grep -q "Restarting from improvement target: quiz-writer"; then
    echo "❌ FAIL: Did not start from improvement target"
    exit 1
fi

echo "✅ PASS: Improvement cycle executed"
```

#### Scenario 4: 조건부 실행

```bash
#!/bin/bash
# test/scenarios/test-conditional-execution.sh

echo "=== Scenario 4: Conditional Execution ==="

# Test --skip-visualization
TEST_FILE="test/fixtures/test-skip-viz.md"
rm -f "$TEST_FILE"

./scripts/content-generator-v6.sh --direct="$TEST_FILE" --skip-visualization --test

# Verify: visualization-writer was skipped
log_content=$(cat logs/execution.log | tail -30)
if echo "$log_content" | grep -q "Executing agent: visualization-writer"; then
    echo "❌ FAIL: visualization-writer was not skipped"
    exit 1
fi

if echo "$log_content" | grep -q "Skipping visualization-writer"; then
    echo "✅ PASS: --skip-visualization worked"
else
    echo "❌ FAIL: Skip message not found"
    exit 1
fi

# Test --only=quiz-writer
TEST_FILE="test/fixtures/test-only-quiz.md"
rm -f "$TEST_FILE"

./scripts/content-generator-v6.sh --direct="$TEST_FILE" --only=quiz-writer --test

# Verify: only quiz-writer was executed
log_content=$(cat logs/execution.log | tail -30)
agent_count=$(echo "$log_content" | grep "Executing agent:" | wc -l)

if [ "$agent_count" -ne 1 ]; then
    echo "❌ FAIL: Expected 1 agent, got $agent_count"
    exit 1
fi

if echo "$log_content" | grep -q "Executing agent: quiz-writer"; then
    echo "✅ PASS: --only=quiz-writer worked"
else
    echo "❌ FAIL: quiz-writer was not executed"
    exit 1
fi
```

### 6.3 파일럿 콘텐츠 생성

#### Pilot Test Script

```bash
#!/bin/bash
# test/pilot-content-generation.sh

echo "=== Pilot Content Generation ==="

# Target: Generate 1 complete topic
PILOT_FILE="public/content/ko/javascript-core-concepts/01-variables/test-pilot.md"

# Clean start
rm -f "$PILOT_FILE"

# Execute full pipeline with improved script
./scripts/content-generator-v6.sh --direct="$PILOT_FILE"

# Run all parser tests
echo
echo "Running parser tests..."

test_results=()

for test in overview concepts patterns experiments quiz-raw; do
    echo -n "Testing $test... "
    if npx tsx "test/test-${test}.mjs" "$PILOT_FILE" >/dev/null 2>&1; then
        echo "✅ PASS"
        test_results+=("$test:PASS")
    else
        echo "❌ FAIL"
        test_results+=("$test:FAIL")
    fi
done

# Summary
echo
echo "=== Test Summary ==="
pass_count=0
fail_count=0

for result in "${test_results[@]}"; do
    if [[ "$result" == *":PASS" ]]; then
        ((pass_count++))
    else
        ((fail_count++))
    fi
done

echo "Passed: $pass_count"
echo "Failed: $fail_count"

if [ $fail_count -eq 0 ]; then
    echo
    echo "✅ Pilot content generation successful!"
    exit 0
else
    echo
    echo "❌ Pilot content generation had issues"
    exit 1
fi
```

### 6.4 성능 벤치마크

#### Benchmark Script

```bash
#!/bin/bash
# test/benchmark.sh

echo "=== Performance Benchmark ==="

# Test with 3 files
TEST_FILES=(
    "public/content/ko/javascript-core-concepts/01-variables/bench-1.md"
    "public/content/ko/javascript-core-concepts/01-variables/bench-2.md"
    "public/content/ko/javascript-core-concepts/01-variables/bench-3.md"
)

# Clean start
for file in "${TEST_FILES[@]}"; do
    rm -f "$file"
done

# Run benchmark
echo "Generating 3 files with improved orchestration..."
start_time=$(date +%s)

for file in "${TEST_FILES[@]}"; do
    echo "Processing $(basename "$file")..."
    ./scripts/content-generator-v6.sh --direct="$file" --test
done

end_time=$(date +%s)
total_duration=$((end_time - start_time))

# Analyze performance log
echo
echo "=== Performance Analysis ==="
./scripts/analyze-performance.sh

echo
echo "Total time: ${total_duration}s"
echo "Average per file: $((total_duration / ${#TEST_FILES[@]}))s"
```

---

## 다음 단계

### 완료 체크리스트

#### Phase 1: P0 (필수)
- [ ] `parse_work_status_markers()` 구현 및 테스트
- [ ] `determine_next_agent()` 구현 및 테스트
- [ ] `execute_comprehensive_mode()` 개선
- [ ] `identify_restart_point()` 구현
- [ ] `--restart` 옵션 추가
- [ ] `handle_agent_failure()` 구현
- [ ] 실패 로깅 통합
- [ ] 단위 테스트 작성

#### Phase 2: P1 (권장)
- [ ] `--skip-{agent}` 옵션 추가
- [ ] `--only={agent}` 옵션 추가
- [ ] `should_run_agent()` 구현
- [ ] `log_agent_performance()` 구현
- [ ] 성능 로그 파일 생성
- [ ] `AGENT_PIPELINE` 배열 정의
- [ ] 조건부 실행 테스트

#### Phase 3: 통합 테스트
- [ ] 정상 실행 시나리오 테스트
- [ ] 재시작 시나리오 테스트
- [ ] 개선 사이클 시나리오 테스트
- [ ] 조건부 실행 시나리오 테스트
- [ ] 파일럿 콘텐츠 생성 및 검증
- [ ] 성능 벤치마크 실행

#### 문서화 및 배포
- [ ] README 업데이트
- [ ] 설계 문서 최종화
- [ ] 백업 생성
- [ ] Unit 4 완료 문서 작성

### Unit 5로 진행

Unit 4 완료 후:
1. 개선된 스크립트로 실제 콘텐츠 생성
2. 성능 데이터 수집 및 분석
3. Unit 5 (품질 측정 방법 구축)로 진행

---

**Document Status**: In Progress
**Last Updated**: 2025-10-14
**Next Update**: After P0 implementation
