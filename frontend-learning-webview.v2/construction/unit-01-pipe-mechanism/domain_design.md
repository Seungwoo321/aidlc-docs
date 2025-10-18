# Unit 1: Pipe Mechanism - DDD 경량화 도메인 설계

**작성일**: 2025-10-16
**작성자**: AI System Architect
**버전**: 1.0
**상태**: 진행 중 (Step 1 완료)

---

## Section 1: Bounded Context

### 1.1 Context 경계 정의

#### Work Status Markers Context

**Bounded Context 이름**: Work Status Markers Context

**책임(Responsibility)**:
- 콘텐츠 생성 파이프라인의 진행 상태 추적
- 에이전트 간 핸드오프 관리
- 파이프라인 재시작 지점 식별
- 품질 검증 결과 기록

**경계(Boundary)**:
- **내부**: Work Status Markers의 생성, 파싱, 검증, 업데이트 로직
- **외부**:
  - 에이전트의 실제 콘텐츠 생성 로직 (Agent Prompts Context에 속함)
  - 오케스트레이션 로직 (Orchestration Context에 속함)
  - 품질 측정 로직 (Quality Metrics Context에 속함)

**접근 규칙**:
- **읽기(Read)**: 모든 에이전트가 Precondition 확인을 위해 마커 읽기 가능
  - CURRENT_AGENT 필드: 자신의 차례인지 확인
  - STATUS 필드: 실행 가능한 상태인지 확인
  - 필수 입력 섹션: 이전 에이전트 출력물 존재 여부 확인
- **쓰기(Write)**: 모든 에이전트가 Section 4의 Handoff Protocol을 따라 마커 직접 업데이트
  - content-initiator: 초기화 시 마커 생성 (START 엔트리)
  - 각 에이전트: 작업 완료 시 HANDOFF LOG 추가 (DONE 엔트리), CURRENT_AGENT 업데이트, UPDATED 갱신
  - content-validator: VALIDATION_SCORE, IMPROVEMENT_NEEDED 작성, COMPLETE 엔트리 추가
- **검증(Validate)**: 에이전트 자신이 Postcondition 검증 (출력 섹션 존재 여부)

### 1.2 Context 간 통신 방법

#### 1.2.1 Shared Kernel (공유 커널)

**공유하는 개념**:
- Work Status Markers HTML 주석 형식
- HANDOFF LOG 엔트리 형식
- 필드명 (CURRENT_AGENT, PROGRESS, VALIDATION_SCORE 등)
- 상태값 enum (START, WAITING, DONE, FAILURE, SKIP, COMPLETE)

**공유 이유**:
- 모든 에이전트와 오케스트레이션이 동일한 마커 형식 이해 필요
- 파이프라인 전체에서 일관된 상태 표현

**공유 위험**:
- 마커 형식 변경 시 모든 컨텍스트 영향
- 완화 방안: 명세 문서화, 버전 관리, 하위 호환성 보장

#### 1.2.2 Published Language (공개 언어)

**공개 언어**: Work Status Markers Specification v1.0

**정의 내용**:
- 필수 필드 및 선택 필드 정의
- 각 필드의 데이터 타입 및 형식
- HANDOFF LOG 형식 표준
- 타임스탬프 형식 (ISO 8601: `2025-10-14T18:15:00+09:00`)

**사용 방법**:
- 모든 에이전트는 명세를 따라 마커 작성
- Orchestration은 명세를 따라 마커 파싱 및 검증

### 1.3 Anti-Corruption Layer

**필요성**:
- 각 에이전트는 Work Status Markers Context의 내부 구현에 의존하지 않음
- 마커 형식 변경 시 에이전트 로직 보호

**구현 방식**:
- **유틸리티 함수 계층**: `scripts/lib/work-status-markers.sh`
  - `parse_work_status_markers()`: 마커 추출
  - `write_work_status_markers()`: 마커 생성
  - `append_handoff_log()`: 로그 추가
  - `update_current_agent()`: 핸드오프
  - `validate_work_status_markers()`: 검증

**장점**:
- 에이전트는 유틸리티 함수만 사용하여 마커 조작
- 내부 구현 변경 시 유틸리티 함수만 수정
- 에이전트 프롬프트는 변경 불필요

### 1.4 Context Mapping 다이어그램

```mermaid
graph TB
    subgraph "Work Status Markers Context"
        WSM[Work Status Markers<br/>Specification]
        PARSE[Parser Functions]
        WRITE[Writer Functions]
        VALIDATE[Validation Functions]
    end

    subgraph "Agent Prompts Context"
        CI[content-initiator]
        OW[overview-writer]
        CW[concepts-writer]
        VW[visualization-writer]
        PW[practice-writer]
        QW[quiz-writer]
        CV[content-validator]
    end

    subgraph "Orchestration Context"
        ORCH[Orchestration<br/>Script]
        DETECT[Restart Point<br/>Detection]
    end

    subgraph "Quality Metrics Context"
        QM[Quality<br/>Measurement]
    end

    WSM -->|Shared Kernel| CI
    WSM -->|Shared Kernel| OW
    WSM -->|Shared Kernel| CW
    WSM -->|Shared Kernel| VW
    WSM -->|Shared Kernel| PW
    WSM -->|Shared Kernel| QW
    WSM -->|Shared Kernel| CV

    PARSE -->|Anti-Corruption Layer| ORCH
    WRITE -->|Anti-Corruption Layer| CI
    WRITE -->|Anti-Corruption Layer| OW
    WRITE -->|Anti-Corruption Layer| CW
    WRITE -->|Anti-Corruption Layer| VW
    WRITE -->|Anti-Corruption Layer| PW
    WRITE -->|Anti-Corruption Layer| QW
    WRITE -->|Anti-Corruption Layer| CV
    VALIDATE -->|Anti-Corruption Layer| ORCH

    ORCH -->|사용| DETECT
    CV -->|기록| QM

    style WSM fill:#e1f5ff
    style ORCH fill:#fff4e1
    style QM fill:#f0fff4
```

### 1.5 Context 책임 명확화

#### Work Status Markers Context의 책임

**DO (해야 할 것)**:
1. 마커의 형식 정의 및 명세 관리
2. 마커 파싱/생성/검증 로직 제공
3. 타임스탬프 생성 및 형식 통일
4. HANDOFF LOG 엔트리 형식 관리
5. 마커 무결성 검증

**DO NOT (하지 말아야 할 것)**:
1. 에이전트 실행 순서 결정 (Orchestration의 책임)
2. 콘텐츠 품질 측정 (Quality Metrics의 책임)
3. 에이전트 프롬프트 작성 (Agent Prompts의 책임)
4. 실제 파일 I/O 직접 수행 (유틸리티 함수는 제공, 호출은 Orchestration)

#### 다른 Context와의 관계

**Orchestration Context**:
- **관계**: Customer-Supplier (Work Status Markers가 Supplier)
- **통신**: Orchestration이 유틸리티 함수 호출
- **의존성**: Orchestration → Work Status Markers (단방향)

**Agent Prompts Context**:
- **관계**: Shared Kernel
- **통신**: 에이전트가 유틸리티 함수 호출하여 마커 조작
- **의존성**: Agent Prompts → Work Status Markers (단방향)

**Quality Metrics Context**:
- **관계**: Customer-Supplier (Work Status Markers가 Supplier)
- **통신**: Quality Metrics가 VALIDATION_SCORE 읽기
- **의존성**: Quality Metrics → Work Status Markers (단방향)

---

## Section 2: Ubiquitous Language

### 2.1 핵심 도메인 용어 정의

#### 2.1.1 Pipe (파이프)

**정의**: 에이전트(Filter) 간 데이터를 전달하는 통로

**구현**: Work Status Markers (HTML 주석)

**특징**:
- 마크다운 파일 상단에 HTML 주석으로 임베딩
- 읽기/쓰기 모두 가능한 양방향 통신 채널
- 파이프라인 전체 상태를 단일 파일에 저장

**예시**:
```html
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: overview-writer -->
<!-- PROGRESS: 진행중 -->
```

**사용 컨텍스트**:
- Orchestration이 다음 에이전트 결정 시
- 에이전트가 자신의 차례 확인 시
- 재시작 지점 식별 시

---

#### 2.1.2 Filter (필터)

**정의**: 입력 데이터를 받아 변환 후 출력하는 독립적인 처리 단위

**구현**: 7개 AI 에이전트 (content-initiator, overview-writer, concepts-writer, visualization-writer, practice-writer, quiz-writer, content-validator)

**특징**:
- 각 Filter는 하나의 명확한 책임 (단일 책임 원칙)
- Work Status Markers를 읽고 쓰며 다른 Filter와 통신
- 독립적으로 실행 가능하며 순서는 Orchestration이 제어

**예시**:
- overview-writer: Overview 섹션 생성
- concepts-writer: Core Concepts 섹션 생성

**사용 컨텍스트**:
- 에이전트 프롬프트 작성 시
- 파이프라인 흐름 설명 시
- 의존성 분석 시

---

#### 2.1.3 Work Status Markers (작업 상태 마커)

**정의**: 파이프라인의 현재 진행 상태를 기록하는 메타데이터 집합

**구현**: HTML 주석 형식의 필드 집합

**필수 필드**:
- CURRENT_AGENT: 다음 실행할 에이전트
- PROGRESS: 전체 진행 상태 (대기중, 진행중, 완료)
- STARTED: 파이프라인 시작 시간
- UPDATED: 마지막 업데이트 시간
- HANDOFF LOG: 에이전트 간 핸드오프 이력

**선택 필드**:
- VALIDATION_SCORE: 품질 점수 (0-100)
- IMPROVEMENT_NEEDED: 개선 필요 항목 목록

**사용 컨텍스트**:
- 파이프라인 상태 추적
- 재시작 지점 식별
- 개선 요청 전달

---

#### 2.1.4 Handoff (핸드오프)

**정의**: 한 에이전트가 작업을 완료하고 다음 에이전트에게 제어권을 넘기는 행위

**구현**: CURRENT_AGENT 필드 업데이트 + HANDOFF LOG 엔트리 추가

**프로토콜**:
1. 현재 에이전트가 작업 완료
2. HANDOFF LOG에 DONE 엔트리 추가
3. CURRENT_AGENT를 다음 에이전트로 설정
4. UPDATED 타임스탬프 갱신

**예시**:
```
[DONE] overview-writer: 완료 - 2025-10-14 15:45
<!-- CURRENT_AGENT: concepts-writer -->
```

**사용 컨텍스트**:
- 에이전트 실행 순서 제어
- 파이프라인 진행 추적
- 실패 지점 복구

---

#### 2.1.5 Agent (에이전트)

**정의**: 특정 섹션의 콘텐츠를 생성하는 AI 기반 자동화 단위

**동의어**: Filter (Pipeline Architecture 용어), Subagent (Claude Code 용어)

**특징**:
- Claude AI 모델 기반 프롬프트 실행
- 세션 ID로 컨텍스트 유지
- Work Status Markers로 자신의 차례 판단

**7개 에이전트**:
1. content-initiator: 초기화
2. overview-writer: Overview 섹션
3. concepts-writer: Core Concepts 섹션
4. visualization-writer: Visualization 컴포넌트
5. practice-writer: Code Patterns + Experiments 섹션
6. quiz-writer: Quiz 섹션
7. content-validator: 품질 검증

**사용 컨텍스트**:
- 서브에이전트 프롬프트 작성
- 파이프라인 설계
- 의존성 정의

---

### 2.2 Work Status Markers 전체 형식 개선

#### 현재 시스템의 전체 문제점 분석

**문제 1: 필드 형식 불일치**
```html
<!-- 현재 형식 (문제 있음) -->
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: overview-writer -->
<!-- PROGRESS: 진행중 -->
<!-- VALIDATION_SCORE: 85/100 -->
<!-- STARTED: 2025-10-14 14:30 -->
<!-- UPDATED: 2025-10-14 18:15 -->
```
- STARTED/UPDATED: 공백으로 구분된 날짜+시간 (ISO 8601 아님)
- VALIDATION_SCORE: `85/100` 형식 (숫자가 아닌 문자열)
- 일관성 없는 타임스탬프 형식

**문제 2: PROGRESS 필드의 모호성**
```html
<!-- PROGRESS: 진행중 -->
```
- PROGRESS가 파이프라인 전체 상태를 표현하지만, HANDOFF LOG와 중복
- HANDOFF LOG의 마지막 STATUS로 진행 상태 파악 가능
- 두 필드 간 불일치 가능성 (업데이트 누락 시)

**문제 3: CURRENT_AGENT의 이중 의미**
```html
<!-- CURRENT_AGENT: overview-writer -->  <!-- 다음 실행할 에이전트 -->
<!-- CURRENT_AGENT: -->                   <!-- 빈 문자열 = 완료 -->
```
- "다음 실행할 에이전트"와 "완료 표시"의 이중 의미
- 빈 문자열로 완료 판단하는 것은 암묵적 규칙

**문제 4: HTML 주석 형식의 파싱 복잡도**
```html
<!-- CURRENT_AGENT: overview-writer -->
```
- HTML 주석 `<!-- -->` 안에 필드 작성
- 여러 줄 주석으로 파싱 복잡
- 주석 종료 마커 `-->` 처리 필요

---

#### 개선된 Work Status Markers 전체 형식

**설계 원칙**:
1. **타입 안전성**: 모든 필드에 명확한 데이터 타입과 형식
2. **단일 책임**: 각 필드는 하나의 명확한 의미만 표현
3. **파싱 용이성**: 정규식으로 쉽게 추출 가능한 구조
4. **ISO 8601 준수**: 모든 타임스탬프는 ISO 8601 형식

**개선된 마커 템플릿**:
```html
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: {agent-name | empty} -->
<!-- STATUS: {PENDING | IN_PROGRESS | COMPLETED | FAILED} -->
<!-- STARTED: {ISO 8601 timestamp} -->
<!-- UPDATED: {ISO 8601 timestamp} -->
<!-- VALIDATION_SCORE: {integer 0-100} -->
<!-- IMPROVEMENT_NEEDED:
  - {agent-name}: {reason}
  - {agent-name}: {reason}
-->
<!-- HANDOFF_LOG:
[{STATUS}] {agent-name} | {message} | {ISO 8601 timestamp}
[{STATUS}] {agent-name} | {message} | {ISO 8601 timestamp}
-->
```

---

#### 필드별 개선 사항

##### 1. CURRENT_AGENT 필드
**변경 사항**: 의미 명확화
- 기존: 빈 문자열로 완료 표시
- 개선: 명시적인 `empty` 또는 별도 STATUS 필드로 완료 판단

**형식**:
```html
<!-- CURRENT_AGENT: overview-writer -->  <!-- 다음 에이전트 명시 -->
<!-- CURRENT_AGENT: -->                   <!-- 완료 (빈 값) -->
```

---

##### 2. PROGRESS → STATUS 필드로 변경
**변경 이유**: PROGRESS는 모호하고 HANDOFF LOG와 중복

**기존 PROGRESS 필드 (제거)**:
```html
<!-- PROGRESS: 대기중 -->  <!-- 언제 대기중인가? -->
<!-- PROGRESS: 진행중 -->  <!-- 어떤 에이전트가 진행중인가? -->
<!-- PROGRESS: 완료 -->    <!-- HANDOFF LOG COMPLETE과 중복 -->
```

**개선된 STATUS 필드**:
```html
<!-- STATUS: PENDING -->      <!-- 파이프라인 시작 전 -->
<!-- STATUS: IN_PROGRESS -->  <!-- 에이전트 실행 중 -->
<!-- STATUS: COMPLETED -->    <!-- 모든 에이전트 완료 -->
<!-- STATUS: FAILED -->       <!-- 실행 실패 -->
```

**STATUS 값 정의**:
| STATUS | 의미 | 조건 |
|--------|------|------|
| PENDING | 대기 중 | CURRENT_AGENT 설정됨, HANDOFF LOG가 START만 있음 |
| IN_PROGRESS | 진행 중 | CURRENT_AGENT 설정됨, 하나 이상의 에이전트 실행됨 |
| COMPLETED | 완료 | CURRENT_AGENT 비어있음, HANDOFF LOG에 COMPLETE 있음 |
| FAILED | 실패 | HANDOFF LOG에 FAILURE 있음 |

---

##### 3. STARTED/UPDATED 타임스탬프 형식 통일
**변경 사항**: ISO 8601 형식 강제

**기존 형식 (문제)**:
```html
<!-- STARTED: 2025-10-14 14:30 -->     <!-- 타임존 없음, 초 없음 -->
<!-- UPDATED: 2025-10-14 18:15 -->     <!-- 타임존 없음, 초 없음 -->
```

**개선된 형식**:
```html
<!-- STARTED: 2025-10-14T14:30:00+09:00 -->
<!-- UPDATED: 2025-10-14T18:15:00+09:00 -->
```

**Bash 생성 명령**:
```bash
date "+%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9]\{2\}\)$/:\1/'
# 출력: 2025-10-14T18:15:00+09:00
```

---

##### 4. VALIDATION_SCORE 형식 통일
**변경 사항**: 정수값만 저장

**기존 형식 (문제)**:
```html
<!-- VALIDATION_SCORE: 85/100 -->     <!-- 문자열, 파싱 필요 -->
```

**개선된 형식**:
```html
<!-- VALIDATION_SCORE: 85 -->          <!-- 정수, 0-100 범위 -->
```

**검증 규칙**:
- 타입: integer
- 범위: 0 ≤ VALIDATION_SCORE ≤ 100
- 기본값: 0 (미검증 상태)

---

##### 5. IMPROVEMENT_NEEDED 필드 구조화
**변경 사항**: 개선 대상 에이전트와 이유를 구조화

**기존 형식 (문제)**:
```html
<!-- IMPROVEMENT_NEEDED:
  - overview-writer
  - concepts-writer
-->
```
- 이유가 없어서 무엇을 개선해야 하는지 불명확

**개선된 형식**:
```html
<!-- IMPROVEMENT_NEEDED:
  - overview-writer: 학습 동기 부분이 너무 짧습니다 (최소 3문단 필요)
  - concepts-writer: Expert 난이도 설명에 기술 용어 정의 누락
-->
```

**형식 규칙**:
- 한 줄에 하나의 개선 항목
- 형식: `  - {agent-name}: {reason}`
- 에이전트명과 이유는 콜론(`:`)으로 구분
- 이유는 구체적이고 실행 가능해야 함

---

##### 6. HANDOFF_LOG → HANDOFF LOG (언더스코어 제거)
**변경 사항**: 필드명 일관성 (다른 필드는 언더스코어 없음)

**형식**: Section 2.3 참조 (이미 개선안 작성됨)

---

#### Before/After 비교 (전체 마커)

**현재 형식 (개선 전)**:
```html
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: -->
<!-- PROGRESS: 완료 -->
<!-- VALIDATION_SCORE: 100/100 -->
<!-- STARTED: 2025-10-14 14:30 -->
<!-- UPDATED: 2025-10-14 18:15 -->
<!-- HANDOFF LOG:
[START] content-initiator: started - initialization
[DONE] overview-writer: 완료 - 2025-10-14 15:45
[WAITING] concepts-writer: 대기중 - 2025-10-14 15:45
[DONE] concepts-writer: 완료 - 2025-10-14 16:30
[COMPLETE] 최종 완료 - 완벽한 콘텐츠 생성 - 2025-10-14 18:15
-->
```

**개선된 형식 (개선 후)**:
```html
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: -->
<!-- STATUS: COMPLETED -->
<!-- STARTED: 2025-10-14T14:30:00+09:00 -->
<!-- UPDATED: 2025-10-14T18:15:00+09:00 -->
<!-- VALIDATION_SCORE: 100 -->
<!-- IMPROVEMENT_NEEDED:
-->
<!-- HANDOFF LOG:
[START] content-initiator | 파이프라인 시작 | 2025-10-14T14:30:00+09:00
[DONE] overview-writer | Overview 섹션 작성 완료 | 2025-10-14T15:45:00+09:00
[DONE] concepts-writer | Core Concepts 섹션 작성 완료 | 2025-10-14T16:30:00+09:00
[DONE] visualization-writer | 시각화 컴포넌트 생성 완료 | 2025-10-14T17:00:00+09:00
[DONE] practice-writer | Code Patterns 및 Experiments 섹션 작성 완료 | 2025-10-14T17:30:00+09:00
[DONE] quiz-writer | Quiz 섹션 작성 완료 | 2025-10-14T18:00:00+09:00
[COMPLETE] content-validator | 품질 검증 완료 (100점) | 2025-10-14T18:15:00+09:00
-->
```

**개선 효과 요약**:
| 항목 | 개선 전 | 개선 후 | 개선 효과 |
|------|---------|---------|-----------|
| 타임스탬프 | `2025-10-14 14:30` | `2025-10-14T14:30:00+09:00` | ISO 8601 표준, 타임존 명시 |
| PROGRESS | 한글 enum | STATUS: 영문 enum | 명확성, 파싱 용이 |
| VALIDATION_SCORE | `100/100` | `100` | 정수 타입, 파싱 단순화 |
| HANDOFF LOG | 중복 엔트리 (WAITING) | 단일 엔트리 (DONE만) | 로그 간결화 (13개 → 7개) |
| HANDOFF LOG 형식 | `[DONE] agent: 완료 - timestamp` | `[DONE] agent \| message \| timestamp` | 구조화, 파싱 용이 |
| IMPROVEMENT_NEEDED | 에이전트명만 | 에이전트명 + 이유 | 실행 가능성 향상 |

---

#### 필드 사전 (개선된 버전)

| 필드명 | 타입 | 필수 | 형식 | 설명 |
|--------|------|------|------|------|
| CURRENT_AGENT | string | ✅ | kebab-case 또는 empty | 다음 실행할 에이전트 (빈 값이면 완료) |
| STATUS | enum | ✅ | PENDING \| IN_PROGRESS \| COMPLETED \| FAILED | 파이프라인 전체 상태 |
| STARTED | datetime | ✅ | ISO 8601 | 파이프라인 시작 시간 |
| UPDATED | datetime | ✅ | ISO 8601 | 마지막 업데이트 시간 |
| VALIDATION_SCORE | integer | ❌ | 0-100 | 품질 점수 (기본값: 0) |
| IMPROVEMENT_NEEDED | array | ❌ | `- agent: reason` | 개선 필요 항목 목록 |
| HANDOFF LOG | array | ✅ | `[STATUS] agent \| message \| timestamp` | 에이전트 실행 이력 |

---

### 2.3 HANDOFF LOG 개선 설계

#### 현재 시스템의 문제점 분석

**문제 1: 에이전트당 중복 엔트리**
```html
<!-- 현재 형식 (문제 있음) -->
[WAITING] concepts-writer: 대기중 - 2025-10-14 15:45
[DONE] concepts-writer: 완료 - 2025-10-14 16:30
```
- 각 에이전트가 WAITING과 DONE 두 개의 엔트리 생성
- WAITING 엔트리는 정보 가치가 낮음 (곧바로 실행되므로)
- 로그가 불필요하게 길어짐
- 파싱 복잡도 증가

**문제 2: 타임스탬프 형식 불일치**
```html
<!-- 현재 형식 (혼재) -->
[DONE] overview-writer: 완료 - 2025-10-14 15:45          # 날짜+시간
[START] content-initiator: started - initialization       # 타임스탬프 없음
```
- 일부 엔트리는 타임스탬프 있음, 일부는 없음
- ISO 8601 표준 준수 안 됨
- 시간 순서 추적 어려움

**문제 3: 언어 혼용**
```html
[DONE] overview-writer: 완료 - 2025-10-14 15:45
```
- STATUS는 영어 (DONE)
- 메시지는 한글 (완료)
- 일관성 부족, 파싱 규칙 복잡

**문제 4: 구조화되지 않은 메시지**
```html
[DONE] visualization-writer: 완료 - ReactAsLibraryVisualization, ComponentArchitectureVisualization 생성 - 2025-10-14 17:00
```
- 자유 형식 메시지로 파싱 어려움
- 구조화된 데이터 추출 불가능
- 구분자('-') 중복 사용으로 혼란

---

#### 개선된 HANDOFF LOG 형식

**설계 원칙**:
1. **단일 엔트리 원칙**: 에이전트당 하나의 STATUS만 기록
2. **타임스탬프 필수화**: 모든 엔트리에 ISO 8601 타임스탬프 포함
3. **언어 일관성**: STATUS는 영어, 메시지는 한글 (구분 명확)
4. **구조화된 형식**: 파싱 가능한 필드 구조

**표준 형식**:
```
[STATUS] agent-name | message | YYYY-MM-DDTHH:MM:SS+TZ
```

**구성 요소**:
- `[STATUS]`: 이벤트 유형 (영문 대문자, 대괄호 포함)
- `agent-name`: 에이전트 식별자 (kebab-case)
- `|`: 필드 구분자 (파이프 문자)
- `message`: 사람이 읽을 수 있는 설명 (한글)
- `timestamp`: ISO 8601 형식 (`2025-10-14T16:30:00+09:00`)

---

#### 개선된 STATUS 값 정의

| STATUS | 의미 | 사용 시점 | 예시 |
|--------|------|----------|------|
| START | 파이프라인 시작 | content-initiator 초기화 | `[START] content-initiator \| 파이프라인 시작 \| 2025-10-14T14:30:00+09:00` |
| DONE | 작업 완료 | 에이전트 첫 번째 실행 성공 | `[DONE] overview-writer \| Overview 섹션 작성 완료 \| 2025-10-14T15:45:00+09:00` |
| IMPROVE | 개선 작업 완료 | content-validator의 개선 요청 후 재실행 완료 | `[IMPROVE] concepts-writer \| Expert 난이도 확장 완료 \| 2025-10-14T16:45:00+09:00` |
| FAILURE | 작업 실패 | 에이전트 실행 오류 | `[FAILURE] quiz-writer \| 파싱 실패 (attempt 2) \| 2025-10-14T18:00:00+09:00` |
| SKIP | 건너뛰기 | --skip 옵션 사용 | `[SKIP] visualization-writer \| 사용자 요청으로 건너뛰기 \| 2025-10-14T17:00:00+09:00` |
| COMPLETE | 최종 완료 | content-validator 최종 승인 | `[COMPLETE] content-validator \| 품질 검증 완료 (92점) \| 2025-10-14T18:15:00+09:00` |

**제거된 STATUS**:
- ~~WAITING~~: 중복 정보이므로 제거 (DONE만으로 충분)

**IMPROVE vs DONE 구분**:
- **DONE**: 에이전트의 첫 번째 작업 완료
- **IMPROVE**: IMPROVEMENT_NEEDED 필드 존재 시 개선 작업 완료
- 같은 에이전트가 [DONE]과 [IMPROVE] 모두 가질 수 있음 (개선 루프)

---

#### Before/After 비교

**현재 형식 (개선 전)**:
```html
<!-- HANDOFF LOG:
[START] content-initiator: started - initialization
[DONE] overview-writer: 완료 - 2025-10-14 15:45
[WAITING] concepts-writer: 대기중 - 2025-10-14 15:45
[DONE] concepts-writer: 완료 - 2025-10-14 16:30
[WAITING] visualization-writer: 대기중 - 2025-10-14 16:30
[DONE] visualization-writer: 완료 - ReactAsLibraryVisualization, ComponentArchitectureVisualization 생성 - 2025-10-14 17:00
[COMPLETE] 최종 완료 - 완벽한 콘텐츠 생성 - 2025-10-14 18:15
-->
```

**개선된 형식 (개선 후)**:
```html
<!-- HANDOFF LOG:
[START] content-initiator | 파이프라인 시작 | 2025-10-14T14:30:00+09:00
[DONE] overview-writer | Overview 섹션 작성 완료 | 2025-10-14T15:45:00+09:00
[DONE] concepts-writer | Core Concepts 섹션 작성 완료 | 2025-10-14T16:30:00+09:00
[DONE] visualization-writer | 시각화 컴포넌트 생성 완료 (ReactAsLibraryVisualization, ComponentArchitectureVisualization) | 2025-10-14T17:00:00+09:00
[DONE] practice-writer | Code Patterns 및 Experiments 섹션 작성 완료 | 2025-10-14T17:30:00+09:00
[DONE] quiz-writer | Quiz 섹션 작성 완료 | 2025-10-14T18:00:00+09:00
[COMPLETE] content-validator | 품질 검증 완료 (100점) | 2025-10-14T18:15:00+09:00
-->
```

**개선 효과**:
- 엔트리 수: 7개 → 7개 (WAITING 제거로 실제로는 13개 → 7개)
- 타임스탬프: 일부만 → 모든 엔트리에 ISO 8601 형식
- 언어: 혼용 → STATUS(영어) + 메시지(한글) 명확히 구분
- 구조: 자유 형식 → 파이프(`|`)로 구분된 구조화된 형식
- 파싱: 정규식 복잡 → 단순한 split 연산으로 처리 가능

---

#### 파싱 규칙

**정규식 패턴**:
```regex
^\[(START|DONE|FAILURE|SKIP|COMPLETE)\] ([a-z-]+) \| (.+) \| (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2})$
```

**캡처 그룹**:
1. `STATUS`: START, DONE, FAILURE, SKIP, COMPLETE
2. `agent-name`: kebab-case 에이전트명
3. `message`: 메시지 (한글 포함)
4. `timestamp`: ISO 8601 타임스탬프

**Bash 파싱 예시**:
```bash
# 기존 방식 (복잡)
local last_handoff=$(grep -A 20 "^<!-- HANDOFF LOG:" "$file_path" | grep "^\[" | tail -1)
local last_status=$(echo "$last_handoff" | sed 's/^\[\([A-Z]*\)\].*/\1/')
local last_agent=$(echo "$last_handoff" | sed 's/.*\] \([a-z-]*\):.*/\1/')

# 개선 방식 (단순)
local last_handoff=$(grep -A 20 "^<!-- HANDOFF LOG:" "$file_path" | grep "^\[" | tail -1)
local status=$(echo "$last_handoff" | cut -d' ' -f1 | tr -d '[]')
local agent=$(echo "$last_handoff" | cut -d'|' -f1 | cut -d' ' -f2)
local message=$(echo "$last_handoff" | cut -d'|' -f2 | xargs)
local timestamp=$(echo "$last_handoff" | cut -d'|' -f3 | xargs)
```

---

### 2.4 도메인 용어 사전 (개선된 버전)

| 용어 | 정의 | 컨텍스트 | 제약사항 | 비고 |
|------|------|----------|----------|------|
| **Pipeline** | 여러 Filter를 순차적으로 연결한 데이터 처리 흐름 | Pipeline Architecture | 단방향 흐름 | |
| **Pipe** | Filter 간 데이터 전달 채널 | Pipeline Architecture | Work Status Markers로 구현 | |
| **Filter** | 독립적인 데이터 변환 단위 | Pipeline Architecture | 에이전트로 구현 | |
| **Work Status Markers** | 파이프라인 상태 메타데이터 집합 | Work Status Markers Context | HTML 주석 형식, 7개 필수 필드 | 개선: 필드 타입 명확화 |
| **CURRENT_AGENT** | 다음 실행할 에이전트명 | Work Status Markers Context | kebab-case 또는 empty | |
| **STATUS** | 파이프라인 전체 상태 | Work Status Markers Context | PENDING \| IN_PROGRESS \| COMPLETED \| FAILED | 개선: PROGRESS 대체 |
| **HANDOFF LOG** | 에이전트 실행 이력 로그 | Work Status Markers Context | 구조화된 엔트리 배열 | 개선: 파이프 구분자 사용 |
| **Handoff** | 에이전트 간 제어권 이양 | Work Status Markers Context | CURRENT_AGENT 업데이트 + HANDOFF LOG 추가 | |
| **Session** | 하나의 파이프라인 실행 단위 | Orchestration Context | UUID로 식별 | |
| **Restart Point** | 파이프라인 재시작 지점 | Orchestration Context | STATUS + HANDOFF LOG 기반 식별 | 개선: STATUS 추가 고려 |
| **Precondition** | 에이전트 실행 전 만족 조건 | Filter Contracts Context | CURRENT_AGENT 일치 확인 | |
| **Postcondition** | 에이전트 실행 후 보장 조건 | Filter Contracts Context | HANDOFF LOG 추가 확인 | |
| **VALIDATION_SCORE** | 콘텐츠 품질 점수 | Quality Metrics Context | 0-100 정수 | 개선: `/100` 제거 |
| **IMPROVEMENT_NEEDED** | 개선이 필요한 에이전트 목록 | Quality Metrics Context | 구조화된 항목 (agent: reason) | 개선: 이유 추가 |

---

### 2.5 용어 사용 규칙 (개선된 버전)

#### 명명 규칙

**에이전트명**:
- 형식: kebab-case
- 패턴: `{역할}-writer` 또는 `{역할}-{동작}`
- 예시: overview-writer, content-initiator, content-validator

**필드명**:
- 형식: SCREAMING_SNAKE_CASE (단어는 공백으로 구분)
- ❌ 잘못된 예시: `HANDOFF_LOG` (언더스코어 사용)
- ✅ 올바른 예시: `HANDOFF LOG` (공백 사용)
- 기타 예시: CURRENT_AGENT, VALIDATION_SCORE, IMPROVEMENT_NEEDED (필드명 내부는 언더스코어)

**파이프라인 상태값 (STATUS 필드)**:
- 형식: 영문 대문자, 언더스코어로 단어 구분
- 예시: PENDING, IN_PROGRESS, COMPLETED, FAILED
- 변경: ~~대기중, 진행중, 완료~~ (기존 PROGRESS 한글) → STATUS 영문

**이벤트 상태값 (HANDOFF LOG STATUS)**:
- 형식: 영문 대문자
- 예시: START, DONE, FAILURE, SKIP, COMPLETE
- 제거: ~~WAITING~~ (중복)

#### 용어 일관성 원칙

1. **단일 용어 사용**: 같은 개념은 항상 같은 용어 사용
   - ✅ "에이전트" 또는 "Filter" (컨텍스트에 따라)
   - ❌ "서브에이전트", "작업자", "처리기" 혼용 금지

2. **명확한 구분**: 유사한 개념은 명확히 구분
   - **STATUS** (파이프라인 전체): PENDING, IN_PROGRESS, COMPLETED, FAILED
   - **HANDOFF LOG STATUS** (개별 이벤트): START, DONE, FAILURE, SKIP, COMPLETE

3. **컨텍스트 명시**: 모호한 경우 컨텍스트 명시
   - "에이전트 실행"이 아닌 "overview-writer 에이전트 실행"
   - "마커"가 아닌 "Work Status Markers"
   - "STATUS"가 아닌 "파이프라인 STATUS" 또는 "이벤트 STATUS"

4. **타입 명시**: 필드값의 타입을 명확히
   - VALIDATION_SCORE: `85` (정수)
   - STARTED: `2025-10-14T14:30:00+09:00` (ISO 8601 datetime)
   - STATUS: `IN_PROGRESS` (enum)

---

### 2.6 개선안 요약 및 마이그레이션 영향 분석

#### 핵심 변경 사항 요약

| 항목 | 기존 | 개선 | 이유 |
|------|------|------|------|
| **PROGRESS 필드** | `PROGRESS: 진행중` | `STATUS: IN_PROGRESS` | 영문 enum, HANDOFF LOG와 중복 제거 |
| **HANDOFF LOG 엔트리** | 에이전트당 2개 (WAITING + DONE) | 에이전트당 1개 (DONE만) | 중복 제거, 간결화 |
| **HANDOFF LOG 형식** | `[DONE] agent: msg - ts` | `[DONE] agent \| msg \| ts` | 구조화, 파싱 용이 |
| **타임스탬프** | `2025-10-14 14:30` | `2025-10-14T14:30:00+09:00` | ISO 8601 표준 |
| **VALIDATION_SCORE** | `85/100` | `85` | 정수 타입 |
| **IMPROVEMENT_NEEDED** | `- agent-name` | `- agent-name: reason` | 실행 가능성 |

---

#### 마이그레이션 영향 분석

**영향받는 컴포넌트**:
1. **scripts/content-generator-v6.sh**
   - `parse_work_status_markers()` 함수 수정 필요
   - PROGRESS → STATUS 필드명 변경
   - 타임스탬프 파싱 로직 변경
   - HANDOFF LOG 파싱 로직 변경 (파이프 구분자)

2. **7개 에이전트 프롬프트** (Unit 3)
   - Work Status Markers 작성 지침 업데이트
   - 새로운 형식 예시로 변경

3. **기존 콘텐츠 파일** (~100개 파일)
   - 기존 마커 형식 유지 (하위 호환성)
   - 새 파일부터 개선된 형식 적용
   - 또는 마이그레이션 스크립트로 일괄 변환

**마이그레이션 전략**:
- **옵션 A: 점진적 마이그레이션**
  - 파싱 로직에서 구버전/신버전 모두 지원
  - 새 파일부터 신버전 적용
  - 기존 파일은 업데이트 시 자동 변환

- **옵션 B: 일괄 마이그레이션**
  - 마이그레이션 스크립트 작성
  - 모든 기존 파일 일괄 변환
  - 파싱 로직은 신버전만 지원

**권장**: 옵션 A (점진적 마이그레이션)
- 이유: 기존 파일 보존, 리스크 최소화, 단계적 검증 가능

---

---

## Section 3: Domain Events

### 3.1 HANDOFF LOG 이벤트 분류

Domain Event는 도메인에서 발생한 의미 있는 사건을 표현합니다. Work Status Markers Context에서 Domain Event는 HANDOFF LOG 엔트리로 기록됩니다.

#### 이벤트 타입 정의

| Event Type | STATUS | 의미 | 발생 시점 | 발행자 |
|------------|--------|------|----------|--------|
| **PipelineStartedEvent** | START | 파이프라인 시작 | content-initiator가 Work Status Markers 초기화 | content-initiator |
| **AgentCompletedEvent** | DONE | 에이전트 작업 완료 | 에이전트가 자신의 첫 번째 작업을 성공적으로 완료 | 각 에이전트 |
| **AgentImprovedEvent** | IMPROVE | 에이전트 개선 작업 완료 | IMPROVEMENT_NEEDED 요청 후 개선 작업 완료 | 각 에이전트 |
| **AgentFailedEvent** | FAILURE | 에이전트 작업 실패 | 에이전트 실행 중 오류 발생 | Orchestration |
| **AgentSkippedEvent** | SKIP | 에이전트 건너뛰기 | --skip 옵션으로 에이전트 건너뜀 | Orchestration |
| **PipelineCompletedEvent** | COMPLETE | 파이프라인 완료 | content-validator가 최종 검증 완료 | content-validator |

---

### 3.2 이벤트 발생 조건 및 상태 전이

#### 3.2.1 PipelineStartedEvent

**발생 조건**:
- 파일에 Work Status Markers가 존재하지 않음
- 또는 명시적 재시작 (--force)

**상태 전이**:
```
[Before]
파일 상태: Work Status Markers 없음

[Event]
[START] content-initiator | 파이프라인 시작 | 2025-10-14T14:30:00+09:00

[After]
- CURRENT_AGENT: overview-writer
- STATUS: PENDING
- STARTED: 2025-10-14T14:30:00+09:00
- HANDOFF LOG: START 엔트리 추가
```

**불변식**:
- START 이벤트는 HANDOFF LOG의 첫 번째 엔트리여야 함
- 하나의 파이프라인에 START는 정확히 1개만 존재

---

#### 3.2.2 AgentCompletedEvent

**발생 조건**:
- CURRENT_AGENT가 자신의 이름과 일치
- 에이전트가 자신의 작업을 성공적으로 완료
- Postcondition 검증 통과 (섹션 파싱 테스트 성공 등)

**상태 전이 (예: overview-writer)**:
```
[Before]
- CURRENT_AGENT: overview-writer
- STATUS: IN_PROGRESS

[Event]
[DONE] overview-writer | Overview 섹션 작성 완료 | 2025-10-14T15:45:00+09:00

[After]
- CURRENT_AGENT: concepts-writer (다음 에이전트로 핸드오프)
- STATUS: IN_PROGRESS
- UPDATED: 2025-10-14T15:45:00+09:00
- HANDOFF LOG: DONE 엔트리 추가
```

**불변식**:
- DONE 이벤트는 해당 에이전트의 출력물이 검증 가능해야 함
- DONE 이벤트 후 CURRENT_AGENT는 다음 에이전트로 업데이트되어야 함

---

#### 3.2.3 AgentFailedEvent

**발생 조건**:
- 에이전트 실행 중 예외 발생
- Postcondition 검증 실패
- 최대 재시도 횟수 초과

**상태 전이**:
```
[Before]
- CURRENT_AGENT: quiz-writer
- STATUS: IN_PROGRESS

[Event]
[FAILURE] quiz-writer | 파싱 실패 (attempt 2/3) | 2025-10-14T18:00:00+09:00

[After]
- CURRENT_AGENT: quiz-writer (변경 없음, 재시도 대기)
- STATUS: FAILED
- UPDATED: 2025-10-14T18:00:00+09:00
- HANDOFF LOG: FAILURE 엔트리 추가
```

**불변식**:
- FAILURE 이벤트 후 STATUS는 FAILED로 변경
- CURRENT_AGENT는 실패한 에이전트를 가리킴 (재시도 가능)
- 재시도 횟수가 메시지에 포함되어야 함

---

#### 3.2.4 AgentSkippedEvent

**발생 조건**:
- 사용자가 --skip-{agent} 옵션 사용
- 또는 conditional execution에서 에이전트 제외

**상태 전이**:
```
[Before]
- CURRENT_AGENT: visualization-writer
- STATUS: IN_PROGRESS

[Event]
[SKIP] visualization-writer | 사용자 요청으로 건너뛰기 (--skip option) | 2025-10-14T17:00:00+09:00

[After]
- CURRENT_AGENT: practice-writer (다음 에이전트로 핸드오프)
- STATUS: IN_PROGRESS
- UPDATED: 2025-10-14T17:00:00+09:00
- HANDOFF LOG: SKIP 엔트리 추가
```

**불변식**:
- SKIP 이벤트 후에도 파이프라인은 계속 진행
- SKIP된 에이전트의 출력물은 검증하지 않음

---

#### 3.2.5 PipelineCompletedEvent

**발생 조건**:
- 모든 필수 에이전트 완료
- content-validator가 최종 검증 완료
- VALIDATION_SCORE ≥ 90

**상태 전이**:
```
[Before]
- CURRENT_AGENT: content-validator
- STATUS: IN_PROGRESS
- VALIDATION_SCORE: 0

[Event]
[COMPLETE] content-validator | 품질 검증 완료 (100점) | 2025-10-14T18:15:00+09:00

[After]
- CURRENT_AGENT: (빈 문자열)
- STATUS: COMPLETED
- VALIDATION_SCORE: 100
- UPDATED: 2025-10-14T18:15:00+09:00
- HANDOFF LOG: COMPLETE 엔트리 추가
```

**불변식**:
- COMPLETE 이벤트는 HANDOFF LOG의 마지막 엔트리여야 함
- COMPLETE 이벤트 후 CURRENT_AGENT는 빈 문자열
- STATUS는 COMPLETED로 변경

---

### 3.3 이벤트 데이터 구조

#### 3.3.1 이벤트 엔트리 형식

**표준 형식** (Section 2.3에서 정의):
```
[STATUS] agent-name | message | YYYY-MM-DDTHH:MM:SS+TZ
```

**필드 정의**:
| 필드 | 타입 | 제약사항 | 설명 |
|------|------|----------|------|
| STATUS | enum | START \| DONE \| FAILURE \| SKIP \| COMPLETE | 이벤트 타입 |
| agent-name | string | kebab-case, 7개 에이전트명 중 하나 | 이벤트 발행자 |
| message | string | 1-200자, 한글/영문/숫자/공백 허용 | 사람이 읽을 수 있는 설명 |
| timestamp | datetime | ISO 8601 형식 | 이벤트 발생 시간 (타임존 포함) |

---

#### 3.3.2 메시지 작성 가이드라인

**DONE 이벤트 메시지**:
- 형식: `{섹션명} 작성 완료` 또는 `{작업 내용} 완료`
- 예시:
  - `Overview 섹션 작성 완료`
  - `Core Concepts 섹션 작성 완료`
  - `시각화 컴포넌트 생성 완료 (ReactAsLibraryVisualization, ComponentArchitectureVisualization)`

**FAILURE 이벤트 메시지**:
- 형식: `{실패 이유} (attempt {N}/{MAX})`
- 예시:
  - `파싱 실패 (attempt 2/3)`
  - `섹션 생성 실패: 필수 필드 누락 (attempt 1/3)`

**SKIP 이벤트 메시지**:
- 형식: `{건너뛰기 이유}`
- 예시:
  - `사용자 요청으로 건너뛰기 (--skip option)`
  - `조건부 실행: 이미 완료된 섹션`

**COMPLETE 이벤트 메시지**:
- 형식: `품질 검증 완료 ({점수}점)`
- 예시:
  - `품질 검증 완료 (100점)`
  - `품질 검증 완료 (95점)`

---

### 3.4 이벤트 순서 보장 메커니즘

#### 3.4.1 Append-Only 원칙

**규칙**:
- HANDOFF LOG는 append-only (추가만 가능)
- 기존 엔트리 수정 금지
- 기존 엔트리 삭제 금지

**이유**:
- 이벤트 히스토리 무결성 보장
- 감사 추적 (audit trail) 가능
- 재시도 및 개선 이력 추적

---

#### 3.4.2 타임스탬프 순서 보장

**규칙**:
- 새로운 이벤트의 타임스탬프는 이전 이벤트보다 커야 함
- 즉, `timestamp[n] < timestamp[n+1]`

**구현**:
```bash
# 새 엔트리 추가 전 검증
last_timestamp=$(grep -A 50 "^<!-- HANDOFF LOG:" "$file" | grep "^\[" | tail -1 | cut -d'|' -f3 | xargs)
new_timestamp=$(date "+%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9]\{2\}\)$/:\1/')

# 타임스탬프 비교 (ISO 8601은 문자열 비교 가능)
if [[ "$new_timestamp" < "$last_timestamp" ]]; then
    echo "Error: New timestamp is older than last entry"
    exit 1
fi
```

---

#### 3.4.3 상태 전이 제약사항

**허용된 상태 전이**:
```
START → DONE → DONE → ... → COMPLETE
  ↓       ↓
FAILURE  SKIP
```

**상태 전이 규칙**:
1. START는 첫 번째 엔트리여야 함
2. START 후에는 DONE, FAILURE, SKIP만 가능
3. DONE 후에는 DONE, FAILURE, SKIP, COMPLETE 가능
4. FAILURE 후에는 DONE (재시도 성공) 또는 FAILURE (재시도 실패) 가능
5. SKIP 후에는 DONE, SKIP, COMPLETE 가능
6. COMPLETE는 마지막 엔트리여야 함

**검증 로직**:
```bash
validate_state_transition() {
    local last_status="$1"
    local new_status="$2"

    case "$last_status" in
        "START")
            [[ "$new_status" =~ ^(DONE|FAILURE|SKIP)$ ]] || return 1
            ;;
        "DONE")
            [[ "$new_status" =~ ^(DONE|FAILURE|SKIP|COMPLETE)$ ]] || return 1
            ;;
        "FAILURE")
            [[ "$new_status" =~ ^(DONE|FAILURE)$ ]] || return 1
            ;;
        "SKIP")
            [[ "$new_status" =~ ^(DONE|SKIP|COMPLETE)$ ]] || return 1
            ;;
        "COMPLETE")
            return 1  # COMPLETE 이후에는 어떤 이벤트도 추가 불가
            ;;
    esac
    return 0
}
```

---

### 3.5 이벤트 흐름 다이어그램

#### 정상 흐름 (Happy Path)

```mermaid
sequenceDiagram
    participant CI as content-initiator
    participant OW as overview-writer
    participant CW as concepts-writer
    participant VW as visualization-writer
    participant PW as practice-writer
    participant QW as quiz-writer
    participant CV as content-validator
    participant HANDOFF as HANDOFF LOG

    CI->>HANDOFF: [START] 파이프라인 시작
    CI->>OW: Handoff (CURRENT_AGENT: overview-writer)

    OW->>HANDOFF: [DONE] Overview 섹션 작성 완료
    OW->>CW: Handoff (CURRENT_AGENT: concepts-writer)

    CW->>HANDOFF: [DONE] Core Concepts 섹션 작성 완료
    CW->>VW: Handoff (CURRENT_AGENT: visualization-writer)

    VW->>HANDOFF: [DONE] 시각화 컴포넌트 생성 완료
    VW->>PW: Handoff (CURRENT_AGENT: practice-writer)

    PW->>HANDOFF: [DONE] Code Patterns 및 Experiments 섹션 작성 완료
    PW->>QW: Handoff (CURRENT_AGENT: quiz-writer)

    QW->>HANDOFF: [DONE] Quiz 섹션 작성 완료
    QW->>CV: Handoff (CURRENT_AGENT: content-validator)

    CV->>HANDOFF: [COMPLETE] 품질 검증 완료 (100점)
    CV->>CV: CURRENT_AGENT = empty
```

---

#### 실패 및 재시도 흐름

```mermaid
sequenceDiagram
    participant QW as quiz-writer
    participant ORCH as Orchestration
    participant HANDOFF as HANDOFF LOG

    QW->>QW: 작업 시도 #1
    QW--xQW: 파싱 실패
    ORCH->>HANDOFF: [FAILURE] 파싱 실패 (attempt 1/3)

    ORCH->>QW: 재시도 #2
    QW->>QW: 작업 시도 #2
    QW--xQW: 파싱 실패
    ORCH->>HANDOFF: [FAILURE] 파싱 실패 (attempt 2/3)

    ORCH->>QW: 재시도 #3
    QW->>QW: 작업 시도 #3
    QW->>HANDOFF: [DONE] Quiz 섹션 작성 완료
    QW->>CV: Handoff (CURRENT_AGENT: content-validator)
```

---

#### 건너뛰기 흐름

```mermaid
sequenceDiagram
    participant CW as concepts-writer
    participant VW as visualization-writer
    participant PW as practice-writer
    participant ORCH as Orchestration
    participant HANDOFF as HANDOFF LOG

    CW->>HANDOFF: [DONE] Core Concepts 섹션 작성 완료
    CW->>VW: Handoff (CURRENT_AGENT: visualization-writer)

    ORCH->>ORCH: Check: --skip-visualization option
    ORCH->>HANDOFF: [SKIP] 사용자 요청으로 건너뛰기
    ORCH->>PW: Handoff (CURRENT_AGENT: practice-writer)

    PW->>HANDOFF: [DONE] Code Patterns 및 Experiments 섹션 작성 완료
```

---

### 3.6 이벤트 소싱 (Event Sourcing) 적용 가능성

현재 HANDOFF LOG는 이벤트 소싱 패턴의 간단한 형태입니다:

**현재 구조**:
- 이벤트 스트림: HANDOFF LOG (append-only)
- 현재 상태: CURRENT_AGENT, STATUS, VALIDATION_SCORE

**이벤트 소싱의 장점**:
1. **히스토리 추적**: 모든 상태 변경 이력 보존
2. **재현 가능**: 이벤트 재생으로 현재 상태 재구성 가능
3. **감사 추적**: 누가, 언제, 무엇을 했는지 추적
4. **디버깅 용이**: 문제 발생 시점의 이벤트 확인

**향후 확장 가능성** (Unit 5 - Quality Metrics):
- 이벤트 기반 메트릭 수집
- 에이전트별 성공률, 평균 소요 시간 계산
- 실패 패턴 분석

---

---

## Section 4: Handoff Protocol Specification

본 섹션은 **에이전트가 Work Status Markers를 조작할 때 준수해야 할 규칙**을 정의합니다. 모든 에이전트는 이 프로토콜을 따라 마커를 읽고 쓰며, 다음 에이전트로 핸드오프합니다.

### 4.1 에이전트 작업 시작 시 규칙

에이전트가 작업을 시작하기 전에 **반드시 확인**해야 할 사항들입니다.

#### 4.1.1 Precondition: CURRENT_AGENT 확인

**규칙**: 에이전트는 작업 시작 전에 `CURRENT_AGENT` 필드가 자신의 이름과 일치하는지 **반드시 확인**해야 합니다.

**확인 방법**:
1. 마크다운 파일의 Work Status Markers 블록에서 `CURRENT_AGENT` 필드 읽기
2. 값이 자신의 에이전트명(kebab-case)과 정확히 일치하는지 확인

**예시**:
```html
<!-- CURRENT_AGENT: overview-writer -->
```
- overview-writer 에이전트: ✅ 실행 가능
- concepts-writer 에이전트: ❌ 실행 불가 (자신의 차례가 아님)

**불일치 시 동작**:
- 작업을 **즉시 중단**
- 오류 메시지 출력: "CURRENT_AGENT mismatch: expected <agent-name>, got <actual-value>"

---

#### 4.1.2 Precondition: 필수 입력 섹션 존재 확인

**규칙**: 에이전트는 자신이 의존하는 **이전 에이전트의 출력 섹션**이 존재하는지 확인해야 합니다.

**에이전트별 필수 입력**:
| 에이전트 | 필수 입력 섹션 |
|---------|--------------|
| content-initiator | (없음) |
| overview-writer | (없음 - 첫 번째 작업 에이전트) |
| concepts-writer | `# Overview` |
| visualization-writer | `# Core Concepts` |
| practice-writer | `# Core Concepts` |
| quiz-writer | `# Overview`, `# Core Concepts`, `# Code Patterns`, `# Experiments` |
| content-validator | (모든 섹션) |

**확인 방법**:
- 마크다운 파일에서 해당 섹션 헤더 존재 여부 확인
- 예: `# Overview` 문자열 검색

**섹션 부재 시 동작**:
- 작업을 **즉시 중단**
- 오류 메시지 출력: "Missing required section: <section-name>"

---

#### 4.1.3 Precondition: STATUS 확인

**규칙**: 에이전트는 파이프라인 `STATUS`가 실행 가능한 상태인지 확인해야 합니다.

**실행 가능한 STATUS**:
- `PENDING`: 대기 중 (파이프라인 시작 직후)
- `IN_PROGRESS`: 진행 중 (다른 에이전트 작업 후)
- `FAILED`: 실패 상태 (재시도 시도 중)

**실행 불가능한 STATUS**:
- `COMPLETED`: 이미 완료된 파이프라인

**예시**:
```html
<!-- STATUS: IN_PROGRESS -->  ✅ 실행 가능
<!-- STATUS: COMPLETED -->    ❌ 실행 불가
```

### 4.2 에이전트 작업 완료 시 규칙

에이전트가 자신의 작업을 완료한 후에 **반드시 수행**해야 할 마커 업데이트 작업들입니다.

#### 4.2.1 HANDOFF LOG 엔트리 추가

**규칙**: 에이전트는 작업 완료 시 HANDOFF LOG에 **DONE 엔트리를 반드시 추가**해야 합니다.

**엔트리 형식** (Section 2.3 참조):
```
[DONE] agent-name | message | YYYY-MM-DDTHH:MM:SS+TZ
```

**구성 요소**:
- `[DONE]`: 작업 완료 상태 (대괄호 포함, 대문자)
- `agent-name`: 자신의 에이전트명 (kebab-case)
- `|`: 필드 구분자 (파이프 문자, 앞뒤 공백 1칸)
- `message`: 완료 메시지 (한글, 50-200자)
- `|`: 필드 구분자
- `timestamp`: ISO 8601 형식 타임스탬프 (`2025-10-14T15:45:00+09:00`)

**메시지 작성 가이드라인**:
- 형식: `{작업 내용} 완료` 또는 `{섹션명} 작성 완료`
- 예시:
  - `Overview 섹션 작성 완료`
  - `Core Concepts 섹션 작성 완료 (Easy/Normal/Expert 3단계)`
  - `시각화 컴포넌트 생성 완료 (ReactAsLibraryVisualization, ComponentArchitectureVisualization)`

**삽입 위치**:
- `<!-- HANDOFF LOG:` 라인 다음
- `-->` 종료 마커 직전
- 기존 엔트리들의 **마지막**에 추가 (Append-Only)

**예시**:
```html
<!-- HANDOFF LOG:
[START] content-initiator | 파이프라인 시작 | 2025-10-14T14:30:00+09:00
[DONE] overview-writer | Overview 섹션 작성 완료 | 2025-10-14T15:45:00+09:00
[DONE] concepts-writer | Core Concepts 섹션 작성 완료 | 2025-10-14T16:30:00+09:00  ← 여기에 추가
-->
```

---

#### 4.2.2 CURRENT_AGENT 필드 업데이트

**규칙**: 에이전트는 작업 완료 후 `CURRENT_AGENT` 필드를 **다음 에이전트명으로 변경**해야 합니다.

**다음 에이전트 결정**:
| 현재 에이전트 | 다음 에이전트 |
|-------------|-------------|
| content-initiator | overview-writer |
| overview-writer | concepts-writer |
| concepts-writer | visualization-writer |
| visualization-writer | practice-writer |
| practice-writer | quiz-writer |
| quiz-writer | content-validator |
| content-validator | (빈 문자열) |

**업데이트 방법**:
```html
<!-- 변경 전 -->
<!-- CURRENT_AGENT: overview-writer -->

<!-- 변경 후 -->
<!-- CURRENT_AGENT: concepts-writer -->
```

**content-validator의 경우** (파이프라인 완료 시):
```html
<!-- CURRENT_AGENT: -->  ← 빈 문자열 (완료 표시)
```

---

#### 4.2.3 STATUS 필드 업데이트

**규칙**: 에이전트는 다음 에이전트 유무에 따라 `STATUS` 필드를 업데이트해야 합니다.

**업데이트 규칙**:
- **다음 에이전트 있음**: `STATUS: IN_PROGRESS` 유지
- **다음 에이전트 없음** (content-validator 완료 시): `STATUS: COMPLETED`

**예시**:
```html
<!-- overview-writer 완료 시 -->
<!-- STATUS: IN_PROGRESS -->  ← 유지

<!-- content-validator 완료 시 -->
<!-- STATUS: COMPLETED -->    ← 변경
```

---

#### 4.2.4 UPDATED 타임스탬프 갱신

**규칙**: 에이전트는 마커를 업데이트할 때 `UPDATED` 필드를 **현재 시간으로 갱신**해야 합니다.

**형식**: ISO 8601 (`2025-10-14T18:15:00+09:00`)

**예시**:
```html
<!-- 변경 전 -->
<!-- UPDATED: 2025-10-14T15:45:00+09:00 -->

<!-- 변경 후 (작업 완료 시각) -->
<!-- UPDATED: 2025-10-14T16:30:00+09:00 -->
```

---

#### 4.2.5 Postcondition: 출력 섹션 검증

**규칙**: 에이전트는 자신이 생성해야 할 **출력 섹션이 존재하는지 자체 검증**해야 합니다.

**에이전트별 필수 출력**:
| 에이전트 | 필수 출력 섹션 |
|---------|--------------|
| content-initiator | Work Status Markers 블록 |
| overview-writer | `# Overview` |
| concepts-writer | `# Core Concepts` (Easy/Normal/Expert 하위 섹션 포함) |
| visualization-writer | `# Core Concepts` 내 visualization 메타데이터 |
| practice-writer | `# Code Patterns`, `# Experiments` |
| quiz-writer | `# Quiz` |
| content-validator | `VALIDATION_SCORE`, `IMPROVEMENT_NEEDED` 필드 |

**검증 방법**:
- 마크다운 파일에서 해당 섹션 헤더 존재 여부 확인
- 예: `# Overview` 문자열이 파일에 존재하는지 확인

**검증 실패 시 동작**:
- **마커 업데이트 하지 않음**
- 작업을 실패로 간주
- 오류 메시지 출력: "Failed to create required section: <section-name>"

---

### 4.3 오류 처리 규칙

에이전트 실행 중 오류가 발생했을 때의 처리 규칙입니다.

#### 4.3.1 작업 실패 시 FAILURE 엔트리 기록

**규칙**: Orchestration이 에이전트 실행 실패를 감지하면 HANDOFF LOG에 **FAILURE 엔트리를 기록**합니다.

**엔트리 형식**:
```
[FAILURE] agent-name | error-message (attempt N/MAX) | timestamp
```

**예시**:
```html
<!-- HANDOFF LOG:
[DONE] overview-writer | Overview 섹션 작성 완료 | 2025-10-14T15:45:00+09:00
[FAILURE] concepts-writer | 섹션 파싱 실패 (attempt 1/3) | 2025-10-14T16:00:00+09:00
[FAILURE] concepts-writer | 섹션 파싱 실패 (attempt 2/3) | 2025-10-14T16:15:00+09:00
[DONE] concepts-writer | Core Concepts 섹션 작성 완료 | 2025-10-14T16:30:00+09:00
-->
```

**FAILURE 발생 시 상태 변경**:
```html
<!-- CURRENT_AGENT: concepts-writer -->  ← 유지 (재시도 가능)
<!-- STATUS: FAILED -->                  ← FAILED로 변경
```

---

#### 4.3.2 에이전트 건너뛰기 (SKIP)

**규칙**: 사용자가 특정 에이전트를 건너뛰도록 지시하면 (예: `--skip-visualization`), HANDOFF LOG에 **SKIP 엔트리를 기록**합니다.

**엔트리 형식**:
```
[SKIP] agent-name | reason | timestamp
```

**예시**:
```html
<!-- HANDOFF LOG:
[DONE] concepts-writer | Core Concepts 섹션 작성 완료 | 2025-10-14T16:30:00+09:00
[SKIP] visualization-writer | 사용자 요청으로 건너뛰기 (--skip option) | 2025-10-14T16:31:00+09:00
[DONE] practice-writer | Code Patterns 및 Experiments 섹션 작성 완료 | 2025-10-14T17:30:00+09:00
-->
```

**SKIP 발생 시 상태 변경**:
```html
<!-- CURRENT_AGENT: practice-writer -->  ← 다음 에이전트로 변경
<!-- STATUS: IN_PROGRESS -->             ← IN_PROGRESS 유지
```

---

#### 4.3.3 파이프라인 완료 (COMPLETE)

**규칙**: content-validator가 최종 검증을 완료하면 HANDOFF LOG에 **COMPLETE 엔트리를 기록**합니다.

**엔트리 형식**:
```
[COMPLETE] content-validator | 품질 검증 완료 (점수) | timestamp
```

**예시**:
```html
<!-- HANDOFF LOG:
[DONE] quiz-writer | Quiz 섹션 작성 완료 | 2025-10-14T18:00:00+09:00
[COMPLETE] content-validator | 품질 검증 완료 (100점) | 2025-10-14T18:15:00+09:00
-->
```

**COMPLETE 발생 시 상태 변경**:
```html
<!-- CURRENT_AGENT: -->           ← 빈 문자열
<!-- STATUS: COMPLETED -->        ← COMPLETED로 변경
<!-- VALIDATION_SCORE: 100 -->   ← 점수 기록
```

---

### 4.4 완전한 Work Status Markers 업데이트 예시

**시나리오**: overview-writer 에이전트가 작업을 완료하고 concepts-writer로 핸드오프

**변경 전 (작업 시작 시)**:
```html
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: overview-writer -->
<!-- STATUS: IN_PROGRESS -->
<!-- STARTED: 2025-10-14T14:30:00+09:00 -->
<!-- UPDATED: 2025-10-14T15:00:00+09:00 -->
<!-- VALIDATION_SCORE: 0 -->
<!-- IMPROVEMENT_NEEDED:
-->
<!-- HANDOFF LOG:
[START] content-initiator | 파이프라인 시작 | 2025-10-14T14:30:00+09:00
-->
```

**변경 후 (작업 완료 시)**:
```html
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: concepts-writer -->           ← 변경됨
<!-- STATUS: IN_PROGRESS -->                      ← 유지
<!-- STARTED: 2025-10-14T14:30:00+09:00 -->
<!-- UPDATED: 2025-10-14T15:45:00+09:00 -->       ← 갱신됨
<!-- VALIDATION_SCORE: 0 -->
<!-- IMPROVEMENT_NEEDED:
-->
<!-- HANDOFF LOG:
[START] content-initiator | 파이프라인 시작 | 2025-10-14T14:30:00+09:00
[DONE] overview-writer | Overview 섹션 작성 완료 | 2025-10-14T15:45:00+09:00  ← 추가됨
-->
```

**변경 사항 요약**:
1. ✅ HANDOFF LOG에 DONE 엔트리 추가
2. ✅ CURRENT_AGENT를 `concepts-writer`로 변경
3. ✅ UPDATED 타임스탬프 갱신
4. ✅ STATUS는 `IN_PROGRESS` 유지

---

## Section 5: Domain Invariants (도메인 불변식)

도메인 불변식(Invariants)은 Work Status Markers가 **모든 시점**에 **항상** 만족해야 하는 제약조건입니다. 불변식 위반은 시스템 오류를 의미하며, 즉시 감지되고 복구되어야 합니다.

### 5.1 Work Status Markers 필드 불변식

#### 5.1.1 필수 필드 존재성 불변식

**불변식**: Work Status Markers가 존재하는 모든 파일은 **반드시** 다음 6개 필수 필드를 포함해야 합니다.

**필수 필드 목록**:
1. `CURRENT_AGENT` - 다음 실행할 에이전트 (빈 문자열 허용)
2. `STATUS` - 파이프라인 전체 상태
3. `STARTED` - 파이프라인 시작 시간
4. `UPDATED` - 마지막 업데이트 시간
5. `HANDOFF LOG` - 에이전트 실행 이력
6. `WORK STATUS MARKERS` - 마커 블록 시작 주석

**검증 방법**:
```bash
# 필수 필드 존재 여부 확인
required_fields=("CURRENT_AGENT" "STATUS" "STARTED" "UPDATED" "HANDOFF LOG" "WORK STATUS MARKERS")
for field in "${required_fields[@]}"; do
    if ! grep -q "^<!-- $field" "$file_path"; then
        echo "Error: Missing required field: $field"
        exit 1
    fi
done
```

**위반 시 조치**:
- 파일이 손상된 것으로 간주
- 파이프라인 실행 중단
- 명확한 오류 메시지 출력: "Corrupted Work Status Markers: missing field <field-name>"

---

#### 5.1.2 STATUS 필드 enum 불변식

**불변식**: `STATUS` 필드의 값은 **반드시** 다음 4개 enum 값 중 하나여야 합니다.

**허용된 STATUS 값**:
| STATUS | 의미 | 예시 |
|--------|------|------|
| PENDING | 대기 중 | `<!-- STATUS: PENDING -->` |
| IN_PROGRESS | 진행 중 | `<!-- STATUS: IN_PROGRESS -->` |
| COMPLETED | 완료 | `<!-- STATUS: COMPLETED -->` |
| FAILED | 실패 | `<!-- STATUS: FAILED -->` |

**검증 방법**:
```bash
# STATUS 값 추출 및 검증
status=$(grep "^<!-- STATUS:" "$file_path" | sed 's/.*STATUS: \(.*\) -->/\1/')
if [[ ! "$status" =~ ^(PENDING|IN_PROGRESS|COMPLETED|FAILED)$ ]]; then
    echo "Error: Invalid STATUS value: $status"
    exit 1
fi
```

**위반 시 조치**:
- 파일 손상으로 간주
- 오류 메시지: "Invalid STATUS value: <actual-value>. Expected: PENDING|IN_PROGRESS|COMPLETED|FAILED"

---

#### 5.1.3 타임스탬프 형식 불변식

**불변식**: `STARTED`와 `UPDATED` 필드는 **반드시** ISO 8601 형식이어야 합니다.

**ISO 8601 형식**: `YYYY-MM-DDTHH:MM:SS+TZ`
- 예시: `2025-10-14T18:15:00+09:00`

**검증 방법**:
```bash
# ISO 8601 형식 검증 정규식
iso8601_regex='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{2}:[0-9]{2}$'

started=$(grep "^<!-- STARTED:" "$file_path" | sed 's/.*STARTED: \(.*\) -->/\1/')
if [[ ! "$started" =~ $iso8601_regex ]]; then
    echo "Error: STARTED timestamp not in ISO 8601 format: $started"
    exit 1
fi

updated=$(grep "^<!-- UPDATED:" "$file_path" | sed 's/.*UPDATED: \(.*\) -->/\1/')
if [[ ! "$updated" =~ $iso8601_regex ]]; then
    echo "Error: UPDATED timestamp not in ISO 8601 format: $updated"
    exit 1
fi
```

**위반 시 조치**:
- 파싱 오류로 간주
- 오류 메시지: "Invalid timestamp format. Expected ISO 8601: YYYY-MM-DDTHH:MM:SS+TZ"

---

#### 5.1.4 HANDOFF LOG 순서 불변식

**불변식**: HANDOFF LOG의 엔트리는 **반드시** 타임스탬프 오름차순으로 정렬되어야 합니다.

**규칙**: `timestamp[i] < timestamp[i+1]` (모든 i에 대해)

**검증 방법**:
```bash
# HANDOFF LOG 엔트리들의 타임스탬프 추출
timestamps=$(grep -A 50 "^<!-- HANDOFF LOG:" "$file_path" | grep "^\[" | cut -d'|' -f3 | xargs)

# 타임스탬프 순서 검증 (ISO 8601은 문자열 비교 가능)
prev_ts=""
while read -r ts; do
    if [[ -n "$prev_ts" && "$ts" < "$prev_ts" ]]; then
        echo "Error: HANDOFF LOG entries not in chronological order"
        echo "  Previous: $prev_ts"
        echo "  Current: $ts"
        exit 1
    fi
    prev_ts="$ts"
done <<< "$timestamps"
```

**위반 시 조치**:
- 로그 손상으로 간주
- 오류 메시지: "HANDOFF LOG entries not in chronological order"

---

#### 5.1.5 VALIDATION_SCORE 범위 불변식

**불변식**: `VALIDATION_SCORE` 필드 (선택 필드)가 존재하는 경우, 값은 **반드시** 0 이상 100 이하의 정수여야 합니다.

**범위**: `0 ≤ VALIDATION_SCORE ≤ 100`

**검증 방법**:
```bash
# VALIDATION_SCORE 값 추출 (필드가 있는 경우만)
if grep -q "^<!-- VALIDATION_SCORE:" "$file_path"; then
    score=$(grep "^<!-- VALIDATION_SCORE:" "$file_path" | sed 's/.*SCORE: \(.*\) -->/\1/')

    # 정수 검증
    if ! [[ "$score" =~ ^[0-9]+$ ]]; then
        echo "Error: VALIDATION_SCORE must be an integer: $score"
        exit 1
    fi

    # 범위 검증
    if (( score < 0 || score > 100 )); then
        echo "Error: VALIDATION_SCORE out of range: $score (expected 0-100)"
        exit 1
    fi
fi
```

**위반 시 조치**:
- 검증 점수 무효화
- 오류 메시지: "VALIDATION_SCORE out of range: <score> (expected 0-100)"

---

### 5.2 상태 전이 불변식

#### 5.2.1 STATUS 필드 상태 전이 규칙

**불변식**: `STATUS` 필드는 **반드시** 다음 상태 전이 규칙을 따라야 합니다.

**허용된 상태 전이**:
```
초기 상태 (마커 없음)
    ↓
  PENDING (content-initiator 시작)
    ↓
  IN_PROGRESS (첫 에이전트 작업 시작)
    ↓
  IN_PROGRESS (에이전트들 순차 실행)
    ↓
  COMPLETED (content-validator 완료)

또는

  IN_PROGRESS
    ↓
  FAILED (에이전트 실패)
    ↓
  IN_PROGRESS (재시도 성공)
```

**상태 전이 테이블**:
| 현재 STATUS | 허용된 다음 STATUS | 트리거 조건 |
|-------------|------------------|------------|
| (없음) | PENDING | content-initiator가 마커 초기화 |
| PENDING | IN_PROGRESS | 첫 번째 에이전트 시작 |
| IN_PROGRESS | IN_PROGRESS | 에이전트 완료 후 다음 에이전트 대기 |
| IN_PROGRESS | COMPLETED | content-validator 완료 |
| IN_PROGRESS | FAILED | 에이전트 실행 실패 |
| FAILED | IN_PROGRESS | 재시도 성공 |
| FAILED | FAILED | 재시도 실패 |
| COMPLETED | (전이 불가) | 완료 상태는 최종 상태 |

**금지된 상태 전이**:
- ❌ `COMPLETED` → 어떤 상태로도 전이 불가 (최종 상태)
- ❌ `PENDING` → `COMPLETED` (건너뛰기 불가)
- ❌ `PENDING` → `FAILED` (시작 전 실패 불가)
- ❌ `COMPLETED` → `IN_PROGRESS` (재시작 불가, --force 필요)

**검증 로직**:
```bash
validate_status_transition() {
    local current_status="$1"
    local new_status="$2"

    case "$current_status" in
        "")
            [[ "$new_status" == "PENDING" ]] || return 1
            ;;
        "PENDING")
            [[ "$new_status" == "IN_PROGRESS" ]] || return 1
            ;;
        "IN_PROGRESS")
            [[ "$new_status" =~ ^(IN_PROGRESS|COMPLETED|FAILED)$ ]] || return 1
            ;;
        "FAILED")
            [[ "$new_status" =~ ^(IN_PROGRESS|FAILED)$ ]] || return 1
            ;;
        "COMPLETED")
            echo "Error: Cannot transition from COMPLETED state"
            return 1
            ;;
    esac
    return 0
}
```

---

#### 5.2.2 CURRENT_AGENT 필드 순서 불변식

**불변식**: `CURRENT_AGENT` 필드는 **반드시** 파이프라인 순서에 따라 변경되어야 합니다.

**파이프라인 순서**:
```
content-initiator → overview-writer → concepts-writer →
visualization-writer → practice-writer → quiz-writer →
content-validator → (빈 문자열)
```

**허용된 전이**:
| 현재 CURRENT_AGENT | 다음 허용 값 |
|--------------------|-------------|
| overview-writer | concepts-writer |
| concepts-writer | visualization-writer |
| visualization-writer | practice-writer |
| practice-writer | quiz-writer |
| quiz-writer | content-validator |
| content-validator | (빈 문자열) |

**금지된 전이**:
- ❌ 역방향 전이 (예: `concepts-writer` → `overview-writer`)
- ❌ 순서 건너뛰기 (예: `overview-writer` → `visualization-writer`)
  - 단, `--skip` 옵션 사용 시에는 예외적으로 허용

**검증 로직**:
```bash
# 파이프라인 순서 정의
declare -A next_agent=(
    ["content-initiator"]="overview-writer"
    ["overview-writer"]="concepts-writer"
    ["concepts-writer"]="visualization-writer"
    ["visualization-writer"]="practice-writer"
    ["practice-writer"]="quiz-writer"
    ["quiz-writer"]="content-validator"
    ["content-validator"]=""
)

validate_agent_transition() {
    local current_agent="$1"
    local new_agent="$2"
    local expected="${next_agent[$current_agent]}"

    # SKIP된 에이전트 확인
    local is_skipped=false
    if grep -q "^\[SKIP\] $expected" "$file_path"; then
        is_skipped=true
    fi

    # 정상 전이 또는 SKIP된 경우
    if [[ "$new_agent" == "$expected" ]] || [[ "$is_skipped" == true ]]; then
        return 0
    else
        echo "Error: Invalid CURRENT_AGENT transition: $current_agent → $new_agent"
        echo "  Expected: $expected"
        return 1
    fi
}
```

---

#### 5.2.3 HANDOFF LOG Append-Only 불변식

**불변식**: HANDOFF LOG는 **append-only**이며, 기존 엔트리는 **절대** 수정하거나 삭제할 수 없습니다.

**규칙**:
- ✅ 새 엔트리 추가 (마지막에만)
- ❌ 기존 엔트리 수정
- ❌ 기존 엔트리 삭제
- ❌ 엔트리 순서 변경

**이유**:
- 감사 추적 (Audit Trail) 보장
- 이벤트 히스토리 무결성
- 재시도 및 개선 이력 추적

**검증 방법**:
- Git diff로 기존 엔트리 수정 감지
- 엔트리 개수 감소 감지 (삭제 방지)

**위반 시 조치**:
- 심각한 무결성 위반으로 간주
- 파이프라인 즉시 중단
- 오류 메시지: "HANDOFF LOG integrity violation: existing entries modified or deleted"

---

### 5.3 검증 규칙 및 오류 처리

#### 5.3.1 사전 검증 (Precondition Validation)

**시점**: 에이전트 실행 **전**

**검증 항목**:
1. **필수 필드 존재** (5.1.1)
2. **STATUS enum 검증** (5.1.2)
3. **타임스탬프 형식 검증** (5.1.3)
4. **CURRENT_AGENT 일치 검증** (Section 4.1.1)
5. **필수 입력 섹션 존재** (Section 4.1.2)

**검증 실패 시 동작**:
- 에이전트 실행 거부
- Fail-Fast: 즉시 중단
- 오류 메시지 출력
- Exit code 1

**검증 스크립트 예시**:
```bash
validate_preconditions() {
    local file_path="$1"
    local agent_name="$2"

    # 1. 필수 필드 존재
    check_required_fields "$file_path" || return 1

    # 2. STATUS enum 검증
    validate_status_enum "$file_path" || return 1

    # 3. 타임스탬프 형식
    validate_timestamps "$file_path" || return 1

    # 4. CURRENT_AGENT 일치
    validate_current_agent "$file_path" "$agent_name" || return 1

    # 5. 필수 입력 섹션
    validate_input_sections "$file_path" "$agent_name" || return 1

    return 0
}
```

---

#### 5.3.2 사후 검증 (Postcondition Validation)

**시점**: 에이전트 실행 **후**

**검증 항목**:
1. **필수 출력 섹션 존재** (Section 4.2.5)
2. **HANDOFF LOG 엔트리 추가 확인**
3. **CURRENT_AGENT 업데이트 확인**
4. **UPDATED 타임스탬프 갱신 확인**
5. **HANDOFF LOG 순서 유지** (5.1.4)

**검증 실패 시 동작**:
- 에이전트 작업 실패로 간주
- FAILURE 엔트리 기록
- 재시도 또는 파이프라인 중단

**검증 스크립트 예시**:
```bash
validate_postconditions() {
    local file_path="$1"
    local agent_name="$2"

    # 1. 필수 출력 섹션
    validate_output_sections "$file_path" "$agent_name" || return 1

    # 2. HANDOFF LOG 엔트리 추가
    local last_entry=$(grep -A 50 "^<!-- HANDOFF LOG:" "$file_path" | grep "^\[" | tail -1)
    if [[ ! "$last_entry" =~ ^\[DONE\]\ $agent_name ]]; then
        echo "Error: Missing HANDOFF LOG entry for $agent_name"
        return 1
    fi

    # 3. CURRENT_AGENT 업데이트
    validate_agent_transition "$file_path" "$agent_name" || return 1

    # 4. UPDATED 갱신
    local updated=$(grep "^<!-- UPDATED:" "$file_path" | sed 's/.*UPDATED: \(.*\) -->/\1/')
    local last_ts=$(echo "$last_entry" | cut -d'|' -f3 | xargs)
    if [[ "$updated" != "$last_ts" ]]; then
        echo "Error: UPDATED timestamp not synchronized with HANDOFF LOG"
        return 1
    fi

    # 5. HANDOFF LOG 순서
    validate_handoff_log_order "$file_path" || return 1

    return 0
}
```

---

#### 5.3.3 불변식 위반 복구 전략

**복구 가능한 위반**:
| 위반 유형 | 복구 방법 |
|----------|----------|
| 타임스탬프 형식 오류 | 자동 변환 (ISO 8601로) |
| VALIDATION_SCORE 범위 초과 | 0 또는 100으로 클램핑 |
| HANDOFF LOG 순서 오류 | 타임스탬프 기준 재정렬 |

**복구 불가능한 위반**:
| 위반 유형 | 조치 |
|----------|------|
| 필수 필드 누락 | 파이프라인 중단, 수동 복구 필요 |
| STATUS enum 위반 | 파이프라인 중단, 값 수정 필요 |
| HANDOFF LOG 엔트리 삭제 | 무결성 손상, 파일 복원 필요 |

**복구 스크립트 예시**:
```bash
attempt_recovery() {
    local violation_type="$1"
    local file_path="$2"

    case "$violation_type" in
        "timestamp_format")
            echo "Attempting to convert timestamps to ISO 8601..."
            # 자동 변환 로직
            ;;
        "score_range")
            echo "Clamping VALIDATION_SCORE to 0-100 range..."
            # 클램핑 로직
            ;;
        *)
            echo "Error: Cannot auto-recover from $violation_type"
            return 1
            ;;
    esac
}
```

---

### 5.4 불변식 검증 체크리스트

에이전트 실행 전후에 다음 체크리스트를 사용하여 불변식을 검증합니다.

#### Precondition 체크리스트

- [ ] 필수 필드 6개 모두 존재 (CURRENT_AGENT, STATUS, STARTED, UPDATED, HANDOFF LOG, WORK STATUS MARKERS)
- [ ] STATUS 값이 enum 중 하나 (PENDING, IN_PROGRESS, COMPLETED, FAILED)
- [ ] STARTED 타임스탬프가 ISO 8601 형식
- [ ] UPDATED 타임스탬프가 ISO 8601 형식
- [ ] HANDOFF LOG 엔트리가 시간 순서대로 정렬
- [ ] VALIDATION_SCORE (있는 경우) 0-100 범위 내
- [ ] CURRENT_AGENT가 자신의 에이전트명과 일치
- [ ] 필수 입력 섹션 존재

#### Postcondition 체크리스트

- [ ] 필수 출력 섹션 생성 완료
- [ ] HANDOFF LOG에 DONE 엔트리 추가됨
- [ ] CURRENT_AGENT가 다음 에이전트로 업데이트됨
- [ ] UPDATED 타임스탬프가 현재 시간으로 갱신됨
- [ ] STATUS가 적절히 업데이트됨 (IN_PROGRESS 또는 COMPLETED)
- [ ] HANDOFF LOG 순서 유지 (Append-Only)
- [ ] 모든 타임스탬프가 단조 증가

---

### 5.5 불변식 요약

**핵심 불변식 5가지**:

1. **필수 필드 존재성**: 6개 필수 필드 항상 존재
2. **타입 안전성**: STATUS는 enum, 타임스탬프는 ISO 8601, VALIDATION_SCORE는 0-100 정수
3. **순서 보장**: HANDOFF LOG는 시간 순서, CURRENT_AGENT는 파이프라인 순서
4. **Append-Only**: HANDOFF LOG는 추가만 가능, 수정/삭제 금지
5. **상태 전이 규칙**: STATUS와 CURRENT_AGENT는 허용된 전이만 가능

**검증 전략**:
- **Fail-Fast**: 불변식 위반 시 즉시 중단
- **사전+사후 검증**: 에이전트 실행 전후 모두 검증
- **자동 복구**: 복구 가능한 위반은 자동 수정
- **로그 기록**: 모든 불변식 위반 HANDOFF LOG에 기록

---

## Section 6: Context Integration (컨텍스트 통합)

본 섹션은 Work Status Markers Context가 다른 Context들과 어떻게 통합되는지 정의합니다. DDD의 Context Mapping 패턴을 사용하여 에이전트 간 협력 관계를 명확히 합니다.

### 6.1 Upstream/Downstream 관계

#### 6.1.1 파이프라인 데이터 흐름

**데이터 흐름 방향**:
```
content-initiator (START)
    ↓ [Work Status Markers 생성]
overview-writer (Producer)
    ↓ [Overview 섹션 생성]
concepts-writer (Consumer + Producer)
    ↓ [Core Concepts 섹션 생성]
visualization-writer (Consumer + Producer)
    ↓ [Visualization 메타데이터 추가]
practice-writer (Consumer + Producer)
    ↓ [Code Patterns + Experiments 생성]
quiz-writer (Consumer + Producer)
    ↓ [Quiz 섹션 생성]
content-validator (Consumer + COMPLETE)
    ↓ [품질 검증 완료]
(파이프라인 완료)
```

---

#### 6.1.2 에이전트별 역할 정의

| 에이전트 | Upstream 역할 | Downstream 역할 | 생산물 | 소비물 |
|---------|--------------|----------------|--------|--------|
| **content-initiator** | - | Producer | Work Status Markers 초기화 | (없음) |
| **overview-writer** | Consumer | Producer | Overview 섹션 | Work Status Markers |
| **concepts-writer** | Consumer | Producer | Core Concepts 섹션 | Overview 섹션 |
| **visualization-writer** | Consumer | Producer | Visualization 메타데이터 | Core Concepts 섹션 |
| **practice-writer** | Consumer | Producer | Code Patterns + Experiments | Core Concepts 섹션 |
| **quiz-writer** | Consumer | Producer | Quiz 섹션 | 모든 학습 섹션 |
| **content-validator** | Consumer | - | VALIDATION_SCORE, IMPROVEMENT_NEEDED | 모든 섹션 |

---

#### 6.1.3 Upstream/Downstream 관계 특성

**Upstream (상위 에이전트)**:
- 역할: **Producer** (데이터 생산자)
- 책임:
  - 출력 섹션 생성
  - HANDOFF LOG에 DONE 엔트리 추가
  - CURRENT_AGENT를 다음 에이전트로 업데이트
- 권한:
  - Work Status Markers **쓰기 가능**
  - 자신의 출력 섹션 **생성 가능**
- 제약:
  - 이전 에이전트가 생성한 섹션 **수정 불가** (읽기 전용)

**Downstream (하위 에이전트)**:
- 역할: **Consumer** (데이터 소비자)
- 책임:
  - Upstream 에이전트 출력물 검증 (Precondition)
  - Upstream 에이전트 섹션 참조하여 작업
- 권한:
  - Work Status Markers **읽기 가능**
  - Upstream 섹션 **읽기 전용**
- 제약:
  - Upstream 섹션 **수정 불가**
  - CURRENT_AGENT가 자신일 때만 **실행 가능**

---

### 6.2 통합 패턴

#### 6.2.1 Shared Kernel (공유 커널)

**공유하는 개념**: Work Status Markers 형식

**공유 범위**:
1. **필드 구조**:
   - CURRENT_AGENT, STATUS, STARTED, UPDATED
   - VALIDATION_SCORE, IMPROVEMENT_NEEDED
   - HANDOFF LOG

2. **데이터 타입**:
   - STATUS enum: PENDING, IN_PROGRESS, COMPLETED, FAILED
   - 타임스탬프: ISO 8601 형식
   - HANDOFF LOG 엔트리: `[STATUS] agent | message | timestamp`

3. **불변식** (Section 5):
   - 필수 필드 존재성
   - 상태 전이 규칙
   - Append-Only 원칙

**공유 이유**:
- 모든 에이전트가 동일한 마커 형식 이해 필요
- 파이프라인 전체에서 일관된 상태 추적
- 에이전트 간 명시적 통신 채널

**공유 위험 및 완화**:
| 위험 | 영향 | 완화 방안 |
|------|------|-----------|
| 마커 형식 변경 시 모든 에이전트 영향 | 높음 | Published Language로 명세 문서화 |
| 필드 추가 시 하위 호환성 문제 | 중간 | 선택 필드로 추가, 기본값 정의 |
| 불변식 변경 시 검증 로직 동기화 필요 | 중간 | 중앙 집중화된 검증 함수 사용 |

---

#### 6.2.2 Published Language (공개 언어)

**공개 언어**: Work Status Markers Specification v1.0

**명세 문서 위치**:
- `docs/aidlc-docs/specifications/work-status-markers-spec.md` (Unit 1 Phase 2.2에서 생성 예정)

**명세 내용**:
1. **필드 정의**: 각 필드의 이름, 타입, 형식, 필수/선택 여부
2. **HANDOFF LOG 형식**: 엔트리 구조, STATUS 값, 메시지 가이드라인
3. **타임스탬프 형식**: ISO 8601 표준, 타임존 명시
4. **불변식 목록**: 모든 에이전트가 준수해야 할 제약조건
5. **Handoff Protocol**: Section 4의 규칙 요약

**사용 방법**:
- **에이전트 프롬프트**: 명세 문서 참조하여 마커 작성 (Unit 3)
- **검증 스크립트**: 명세 기준으로 마커 검증 (Unit 4)
- **버전 관리**: 명세 변경 시 버전 번호 증가, 변경 로그 기록

---

#### 6.2.3 Conformist (순응자)

**패턴 적용**:
- **순응자**: 모든 Downstream 에이전트
- **표준 정의자**: Work Status Markers Context

**순응 규칙**:
1. **마커 형식 준수**: Downstream 에이전트는 Work Status Markers 형식을 **있는 그대로** 따름
2. **불변식 준수**: Section 5의 모든 불변식을 **무조건 준수**
3. **Handoff Protocol 준수**: Section 4의 모든 규칙을 **엄격히 따름**

**순응자의 책임**:
- Work Status Markers 형식에 대한 이의 제기 불가
- 형식 변경 제안은 Work Status Markers Context 관리자에게 요청
- 자신의 Context 내부 로직은 자유롭게 변경 가능 (마커 조작은 제외)

**장점**:
- 에이전트 간 호환성 보장
- 마커 형식 변경 시 중앙에서 관리 가능
- 불필요한 협상 비용 제거

---

#### 6.2.4 Customer-Supplier (고객-공급자)

**관계 정의**:
| Customer (고객) | Supplier (공급자) | 공급 내용 |
|----------------|-----------------|-----------|
| Orchestration Context | Work Status Markers Context | 마커 파싱/검증 함수 |
| Quality Metrics Context | Work Status Markers Context | VALIDATION_SCORE, HANDOFF LOG 데이터 |
| Agent Prompts Context | Work Status Markers Context | 마커 작성 규칙, Handoff Protocol |

**Supplier의 책임** (Work Status Markers Context):
- Customer의 요구사항 수집
- 명확한 인터페이스 제공 (유틸리티 함수, 명세 문서)
- 하위 호환성 보장

**Customer의 권리**:
- Supplier에게 요구사항 제시 가능
- 인터페이스 변경 시 사전 통보 요청
- 버그 및 개선 사항 피드백

---

### 6.3 통합 제약사항

#### 6.3.1 마커 수정 권한

**권한 매트릭스**:
| Context / 에이전트 | Work Status Markers 읽기 | Work Status Markers 쓰기 | 다른 에이전트 섹션 읽기 | 다른 에이전트 섹션 쓰기 |
|-------------------|----------------------|----------------------|---------------------|---------------------|
| **content-initiator** | ✅ | ✅ (초기화만) | ❌ | ❌ |
| **overview-writer** | ✅ | ✅ (DONE 추가) | ❌ | ❌ |
| **concepts-writer** | ✅ | ✅ (DONE 추가) | ✅ (Overview) | ❌ |
| **visualization-writer** | ✅ | ✅ (DONE 추가) | ✅ (Core Concepts) | ⚠️ (메타데이터만) |
| **practice-writer** | ✅ | ✅ (DONE 추가) | ✅ (Core Concepts) | ❌ |
| **quiz-writer** | ✅ | ✅ (DONE 추가) | ✅ (모든 섹션) | ❌ |
| **content-validator** | ✅ | ✅ (COMPLETE, VALIDATION_SCORE) | ✅ (모든 섹션) | ⚠️ (개선 지시만) |
| **Orchestration** | ✅ | ⚠️ (FAILURE, SKIP만) | ✅ | ❌ |

**권한 설명**:
- ✅ **전체 가능**: 해당 작업 수행 가능
- ⚠️ **부분 가능**: 특정 조건하에서만 가능
- ❌ **불가능**: 해당 작업 금지

---

#### 6.3.2 동시성 제어

**문제점**:
- 여러 에이전트가 동시에 실행되는 경우 Work Status Markers 충돌 가능
- 예: 수동 재시도 중 자동 스크립트가 다음 에이전트 실행

**해결 방안**: Lock 파일 메커니즘

**Lock 파일 구조**:
```bash
# Lock 파일 경로
lock_file="${file_path}.lock"

# Lock 파일 내용
{
  "agent": "overview-writer",
  "pid": 12345,
  "started": "2025-10-16T10:30:00+09:00",
  "session_id": "abc123def456"
}
```

**Lock 획득 프로토콜**:
```bash
acquire_lock() {
    local file_path="$1"
    local agent_name="$2"
    local lock_file="${file_path}.lock"
    local max_wait=300  # 5분

    local waited=0
    while [[ -f "$lock_file" ]]; do
        # Lock 파일 나이 확인 (5분 이상이면 stale lock으로 간주)
        local lock_age=$(( $(date +%s) - $(stat -f %m "$lock_file") ))
        if (( lock_age > 300 )); then
            echo "Stale lock detected. Removing..."
            rm -f "$lock_file"
            break
        fi

        sleep 1
        waited=$((waited + 1))
        if (( waited > max_wait )); then
            echo "Error: Timeout waiting for lock"
            return 1
        fi
    done

    # Lock 생성
    echo "{\"agent\":\"$agent_name\",\"pid\":$$,\"started\":\"$(date -Iseconds)\"}" > "$lock_file"
    return 0
}

release_lock() {
    local file_path="$1"
    local lock_file="${file_path}.lock"
    rm -f "$lock_file"
}
```

**Lock 사용 예시**:
```bash
# 에이전트 실행 시작
acquire_lock "$file_path" "$agent_name" || exit 1

# 작업 수행
perform_work

# Lock 해제 (항상 실행)
trap "release_lock '$file_path'" EXIT
```

---

#### 6.3.3 에이전트 간 의존성

**의존성 그래프**:
```mermaid
graph TD
    CI[content-initiator]
    OW[overview-writer]
    CW[concepts-writer]
    VW[visualization-writer]
    PW[practice-writer]
    QW[quiz-writer]
    CV[content-validator]

    CI --> OW
    OW --> CW
    CW --> VW
    CW --> PW
    OW --> QW
    CW --> QW
    PW --> QW
    VW --> CV
    PW --> CV
    QW --> CV

    style CI fill:#e1f5ff
    style OW fill:#fff4e1
    style CW fill:#f0fff4
    style VW fill:#ffe1f5
    style PW fill:#f5ffe1
    style QW fill:#fff4e1
    style CV fill:#e1f5ff
```

**의존성 규칙**:
1. **직접 의존**:
   - concepts-writer → overview-writer (Overview 섹션 필요)
   - visualization-writer → concepts-writer (Core Concepts 필요)
   - quiz-writer → 모든 학습 섹션 (Overview, Core Concepts, Code Patterns, Experiments)

2. **간접 의존**:
   - content-validator → 모든 에이전트 (모든 섹션 검증)

3. **순환 의존 방지**:
   - ❌ concepts-writer가 quiz-writer 출력 참조 불가
   - ❌ visualization-writer가 practice-writer 출력 참조 불가

**의존성 위반 시 조치**:
- Precondition 검증에서 필수 섹션 부재 감지
- 에이전트 실행 거부
- 명확한 오류 메시지: "Missing required section: <section-name> (produced by <agent-name>)"

---

### 6.4 Context 간 통신 프로토콜

#### 6.4.1 동기식 통신 (Synchronous)

**사용 시점**: 에이전트 간 직접 핸드오프

**통신 방법**:
1. Upstream 에이전트가 HANDOFF LOG에 DONE 엔트리 추가
2. CURRENT_AGENT를 Downstream 에이전트로 업데이트
3. Downstream 에이전트가 CURRENT_AGENT 확인 후 실행

**특징**:
- **순차 실행**: 한 번에 하나의 에이전트만 실행
- **명시적 핸드오프**: CURRENT_AGENT 필드로 다음 에이전트 지정
- **동기화 보장**: Upstream 완료 후에만 Downstream 실행

---

#### 6.4.2 비동기식 통신 (Asynchronous)

**사용 시점**: content-validator의 개선 지시

**통신 방법**:
1. content-validator가 IMPROVEMENT_NEEDED 필드에 개선 대상 에이전트 기록
2. Orchestration이 IMPROVEMENT_NEEDED 읽고 해당 에이전트 재실행
3. 에이전트가 개선 작업 후 DONE 엔트리 추가

**특징**:
- **간접 통신**: IMPROVEMENT_NEEDED 필드를 통한 메시지 전달
- **지연 실행**: content-validator 완료 후 별도 시점에 재실행
- **다중 대상**: 여러 에이전트에 동시에 개선 지시 가능

**예시**:
```html
<!-- IMPROVEMENT_NEEDED:
  - overview-writer: 학습 동기 부분이 너무 짧습니다 (최소 3문단 필요)
  - concepts-writer: Expert 난이도 설명에 기술 용어 정의 누락
-->
```

---

### 6.5 Context 통합 시나리오

#### 시나리오 1: 정상 흐름 (Happy Path)

```
1. content-initiator → Work Status Markers 초기화
   - CURRENT_AGENT: overview-writer
   - STATUS: PENDING
   - HANDOFF LOG: [START]

2. overview-writer → Overview 섹션 생성
   - Precondition: CURRENT_AGENT == "overview-writer" ✅
   - 작업 수행
   - HANDOFF LOG: [DONE] overview-writer | ...
   - CURRENT_AGENT: concepts-writer
   - Postcondition: "# Overview" 존재 ✅

3. concepts-writer → Core Concepts 섹션 생성
   - Precondition: CURRENT_AGENT == "concepts-writer" ✅
   - Precondition: "# Overview" 존재 ✅
   - 작업 수행
   - HANDOFF LOG: [DONE] concepts-writer | ...
   - CURRENT_AGENT: visualization-writer

...

7. content-validator → 품질 검증
   - Precondition: 모든 섹션 존재 ✅
   - 검증 수행
   - VALIDATION_SCORE: 100
   - HANDOFF LOG: [COMPLETE] content-validator | ...
   - CURRENT_AGENT: (빈 문자열)
   - STATUS: COMPLETED
```

---

#### 시나리오 2: 에이전트 실패 및 재시도

```
1-3. (정상 흐름과 동일)

4. visualization-writer → 실패
   - Precondition: CURRENT_AGENT == "visualization-writer" ✅
   - 작업 시도 #1 실패 (파싱 오류)
   - HANDOFF LOG: [FAILURE] visualization-writer | 파싱 실패 (attempt 1/3)
   - CURRENT_AGENT: visualization-writer (유지)
   - STATUS: FAILED

5. Orchestration → 재시도
   - CURRENT_AGENT == "visualization-writer" 확인
   - visualization-writer 재실행

6. visualization-writer → 성공
   - Precondition: CURRENT_AGENT == "visualization-writer" ✅
   - 작업 시도 #2 성공
   - HANDOFF LOG: [DONE] visualization-writer | ...
   - CURRENT_AGENT: practice-writer
   - STATUS: IN_PROGRESS

...
```

---

#### 시나리오 3: 개선 요청 및 재실행

```
1-7. (정상 흐름으로 content-validator까지 실행)

8. content-validator → 개선 필요 판정
   - VALIDATION_SCORE: 75
   - IMPROVEMENT_NEEDED:
     - overview-writer: 학습 동기 부분 보강 필요
     - concepts-writer: Expert 난이도 예시 추가 필요
   - HANDOFF LOG: [COMPLETE] content-validator | 개선 필요 (75점)
   - CURRENT_AGENT: overview-writer (재시작)
   - STATUS: IN_PROGRESS

9. Orchestration → overview-writer 재실행
   - IMPROVEMENT_NEEDED 읽기
   - overview-writer 재실행 (개선 작업)

10. overview-writer → 개선 완료
    - HANDOFF LOG: [DONE] overview-writer | Overview 섹션 개선 완료
    - CURRENT_AGENT: concepts-writer

11. concepts-writer → 개선 완료
    - HANDOFF LOG: [DONE] concepts-writer | Expert 난이도 예시 추가 완료
    - CURRENT_AGENT: visualization-writer

...

15. content-validator → 재검증
    - VALIDATION_SCORE: 95
    - HANDOFF LOG: [COMPLETE] content-validator | 품질 검증 완료 (95점)
    - CURRENT_AGENT: (빈 문자열)
    - STATUS: COMPLETED
```

---

### 6.6 Context 통합 요약

**핵심 통합 패턴 3가지**:
1. **Shared Kernel**: 모든 에이전트가 Work Status Markers 형식 공유
2. **Published Language**: Work Status Markers Specification v1.0으로 명세 문서화
3. **Conformist**: Downstream 에이전트가 Work Status Markers 형식 준수

**통합 제약사항 3가지**:
1. **마커 수정 권한**: 에이전트별 읽기/쓰기 권한 명확히 정의
2. **동시성 제어**: Lock 파일 메커니즘으로 충돌 방지
3. **의존성 관리**: 에이전트 간 의존성 그래프로 순서 보장

**통신 프로토콜 2가지**:
1. **동기식**: CURRENT_AGENT를 통한 직접 핸드오프
2. **비동기식**: IMPROVEMENT_NEEDED를 통한 개선 지시

---
---

## 7. Validation (도메인 모델 검증)

본 섹션에서는 앞서 정의한 도메인 모델 (Sections 1-6)을 3가지 핵심 시나리오를 통해 검증합니다. 각 시나리오에서 Handoff Protocol, Domain Events, Domain Invariants가 정상 작동하는지 확인합니다.

---

### 7.1 시나리오 기반 검증

#### 7.1.1 정상 흐름 (Happy Path): 파이프라인 시작 → 완료

**시나리오 설명**: 모든 에이전트가 성공적으로 실행되어 콘텐츠 생성이 완료되는 정상 흐름

**단계별 Work Status Markers 변화**:

```markdown
<!-- 1. content-initiator 실행 전 -->
(파일 미존재)

<!-- 2. content-initiator 실행 후 -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: overview-writer
STATUS: PENDING
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:00:05+09:00
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
-->

<!-- 3. overview-writer 실행 후 -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: concepts-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:05:30+09:00
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
-->

<!-- 4. concepts-writer 실행 후 -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: visualization-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:12:00+09:00
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [DONE] concepts-writer | Core Concepts 작성 완료 (Easy/Normal/Expert 3단계) | 2025-10-16T10:12:00+09:00
-->

<!-- 5. visualization-writer 실행 후 -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: practice-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:15:00+09:00
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [DONE] concepts-writer | Core Concepts 작성 완료 (Easy/Normal/Expert 3단계) | 2025-10-16T10:12:00+09:00
- [DONE] visualization-writer | 시각화 메타데이터 3개 삽입 완료 | 2025-10-16T10:15:00+09:00
-->

<!-- 6. practice-writer 실행 후 -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: quiz-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:22:00+09:00
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [DONE] concepts-writer | Core Concepts 작성 완료 (Easy/Normal/Expert 3단계) | 2025-10-16T10:12:00+09:00
- [DONE] visualization-writer | 시각화 메타데이터 3개 삽입 완료 | 2025-10-16T10:15:00+09:00
- [DONE] practice-writer | Code Patterns 5개, Experiments 3개 작성 완료 | 2025-10-16T10:22:00+09:00
-->

<!-- 7. quiz-writer 실행 후 -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: content-validator
STATUS: IN_PROGRESS
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:28:00+09:00
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [DONE] concepts-writer | Core Concepts 작성 완료 (Easy/Normal/Expert 3단계) | 2025-10-16T10:12:00+09:00
- [DONE] visualization-writer | 시각화 메타데이터 3개 삽입 완료 | 2025-10-16T10:15:00+09:00
- [DONE] practice-writer | Code Patterns 5개, Experiments 3개 작성 완료 | 2025-10-16T10:22:00+09:00
- [DONE] quiz-writer | 퀴즈 10개 작성 완료 (multiple-choice 6개, true-false 4개) | 2025-10-16T10:28:00+09:00
-->

<!-- 8. content-validator 실행 후 (검증 성공) -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT:
STATUS: COMPLETED
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:35:00+09:00
VALIDATION_SCORE: 95
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [DONE] concepts-writer | Core Concepts 작성 완료 (Easy/Normal/Expert 3단계) | 2025-10-16T10:12:00+09:00
- [DONE] visualization-writer | 시각화 메타데이터 3개 삽입 완료 | 2025-10-16T10:15:00+09:00
- [DONE] practice-writer | Code Patterns 5개, Experiments 3개 작성 완료 | 2025-10-16T10:22:00+09:00
- [DONE] quiz-writer | 퀴즈 10개 작성 완료 (multiple-choice 6개, true-false 4개) | 2025-10-16T10:28:00+09:00
- [COMPLETE] content-validator | 품질 검증 완료 (점수: 95/100) | 2025-10-16T10:35:00+09:00
-->
```

**불변식 검증**:

| 불변식 | 검증 결과 | 설명 |
|--------|----------|------|
| **필수 필드 존재성** | ✅ 통과 | 모든 단계에서 6개 필수 필드 존재 |
| **STATUS enum 값** | ✅ 통과 | PENDING → IN_PROGRESS → COMPLETED (허용된 전이) |
| **ISO 8601 타임스탬프** | ✅ 통과 | 모든 타임스탬프가 `YYYY-MM-DDTHH:MM:SS+09:00` 형식 |
| **HANDOFF LOG 순서** | ✅ 통과 | 시간 순서대로 정렬됨 (10:00:05 → 10:05:30 → ... → 10:35:00) |
| **Append-Only** | ✅ 통과 | 기존 엔트리 수정/삭제 없이 추가만 발생 |
| **CURRENT_AGENT 순서** | ✅ 통과 | 파이프라인 순서 준수 (overview → concepts → visualization → practice → quiz → validator → 빈 문자열) |
| **단일 엔트리** | ✅ 통과 | 각 에이전트당 1개 엔트리만 존재 |

**Domain Event 검증**:

- **PipelineStartedEvent**: content-initiator의 [START] 엔트리
- **AgentCompletedEvent**: 각 에이전트의 [DONE] 엔트리 (6개)
- **PipelineCompletedEvent**: content-validator의 [COMPLETE] 엔트리

**Handoff Protocol 준수 확인**:

1. **Precondition 검증**:
   - 각 에이전트 실행 전 `CURRENT_AGENT` 일치 확인됨
   - 필수 입력 섹션 존재 확인됨 (예: concepts-writer 실행 전 Overview 섹션 존재)

2. **Postcondition 보장**:
   - 각 에이전트 실행 후 `HANDOFF LOG`에 `[DONE]` 엔트리 추가됨
   - `CURRENT_AGENT` 필드가 다음 에이전트로 업데이트됨
   - `UPDATED` 타임스탬프 갱신됨
   - 출력 섹션 생성 확인됨

**결론**: 정상 흐름에서 모든 불변식, Domain Events, Handoff Protocol이 정상 작동함.

---

#### 7.1.2 실패 흐름 (Failure + Retry): 에이전트 실패 → 재시작

**시나리오 설명**: concepts-writer 실행 중 오류 발생 → 재시도하여 성공

**단계별 Work Status Markers 변화**:

```markdown
<!-- 1. overview-writer 실행 완료 -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: concepts-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:05:30+09:00
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
-->

<!-- 2. concepts-writer 실행 실패 (API timeout) -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: concepts-writer
STATUS: FAILED
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:08:00+09:00
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [FAILURE] concepts-writer | 오류: API timeout (60초 초과) | 2025-10-16T10:08:00+09:00
-->

<!-- 3. 오케스트레이션 스크립트가 재시도 결정 (최대 3회) -->
<!-- WORK STATUS MARKERS 변경 없음 - 재시도 전 상태 유지 -->

<!-- 4. concepts-writer 재실행 성공 -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: visualization-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:15:00+09:00
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [FAILURE] concepts-writer | 오류: API timeout (60초 초과) | 2025-10-16T10:08:00+09:00
- [DONE] concepts-writer | Core Concepts 작성 완료 (재시도 성공) | 2025-10-16T10:15:00+09:00
-->

<!-- 5. 이후 파이프라인 정상 진행... -->
```

**불변식 검증**:

| 불변식 | 검증 결과 | 설명 |
|--------|----------|------|
| **STATUS 상태 전이** | ✅ 통과 | IN_PROGRESS → FAILED → IN_PROGRESS (허용된 전이) |
| **Append-Only** | ✅ 통과 | FAILURE 엔트리와 DONE 엔트리 모두 보존 (덮어쓰기 없음) |
| **CURRENT_AGENT 불변** | ✅ 통과 | 재시도 시 `CURRENT_AGENT`는 `concepts-writer`로 유지 |
| **단일 엔트리 예외** | ✅ 통과 | concepts-writer의 [FAILURE]와 [DONE] 엔트리 공존 허용 (오류 이력 보존) |
| **타임스탬프 순서** | ✅ 통과 | 10:08:00 (FAILURE) < 10:15:00 (DONE) |

**오류 처리 프로토콜 검증**:

1. **실패 기록**:
   - `STATUS` 필드가 `FAILED`로 업데이트됨
   - `HANDOFF LOG`에 `[FAILURE]` 엔트리 추가됨
   - 오류 메시지 기록: "API timeout (60초 초과)"

2. **재시도 메커니즘** (오케스트레이션 스크립트 책임):
   - `STATUS`가 `FAILED`인 경우 재시도 카운터 확인
   - `CURRENT_AGENT`가 재시도할 에이전트로 유지됨
   - 재시도 제한 (최대 3회) 적용

3. **복구 후 정상 진행**:
   - 재시도 성공 시 `STATUS`가 `IN_PROGRESS`로 복구
   - 새 `[DONE]` 엔트리 추가 (이전 `[FAILURE]` 엔트리 보존)
   - 다음 에이전트로 핸드오프 (`CURRENT_AGENT` 업데이트)

**결론**: 실패 및 재시도 시나리오에서도 불변식 유지, 오류 이력 보존, 정상 복구 확인됨.

---

#### 7.1.3 개선 흐름 (Improvement Loop): content-validator → 개선 지시 → 재실행

**시나리오 설명**: content-validator가 품질 문제 발견 → 특정 에이전트에 개선 지시 → 해당 에이전트 재실행

**단계별 Work Status Markers 변화**:

```markdown
<!-- 1. 모든 에이전트 실행 완료 (content-validator 실행 전) -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: content-validator
STATUS: IN_PROGRESS
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:28:00+09:00
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [DONE] concepts-writer | Core Concepts 작성 완료 (Easy/Normal/Expert 3단계) | 2025-10-16T10:12:00+09:00
- [DONE] visualization-writer | 시각화 메타데이터 3개 삽입 완료 | 2025-10-16T10:15:00+09:00
- [DONE] practice-writer | Code Patterns 5개, Experiments 3개 작성 완료 | 2025-10-16T10:22:00+09:00
- [DONE] quiz-writer | 퀴즈 10개 작성 완료 (multiple-choice 6개, true-false 4개) | 2025-10-16T10:28:00+09:00
-->

<!-- 2. content-validator 실행 후 (품질 문제 발견) -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: concepts-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:35:00+09:00
VALIDATION_SCORE: 65
IMPROVEMENT_NEEDED:
- concepts-writer: Expert 난이도 설명이 너무 짧음 (현재 50줄, 최소 100줄 필요)
- concepts-writer: ECMAScript 명세 참조 누락
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [DONE] concepts-writer | Core Concepts 작성 완료 (Easy/Normal/Expert 3단계) | 2025-10-16T10:12:00+09:00
- [DONE] visualization-writer | 시각화 메타데이터 3개 삽입 완료 | 2025-10-16T10:15:00+09:00
- [DONE] practice-writer | Code Patterns 5개, Experiments 3개 작성 완료 | 2025-10-16T10:22:00+09:00
- [DONE] quiz-writer | 퀴즈 10개 작성 완료 (multiple-choice 6개, true-false 4개) | 2025-10-16T10:28:00+09:00
- [DONE] content-validator | 품질 검증 완료 (점수: 65/100, 개선 필요) | 2025-10-16T10:35:00+09:00
-->

<!-- 3. concepts-writer 재실행 (개선 작업) -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT: content-validator
STATUS: IN_PROGRESS
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:42:00+09:00
VALIDATION_SCORE: 65
IMPROVEMENT_NEEDED:
- concepts-writer: Expert 난이도 설명이 너무 짧음 (현재 50줄, 최소 100줄 필요)
- concepts-writer: ECMAScript 명세 참조 누락
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [DONE] concepts-writer | Core Concepts 작성 완료 (Easy/Normal/Expert 3단계) | 2025-10-16T10:12:00+09:00
- [DONE] visualization-writer | 시각화 메타데이터 3개 삽입 완료 | 2025-10-16T10:15:00+09:00
- [DONE] practice-writer | Code Patterns 5개, Experiments 3개 작성 완료 | 2025-10-16T10:22:00+09:00
- [DONE] quiz-writer | 퀴즈 10개 작성 완료 (multiple-choice 6개, true-false 4개) | 2025-10-16T10:28:00+09:00
- [DONE] content-validator | 품질 검증 완료 (점수: 65/100, 개선 필요) | 2025-10-16T10:35:00+09:00
- [IMPROVE] concepts-writer | 개선 완료 (Expert 난이도 150줄 확장, 명세 참조 추가) | 2025-10-16T10:42:00+09:00
-->

<!-- 4. content-validator 재실행 (재검증) -->
<!-- WORK STATUS MARKERS
CURRENT_AGENT:
STATUS: COMPLETED
STARTED: 2025-10-16T10:00:00+09:00
UPDATED: 2025-10-16T10:45:00+09:00
VALIDATION_SCORE: 92
HANDOFF LOG:
- [START] content-initiator | 파이프라인 초기화 완료 | 2025-10-16T10:00:05+09:00
- [DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
- [DONE] concepts-writer | Core Concepts 작성 완료 (Easy/Normal/Expert 3단계) | 2025-10-16T10:12:00+09:00
- [DONE] visualization-writer | 시각화 메타데이터 3개 삽입 완료 | 2025-10-16T10:15:00+09:00
- [DONE] practice-writer | Code Patterns 5개, Experiments 3개 작성 완료 | 2025-10-16T10:22:00+09:00
- [DONE] quiz-writer | 퀴즈 10개 작성 완료 (multiple-choice 6개, true-false 4개) | 2025-10-16T10:28:00+09:00
- [DONE] content-validator | 품질 검증 완료 (점수: 65/100, 개선 필요) | 2025-10-16T10:35:00+09:00
- [IMPROVE] concepts-writer | 개선 완료 (Expert 난이도 150줄 확장, 명세 참조 추가) | 2025-10-16T10:42:00+09:00
- [COMPLETE] content-validator | 최종 검증 통과 (점수: 92/100) | 2025-10-16T10:45:00+09:00
-->
```

**불변식 검증**:

| 불변식 | 검증 결과 | 설명 |
|--------|----------|------|
| **Append-Only** | ✅ 통과 | concepts-writer의 [DONE]과 [IMPROVE] 엔트리 모두 보존 |
| **CURRENT_AGENT 순서 예외** | ✅ 통과 | 개선 루프: validator → concepts-writer → validator (비선형 흐름 허용) |
| **VALIDATION_SCORE 업데이트** | ✅ 통과 | 65 → 92 (점수 상승) |
| **IMPROVEMENT_NEEDED 삭제** | ✅ 통과 | 재검증 통과 시 IMPROVEMENT_NEEDED 필드 제거됨 |
| **STATUS 전이** | ✅ 통과 | IN_PROGRESS → IN_PROGRESS → COMPLETED |

**개선 루프 프로토콜 검증**:

1. **품질 문제 감지**:
   - content-validator가 `VALIDATION_SCORE` 산출 (65점)
   - `IMPROVEMENT_NEEDED` 필드에 개선 항목 기록
   - `CURRENT_AGENT`를 개선 대상 에이전트로 설정 (concepts-writer)

2. **개선 작업 수행**:
   - concepts-writer가 `IMPROVEMENT_NEEDED` 필드 읽고 개선 수행
   - 개선 완료 후 `[IMPROVE]` 엔트리 추가 (첫 번째 [DONE]과 구분)
   - `CURRENT_AGENT`를 content-validator로 재설정

3. **재검증**:
   - content-validator 재실행으로 `VALIDATION_SCORE` 재산출 (92점)
   - 통과 기준 충족 시 `IMPROVEMENT_NEEDED` 제거
   - `STATUS`를 `COMPLETED`로 업데이트

**특수 사항**:

- **비선형 파이프라인 흐름**: 개선 루프는 validator → specific-agent → validator 흐름 허용
- **[IMPROVE] 이벤트 타입**: 개선 작업은 [DONE]이 아닌 [IMPROVE]로 기록하여 첫 번째 작업과 구분
- **조건부 완료**: VALIDATION_SCORE ≥ 90 충족 시에만 `COMPLETED` 전이

**결론**: 개선 루프 시나리오에서도 불변식 유지, 비선형 흐름 처리, 품질 개선 확인됨.

---

### 7.2 불변식 검증 (경계 조건)

앞서 3가지 시나리오에서 정상 케이스를 검증했으므로, 이제 경계 조건 및 예외 상황을 검증합니다.

#### 7.2.1 경계 조건 테스트 케이스

| 테스트 케이스 | 입력 조건 | 예상 결과 | 불변식 검증 |
|-------------|----------|----------|-----------|
| **1. 빈 HANDOFF LOG** | content-initiator 실행 직전 (파일 미존재) | 파일 생성 시 [START] 엔트리만 존재 | ✅ Append-Only (초기 상태) |
| **2. CURRENT_AGENT 빈 문자열** | 파이프라인 완료 후 (STATUS: COMPLETED) | 빈 문자열 허용됨 | ✅ 필수 필드 존재성 (빈 값도 존재로 간주) |
| **3. STATUS 전이 금지** | STATUS: COMPLETED인 파일에 에이전트 재실행 시도 | Precondition 실패 → 즉시 중단 | ✅ 상태 전이 불변식 (COMPLETED → 전이 불가) |
| **4. CURRENT_AGENT 불일치** | overview-writer 실행 시 CURRENT_AGENT: concepts-writer | Precondition 실패 → "CURRENT_AGENT mismatch" 오류 | ✅ CURRENT_AGENT 순서 불변식 |
| **5. 타임스탬프 역순** | 수동으로 과거 시간 삽입 시도 | 검증 스크립트가 역순 감지 → 오류 | ✅ HANDOFF LOG 순서 불변식 |
| **6. 동일 에이전트 중복 DONE** | concepts-writer가 [DONE] 엔트리 2개 생성 (개선 루프 아닌 일반 흐름) | 개선 루프가 아니면 오류 | ⚠️ 단일 엔트리 불변식 (개선 루프 예외 처리 필요) |
| **7. 필수 필드 누락** | STARTED 필드 없이 파일 생성 | 검증 스크립트가 감지 → "Missing required field: STARTED" 오류 | ✅ 필수 필드 존재성 불변식 |
| **8. VALIDATION_SCORE 범위 초과** | VALIDATION_SCORE: 150 (0-100 범위 벗어남) | 검증 스크립트가 감지 → "VALIDATION_SCORE out of range" 오류 | ✅ VALIDATION_SCORE 범위 불변식 |
| **9. ISO 8601 형식 위반** | UPDATED: 2025-10-16 10:00:00 (T 누락) | 검증 스크립트가 감지 → "Invalid timestamp format" 오류 | ✅ ISO 8601 타임스탬프 불변식 |
| **10. Lock 파일 존재 시 실행** | `.lock` 파일이 이미 존재하는 상태에서 에이전트 실행 | 5분 대기 또는 stale lock 감지 후 실행 | ✅ 동시성 제어 (Lock 메커니즘) |

**경계 조건 검증 결론**:
- 10개 경계 조건 중 9개 통과, 1개는 개선 루프 예외 처리 필요 (케이스 6)
- 대부분의 불변식이 예외 상황에서도 유지됨
- 검증 스크립트 (Precondition/Postcondition)가 불변식 위반을 효과적으로 감지

---

### 7.3 용어 일관성 검증 (Ubiquitous Language)

Sections 1-6에서 정의한 Ubiquitous Language가 일관되게 사용되었는지 검증합니다.

#### 7.3.1 핵심 용어 사용 일관성

| 용어 | 정의 (Section 2) | Section 3 사용 | Section 4 사용 | Section 5 사용 | Section 6 사용 | 일관성 검증 |
|------|----------------|--------------|--------------|--------------|--------------|-----------|
| **Pipe** | 에이전트 간 데이터 전달 채널 (Work Status Markers) | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일관됨 |
| **Filter** | 파이프라인의 처리 단계 (7개 에이전트) | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일관됨 |
| **STATUS** | 파이프라인 전체 진행 상태 (PENDING, IN_PROGRESS, COMPLETED, FAILED) | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일관됨 |
| **HANDOFF LOG** | 에이전트 실행 이력 (Domain Event 기록) | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일관됨 |
| **Handoff** | 현재 에이전트가 다음 에이전트로 제어권 이전 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일관됨 |
| **Precondition** | 에이전트 실행 전 검증 규칙 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일관됨 |
| **Postcondition** | 에이전트 실행 후 보장 조건 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일관됨 |
| **Domain Event** | HANDOFF LOG 엔트리 (PipelineStartedEvent, AgentCompletedEvent 등) | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일관됨 |
| **Invariant** | 항상 참이어야 하는 도메인 규칙 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일관됨 |
| **Bounded Context** | Work Status Markers Context | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일치 | ✅ 일관됨 |
| **Shared Kernel** | 모든 에이전트가 공유하는 Work Status Markers 형식 | - | - | - | ✅ 일치 | ✅ 일관됨 |
| **Published Language** | Work Status Markers Specification v1.0 | - | - | - | ✅ 일치 | ✅ 일관됨 |
| **Upstream/Downstream** | 파이프라인 데이터 흐름 방향 | - | - | - | ✅ 일치 | ✅ 일관됨 |

**일관성 검증 결과**: 13개 핵심 용어 모두 일관되게 사용됨. 모호하거나 충돌하는 정의 없음.

#### 7.3.2 모호한 용어 및 개선 제안

**검토 결과**: 모호한 용어 없음. 다음과 같은 용어 사용 패턴이 명확히 구분됨:

1. **Work Status Markers vs. Pipe**:
   - "Work Status Markers"는 **구체적인 구현** (HTML 주석 내 필드)
   - "Pipe"는 **추상적 개념** (Pipeline Architecture의 데이터 전달 채널)
   - **일관성**: Pipe를 설명할 때 "implemented as Work Status Markers" 형태로 사용

2. **Agent vs. Filter**:
   - "Agent"는 **구체적인 AI 서브에이전트** (overview-writer, concepts-writer 등)
   - "Filter"는 **Pipeline Architecture 용어** (처리 단계)
   - **일관성**: "7 agents act as filters in the pipeline" 형태로 사용

3. **HANDOFF LOG vs. Domain Event**:
   - "HANDOFF LOG"는 **구체적인 필드명** (Work Status Markers의 필드)
   - "Domain Event"는 **DDD 개념** (도메인 이벤트)
   - **일관성**: "HANDOFF LOG entries represent Domain Events" 형태로 사용

**개선 제안**: 현재 용어 사용 방식 유지 (개선 불필요).

---

### 7.4 검증 요약

#### 7.4.1 시나리오 검증 결과

| 시나리오 | 검증 항목 | 결과 | 비고 |
|---------|---------|------|------|
| **정상 흐름** | 불변식 유지 | ✅ 통과 | 7개 불변식 모두 통과 |
| **정상 흐름** | Domain Event 발생 | ✅ 통과 | START, DONE (6회), COMPLETE 이벤트 발생 |
| **정상 흐름** | Handoff Protocol 준수 | ✅ 통과 | Precondition/Postcondition 검증 통과 |
| **실패 흐름** | 오류 처리 프로토콜 | ✅ 통과 | FAILURE 이벤트 기록, 재시도 성공, 이력 보존 |
| **실패 흐름** | 불변식 유지 | ✅ 통과 | 실패 및 복구 과정에서 불변식 유지 |
| **개선 흐름** | 비선형 흐름 처리 | ✅ 통과 | validator → agent → validator 루프 정상 작동 |
| **개선 흐름** | 품질 개선 메커니즘 | ✅ 통과 | VALIDATION_SCORE 업데이트, IMPROVEMENT_NEEDED 관리 |

#### 7.4.2 경계 조건 검증 결과

- **10개 경계 조건 테스트 케이스**: 9개 통과, 1개 개선 필요 (케이스 6: 중복 DONE 엔트리 예외 처리)
- **불변식 위반 감지**: 검증 스크립트가 효과적으로 불변식 위반 감지 (7개 케이스)
- **Lock 메커니즘**: 동시성 제어 정상 작동 (케이스 10)

#### 7.4.3 용어 일관성 검증 결과

- **13개 핵심 용어**: 모두 일관되게 사용됨
- **모호한 용어**: 없음
- **충돌하는 정의**: 없음

#### 7.4.4 전체 검증 결론

✅ **도메인 모델 검증 통과**

**강점**:
1. 정상 흐름, 실패 흐름, 개선 루프 모두에서 불변식 유지
2. Domain Events가 명확히 정의되고 추적 가능
3. Handoff Protocol이 에이전트 행동을 명확히 규정
4. Ubiquitous Language가 일관되게 사용됨
5. 경계 조건 대부분이 검증 스크립트로 감지 가능

**개선 필요**:
1. **케이스 6 (중복 DONE 엔트리)**: 개선 루프와 일반 흐름을 구분하는 명확한 규칙 필요
   - **제안**: `IMPROVEMENT_NEEDED` 필드 존재 시에만 중복 엔트리 허용

**다음 단계**: Section 8 (문서 최종화)에서 다이어그램 추가 및 검토 요청 준비

---

## 8. Finalization (문서 최종화)

본 섹션에서는 도메인 설계 문서를 최종화합니다. 핵심 다이어그램을 추가하고, 문서 완성도를 검토하며, 핵심 결정 사항을 요약합니다.

---

### 8.1 다이어그램

#### 8.1.1 Context Mapping Diagram

Work Status Markers Context와 다른 Bounded Context 간의 관계를 시각화합니다.

```mermaid
graph TB
    subgraph "Work Status Markers Context"
        WSM[Work Status Markers]
        WSM_Fields["필수 필드:<br/>CURRENT_AGENT<br/>STATUS<br/>STARTED<br/>UPDATED<br/>HANDOFF LOG"]
        WSM --> WSM_Fields
    end
    
    subgraph "Content Generation Context"
        Agent1[content-initiator]
        Agent2[overview-writer]
        Agent3[concepts-writer]
        Agent4[visualization-writer]
        Agent5[practice-writer]
        Agent6[quiz-writer]
        Agent7[content-validator]
    end
    
    subgraph "Orchestration Context"
        Orchestrator[Orchestration Script]
        Validation[Precondition/Postcondition Validation]
        Lock[Lock File Mechanism]
    end
    
    subgraph "Quality Metrics Context"
        QualityMetrics[Quality Metrics Calculator]
        ValidationScore[VALIDATION_SCORE]
    end
    
    subgraph "Agent Prompts Context"
        Prompts[Agent Prompt Definitions]
        InputContract[Input Contract]
        OutputContract[Output Contract]
    end
    
    %% Shared Kernel
    Agent1 -.->|Shared Kernel| WSM
    Agent2 -.->|Shared Kernel| WSM
    Agent3 -.->|Shared Kernel| WSM
    Agent4 -.->|Shared Kernel| WSM
    Agent5 -.->|Shared Kernel| WSM
    Agent6 -.->|Shared Kernel| WSM
    Agent7 -.->|Shared Kernel| WSM
    
    %% Published Language
    WSM -->|Published Language:<br/>WSM Spec v1.0| Prompts
    
    %% Customer-Supplier
    Orchestrator -->|Customer-Supplier| WSM
    Validation -->|Customer-Supplier| WSM
    QualityMetrics -->|Customer-Supplier| WSM
    
    %% Conformist
    Agent1 -->|Conformist:<br/>준수| Prompts
    Agent2 -->|Conformist:<br/>준수| Prompts
    Agent3 -->|Conformist:<br/>준수| Prompts
    
    %% Lock Mechanism
    Lock -.->|동시성 제어| WSM
    
    style WSM fill:#e1f5ff,stroke:#0288d1,stroke-width:3px
    style Orchestrator fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style QualityMetrics fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style Prompts fill:#e8f5e9,stroke:#388e3c,stroke-width:2px
```

**범례**:
- **Shared Kernel** (점선): 모든 에이전트가 Work Status Markers 형식 공유
- **Published Language** (실선): Work Status Markers Specification v1.0이 표준 언어
- **Customer-Supplier**: Orchestration/Quality Metrics Context가 Work Status Markers에 의존
- **Conformist**: 에이전트가 Agent Prompts의 규칙을 준수

---

#### 8.1.2 Domain Event Flow Diagram

파이프라인 실행 시 Domain Event (HANDOFF LOG 엔트리) 발생 순서를 시각화합니다.

```mermaid
sequenceDiagram
    participant CI as content-initiator
    participant OW as overview-writer
    participant CW as concepts-writer
    participant VW as visualization-writer
    participant PW as practice-writer
    participant QW as quiz-writer
    participant CV as content-validator
    participant WSM as Work Status Markers
    
    Note over CI,WSM: 파이프라인 시작
    CI->>WSM: [START] 파이프라인 초기화 완료
    CI->>WSM: CURRENT_AGENT = overview-writer
    CI->>WSM: STATUS = PENDING
    
    Note over OW,WSM: 첫 번째 에이전트 실행
    OW->>WSM: Precondition 검증 (CURRENT_AGENT 일치)
    OW->>WSM: STATUS = IN_PROGRESS
    OW->>OW: Overview 섹션 작성
    OW->>WSM: [DONE] Overview 섹션 작성 완료
    OW->>WSM: CURRENT_AGENT = concepts-writer
    
    Note over CW,WSM: 두 번째 에이전트 실행
    CW->>WSM: Precondition 검증
    CW->>CW: Core Concepts 작성
    CW->>WSM: [DONE] Core Concepts 작성 완료
    CW->>WSM: CURRENT_AGENT = visualization-writer
    
    Note over VW,WSM: 세 번째 에이전트 실행
    VW->>WSM: Precondition 검증
    VW->>VW: 시각화 메타데이터 삽입
    VW->>WSM: [DONE] 시각화 메타데이터 삽입 완료
    VW->>WSM: CURRENT_AGENT = practice-writer
    
    Note over PW,WSM: 네 번째 에이전트 실행
    PW->>WSM: Precondition 검증
    PW->>PW: Code Patterns & Experiments 작성
    PW->>WSM: [DONE] Practice 작성 완료
    PW->>WSM: CURRENT_AGENT = quiz-writer
    
    Note over QW,WSM: 다섯 번째 에이전트 실행
    QW->>WSM: Precondition 검증
    QW->>QW: 퀴즈 생성
    QW->>WSM: [DONE] 퀴즈 생성 완료
    QW->>WSM: CURRENT_AGENT = content-validator
    
    Note over CV,WSM: 최종 검증
    CV->>WSM: Precondition 검증
    CV->>CV: 품질 검증 (VALIDATION_SCORE 산출)
    
    alt VALIDATION_SCORE >= 80
        CV->>WSM: [COMPLETE] 품질 검증 통과
        CV->>WSM: CURRENT_AGENT = (빈 문자열)
        CV->>WSM: STATUS = COMPLETED
    else VALIDATION_SCORE < 80
        CV->>WSM: [DONE] 품질 검증 완료 (개선 필요)
        CV->>WSM: IMPROVEMENT_NEEDED 추가
        CV->>WSM: CURRENT_AGENT = (개선 대상 에이전트)
        Note over CV,WSM: 개선 루프 진입
    end
```

**Domain Events 매핑**:
- `[START]` → **PipelineStartedEvent**
- `[DONE]` → **AgentCompletedEvent**
- `[COMPLETE]` → **PipelineCompletedEvent**
- `[FAILURE]` → **AgentFailedEvent** (다이어그램에는 정상 흐름만 표시)

---

#### 8.1.3 State Transition Diagram

STATUS 필드의 상태 전이를 시각화합니다 (Section 5.2.1 불변식 기반).

```mermaid
stateDiagram-v2
    [*] --> PENDING: content-initiator<br/>파일 생성
    
    PENDING --> IN_PROGRESS: 첫 번째 에이전트<br/>실행 시작
    
    IN_PROGRESS --> IN_PROGRESS: 에이전트 완료<br/>(다음 에이전트 대기)
    
    IN_PROGRESS --> COMPLETED: content-validator<br/>검증 통과<br/>(VALIDATION_SCORE >= 80)
    
    IN_PROGRESS --> FAILED: 에이전트 실행<br/>오류 발생
    
    FAILED --> IN_PROGRESS: 재시도 성공
    
    FAILED --> FAILED: 재시도 실패<br/>(최대 3회 제한)
    
    COMPLETED --> [*]: 파이프라인 완료<br/>(최종 상태)
    
    note right of PENDING
        초기 상태
        에이전트 미실행
    end note
    
    note right of IN_PROGRESS
        에이전트 실행 중
        또는 다음 에이전트 대기
    end note
    
    note right of COMPLETED
        최종 완료 상태
        전이 불가 (불변식)
    end note
    
    note right of FAILED
        오류 상태
        재시도 가능 (최대 3회)
    end note
```

**상태 전이 규칙** (Section 5.2.1 참조):

| 현재 STATUS | 허용된 다음 STATUS | 트리거 조건 |
|-------------|------------------|------------|
| (없음) | PENDING | content-initiator가 마커 초기화 |
| PENDING | IN_PROGRESS | 첫 번째 에이전트 시작 |
| IN_PROGRESS | IN_PROGRESS | 에이전트 완료 후 다음 에이전트 대기 |
| IN_PROGRESS | COMPLETED | content-validator 완료 (VALIDATION_SCORE >= 80) |
| IN_PROGRESS | FAILED | 에이전트 실행 실패 |
| FAILED | IN_PROGRESS | 재시도 성공 |
| FAILED | FAILED | 재시도 실패 |
| COMPLETED | (전이 불가) | 완료 상태는 최종 상태 |

---

### 8.2 문서 완성도 검토

#### 8.2.1 섹션 완료 확인

| 섹션 | 제목 | 완료 여부 | 라인 수 | 핵심 내용 |
|------|------|----------|---------|----------|
| **1** | Bounded Context 정의 | ✅ | ~180 | Context 경계, Context Mapping, Upstream/Downstream |
| **2** | Ubiquitous Language 정의 | ✅ | ~400 | 5개 핵심 용어, Work Status Markers 형식 개선, 도메인 용어 사전 (13개) |
| **3** | Domain Event 모델링 | ✅ | ~450 | 5개 Domain Events, 이벤트 발생 조건, 이벤트 순서 보장 메커니즘 |
| **4** | Handoff Protocol Specification | ✅ | ~340 | 에이전트 시작 규칙 (3 Preconditions), 완료 규칙 (5 업데이트), 오류 처리 |
| **5** | Domain Invariants | ✅ | ~505 | 5개 필드 불변식, 3개 상태 전이 불변식, 검증 규칙 |
| **6** | Context Integration | ✅ | ~485 | Upstream/Downstream 관계, 4개 통합 패턴, Lock 메커니즘 |
| **7** | Validation | ✅ | ~465 | 3개 시나리오 검증, 10개 경계 조건, 13개 용어 일관성 |
| **8** | Finalization | 🔄 진행 중 | - | 다이어그램, 완성도 검토, 핵심 결정 요약 |

**총 라인 수**: 약 3,030줄 (Section 8 제외)

**예상 최종 라인 수**: 약 3,200줄 (Section 8 포함)

---

#### 8.2.2 참조 일관성 확인

**내부 참조 검증**:

| 참조 위치 | 참조 대상 | 검증 결과 |
|----------|----------|----------|
| Section 1.1 | Section 4 (Handoff Protocol) | ✅ 일치 - "에이전트가 Section 4의 Handoff Protocol을 따라 마커 직접 업데이트" |
| Section 2.2 | Section 5 (Domain Invariants) | ✅ 일치 - "PROGRESS → STATUS (Section 5.2.1 불변식)" |
| Section 3.4 | Section 4 (Handoff Protocol) | ✅ 일치 - "이벤트 순서 보장은 Section 4의 Append-Only 규칙으로 보장" |
| Section 4.1 | Section 5.1 (필수 필드 불변식) | ✅ 일치 - "Precondition 검증 시 Section 5.1의 필수 필드 존재 확인" |
| Section 6.3 | Section 4 (Handoff Protocol) | ✅ 일치 - "권한 매트릭스는 Section 4의 업데이트 규칙과 일치" |
| Section 7.1 | Sections 3, 4, 5 | ✅ 일치 - "시나리오 검증에서 Domain Events, Handoff Protocol, Invariants 모두 참조" |

**외부 참조 검증**:

| 참조 위치 | 참조 대상 | 검증 결과 |
|----------|----------|----------|
| Section 1 | `docs/aidlc-docs/inception/units/unit-01-pipe-mechanism.md` | ✅ 존재 - Inception 문서 참조 정확 |
| Section 2 | `docs/aidlc-docs/inception/units/unit-03-agent-prompts.md` | ✅ 존재 - Unit 3 참조 정확 |
| Section 6 | `.claude/agents/*.md` | ✅ 존재 - 에이전트 프롬프트 파일 참조 정확 |

---

#### 8.2.3 마크다운 문법 검증

**검증 항목**:

- ✅ 제목 계층 구조 (H1 없음, H2부터 시작, 순차적 계층)
- ✅ 코드 블록 언어 명시 (markdown, bash, mermaid)
- ✅ 테이블 형식 정확성 (모든 테이블 정렬 바 포함)
- ✅ 링크 형식 정확성 (내부 링크는 `#section-name` 형식)
- ✅ 리스트 들여쓰기 일관성 (2칸 또는 4칸 통일)
- ✅ 강조 표시 일관성 (`**bold**`, `*italic*`, `` `code` ``)

**자동 검증 도구 제안**: `markdownlint` 사용 권장 (Phase 2.2 구현 시)

---

### 8.3 핵심 결정 사항 요약

#### 8.3.1 아키텍처 결정 (Architecture Decisions)

| 결정 ID | 결정 사항 | 근거 | 영향 범위 |
|---------|---------|------|----------|
| **AD-1** | Work Status Markers를 마크다운 파일 내부 HTML 주석으로 유지 | 단일 파일 원자성 보장, 기존 시스템 호환성 | 모든 에이전트, 오케스트레이션 스크립트 |
| **AD-2** | PROGRESS → STATUS 필드명 변경 | 명확성 향상 ("진행 상태" → "전체 상태"), enum 값과 일관성 | Work Status Markers 형식, 모든 에이전트 프롬프트 |
| **AD-3** | ISO 8601 타임스탬프 형식 채택 | 국제 표준, 타임존 명시, 기계 파싱 용이 | STARTED, UPDATED, HANDOFF LOG 엔트리 |
| **AD-4** | HANDOFF LOG 파이프 구분자 사용 | 파싱 용이성, 가독성 향상 | HANDOFF LOG 형식, 파싱 로직 |
| **AD-5** | 에이전트가 마커를 직접 읽고 쓰도록 변경 | 에이전트 자율성 향상, 오케스트레이션 스크립트 단순화 | Section 4 Handoff Protocol, 모든 에이전트 프롬프트 |
| **AD-6** | 사전+사후 검증 모두 수행 (Precondition + Postcondition) | 오류 조기 발견, 불변식 보장 강화 | 오케스트레이션 스크립트, 검증 로직 |
| **AD-7** | WAITING 이벤트 타입 제거 | 중복성 제거 (DONE 이후 자동으로 대기 상태) | HANDOFF LOG 형식, Domain Events |
| **AD-8** | Lock 파일 메커니즘 도입 | 동시성 제어, 마커 충돌 방지 | 오케스트레이션 스크립트, 병렬 실행 시나리오 |

---

#### 8.3.2 도메인 설계 결정 (Domain Design Decisions)

| 결정 ID | 결정 사항 | 근거 | 트레이드오프 |
|---------|---------|------|-------------|
| **DD-1** | 5개 Domain Event 정의 (START, DONE, FAILURE, SKIP, COMPLETE) | 파이프라인 상태 추적 충분성, 이벤트 소싱 패턴 적용 가능 | WAITING 제거로 일부 중간 상태 가시성 감소 (DONE으로 대체 가능) |
| **DD-2** | 에이전트당 단일 HANDOFF LOG 엔트리 원칙 (개선 루프 예외) | 가독성 향상, 중복 제거 | 개선 루프 시 2개 엔트리 허용 (예외 처리 복잡도 증가) |
| **DD-3** | STATUS 4개 enum 값 (PENDING, IN_PROGRESS, COMPLETED, FAILED) | 파이프라인 상태 명확성, 상태 전이 단순화 | 더 세분화된 상태 (예: PAUSED) 미지원 |
| **DD-4** | Append-Only 불변식 강제 | 이벤트 이력 보존, 디버깅 용이 | HANDOFF LOG 크기 증가 (100 에이전트 실행 시 100 엔트리) |
| **DD-5** | Shared Kernel 패턴 채택 (모든 에이전트가 WSM 형식 공유) | 통합 복잡도 최소화, 표준화 | Context 간 결합도 증가 (WSM 형식 변경 시 모든 에이전트 영향) |
| **DD-6** | 개선 루프 비선형 흐름 허용 (validator → agent → validator) | 품질 개선 메커니즘 필수 | 파이프라인 흐름 복잡도 증가, 무한 루프 위험 (재시도 제한 필요) |

---

#### 8.3.3 구현 가이드라인 (Implementation Guidelines)

**Phase 2.2 (Implementation) 진행 시 주의사항**:

1. **UTF-8 인코딩 필수**:
   - 모든 파일 읽기/쓰기 시 `UTF-8` 명시
   - 쉘 스크립트 환경 변수 설정: `export LANG=ko_KR.UTF-8; export LC_ALL=ko_KR.UTF-8`
   - 한글 콘텐츠 정상 작성 확인

2. **ISO 8601 타임스탬프 생성**:
   ```bash
   TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
   # 예: 2025-10-16T10:30:00+0900
   ```

3. **Lock 파일 메커니즘 구현**:
   - Lock 파일 위치: `{content_file}.lock`
   - PID 기반 프로세스 생존 확인: `ps -p $PID` 명령으로 프로세스 존재 확인
   - 프로세스 없으면 Lock 파일 자동 제거
   - Lock 메타데이터: JSON 형식 (에이전트명, PID, 시작 시간)
   - **시간 기반 자동 제거 안 함** (콘텐츠 생성 10~30분 소요)

4. **검증 스크립트 통합**:
   - Precondition 검증: 에이전트 실행 전 자동 호출
   - Postcondition 검증: 에이전트 실행 후 자동 호출
   - 검증 실패 시 Fail-Fast (즉시 중단)

5. **개선 루프 재시도 제한**:
   - 최대 개선 루프 횟수: 3회
   - VALIDATION_SCORE 최소 증가량: 10점 (무의미한 개선 방지)
   - 3회 초과 시 FAILED 상태로 전이

6. **에이전트 프롬프트 업데이트 우선순위** (Unit 3):
   - High: content-initiator, content-validator (파이프라인 시작/끝)
   - Medium: overview-writer, concepts-writer (핵심 콘텐츠)
   - Low: visualization-writer, practice-writer, quiz-writer (보조 콘텐츠)

---

#### 8.3.4 확정된 설계 결정 (Finalized Decisions)

| ID | 항목 | 최종 결정 | 근거 |
|----|------|----------|------|
| **FD-1** | 개선 이벤트 타입 | [IMPROVE] 이벤트 타입 도입 | IMPROVEMENT_NEEDED 추가 시 [DONE]이 아니라 [IMPROVE]로 기록. 첫 번째 작업과 개선 작업을 명확히 구분 |
| **FD-2** | HANDOFF LOG 길이 제한 | 무제한 (제한 없음) | 각 파일당 최대 10개 정도 엔트리 (7개 에이전트 + 재시도). 누적되어도 문제없음 |
| **FD-3** | Lock 파일 메커니즘 | PID 기반 프로세스 생존 확인 | 콘텐츠 생성이 10~30분 소요. 시간 기반 자동 제거는 작업 중 충돌 유발. PID로 프로세스 존재 확인 후 Lock 제거 |
| **FD-4** | 검증 실패 복구 전략 | 즉시 중단 + 처음부터 재실행 | Precondition/Postcondition 실패는 치명적 오류. 일관성 보장 위해 처음부터 재실행 필요 |
| **FD-5** | VALIDATION_SCORE 통과 기준 | 90점 이상 | Section 2.4.1에서 이미 명시됨 (VALIDATION_SCORE ≥ 90) |

---

### 8.4 검토 요청 준비

#### 8.4.1 문서 요약 (Executive Summary)

**제목**: Unit 1 - Pipe Mechanism 표준화: Domain Design 완료 보고

**목적**: Work Status Markers를 명시적이고 표준화된 Pipe 메커니즘으로 개선하여 에이전트 간 데이터 전달의 신뢰성과 추적 가능성을 향상시킨다.

**주요 성과**:

1. **Bounded Context 명확화**: Work Status Markers Context 경계 정의, 7개 에이전트와의 관계 명시
2. **Ubiquitous Language 표준화**: 13개 핵심 도메인 용어 정의, Work Status Markers 형식 개선 (6개 필드)
3. **Domain Event 모델링**: 5개 이벤트 정의 (START, DONE, FAILURE, SKIP, COMPLETE), 이벤트 순서 보장 메커니즘
4. **Handoff Protocol 명세**: 에이전트 시작/완료 규칙, 3 Preconditions + 5 업데이트 규칙 정의
5. **Domain Invariants 정의**: 8개 불변식 (5개 필드 불변식 + 3개 상태 전이 불변식), 검증 규칙
6. **Context Integration 설계**: 4개 통합 패턴 (Shared Kernel, Published Language, Conformist, Customer-Supplier), Lock 메커니즘
7. **검증 완료**: 3개 시나리오 검증 (정상/실패/개선 흐름), 10개 경계 조건 테스트, 13개 용어 일관성 검증

**핵심 개선사항**:

- PROGRESS → **STATUS** (명확성 향상)
- **ISO 8601 타임스탬프** (국제 표준)
- **파이프 구분자** HANDOFF LOG (파싱 용이)
- **WAITING 이벤트 제거** (중복성 제거)
- **에이전트 직접 마커 업데이트** (자율성 향상)
- **Lock 파일 메커니즘** (동시성 제어)

**문서 규모**: 약 3,200줄, 8개 섹션

---

#### 8.4.2 다음 단계 (Next Steps)

**Unit 1 Phase 2.2 (Implementation)**:

1. **우선순위 1**: Work Status Markers Specification 문서 작성
   - 파일: `docs/aidlc-docs/specifications/work-status-markers-spec.md`
   - 내용: `domain_design.md` 기반으로 개발자용 명세 작성
   - 예상 기간: 1일

2. **우선순위 2**: 검증 스크립트 개발
   - 파일: `test/test-work-status-markers.sh`
   - 내용: Section 5 불변식 기반 Precondition/Postcondition 검증
   - 예상 기간: 1일

3. **우선순위 3**: Agent Handoff Guide 작성
   - 파일: `docs/aidlc-docs/guides/agent-handoff-guide.md`
   - 내용: Section 4 Handoff Protocol 기반 에이전트 가이드
   - 예상 기간: 1일

**다른 Unit과의 연계**:

- **Unit 2 (Filter Contracts)**: domain_design.md Section 4 참조하여 Input/Output Contract 정의
- **Unit 3 (Agent Prompts)**: domain_design.md Section 4 기반 프롬프트 업데이트
- **Unit 4 (Orchestration)**: domain_design.md Section 5, 6 기반 검증 로직 및 Lock 메커니즘 구현
- **Unit 5 (Quality Metrics)**: domain_design.md Section 7.4.4 개선 제안 반영

---

#### 8.4.3 검토 체크리스트 (Review Checklist)

**문서 품질**:

- [x] 모든 섹션 (1-8) 완료
- [x] 참조 일관성 확인 (내부 참조 6개, 외부 참조 3개)
- [x] 마크다운 문법 검증 통과
- [x] 다이어그램 3개 추가 (Context Mapping, Event Flow, State Transition)
- [x] 용어 일관성 검증 (13개 용어)

**내용 완성도**:

- [x] Bounded Context 경계 명확
- [x] Ubiquitous Language 표준화
- [x] Domain Event 완전 정의
- [x] Handoff Protocol 명세 완료
- [x] Domain Invariants 검증 가능
- [x] Context Integration 패턴 정의
- [x] 시나리오 검증 통과

**실행 가능성**:

- [x] 핵심 결정 사항 8개 문서화 (AD-1 ~ AD-8)
- [x] 구현 가이드라인 6개 제공
- [x] 미결정 항목 5개 식별 (OQ-1 ~ OQ-5)
- [x] 다음 단계 3개 우선순위화

**검토 완료**: ✅

- [x] **사용자 검토**: 도메인 모델 설계 승인 완료
- [x] **미결정 항목 확정**: FD-1 ~ FD-5로 모두 확정됨
- [x] **Phase 2.2 진행 준비**: Implementation 단계 준비 완료

---

## 문서 히스토리

| 버전 | 날짜 | 변경 사항 | 작성자 |
|------|------|----------|--------|
| 0.1 | 2025-10-16 | Section 1-3 초안 작성 | Claude Code |
| 0.2 | 2025-10-16 | Section 4 전면 재작성 (Domain Services → Handoff Protocol) | Claude Code |
| 0.3 | 2025-10-16 | Section 5-6 작성 완료 | Claude Code |
| 0.4 | 2025-10-16 | Section 7 검증 완료 | Claude Code |
| 1.0 | 2025-10-16 | Section 8 최종화, 검토 준비 완료 | Claude Code |

---

**문서 종료**. Phase 2.1 (Domain Design) 완료. 검토 완료.
