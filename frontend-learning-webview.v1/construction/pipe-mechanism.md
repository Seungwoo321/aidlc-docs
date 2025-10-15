# Pipe 메커니즘 설계

**작성일**: 2025-10-13
**버전**: 1.0.0
**목적**: Work Status Markers 기반 Filter 간 데이터 전달 메커니즘 표준화

---

## 1. 개요

### 1.1 Pipe 메커니즘이란?

**Pipe**: Filter 간 데이터 전달 통로
- **물리적 구현**: 마크다운 파일 (`.md`)
- **제어 메커니즘**: Work Status Markers (HTML 주석)
- **데이터 흐름**: Filter A 출력 → 파일 → Filter B 입력

### 1.2 설계 원칙

1. **단순성**: 파일 기반, 순차 처리
2. **명시성**: 모든 상태를 Work Status Markers에 기록
3. **자율성**: 각 Filter가 마커를 보고 독립적으로 판단
4. **추적성**: HANDOFF LOG로 전체 작업 이력 기록
5. **재시작 가능성**: 마지막 완료 지점부터 재시작 가능

---

## 2. Work Status Markers 표준

### 2.1 마커 위치

**파일 구조**:
```markdown
---
[Frontmatter]
---

<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: [agent-name] -->
<!-- PROGRESS: [status] -->
<!-- VALIDATION_SCORE: [score]/100 -->
<!-- IMPROVEMENT_NEEDED:
  - [agent]: [issue] (-[points]점)
-->
<!-- STARTED: [YYYY-MM-DD HH:MM] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[log entries]
-->

[Content sections]
```

**위치 규칙**:
- ✅ Frontmatter 바로 다음 (line 3~)
- ✅ 파일 최상단 (콘텐츠 이전)
- ❌ 파일 중간이나 끝

### 2.2 필수 마커 (6개)

#### (1) CURRENT_AGENT
```markdown
<!-- CURRENT_AGENT: [agent-name] -->
```
- **의미**: 현재 작업 대상 Filter
- **값**: Filter 이름 (kebab-case) 또는 빈 문자열 (완료 시)
- **예시**: `overview-writer`, `concepts-writer`, ` ` (완료)

#### (2) PROGRESS
```markdown
<!-- PROGRESS: [status] -->
```
- **의미**: 현재 작업 진행 상태
- **값**: `대기중` | `진행중` | `완료`
- **예시**: `대기중` (다음 Filter 대기), `진행중` (작업 중), `완료` (모든 작업 완료)

#### (3) STARTED
```markdown
<!-- STARTED: [YYYY-MM-DD HH:MM] -->
```
- **의미**: 최초 작업 시작 시간 (Pipeline 시작)
- **값**: ISO 8601 형식 (YYYY-MM-DD HH:MM)
- **불변성**: 한 번 설정 후 변경 금지

#### (4) UPDATED
```markdown
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
```
- **의미**: 마지막 마커 업데이트 시간
- **값**: ISO 8601 형식 (YYYY-MM-DD HH:MM)
- **갱신**: Filter가 작업 완료 시마다 업데이트

#### (5) HANDOFF LOG
```markdown
<!-- HANDOFF LOG:
[STATUS] filter-name: message - [timestamp or details]
[STATUS] filter-name: message - [timestamp or details]
...
-->
```
- **의미**: Filter별 작업 이력 기록
- **형식**: 각 줄은 `[STATUS] filter: message - details`
- **누적**: 새로운 항목을 끝에 추가 (기존 항목 유지)

**STATUS 종류**:
- `[START]`: 작업 시작 (content-initiator only)
- `[WAITING]`: 작업 대기 시작
- `[DONE]`: 작업 완료
- `[SKIP]`: 작업 건너뛰기
- `[FAIL]`: 작업 실패
- `[IMPROVE]`: 개선 작업 완료
- `[INFO]`: 다음 Filter를 위한 정보
- `[COMPLETE]`: 최종 완료 (content-validator only)

#### (6) 선택 마커

**VALIDATION_SCORE** (content-validator only):
```markdown
<!-- VALIDATION_SCORE: [score]/100 -->
```
- **의미**: 콘텐츠 품질 점수
- **값**: 0-100 정수
- **사용**: content-validator가 점수 산정 후 기록

**IMPROVEMENT_NEEDED** (content-validator only):
```markdown
<!-- IMPROVEMENT_NEEDED:
  - [agent-name]: [specific issue] (-[points]점)
  - [agent-name]: [specific issue] (-[points]점)
-->
```
- **의미**: 개선이 필요한 사항 목록
- **형식**: 각 줄은 `- agent: issue (-points점)`
- **우선순위**: 점수 차감 큰 것부터 나열

---

## 3. 데이터 전달 프로토콜

### 3.1 마크다운 파일 구조

```markdown
[Line 1-2] Frontmatter
---
---

[Line 3-N] Work Status Markers
<!-- WORK STATUS MARKERS -->
...

[Line N+1~] Content Sections
# Overview
...
# Core Concepts
...
# Code Patterns
...
# Experiments
...
# Quiz
...
```

### 3.2 Filter 간 데이터 흐름

```
┌─────────────────┐
│ Filter A        │
│ (작업 완료)     │
└────────┬────────┘
         │ 1. 섹션 작성
         │ 2. Work Status Markers 업데이트
         │    - CURRENT_AGENT: filter-b
         │    - PROGRESS: 대기중
         │    - HANDOFF LOG 추가
         v
┌─────────────────┐
│ Markdown File   │ (Pipe)
│ - Markers       │
│ - Content       │
└────────┬────────┘
         │ 3. 파일 읽기
         v
┌─────────────────┐
│ Filter B        │
│ (작업 시작)     │
│ 1. CURRENT_AGENT 확인
│ 2. 이전 섹션 읽기
│ 3. 새 섹션 작성
└─────────────────┘
```

### 3.3 Filter 읽기/쓰기 권한

| Filter | 읽기 권한 | 쓰기 권한 | Work Status Markers 업데이트 |
|--------|----------|----------|---------------------------|
| content-initiator | - | Frontmatter (생성) | 초기화 (모든 마커 생성) |
| overview-writer | Frontmatter, Markers | # Overview | CURRENT_AGENT, UPDATED, HANDOFF LOG |
| concepts-writer | Overview | # Core Concepts | 동일 |
| visualization-writer | Core Concepts (Viz 메타데이터) | React 컴포넌트 파일 (.tsx) | 동일 |
| practice-writer | Overview, Core Concepts | # Code Patterns, # Experiments | 동일 |
| quiz-writer | 모든 학습 섹션 | # Quiz | 동일 |
| content-validator | 모든 섹션 | Work Status Markers only | 모든 마커 (VALIDATION_SCORE, IMPROVEMENT_NEEDED 추가) |

**원칙**:
- ✅ 각 Filter는 자신이 담당한 섹션만 쓰기
- ✅ 이전 Filter의 출력은 읽기 only
- ✅ Work Status Markers는 모든 Filter가 업데이트 (자신의 작업 이력 추가)
- ❌ 다른 Filter의 섹션 수정 금지

---

## 4. 상태 관리 메커니즘

### 4.1 작업 진행 상태 정의

```
[대기중] → [진행중] → [대기중] (다음 Filter) → ... → [완료]
```

| 상태 | 의미 | CURRENT_AGENT | PROGRESS |
|------|------|--------------|---------|
| 대기중 | 특정 Filter가 작업 시작 대기 | Filter 이름 | 대기중 |
| 진행중 | 특정 Filter가 작업 중 | Filter 이름 | 진행중 |
| 완료 | 모든 Filter 작업 완료 | (빈 문자열) | 완료 |

### 4.2 재시작 지점 결정 알고리즘

**알고리즘**:
```
1. Work Status Markers 읽기
2. CURRENT_AGENT 확인
3. 조건 판단:
   - CURRENT_AGENT == (빈 문자열) AND PROGRESS == 완료
     → 작업 완료, 재시작 불필요

   - CURRENT_AGENT == [agent-name] AND PROGRESS == 대기중
     → 해당 Filter부터 재시작

   - CURRENT_AGENT == [agent-name] AND PROGRESS == 진행중
     → 해당 Filter 재시작 (이전 작업 덮어쓰기)

   - IMPROVEMENT_NEEDED 존재
     → CURRENT_AGENT Filter부터 재시작 (개선 모드)
```

**예시**:
```markdown
<!-- CURRENT_AGENT: practice-writer -->
<!-- PROGRESS: 대기중 -->
<!-- HANDOFF LOG:
[DONE] overview-writer: 완료
[DONE] concepts-writer: 완료
[DONE] visualization-writer: 완료
-->
```
→ **재시작 지점**: practice-writer

### 4.3 실패 처리 프로토콜

**실패 감지**:
- Filter가 예외 발생 시 `[FAIL]` 로그 기록
- PROGRESS는 `진행중` 유지 (재시도 필요)

**실패 기록**:
```markdown
<!-- HANDOFF LOG:
[WAITING] practice-writer: 진행중 - [timestamp]
[FAIL] practice-writer: 실패 - Parser test failed (test-patterns.mjs)
-->
```

**재시도 전략**:
1. 오케스트레이션 스크립트가 `[FAIL]` 감지
2. 동일한 Filter 재실행 (최대 3회)
3. 3회 실패 시 수동 개입 필요

---

## 5. Pipeline 흐름 상세

### 5.1 전체 Pipeline 흐름

```
START
  ↓
content-initiator (초기화)
  ↓ Work Status Markers 생성
overview-writer (대기중)
  ↓ Overview 작성 → HANDOFF LOG 추가 → CURRENT_AGENT: concepts-writer
concepts-writer (대기중)
  ↓ Core Concepts 작성 → Viz 메타데이터 생성 → CURRENT_AGENT: visualization-writer
visualization-writer (대기중)
  ↓ React 컴포넌트 생성 → index.ts export → CURRENT_AGENT: practice-writer
practice-writer (대기중)
  ↓ Code Patterns + Experiments → CURRENT_AGENT: quiz-writer
quiz-writer (대기중)
  ↓ Quiz 섹션 작성 → CURRENT_AGENT: content-validator
content-validator (대기중)
  ↓ 품질 검증 (100점 만점)
  ├─ 100점: CURRENT_AGENT: (빈), PROGRESS: 완료 → [COMPLETE]
  └─ < 100점: IMPROVEMENT_NEEDED 생성 → CURRENT_AGENT: [first-improvement-agent]
     ↓ 개선 작업
     ↓ 재검증...
     └─ 100점 달성 → [COMPLETE]
END
```

### 5.2 각 Filter별 마커 업데이트 예시

#### content-initiator (초기화)
**Before**: (파일 없음)

**After**:
```markdown
---
---

<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: overview-writer -->
<!-- PROGRESS: 대기중 -->
<!-- STARTED: 2025-10-13 14:30 -->
<!-- UPDATED: 2025-10-13 14:30 -->
<!-- HANDOFF LOG:
[START] content-initiator: started - initialization
-->
```

#### overview-writer (작업 완료)
**Before**: content-initiator 마커

**After**:
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: concepts-writer -->
<!-- PROGRESS: 대기중 -->
<!-- STARTED: 2025-10-13 14:30 -->
<!-- UPDATED: 2025-10-13 14:35 -->
<!-- HANDOFF LOG:
[START] content-initiator: started - initialization
[WAITING] overview-writer: 진행중 - 2025-10-13 14:32
[DONE] overview-writer: 완료 - 2025-10-13 14:35
[WAITING] concepts-writer: 대기중 - 2025-10-13 14:35
-->

# Overview
[content]
```

#### content-validator (100점)
**Before**: quiz-writer 마커

**After**:
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: -->
<!-- PROGRESS: 완료 -->
<!-- VALIDATION_SCORE: 100/100 -->
<!-- STARTED: 2025-10-13 14:30 -->
<!-- UPDATED: 2025-10-13 15:30 -->
<!-- HANDOFF LOG:
[START] content-initiator: started - initialization
[DONE] overview-writer: 완료 - 2025-10-13 14:35
[DONE] concepts-writer: 완료 - 2025-10-13 14:50
[DONE] visualization-writer: 완료 - VarScopeVisualization 생성
[DONE] practice-writer: 완료 - 2025-10-13 15:15
[DONE] quiz-writer: 완료 - 2025-10-13 15:25
[DONE] content-validator: 검증 완료 - 100점
[COMPLETE] 최종 완료 - 완벽한 콘텐츠 생성
-->
```

#### content-validator (95점, 개선 필요)
**After**:
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: concepts-writer -->
<!-- PROGRESS: 대기중 -->
<!-- VALIDATION_SCORE: 95/100 -->
<!-- IMPROVEMENT_NEEDED:
  - concepts-writer: Add explanation for "heap" term in Expert section (-3점)
  - quiz-writer: Improve difficulty distribution (-2점)
-->
<!-- STARTED: 2025-10-13 14:30 -->
<!-- UPDATED: 2025-10-13 15:30 -->
<!-- HANDOFF LOG:
[START] content-initiator: started - initialization
[DONE] overview-writer: 완료 - 2025-10-13 14:35
[DONE] concepts-writer: 완료 - 2025-10-13 14:50
[DONE] visualization-writer: 완료 - VarScopeVisualization 생성
[DONE] practice-writer: 완료 - 2025-10-13 15:15
[DONE] quiz-writer: 완료 - 2025-10-13 15:25
[DONE] content-validator: 검증 완료 - 95점 (개선 필요)
[WAITING] concepts-writer: 대기중 - 2025-10-13 15:30
-->
```

---

## 6. 특수 시나리오

### 6.1 Visualization 건너뛰기

**상황**: 시각화가 필요 없는 토픽

**concepts-writer 출력**:
```markdown
<!-- HANDOFF LOG:
[DONE] concepts-writer: 완료 - 2025-10-13 14:50
[INFO] VISUALIZATION: 이 토픽에는 시각화가 필요하지 않음
-->
```

**visualization-writer 처리**:
```markdown
<!-- HANDOFF LOG:
[DONE] concepts-writer: 완료 - 2025-10-13 14:50
[INFO] VISUALIZATION: 이 토픽에는 시각화가 필요하지 않음
[SKIP] visualization-writer: 건너뛰기 - 2025-10-13 14:51
[WAITING] practice-writer: 대기중 - 2025-10-13 14:51
-->
```

### 6.2 Filter 작업 실패

**상황**: practice-writer가 Parser 테스트 실패

**HANDOFF LOG**:
```markdown
[WAITING] practice-writer: 진행중 - 2025-10-13 15:05
[FAIL] practice-writer: 실패 - Parser test failed (Pattern 필수 필드 누락)
```

**재시도**:
- PROGRESS: `진행중` 유지
- 오케스트레이션 스크립트가 practice-writer 재실행

### 6.3 개선 모드 (Improvement Cycle)

**1차 완료 (95점)**:
```markdown
<!-- VALIDATION_SCORE: 95/100 -->
<!-- IMPROVEMENT_NEEDED:
  - concepts-writer: Add explanation (-3점)
  - quiz-writer: Fix distribution (-2점)
-->
<!-- CURRENT_AGENT: concepts-writer -->
```

**concepts-writer 개선 완료**:
```markdown
<!-- IMPROVEMENT_NEEDED:
  - quiz-writer: Fix distribution (-2점)
-->
<!-- HANDOFF LOG:
[IMPROVE] concepts-writer: 개선 완료 - Explanation added
[WAITING] quiz-writer: 대기중 - 2025-10-13 15:40
-->
<!-- CURRENT_AGENT: quiz-writer -->
```

**quiz-writer 개선 완료**:
```markdown
<!-- IMPROVEMENT_NEEDED: -->
<!-- HANDOFF LOG:
[IMPROVE] concepts-writer: 개선 완료 - Explanation added
[IMPROVE] quiz-writer: 개선 완료 - Distribution fixed
[WAITING] content-validator: 대기중 - 2025-10-13 15:45
-->
<!-- CURRENT_AGENT: content-validator -->
```

**재검증 (100점)**:
```markdown
<!-- VALIDATION_SCORE: 100/100 -->
<!-- IMPROVEMENT_NEEDED: -->
<!-- CURRENT_AGENT: -->
<!-- PROGRESS: 완료 -->
<!-- HANDOFF LOG:
[IMPROVE] concepts-writer: 개선 완료
[IMPROVE] quiz-writer: 개선 완료
[DONE] content-validator: 검증 완료 - 100점
[COMPLETE] 최종 완료
-->
```

---

## 7. 확장성 고려사항

### 7.1 새로운 Filter 추가

**요구사항**:
1. Filter 계약 문서 작성 (Unit 1 템플릿)
2. Work Status Markers 업데이트 프로토콜 준수
3. HANDOFF LOG 형식 준수

**Pipeline 통합**:
```
기존: A → B → C
추가: A → B → [NEW] → C
```

**마커 업데이트**:
- Filter B: `CURRENT_AGENT: new-filter`
- NEW Filter: 작업 후 `CURRENT_AGENT: filter-c`

### 7.2 조건부 Filter 실행

**현재 지원**: SKIP 메커니즘 (visualization-writer)

**향후 확장**:
```markdown
<!-- EXECUTION_CONDITIONS:
  - filter-name: skip_if [condition]
  - filter-name: run_if [condition]
-->
```

**예시**:
```markdown
<!-- EXECUTION_CONDITIONS:
  - visualization-writer: skip_if "no_viz_metadata"
  - advanced-concepts-writer: run_if "difficulty >= 4"
-->
```

### 7.3 병렬 처리 가능성

**현재**: 순차 처리만 지원 (파일 기반 한계)

**향후 고려사항**:
- 독립적 Filter 식별 (입력이 겹치지 않는 경우)
- 파일 잠금 메커니즘 (동시 쓰기 방지)
- 병렬 실행 마커:
  ```markdown
  <!-- PARALLEL_GROUP: group-1 -->
  ```

**제약**:
- 현재 시스템은 단순성을 위해 순차 처리 유지
- 병렬 처리는 복잡도 증가 → 장기 고려사항

---

## 8. 오케스트레이션 스크립트 역할

### 8.1 스크립트 책임

**현재 스크립트**: `scripts/content-generator-v6.sh`

**책임**:
1. **Filter 순차 실행**
   - 7개 Filter를 순서대로 실행
   - 각 Filter에 파일 경로 전달

2. **재시도 로직**
   - content-validator 점수 확인
   - 100점 미만 시 재시도 (최대 3회)

3. **실패 감지**
   - `[FAIL]` 로그 감지
   - 해당 Filter 재실행

4. **락 파일 관리**
   - 동시 실행 방지
   - 작업 완료 후 락 해제

### 8.2 Filter 자율성

**Filter의 책임**:
- ✅ `CURRENT_AGENT` 확인하여 본인 차례 판단
- ✅ `IMPROVEMENT_NEEDED` 확인하여 개선 사항 처리
- ✅ 작업 완료 후 Work Status Markers 업데이트
- ❌ 다른 Filter 호출 (스크립트 담당)

**분리 원칙**:
- 스크립트: 순서 제어, 재시도, 실패 감지
- Filter: 콘텐츠 생성, 마커 업데이트

---

## 9. 검증 체크리스트

### 9.1 Work Status Markers 검증
- [ ] 6개 필수 마커 모두 존재 (CURRENT_AGENT, PROGRESS, STARTED, UPDATED, HANDOFF LOG, + 선택 2개)
- [ ] 마커 형식 정확 (HTML 주석, 대문자 키워드)
- [ ] HANDOFF LOG에 모든 Filter 작업 이력 기록
- [ ] STARTED 불변, UPDATED 갱신
- [ ] CURRENT_AGENT가 다음 Filter 이름 또는 빈 문자열

### 9.2 데이터 흐름 검증
- [ ] Filter N의 출력 섹션이 파일에 존재
- [ ] Filter N+1이 Filter N의 출력을 읽을 수 있음
- [ ] 섹션별 읽기/쓰기 권한 준수
- [ ] 다른 Filter의 섹션 수정하지 않음

### 9.3 상태 관리 검증
- [ ] PROGRESS가 올바른 값 (`대기중`, `진행중`, `완료`)
- [ ] 재시작 지점 정확히 결정 가능
- [ ] 실패 시 `[FAIL]` 로그 기록
- [ ] 개선 모드 시 IMPROVEMENT_NEEDED 올바르게 처리

---

## 10. 참고 문서

- `docs/aidlc-docs/construction/filter-contracts-summary.md` (Filter I/O 관계)
- `docs/aidlc-docs/construction/filters/*.md` (각 Filter 계약)
- `.claude/handoff-guide.md` (현재 핸드오프 가이드)
- `scripts/content-generator-v6.sh` (오케스트레이션 스크립트)

---

**작성 완료**: 2025-10-13
**적용 대상**: Unit 3 (에이전트 프롬프트), Unit 4 (오케스트레이션 스크립트)
