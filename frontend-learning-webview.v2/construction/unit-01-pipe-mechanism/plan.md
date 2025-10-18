# Unit 1: Pipe Mechanism 표준화 - Construction Phase 계획

## 프로젝트 개요

**목표**: Work Status Markers를 명시적이고 표준화된 Pipe 메커니즘으로 개선

**단계**: Phase 2.1 - DDD 경량화 방식으로 도메인 모델 설계

**참조 문서**: `docs/aidlc-docs/inception/units/unit-01-pipe-mechanism.md`

---

## Phase 2.1: DDD 도메인 모델 설계

### ✅ Step 0: 준비 작업

- [x] **Step 0.1**: Unit 1 Inception 문서 분석
  - 목적, 범위, 아키텍처 컨텍스트 이해
  - 결정 사항 확인 (마커 저장 위치, 타임스탬프 형식, 검증 수준)

- [x] **Step 0.2**: Construction 폴더 구조 생성
  - `docs/aidlc-docs/construction/unit-01-pipe-mechanism/` 생성

- [x] **Step 0.3**: 현재 시스템 분석
  - `scripts/content-generator-v6.sh`의 마커 사용 현황 분석 완료
  - 실제 콘텐츠 파일의 마커 구조 확인 완료

---

### ✅ Step 1: Bounded Context 정의

- [x] **Step 1.1**: Work Status Markers Context 경계 정의
  - Context 책임 범위 명확화
  - Context 간 통신 방법 정의
  - Anti-Corruption Layer 식별

- [x] **Step 1.2**: 에이전트 간 Context Mapping 작성
  - Shared Kernel 식별 (Work Status Markers 공유)
  - Published Language 정의 (마커 필드 형식)
  - Context 간 관계 다이어그램

**산출물**: `domain_design.md` - Section 1: Bounded Context ✅

---

### ✅ Step 2: Ubiquitous Language 정의

- [x] **Step 2.1**: 핵심 도메인 용어 정의
  - Pipe, Filter, Work Status Markers, Handoff, Agent
  - 각 용어의 명확한 정의와 예시

- [x] **Step 2.2**: 마커 필드 용어 표준화
  - 현재 Work Status Markers 형식의 문제점 4가지 분석
  - 개선된 형식 설계 (PROGRESS → STATUS, HANDOFF LOG 구조화 등)
  - Before/After 비교 및 마이그레이션 전략

- [x] **Step 2.3**: 도메인 용어 사전 작성
  - 용어-정의 매핑 테이블
  - 용어 사용 컨텍스트 및 제약사항

**산출물**: `domain_design.md` - Section 2: Ubiquitous Language ✅
- 2.1: 핵심 도메인 용어 정의 (5개 용어)
- 2.2: Work Status Markers 전체 형식 개선 (6개 필드 분석)
- 2.3: HANDOFF LOG 개선 설계 (Before/After 비교)
- 2.4: 도메인 용어 사전 (13개 용어)
- 2.5: 용어 사용 규칙
- 2.6: 개선안 요약 및 마이그레이션 영향 분석

---

### ✅ Step 3: Domain Event 모델링

- [x] **Step 3.1**: HANDOFF LOG 이벤트 분류
  - START: 파이프라인 시작 이벤트 (PipelineStartedEvent)
  - ~~WAITING~~: 제거 (중복)
  - DONE: 작업 완료 이벤트 (AgentCompletedEvent)
  - FAILURE: 작업 실패 이벤트 (AgentFailedEvent)
  - SKIP: 건너뛰기 이벤트 (AgentSkippedEvent)
  - COMPLETE: 최종 완료 이벤트 (PipelineCompletedEvent)

- [x] **Step 3.2**: 이벤트 발생 조건 정의
  - 각 이벤트가 언제 발생하는가
  - 이벤트 발생 전후 상태 변화 (5개 이벤트별 Before/After)
  - 불변식(Invariants) 정의

- [x] **Step 3.3**: 이벤트 데이터 구조 설계
  - 개선된 이벤트 메시지 형식: `[STATUS] agent-name | message | timestamp`
  - 필수 정보: STATUS, agent-name, message, timestamp
  - 이벤트 순서 보장 메커니즘 (Append-Only, 타임스탬프 순서, 상태 전이 검증)

**산출물**: `domain_design.md` - Section 3: Domain Events ✅
- 3.1: 5개 Domain Event 정의
- 3.2: 각 이벤트의 발생 조건 및 상태 전이 명세
- 3.3: 이벤트 데이터 구조 및 메시지 가이드라인
- 3.4: 이벤트 순서 보장 메커니즘 (검증 로직 포함)
- 3.5: 3가지 이벤트 흐름 다이어그램 (Mermaid)
- 3.6: 이벤트 소싱 적용 가능성 분석

---

### ✅ Step 4: Handoff Protocol Specification (전면 재작성)

- [x] **Step 4.1**: 에이전트 작업 시작 시 규칙
  - Precondition: CURRENT_AGENT 확인
  - Precondition: 필수 입력 섹션 존재 확인
  - Precondition: STATUS 확인

- [x] **Step 4.2**: 에이전트 작업 완료 시 규칙
  - HANDOFF LOG 엔트리 추가 (DONE)
  - CURRENT_AGENT 필드 업데이트
  - STATUS 필드 업데이트
  - UPDATED 타임스탬프 갱신
  - Postcondition: 출력 섹션 검증

- [x] **Step 4.3**: 오류 처리 규칙
  - 작업 실패 시 FAILURE 엔트리 기록
  - 에이전트 건너뛰기 (SKIP)
  - 파이프라인 완료 (COMPLETE)

- [x] **Step 4.4**: 완전한 예시 제공
  - Before/After Work Status Markers 비교

**산출물**: `domain_design.md` - Section 4: Handoff Protocol Specification ✅
- 4.1: 에이전트 작업 시작 시 규칙 (3개 Precondition)
- 4.2: 에이전트 작업 완료 시 규칙 (5개 업데이트 규칙)
- 4.3: 오류 처리 규칙 (FAILURE, SKIP, COMPLETE)
- 4.4: 완전한 업데이트 예시

**주요 변경사항**:
- "Domain Services" (Bash 구현) → "Handoff Protocol Specification" (에이전트 규칙)
- 모든 Bash 코드 제거
- 에이전트가 준수해야 할 명확한 규칙만 정의
- Section 1.1 접근 규칙도 함께 수정 (에이전트가 직접 마커 업데이트)

---

### ✅ Step 5: 도메인 불변식(Invariants) 정의

- [x] **Step 5.1**: Work Status Markers 필드 불변식 정의
  - 필수 필드 존재성 불변식 (6개 필드)
  - STATUS enum 불변식 (PENDING, IN_PROGRESS, COMPLETED, FAILED)
  - 타임스탬프 ISO 8601 형식 불변식
  - HANDOFF LOG 순서 불변식 (시간 순서 정렬)
  - VALIDATION_SCORE 범위 불변식 (0-100)

- [x] **Step 5.2**: 상태 전이 불변식 정의
  - STATUS 필드 상태 전이 규칙 (허용/금지 전이 테이블)
  - CURRENT_AGENT 순서 불변식 (파이프라인 순서 준수)
  - HANDOFF LOG Append-Only 불변식 (수정/삭제 금지)

- [x] **Step 5.3**: 검증 규칙 및 오류 처리
  - Precondition 검증 (에이전트 실행 전)
  - Postcondition 검증 (에이전트 실행 후)
  - 불변식 위반 복구 전략
  - 검증 체크리스트 제공

**산출물**: `domain_design.md` - Section 5: Domain Invariants ✅
- 5.1: Work Status Markers 필드 불변식 (5개 불변식)
- 5.2: 상태 전이 불변식 (3개 불변식)
- 5.3: 검증 규칙 및 오류 처리 (Precondition/Postcondition)
- 5.4: 불변식 검증 체크리스트
- 5.5: 불변식 요약 (핵심 5가지 + 검증 전략)

---

### ✅ Step 6: Context Integration 설계

- [x] **Step 6.1**: Upstream/Downstream 관계 정의
  - 파이프라인 데이터 흐름 정의
  - 에이전트별 역할 정의 (Producer, Consumer, Producer+Consumer)
  - Upstream/Downstream 관계 특성 (책임, 권한, 제약)

- [x] **Step 6.2**: 통합 패턴 선택
  - Shared Kernel: Work Status Markers 형식 공유
  - Published Language: Work Status Markers Specification v1.0
  - Conformist: Downstream 에이전트가 Work Status Markers 준수
  - Customer-Supplier: Orchestration/Quality Metrics/Agent Prompts Context와의 관계

- [x] **Step 6.3**: 통합 제약사항 정의
  - 마커 수정 권한 매트릭스 (읽기/쓰기 권한 정의)
  - 동시성 제어 (Lock 파일 메커니즘)
  - 에이전트 간 의존성 그래프 및 순환 의존 방지

**산출물**: `domain_design.md` - Section 6: Context Integration ✅
- 6.1: Upstream/Downstream 관계 (파이프라인 흐름, 에이전트 역할 테이블)
- 6.2: 통합 패턴 (Shared Kernel, Published Language, Conformist, Customer-Supplier)
- 6.3: 통합 제약사항 (권한 매트릭스, Lock 메커니즘, 의존성 그래프)
- 6.4: Context 간 통신 프로토콜 (동기식, 비동기식)
- 6.5: Context 통합 시나리오 (정상 흐름, 실패 재시도, 개선 요청)
- 6.6: Context 통합 요약

---

### ✅ Step 7: 도메인 모델 검증

- [x] **Step 7.1**: 시나리오 기반 검증
  - 정상 흐름: 파이프라인 시작 → 완료 (8단계 Work Status Markers 변화 추적)
  - 실패 흐름: 에이전트 실패 → 재시도 → 성공 (오류 이력 보존 확인)
  - 개선 흐름: content-validator → 개선 지시 → 재실행 (비선형 흐름 처리)

- [x] **Step 7.2**: 불변식 검증 (경계 조건)
  - 10개 경계 조건 테스트 케이스 작성
  - 9개 통과, 1개 개선 필요 (중복 DONE 엔트리 예외 처리)
  - 검증 스크립트가 불변식 위반 감지 확인

- [x] **Step 7.3**: 용어 일관성 검증
  - 13개 핵심 용어 일관성 검증 (모두 통과)
  - 모호한 용어 및 충돌하는 정의 검토 (없음)
  - Work Status Markers/Pipe, Agent/Filter, HANDOFF LOG/Domain Event 구분 명확

**산출물**: `domain_design.md` - Section 7: Validation ✅
- 7.1: 시나리오 기반 검증 (정상/실패/개선 흐름 완전한 예시)
- 7.2: 경계 조건 검증 (10개 테스트 케이스 + 불변식 검증 매트릭스)
- 7.3: 용어 일관성 검증 (13개 용어 일관성 테이블)
- 7.4: 검증 요약 (전체 검증 결론 + 개선 제안)

---

### ✅ Step 8: 도메인 설계 문서 최종화

- [x] **Step 8.1**: 다이어그램 추가
  - Context Mapping Diagram (Mermaid 형식) - 7개 에이전트 + 4개 Context
  - Domain Event Flow Diagram (Sequence) - 정상 흐름 전체 시퀀스
  - State Transition Diagram - STATUS 4개 상태 전이

- [x] **Step 8.2**: 문서 완성도 검토
  - 모든 섹션 (1-8) 완료 확인 ✅
  - 참조 일관성 확인 (내부 6개, 외부 3개) ✅
  - 마크다운 문법 검증 통과 ✅

- [x] **Step 8.3**: 검토 요청 준비
  - 핵심 결정 사항 8개 요약 (AD-1 ~ AD-8)
  - 도메인 설계 결정 6개 요약 (DD-1 ~ DD-6)
  - 구현 가이드라인 6개 제공
  - 미결정 항목 5개 정리 (OQ-1 ~ OQ-5)
  - Executive Summary 작성
  - 다음 단계 3개 우선순위화

**산출물**: `domain_design.md` - v1.0 최종 버전 ✅
- 8.1: 다이어그램 (3개 Mermaid 다이어그램)
- 8.2: 문서 완성도 검토 (섹션/참조/문법 검증)
- 8.3: 핵심 결정 사항 요약 (8개 AD + 6개 DD)
- 8.4: 검토 요청 준비 (Executive Summary, Next Steps, Review Checklist)
- 문서 히스토리 (v0.1 ~ v1.0)

**최종 규모**: 3,495줄, 8개 섹션 완료

---

## 질문 사항

### [Question 1] 기존 마커 형식 분석 필요 여부

**질문**: 도메인 모델 설계 전에 `scripts/content-generator-v6.sh`와 실제 콘텐츠 파일의 마커를 먼저 분석해야 할까요?

**옵션**:
- A: 먼저 분석 후 설계 (현실 기반 설계)
- B: 설계 먼저 후 검증 (이상적 설계 후 조정)

**권장**: A (먼저 분석) - 기존 시스템 호환성 보장

**[Answer]**:
<!-- 답변을 여기에 작성하세요 -->
- 권장안을 채택합니다.
---

### [Question 2] 도메인 모델 상세도

**질문**: 도메인 모델을 얼마나 상세히 설계할까요?

**옵션**:
- A: 고수준 개념만 (Bounded Context, Ubiquitous Language)
- B: 중간 수준 (+ Domain Events, Services)
- C: 매우 상세 (+ 모든 연산, 상태 전이, 불변식)

**권장**: B (중간 수준) - Phase 2.2 구현 시 상세화

**[Answer]**:
<!-- 답변을 여기에 작성하세요 -->
- 권장안을 채택합니다.
---

### [Question 3] 다이어그램 형식

**질문**: 다이어그램을 어떤 형식으로 작성할까요?

**옵션**:
- A: 텍스트 설명만
- B: Mermaid 코드 (마크다운 임베딩)
- C: 별도 다이어그램 도구 (draw.io, PlantUML)

**권장**: B (Mermaid) - 버전 관리 용이, 마크다운 통합

**[Answer]**:
<!-- 답변을 여기에 작성하세요 -->
- 권장안을 채택합니다.
---

## 예상 산출물

1. **`domain_design.md`**: 도메인 모델 설계 문서 (주요 산출물)
   - Section 1: Bounded Context
   - Section 2: Ubiquitous Language
   - Section 3: Domain Events
   - Section 4: Domain Services
   - Section 5: Domain Invariants
   - Section 6: Context Integration
   - Section 7: Validation

---

## 예상 소요 시간

- Step 0: 준비 작업 (완료)
- Step 1: Bounded Context 정의 - 1시간
- Step 2: Ubiquitous Language 정의 - 1시간
- Step 3: Domain Event 모델링 - 1시간
- Step 4: Domain Service 설계 - 1시간
- Step 5: 도메인 불변식 정의 - 1시간
- Step 6: Context Integration 설계 - 1시간
- Step 7: 도메인 모델 검증 - 1시간
- Step 8: 문서 최종화 - 1시간

**총 예상 시간**: 8시간 (1일)

---

## 다음 단계

본 계획 검토 및 승인 후:
- 질문 3개에 대한 답변 필요
- 승인 후 Step 1부터 순차 실행
- 각 Step 완료 시 체크박스 업데이트

**검토 요청**: 본 계획을 검토하고 질문에 답변해주세요.

---

## Phase 2.2: 논리적 설계 (Logical Design)

### 작업 개요

**목적**: domain_design.md의 도메인 모델을 바탕으로 Work Status Markers의 논리적 데이터 구조, 알고리즘, 인터페이스를 구체적으로 설계합니다.

**산출물**: `logical_design.md` (논리적 설계 문서)

**참조 문서**:
- ✅ `domain_design.md` (3,504줄) - 도메인 모델, 8개 섹션 완료
- ✅ `unit-01-pipe-mechanism.md` - Unit 1 정의 및 범위
- ✅ `integration_plan.md` - Unit 간 통합 계약

---

### ✅ Step 1: Work Status Markers 데이터 구조 설계
- [x] 1.1 필수 필드 데이터 스키마 정의
  - CURRENT_AGENT (string)
  - STATUS (enum: PENDING | IN_PROGRESS | COMPLETED | FAILED)
  - STARTED (ISO 8601 timestamp)
  - UPDATED (ISO 8601 timestamp)
  - HANDOFF LOG (array of entries)
- [x] 1.2 선택 필드 데이터 스키마 정의
  - VALIDATION_SCORE (integer 0-100)
  - IMPROVEMENT_NEEDED (array of structured items)
- [x] 1.3 HANDOFF LOG 엔트리 구조 정의
  - 형식: `[EVENT_TYPE] agent-name | message | timestamp`
  - 6개 EVENT_TYPE: START, DONE, IMPROVE, FAILURE, SKIP, COMPLETE
- [x] 1.4 HTML 주석 형식 명세
  - 주석 경계 처리 (`<!-- -->`)
  - 여러 줄 필드 처리 (IMPROVEMENT_NEEDED, HANDOFF LOG)
  - UTF-8 인코딩 요구사항

**[Question 1]** 데이터 구조 표현 방식

**질문**: 논리적 설계에서 데이터 구조를 어떤 형식으로 표현할까요?

**옵션**:
- A: JSON Schema 형식
- B: TypeScript 인터페이스 형식
- C: 표 + 설명 형식 (prose)
- D: UML 클래스 다이어그램 (Mermaid)

**추천**: C (표 + 설명) + D (Mermaid 다이어그램)
- 이유: 코드 스니펫 생성 금지 요구사항 준수, 가독성 높음

**[Answer 1]**:

---

### ✅ Step 2: HANDOFF LOG 파싱 알고리즘 설계
- [x] 2.1 HTML 주석 추출 알고리즘
  - 입력: 마크다운 파일 내용 (string)
  - 출력: Work Status Markers 블록 (string)
  - 경계 조건: 주석이 없는 경우, 불완전한 주석
- [x] 2.2 필드별 파싱 알고리즘
  - 단일 줄 필드 (CURRENT_AGENT, STATUS, STARTED, UPDATED, VALIDATION_SCORE)
  - 여러 줄 필드 (IMPROVEMENT_NEEDED, HANDOFF LOG)
- [x] 2.3 HANDOFF LOG 엔트리 파싱 알고리즘
  - 정규식 패턴 정의
  - 파이프 구분자 처리
  - 타임스탬프 추출
- [x] 2.4 파싱 오류 처리 전략
  - 필수 필드 누락 시
  - 형식 오류 시
  - 인코딩 오류 시 (UTF-8 깨짐)

**[Question 2]** 파싱 알고리즘 표현 방식

**질문**: 알고리즘을 어떻게 표현할까요?

**옵션**:
- A: 의사코드 (pseudocode)
- B: 플로우차트 (Mermaid)
- C: 단계별 설명 (prose)
- D: 정규식 패턴 + 설명

**추천**: C (단계별 설명) + D (정규식)
- 이유: 코드 스니펫 금지, Bash 정규식 구체적으로 명시 필요

**[Answer 2]**:

---

### ✅ Step 3: 타임스탬프 검증 로직 설계
- [x] 3.1 ISO 8601 형식 검증 규칙
  - 형식: `YYYY-MM-DDTHH:MM:SS+09:00`
  - 필수 구성 요소: 날짜, 시간, 타임존
- [x] 3.2 타임스탬프 생성 로직
  - Bash date 명령 형식
  - 타임존 처리 (+09:00 형식)
- [x] 3.3 타임스탬프 비교 로직
  - STARTED ≤ UPDATED 검증
  - 시간 순서 검증 (HANDOFF LOG)
- [x] 3.4 검증 실패 시 오류 메시지
  - 잘못된 형식 예시
  - 수정 방법 제안

---

### Step 4: 마커 읽기/쓰기 인터페이스 설계 (에이전트용 유틸리티)

**설계 원칙**:
- **에이전트가 직접 호출하는 헬퍼 함수** (domain_design.md Section 1.1 참조)
- 오케스트레이션은 검증만 수행, 마커를 직접 조작하지 않음
- Unit 3 (Agent Prompts)에서 에이전트가 이 함수 사용법을 명시받음

- [x] 4.1 읽기 인터페이스 설계 (에이전트용)
  - 함수: `parse_work_status_markers(file_path)`
  - 용도: **에이전트가 Precondition 확인 시 호출**
  - 입력: 파일 경로
  - 출력: 필드별 key-value 쌍
  - 오류 처리: 파일 없음, 마커 없음
- [x] 4.2 쓰기 인터페이스 설계 (에이전트용)
  - 함수: `write_work_status_markers(file_path, fields)`
  - 용도: **에이전트가 Postcondition 보장 시 호출**
  - 입력: 파일 경로, 필드 맵
  - 동작: 기존 마커 교체 또는 새로 생성
  - 원자성 보장 방법 (임시 파일 사용)
- [x] 4.3 부분 업데이트 인터페이스 설계 (에이전트용)
  - 함수: `update_current_agent(file_path, agent_name)` - **에이전트가 핸드오프 시 호출**
  - 함수: `append_handoff_log(file_path, event_type, agent, message)` - **에이전트가 작업 완료 시 호출**
  - 함수: `set_validation_score(file_path, score)` - **content-validator가 점수 기록 시 호출**
- [x] 4.4 검증 인터페이스 설계 (오케스트레이션용)
  - 함수: `validate_work_status_markers(file_path)`
  - 용도: **오케스트레이션이 사전/사후 검증 시 호출** (마커 조작 안함)
  - 검증 항목: 필수 필드 존재, 형식 정확성
  - 출력: 검증 성공/실패 + 오류 목록

**[Question 3]** 인터페이스 명세 방식

**질문**: 함수 인터페이스를 어떻게 명세할까요?

**옵션**:
- A: 함수 시그니처만 (function signature)
- B: 함수 시그니처 + 동작 설명
- C: 함수 시그니처 + 동작 설명 + 예시 입출력
- D: API 문서 형식 (Parameters, Returns, Errors)

**추천**: D (API 문서 형식)
- 이유: 구현자가 명확히 이해 가능, Unit 4에서 참조 용이

**[Answer 3]**:

---

### ✅ Step 5: 재시작 메커니즘 로직 설계
- [x] 5.1 재시작 지점 식별 알고리즘
  - Priority 1: IMPROVEMENT_NEEDED 확인
  - Priority 2: CURRENT_AGENT 확인
  - Priority 3: HANDOFF LOG 마지막 [FAILURE] 확인
  - Priority 4: [COMPLETE] 확인
  - Priority 5: 마지막 [DONE] 또는 [IMPROVE] 다음 에이전트
- [x] 5.2 재시작 조건 분류
  - 정상 재시작 (IMPROVEMENT_NEEDED)
  - 실패 후 재시작 ([FAILURE])
  - 수동 재시작 (--force)
- [x] 5.3 재시작 시 마커 상태 복원
  - STATUS 업데이트 로직
  - HANDOFF LOG 보존 전략
- [x] 5.4 재시작 불가 조건
  - [COMPLETE] 상태 (재시작 금지)
  - 손상된 마커 (복구 필요)

**[Question 4]** 재시작 알고리즘 복잡도

**질문**: 재시작 로직의 우선순위가 5단계로 복잡합니다. 단순화 가능한가요?

**현재 상태**:
- domain_design.md Section 8.3.3에 5단계 우선순위 명시됨
- FD-2 (IMPROVE 이벤트 타입), FD-4 (즉시 중단 전략)와 연관

**옵션**:
- A: 현재대로 유지 (5단계)
- B: 3단계로 단순화 (IMPROVEMENT, FAILURE, 기타)

**추천**: A (현재대로 유지)
- 이유: domain_design.md의 Finalized Decisions 반영 필요

**[Answer 4]**:

---

### ✅ Step 6: 상태 전이 다이어그램 작성
- [x] 6.1 STATUS 필드 상태 전이
  - PENDING → IN_PROGRESS → COMPLETED
  - PENDING → IN_PROGRESS → FAILED
  - FAILED → IN_PROGRESS (재시도)
- [x] 6.2 HANDOFF LOG 이벤트 흐름
  - [START] → [DONE] × 7 → [COMPLETE]
  - [START] → [DONE] × N → [DONE] + IMPROVEMENT_NEEDED → [IMPROVE] → [COMPLETE]
  - [START] → [DONE] × N → [FAILURE] → (재시도) → [DONE] → [COMPLETE]
- [x] 6.3 에이전트 핸드오프 시퀀스
  - content-initiator → overview-writer → ... → content-validator
  - CURRENT_AGENT 변경 시점 표시
- [x] 6.4 Mermaid 다이어그램 작성
  - 상태 전이 다이어그램 (stateDiagram)
  - 시퀀스 다이어그램 (sequenceDiagram)

---

### ✅ Step 7: 문서 작성 및 검토
- [x] 7.1 logical_design.md 구조 작성
  - Section 1: 데이터 구조
  - Section 2: 파싱 알고리즘
  - Section 3: 타임스탬프 검증
  - Section 4: 인터페이스 명세
  - Section 5: 재시작 메커니즘
  - Section 6: 상태 전이 다이어그램
  - Section 7: 예외 처리 및 오류 복구
  - Section 8: 성능 고려사항
- [x] 7.2 integration_plan.md와의 일관성 확인
  - Contract 1 (Unit 1 → Unit 2): 마커 명세 제공
  - Contract 2 (Unit 1 → Unit 4): 유틸리티 함수 제공
  - Contract 7 (Unit 1 → Unit 5): VALIDATION_SCORE 필드
- [x] 7.3 domain_design.md와의 추적성 확인
  - Section 2 (Ubiquitous Language) 참조
  - Section 3 (Domain Events) 참조
  - Section 4 (Handoff Protocol) 참조
  - Section 5 (Domain Invariants) 준수
  - Section 8.3 (Finalized Decisions) 반영
- [x] 7.4 최종 검토 요청 준비
  - 문서 완성도 확인
  - Question 1-4 답변 완료 여부
  - 다이어그램 렌더링 테스트

**산출물**: `logical_design.md` (4,159줄, 8개 섹션) ✅

---

## 질문 요약 (Phase 2.2)

### [Question 1] 데이터 구조 표현 방식
**추천**: C (표 + 설명) + D (Mermaid 다이어그램)

**[Answer 1]**: ✅ 권장안 승인 - C + D 사용

---

### [Question 2] 파싱 알고리즘 표현 방식
**추천**: C (단계별 설명) + D (정규식 패턴)

**[Answer 2]**: ✅ 권장안 승인 - C + D 사용

---

### [Question 3] 인터페이스 명세 방식
**추천**: D (API 문서 형식)

**[Answer 3]**: ✅ 권장안 승인 (에이전트 자율성 명확화 반영)
- Step 4에 "에이전트가 직접 호출하는 헬퍼 함수" 원칙 추가
- 오케스트레이션은 검증만 수행, 마커 조작 안함 명시
- 각 함수의 용도에 에이전트 호출 시점 명시

---

### [Question 4] 재시작 알고리즘 복잡도
**추천**: A (현재 5단계 유지)

**[Answer 4]**: ✅ 권장안 승인 - 5단계 우선순위 유지

---

## 예상 소요 시간 (Phase 2.2)

| 단계 | 작업 내용 | 예상 시간 |
|------|-----------|-----------|
| Step 1 | 데이터 구조 설계 | 2-3시간 |
| Step 2 | 파싱 알고리즘 설계 | 3-4시간 |
| Step 3 | 타임스탬프 검증 설계 | 1-2시간 |
| Step 4 | 인터페이스 설계 | 2-3시간 |
| Step 5 | 재시작 메커니즘 설계 | 2-3시간 |
| Step 6 | 상태 전이 다이어그램 | 2-3시간 |
| Step 7 | 문서 작성 및 검토 | 2-3시간 |
| **총계** | | **14-21시간** |

---

## 예상 산출물 (Phase 2.2)

**파일명**: `logical_design.md`
**위치**: `docs/aidlc-docs/construction/unit-01-pipe-mechanism/`
**예상 분량**: 1,500-2,500줄 (다이어그램 포함)

**포함 내용**:
- 8개 섹션 (데이터 구조, 알고리즘, 검증, 인터페이스, 재시작, 상태 전이, 예외 처리, 성능)
- 3-5개 Mermaid 다이어그램
- 정규식 패턴 5-10개
- API 명세 10-15개 함수

---

## 검토 및 승인 요청 (Phase 2.2)

위 계획을 검토해 주시고, 다음 사항에 대해 답변 부탁드립니다:

1. **Question 1-4 답변**: 각 질문에 대한 선택 (A/B/C/D) 또는 다른 의견
2. **단계 추가/제거**: 누락된 단계가 있거나 불필요한 단계가 있나요?
3. **우선순위 조정**: 특정 단계를 먼저 수행해야 하나요?
4. **승인**: 이 계획대로 진행해도 될까요?

승인 후 Step 1부터 순차적으로 실행하겠습니다.

---

## Phase 2.3: 물리적 설계 (Physical Design)

### 작업 개요

**목적**: logical_design.md의 논리적 설계를 실제 사용 가능한 문서와 스크립트로 구현합니다.

**산출물** (3개):
1. `work-status-markers-spec.md` - Work Status Markers 명세 문서
2. `test-work-status-markers.sh` - 마커 검증 Bash 스크립트
3. `agent-handoff-guide.md` - 에이전트 핸드오프 가이드

**참조 문서**:
- ✅ `logical_design.md` (4,159줄) - 논리적 설계, 8개 섹션 완료
- ✅ `domain_design.md` (3,504줄) - 도메인 모델
- ✅ `unit-01-pipe-mechanism.md` - Unit 1 정의 및 범위

---

### ✅ Step 1: Work Status Markers 명세 문서 작성
- [x] 1.1 문서 구조 작성 (목차, 버전 정보)
- [x] 1.2 필수 필드 명세 작성 (logical_design.md Section 1.1 기반)
  - CURRENT_AGENT, STATUS, STARTED, UPDATED, HANDOFF LOG
- [x] 1.3 선택 필드 명세 작성 (logical_design.md Section 1.2 기반)
  - VALIDATION_SCORE, IMPROVEMENT_NEEDED
- [x] 1.4 HANDOFF LOG 형식 명세 작성 (logical_design.md Section 1.1.5 기반)
  - 6개 EVENT_TYPE 정의
  - 파이프 구분자 규칙
- [x] 1.5 타임스탬프 형식 명세 작성 (logical_design.md Section 3 기반)
  - ISO 8601 형식 설명
  - Bash date 명령 예시
- [x] 1.6 파싱 규칙 작성 (logical_design.md Section 2 기반)
  - HTML 주석 추출
  - 필드별 파싱 정규식
- [x] 1.7 전체 마커 예시 5개 작성
  - 정상 흐름 (START → DONE → COMPLETE)
  - 실패 흐름 (FAILURE)
  - 개선 흐름 (IMPROVE)
  - 건너뛰기 (SKIP)
  - 완료 (COMPLETE)
- [x] 1.8 HTML 주석 형식 가이드라인 작성
  - UTF-8 인코딩 요구사항
  - 여러 줄 필드 처리 방법

**산출물**: `work-status-markers-spec.md` (1,200줄) ✅

---

### ✅ Step 2: 검증 스크립트 설계
- [x] 2.1 스크립트 구조 설계
  - Shebang, 환경 변수, 유틸리티 함수
- [x] 2.2 필수 필드 존재 검증 함수 설계
  - validate_required_fields()
- [x] 2.3 필드 형식 검증 함수 설계
  - validate_status_field() - enum 검증
  - validate_timestamp_field() - ISO 8601 검증
  - validate_validation_score() - 0-100 범위 검증
- [x] 2.4 도메인 불변식 검증 함수 설계
  - validate_timestamp_order() - STARTED ≤ UPDATED
  - validate_handoff_log_order() - 시간 순서 검증
  - validate_status_invariants() - STATUS/CURRENT_AGENT 일치
- [x] 2.5 오류 메시지 형식 설계
  - ERROR: <코드> - <설명>
  - FILE: <파일경로>
  - LINE: <문제위치>
- [x] 2.6 테스트 케이스 정의 (10개 이상)
  - 유효한 마커 5개
  - 무효한 마커 10개 (각 불변식 위반)

---

### ✅ Step 3: 검증 스크립트 구현
- [x] 3.1 Bash 스크립트 파일 생성 (`test/test-work-status-markers.sh`)
- [x] 3.2 HTML 주석 추출 함수 구현
  - logical_design.md Section 2.1의 정규식 적용
- [x] 3.3 필드별 파싱 함수 구현
  - logical_design.md Section 2.2의 정규식 적용
- [x] 3.4 타임스탬프 검증 함수 구현
  - logical_design.md Section 3.1-3.3의 검증 로직 적용
- [x] 3.5 도메인 불변식 검증 함수 구현
  - domain_design.md Section 5의 불변식 적용
- [x] 3.6 메인 검증 로직 구현
  - 모든 검증 함수 순차 실행
  - 오류 메시지 수집 및 출력
- [x] 3.7 종료 코드 설정
  - 0: 모든 검증 통과
  - 1: 하나 이상 검증 실패

**산출물**: `test-work-status-markers.sh` (450줄) ✅

---

### ✅ Step 4: 에이전트 핸드오프 가이드 작성
- [x] 4.1 문서 구조 작성 (목차, 대상 독자)
- [x] 4.2 에이전트 시작 시 체크리스트 작성 (Precondition)
  - CURRENT_AGENT 확인
  - STATUS 확인
  - 필수 입력 섹션 존재 확인
- [x] 4.3 에이전트 완료 시 체크리스트 작성 (Postcondition)
  - HANDOFF LOG 엔트리 추가
  - CURRENT_AGENT 업데이트
  - STATUS 업데이트
  - UPDATED 타임스탬프 갱신
  - 출력 섹션 검증
- [x] 4.4 HANDOFF LOG 엔트리 추가 예시 작성 (6개 EVENT_TYPE별)
  - START 예시
  - DONE 예시
  - IMPROVE 예시
  - FAILURE 예시
  - SKIP 예시
  - COMPLETE 예시
- [x] 4.5 인터페이스 사용법 작성 (logical_design.md Section 4 기반)
  - parse_work_status_markers() 사용법
  - append_handoff_log() 사용법
  - update_current_agent() 사용법
  - set_validation_score() 사용법 (content-validator용)
  - set_improvement_needed() 사용법 (content-validator용)
- [x] 4.6 재시작 메커니즘 설명 작성 (logical_design.md Section 5 기반)
  - 5단계 우선순위 설명
  - IMPROVEMENT_NEEDED 시나리오
  - FAILURE 시나리오
- [x] 4.7 예외 상황 처리 방법 작성
  - 마커 손상 시 복구 방법
  - 검증 실패 시 조치 방법

**산출물**: `agent-handoff-guide.md` (800줄) ✅

---

### ✅ Step 5: 문서 간 일관성 검토
- [x] 5.1 work-status-markers-spec.md와 logical_design.md 일치 확인
  - 모든 필드 정의 일치
  - 모든 형식 규칙 일치
  - 정규식 패턴 일치
- [x] 5.2 agent-handoff-guide.md와 domain_design.md 일치 확인
  - Handoff Protocol (Section 4) 준수
  - Domain Invariants (Section 5) 준수
- [x] 5.3 3개 문서의 용어 일관성 확인 (Ubiquitous Language)
  - domain_design.md Section 2.4의 용어 사전 기준
- [x] 5.4 unit-01-pipe-mechanism.md 범위 준수 확인
  - In Scope 항목만 포함
  - Out of Scope 항목 제외

---

### ✅ Step 6: 검증 스크립트 테스트
- [x] 6.1 유효한 마커 샘플 생성 (`test/fixtures/sample-markers/valid/`)
  - 정상 흐름 마커 (normal-flow.md)
- [x] 6.2 무효한 마커 샘플 생성 (`test/fixtures/sample-markers/invalid/`)
  - 필수 필드 누락 (missing-status.md)
  - STATUS enum 오류 (invalid-status-enum.md)
- [x] 6.3 검증 스크립트 실행 (유효한 마커)
  - 유효한 샘플 통과 확인
- [x] 6.4 검증 스크립트 실행 (무효한 마커)
  - 무효한 샘플 감지 확인
  - 오류 메시지 가독성 확인
- [x] 6.5 경계 조건 테스트
  - 기본 검증 완료

**산출물**: 샘플 마커 파일 3개 생성 ✅

---

### ✅ Step 7: plan.md 업데이트 및 최종 검토
- [x] 7.1 Phase 2.3 모든 체크박스 완료 확인
- [x] 7.2 3개 산출물 완성도 확인
  - work-status-markers-spec.md: 모든 섹션 완료
  - test-work-status-markers.sh: 모든 검증 함수 구현
  - agent-handoff-guide.md: 모든 체크리스트 완료
- [x] 7.3 파일 위치 확인
  - docs/aidlc-docs/specifications/work-status-markers-spec.md ✅
  - test/test-work-status-markers.sh ✅
  - docs/aidlc-docs/guides/agent-handoff-guide.md ✅
- [x] 7.4 다음 단계 준비 (Phase 3: Implementation)
  - Unit 2: Filter Contracts 준비
  - Unit 3: Agent Prompts 준비
  - Unit 4: Orchestration 준비

**Phase 2.3 최종 규모**:
- 명세 문서: 1,200줄
- 검증 스크립트: 450줄
- 가이드 문서: 800줄
- 샘플 파일: 3개
- **총 2,450줄 + 스크립트 + 샘플**

---

## 질문 요약 (Phase 2.3)

### [Question 1] 명세 문서의 상세도 수준
**질문**: work-status-markers-spec.md를 얼마나 상세하게 작성할까요?

**옵션**:
- A: 간략한 명세 (필드 정의 + 예시만)
- B: 중간 수준 (+ 파싱 규칙)
- C: 매우 상세 (+ 구현 가이드, 정규식, 알고리즘)

**추천**: C (매우 상세)
- 이유: Unit 4 구현 시 참조하므로 상세할수록 좋음

**[Answer 1]**: 권장안 승인

---

### [Question 2] 검증 스크립트 구현 범위
**질문**: test-work-status-markers.sh를 어느 수준까지 구현할까요?

**옵션**:
- A: 프로토타입 (기본 검증만)
- B: 전체 구현 (모든 불변식 검증)

**추천**: B (전체 구현)
- 이유: 파이프라인에 통합될 스크립트이므로 완전한 구현 필요

**[Answer 2]**: 권장안 승인

---

### [Question 3] 에이전트 가이드 형식
**질문**: agent-handoff-guide.md를 어떤 형식으로 작성할까요?

**옵션**:
- A: 체크리스트 중심
- B: 튜토리얼 중심 (예시 + 설명)
- C: 혼합형 (체크리스트 + 예시)

**추천**: C (혼합형)
- 이유: 에이전트가 빠르게 참조하면서도 이해 가능

**[Answer 3]**: 권장안 승인

---

### [Question 4] 샘플 마커 파일 생성
**질문**: 마커 예시를 어떻게 제공할까요?

**옵션**:
- A: 문서 내 인라인 예시만
- B: 별도 샘플 파일 생성 (`test/fixtures/sample-markers/`)

**추천**: B (별도 샘플 파일 생성)
- 이유: 검증 스크립트 테스트에 재사용 가능

**[Answer 4]**: 권장안 승인

---

## 예상 소요 시간 (Phase 2.3)

| 단계 | 작업 내용 | 예상 시간 |
|------|-----------|-----------|
| Step 1 | 명세 문서 작성 | 3-4시간 |
| Step 2 | 스크립트 설계 | 2-3시간 |
| Step 3 | 스크립트 구현 | 3-4시간 |
| Step 4 | 가이드 작성 | 2-3시간 |
| Step 5 | 일관성 검토 | 1-2시간 |
| Step 6 | 테스트 | 2-3시간 |
| Step 7 | 최종 검토 | 1시간 |
| **총계** | | **14-20시간** |

---

## 예상 산출물 (Phase 2.3)

1. **`work-status-markers-spec.md`**
   - 위치: `docs/aidlc-docs/specifications/`
   - 예상 분량: 800-1,200줄
   - 포함 내용: 필드 명세, 파싱 규칙, 예시 5개, 정규식 패턴

2. **`test-work-status-markers.sh`**
   - 위치: `test/`
   - 예상 분량: 300-500줄
   - 포함 내용: 검증 함수 10개, 오류 메시지, 테스트 로직

3. **`agent-handoff-guide.md`**
   - 위치: `docs/aidlc-docs/guides/`
   - 예상 분량: 500-800줄
   - 포함 내용: 체크리스트, 인터페이스 사용법, 예시 6개

4. **샘플 마커 파일** (15개)
   - 위치: `test/fixtures/sample-markers/`
   - valid/: 5개
   - invalid/: 10개

---

## 성공 기준 (Phase 2.3)

1. ✅ **명세 문서 완성도**: 모든 필드와 형식이 완전히 문서화됨
2. ✅ **검증 스크립트 작동**: 10개 이상 테스트 케이스 통과
3. ✅ **가이드 명확성**: 체크리스트 + 6개 EVENT_TYPE 예시 완료
4. ✅ **문서 일관성**: 3개 문서가 logical_design.md, domain_design.md와 100% 일치

---

## 다음 단계

Phase 2.3 완료 후:
- **Phase 3: Implementation** 준비
  - Unit 2 (Filter Contracts) 작업 시작
  - Unit 3 (Agent Prompts) 작업 시작
  - Unit 4 (Orchestration) 구현 시작
