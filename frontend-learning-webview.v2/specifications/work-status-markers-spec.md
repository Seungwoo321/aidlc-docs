# Work Status Markers Specification v1.0

## 문서 정보

**버전**: 1.0
**작성일**: 2025-10-17
**상태**: Final
**대상 독자**: 에이전트 개발자, 오케스트레이션 구현자

**목적**: Work Status Markers의 형식, 필드, 파싱 규칙을 명확히 정의하여 에이전트 간 데이터 전달의 표준을 제공합니다.

**참조 문서**:
- `logical_design.md` - 논리적 설계 (Section 1, 2, 3)
- `domain_design.md` - 도메인 모델 (Section 2, 5)
- `unit-01-pipe-mechanism.md` - Unit 1 정의 및 범위

---

## 목차

1. [개요](#1-개요)
2. [필수 필드](#2-필수-필드)
3. [선택 필드](#3-선택-필드)
4. [HANDOFF LOG 형식](#4-handoff-log-형식)
5. [타임스탬프 형식](#5-타임스탬프-형식)
6. [파싱 규칙](#6-파싱-규칙)
7. [전체 예시](#7-전체-예시)
8. [HTML 주석 형식 가이드라인](#8-html-주석-형식-가이드라인)

---

# 1. 개요

## 1.1 Work Status Markers란?

Work Status Markers는 콘텐츠 생성 파이프라인의 진행 상태를 추적하기 위한 메타데이터입니다. HTML 주석 형식으로 마크다운 파일 상단에 임베딩되며, 에이전트 간 핸드오프와 상태 추적을 관리합니다.

## 1.2 위치

마크다운 파일의 **최상단**에 HTML 주석 (`<!-- -->`) 형식으로 위치합니다.

## 1.3 형식

```markdown
<!--
CURRENT_AGENT: agent-name
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T10:30:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] content-initiator | Initialized content structure | 2025-10-17T10:05:00+09:00
[DONE] overview-writer | Overview section completed | 2025-10-17T10:30:00+09:00
-->

# 학습 콘텐츠 제목
...
```

## 1.4 인코딩

**필수**: UTF-8 인코딩
한글 메시지를 포함하므로 반드시 UTF-8 인코딩으로 저장해야 합니다.

---

# 2. 필수 필드

필수 필드는 모든 Work Status Markers에 반드시 존재해야 합니다.

## 2.1 CURRENT_AGENT

| 속성 | 값 |
|------|-----|
| **필드명** | CURRENT_AGENT |
| **데이터 타입** | string |
| **허용 값** | 빈 문자열 또는 에이전트 이름 |
| **패턴** | `[a-z-]+` (소문자, 하이픈만) |
| **의미** | 현재 작업 중인 에이전트 식별자 |

**상태별 값**:
- **PENDING**: 다음 에이전트 이름 (예: `content-initiator`)
- **IN_PROGRESS**: 작업 중인 에이전트 이름 (예: `concepts-writer`)
- **COMPLETED**: 빈 문자열 (`""`)
- **FAILED**: 실패한 에이전트 이름 유지

**예시**:
```
CURRENT_AGENT: overview-writer
CURRENT_AGENT:
```

**불변식**:
- 에이전트 이름은 파이프라인 정의를 따라야 함
- CURRENT_AGENT가 빈 문자열이면 STATUS는 COMPLETED여야 함

---

## 2.2 STATUS

| 속성 | 값 |
|------|-----|
| **필드명** | STATUS |
| **데이터 타입** | enum (열거형) |
| **허용 값** | `PENDING`, `IN_PROGRESS`, `COMPLETED`, `FAILED` |
| **기본값** | PENDING |
| **의미** | 파이프라인 전체 진행 상태 |

**STATUS 값 정의**:

| STATUS | 의미 | 조건 |
|--------|------|------|
| PENDING | 대기 중 | CURRENT_AGENT 설정됨, HANDOFF LOG에 START만 있음 |
| IN_PROGRESS | 진행 중 | CURRENT_AGENT 설정됨, 하나 이상의 에이전트 실행됨 |
| COMPLETED | 완료 | CURRENT_AGENT 비어있음, HANDOFF LOG에 COMPLETE 있음 |
| FAILED | 실패 | HANDOFF LOG에 FAILURE 있음 |

**예시**:
```
STATUS: PENDING
STATUS: IN_PROGRESS
STATUS: COMPLETED
STATUS: FAILED
```

**불변식**:
- STATUS는 항상 4개 값 중 하나여야 함
- 대소문자 정확히 일치해야 함 (PENDING, not pending)

---

## 2.3 STARTED

| 속성 | 값 |
|------|-----|
| **필드명** | STARTED |
| **데이터 타입** | ISO 8601 timestamp |
| **형식** | `YYYY-MM-DDTHH:MM:SS+09:00` |
| **제약사항** | STARTED ≤ UPDATED |
| **의미** | 파이프라인 최초 시작 시각 |

**형식 구성 요소**:
- `YYYY`: 4자리 연도
- `MM`: 2자리 월 (01-12)
- `DD`: 2자리 일 (01-31)
- `T`: 날짜와 시간 구분자 (리터럴)
- `HH`: 2자리 시 (00-23)
- `MM`: 2자리 분 (00-59)
- `SS`: 2자리 초 (00-59)
- `+09:00`: 타임존 (UTC+9, 한국 표준시)

**예시**:
```
STARTED: 2025-10-17T10:00:00+09:00
STARTED: 2025-01-01T00:00:00+09:00
```

**불변식**:
- ISO 8601 형식 엄격히 준수
- 타임존 필수 (예: +09:00)
- 유효한 날짜/시간이어야 함 (예: 02-31 불가)
- STARTED ≤ UPDATED

---

## 2.4 UPDATED

| 속성 | 값 |
|------|-----|
| **필드명** | UPDATED |
| **데이터 타입** | ISO 8601 timestamp |
| **형식** | `YYYY-MM-DDTHH:MM:SS+09:00` |
| **제약사항** | STARTED ≤ UPDATED |
| **의미** | 마커 최종 업데이트 시각 |

**갱신 시점**:
- 에이전트가 마커 업데이트할 때마다
- HANDOFF LOG 엔트리 추가 시
- CURRENT_AGENT 변경 시

**예시**:
```
UPDATED: 2025-10-17T10:30:00+09:00
```

**불변식**:
- STARTED ≤ UPDATED (시작 시각보다 이전일 수 없음)

---

## 2.5 HANDOFF LOG

| 속성 | 값 |
|------|-----|
| **필드명** | HANDOFF LOG |
| **데이터 타입** | array of log entries (여러 줄) |
| **형식** | `[EVENT_TYPE] agent-name \| message \| timestamp` |
| **제약사항** | Append-Only (수정/삭제 금지) |
| **의미** | 파이프라인 실행 이력 추적 |

**기본값**:
```
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
```

**HANDOFF LOG 엔트리 구조**:

```
[EVENT_TYPE] agent-name | message | YYYY-MM-DDTHH:MM:SS+09:00
└─────┬────┘ └───┬───┘   └──┬───┘   └───────────┬──────────────┘
   이벤트 타입  에이전트명   메시지        ISO 8601 타임스탬프
```

**구분자**: 파이프 문자 (`|`) 양옆에 공백 1개

**엔트리 구성 요소**:

| 구성 요소 | 설명 | 제약사항 |
|-----------|------|----------|
| **EVENT_TYPE** | 이벤트 종류 | START, DONE, IMPROVE, FAILURE, SKIP, COMPLETE 중 하나 |
| **agent-name** | 에이전트 이름 | `[a-z-]+` 패턴 (소문자, 하이픈만) |
| **message** | 이벤트 설명 | 한글/영문/숫자, 파이프 문자 포함 불가 |
| **timestamp** | 이벤트 발생 시각 | ISO 8601 형식 |

**불변식**:
- HANDOFF LOG는 Append-Only (기존 엔트리 수정/삭제 금지)
- 타임스탬프 순서대로 정렬되어야 함
- 파이프라인당 [START]는 1개만 (처음에만)
- 파이프라인당 [COMPLETE]는 1개만 (마지막에만)

---

# 3. 선택 필드

선택 필드는 특정 조건에서만 존재합니다.

## 3.1 VALIDATION_SCORE

| 속성 | 값 |
|------|-----|
| **필드명** | VALIDATION_SCORE |
| **데이터 타입** | integer |
| **허용 값** | 0-100 |
| **의미** | content-validator의 품질 평가 점수 |
| **설정 에이전트** | content-validator |

**점수 의미**:
- **90-100점**: 개선 불필요, 즉시 완료
- **70-89점**: 경미한 개선 필요 (선택적)
- **0-69점**: 중대한 개선 필요 (필수)

**예시**:
```
VALIDATION_SCORE: 95
VALIDATION_SCORE: 72
```

**불변식**:
- 0 이상 100 이하의 정수
- 소수점 불가

---

## 3.2 IMPROVEMENT_NEEDED

| 속성 | 값 |
|------|-----|
| **필드명** | IMPROVEMENT_NEEDED |
| **데이터 타입** | array of structured items (여러 줄) |
| **형식** | `- agent-name: improvement description [(-점수)점]` (점수는 선택) |
| **의미** | content-validator의 개선 지시 사항 |
| **설정 에이전트** | content-validator |

**엔트리 형식**:

**기본 형식** (점수 없음):
```
IMPROVEMENT_NEEDED:
- concepts-writer: 난이도별 설명 길이 불균형 (Easy 너무 짧음)
- visualization-writer: 시각화 컴포넌트 인터랙션 부족
```

**확장 형식** (점수 포함):
```
IMPROVEMENT_NEEDED:
- concepts-writer: Easy 설명이 너무 짧음, 비유 추가 필요 (-8점)
- practice-writer: Pattern 2의 코드 실행 오류 수정 필요 (-5점)
```

**제약사항**:
- YAML 리스트 형식 준수
- 에이전트명은 `[a-z-]+` 패턴
- 개선 설명은 한글/영문 자유 형식
- 점수 표기는 선택적: `(-N점)` 형식 (괄호, 마이너스, 숫자, "점")
- 점수는 메시지 끝에 위치

**점수 표기 규칙**:
- **형식**: `(-N점)` (N은 양의 정수)
- **위치**: 메시지의 끝에 위치 (선택적)
- **의미**: 해당 개선 항목으로 인한 감점 (content-validator가 계산)
- **파싱**: 점수는 정보 제공용, 파싱 시 무시 가능

**예시**:
```
IMPROVEMENT_NEEDED:
- overview-writer: 핵심 특징 섹션에 구체적 예시 추가 필요
- quiz-writer: 문제 난이도 불균형 (Expert 문제 너무 어려움) (-10점)
- concepts-writer: Expert 섹션 ECMAScript 명세 인용 부족 (-5점)
```

**정규식 패턴** (점수 추출용):
```regex
^-\s+([a-z-]+):\s+(.+?)(?:\s+\(-(\ d+)점\))?$
```

**캡처 그룹**:
1. `([a-z-]+)`: agent-name
2. `(.+?)`: improvement description (점수 제외)
3. `(\d+)`: 점수 (선택적, 점수 없으면 null)

---

# 4. HANDOFF LOG 형식

## 4.1 6개 EVENT_TYPE

| EVENT_TYPE | 발생 시점 | 상태 변화 | 예시 메시지 |
|------------|-----------|-----------|-------------|
| START | 파이프라인 시작 | STATUS: PENDING | Content generation started |
| DONE | 에이전트 작업 완료 | CURRENT_AGENT 다음으로 이동 | Overview section completed |
| IMPROVE | 개선 요청 후 재작업 | CURRENT_AGENT 이전 에이전트로 | Improved concepts section |
| FAILURE | 에이전트 작업 실패 | STATUS: FAILED | Failed to generate quiz |
| SKIP | 에이전트 건너뛰기 | CURRENT_AGENT 다음으로 | Skipped optional section |
| COMPLETE | 파이프라인 완료 | STATUS: COMPLETED, CURRENT_AGENT: "" | All content validated |

## 4.2 EVENT_TYPE 상세 설명

### 4.2.1 START

**발생 시점**: 파이프라인 최초 시작 (content-initiator 실행 전)

**에이전트**: `pipeline`

**상태 변화**:
- STATUS: PENDING
- CURRENT_AGENT: `content-initiator` (첫 번째 에이전트)

**예시**:
```
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
```

---

### 4.2.2 DONE

**발생 시점**: 에이전트가 자신의 작업을 성공적으로 완료했을 때

**에이전트**: 작업 완료한 에이전트 이름

**상태 변화**:
- CURRENT_AGENT: 다음 에이전트로 업데이트
- UPDATED: 현재 시각으로 갱신

**예시**:
```
[DONE] overview-writer | Overview section completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts section completed | 2025-10-17T10:45:00+09:00
```

---

### 4.2.3 IMPROVE

**발생 시점**: content-validator가 개선 요청 후 에이전트가 재작업을 완료했을 때

**에이전트**: 개선 작업을 완료한 에이전트 이름

**상태 변화**:
- IMPROVEMENT_NEEDED에서 해당 에이전트 항목 제거
- CURRENT_AGENT: 다음 에이전트 또는 content-validator로 업데이트

**예시**:
```
[IMPROVE] concepts-writer | Improved difficulty balance in Easy level | 2025-10-17T11:30:00+09:00
```

---

### 4.2.4 FAILURE

**발생 시점**: 에이전트가 작업 중 실패했을 때

**에이전트**: 실패한 에이전트 이름

**상태 변화**:
- STATUS: FAILED
- CURRENT_AGENT: 실패한 에이전트 이름 유지 (재시작 지점)

**예시**:
```
[FAILURE] quiz-writer | API quota exceeded | 2025-10-17T12:00:00+09:00
```

---

### 4.2.5 SKIP

**발생 시점**: 에이전트가 작업을 건너뛸 때 (선택적 섹션 등)

**에이전트**: 건너뛴 에이전트 이름

**상태 변화**:
- CURRENT_AGENT: 다음 에이전트로 업데이트

**예시**:
```
[SKIP] optional-section-writer | Optional content not required for this topic | 2025-10-17T11:00:00+09:00
```

---

### 4.2.6 COMPLETE

**발생 시점**: 파이프라인 전체 완료 (content-validator가 최종 승인)

**에이전트**: `content-validator`

**상태 변화**:
- STATUS: COMPLETED
- CURRENT_AGENT: 빈 문자열 (`""`)

**예시**:
```
[COMPLETE] content-validator | All content validated and approved | 2025-10-17T13:00:00+09:00
```

---

# 5. 타임스탬프 형식

## 5.1 ISO 8601 형식

**표준 형식**: `YYYY-MM-DDTHH:MM:SS+09:00`

**구성 요소**:

| 구성 요소 | 설명 | 형식 | 예시 |
|-----------|------|------|------|
| YYYY | 4자리 연도 | `\d{4}` | 2025 |
| MM | 2자리 월 (01-12) | `\d{2}` | 10 |
| DD | 2자리 일 (01-31) | `\d{2}` | 17 |
| T | 날짜/시간 구분자 | 리터럴 `T` | T |
| HH | 2자리 시 (00-23) | `\d{2}` | 14 |
| MM | 2자리 분 (00-59) | `\d{2}` | 30 |
| SS | 2자리 초 (00-59) | `\d{2}` | 00 |
| +09:00 | 타임존 오프셋 | `[+-]\d{2}:\d{2}` | +09:00 |

**유효한 예시**:
```
✅ 2025-10-17T14:30:00+09:00
✅ 2025-01-01T00:00:00+09:00
✅ 2025-12-31T23:59:59+09:00
```

**무효한 예시**:
```
❌ 2025-10-17 14:30:00       (T 구분자 없음)
❌ 2025-10-17T14:30:00       (타임존 없음)
❌ 2025-10-17T14:30:00Z      (Z 대신 +09:00 필요)
❌ 2025-13-01T00:00:00+09:00 (13월 없음)
❌ 2025-02-31T00:00:00+09:00 (2월 31일 없음)
```

## 5.2 Bash date 명령으로 생성

**현재 시각 타임스탬프 생성**:
```bash
current_timestamp=$(date +"%Y-%m-%dT%H:%M:%S%:z")
```

**출력 예시**:
```
2025-10-17T14:30:00+09:00
```

**한국 표준시 (KST) 명시적 설정**:
```bash
export TZ="Asia/Seoul"
current_timestamp=$(date +"%Y-%m-%dT%H:%M:%S%:z")
```

## 5.3 타임스탬프 검증

**정규식 패턴**:
```regex
^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$
```

**Bash 검증 예시**:
```bash
timestamp_pattern="^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$"

if [[ ! "$timestamp" =~ $timestamp_pattern ]]; then
    echo "ERROR: INVALID_TIMESTAMP - Timestamp must match ISO 8601 format"
    exit 1
fi
```

**의미적 검증** (date 명령 사용):
```bash
if ! date -d "$timestamp" > /dev/null 2>&1; then
    echo "ERROR: INVALID_TIMESTAMP - Invalid date/time values"
    exit 1
fi
```

---

# 6. 파싱 규칙

## 6.1 HTML 주석 추출

**정규식 패턴**:
```regex
<!--\s*([\s\S]*?)\s*-->
```

**패턴 설명**:
- `<!--`: HTML 주석 시작 (리터럴)
- `\s*`: 시작 후 선택적 공백
- `([\s\S]*?)`: 캡처 그룹 - 모든 문자 (개행 포함), 비탐욕적 매칭
- `\s*`: 종료 전 선택적 공백
- `-->`: HTML 주석 종료 (리터럴)

**Bash 구현 예시**:
```bash
# sed를 사용한 추출
marker_content=$(sed -n '/<!--/,/-->/p' "$file_path" | sed '1d;$d')
```

## 6.2 단일 줄 필드 파싱

**대상 필드**: CURRENT_AGENT, STATUS, STARTED, UPDATED, VALIDATION_SCORE

**정규식 패턴**:
```regex
^FIELD_NAME:\s*(.*)$
```

**Bash 구현 예시**:
```bash
# CURRENT_AGENT 추출
current_agent=$(echo "$marker_content" | grep "^CURRENT_AGENT:" | sed 's/^CURRENT_AGENT:\s*//' | sed 's/\s*$//')

# STATUS 추출
status=$(echo "$marker_content" | grep "^STATUS:" | sed 's/^STATUS:\s*//' | sed 's/\s*$//')
```

## 6.3 여러 줄 필드 파싱

**대상 필드**: HANDOFF LOG, IMPROVEMENT_NEEDED

**HANDOFF LOG 추출**:
```bash
# HANDOFF LOG 엔트리 추출
handoff_log=$(echo "$marker_content" | sed -n '/^HANDOFF LOG:/,/^[A-Z_]/p' | sed '1d;$d')

# 배열로 변환
IFS=$'\n' read -r -d '' -a log_entries <<< "$handoff_log"
```

## 6.4 HANDOFF LOG 엔트리 파싱

**전체 엔트리 파싱 패턴**:
```regex
^\[([A-Z]+)\]\s+([a-z-]+)\s+\|\s+(.*?)\s+\|\s+(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2})$
```

**캡처 그룹**:
1. `([A-Z]+)`: EVENT_TYPE
2. `([a-z-]+)`: agent-name
3. `(.*?)`: message
4. `(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2})`: timestamp

**Bash 구현 예시**:
```bash
# 엔트리 파싱
entry_pattern='^\[([A-Z]+)\]\s+([a-z-]+)\s+\|\s+(.*?)\s+\|\s+(.*?)$'

while IFS= read -r entry; do
    if [[ "$entry" =~ $entry_pattern ]]; then
        event_type="${BASH_REMATCH[1]}"
        agent_name="${BASH_REMATCH[2]}"
        message="${BASH_REMATCH[3]}"
        timestamp="${BASH_REMATCH[4]}"

        # 처리 로직...
    fi
done <<< "$handoff_log"
```

---

# 7. 전체 예시

## 7.1 정상 흐름 (START → DONE → COMPLETE)

```markdown
<!--
CURRENT_AGENT:
STATUS: COMPLETED
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:00:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] content-initiator | Initialized content structure | 2025-10-17T10:05:00+09:00
[DONE] overview-writer | Overview section completed | 2025-10-17T10:30:00+09:00
[DONE] concepts-writer | Core concepts section completed | 2025-10-17T11:00:00+09:00
[DONE] visualization-writer | Visualization components created | 2025-10-17T11:30:00+09:00
[DONE] practice-writer | Practice content completed | 2025-10-17T12:00:00+09:00
[DONE] quiz-writer | Quiz section completed | 2025-10-17T12:30:00+09:00
[COMPLETE] content-validator | All content validated and approved | 2025-10-17T13:00:00+09:00
VALIDATION_SCORE: 95
-->

# JavaScript 타입 시스템
...
```

---

## 7.2 실패 흐름 (FAILURE)

```markdown
<!--
CURRENT_AGENT: quiz-writer
STATUS: FAILED
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T12:00:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] content-initiator | Initialized content structure | 2025-10-17T10:05:00+09:00
[DONE] overview-writer | Overview section completed | 2025-10-17T10:30:00+09:00
[DONE] concepts-writer | Core concepts section completed | 2025-10-17T11:00:00+09:00
[DONE] visualization-writer | Visualization components created | 2025-10-17T11:30:00+09:00
[DONE] practice-writer | Practice content completed | 2025-10-17T12:00:00+09:00
[FAILURE] quiz-writer | API quota exceeded | 2025-10-17T12:00:00+09:00
-->

# JavaScript 타입 시스템
...
```

---

## 7.3 개선 흐름 (IMPROVE)

```markdown
<!--
CURRENT_AGENT:
STATUS: COMPLETED
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T14:30:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] content-initiator | Initialized content structure | 2025-10-17T10:05:00+09:00
[DONE] overview-writer | Overview section completed | 2025-10-17T10:30:00+09:00
[DONE] concepts-writer | Core concepts section completed | 2025-10-17T11:00:00+09:00
[DONE] visualization-writer | Visualization components created | 2025-10-17T11:30:00+09:00
[DONE] practice-writer | Practice content completed | 2025-10-17T12:00:00+09:00
[DONE] quiz-writer | Quiz section completed | 2025-10-17T12:30:00+09:00
[DONE] content-validator | Initial validation completed | 2025-10-17T13:00:00+09:00
[IMPROVE] concepts-writer | Improved difficulty balance in Easy level | 2025-10-17T14:00:00+09:00
[IMPROVE] visualization-writer | Added interactive elements to visualization | 2025-10-17T14:30:00+09:00
[COMPLETE] content-validator | All improvements applied and validated | 2025-10-17T14:30:00+09:00
VALIDATION_SCORE: 92
-->

# JavaScript 타입 시스템
...
```

---

## 7.4 건너뛰기 (SKIP)

```markdown
<!--
CURRENT_AGENT: content-validator
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T12:30:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] content-initiator | Initialized content structure | 2025-10-17T10:05:00+09:00
[DONE] overview-writer | Overview section completed | 2025-10-17T10:30:00+09:00
[DONE] concepts-writer | Core concepts section completed | 2025-10-17T11:00:00+09:00
[SKIP] visualization-writer | No visualization needed for this topic | 2025-10-17T11:00:00+09:00
[DONE] practice-writer | Practice content completed | 2025-10-17T11:30:00+09:00
[DONE] quiz-writer | Quiz section completed | 2025-10-17T12:00:00+09:00
-->

# JavaScript 변수 선언
...
```

---

## 7.5 완료 (COMPLETE with HIGH SCORE)

```markdown
<!--
CURRENT_AGENT:
STATUS: COMPLETED
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:00:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] content-initiator | Initialized content structure | 2025-10-17T10:05:00+09:00
[DONE] overview-writer | Overview section completed | 2025-10-17T10:30:00+09:00
[DONE] concepts-writer | Core concepts section completed | 2025-10-17T11:00:00+09:00
[DONE] visualization-writer | Visualization components created | 2025-10-17T11:30:00+09:00
[DONE] practice-writer | Practice content completed | 2025-10-17T12:00:00+09:00
[DONE] quiz-writer | Quiz section completed | 2025-10-17T12:30:00+09:00
[COMPLETE] content-validator | Excellent quality - no improvements needed | 2025-10-17T13:00:00+09:00
VALIDATION_SCORE: 98
-->

# JavaScript 클로저
...
```

---

# 8. HTML 주석 형식 가이드라인

## 8.1 UTF-8 인코딩 필수

**이유**: HANDOFF LOG 메시지와 IMPROVEMENT_NEEDED 설명에 한글이 포함되므로 UTF-8 인코딩 필수

**파일 저장 시**:
- 에디터 설정: UTF-8 (BOM 없음)
- Bash 스크립트: `LC_ALL=en_US.UTF-8` 설정

**검증**:
```bash
file -b --mime-encoding "$file_path"
# 출력: utf-8
```

## 8.2 HTML 주석 경계

**시작**: `<!--`
**종료**: `-->`

**규칙**:
- 파일 최상단에 위치 (프론트매터 있으면 그 다음)
- 주석 시작/종료 태그는 별도 줄에 위치하지 않아도 됨
- 중첩된 주석 불가

**올바른 예시**:
```markdown
<!--
CURRENT_AGENT: overview-writer
STATUS: IN_PROGRESS
...
-->

# 콘텐츠 제목
```

**잘못된 예시**:
```markdown
<!-- CURRENT_AGENT: overview-writer
STATUS: IN_PROGRESS
...
-->  ← 주석 종료 전 공백 허용되지만 권장하지 않음
```

## 8.3 여러 줄 필드 처리

**HANDOFF LOG**:
- 필드명 다음 줄부터 엔트리 시작
- 각 엔트리는 한 줄
- 빈 줄 허용 안 함

**IMPROVEMENT_NEEDED**:
- YAML 리스트 형식 준수
- 각 항목은 `- agent-name: description` 형식
- 들여쓰기 없음 (대시로 시작)

**올바른 예시**:
```
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] content-initiator | Initialized content structure | 2025-10-17T10:05:00+09:00

IMPROVEMENT_NEEDED:
- concepts-writer: 난이도별 설명 길이 불균형
- visualization-writer: 인터랙션 부족
```

**잘못된 예시**:
```
HANDOFF LOG:

[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00  ← 빈 줄 불가
  [DONE] content-initiator | ...  ← 들여쓰기 불가

IMPROVEMENT_NEEDED:
  - concepts-writer: ...  ← 들여쓰기 불가
```

## 8.4 필드 순서

**권장 순서** (가독성 향상):
1. CURRENT_AGENT
2. STATUS
3. STARTED
4. UPDATED
5. HANDOFF LOG
6. VALIDATION_SCORE (선택)
7. IMPROVEMENT_NEEDED (선택)

**필수 아님**: 파싱 로직은 순서에 의존하지 않지만, 일관성을 위해 권장

## 8.5 공백 처리

**필드명과 값 사이**: 콜론(`:`) 다음 공백 1개 이상

**올바른 예시**:
```
CURRENT_AGENT: overview-writer
STATUS: IN_PROGRESS
```

**허용되지만 권장하지 않음**:
```
CURRENT_AGENT:overview-writer  ← 공백 없음 (파싱은 가능하지만 비권장)
CURRENT_AGENT:    overview-writer  ← 공백 여러 개 (파싱은 가능하지만 비권장)
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
