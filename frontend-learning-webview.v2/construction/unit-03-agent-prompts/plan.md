# Unit 3: Agent Prompts 개선 - Construction Phase 계획

## 프로젝트 개요

**목표**: 에이전트 프롬프트를 Unit 1(Pipe 명세)과 Unit 2(Filter 계약)를 반영하여 개선하고, 명확한 I/O 명세와 책임 경계를 프롬프트에 명시한다.

**단계**: Phase 2.1 - DDD 경량화 방식으로 도메인 모델 설계

**참조 문서**:
- `docs/aidlc-docs/inception/units/unit-03-agent-prompts.md` (Unit 3 정의)
- `docs/aidlc-docs/construction/unit-01-pipe-mechanism/domain_design.md` (Pipe 메커니즘)
- `docs/aidlc-docs/construction/unit-02-filter-contracts/domain_design.md` (Filter 계약)
- `docs/aidlc-docs/specifications/work-status-markers-spec.md` (Work Status Markers 명세)

---

## Phase 2.1: DDD 도메인 모델 설계

### 작업 개요

**목적**: Unit 3 요구사항을 바탕으로 Agent Prompts 개선의 도메인 모델을 DDD 경량화 방식으로 설계합니다.

**산출물**: `domain_design.md` (도메인 설계 문서)

**핵심 설계 원칙**:
- 프롬프트를 Filter의 실행 명세로 정의 (Published Language)
- I/O Contract를 프롬프트에 통합하는 패턴 정의
- 에이전트 책임 경계 명확화 (DO/DO NOT)
- 오류 처리 지침 표준화

---

### Step 0: 준비 작업

- [x] **Step 0.1**: Unit 3 Inception 문서 재분석 ✅
  - 목적: 프롬프트 개선을 통한 에이전트 동작 표준화
  - 범위: 7개 에이전트 프롬프트 업데이트, 템플릿 작성, 검증 체크리스트
  - 현재 문제점: 입출력 명세 산재/누락, Work Status Markers 조작 불일치, 책임 경계 모호
  - In Scope/Out of Scope 명확화
  - **분석 완료**: 390줄 문서 전체 검토, 4개 질문 모두 결정됨 확인

- [x] **Step 0.2**: Construction 폴더 준비 ✅
  - `docs/aidlc-docs/construction/unit-03-agent-prompts/` 생성 완료
  - plan.md 이미 작성됨 (19,801 bytes)

- [x] **Step 0.3**: 현재 시스템 분석 ✅
  - `.claude/agents/*.md` 에이전트 프롬프트 분석 (7개 완료)
  - 각 프롬프트의 구조, 스타일, 완성도 평가 완료
  - 프롬프트 간 일관성 분석 완료 (용어, 구조, 형식)
  - 개선 필요 영역 식별 완료
  - **분석 결과**:
    - content-initiator: 1.5KB (가장 간결, Work Status Markers 초기화 전용)
    - overview-writer: 7.6KB (v5.0.0, 구조 잘 정리됨)
    - concepts-writer: 10KB (v6.0.0, 가장 상세함)
    - visualization-writer: 9.4KB (v1.0.0, React 컴포넌트 생성 전용)
    - practice-writer: 7.6KB (v7.0.0, 높은 버전, 실습 콘텐츠)
    - quiz-writer: 8.8KB (v3.0.0, 6가지 퀴즈 타입)
    - content-validator: 8.2KB (v1.0.0, 검증 및 개선 지시)

- [x] **Step 0.4**: Unit 1, Unit 2 의존성 확인 ✅
  - **Unit 1 Pipe 메커니즘** (분석 완료):
    - Work Status Markers 명세 (`work-status-markers-spec.md`, 858줄)
    - Handoff Protocol (`agent-handoff-guide.md`, 982줄)
    - HANDOFF LOG 이벤트 타입: START, DONE, IMPROVE, FAILURE, SKIP, COMPLETE
    - ISO 8601 타임스탬프 형식: `YYYY-MM-DDTHH:MM:SS+09:00`
    - Precondition/Postcondition 체크리스트
    - 5단계 재시작 메커니즘 알고리즘
  - **Unit 2 Filter 계약** (분석 완료):
    - 7개 에이전트 계약 문서 (`contracts/*.md`)
    - Input Contract: File State, Work Status Markers, Section Dependencies
    - Output Contract: File Modifications, WSM Updates, Content Guarantees
    - Preconditions/Postconditions 명확한 정의
    - Fail-Fast 오류 처리 패턴
    - Example 1: Normal Flow, Example 2: Improvement Mode, Example 3: Precondition Failure

- [x] **Step 0.5**: Claude Code 공식 문서 검토 ✅
  - Sub-agents 작성 Best Practices: https://docs.claude.com/en/docs/claude-code/sub-agents
  - 프롬프트 구조: Markdown + YAML frontmatter
  - **핵심 원칙**:
    - 단일 명확한 책임 (Focused subagents)
    - 상세한 지시사항 제공 (Detailed instructions)
    - 구체적 예시 및 제약사항 포함
    - 도구 접근 제한 (최소 권한)
  - **권장 스타일**:
    - 명확하고 직접적인 언어
    - 단계별 지시 (numbered steps)
    - 체크리스트 형식
    - 구체적 출력 예시
    - 우선순위별 피드백

**산출물**: Step 0 준비 작업 전체 완료 ✅

---

### Step 1-8: domain_design.md 작성

**통합 작업**: 모든 단계를 domain_design.md 하나의 문서로 통합 작성

- [x] **Section 1: 프롬프트 도메인 개요 (Prompt Domain Overview)** ✅
  - 1.1: 프롬프트의 역할 정의 완료
    - Filter 실행 명세로서의 프롬프트
    - Published Language로서의 프롬프트
    - 자기 문서화 (Self-documenting) 에이전트
  - 1.2: 프롬프트 아키텍처 원칙 완료
    - 단일 책임 원칙 (Single Responsibility)
    - 명시적 계약 (Explicit Contract)
    - 오류 조기 발견 (Fail-Fast)
    - 일관된 용어 (Ubiquitous Language)
  - 1.3: 프롬프트와 계약의 관계 완료
    - 계약(Contract): What (무엇을 해야 하는가)
    - 프롬프트(Prompt): How (어떻게 해야 하는가)
    - 계약 → 프롬프트 변환 패턴
  - 1.4: 프롬프트 품질 기준 완료
    - 완전성: 모든 필수 정보 포함
    - 명확성: 모호함 없는 지시
    - 일관성: 7개 프롬프트 간 구조/용어 통일
    - 검증 가능성: 자동 검증 가능한 형식

- [x] **Section 2: 프롬프트 템플릿 구조 (Prompt Template Structure)** ✅
  - 2.1: YAML Frontmatter 구조 완료
    - name, version, description, tools, model
    - Unit 2 계약 frontmatter와의 관계
  - 2.2: Markdown 본문 섹션 구조 완료
    - 10개 표준 섹션 정의 (Role, Input, Output, Execution, Constraints, Error, Handoff, Quality, Examples, References)
    - 각 섹션별 상세 템플릿 및 예시
  - 2.3: 섹션별 작성 가이드라인 완료
    - 필수 섹션 (8개), 권장 섹션 (2개)
    - 섹션별 권장 길이 (200-400줄 목표 달성)
  - 2.4: 프롬프트 타입별 변형 완료
    - 일반 에이전트 vs 특수 에이전트
    - content-initiator, visualization-writer, content-validator 특수성 명시

- [x] **Section 3: I/O Contract 통합 패턴 (I/O Contract Integration Patterns)** ✅
  - 3.1: Contract-to-Prompt 변환 원칙 완료
    - 변환의 목적 (What → How)
    - 변환 범위 결정 (Question 1 답변: 요약 + 참조)
    - 변환 시 일관성 유지 (용어, 구조, 형식)
  - 3.2: Input Contract 프롬프트 표현 완료
    - File State → 프롬프트 지시문 변환
    - Work Status Markers → 검증 단계 변환
    - Section Dependencies → 명확화
  - 3.3: Output Contract 프롬프트 표현 완료
    - File Modifications → 작업 단계 변환
    - Work Status Markers Updates → 업데이트 지시문 변환
    - Content Guarantees → 품질 기준 변환
  - 3.4: Preconditions/Postconditions 검증 지시 완료
    - Preconditions → 체크리스트 생성 (PC-1, PC-2, ...)
    - Postconditions → 검증 단계 명시 (PO-1, PO-2, ...)
    - 표준 형식 정의 (ID, Check, If fails, Output, HANDOFF LOG, EXIT 1)
  - 3.5: 변환 패턴 요약 완료
    - 계약 요소 → 프롬프트 섹션 매핑표
    - 4단계 변환 워크플로우
    - 변환 시 주의사항 (DO/DO NOT)

- [x] **Section 4: 에이전트 책임 경계 (Agent Responsibility Boundaries)** ✅
  - 4.1: Bounded Context 기반 책임 정의 완료
    - 각 에이전트의 Bounded Context (7개 Context 테이블)
    - Context 경계 내 허용 작업 (에이전트별 ✅/❌ 명시)
    - Context 경계 외 금지 작업 (5가지 절대 금지 사항)
    - 경계 위반 예시 및 수정
  - 4.2: DO/DO NOT 표준화 완료
    - DO 섹션 작성 패턴 (구체적 동사, 범위, 조건)
    - DO NOT 섹션 작성 패턴 (명확한 금지, 이유, 대안)
    - 공통 금지 사항 (모든 에이전트 공통 DO NOT 템플릿)
  - 4.3: 에이전트 간 협업 규칙 완료
    - 이전 에이전트 출력물 사용 방법 (READ-ONLY 패턴)
    - 다음 에이전트로 핸드오프 방법 (CURRENT_AGENT 업데이트 절차)
    - 개선 모드에서의 협업 (IMPROVEMENT_NEEDED 기반 순환 처리)

- [x] **Section 5: Work Status Markers 조작 표준화 (WSM Manipulation Standards)** ✅
  - 5.1: 마커 조작 책임 명확화 완료
    - 에이전트 vs Orchestration 책임 분리 (책임 매트릭스)
    - 에이전트 책임: DONE, IMPROVE, SKIP, COMPLETE 기록
    - Orchestration 책임: START, FAILURE 기록
    - FAILURE vs 에이전트 내부 EXIT 1 비교
  - 5.2: HANDOFF LOG 기록 패턴 완료
    - 이벤트 타입별 기록 형식 (6개 타입 상세)
    - 타임스탬프 형식 (ISO 8601: YYYY-MM-DDTHH:MM:SS+09:00)
    - 메시지 작성 가이드라인 (에이전트별 패턴)
  - 5.3: CURRENT_AGENT 업데이트 규칙 완료
    - 정상 완료 시: Next Agent Mapping
    - 개선 모드: IMPROVEMENT_NEEDED 처리 로직
    - 최종 완료 시 (content-validator): 빈 문자열
  - 5.4: STATUS 업데이트 규칙 완료
    - STATUS 전이 다이어그램 (정상/실패/개선)
    - 에이전트별 STATUS 업데이트 패턴
    - STATUS와 CURRENT_AGENT 일관성 규칙

- [x] **Section 6: 오류 처리 표준화 (Error Handling Standardization)** ✅
  - 6.1: Fail-Fast 전략 완료
    - 핵심 원칙 5가지 정의 (조기 검증, 즉시 중단, 명확한 오류, 안전한 상태, 감사 기록)
    - Precondition 검증 템플릿 (PC-N 식별자 체계)
    - Fail-Fast 흐름도 및 실패 기록 형식
  - 6.2: 오류 시나리오 분류 완료
    - Precondition 실패 (4가지 시나리오)
    - 작업 중 오류 (3가지 시나리오)
    - Postcondition 실패 (4가지 시나리오)
  - 6.3: 오류 메시지 형식 표준화 완료
    - 표준 형식: `ERROR: [오류 타입] - [상세 설명]`
    - 오류 타입 6개 분류 (Precondition/Postcondition failed, Content generation failed, File write error, Parsing failed, Validation failed)
    - 에이전트별 오류 메시지 패턴 정의 (7개 전체)
  - 6.4: 오류 복구 지침 완료
    - 에이전트 원칙: 복구 시도 없음 (Fail-Fast)
    - Orchestration 책임: 4가지 복구 전략 (자동 재시도, 조건부 재시도, 파일 복구, 복구 불가 에러 처리)

- [x] **Section 7: UTF-8 인코딩 보장 전략 (UTF-8 Encoding Strategy)** ✅
  - 7.1: 한글 콘텐츠 작성 요구사항 완료
    - 필수 요구사항 4가지 (UTF-8 인코딩, 한글 정확성, 일관성, 특수문자 처리)
    - 금지 사항 5가지 (깨짐 문자, 잘못된 인코딩, 혼합 인코딩, ASCII 변환, HTML 엔티티)
    - 품질 기준 (Acceptance Criteria 4개)
  - 7.2: 프롬프트 지시문 완료
    - 표준 UTF-8 지시문 템플릿 (모든 에이전트 공통, CRITICAL 태그)
    - 에이전트별 맞춤 지시문 (7개 에이전트 각각)
    - 오류 감지 지시문 (Self-Check 체크리스트)
  - 7.3: Orchestration 환경 설정 완료
    - 환경 변수 (LANG, LC_ALL, LC_CTYPE, PYTHONIOENCODING)
    - 사후 검증 함수 (verify_utf8_encoding)
    - 오류 처리 (run_agent_with_encoding_check)
  - 7.4: 검증 및 오류 감지 완료
    - 자동 검증 체크리스트 (validate_encoding 스크립트)
    - 오류 감지 패턴 4가지 (정규식 테이블)
    - 인코딩 오류 메시지 형식 (에이전트별 예시)
    - 사후 검증 통합 (content-generator-v6.sh 예시)
  - 7.5: 실전 예시 완료 (정상/오류/복구불가 케이스)

- [x] **Section 8: 7개 에이전트 프롬프트 설계 (7 Agent Prompt Designs)** ✅
  - 8.1: content-initiator 프롬프트 설계 완료 (상세)
    - 역할: 파일 초기화, frontmatter + Work Status Markers 생성
    - I/O Contract 요약, Execution Instructions (7단계)
    - DO/DO NOT, Constraints (UTF-8, 파일 덮어쓰기 방지)
    - Error Handling (Precondition/Postcondition), Handoff Protocol
    - 예시: Normal Flow (category.yaml → 파일 생성)
  - 8.2: overview-writer 프롬프트 설계 완료 (상세)
    - 역할: Overview 섹션 작성 (50-100줄, 한글 콘텐츠)
    - Section Structure (Introduction, 핵심 특징, 실무 영향)
    - Execution Instructions (7단계), Quality Standards
    - Improvement Mode 지원
    - 예시: Normal Flow (var 키워드의 문제점)
  - 8.3: concepts-writer 프롬프트 설계 완료 (상세)
    - **핵심**: Easy/Normal/Expert 3단계 난이도 설명
    - Difficulty Level Guidelines (각 레벨별 상세 가이드)
      - Easy: 일상 비유, 이모지, 절대 코드 없음
      - Normal: 기술 용어, 간단한 코드 예시 (5-10줄)
      - Expert: ECMAScript 명세, 내부 메커니즘, 고급 코드
    - needs_visualization 플래그 결정
    - 3-Level Quality Standards, 예시 (var 키워드)
  - 8.4: visualization-writer 프롬프트 설계 완료 (상세)
    - **조건부 실행**: needs_visualization true/false
    - SKIP path vs Generate path
    - React 컴포넌트 생성 (.tsx, Tailwind CSS)
    - **CRITICAL**: index.ts export 업데이트 필수
    - 예시: SKIP path, Generate path
  - 8.5: practice-writer 프롬프트 설계 완료 (간략)
    - Code Patterns 3-5개, Experiments 2-4개
    - 한글 설명 UTF-8
  - 8.6: quiz-writer 프롬프트 설계 완료 (간략)
    - 6가지 퀴즈 타입, 8-12개 문제
    - 난이도 분포 준수
  - 8.7: content-validator 프롬프트 설계 완료 (간략)
    - 5단계 검증 (Overview 20점, Concepts 30점, Practice 20점, Quiz 20점, UTF-8 10점)
    - Scoring Rubric (90점 기준)
    - IMPROVEMENT_NEEDED 생성 (90점 미만)

- [x] **Section 9: 프롬프트 검증 전략 (Prompt Validation Strategy)** ✅
  - 9.1: 정적 검증 완료 (Static Validation)
    - Frontmatter 검증 (name, version, description, tools, model)
    - 필수 섹션 검증 (7개 공통 + 에이전트별 특수 섹션)
    - 프롬프트 길이 검증 (150-500줄, 권장 200-400줄)
  - 9.2: 내용 검증 완료 (Content Validation)
    - 섹션 비어있지 않은지 검증 (최소 3줄)
    - UTF-8 지시문 존재 검증 (CRITICAL 키워드, 한글/Korean)
    - DO/DO NOT 섹션 검증 (최소 3개씩)
  - 9.3: 의미 검증 완료 (Semantic Validation - 수동)
    - Unit 2 계약 일치성 (Input/Output Contract, Error Handling)
    - 용어 일관성 (Ubiquitous Language, 표준 표현 테이블)
    - Handoff Protocol 일치성 (파이프라인 순서)
  - 9.4: 통합 검증 스크립트 완료
    - scripts/lib/validate-prompts.sh 명세
    - CI/CD 통합 (GitHub Actions 워크플로우)
  - 9.5: 검증 오류 코드 및 메시지 완료
    - 오류 코드 체계 (E001-E005 심각, W001-W006 경고)
    - 표준 오류 메시지 형식

- [x] **Section 10: 프롬프트 버전 관리 (Prompt Versioning)** ✅
  - 10.1: 버전 관리 전략 완료
    - 채택: backup/agents/v1.0/ 디렉터리 기반 (Question 4)
    - SemVer 버전 번호 (X.Y.Z)
  - 10.2: 백업 절차 완료
    - 프롬프트 업데이트 시 백업 스크립트
    - README.md 업데이트
  - 10.3: 롤백 전략 완료
    - 롤백 시나리오 3가지
    - 롤백 절차 (백업 복원 → Git 커밋 → 검증)
  - 10.4: Breaking Changes 판단 기준 완료
    - Breaking Change 예시 (I/O Contract 변경 등)
    - Non-Breaking Change 예시 (설명 개선, 오타 수정 등)

- [x] **Section 11: 프롬프트 작성 가이드 (Prompt Writing Guide)** ✅
  - 11.1: 새 에이전트 추가 시 완료
    - Step 1: Unit 2 계약 작성
    - Step 2: 프롬프트 템플릿 생성
    - Step 3: Section 3-7 원칙 적용
    - Step 4: 검증
  - 11.2: 기존 프롬프트 수정 시 완료
    - 체크사항 (Unit 2 계약 일치, 영향 분석, Breaking Change 판단)
    - 수정 후 (검증, 테스트, 품질 확인, 백업)
  - 11.3: 프롬프트 테스트 방법 완료
    - 단일 에이전트 테스트
    - 전체 파이프라인 테스트
    - 품질 검증

- [x] **Section 12: Summary and Next Steps** ✅
  - 12.1: 핵심 설계 결정 사항 요약 완료
    - Architectural Decisions (AD-1 ~ AD-5)
    - Design Decisions (DD-1 ~ DD-5)
  - 12.2: Phase 2.2 준비사항 완료
    - 작업 내용 4가지 (템플릿 구체화, 검증 스크립트, 프롬프트 초안, 일관성 검증)
    - 산출물 (logical_design.md, 검증 스크립트, 7개 프롬프트 초안)
  - 12.3: Open Questions 완료
    - 4가지 미해결 질문 (Context Length, 반복 횟수, 컴포넌트 재사용, Backward Compatibility)

**산출물**: `domain_design.md` - v1.0 ✅

---

## Phase 2.2: 논리적 설계 (Logical Design)

### 작업 개요

**목적**: Phase 2.1 도메인 모델을 바탕으로 프롬프트의 논리적 데이터 구조, 검증 알고리즘, 인터페이스를 구체적으로 설계합니다.

**산출물**: `logical_design.md` (논리적 설계 문서)

**핵심 설계 원칙** (Unit 1, 2 참조):
- 코드 스니펫 생성 금지 (명세만 작성)
- 표 + Mermaid 다이어그램으로 구조 표현
- 단계별 설명 + 정규식 패턴으로 알고리즘 표현
- API 문서 형식으로 인터페이스 명세

**참조 문서**:
- `domain_design.md` (Unit 3) - 6,997줄, 12개 섹션
- `logical_design.md` (Unit 1) - Pipe Mechanism 논리적 설계
- `logical_design.md` (Unit 2) - Filter Contracts 논리적 설계
- `docs/aidlc-docs/specifications/contracts/*.md` - 7개 에이전트 계약

---

### Step 0: 준비 작업

- [x] **Step 0.1**: Unit 1, 2 logical_design.md 구조 분석 ✅
  - Unit 1 목차 8개 섹션 파악 (4,157줄)
  - Unit 2 목차 8개 섹션 파악 (2,662줄)
  - 공통 패턴 도출 (데이터 구조 → 알고리즘 → 인터페이스 → 검증)

- [x] **Step 0.2**: Unit 3 domain_design.md 핵심 개념 정리 ✅
  - Section 2: 프롬프트 템플릿 구조 (10개 섹션)
  - Section 3: I/O Contract 통합 패턴
  - Section 5: Work Status Markers 조작 표준화
  - Section 8: 7개 에이전트 프롬프트 설계

- [x] **Step 0.3**: 논리적 설계 범위 결정 ✅
  - In Scope: 프롬프트 데이터 구조, I/O Contract 형식, 검증 알고리즘, WSM 조작 명세
  - Out of Scope: 완전한 프롬프트 구현 (Phase 2.3)

---

### Step 1: logical_design.md 작성

**통합 작업**: 모든 섹션을 logical_design.md 하나의 문서로 통합 작성

- [x] **Section 1: 프롬프트 데이터 구조 (Prompt Data Structure)** ✅
  - 1.1: YAML Frontmatter 스키마
    - 필드 정의 (name, version, description, tools, model)
    - 데이터 타입 및 제약사항
    - 정규식 패턴
  - 1.2: Markdown 본문 섹션 구조
    - 10개 표준 섹션 명세 (Role, Input, Output, Execution, Constraints, Error, Handoff, Quality, Examples, References)
    - 각 섹션의 데이터 형식
  - 1.3: 프롬프트 파일 형식
    - 파일 인코딩 (UTF-8)
    - 줄바꿈 형식 (LF)
    - 파일 구조 다이어그램 (Mermaid)

- [x] **Section 2: I/O Contract 통합 형식 (I/O Contract Integration Format)** ✅
  - 2.1: Input Contract 표현 형식
    - File State 표현 방법 (표 형식)
    - Work Status Markers 표현 방법
    - Section Dependencies 표현 방법
  - 2.2: Output Contract 표현 형식
    - File Modifications 표현 방법
    - Work Status Markers Updates 표현 방법
    - Content Guarantees 표현 방법
  - 2.3: Preconditions/Postconditions 체크리스트 형식
    - 체크리스트 항목 구조 (ID, Check, If fails, Output, HANDOFF LOG, EXIT)
    - 체크리스트 템플릿
  - 2.4: 계약-프롬프트 매핑 테이블
    - Unit 2 계약 요소 → Unit 3 프롬프트 섹션 매핑

- [x] **Section 3: Execution Instructions 알고리즘 (Execution Instructions Algorithm)** ✅
  - 3.1: 단계별 지시문 형식
    - Step 번호 체계
    - 각 Step 구성 요소 (동작, 조건, 출력)
  - 3.2: 조건부 실행 패턴
    - if-then-else 표현 방법
    - needs_visualization 플래그 기반 분기 (visualization-writer)
  - 3.3: 반복 패턴
    - IMPROVEMENT_NEEDED 기반 반복 (개선 모드)
  - 3.4: Execution Instructions 예시
    - content-initiator 7단계 알고리즘
    - overview-writer 7단계 알고리즘

- [x] **Section 4: Work Status Markers 조작 명세 (WSM Manipulation Specification)** ✅
  - 4.1: CURRENT_AGENT 업데이트 알고리즘
    - 정상 완료 시 업데이트 로직
    - 개선 모드 업데이트 로직
    - 최종 완료 시 (빈 문자열)
  - 4.2: STATUS 업데이트 알고리즘
    - STATUS 전이 다이어그램 (Mermaid)
    - 전이 조건 및 액션
  - 4.3: HANDOFF LOG 기록 형식
    - 6가지 EVENT_TYPE 형식 (START, DONE, IMPROVE, SKIP, FAILURE, COMPLETE)
    - 타임스탬프 형식 (ISO 8601)
    - 메시지 템플릿
  - 4.4: UPDATED 타임스탬프 갱신 로직

- [x] **Section 5: 오류 처리 알고리즘 (Error Handling Algorithm)** ✅
  - 5.1: Fail-Fast 전략 알고리즘
    - Precondition 검증 플로우차트 (Mermaid)
    - 검증 실패 시 처리 단계
  - 5.2: 오류 메시지 형식
    - 표준 형식: `ERROR: [오류 타입] - [상세 설명]`
    - 6가지 오류 타입 정의
  - 5.3: HANDOFF LOG 실패 기록 형식
    - [FAILURE] 엔트리 형식
    - EXIT 1 호출 시점
  - 5.4: 에이전트별 오류 처리 패턴
    - 7개 에이전트 각각의 오류 시나리오

- [x] **Section 6: 프롬프트 검증 알고리즘 (Prompt Validation Algorithm)** ✅
  - 6.1: 정적 검증 알고리즘
    - Frontmatter 검증 단계
    - 필수 섹션 검증 단계
    - 프롬프트 길이 검증 (150-500줄)
  - 6.2: 내용 검증 알고리즘
    - 섹션 비어있지 않은지 검증 (최소 3줄)
    - UTF-8 지시문 존재 검증 (CRITICAL 키워드)
    - DO/DO NOT 섹션 검증 (최소 3개씩)
  - 6.3: 의미 검증 체크리스트 (수동)
    - Unit 2 계약 일치성 체크리스트
    - 용어 일관성 체크리스트 (Ubiquitous Language)
    - Handoff Protocol 일치성 체크리스트
  - 6.4: 검증 오류 코드 체계
    - E001-E005 (심각), W001-W006 (경고)
    - 오류 메시지 템플릿

- [x] **Section 7: 난이도 레벨 표준 (Difficulty Level Standards)** ✅
  - 7.1: Easy 레벨 명세
    - 대상 독자
    - 작성 스타일 규칙
    - 금지 사항 (코드 블록 없음)
    - 길이 기준 (3-5 paragraphs)
  - 7.2: Normal 레벨 명세
    - 대상 독자
    - 작성 스타일 규칙
    - 코드 예시 기준 (5-10줄)
    - 길이 기준 (5-10 paragraphs)
  - 7.3: Expert 레벨 명세
    - 대상 독자
    - 작성 스타일 규칙 (ECMAScript 명세 참조)
    - 코드 예시 기준 (고급 예시)
    - 길이 기준 (5-10 paragraphs)
  - 7.4: 난이도별 품질 기준 비교 테이블

- [x] **Section 8: 7개 에이전트 프롬프트 명세 요약 (7 Agent Prompts Specification Summary)** ✅
  - 8.1: content-initiator 명세 요약
    - I/O Contract 요약
    - Execution Instructions 핵심 알고리즘
    - 특수 제약사항
  - 8.2: overview-writer 명세 요약
  - 8.3: concepts-writer 명세 요약 (3-Level Difficulty 포함)
  - 8.4: visualization-writer 명세 요약 (조건부 실행 포함)
  - 8.5: practice-writer 명세 요약
  - 8.6: quiz-writer 명세 요약
  - 8.7: content-validator 명세 요약 (90-Point Threshold 포함)

**산출물**: `logical_design.md` - v1.0 ✅ (2,543줄 완성)

---

### Step 2: 검증 및 검토

- [x] **Step 2.1**: Unit 1, 2 logical_design.md와 일관성 검증 ✅
  - 문서 구조 일관성 (목차, 섹션 형식)
  - 용어 일관성 (Ubiquitous Language)
  - 다이어그램 스타일 일관성

- [x] **Step 2.2**: domain_design.md 대비 완전성 검증 ✅
  - domain_design.md 12개 섹션 모두 반영되었는지 확인
  - 누락된 개념이 없는지 확인

- [x] **Step 2.3**: 검토 요청 및 승인 대기 ✅

**산출물**: 검증 체크리스트 ✅

---

## Phase 2.3: 프롬프트 작성 (Prompt Implementation)

### 작업 개요

**목적**: Phase 2.2 논리적 설계를 바탕으로 7개 에이전트 프롬프트를 10-Section 표준 형식으로 작성합니다.

**산출물**: 7개 에이전트 프롬프트 파일 (`.claude/agents/*.md`)

**핵심 작업 원칙**:
- 10개 표준 섹션 준수 (logical_design.md Section 1 참조)
- Unit 2 계약 100% 반영 (I/O Contract, Error Handling)
- UTF-8 인코딩 CRITICAL 지시문 필수 포함
- 3-Level Difficulty 상세 가이드라인 (concepts-writer)
- Work Status Markers 조작 명세 정확히 반영

**참조 문서**:
- `logical_design.md` (Unit 3) - 2,543줄, 8개 섹션
- `domain_design.md` (Unit 3) - 6,997줄, 12개 섹션
- `docs/aidlc-docs/specifications/contracts/*.md` - 7개 에이전트 계약

---

### 작업 완료

- [x] **content-initiator.md**: 434줄 완성 ✅
  - 파일 초기화 전용 프롬프트
  - 7-Step Execution Instructions
  - frontmatter + Work Status Markers 생성
  - 특수 사항: [START] 기록만, [DONE] 없음

- [x] **overview-writer.md**: 482줄 완성 ✅
  - Overview 섹션 작성 (50-100줄)
  - Introduction (3-5문장) + 핵심 특징 (4-5개) + 실무 영향 (4-6문장)
  - MultiEdit 도구 사용

- [x] **concepts-writer.md**: 775줄 완성 ✅ (가장 중요)
  - **핵심**: Easy/Normal/Expert 3단계 난이도 설명
  - Easy: 중학생, 일상 비유, 이모지, 절대 코드 없음
  - Normal: 일반 개발자, 기술 용어, 5-10줄 코드
  - Expert: 전문가 20년+, ECMAScript 명세 인용, 고급 코드
  - needs_visualization 플래그 결정 로직

- [x] **visualization-writer.md**: 524줄 완성 ✅
  - 조건부 실행: needs_visualization true/false
  - SKIP path (6 steps) vs Generate path (9 steps)
  - **CRITICAL**: index.ts export 업데이트 필수 (Step 7)
  - React 컴포넌트 생성 (.tsx, Tailwind CSS)

- [x] **practice-writer.md**: 369줄 완성 ✅
  - Code Patterns (2-4개): Short Code (3-5줄) + Full Code (10-20줄)
  - ❌ Anti-pattern vs ✅ Best Practice 대비
  - Experiments (1-3개): Instructions (5-8 steps) + Initial Code (10-25줄)
  - 3-Level Explanation (Easy/Normal/Expert)

- [x] **quiz-writer.md**: 727줄 완성 ✅
  - 6가지 퀴즈 타입 (multiple-choice, true-false, fill-in-blank, code-review, output-prediction, text-fill-in-blank)
  - 8-12개 문제, 난이도 분포 30%/40%/30% (1-2/3/4-5)
  - 각 문제당 3개 Progressive Hints
  - Correct Answer 검증 (multiple-choice)

- [x] **content-validator.md**: 681줄 완성 ✅
  - 100점 만점 채점 시스템
  - Overview (20점), Core Concepts (25점), Code Patterns (20점), Experiments (15점), Quiz (20점)
  - 90점 threshold: STATUS: COMPLETED vs IMPROVEMENT_NEEDED
  - index.ts export 검증 (Grep 도구 사용)

**산출물**: 7개 프롬프트 완성 ✅ (총 3,992줄)

---

### 품질 기준 달성

1. **일관성**: 모든 프롬프트가 10-Section 표준 형식 준수 ✅
2. **완전성**: Unit 2 계약 내용 100% 반영 ✅
3. **명확성**: Execution Instructions 단계별 명확한 지시 ✅
4. **검증 가능성**: Preconditions/Postconditions 체크리스트 포함 ✅

---

## 질문 사항 (Phase 2.2)

### [Question 1] 논리적 설계 범위

**질문**: Unit 3 논리적 설계의 범위를 명확히 하고 싶습니다. 다음 중 어디까지 포함할까요?

**옵션**:
- **A (최소 범위)**: 프롬프트 데이터 구조, I/O Contract 형식, 검증 알고리즘만
- **B (중간 범위)**: A + Work Status Markers 조작 명세, 오류 처리 알고리즘
- **C (최대 범위)**: B + 7개 에이전트 각각의 상세 명세

**권장**: **B (중간 범위)**
- 이유: A는 너무 추상적, C는 Phase 2.3 (물리적 설계)와 중복
- B는 논리적 설계에 적합한 수준 (알고리즘 + 인터페이스)

**[Answer 1]**: B (중간 범위) - 권장안 채택 ✅
- 프롬프트 데이터 구조, I/O Contract 형식, 검증 알고리즘
- Work Status Markers 조작 명세, 오류 처리 알고리즘
- 7개 에이전트 각각의 상세 명세는 제외 (간략 요약만)

---

### [Question 2] Section 8 상세도

**질문**: Section 8 (7개 에이전트 프롬프트 명세 요약)을 어느 수준까지 작성할까요?

**옵션**:
- **A (간략)**: 각 에이전트당 1-2 페이지 요약 (I/O Contract + 핵심 알고리즘만)
- **B (중간)**: 각 에이전트당 3-5 페이지 (A + Execution Instructions + 특수 로직)
- **C (상세)**: 각 에이전트당 10+ 페이지 (완전한 프롬프트 초안 수준)

**권장**: **A (간략)**
- 이유: 논리적 설계는 "명세"이지 "구현"이 아님
- 상세 내용은 domain_design.md Section 8에 이미 있음
- logical_design.md는 데이터 구조 + 알고리즘 중심

**[Answer 2]**: A (간략) - 권장안 채택 ✅
- 각 에이전트당 1-2 페이지 요약
- I/O Contract + 핵심 알고리즘만 포함
- 특수 제약사항 간략히 언급

---

### [Question 3] 다이어그램 포함 여부

**질문**: Unit 1, 2처럼 Mermaid 다이어그램을 많이 포함할까요?

**옵션**:
- **A (최소)**: 핵심 다이어그램 2-3개만 (프롬프트 구조, STATUS 전이)
- **B (중간)**: 5-7개 다이어그램 (A + Execution 플로우차트, 오류 처리 플로우)
- **C (최대)**: 10+ 다이어그램 (각 에이전트별 플로우차트 포함)

**권장**: **B (중간)**
- 이유: 다이어그램은 이해를 돕지만 너무 많으면 문서 비대화
- 알고리즘 설명에 필수적인 다이어그램만 포함

**[Answer 3]**: B (중간) - 권장안 채택 ✅
- 5-7개 Mermaid 다이어그램 포함
- 프롬프트 구조, STATUS 전이, Execution 플로우, 오류 처리 플로우 등

---

## 예상 산출물 (Phase 2.2)

1. **`logical_design.md`**: 논리적 설계 문서
   - 예상 길이: 2,000-3,000줄
   - 8개 섹션
   - 5-7개 Mermaid 다이어그램
   - 다수의 테이블 및 정규식 패턴

---

## 예상 소요 시간 (Phase 2.2)

| 단계 | 작업 내용 | 예상 시간 |
|------|-----------|-----------|
| Step 0 | 준비 작업 (분석, 범위 결정) | 1-2시간 |
| Section 1 | 프롬프트 데이터 구조 | 2-3시간 |
| Section 2 | I/O Contract 통합 형식 | 2-3시간 |
| Section 3 | Execution Instructions 알고리즘 | 2-3시간 |
| Section 4 | WSM 조작 명세 | 2-3시간 |
| Section 5 | 오류 처리 알고리즘 | 1-2시간 |
| Section 6 | 프롬프트 검증 알고리즘 | 2-3시간 |
| Section 7 | 난이도 레벨 표준 | 1-2시간 |
| Section 8 | 7개 에이전트 명세 요약 | 3-4시간 |
| Step 2 | 검증 및 검토 | 1-2시간 |
| **총계** | | **17-27시간** |

---

## 리스크 및 완화 방안 (Phase 2.2)

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| Unit 1, 2와 문서 스타일 불일치 | 중간 | Step 0.1에서 철저히 분석, 동일한 패턴 적용 |
| domain_design.md 내용 중복 | 중간 | 논리적 설계는 "명세"에 집중, 도메인 개념 반복 최소화 |
| 다이어그램 과다 | 낮음 | Question 3 답변에 따라 조정 |
| Section 8 너무 상세해짐 | 중간 | Question 2 답변에 따라 간략히 유지 |

---

## 성공 기준 (Phase 2.2)

1. **일관성**: Unit 1, 2 logical_design.md와 문서 구조 일치
2. **완전성**: domain_design.md 핵심 개념 모두 반영
3. **명세 중심**: 코드 없이 데이터 구조, 알고리즘, 인터페이스 명세만 작성
4. **가독성**: 표, 다이어그램, 정규식 패턴으로 명확히 표현

---

## 검토 및 승인 요청

본 Phase 2.2 계획을 검토해 주시고, 다음 사항에 대해 답변 부탁드립니다:

1. **Question 1-3 답변**: 각 질문에 대한 선택 (A/B/C) 또는 다른 의견
2. **단계 추가/제거**: 누락된 단계가 있거나 불필요한 단계가 있나요?
3. **승인**: 이 계획대로 진행해도 될까요?

승인 후 Step 0부터 순차적으로 실행하겠습니다.

---

## 질문 사항 (Phase 2.1)

### [Question 1] I/O Contract 통합 수준

**질문**: 프롬프트에 Unit 2 계약의 I/O Contract를 어느 수준까지 통합할까요?

**옵션**:
- **A (전체 복사)**: 계약의 I/O Contract 섹션을 프롬프트에 전체 복사
- **B (요약 + 참조)**: 핵심 내용만 요약하고 상세 내용은 계약 문서 참조
- **C (참조만)**: I/O Contract는 계약 문서 참조만 명시

**권장**: **B (요약 + 참조)**
- 이유: 프롬프트 간결성 유지하면서도 에이전트가 즉시 이해 가능
- 핵심 필드(File State, Work Status Markers)는 프롬프트에 포함
- 상세 제약사항은 계약 문서 참조 링크

**참고**: Claude Code 공식 문서에 따르면 프롬프트는 간결하고 명확해야 함

**[Answer 1]**: B (요약 + 참조) - 권장안 승인

---

### [Question 2] 프롬프트 길이 제한

**질문**: 각 에이전트 프롬프트의 적정 길이는 어느 정도일까요?

**옵션**:
- **A (짧게 - 200줄 이하)**: 핵심만 포함, 상세 내용은 참조 문서로
- **B (중간 - 200-400줄)**: 핵심 + 자주 참조하는 정보 포함
- **C (길게 - 400줄 이상)**: 모든 정보 자기 완결적으로 포함

**권장**: **B (중간 - 200-400줄)**
- 이유: 에이전트가 참조 문서 없이도 대부분 작업 가능
- 너무 짧으면 정보 부족, 너무 길면 AI가 놓칠 수 있음
- Claude Code 공식 가이드 참조

**참고**: 현재 프롬프트 길이 확인 필요

**[Answer 2]**: B (중간 - 200-400줄) - 권장안 승인

---

### [Question 3] 프롬프트 검증 자동화 수준

**질문**: 프롬프트 검증을 어느 수준까지 자동화할까요?

**옵션**:
- **A (최소)**: frontmatter 필드, 필수 섹션 존재 여부만 검증
- **B (중간)**: A + 섹션 내용 검증 (예: I/O Contract가 비어있지 않은지)
- **C (최대)**: B + 의미 검증 (Unit 2 계약과 일치 여부)

**권장**: **B (중간)**
- 이유: A만으로는 품질 보장 부족, C는 구현 복잡도 높음
- 의미 검증은 수동 검토로 보완

**참고**: Unit 4 Orchestration 스크립트와 연계

**[Answer 3]**: B (중간) - 권장안 승인

---

### [Question 4] 프롬프트 백업 전략

**질문**: 기존 프롬프트를 어떻게 백업할까요?

**배경**: AI-DLC 화이트페이퍼에 프롬프트 보존 정책이 있을 수 있음

**옵션**:
- **A (Git 히스토리)**: Git 커밋 히스토리로 충분, 별도 백업 불필요
- **B (백업 디렉터리)**: `.claude/agents/backup/v1.0/` 형태로 백업
- **C (별도 브랜치)**: `prompts/v1.0` 브랜치에 보존

**권장**: **A (Git 히스토리) + 화이트페이퍼 확인**
- Git으로 충분하지만 화이트페이퍼 정책 우선 적용

**참고**: `docs/aidlc-docs/ai-dlc-whitepaper-ko.md` 검토 필요

**[Answer 4]**: 루트의 backup 폴더에 보관 (사용자 지정 경로 적용)

---

## 예상 산출물 (Phase 2.1)

1. **`domain_design.md`**: 도메인 모델 설계 문서 (주요 산출물)
   - Section 1: 프롬프트 도메인 개요
   - Section 2: 프롬프트 템플릿 구조
   - Section 3: I/O Contract 통합 패턴
   - Section 4: 에이전트 책임 경계
   - Section 5: Work Status Markers 조작 표준화
   - Section 6: 오류 처리 표준화
   - Section 7: UTF-8 인코딩 보장 전략
   - Section 8: 7개 에이전트 프롬프트 설계
   - Section 9: 프롬프트 검증 전략
   - Section 10: 프롬프트 버전 관리
   - Section 11: 프롬프트 작성 가이드
   - Section 12: Summary and Next Steps

---

## 예상 소요 시간 (Phase 2.1)

| 단계 | 작업 내용 | 예상 시간 |
|------|-----------|-----------|
| Step 0 | 준비 작업 (분석, 검토) | 2-3시간 |
| Section 1 | 프롬프트 도메인 개요 | 1-2시간 |
| Section 2 | 프롬프트 템플릿 구조 | 2-3시간 |
| Section 3 | I/O Contract 통합 패턴 | 2-3시간 |
| Section 4 | 에이전트 책임 경계 | 2-3시간 |
| Section 5 | WSM 조작 표준화 | 2-3시간 |
| Section 6 | 오류 처리 표준화 | 1-2시간 |
| Section 7 | UTF-8 인코딩 보장 | 1-2시간 |
| Section 8 | 7개 에이전트 설계 | 4-6시간 |
| Section 9 | 프롬프트 검증 전략 | 2-3시간 |
| Section 10 | 프롬프트 버전 관리 | 1-2시간 |
| Section 11 | 프롬프트 작성 가이드 | 2-3시간 |
| Section 12 | Summary and Next Steps | 1-2시간 |
| **총계** | | **23-37시간** |

---

## 리스크 및 완화 방안 (Phase 2.1)

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| 프롬프트가 너무 길어져 AI 이해도 저하 | 높음 | Question 2로 길이 제한 결정, 핵심만 포함 |
| Unit 2 계약과 프롬프트 불일치 | 높음 | Section 3에서 계약-프롬프트 변환 패턴 명확히 정의 |
| 7개 프롬프트 간 일관성 부족 | 중간 | Section 2에서 표준 템플릿 정의, Section 9에서 검증 |
| 기존 에이전트 동작 변경으로 품질 저하 | 높음 | Step 0.3에서 현재 동작 철저히 분석, 변경 최소화 |
| UTF-8 인코딩 문제 지속 | 높음 | Section 7에서 명시적 지시 + Unit 4 환경 설정 연계 |

---

## 성공 기준 (Phase 2.1)

1. **완전성**: 12개 섹션 모두 작성 완료, 7개 에이전트 프롬프트 설계 포함
2. **일관성**: Unit 1, Unit 2와 용어, 개념, 패턴이 100% 일치
3. **실용성**: 도메인 모델만으로 Phase 2.2(논리적 설계) 진행 가능
4. **검증 가능성**: 프롬프트 품질 기준이 명확히 정의됨

---

## 다음 단계 (Phase 2.1 이후)

Phase 2.1 완료 후:
- **Phase 2.2: 논리적 설계 (Logical Design)** - 프롬프트 템플릿 구체화, 자동 검증 스크립트 명세
- **Phase 2.3: 물리적 설계 (Physical Design)** - 7개 프롬프트 업데이트 및 검증

---

## 검토 및 승인 요청

본 Phase 2.1 계획을 검토해 주시고, 다음 사항에 대해 답변 부탁드립니다:

1. **Question 1-4 답변**: 각 질문에 대한 선택 (A/B/C) 또는 다른 의견
2. **단계 추가/제거**: 누락된 단계가 있거나 불필요한 단계가 있나요?
3. **우선순위 조정**: 특정 섹션을 먼저 작성해야 하나요?
4. **승인**: 이 계획대로 진행해도 될까요?

승인 후 Step 0부터 순차적으로 실행하겠습니다.

---

## 참조 문서

- `docs/aidlc-docs/inception/units/unit-03-agent-prompts.md` - Unit 3 정의 및 범위
- `docs/aidlc-docs/construction/unit-01-pipe-mechanism/domain_design.md` - Pipe 메커니즘 도메인 모델
- `docs/aidlc-docs/construction/unit-02-filter-contracts/domain_design.md` - Filter 계약 도메인 모델
- `docs/aidlc-docs/specifications/work-status-markers-spec.md` - Work Status Markers 명세
- `docs/aidlc-docs/specifications/contracts/*.md` - 7개 에이전트 계약 문서
- `.claude/agents/*.md` - 현재 에이전트 프롬프트 (7개)
- `docs/aidlc-docs/ai-dlc-whitepaper-ko.md` - AI-DLC 화이트페이퍼
- Claude Code Sub-agents Guide: https://docs.claude.com/en/docs/claude-code/sub-agents
