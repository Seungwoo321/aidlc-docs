# Unit 4: Orchestration 스크립트 개선

## 개요

**목적**: `content-generator-v6.sh`를 Unit 1~3의 개선 사항을 반영하여 재구성하고, 재시작 메커니즘, 병렬 실행, 세밀한 오류 처리를 추가한다.

**현재 문제점**:
- 파싱 로직이 스크립트 내부에 하드코딩됨
- 계약 검증 로직 부재
- 중간 실패 시 전체 재실행 필요 (부분 재시작 어려움)
- 에이전트 간 독립성 부족 (순차 실행만 가능)
- 오류 메시지가 불명확

**개선 방향**:
- Unit 1의 마커 유틸리티 활용
- Unit 2의 계약 검증 통합
- Unit 3의 개선된 프롬프트 기반 실행
- 재시작 지점 자동 식별
- 선택적 병렬 실행 지원
- 명확한 오류 보고 및 로깅

## 범위

### In Scope
1. **스크립트 모듈화**
   - 마커 파싱 로직을 `scripts/lib/work-status-markers.sh`로 분리
   - 계약 검증 로직을 `scripts/lib/contract-validator.sh`로 분리
   - 공통 유틸리티를 `scripts/lib/common-utils.sh`로 분리

2. **재시작 메커니즘 강화**
   - Work Status Markers 기반 재시작 지점 자동 식별
   - `--resume` 모드 개선
   - 실패한 에이전트부터 재실행
   - 개선 요청 에이전트부터 재실행

3. **계약 검증 통합**
   - 에이전트 실행 전 Precondition 검증
   - 에이전트 실행 후 Postcondition 검증
   - 검증 실패 시 명확한 오류 메시지

4. **오류 처리 및 로깅 개선**
   - 에이전트별 로그 파일 생성
   - 실패 원인 자동 분류
   - 복구 제안 메시지

5. **병렬 실행 지원 (선택적)**
   - 독립적인 에이전트 병렬 실행 (예: visualization-writer는 practice-writer와 독립)
   - 의존성 그래프 기반 실행 순서 결정

### Out of Scope
- 새로운 에이전트 추가 (기존 7개만 처리)
- 클라우드 실행 환경 지원 (로컬 Bash만)
- GUI 또는 웹 인터페이스 (CLI만)

## 아키텍처 컨텍스트

**Pipeline Architecture 관점**:
- **Pipeline Orchestrator**: 스크립트가 Filter들의 실행 순서 제어
- **Backpressure Handling**: 에이전트 실패 시 파이프라인 중단 및 재시도
- **Monitoring**: 각 Filter의 처리 시간 및 성능 추적

**DDD 경량화 관점**:
- **Application Service**: 오케스트레이션 스크립트가 Application Layer 역할
- **Domain Services**: 마커 유틸리티, 계약 검증이 Domain Service
- **Infrastructure**: Bash 스크립트, 파일 시스템, Claude CLI

## 작업 항목

### 1. 스크립트 모듈화
**예상 산출물**:
- `scripts/lib/common-utils.sh`
- `scripts/lib/work-status-markers.sh` (Unit 1에서 생성)
- `scripts/lib/contract-validator.sh` (Unit 2에서 생성)
- `scripts/content-generator-v7.sh` (v6 업그레이드)

**common-utils.sh 함수 목록**:
```bash
# 로깅
log_info() { echo "ℹ️  $1" | tee -a "$LOG_FILE"; }
log_success() { echo "✅ $1" | tee -a "$LOG_FILE"; }
log_error() { echo "❌ $1" | tee -a "$LOG_FILE"; }
log_warning() { echo "⚠️  $1" | tee -a "$LOG_FILE"; }

# 파일 잠금
acquire_file_lock() { ... }
release_file_lock() { ... }

# 세션 ID 생성
generate_session_id() { ... }

# 타임스탬프
get_timestamp() { date -u +"%Y-%m-%dT%H:%M:%S%z"; }
```

### 2. 재시작 메커니즘 강화
**현재 v6 기능**: `identify_restart_point()` 함수 존재

**개선 사항 (IMPROVE 이벤트 타입 반영)**:
```bash
# 재시작 지점 자동 결정
auto_determine_restart_point() {
    local file_path=$1

    # Priority 1: IMPROVEMENT_NEEDED 확인
    if has_improvement_needed "$file_path"; then
        local target_agent=$(get_improvement_target_agent "$file_path")
        echo "IMPROVEMENT:$target_agent"
        return
    fi

    # Priority 2: CURRENT_AGENT 확인
    local current_agent=$(get_current_agent "$file_path")
    if [ -n "$current_agent" ]; then
        echo "RESUME:$current_agent"
        return
    fi

    # Priority 3: HANDOFF LOG 마지막 [FAILURE] 확인
    local last_failure=$(grep -o '\[FAILURE\] [^ ]*' "$file_path" | tail -1 | cut -d' ' -f2)
    if [ -n "$last_failure" ]; then
        echo "RETRY:$last_failure"
        return
    fi

    # Priority 4: [COMPLETE] 확인
    if grep -q '\[COMPLETE\]' "$file_path"; then
        echo "COMPLETE"
        return
    fi

    # Priority 5: 마지막 [DONE] 또는 [IMPROVE] 이후 다음 에이전트
    local last_completed=$(grep -E '\[(DONE|IMPROVE)\]' "$file_path" | tail -1 | cut -d' ' -f2)
    if [ -n "$last_completed" ]; then
        local next_agent=$(get_next_agent "$last_completed")
        echo "RESUME:$next_agent"
        return
    fi

    # 기본: 시작점
    echo "START:content-initiator"
}
```

**IMPROVE vs DONE 구분 처리**:
- **DONE**: 에이전트의 첫 번째 작업 완료 → 다음 에이전트로 진행
- **IMPROVE**: 개선 작업 완료 → 다음 에이전트로 진행 (동일 동작)
- 재시작 지점 식별 시 둘 다 "완료된 에이전트"로 취급

### 3. 계약 검증 통합
**v7 실행 흐름**:
```bash
execute_agent_with_validation() {
    local agent_name=$1
    local file_path=$2
    local session_id=$3

    # 1. Precondition 검증
    log_info "Validating preconditions for $agent_name..."
    if ! validate_preconditions "$agent_name" "$file_path"; then
        log_error "Precondition validation failed for $agent_name"
        return 1
    fi

    # 2. 에이전트 실행
    log_info "Executing $agent_name..."
    local start_time=$(date +%s)
    execute_claude_agent "$agent_name" "$session_id" "$file_path"
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # 3. Postcondition 검증
    if [ $exit_code -eq 0 ]; then
        log_info "Validating postconditions for $agent_name..."
        if ! validate_postconditions "$agent_name" "$file_path"; then
            log_error "Postcondition validation failed for $agent_name"
            return 1
        fi
    fi

    # 4. 로깅
    log_agent_performance "$agent_name" "$duration" "$exit_code"

    return $exit_code
}
```

### 4. 오류 처리 및 로깅 개선

**HANDOFF LOG 이벤트 타입 (from Unit 1)**:

오케스트레이션 스크립트는 Work Status Markers의 HANDOFF LOG를 읽고 다음 6가지 이벤트 타입을 처리해야 합니다:

| Event Type | 의미 | 사용 시점 |
|-----------|------|----------|
| **START** | 파이프라인 시작 | content-initiator 초기화 |
| **DONE** | 첫 번째 작업 완료 | 에이전트의 첫 실행 성공 |
| **IMPROVE** | 개선 작업 완료 | IMPROVEMENT_NEEDED 응답 후 재실행 완료 |
| **FAILURE** | 작업 실패 | 에이전트 실행 오류 |
| **SKIP** | 건너뛰기 | --skip 옵션 사용 |
| **COMPLETE** | 최종 완료 | content-validator 최종 승인 (VALIDATION_SCORE ≥ 90) |

**HANDOFF LOG 형식**:
```
[EVENT_TYPE] agent-name | message | YYYY-MM-DDTHH:MM:SS+09:00
```

**예시**:
```html
<!-- WORK STATUS MARKERS
...
- [START] content-initiator | 파이프라인 시작 | 2025-10-16T10:00:00+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [DONE] concepts-writer | Core Concepts 섹션 작성 완료 | 2025-10-16T10:20:00+09:00
- [DONE] content-validator | 품질 검증 완료 (점수: 65/100, 개선 필요) | 2025-10-16T10:35:00+09:00
- [IMPROVE] concepts-writer | Expert 난이도 확장 완료 | 2025-10-16T10:42:00+09:00
- [COMPLETE] content-validator | 최종 승인 (점수: 92/100) | 2025-10-16T10:50:00+09:00
-->
```

**로그 구조**:
```
logs/
├── content-generator-v7.log (전체 실행 로그)
├── sessions/
│   └── [session-id]/
│       ├── content-initiator.log
│       ├── overview-writer.log
│       ├── concepts-writer.log
│       ├── ...
│       └── execution-summary.json
```

**execution-summary.json 형식**:
```json
{
  "session_id": "uuid",
  "start_time": "2025-10-16T10:00:00+09:00",
  "end_time": "2025-10-16 10:50:00+09:00",
  "target_file": "public/content/ko/.../file.md",
  "status": "success|failed|partial",
  "agents_executed": [
    {
      "agent": "overview-writer",
      "start": "2025-10-16T10:05:00+09:00",
      "end": "2025-10-16T10:12:00+09:00",
      "duration_seconds": 420,
      "status": "success",
      "precondition_check": "passed",
      "postcondition_check": "passed"
    },
    // ...
  ],
  "errors": [
    {
      "agent": "quiz-writer",
      "error_type": "postcondition_failed",
      "error_message": "Section structure validation failed",
      "suggestion": "Check Quiz section header format"
    }
  ]
}
```

### 5. 병렬 실행 지원 (선택적 기능)
**의존성 그래프**:
```
content-initiator
    ↓
overview-writer
    ↓
concepts-writer
    ├─→ visualization-writer (optional, can skip)
    └─→ practice-writer
         ↓
    quiz-writer
         ↓
content-validator
```

**병렬 실행 가능 구간**:
- visualization-writer와 practice-writer는 concepts-writer 완료 후 병렬 실행 가능
- 단, 현재 파일 잠금 메커니즘과 충돌 가능성 검토 필요

**구현 방안**:
```bash
# --parallel 플래그 추가
if [ "$PARALLEL_MODE" = "true" ]; then
    # concepts-writer 완료 후
    visualization-writer & pid1=$!
    practice-writer & pid2=$!
    wait $pid1 $pid2
else
    # 순차 실행 (기본)
    visualization-writer
    practice-writer
fi
```

### 6. 명령줄 인터페이스 개선
**v7 추가 옵션**:
```bash
# 재시작 옵션
--resume               # 자동으로 재시작 지점 식별
--from=AGENT_NAME      # 특정 에이전트부터 시작

# 검증 옵션
--validate-only        # 계약 검증만 수행 (실행 X)
--skip-validation      # 계약 검증 건너뛰기 (빠른 실행)

# 로깅 옵션
--verbose              # 상세 로깅
--log-dir=PATH         # 로그 디렉터리 지정
--json-summary         # execution-summary.json 생성

# 병렬 실행 옵션
--parallel             # 가능한 에이전트 병렬 실행

# 예시
./content-generator-v7.sh --direct=file.md --resume --verbose --json-summary
./content-generator-v7.sh --validate-only --direct=file.md
./content-generator-v7.sh --from=quiz-writer --direct=file.md
```

## 의존성

### 입력 의존성
- **Unit 1**: `scripts/lib/work-status-markers.sh` 사용
- **Unit 2**: `scripts/lib/contract-validator.sh` 사용
- **Unit 3**: 개선된 에이전트 프롬프트 실행

### 출력 의존성
- **Unit 5**: 실행 로그 및 summary.json을 품질 분석에 활용

## 성공 기준

1. **모듈화 완료**: 마커/검증 로직이 별도 라이브러리로 분리
2. **재시작 신뢰성**: 중간 실패 후 정확한 지점에서 재시작 가능
3. **검증 통합**: 모든 에이전트 실행 전후 계약 검증
4. **로그 명확성**: 오류 발생 시 원인과 복구 방법 즉시 파악 가능
5. **성능**: 병렬 실행 시 최소 20% 시간 단축

## 예상 산출물 리스트

1. `scripts/lib/common-utils.sh`
2. `scripts/content-generator-v7.sh`
3. `logs/sessions/[session-id]/execution-summary.json` (실행 시 자동 생성)
4. `docs/aidlc-docs/guides/orchestration-guide.md` (사용자 가이드)
5. `test/test-orchestration.sh` (오케스트레이션 로직 테스트)

## 예상 작업 기간

- 스크립트 모듈화: 2일
- 재시작 메커니즘 강화: 1일
- 계약 검증 통합: 2일
- 오류 처리 및 로깅 개선: 2일
- 병렬 실행 지원 (선택): 2일
- 테스트 및 문서화: 1일
- **총 예상: 10일 (병렬 실행 포함) 또는 8일 (순차만)**

## 리스크 및 완화 방안

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| v6 → v7 마이그레이션 시 기능 누락 | 높음 | v6 기능 체크리스트 작성 후 1:1 매핑 검증 |
| 병렬 실행 시 파일 잠금 충돌 | 중간 | 초기엔 순차 실행만, 병렬은 Phase 2로 |
| 계약 검증 오버헤드로 속도 저하 | 낮음 | --skip-validation 옵션 제공 |
| 로그 파일 급증으로 디스크 공간 부족 | 낮음 | 로그 로테이션 및 정리 스크립트 추가 |

## 질문 사항

### Question 1: v6와 v7 공존 ✅ 결정됨
**질문**: v6와 v7를 동시에 유지할까요?

**사용자 답변**:
> 유지하세요 v6의 이름을 바꿀 필요가 있나요? 기존 스크립트를 유지하기 위해서 v*와 같은 이름을 사용하고 있는거 아닌가요? 그리고 새 버전을 작성하더라도 "cladue -p"로 프롬프트에서 서브에이전트를 언급해서 실행하는 방식은 유지해야 됩니다. 이는 이미 검증된 사항이니까 주의하세요.

**최종 결정**: **C - v6와 v7 동시 유지 (권장 B와 유사)**

**구현 방식**:
1. **버전 관리 전략**:
   - 기존 `content-generator-v6.sh` 파일 그대로 보존 (백업용)
   - 새로운 `content-generator-v7.sh` 파일 생성 (개선 버전)
   - v* 네이밍 컨벤션 유지

2. **서브에이전트 실행 방식 보존** (필수):
   - `claude -p "[subagent-name]"` 방식 유지
   - 프롬프트에서 서브에이전트 명시적 언급 방식 유지
   - 검증된 실행 패턴 변경 금지

3. **구현 영향**:
   - 산출물: `content-generator-v7.sh` (신규 생성)
   - v6 파일: 그대로 보존 (이름 변경 불필요)
   - 롤백 가능성: v6로 언제든 되돌릴 수 있음

4. **공존 기간**:
   - v7 안정화까지 v6와 v7 병행 사용
   - v7 검증 완료 후 v6는 레거시로 유지

---

### Question 2: 병렬 실행 우선순위 ✅ 결정됨 (명확화)
**질문**: 병렬 실행 기능을 이번 Unit에 포함할까요?

**사용자 답변**:
> 아니요, 이미 병렬 실행이 가능합니다. 파이프라인 내의 각 섹션은 병렬로 실행되면 안됩니다. 문서가 1개의 파일안에 각 섹션이 순서대로 작성되어야 하니까요. lock파일을 토픽별로 만들고 있기 때문에 동시에 실행되서 충돌되는 것을 막고 있기 때문에 다른 토픽에 대해서는 병렬로 실행이 가능합니다. 오케스트레이션하는 쉘 스크립트 자체가 주제별로 여러 프로세스로 실행되면 됩니다.

**최종 결정**: **병렬 실행 이미 구현됨 - 추가 작업 불필요**

**⚠️ 중요 명확화**:
1. **현재 병렬 실행 메커니즘**:
   - **토픽 레벨 병렬**: 서로 다른 토픽은 동시 실행 가능
   - **파일 잠금**: lock 파일로 토픽별 충돌 방지
   - **파이프라인 레벨 순차**: 단일 파일 내 에이전트는 순차 실행 필수

2. **병렬 실행 불가 영역**:
   - 단일 마크다운 파일의 각 섹션 (Overview → Concepts → Practice → Quiz)
   - 에이전트 간 의존성이 있는 경우

3. **병렬 실행 가능 영역**:
   - 서로 다른 토픽의 콘텐츠 생성
   - 예: `topic-A.md` 생성 중 + `topic-B.md` 생성 중 (동시 실행 OK)

4. **Unit 4 작업 범위 조정**:
   - 에이전트 간 병렬 실행 기능 제거
   - 기존 토픽 레벨 병렬 실행 메커니즘 유지
   - lock 파일 관리 개선에만 집중

**Lock 파일 메커니즘 상세 (from Unit 1 Finalized Design)**:

```bash
# Lock 파일 구조
{
  "agent": "overview-writer",
  "pid": 12345,
  "started_at": "2025-10-16T10:05:00+09:00",
  "file_path": "/path/to/content.md"
}

# PID 기반 프로세스 생존 확인
check_lock_file() {
    local lock_file=$1

    if [ -f "$lock_file" ]; then
        local pid=$(jq -r '.pid' "$lock_file")

        # 프로세스 존재 여부 확인
        if ps -p $pid > /dev/null 2>&1; then
            echo "Lock is active (PID: $pid)"
            return 1  # Lock 유효
        else
            echo "Stale lock detected (PID: $pid not found), removing..."
            rm -f "$lock_file"
            return 0  # Lock 제거됨
        fi
    fi

    return 0  # Lock 없음
}

# Lock 획득
acquire_lock() {
    local file_path=$1
    local agent_name=$2
    local lock_file="${file_path}.lock"

    check_lock_file "$lock_file" || {
        log_error "File is locked by another process"
        return 1
    }

    # Lock 파일 생성
    jq -n \
        --arg agent "$agent_name" \
        --arg pid "$$" \
        --arg started "$(date -u +"%Y-%m-%dT%H:%M:%S%z")" \
        --arg path "$file_path" \
        '{agent: $agent, pid: ($pid|tonumber), started_at: $started, file_path: $path}' \
        > "$lock_file"
}

# Lock 해제
release_lock() {
    local file_path=$1
    rm -f "${file_path}.lock"
}
```

**⚠️ 중요**:
- **시간 기반 자동 제거 안 함**: 콘텐츠 생성은 10~30분 소요되므로 시간 기반 제거는 작업 중 충돌 유발
- **PID 기반 확인**: `ps -p $PID` 명령으로 프로세스 존재 확인 후 없으면 제거
- **프로세스 강제 중단 대응**: 프로세스가 강제 종료되어도 다음 실행 시 stale lock 자동 제거

---

### Question 3: execution-summary.json 필수 여부 ✅ 결정됨
**질문**: 매 실행마다 execution-summary.json을 생성할까요?

**최종 결정**: **A - 항상 생성 (기본)**

**동작 방식**:
- 모든 실행마다 `logs/sessions/[session-id]/execution-summary.json` 자동 생성
- Unit 5의 품질 분석에 필수 데이터 제공
- 실행 이력 추적 및 성능 분석에 활용

---

### Question 4: Claude CLI 래핑 ✅ 결정됨 (조건부)
**질문**: Claude CLI 호출을 래핑할까요?

**최종 결정**: **B - 함수로 래핑 (단, 실행 방식 보존)**

**구현 조건**:
1. **래핑 함수 작성**:
   ```bash
   execute_claude_agent() {
       local agent_name=$1
       local session_id=$2
       local file_path=$3

       # 오류 처리 및 로깅 추가
       log_info "Executing agent: $agent_name"

       # 기존 실행 방식 유지 (중요!)
       $CLAUDE_PATH -p "[subagent-name]" --session-id "$session_id"

       local exit_code=$?
       log_agent_result "$agent_name" "$exit_code"
       return $exit_code
   }
   ```

2. **⚠️ 필수 보존 사항** (Question 1 연계):
   - `$CLAUDE_PATH -p "..." --session-id ...` 실행 방식 그대로 유지
   - 프롬프트 기반 서브에이전트 실행 패턴 변경 금지
   - 검증된 실행 메커니즘 보존

3. **개선 사항**:
   - 중앙 집중화된 오류 처리
   - 일관된 로깅 형식
   - 실행 시간 측정 자동화
