# Unit 2: Filter Contracts 명시화 - Construction Phase 계획

## 프로젝트 개요

**목표**: 각 에이전트(Filter)의 입출력 계약을 명시적으로 정의하여 에이전트 간 결합도를 낮추고, 독립적인 개발/테스트/개선을 가능하게 한다.

**단계**: Phase 2.1 - DDD 경량화 방식으로 도메인 모델 설계

**참조 문서**:
- `docs/aidlc-docs/inception/units/unit-02-filter-contracts.md` (Unit 2 정의)
- `docs/aidlc-docs/construction/unit-01-pipe-mechanism/domain_design.md` (Pipe 메커니즘 도메인 모델)

---

## Phase 2.1: DDD 도메인 모델 설계

### 작업 개요

**목적**: Unit 2 요구사항을 바탕으로 Filter Contracts의 도메인 모델을 DDD 경량화 방식으로 설계합니다.

**산출물**: `domain_design.md` (도메인 설계 문서)

**핵심 설계 원칙**:
- 각 에이전트를 독립적인 Bounded Context로 정의
- 입출력 계약을 Published Language로 명시
- Interface Definition Language (IDL) 스타일 명세 작성
- 계약 변경 시 영향 범위 명확화

---

### ✅ Step 0: 준비 작업

- [x] **Step 0.1**: Unit 2 Inception 문서 재분석
  - 목적, 범위, 아키텍처 컨텍스트 이해
  - 7개 에이전트 목록 확인 (content-initiator, overview-writer, concepts-writer, visualization-writer, practice-writer, quiz-writer, content-validator)
  - In Scope/Out of Scope 명확화

- [x] **Step 0.2**: Construction 폴더 준비 완료
  - `docs/aidlc-docs/construction/unit-02-filter-contracts/` 생성 완료

- [x] **Step 0.3**: 현재 시스템 분석
  - `.claude/agents/*.md` 에이전트 프롬프트 분석 완료
  - 각 에이전트가 기대하는 입력과 생성하는 출력 파악 완료
  - 암묵적 계약 추출 완료

- [x] **Step 0.4**: Unit 1과의 의존성 확인
  - Work Status Markers 명세 참조 (`work-status-markers-spec.md`)
  - Handoff Protocol 참조 (`agent-handoff-guide.md`)
  - HANDOFF LOG 이벤트 타입 확인 (START, DONE, IMPROVE, FAILURE, SKIP, COMPLETE)

**산출물**: 현재 시스템 분석 완료 ✅

---

### ✅ Step 1-8: domain_design.md 작성 완료

**통합 작업**: 모든 단계를 domain_design.md 하나의 문서로 통합 작성

- [x] **Section 1: Bounded Context 정의** (7개 에이전트)
  - 1.1: Bounded Context 경계 원칙
  - 1.2: Context Mapping (Shared Kernel, Published Language, Customer-Supplier)
  - 1.3: 7개 Bounded Context 상세 정의
  - 1.4: Context Integration

- [x] **Section 2: Contract Template** (계약 구조 표준)
  - 2.1: Template Structure (YAML frontmatter + Markdown)
  - 2.2: Template Sections (Metadata, Responsibility, Input/Output Contract, etc.)

- [x] **Section 3: Agent Contracts** (7개 에이전트 계약)
  - 3.1: content-initiator Contract
  - 3.2: overview-writer Contract
  - 3.3: concepts-writer Contract
  - 3.4: visualization-writer Contract
  - 3.5: practice-writer Contract
  - 3.6: quiz-writer Contract
  - 3.7: content-validator Contract

- [x] **Section 4: Contract Validation Strategy**
  - 4.1: Validation Overview
  - 4.2: Precondition Validation (Fail-Fast)
  - 4.3: Postcondition Validation
  - 4.4: Validation Interface

- [x] **Section 5: Dependency Analysis**
  - 5.1: Agent Dependency Graph
  - 5.2: Dependency Matrix
  - 5.3: Mermaid 다이어그램 포함

- [x] **Section 6: Versioning and Change Management**
  - 6.1: Contract Versioning Strategy (Semantic Versioning)
  - 6.2: Breaking Change 정의
  - 6.3: Change Impact Analysis
  - 6.4: Versioning Guide

- [x] **Section 7: Validation**
  - 7.1: 시나리오 기반 검증 (정상/실패/개선 흐름)
  - 7.2: 계약 일관성 검증
  - 7.3: 용어 일관성 검증

- [x] **Section 8: Summary and Next Steps**
  - 8.1: 핵심 결정 사항 요약 (AD-1~5, DD-1~6)
  - 8.2: Implementation Checklist
  - 8.3: Next Steps
  - 8.4: Open Questions (OQ-1~5)

**산출물**: `domain_design.md` - v1.0 (완료) ✅
- 파일 크기: 약 92,000자
- 섹션 수: 8개 메인 섹션 + 47개 하위 섹션
- 다이어그램: 1개 (Agent Dependency Graph)
- 예시: 15개 이상

**Question 답변 반영**:
- [x] Question 1: B (중간 수준) - YAML frontmatter + 마크다운
- [x] Question 2: C (Mermaid flowchart + 계약 요약)
- [x] Question 3: A (개별 버전 관리)

---

### ✅ Step 9: domain_design.md 추가 개선 (v1.1)

**배경**: domain_design.md v1.0 완료 후, Unit 1과 Unit 2 간 마커 업데이트 책임 명확화 및 구현 가이드 추가 필요성 발견

**작업 내용**:

- [x] **Step 9.1**: Unit 1 원칙 재검증
  - `docs/aidlc-docs/construction/unit-01-pipe-mechanism/domain_design.md` Section 1.1, 3.1, 4.3.1, 6.3.1 검토
  - **발견**: Unit 1에 이미 명시적 예외 존재 (Orchestration이 FAILURE/SKIP 업데이트)
  - **결론**: Unit 1과 Unit 2 간 모순 없음, 명시적 예외를 Unit 2에 반영 필요

- [x] **Step 9.2**: Section 4.4.3 추가 - 마커 조작 주체 명확화
  - 위치: `domain_design.md` lines 1797-1922 (126줄)
  - 내용:
    - 일반 원칙: 에이전트가 자신의 마커 직접 업데이트
    - 명시적 예외: Orchestration이 FAILURE/SKIP 업데이트 (Unit 1 Section 3.1 참조)
    - 권한 매트릭스 (에이전트 vs Orchestration)
    - 구현 패턴 (정상 완료, 실패 감지, 개선 모드)
    - 설계 근거 (에이전트 자율성 원칙)

- [x] **Step 9.3**: Section 2.1.3 추가 - Implementation References
  - 위치: `domain_design.md` lines 528-779 (252줄)
  - 내용:
    - 11개 Unit 1 헬퍼 함수 명세 (`work-status-markers.sh`)
    - 에이전트별 호출 패턴 (정상 완료, 실패, 개선 모드, 검증 완료)
    - Orchestration 통합 예시
  - **설계 결정**: 계약 섹션과 분리하여 "계약(what)"과 "구현(how)" 명확히 구분

- [x] **Step 9.4**: 7개 에이전트 계약에 Implementation 하위 섹션 추가
  - Section 3.1 (content-initiator): lines 881-883
  - Section 3.2 (overview-writer): lines 1018-1021
  - Section 3.3 (concepts-writer): lines 1155-1158
  - Section 3.4 (visualization-writer): lines 1289-1292
  - Section 3.5 (practice-writer): lines 1432-1435
  - Section 3.6 (quiz-writer): lines 1588-1591
  - Section 3.7 (content-validator): lines 1816-1819
  - 각 계약에 Section 2.1.3 참조 링크 추가
  - 에이전트 타입별 적절한 패턴 명시

- [x] **Step 9.5**: Unit 1 명세 업데이트 - IMPROVEMENT_NEEDED 형식 확장
  - 파일: `docs/aidlc-docs/specifications/work-status-markers-spec.md`
  - 위치: Section 3.2, lines 265-320
  - 내용:
    - 기본 형식: `- agent-name: improvement description`
    - 확장 형식: `- agent-name: improvement description (-N점)` (점수 선택적)
    - 정규식 패턴: `^-\s+([a-z-]+):\s+(.+?)(?:\s+\(-(\d+)점\))?$`
    - 하위 호환성 유지

**산출물**: `domain_design.md` - v1.1 ✅
- 추가 라인 수: 약 500줄
- 새 섹션: 2개 (Section 2.1.3, Section 4.4.3)
- 업데이트 섹션: 7개 (모든 에이전트 계약)

**관련 이슈 해결**:
- ✅ Work Status Markers 업데이트 책임 명확화 (일반 원칙 + 명시적 예외)
- ✅ 에이전트 구현 가이드 제공 (헬퍼 함수 및 호출 패턴)
- ✅ IMPROVEMENT_NEEDED 형식 표준화 (기본/확장 형식)

---

## Phase 2.2: 논리적 설계 (Logical Design)

### 작업 개요

**목적**: domain_design.md에서 정의한 계약 구조를 구체적인 논리적 설계로 변환합니다.

**산출물**: `logical_design.md` (논리적 설계 문서)

**핵심 설계 내용**:
- 각 Filter(에이전트)의 입력 계약 형식 상세화
- 각 Filter의 출력 계약 형식 상세화
- 품질 기준 정의 방법 (Validation Score 계산 로직)
- 계약 검증 방법 (Precondition/Postcondition 검증 알고리즘)
- 계약 템플릿 구조 (파일 형식, 섹션 구조)

**참조 문서**:
- `domain_design.md` (Unit 2) - 도메인 모델 및 계약 템플릿
- `unit-02-filter-contracts.md` - Unit 2 정의 및 범위
- `logical_design.md` (Unit 1) - Unit 1 논리적 설계 (구조 참조)

---

### ✅ Step 0: 준비 작업

- [x] **Step 0.1**: Unit 2 domain_design.md 재분석
  - Section 2: Contract Template 구조 파악 완료
  - Section 3: 7개 Agent Contracts 내용 파악 완료
  - Section 4: Contract Validation Strategy 파악 완료
  - Section 2.1.3: Implementation References 파악 완료 (헬퍼 함수 목록)

- [x] **Step 0.2**: Unit 1 logical_design.md 구조 분석
  - 8개 섹션 구조 파악 완료 (데이터 구조, 파싱 알고리즘, 검증 로직, 인터페이스 등)
  - 명세 작성 스타일 파악 완료 (표 + Mermaid, 정규식, 알고리즘 단계)
  - 코드 스니펫 없이 명세만 작성하는 방법 학습 완료

- [x] **Step 0.3**: Unit 2 범위 명확화
  - In Scope: 계약 형식, 검증 로직, 품질 기준 정의
  - Out of Scope: 실제 검증 스크립트 구현 (Phase 2.3에서 처리)

**산출물**: 분석 완료 ✅

---

### 📋 Step 1-8: logical_design.md 작성

**통합 작업**: 모든 단계를 logical_design.md 하나의 문서로 통합 작성

- [x] **Section 1: 계약 데이터 구조** (Contract Data Structure)
  - 1.1: 계약 파일 형식 (YAML frontmatter + Markdown) ✅
  - 1.2: Input Contract 데이터 스키마 (필수 필드, 선택 필드) ✅
  - 1.3: Output Contract 데이터 스키마 ✅
  - 1.4: Preconditions 데이터 스키마 ✅
  - 1.5: Postconditions 데이터 스키마 ✅
  - 1.6: 데이터 구조 다이어그램 (Mermaid) ✅

- [x] **Section 2: 입력 계약 형식** (Input Contract Format)
  - 2.1: File State 명세 (Required Files, Encoding, Frontmatter, Existing Sections) ✅
  - 2.2: Work Status Markers 명세 (CURRENT_AGENT, STATUS, HANDOFF LOG) ✅
  - 2.3: Section Dependencies 명세 (의존 섹션 목록 형식) ✅
  - 2.4: 7개 에이전트별 Input Contract 상세 명세 ✅
  - 2.5: Input Contract 검증 규칙 ✅

- [x] **Section 3: 출력 계약 형식** (Output Contract Format)
  - 3.1: File State 명세 (Modified Files, New Sections, Section Structure) ✅
  - 3.2: Work Status Markers 명세 (CURRENT_AGENT 업데이트, HANDOFF LOG 추가) ✅
  - 3.3: Content Guarantees 명세 (생성 콘텐츠 보장 사항) ✅
  - 3.4: 7개 에이전트별 Output Contract 상세 명세 ✅
  - 3.5: Output Contract 검증 규칙 ✅

- [x] **Section 4: 품질 기준 정의** (Quality Criteria Definition)
  - 4.1: VALIDATION_SCORE 계산 로직 (0-100점 척도) ✅
  - 4.2: 품질 차원 정의 (완성도, 정확도, 일관성, 학습 효과성) ✅
  - 4.3: 차원별 평가 기준 (각 차원당 25점 만점) ✅
  - 4.4: IMPROVEMENT_NEEDED 생성 규칙 (90점 미만 시) ✅
  - 4.5: 에이전트별 품질 기준 명세 (7개 에이전트) ✅

- [x] **Section 5: 계약 검증 방법** (Contract Validation Methods)
  - 5.1: Precondition 검증 알고리즘 (Fail-Fast 전략) ✅
  - 5.2: Postcondition 검증 알고리즘 ✅
  - 5.3: 섹션 존재 여부 검증 로직 ✅
  - 5.4: 섹션 구조 검증 로직 (헤더 레벨, 하위 섹션) ✅
  - 5.5: Work Status Markers 일치 검증 로직 ✅
  - 5.6: 검증 실패 시 오류 메시지 형식 ✅

- [x] **Section 6: 계약 템플릿 구조** (Contract Template Structure)
  - 6.1: YAML Frontmatter 구조 (agent_id, version, dependencies 등) ✅
  - 6.2: Markdown 본문 섹션 구조 (Metadata, Responsibility, Input/Output Contract 등) ✅
  - 6.3: 섹션별 필수/선택 항목 정의 ✅
  - 6.4: 템플릿 예시 (overview-writer 기준) ✅
  - 6.5: 템플릿 변형 규칙 (에이전트 타입별 차이점) ✅

- [x] **Section 7: 계약 검증 인터페이스** (Contract Validation Interface)
  - 7.1: 검증 함수 명세 (validate_preconditions, validate_postconditions 등) ✅
  - 7.2: 입력/출력 파라미터 정의 ✅
  - 7.3: 반환값 형식 (성공/실패, 오류 코드, 오류 메시지) ✅
  - 7.4: 오류 코드 정의 (E001-E999) ✅
  - 7.5: 검증 함수 호출 순서 ✅

- [x] **Section 8: 계약 변경 시나리오** (Contract Change Scenarios)
  - 8.1: 계약 버전 업그레이드 시나리오 (1.0 → 1.1, 1.x → 2.0) ✅
  - 8.2: Breaking Change 영향 분석 ✅
  - 8.3: 하위 호환성 유지 전략 ✅
  - 8.4: 계약 변경 시 검증 로직 업데이트 ✅
  - 8.5: 롤백 시나리오 ✅

**산출물**: `logical_design.md` - v1.0 완료 ✅
- 파일 크기: 약 2,676줄
- 섹션 수: 8개 메인 섹션 + 60개 이상 하위 섹션
- 다이어그램: 2개 (Mermaid)
- 예시: 30개 이상

---

## 질문 사항 (Phase 2.2)

### [Question 1] 품질 기준 상세도 수준

**질문**: VALIDATION_SCORE 계산 로직을 어느 수준까지 상세히 정의해야 할까요?

**옵션**:
- **A (높은 수준)**: 각 품질 차원별 세부 평가 항목까지 정의 (예: "Easy 설명 길이 200자 이상 → 5점")
- **B (중간 수준)**: 품질 차원과 평가 원칙만 정의 (예: "Easy 설명은 충분히 상세해야 함")
- **C (낮은 수준)**: 전체 점수만 정의, 세부 계산은 content-validator에 위임

**권장**: B (중간 수준)
- 이유: 너무 세밀하면 유연성 저하, 너무 추상적이면 일관성 저하

**[Answer 1]**: B (중간 수준) - 승인 ✅
- 품질 차원과 평가 원칙 정의
- 너무 세밀하면 유연성 저하, 너무 추상적이면 일관성 저하 방지

---

### [Question 2] 계약 검증 실패 처리

**질문**: Precondition 검증 실패 시 어떻게 처리해야 할까요?

**옵션**:
- **A (Fail-Fast)**: 즉시 실패, 파이프라인 중단 (Unit 2 domain_design.md Section 4.2 권장)
- **B (Fail-Soft)**: 경고 메시지 출력 후 계속 진행
- **C (Retry)**: 사전 조건 자동 수정 후 재시도

**권장**: A (Fail-Fast)
- 이유: Unit 1 설계 원칙과 일치, 에러 조기 발견

**[Answer 2]**: A (Fail-Fast) - 승인 ✅
- 즉시 실패, 파이프라인 중단
- Unit 1 설계 원칙과 일치

---

### [Question 3] 계약 템플릿 상세도

**질문**: 계약 템플릿에서 각 에이전트별로 얼마나 상세히 정의해야 할까요?

**옵션**:
- **A (7개 개별 템플릿)**: 각 에이전트마다 별도 템플릿 (총 7개)
- **B (타입별 템플릿)**: 유사한 에이전트 그룹화 (일반 에이전트, content-initiator, content-validator)
- **C (단일 템플릿)**: 하나의 범용 템플릿 + 변형 규칙

**권장**: B (타입별 템플릿)
- 이유: 유지보수성과 명확성의 균형

**[Answer 3]**: B (타입별 템플릿) - 승인 ✅
- 유사한 에이전트 그룹화 (일반 에이전트, content-initiator, content-validator)
- 유지보수성과 명확성의 균형

---

## 예상 산출물 (Phase 2.2)

1. **`logical_design.md`**: 논리적 설계 문서 (주요 산출물)
   - Section 1: 계약 데이터 구조
   - Section 2: 입력 계약 형식
   - Section 3: 출력 계약 형식
   - Section 4: 품질 기준 정의
   - Section 5: 계약 검증 방법
   - Section 6: 계약 템플릿 구조
   - Section 7: 계약 검증 인터페이스
   - Section 8: 계약 변경 시나리오

---

## 예상 소요 시간 (Phase 2.2)

| 단계 | 작업 내용 | 예상 시간 |
|------|-----------|-----------|
| Step 0 | 준비 작업 | 1-2시간 |
| Section 1 | 계약 데이터 구조 | 2-3시간 |
| Section 2 | 입력 계약 형식 | 3-4시간 |
| Section 3 | 출력 계약 형식 | 3-4시간 |
| Section 4 | 품질 기준 정의 | 3-4시간 |
| Section 5 | 계약 검증 방법 | 3-4시간 |
| Section 6 | 계약 템플릿 구조 | 2-3시간 |
| Section 7 | 계약 검증 인터페이스 | 2-3시간 |
| Section 8 | 계약 변경 시나리오 | 2-3시간 |
| **총계** | | **21-30시간** |

---

## 리스크 및 완화 방안 (Phase 2.2)

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| 품질 기준이 너무 주관적 | 높음 | 구체적 평가 차원 정의, 예시 포함 |
| 계약 검증 로직이 너무 복잡 | 중간 | 단계별 알고리즘으로 분해, 정규식 활용 |
| Unit 1 인터페이스와 불일치 | 높음 | Unit 1 헬퍼 함수 명세 참조 (domain_design.md Section 2.1.3) |
| 템플릿 구조가 에이전트별로 너무 다름 | 중간 | 공통 구조 추출, 변형 규칙 명시 |

---

## 성공 기준 (Phase 2.2)

1. **명세 완성도**: 모든 계약 형식이 구체적으로 정의됨 (필드, 타입, 제약사항)
2. **검증 가능성**: 정의된 검증 알고리즘으로 계약 준수 여부 판단 가능
3. **구현 독립성**: 논리적 설계만으로 검증 스크립트 구현 가능 (Phase 2.3)
4. **일관성**: Unit 1 설계와 용어/구조/원칙이 일치

---

## 다음 단계 (Phase 2.2 이후)

Phase 2.2 완료 후:
- **Phase 2.3: 물리적 설계 (Physical Design)** - 검증 스크립트 구현 설계
- **Phase 2.4: 구현 (Implementation)** - 실제 검증 스크립트 개발

**검토 요청**: 본 Phase 2.2 계획을 검토하고 질문에 답변해주세요.

---

## 질문 사항

### [Question 1] 계약 명세의 상세도 수준
**권장**: B (중간 수준)

**[Answer 1]**:
<!-- 답변을 여기에 작성하세요 -->

---

### [Question 2] 의존성 그래프 표현 방식
**권장**: C (Mermaid flowchart + 계약 요약)

**[Answer 2]**:
<!-- 답변을 여기에 작성하세요 -->

---

### [Question 3] 계약 버전 관리 범위
**권장**: A (개별 버전 관리)

**[Answer 3]**:
<!-- 답변을 여기에 작성하세요 -->

---

## 예상 산출물

1. **`domain_design.md`**: 도메인 모델 설계 문서 (주요 산출물)
   - Section 1: Bounded Context (7개 에이전트)
   - Section 2: Contract Template (표준 구조)
   - Section 3: Agent Contracts (7개 계약 명세)
   - Section 4: Contract Validation Strategy
   - Section 5: Dependency Analysis
   - Section 6: Versioning and Change Management
   - Section 7: Validation
   - Section 8: Summary and Next Steps

---

## 예상 소요 시간

| 단계 | 작업 내용 | 예상 시간 |
|------|-----------|-----------|
| Step 0 | 준비 작업 | 1-2시간 |
| Step 1 | Bounded Context 정의 | 2-3시간 |
| Step 2 | 계약 구조 표준 정의 | 2-3시간 |
| Step 3 | 7개 에이전트 계약 작성 | 4-6시간 |
| Step 4 | 계약 의존성 분석 | 2-3시간 |
| Step 5 | 검증 전략 정의 | 2-3시간 |
| Step 6 | 계약 변경 관리 | 2-3시간 |
| Step 7 | 도메인 모델 검증 | 2-3시간 |
| Step 8 | 문서 최종화 | 2-3시간 |
| **총계** | | **19-29시간** |

---

## 리스크 및 완화 방안

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| 기존 에이전트 동작과 계약 불일치 | 높음 | Step 0.3에서 현재 에이전트 프롬프트 철저히 분석 |
| 계약이 너무 엄격하여 유연성 저하 | 중간 | Preconditions는 엄격하게, Postconditions는 최소한으로 |
| 에이전트 간 의존성 복잡도 증가 | 중간 | 의존성 그래프로 시각화, 순환 의존 금지 |
| 계약 버전 관리 오버헤드 | 낮음 | Semantic Versioning 적용, Breaking Change 최소화 |

---

## 성공 기준

1. **명세 완성도**: 7개 에이전트의 모든 입출력 조건이 명시적으로 정의됨
2. **독립성 확보**: 계약만 보고 에이전트를 독립적으로 개발 가능
3. **변경 영향 분석**: 계약 변경 시 영향 받는 에이전트 자동 식별 가능
4. **검증 가능성**: Preconditions/Postconditions 검증 로직 설계 완료

---

## 다음 단계

본 계획 검토 및 승인 후:
- 질문 3개에 대한 답변 필요
- 승인 후 Step 0부터 순차 실행
- 각 Step 완료 시 체크박스 업데이트

**검토 요청**: 본 계획을 검토하고 질문에 답변해주세요.

---

## 참조 문서

- `docs/aidlc-docs/inception/units/unit-02-filter-contracts.md` - Unit 2 정의 및 범위
- `docs/aidlc-docs/construction/unit-01-pipe-mechanism/domain_design.md` - Pipe 메커니즘 도메인 모델
- `docs/aidlc-docs/specifications/work-status-markers-spec.md` - Work Status Markers 명세
- `docs/aidlc-docs/guides/agent-handoff-guide.md` - 에이전트 핸드오프 가이드
- `.claude/agents/*.md` - 현재 에이전트 프롬프트 (7개)

---

## Phase 2.3: 논리적 설계 기반 구현

### 작업 개요

**목적**: logical_design.md의 논리적 설계를 기반으로 7개 Filter의 실제 계약 문서를 생성합니다.

**산출물**: 7개 Filter 계약 문서 (각 `.md` 파일)

**핵심 원칙**:
- logical_design.md의 템플릿 구조 준수 (Section 6)
- domain_design.md의 에이전트별 계약 내용 반영 (Section 3)
- 현재 에이전트 프롬프트 (.claude/agents/*.md) 분석하여 실제 동작 반영
- YAML frontmatter + Markdown 본문 형식

**참조 문서**:
- `logical_design.md` (Unit 2) - 계약 템플릿 구조 (Section 6)
- `domain_design.md` (Unit 2) - 에이전트별 계약 명세 (Section 3)
- `.claude/agents/*.md` - 현재 에이전트 프롬프트 (7개)
- `work-status-markers-spec.md` (Unit 1) - Work Status Markers 명세
- `test/test-*.mjs` - 파서 테스트 (품질 기준 참조)
- `public/content/ko/*/01-*.md` - 샘플 콘텐츠 (섹션 구조 참조)

---

### Step 0: 준비 작업

- [ ] **Step 0.1**: contracts 디렉토리 생성
  - 디렉토리: `docs/aidlc-docs/specifications/contracts/`

- [ ] **Step 0.2**: 템플릿 구조 확인
  - logical_design.md Section 6 재분석 (YAML frontmatter + 9개 Markdown 섹션)
  - 에이전트 타입별 변형 규칙 파악 (일반/content-initiator/visualization-writer/content-validator)

- [ ] **Step 0.3**: 현재 에이전트 프롬프트 분석
  - 7개 에이전트 프롬프트 읽기 (.claude/agents/*.md)
  - 각 에이전트의 실제 입출력 동작 파악
  - domain_design.md Section 3과 비교하여 차이점 확인

**산출물**: 분석 완료

---

### Step 1: content-initiator 계약 생성

- [ ] **Step 1.1**: YAML frontmatter 작성
  - agent_id: content-initiator
  - version: 1.0
  - dependencies: [] (빈 배열)
  - bounded_context: Content Initialization

- [ ] **Step 1.2**: Responsibility 섹션 작성
  - 역할: Work Status Markers 초기화, frontmatter 생성

- [ ] **Step 1.3**: Input Contract 섹션 작성
  - File State: 파일 없음 또는 빈 파일
  - Work Status Markers: 없음 (특수 케이스)
  - Category Metadata: category.yaml 필요

- [ ] **Step 1.4**: Output Contract 섹션 작성
  - File State: Work Status Markers 초기화, frontmatter 생성
  - Work Status Markers: CURRENT_AGENT=overview-writer, STATUS=PENDING, START 엔트리

- [ ] **Step 1.5**: Preconditions/Postconditions 섹션 작성

- [ ] **Step 1.6**: Error Handling 섹션 작성

- [ ] **Step 1.7**: Examples 섹션 작성

- [ ] **Step 1.8**: Implementation 섹션 작성 (domain_design.md Section 2.1.3 참조)

**산출물**: `content-initiator-contract.md`

---

### Step 2: overview-writer 계약 생성

- [ ] **Step 2.1**: YAML frontmatter 작성
  - agent_id: overview-writer
  - version: 1.0
  - dependencies: [content-initiator]
  - bounded_context: Overview Generation

- [ ] **Step 2.2**: Responsibility 섹션 작성

- [ ] **Step 2.3**: Input Contract 섹션 작성
  - File State: frontmatter 존재
  - Work Status Markers: CURRENT_AGENT=overview-writer, STATUS=PENDING
  - Section Dependencies: None

- [ ] **Step 2.4**: Output Contract 섹션 작성
  - New Sections: # Overview
  - Work Status Markers: CURRENT_AGENT=concepts-writer, DONE 엔트리

- [ ] **Step 2.5**: Preconditions/Postconditions 섹션 작성

- [ ] **Step 2.6**: Error Handling 섹션 작성

- [ ] **Step 2.7**: Examples 섹션 작성

- [ ] **Step 2.8**: Improvement Mode 섹션 추가

- [ ] **Step 2.9**: Implementation 섹션 작성

**산출물**: `overview-writer-contract.md`

---

### Step 3: concepts-writer 계약 생성

- [ ] **Step 3.1**: YAML frontmatter 작성
  - agent_id: concepts-writer
  - version: 1.0
  - dependencies: [overview-writer]
  - bounded_context: Core Concepts Generation

- [ ] **Step 3.2**: Responsibility 섹션 작성

- [ ] **Step 3.3**: Input Contract 섹션 작성
  - File State: frontmatter + Overview 섹션 존재
  - Work Status Markers: CURRENT_AGENT=concepts-writer
  - Section Dependencies: # Overview

- [ ] **Step 3.4**: Output Contract 섹션 작성
  - New Sections: # Core Concepts (Easy/Normal/Expert 3단계)
  - Work Status Markers: CURRENT_AGENT=visualization-writer, DONE 엔트리

- [ ] **Step 3.5**: Preconditions/Postconditions 섹션 작성

- [ ] **Step 3.6**: Error Handling 섹션 작성

- [ ] **Step 3.7**: Examples 섹션 작성

- [ ] **Step 3.8**: Improvement Mode 섹션 추가

- [ ] **Step 3.9**: Implementation 섹션 작성

**산출물**: `concepts-writer-contract.md`

---

### Step 4: visualization-writer 계약 생성

- [ ] **Step 4.1**: YAML frontmatter 작성
  - agent_id: visualization-writer
  - version: 1.0
  - dependencies: [concepts-writer]
  - bounded_context: Visualization Component Generation

- [ ] **Step 4.2**: Responsibility 섹션 작성

- [ ] **Step 4.3**: Input Contract 섹션 작성 (특수 케이스)
  - File State: Core Concepts 섹션 존재
  - Work Status Markers: CURRENT_AGENT=visualization-writer
  - Section Dependencies: # Core Concepts

- [ ] **Step 4.4**: Output Contract 섹션 작성 (특수 케이스)
  - Modified Sections: Core Concepts (visualization 메타데이터 임베딩)
  - New Files: src/components/visualizations/*.tsx, index.ts 업데이트
  - Work Status Markers: CURRENT_AGENT=practice-writer, DONE 엔트리

- [ ] **Step 4.5**: Preconditions/Postconditions 섹션 작성

- [ ] **Step 4.6**: Error Handling 섹션 작성

- [ ] **Step 4.7**: Examples 섹션 작성

- [ ] **Step 4.8**: Critical Requirements 섹션 추가 (index.ts 업데이트 필수)

- [ ] **Step 4.9**: Improvement Mode 섹션 추가

- [ ] **Step 4.10**: Implementation 섹션 작성

**산출물**: `visualization-writer-contract.md`

---

### Step 5: practice-writer 계약 생성

- [ ] **Step 5.1**: YAML frontmatter 작성
  - agent_id: practice-writer
  - version: 1.0
  - dependencies: [concepts-writer]
  - bounded_context: Practice Content Generation

- [ ] **Step 5.2**: Responsibility 섹션 작성

- [ ] **Step 5.3**: Input Contract 섹션 작성
  - File State: Core Concepts 섹션 존재
  - Work Status Markers: CURRENT_AGENT=practice-writer
  - Section Dependencies: # Core Concepts

- [ ] **Step 5.4**: Output Contract 섹션 작성
  - New Sections: # Code Patterns, # Experiments
  - Work Status Markers: CURRENT_AGENT=quiz-writer, DONE 엔트리

- [ ] **Step 5.5**: Preconditions/Postconditions 섹션 작성

- [ ] **Step 5.6**: Error Handling 섹션 작성

- [ ] **Step 5.7**: Examples 섹션 작성

- [ ] **Step 5.8**: Improvement Mode 섹션 추가

- [ ] **Step 5.9**: Implementation 섹션 작성

**산출물**: `practice-writer-contract.md`

---

### Step 6: quiz-writer 계약 생성

- [ ] **Step 6.1**: YAML frontmatter 작성
  - agent_id: quiz-writer
  - version: 1.0
  - dependencies: [practice-writer]
  - bounded_context: Quiz Generation

- [ ] **Step 6.2**: Responsibility 섹션 작성

- [ ] **Step 6.3**: Input Contract 섹션 작성
  - File State: Overview, Core Concepts, Practice 섹션 존재
  - Work Status Markers: CURRENT_AGENT=quiz-writer
  - Section Dependencies: # Overview, # Core Concepts, # Code Patterns, # Experiments

- [ ] **Step 6.4**: Output Contract 섹션 작성
  - New Sections: # Quiz
  - Work Status Markers: CURRENT_AGENT=content-validator, DONE 엔트리

- [ ] **Step 6.5**: Preconditions/Postconditions 섹션 작성

- [ ] **Step 6.6**: Error Handling 섹션 작성

- [ ] **Step 6.7**: Examples 섹션 작성

- [ ] **Step 6.8**: Improvement Mode 섹션 추가

- [ ] **Step 6.9**: Implementation 섹션 작성

**산출물**: `quiz-writer-contract.md`

---

### Step 7: content-validator 계약 생성

- [ ] **Step 7.1**: YAML frontmatter 작성
  - agent_id: content-validator
  - version: 1.0
  - dependencies: [quiz-writer]
  - bounded_context: Content Quality Validation

- [ ] **Step 7.2**: Responsibility 섹션 작성

- [ ] **Step 7.3**: Input Contract 섹션 작성
  - File State: 모든 섹션 존재 (Overview, Core Concepts, Practice, Quiz)
  - Work Status Markers: CURRENT_AGENT=content-validator
  - Section Dependencies: 모든 섹션

- [ ] **Step 7.4**: Output Contract 섹션 작성 (특수 케이스: 조건부)
  - 90-100점: STATUS=COMPLETED, CURRENT_AGENT="", COMPLETE 엔트리
  - 90점 미만: IMPROVEMENT_NEEDED 생성, CURRENT_AGENT=[first_target], DONE 엔트리

- [ ] **Step 7.5**: Validation Criteria 섹션 작성 (4개 차원)
  - 완성도 (Completeness): 25점
  - 정확도 (Accuracy): 25점
  - 일관성 (Consistency): 25점
  - 학습 효과성 (Learning Effectiveness): 25점

- [ ] **Step 7.6**: Preconditions/Postconditions 섹션 작성

- [ ] **Step 7.7**: Error Handling 섹션 작성

- [ ] **Step 7.8**: Examples 섹션 작성 (90-100점, 90점 미만 2가지)

- [ ] **Step 7.9**: Implementation 섹션 작성

**산출물**: `content-validator-contract.md`

---

### Step 8: 계약 문서 교차 검증

- [ ] **Step 8.1**: 의존성 체인 검증
  - content-initiator → overview-writer → concepts-writer → visualization-writer → practice-writer → quiz-writer → content-validator
  - 각 dependencies 필드 확인

- [ ] **Step 8.2**: CURRENT_AGENT 핸드오프 일관성 검증
  - 각 에이전트의 Output Contract에서 CURRENT_AGENT 업데이트 값이 다음 에이전트와 일치하는지 확인

- [ ] **Step 8.3**: Section Dependencies 일관성 검증
  - 각 에이전트가 의존하는 섹션이 이전 에이전트의 Output Contract와 일치하는지 확인

- [ ] **Step 8.4**: HANDOFF LOG 이벤트 타입 일관성 검증
  - START, DONE, IMPROVE, FAILURE, SKIP, COMPLETE 사용 확인
  - Unit 1 명세와 일치 여부 확인

- [ ] **Step 8.5**: 용어 일관성 검증
  - Ubiquitous Language (Unit 1 domain_design.md Section 2) 준수 확인

**산출물**: 교차 검증 완료

---

### Step 9: 문서 최종화

- [ ] **Step 9.1**: 7개 계약 문서 파일명 확인
  - content-initiator-contract.md
  - overview-writer-contract.md
  - concepts-writer-contract.md
  - visualization-writer-contract.md
  - practice-writer-contract.md
  - quiz-writer-contract.md
  - content-validator-contract.md

- [ ] **Step 9.2**: 각 계약 문서 메타데이터 확인
  - 파일 인코딩: UTF-8
  - 줄바꿈: LF (\n)
  - YAML frontmatter 형식 검증

- [ ] **Step 9.3**: logical_design.md와 일치 여부 확인
  - Section 6 템플릿 구조 준수
  - Section 1.1.2 YAML frontmatter 스키마 준수
  - Section 2, 3 입출력 계약 형식 준수

- [ ] **Step 9.4**: domain_design.md와 일치 여부 확인
  - Section 3 (Agent Contracts) 내용 반영
  - Section 2.1.3 (Implementation References) 참조

**산출물**: 7개 계약 문서 최종 완성

---

## 질문 사항 (Phase 2.3)

### [Question 1] 계약 문서 생성 순서

**질문**: 7개 Filter 계약 문서를 어떤 순서로 생성할까요?

**옵션**:
- **A (순차적)**: content-initiator부터 content-validator까지 파이프라인 순서대로
- **B (병렬)**: 7개 동시에 생성 후 교차 검증
- **C (유형별)**: 일반 에이전트 (5개) → 특수 에이전트 (2개: content-initiator, content-validator)

**권장**: A (순차적)
- 이유: 각 에이전트가 이전 에이전트를 참조하므로 순차적 생성이 의존성 관리에 유리

**[Answer 1]**:
<!-- 답변을 여기에 작성하세요 -->
- 순차적 실행
---

### [Question 2] 현재 에이전트 프롬프트와의 불일치 처리

**질문**: 현재 .claude/agents/*.md 프롬프트와 logical_design.md/domain_design.md 계약 사이에 차이가 발견되면 어떻게 처리할까요?

**옵션**:
- **A (계약 우선)**: logical_design.md/domain_design.md 계약을 우선하고, 차이점은 문서화만
- **B (프롬프트 우선)**: 현재 동작하는 프롬프트를 기준으로 계약 수정
- **C (혼합)**: 케이스별로 판단 (중요한 계약은 A, 구현 세부사항은 B)

**권장**: A (계약 우선)
- 이유: Phase 2.1, 2.2에서 승인받은 설계를 존중, 차이점은 implementation note로 문서화

**[Answer 2]**:
<!-- 답변을 여기에 작성하세요 -->
- 계약을 우선하되 실제 파싱 로직을 최우선해야 됩니다. 왜냐하면 토픽 md 파일이 정상이면 화면에 정상 렌더링 되기 때문입니다.
---

### [Question 3] Examples 섹션 상세도

**질문**: 각 계약 문서의 Examples 섹션을 어느 수준까지 상세히 작성할까요?

**옵션**:
- **A (간략)**: Input/Output Work Status Markers만 (Before/After)
- **B (중간)**: Work Status Markers + 핵심 섹션 구조
- **C (상세)**: Work Status Markers + 전체 마크다운 예시 (실제 콘텐츠 포함)

**권장**: B (중간)
- 이유: 계약 이해에 충분하면서도 과도하게 길지 않음

**[Answer 3]**:
<!-- 답변을 여기에 작성하세요 -->
- 권장안에 동의합니다. 공식문서 가이드도 참고하세요. (<https://docs.claude.com/en/docs/claude-code/sub-agents>)
---

## 예상 산출물 (Phase 2.3)

1. `docs/aidlc-docs/specifications/contracts/content-initiator-contract.md`
2. `docs/aidlc-docs/specifications/contracts/overview-writer-contract.md`
3. `docs/aidlc-docs/specifications/contracts/concepts-writer-contract.md`
4. `docs/aidlc-docs/specifications/contracts/visualization-writer-contract.md`
5. `docs/aidlc-docs/specifications/contracts/practice-writer-contract.md`
6. `docs/aidlc-docs/specifications/contracts/quiz-writer-contract.md`
7. `docs/aidlc-docs/specifications/contracts/content-validator-contract.md`

**총 7개 파일**

**예상 분량** (파일당):
- YAML frontmatter: 10줄
- Markdown 본문: 200-400줄
- 총: 210-410줄 × 7개 = 1,470-2,870줄

---

## 예상 소요 시간 (Phase 2.3)

| 단계 | 작업 내용 | 예상 시간 |
|------|-----------|-----------|
| Step 0 | 준비 작업 | 1시간 |
| Step 1 | content-initiator 계약 | 1-2시간 |
| Step 2 | overview-writer 계약 | 1-2시간 |
| Step 3 | concepts-writer 계약 | 1-2시간 |
| Step 4 | visualization-writer 계약 | 1-2시간 |
| Step 5 | practice-writer 계약 | 1-2시간 |
| Step 6 | quiz-writer 계약 | 1-2시간 |
| Step 7 | content-validator 계약 | 1-2시간 |
| Step 8 | 교차 검증 | 1-2시간 |
| Step 9 | 문서 최종화 | 1시간 |
| **총계** | | **10-17시간** |

---

## 리스크 및 완화 방안 (Phase 2.3)

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| 현재 프롬프트와 설계 불일치 | 높음 | Question 2로 처리 방침 결정, 차이점 문서화 |
| 템플릿 변형 규칙 해석 오류 | 중간 | logical_design.md Section 6.5 반복 검토 |
| 의존성 체인 오류 | 높음 | Step 8에서 철저히 교차 검증 |
| 예시 과다/과소 | 낮음 | Question 3으로 상세도 결정 |

---

## 성공 기준 (Phase 2.3)

1. **완전성**: 7개 Filter 계약 문서 모두 생성
2. **일관성**: logical_design.md Section 6 템플릿 구조 100% 준수
3. **정확성**: domain_design.md Section 3 계약 내용 반영
4. **검증 가능성**: Step 8 교차 검증 통과
5. **파일 형식**: UTF-8, LF, YAML frontmatter 유효

---

## 검토 및 승인 요청

위 Phase 2.3 계획을 검토해 주시고, 다음 사항에 대해 답변 부탁드립니다:

1. **Question 1-3 답변**: 각 질문에 대한 선택 (A/B/C) 또는 다른 의견
2. **단계 추가/제거**: 누락된 단계가 있거나 불필요한 단계가 있나요?
3. **우선순위 조정**: 특정 단계를 먼저 수행해야 하나요?
4. **승인**: 이 계획대로 진행해도 될까요?

승인 후 Step 0부터 순차적으로 실행하겠습니다.
