# 에이전트 핸드오프 가이드

## 문서 정보

**버전**: 1.0
**작성일**: 2025-10-17
**상태**: Final
**대상 독자**: 에이전트 개발자 (Unit 3 참조용)

**목적**: 에이전트가 Work Status Markers를 사용하여 작업을 시작하고 완료하는 방법을 명확히 정의합니다.

**참조 문서**:
- `work-status-markers-spec.md` - Work Status Markers 명세
- `logical_design.md` - Section 4 (인터페이스), Section 5 (재시작 메커니즘)
- `domain_design.md` - Section 4 (Handoff Protocol), Section 5 (Domain Invariants)

---

## 목차

1. [개요](#1-개요)
2. [에이전트 시작 시 체크리스트](#2-에이전트-시작-시-체크리스트-precondition)
3. [에이전트 완료 시 체크리스트](#3-에이전트-완료-시-체크리스트-postcondition)
4. [HANDOFF LOG 엔트리 추가 예시](#4-handoff-log-엔트리-추가-예시)
5. [인터페이스 사용법](#5-인터페이스-사용법)
6. [재시작 메커니즘](#6-재시작-메커니즘)
7. [예외 상황 처리](#7-예외-상황-처리)

---

# 1. 개요

## 1.1 핵심 원칙

**에이전트 자율성**: 에이전트는 Section 4의 Handoff Protocol을 따라 **마커를 직접 읽고 쓴다**.

**에이전트 책임**:
- **읽기**: Precondition 확인 (CURRENT_AGENT, STATUS, 필수 입력 섹션)
- **쓰기**: Postcondition 보장 (HANDOFF LOG 추가, CURRENT_AGENT 업데이트, STATUS 업데이트, UPDATED 타임스탬프 갱신)
- **검증**: 출력 섹션 존재 여부 확인

**오케스트레이션 역할** (Unit 4):
- 에이전트 실행 환경 설정 (UTF-8 인코딩, 환경 변수)
- 에이전트 실행 전후 검증 (사전/사후 검증)
- 실패 시 재시도 또는 복구 처리
- Lock 파일 메커니즘으로 동시성 제어

## 1.2 파이프라인 흐름

```
[START] → content-initiator → overview-writer → concepts-writer →
visualization-writer → practice-writer → quiz-writer →
content-validator → [COMPLETE]
```

**비선형 흐름** (개선 요청 시):
```
content-validator → IMPROVEMENT_NEEDED 설정 →
특정 에이전트 재실행 → [IMPROVE] 엔트리 추가 →
content-validator → [COMPLETE]
```

---

# 2. 에이전트 시작 시 체크리스트 (Precondition)

에이전트가 작업을 시작하기 전에 반드시 확인해야 할 사항입니다.

## 2.1 Precondition 1: CURRENT_AGENT 확인

**목적**: 현재 자신의 차례인지 확인

**확인 방법**:
```bash
# 마커 파싱
current_agent=$(parse_work_status_markers "$file_path" | jq -r '.CURRENT_AGENT')

# 자신의 이름과 일치하는지 확인
if [ "$current_agent" != "overview-writer" ]; then
    echo "ERROR: Not my turn. CURRENT_AGENT is $current_agent"
    exit 1
fi
```

**예시**:
- ✅ CURRENT_AGENT: `overview-writer` (overview-writer 에이전트인 경우)
- ❌ CURRENT_AGENT: `concepts-writer` (overview-writer 에이전트인 경우)

---

## 2.2 Precondition 2: STATUS 확인

**목적**: 파이프라인이 실행 가능한 상태인지 확인

**확인 방법**:
```bash
# STATUS 파싱
status=$(parse_work_status_markers "$file_path" | jq -r '.STATUS')

# STATUS가 IN_PROGRESS 또는 PENDING인지 확인
if [[ ! "$status" =~ ^(PENDING|IN_PROGRESS)$ ]]; then
    echo "ERROR: Cannot start. STATUS is $status"
    exit 1
fi
```

**허용되는 STATUS**:
- ✅ `PENDING` - 파이프라인 시작 전
- ✅ `IN_PROGRESS` - 파이프라인 진행 중
- ❌ `COMPLETED` - 이미 완료됨
- ❌ `FAILED` - 실패 상태 (재시작 필요)

---

## 2.3 Precondition 3: 필수 입력 섹션 존재 확인

**목적**: 이전 에이전트가 자신의 입력 데이터를 제공했는지 확인

**에이전트별 필수 입력**:

| 에이전트 | 필수 입력 섹션 |
|----------|----------------|
| content-initiator | 없음 (최초 에이전트) |
| overview-writer | (파일 구조만 확인) |
| concepts-writer | `# Overview` |
| visualization-writer | `# Core Concepts` |
| practice-writer | `# Core Concepts` |
| quiz-writer | `# Core Concepts`, `# Practice` |
| content-validator | 모든 섹션 |

**확인 방법**:
```bash
# 파일에서 섹션 존재 확인
if ! grep -q "^# Overview$" "$file_path"; then
    echo "ERROR: Required input section '# Overview' not found"
    exit 1
fi
```

**concepts-writer 예시**:
```bash
# Overview 섹션이 있는지 확인
if ! grep -q "^# Overview$" "$file_path"; then
    echo "ERROR: overview-writer has not completed yet"
    exit 1
fi

# Overview 내용이 비어있지 않은지 확인
overview_content=$(sed -n '/^# Overview$/,/^# /p' "$file_path" | sed '1d;$d')
if [ -z "$overview_content" ]; then
    echo "ERROR: Overview section is empty"
    exit 1
fi
```

---

## 2.4 Precondition 체크리스트 요약

**모든 에이전트가 작업 시작 전 확인해야 할 사항**:

- [ ] **CURRENT_AGENT 확인**: 자신의 차례인가?
- [ ] **STATUS 확인**: `PENDING` 또는 `IN_PROGRESS`인가?
- [ ] **필수 입력 섹션 확인**: 이전 에이전트가 완료했는가?
- [ ] **마커 유효성 확인**: 마커가 손상되지 않았는가?

---

# 3. 에이전트 완료 시 체크리스트 (Postcondition)

에이전트가 작업을 완료한 후 반드시 수행해야 할 사항입니다.

## 3.1 Postcondition 1: HANDOFF LOG 엔트리 추가

**목적**: 자신의 작업 완료를 기록

**추가할 엔트리**:
```
[DONE] agent-name | message | YYYY-MM-DDTHH:MM:SS+09:00
```

**추가 방법**:
```bash
# HANDOFF LOG 엔트리 추가
append_handoff_log "$file_path" "DONE" "overview-writer" "Overview section completed"
```

**예시**:
```
[DONE] overview-writer | Overview section completed | 2025-10-17T10:30:00+09:00
[DONE] concepts-writer | Core concepts section completed | 2025-10-17T11:00:00+09:00
```

---

## 3.2 Postcondition 2: CURRENT_AGENT 업데이트

**목적**: 다음 에이전트로 핸드오프

**업데이트 방법**:
```bash
# 다음 에이전트로 업데이트
update_current_agent "$file_path" "concepts-writer"
```

**파이프라인 순서**:
1. `content-initiator` → 다음: `overview-writer`
2. `overview-writer` → 다음: `concepts-writer`
3. `concepts-writer` → 다음: `visualization-writer`
4. `visualization-writer` → 다음: `practice-writer`
5. `practice-writer` → 다음: `quiz-writer`
6. `quiz-writer` → 다음: `content-validator`
7. `content-validator` → 다음: `""` (빈 문자열, COMPLETE 시)

---

## 3.3 Postcondition 3: STATUS 업데이트

**목적**: 파이프라인 진행 상태 반영

**업데이트 시점**:
- **content-initiator 완료 후**: `PENDING` → `IN_PROGRESS`
- **content-validator [COMPLETE] 후**: `IN_PROGRESS` → `COMPLETED`
- **에이전트 실패 시**: `IN_PROGRESS` → `FAILED`

**일반 에이전트는 STATUS 업데이트하지 않음** (IN_PROGRESS 유지)

**업데이트 방법** (content-initiator만):
```bash
# STATUS 업데이트
update_status "$file_path" "IN_PROGRESS"
```

---

## 3.4 Postcondition 4: UPDATED 타임스탬프 갱신

**목적**: 마커 최종 업데이트 시각 기록

**갱신 시점**: HANDOFF LOG 엔트리 추가 시 자동 갱신 (append_handoff_log 함수가 자동 처리)

**수동 갱신 방법** (필요한 경우):
```bash
# 현재 시각으로 UPDATED 갱신
current_timestamp=$(date +"%Y-%m-%dT%H:%M:%S%:z")
update_timestamp "$file_path" "UPDATED" "$current_timestamp"
```

---

## 3.5 Postcondition 5: 출력 섹션 검증

**목적**: 자신이 생성한 섹션이 올바르게 작성되었는지 확인

**에이전트별 출력 섹션**:

| 에이전트 | 출력 섹션 |
|----------|----------|
| content-initiator | 파일 구조 (# Overview, # Core Concepts 등 헤더만) |
| overview-writer | `# Overview` 내용 |
| concepts-writer | `# Core Concepts` 내용 (Easy/Normal/Expert) |
| visualization-writer | `## Visualization` 컴포넌트 |
| practice-writer | `# Practice` 내용 (Patterns, Experiments) |
| quiz-writer | `# Quiz` 내용 |
| content-validator | VALIDATION_SCORE, IMPROVEMENT_NEEDED (필요 시) |

**검증 방법**:
```bash
# 출력 섹션 존재 확인
if ! grep -q "^# Overview$" "$file_path"; then
    echo "ERROR: Output section '# Overview' not created"
    exit 1
fi

# 출력 섹션 내용 확인 (비어있지 않은지)
section_content=$(sed -n '/^# Overview$/,/^# /p' "$file_path" | sed '1d;$d')
if [ -z "$section_content" ]; then
    echo "ERROR: Output section '# Overview' is empty"
    exit 1
fi
```

---

## 3.6 Postcondition 체크리스트 요약

**모든 에이전트가 작업 완료 후 수행해야 할 사항**:

- [ ] **HANDOFF LOG 엔트리 추가**: [DONE] 엔트리 기록
- [ ] **CURRENT_AGENT 업데이트**: 다음 에이전트로 핸드오프
- [ ] **STATUS 업데이트** (content-initiator, content-validator만): 파이프라인 상태 변경
- [ ] **UPDATED 타임스탬프 갱신**: 자동 갱신 확인
- [ ] **출력 섹션 검증**: 자신이 생성한 섹션 확인

---

# 4. HANDOFF LOG 엔트리 추가 예시

## 4.1 [START] - 파이프라인 시작

**발생 시점**: 파이프라인 최초 시작 (content-initiator 실행 전)

**에이전트**: `pipeline` (시스템)

**예시**:
```
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
```

**추가 방법**:
```bash
# 오케스트레이션 스크립트가 추가
append_handoff_log "$file_path" "START" "pipeline" "Content generation started"
```

---

## 4.2 [DONE] - 작업 완료

**발생 시점**: 에이전트가 자신의 작업을 성공적으로 완료했을 때

**에이전트**: 작업 완료한 에이전트 이름

**예시**:
```
[DONE] overview-writer | Overview section completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts section completed | 2025-10-17T10:45:00+09:00
```

**추가 방법**:
```bash
# overview-writer 에이전트가 추가
append_handoff_log "$file_path" "DONE" "overview-writer" "Overview section completed"

# concepts-writer 에이전트가 추가
append_handoff_log "$file_path" "DONE" "concepts-writer" "Core concepts section completed"
```

**메시지 가이드라인**:
- 간결하고 명확하게 (30자 이내 권장)
- 어떤 섹션을 완료했는지 명시
- 한글 허용

---

## 4.3 [IMPROVE] - 개선 완료

**발생 시점**: content-validator가 개선 요청 후 에이전트가 재작업을 완료했을 때

**에이전트**: 개선 작업을 완료한 에이전트 이름

**예시**:
```
[IMPROVE] concepts-writer | Improved difficulty balance in Easy level | 2025-10-17T11:30:00+09:00
[IMPROVE] visualization-writer | Added interactive elements | 2025-10-17T12:00:00+09:00
```

**추가 방법**:
```bash
# concepts-writer가 개선 후 추가
append_handoff_log "$file_path" "IMPROVE" "concepts-writer" "Improved difficulty balance in Easy level"
```

**메시지 가이드라인**:
- 어떤 부분을 개선했는지 명시
- IMPROVEMENT_NEEDED에 있던 항목 참조

---

## 4.4 [FAILURE] - 작업 실패

**발생 시점**: 에이전트가 작업 중 실패했을 때

**에이전트**: 실패한 에이전트 이름

**예시**:
```
[FAILURE] quiz-writer | API quota exceeded | 2025-10-17T12:00:00+09:00
[FAILURE] visualization-writer | Component rendering error | 2025-10-17T11:00:00+09:00
```

**추가 방법**:
```bash
# quiz-writer가 실패 시 추가
append_handoff_log "$file_path" "FAILURE" "quiz-writer" "API quota exceeded"

# STATUS도 FAILED로 변경
update_status "$file_path" "FAILED"
```

**메시지 가이드라인**:
- 실패 원인을 간결하게 명시
- 디버깅에 도움이 되는 정보 포함
- 예: "API quota exceeded", "Component rendering error"

---

## 4.5 [SKIP] - 건너뛰기

**발생 시점**: 에이전트가 작업을 건너뛸 때 (선택적 섹션 등)

**에이전트**: 건너뛴 에이전트 이름

**예시**:
```
[SKIP] visualization-writer | No visualization needed for this topic | 2025-10-17T11:00:00+09:00
```

**추가 방법**:
```bash
# visualization-writer가 건너뛸 때 추가
append_handoff_log "$file_path" "SKIP" "visualization-writer" "No visualization needed for this topic"

# CURRENT_AGENT는 다음 에이전트로 업데이트
update_current_agent "$file_path" "practice-writer"
```

**메시지 가이드라인**:
- 왜 건너뛰었는지 이유 명시
- 예: "No visualization needed", "Optional content not required"

---

## 4.6 [COMPLETE] - 파이프라인 완료

**발생 시점**: 파이프라인 전체 완료 (content-validator가 최종 승인)

**에이전트**: `content-validator`

**예시**:
```
[COMPLETE] content-validator | All content validated and approved | 2025-10-17T13:00:00+09:00
[COMPLETE] content-validator | Excellent quality - no improvements needed | 2025-10-17T13:00:00+09:00
```

**추가 방법**:
```bash
# content-validator가 추가
append_handoff_log "$file_path" "COMPLETE" "content-validator" "All content validated and approved"

# STATUS를 COMPLETED로 변경
update_status "$file_path" "COMPLETED"

# CURRENT_AGENT를 빈 문자열로 변경
update_current_agent "$file_path" ""
```

**메시지 가이드라인**:
- 최종 승인 메시지
- 품질 평가 결과 포함 가능
- 예: "All content validated and approved", "Excellent quality - no improvements needed"

---

# 5. 인터페이스 사용법

에이전트가 Work Status Markers를 조작하기 위해 사용하는 헬퍼 함수들입니다.

## 5.1 parse_work_status_markers

**용도**: 에이전트가 Precondition 확인 시 호출

**함수 시그니처**:
```bash
parse_work_status_markers(file_path)
```

**Parameters**:
| 매개변수 | 타입 | 설명 |
|----------|------|------|
| file_path | string | 마크다운 파일 절대 경로 |

**Returns**: 필드별 key-value 쌍 (JSON 형식)

**사용 예시**:
```bash
# 마커 파싱
marker_json=$(parse_work_status_markers "/path/to/content.md")

# 필드 추출
current_agent=$(echo "$marker_json" | jq -r '.CURRENT_AGENT')
status=$(echo "$marker_json" | jq -r '.STATUS')
started=$(echo "$marker_json" | jq -r '.STARTED')
updated=$(echo "$marker_json" | jq -r '.UPDATED')

# Precondition 확인
if [ "$current_agent" != "overview-writer" ]; then
    echo "ERROR: Not my turn. CURRENT_AGENT is $current_agent"
    exit 1
fi

if [ "$status" != "IN_PROGRESS" ] && [ "$status" != "PENDING" ]; then
    echo "ERROR: Cannot start. STATUS is $status"
    exit 1
fi
```

**Errors**:
- `FILE_NOT_FOUND`: 파일이 존재하지 않음
- `MARKER_NOT_FOUND`: HTML 주석이 없음
- `INVALID_MARKER`: 마커 형식 오류

---

## 5.2 append_handoff_log

**용도**: 에이전트가 작업 완료 시 호출 (HANDOFF LOG 엔트리 추가)

**함수 시그니처**:
```bash
append_handoff_log(file_path, event_type, agent_name, message)
```

**Parameters**:
| 매개변수 | 타입 | 설명 |
|----------|------|------|
| file_path | string | 마크다운 파일 절대 경로 |
| event_type | enum | START \| DONE \| IMPROVE \| FAILURE \| SKIP \| COMPLETE |
| agent_name | string | 에이전트 이름 |
| message | string | 이벤트 설명 메시지 |

**동작**:
1. HANDOFF LOG에 새 엔트리 추가
2. UPDATED 타임스탬프 자동 갱신
3. 원자성 보장 (임시 파일 사용)

**사용 예시**:
```bash
# overview-writer 작업 완료 시
append_handoff_log "/path/to/content.md" "DONE" "overview-writer" "Overview section completed"

# concepts-writer 개선 완료 시
append_handoff_log "/path/to/content.md" "IMPROVE" "concepts-writer" "Improved difficulty balance"

# quiz-writer 실패 시
append_handoff_log "/path/to/content.md" "FAILURE" "quiz-writer" "API quota exceeded"
```

**Returns**: success (boolean)

---

## 5.3 update_current_agent

**용도**: 에이전트가 핸드오프 시 호출 (다음 에이전트로 변경)

**함수 시그니처**:
```bash
update_current_agent(file_path, next_agent_name)
```

**Parameters**:
| 매개변수 | 타입 | 설명 |
|----------|------|------|
| file_path | string | 마크다운 파일 절대 경로 |
| next_agent_name | string | 다음 에이전트 이름 (빈 문자열 가능) |

**동작**:
1. CURRENT_AGENT 필드 업데이트
2. UPDATED 타임스탬프 자동 갱신

**사용 예시**:
```bash
# overview-writer 완료 후 concepts-writer로 핸드오프
update_current_agent "/path/to/content.md" "concepts-writer"

# content-validator 완료 후 빈 문자열로 설정 (COMPLETE)
update_current_agent "/path/to/content.md" ""
```

**Returns**: success (boolean)

---

## 5.4 set_validation_score

**용도**: content-validator가 점수 기록 시 호출

**함수 시그니처**:
```bash
set_validation_score(file_path, score)
```

**Parameters**:
| 매개변수 | 타입 | 설명 |
|----------|------|------|
| file_path | string | 마크다운 파일 절대 경로 |
| score | integer | 품질 평가 점수 (0-100) |

**동작**:
1. VALIDATION_SCORE 필드 추가 또는 업데이트
2. UPDATED 타임스탬프 자동 갱신

**사용 예시**:
```bash
# content-validator가 95점 부여
set_validation_score "/path/to/content.md" 95

# content-validator가 72점 부여 (개선 필요)
set_validation_score "/path/to/content.md" 72
```

**Returns**: success (boolean)

**점수 의미**:
- **90-100점**: 개선 불필요, 즉시 완료
- **70-89점**: 경미한 개선 필요 (선택적)
- **0-69점**: 중대한 개선 필요 (필수)

---

## 5.5 set_improvement_needed

**용도**: content-validator가 개선 항목 기록 시 호출

**함수 시그니처**:
```bash
set_improvement_needed(file_path, improvements_map)
```

**Parameters**:
| 매개변수 | 타입 | 설명 |
|----------|------|------|
| file_path | string | 마크다운 파일 절대 경로 |
| improvements_map | map | 에이전트별 개선 사항 (key: agent, value: description) |

**improvements_map 구조**:
```bash
declare -A improvements=(
    ["concepts-writer"]="난이도별 설명 길이 불균형 (Easy 너무 짧음)"
    ["visualization-writer"]="시각화 컴포넌트 인터랙션 부족"
)
```

**동작**:
1. IMPROVEMENT_NEEDED 필드 추가 또는 업데이트
2. YAML 리스트 형식으로 작성
3. UPDATED 타임스탬프 자동 갱신

**사용 예시**:
```bash
# content-validator가 개선 항목 기록
declare -A improvements=(
    ["concepts-writer"]="난이도별 설명 길이 불균형"
    ["quiz-writer"]="문제 난이도 불균형 (Expert 문제 너무 어려움)"
)

set_improvement_needed "/path/to/content.md" improvements
```

**Returns**: success (boolean)

---

# 6. 재시작 메커니즘

파이프라인이 중단되었을 때 어디서부터 재시작할지 결정하는 메커니즘입니다.

## 6.1 5단계 우선순위 알고리즘

**재시작 지점 식별 우선순위**:

1. **Priority 1**: IMPROVEMENT_NEEDED 확인
2. **Priority 2**: CURRENT_AGENT 확인
3. **Priority 3**: HANDOFF LOG 마지막 [FAILURE] 확인
4. **Priority 4**: [COMPLETE] 확인
5. **Priority 5**: 마지막 [DONE] 또는 [IMPROVE] 다음 에이전트

### 6.1.1 Priority 1: IMPROVEMENT_NEEDED 확인

**조건**: IMPROVEMENT_NEEDED 필드가 존재하고 비어있지 않음

**재시작 지점**: IMPROVEMENT_NEEDED에 나열된 첫 번째 에이전트

**예시**:
```markdown
<!--
IMPROVEMENT_NEEDED:
- concepts-writer: 난이도별 설명 길이 불균형
- visualization-writer: 시각화 컴포넌트 인터랙션 부족
-->
```

**재시작**: `concepts-writer`부터 시작

**이유**: content-validator가 명시적으로 개선이 필요한 에이전트를 지정했으므로 최우선

---

### 6.1.2 Priority 2: CURRENT_AGENT 확인

**조건**: CURRENT_AGENT 필드가 비어있지 않음

**재시작 지점**: CURRENT_AGENT에 명시된 에이전트

**예시**:
```markdown
<!--
CURRENT_AGENT: quiz-writer
STATUS: IN_PROGRESS
-->
```

**재시작**: `quiz-writer`부터 시작

**이유**: 파이프라인이 중단되기 전 다음 에이전트가 명확히 지정되어 있음

---

### 6.1.3 Priority 3: HANDOFF LOG 마지막 [FAILURE] 확인

**조건**: HANDOFF LOG에 [FAILURE] 엔트리가 있음

**재시작 지점**: 마지막 [FAILURE] 엔트리의 에이전트

**예시**:
```markdown
<!--
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] content-initiator | Initialized | 2025-10-17T10:05:00+09:00
[DONE] overview-writer | Completed | 2025-10-17T10:30:00+09:00
[FAILURE] concepts-writer | API error | 2025-10-17T11:00:00+09:00
-->
```

**재시작**: `concepts-writer`부터 재시도

**이유**: 실패한 에이전트를 다시 실행해야 함

---

### 6.1.4 Priority 4: [COMPLETE] 확인

**조건**: HANDOFF LOG에 [COMPLETE] 엔트리가 있음

**재시작 지점**: **재시작 불가** (파이프라인 완료)

**예시**:
```markdown
<!--
HANDOFF LOG:
...
[COMPLETE] content-validator | All content validated | 2025-10-17T13:00:00+09:00
-->
```

**재시작**: 불가 (이미 완료됨)

**예외**: `--force` 플래그 사용 시 강제 재시작 가능

---

### 6.1.5 Priority 5: 마지막 [DONE] 또는 [IMPROVE] 다음 에이전트

**조건**: HANDOFF LOG에 [DONE] 또는 [IMPROVE] 엔트리가 있음

**재시작 지점**: 마지막 [DONE] 또는 [IMPROVE] 다음 에이전트

**예시**:
```markdown
<!--
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] content-initiator | Initialized | 2025-10-17T10:05:00+09:00
[DONE] overview-writer | Completed | 2025-10-17T10:30:00+09:00
-->
```

**마지막 [DONE]**: `overview-writer`

**재시작**: `concepts-writer` (다음 에이전트)

**이유**: 마지막으로 완료된 에이전트 다음부터 계속 진행

---

## 6.2 재시작 시나리오

### 6.2.1 IMPROVEMENT_NEEDED 시나리오

**상황**: content-validator가 개선 요청

**Work Status Markers**:
```markdown
<!--
CURRENT_AGENT: content-validator
STATUS: IN_PROGRESS
HANDOFF LOG:
...
[DONE] content-validator | Initial validation completed | 2025-10-17T13:00:00+09:00
VALIDATION_SCORE: 75
IMPROVEMENT_NEEDED:
- concepts-writer: 난이도별 설명 길이 불균형
-->
```

**재시작 지점**: `concepts-writer`

**재시작 후 흐름**:
1. `concepts-writer` 재실행
2. 개선 완료 후 [IMPROVE] 엔트리 추가
3. IMPROVEMENT_NEEDED에서 concepts-writer 항목 제거
4. `content-validator` 다시 실행
5. 점수 90점 이상이면 [COMPLETE]

---

### 6.2.2 FAILURE 시나리오

**상황**: quiz-writer가 API 오류로 실패

**Work Status Markers**:
```markdown
<!--
CURRENT_AGENT: quiz-writer
STATUS: FAILED
HANDOFF LOG:
...
[FAILURE] quiz-writer | API quota exceeded | 2025-10-17T12:00:00+09:00
-->
```

**재시작 지점**: `quiz-writer`

**재시작 후 흐름**:
1. `quiz-writer` 재실행
2. 성공 시 [DONE] 엔트리 추가
3. STATUS를 IN_PROGRESS로 변경
4. `content-validator`로 핸드오프

---

# 7. 예외 상황 처리

## 7.1 마커 손상 시 복구 방법

**증상**:
- HTML 주석이 손상됨 (`<!--` 또는 `-->` 누락)
- 필수 필드 누락
- 타임스탬프 형식 오류

**복구 방법**:

### 7.1.1 자동 복구 (가능한 경우)

```bash
# 검증 스크립트 실행
./test/test-work-status-markers.sh /path/to/content.md

# 오류 확인
# ERROR: MISSING_REQUIRED_FIELD - Required field 'STATUS' is missing

# 수동으로 필드 추가
# (에디터로 파일 열어서 추가)
```

### 7.1.2 수동 복구 (마커 재생성)

```bash
# 기존 마커 백업
cp /path/to/content.md /path/to/content.md.bak

# 마커 제거
sed -i '' '/<!--/,/-->/d' /path/to/content.md

# content-initiator 재실행하여 마커 재생성
claude -p .claude/agents/content-initiator.md /path/to/content.md
```

---

## 7.2 검증 실패 시 조치 방법

**증상**:
- `test-work-status-markers.sh` 실행 시 오류
- Precondition 검증 실패
- Postcondition 검증 실패

**조치 방법**:

### 7.2.1 Precondition 실패

**증상**: 에이전트가 작업 시작 전 검증 실패

**원인**:
- CURRENT_AGENT가 자신이 아님
- STATUS가 COMPLETED 또는 FAILED
- 필수 입력 섹션 없음

**조치**:
```bash
# 1. 마커 확인
parse_work_status_markers /path/to/content.md

# 2. CURRENT_AGENT 확인
# CURRENT_AGENT: concepts-writer (현재)
# 자신: overview-writer

# 3. 재시작 메커니즘 확인
# 파이프라인을 재시작하여 올바른 지점부터 시작
```

---

### 7.2.2 Postcondition 실패

**증상**: 에이전트가 작업 완료 후 검증 실패

**원인**:
- HANDOFF LOG 엔트리 추가 실패
- CURRENT_AGENT 업데이트 실패
- 출력 섹션 없음

**조치**:
```bash
# 1. 마커 확인
parse_work_status_markers /path/to/content.md

# 2. HANDOFF LOG 확인
# 마지막 엔트리가 자신의 [DONE]인지 확인

# 3. 수동으로 엔트리 추가 (필요한 경우)
append_handoff_log /path/to/content.md "DONE" "overview-writer" "Overview section completed"

# 4. CURRENT_AGENT 업데이트
update_current_agent /path/to/content.md "concepts-writer"
```

---

## 7.3 동시성 문제 (Lock 파일)

**증상**:
- 여러 에이전트가 동시에 실행됨
- 마커 업데이트 충돌

**예방 방법**:

### 7.3.1 Lock 파일 생성 (오케스트레이션)

```bash
# Lock 파일 경로
lock_file="/tmp/content-gen-${file_hash}.lock"

# Lock 획득
if [ -f "$lock_file" ]; then
    # 기존 프로세스 확인
    lock_pid=$(cat "$lock_file")
    if ps -p "$lock_pid" > /dev/null 2>&1; then
        echo "ERROR: Another process ($lock_pid) is running"
        exit 1
    else
        # Stale lock 제거
        rm "$lock_file"
    fi
fi

# Lock 생성
echo $$ > "$lock_file"

# 작업 수행
...

# Lock 해제
rm "$lock_file"
```

---

## 변경 이력

| 버전 | 날짜 | 변경 사항 |
|------|------|----------|
| 1.0 | 2025-10-17 | 초안 작성 |

---

**작성자**: AI System Architect
**검토자**: Unit 1 Implementation Team
**승인자**: Project Lead
