# 학습 콘텐츠 자동화 시스템 개선 프로젝트 실행 계획

## 프로젝트 개요

**프로젝트명**: Learning Content Automation System Improvement Project

**목표**: 현재 학습 콘텐츠 자동 생성 시스템을 명시적이고 개선 가능한 Pipeline Architecture로 발전시킨다.

**배경**:
- 현재 7개 AI 에이전트가 순차 실행되어 학습 콘텐츠 자동 생성
- Work Status Markers (HTML 주석) 기반 에이전트 간 데이터 전달
- 1개 콘텐츠 생성 소요 시간: 50-80분
- 주요 문제: 암묵적 계약, 비표준화된 Pipe, 재시작 불가, 품질 측정 부재

**선정된 아키텍처**: Pipeline Architecture (Pipes and Filters) + DDD 경량화

**개선 목표**:
1. Filter 계약 명시화
2. Pipe 메커니즘 설계 (Work Status Markers 표준)
3. 에이전트 프롬프트 개선
4. 오케스트레이션 스크립트 개선
5. 품질 측정 시스템 구축

## 프로젝트 구조

### Phase 1: Inception (현재 단계)
**목적**: 개선 영역을 독립적인 유닛으로 분해하고 통합 계획 수립

**산출물**:
- [x] `docs/aidlc-docs/inception/units/unit-01-pipe-mechanism.md`
- [x] `docs/aidlc-docs/inception/units/unit-02-filter-contracts.md`
- [x] `docs/aidlc-docs/inception/units/unit-03-agent-prompts.md`
- [x] `docs/aidlc-docs/inception/units/unit-04-orchestration.md`
- [x] `docs/aidlc-docs/inception/units/unit-05-quality-metrics.md`
- [x] `docs/aidlc-docs/inception/units/integration_plan.md`
- [x] `docs/aidlc-docs/inception/plan.md` (본 문서)

**기간**: 1일 (완료)

---

### Phase 2: Construction
**목적**: 각 유닛을 순차적 또는 병렬적으로 구축

**5개 유닛**:
1. Unit 1: Pipe Mechanism 표준화 (5일)
2. Unit 2: Filter Contracts 명시화 (7일)
3. Unit 3: Agent Prompts 개선 (7일)
4. Unit 4: Orchestration 개선 (8-10일)
5. Unit 5: Quality Metrics 구축 (9일)

**실행 전략**: 시나리오 선택 필요 (아래 참조)

---

### Phase 3: Operations
**목적**: 개선된 시스템 배포, 모니터링, 지속적 개선

**활동**:
- 프로덕션 배포
- 품질 대시보드 모니터링
- 에이전트 프롬프트 튜닝
- 계약 및 표준 업데이트

## 실행 계획 (체크박스)

### ✅ Phase 1: Inception (완료)

- [x] **Step 1.1**: 시스템 아키텍트 역할 이해
- [x] **Step 1.2**: 개선 영역을 유닛으로 분해
  - [x] Unit 1 문서 작성
  - [x] Unit 2 문서 작성
  - [x] Unit 3 문서 작성
  - [x] Unit 4 문서 작성
  - [x] Unit 5 문서 작성
- [x] **Step 1.3**: 통합 계획 수립
- [x] **Step 1.4**: 본 실행 계획 작성

---

### Phase 2: Construction (진행중)

#### ✅ Stage 1: Foundation (Unit 1) - 완료

- [x] **Step 2.0**: Domain Design 작성 (Phase 2.1)
  - [x] Bounded Context 정의
  - [x] Ubiquitous Language 정의
  - [x] Domain Event 모델링
  - [x] Handoff Protocol Specification
  - [x] Domain Invariants 정의
  - [x] Context Integration 설계
  - [x] 도메인 모델 검증
  - **산출물**: `docs/aidlc-docs/construction/unit-01-pipe-mechanism/domain_design.md` (3,504줄) ✅
  - **담당**: Claude Code
  - **완료일**: 2025-10-16

- [x] **Step 2.0.5**: Logical Design 작성 (Phase 2.2)
  - [x] 데이터 구조 설계
  - [x] 파싱 알고리즘 설계
  - [x] 타임스탬프 검증 설계
  - [x] 인터페이스 설계 (에이전트용)
  - [x] 재시작 메커니즘 설계
  - [x] 상태 전이 다이어그램
  - [x] 예외 처리 및 성능 고려사항
  - **산출물**: `docs/aidlc-docs/construction/unit-01-pipe-mechanism/logical_design.md` (4,159줄) ✅
  - **담당**: Claude Code
  - **완료일**: 2025-10-17

- [x] **Step 2.1**: Work Status Markers 명세 작성 (Phase 2.3)
  - [x] 필수/선택 필드 정의
  - [x] HANDOFF LOG 형식 표준화 (6개 EVENT_TYPE)
  - [x] 타임스탬프 형식 결정 (ISO 8601)
  - [x] 파싱 규칙 문서화
  - [x] 5개 전체 마커 예시 작성
  - **산출물**: `docs/aidlc-docs/specifications/work-status-markers-spec.md` (1,200줄) ✅
  - **담당**: Claude Code
  - **완료일**: 2025-10-17

- [x] **Step 2.2**: 마커 검증 스크립트 개발 (Phase 2.3)
  - [x] HTML 주석 추출 함수
  - [x] 필드 형식 검증 함수 (STATUS, TIMESTAMP, VALIDATION_SCORE)
  - [x] 도메인 불변식 검증 함수
  - [x] HANDOFF LOG 검증 함수
  - [x] 오류 메시지 출력 및 종료 코드
  - [x] BSD sed (macOS) 호환성 확보
  - **산출물**: `test/test-work-status-markers.sh` (450줄, 실행 가능) ✅
  - **참고**: 마커 생성은 에이전트가 직접 수행 (domain_design.md Section 1.1 참조)
  - **담당**: Claude Code
  - **완료일**: 2025-10-17

- [x] **Step 2.3**: 샘플 마커 파일 생성 (Phase 2.3)
  - [x] 유효한 마커 샘플 (valid/normal-flow.md)
  - [x] 무효한 마커 샘플 (invalid/missing-status.md, invalid/invalid-status-enum.md)
  - [x] 검증 스크립트 테스트 실행
  - **산출물**: `test/fixtures/sample-markers/` (3개 파일) ✅
  - **담당**: Claude Code
  - **완료일**: 2025-10-17

- [x] **Step 2.4**: 에이전트 핸드오프 가이드 작성 (Phase 2.3)
  - [x] 에이전트 시작 시 체크리스트 (Precondition)
  - [x] 에이전트 완료 시 체크리스트 (Postcondition)
  - [x] 6개 EVENT_TYPE별 예시
  - [x] 인터페이스 사용법 (에이전트가 마커 직접 조작)
  - [x] 재시작 메커니즘 (5단계 우선순위)
  - **산출물**: `docs/aidlc-docs/guides/agent-handoff-guide.md` (800줄) ✅
  - **담당**: Claude Code
  - **완료일**: 2025-10-17

- [x] **Milestone 1 검증**: Unit 1 완료 확인
  - [x] 검증 스크립트 테스트 통과 (valid: ✓ PASSED, invalid: ✗ FAILED)
  - [x] 3개 샘플 파일 검증 완료
  - [x] 가이드 문서 작성 완료
  - [x] domain_design.md, logical_design.md와 일관성 확인 완료
  - **완료일**: 2025-10-17

**Unit 1 최종 산출물 규모**:
- Domain Design: 3,504줄 (8개 섹션)
- Logical Design: 4,159줄 (8개 섹션)
- Work Status Markers 명세: 1,200줄
- 검증 스크립트: 450줄 (10개 검증 함수)
- 에이전트 핸드오프 가이드: 800줄
- 샘플 마커 파일: 3개
- **총 약 10,113줄 + 스크립트 + 샘플**

**Unit 1 핵심 성과**:
- ✅ Pipe 메커니즘 완전 표준화 (6개 EVENT_TYPE, ISO 8601)
- ✅ 에이전트 자율성 원칙 확립 (에이전트가 직접 마커 조작)
- ✅ 5단계 재시작 메커니즘 설계
- ✅ BSD sed (macOS) 호환 검증 스크립트
- ✅ DDD 경량화 방식 적용 (Bounded Context, Ubiquitous Language)

---

#### Stage 2: Contracts (Unit 2)

- [ ] **Step 2.5**: 계약 명세 템플릿 정의
  - **산출물**: `docs/aidlc-docs/specifications/agent-contract-template.md`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.6**: 7개 에이전트 계약 작성
  - [ ] content-initiator-contract.md
  - [ ] overview-writer-contract.md
  - [ ] concepts-writer-contract.md
  - [ ] visualization-writer-contract.md
  - [ ] practice-writer-contract.md
  - [ ] quiz-writer-contract.md
  - [ ] content-validator-contract.md
  - **산출물**: `docs/aidlc-docs/specifications/contracts/*.md` (7개)
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.7**: 계약 검증 스크립트 개발
  - [ ] `validate_preconditions()` 구현
  - [ ] `validate_postconditions()` 구현
  - [ ] `validate_section_exists()` 구현
  - [ ] `validate_section_structure()` 구현
  - **산출물**: `scripts/lib/contract-validator.sh`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.8**: 에이전트 의존성 그래프 작성
  - **산출물**: `docs/aidlc-docs/specifications/agent-dependency-graph.md`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.9**: Breaking Change 관리 가이드 작성
  - **산출물**: `docs/aidlc-docs/guides/contract-versioning-guide.md`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Milestone 2 검증**: Unit 2 완료 확인
  - [ ] 7개 에이전트 계약 작성 완료
  - [ ] 계약 검증 스크립트 단위 테스트 통과
  - [ ] 계약 위반 감지 테스트 통과

---

#### Stage 3: Prompts (Unit 3)

- [ ] **Step 2.10**: 개선된 프롬프트 템플릿 작성
  - **산출물**: `docs/aidlc-docs/templates/agent-prompt-template.md`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.11**: 7개 에이전트 프롬프트 업데이트
  - [ ] content-initiator.md 업데이트
  - [ ] overview-writer.md 업데이트
  - [ ] concepts-writer.md 업데이트
  - [ ] visualization-writer.md 업데이트
  - [ ] practice-writer.md 업데이트
  - [ ] quiz-writer.md 업데이트
  - [ ] content-validator.md 업데이트
  - **산출물**: `.claude/agents/*.md` (업데이트)
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.12**: 프롬프트 검증 체크리스트 작성
  - **산출물**: `docs/aidlc-docs/checklists/prompt-quality-checklist.md`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.13**: 프롬프트 작성 가이드 작성
  - **산출물**: `docs/aidlc-docs/guides/agent-prompt-writing-guide.md`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.14**: 프롬프트 자동 검증 스크립트 개발
  - **산출물**: `scripts/lib/validate-prompts.sh`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Milestone 3 검증**: Unit 3 완료 확인
  - [ ] 모든 프롬프트가 템플릿 준수
  - [ ] 업데이트 전후 출력물 비교 테스트 통과
  - [ ] 프롬프트 검증 체크리스트 통과

---

#### Stage 4: Orchestration (Unit 4)

- [ ] **Step 2.15**: 스크립트 모듈화
  - [ ] `scripts/lib/common-utils.sh` 작성
  - [ ] v6 → v7 기능 마이그레이션
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.16**: 재시작 메커니즘 강화
  - [ ] `auto_determine_restart_point()` 구현
  - [ ] 재시작 지점 자동 식별 테스트
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.17**: 계약 검증 통합
  - [ ] `execute_agent_with_validation()` 구현
  - [ ] Precondition/Postcondition 검증 통합
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.18**: 오류 처리 및 로깅 개선
  - [ ] 에이전트별 로그 파일 생성
  - [ ] execution-summary.json 생성
  - **산출물**: `logs/sessions/[session-id]/execution-summary.json`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.19**: 명령줄 인터페이스 개선
  - [ ] --resume, --from, --validate-only 등 옵션 추가
  - **산출물**: `scripts/content-generator-v7.sh`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.20**: 오케스트레이션 가이드 작성
  - **산출물**: `docs/aidlc-docs/guides/orchestration-guide.md`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.21**: 오케스트레이션 테스트 작성
  - **산출물**: `test/test-orchestration.sh`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Milestone 4 검증**: Unit 4 완료 확인
  - [ ] v6 대비 기능 동등성 확인
  - [ ] 재시작 메커니즘 테스트 통과
  - [ ] 계약 검증 통합 테스트 통과

---

#### Stage 5: Quality Metrics (Unit 5)

- [ ] **Step 2.22**: 품질 메트릭 명세 작성
  - [ ] 5개 메트릭 카테고리 정의 (구조, 완성도, 파싱, 다양성, 길이)
  - **산출물**: `docs/aidlc-docs/specifications/quality-metrics-spec.md`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.23**: 품질 측정 스크립트 개발
  - [ ] `measure_structure_quality()` 구현
  - [ ] `measure_completeness()` 구현
  - [ ] `measure_parseability()` 구현
  - [ ] `measure_diversity()` 구현
  - [ ] `measure_length_adequacy()` 구현
  - [ ] `calculate_total_score()` 구현
  - **산출물**: `scripts/measure-quality.sh`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.24**: 품질 리포트 생성기 개발
  - **산출물**: `scripts/generate-quality-report.sh`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.25**: 품질 대시보드 생성
  - **산출물**: `scripts/generate-quality-dashboard.sh`, `logs/quality-dashboard.html`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.26**: content-validator 통합
  - [ ] content-validator.md 프롬프트 업데이트
  - [ ] 품질 측정 스크립트 호출 추가
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.27**: 품질 메트릭 테스트 작성
  - **산출물**: `test/test-quality-metrics.sh`
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Milestone 5 검증**: Unit 5 완료 확인
  - [ ] 품질 측정 스크립트 테스트 통과
  - [ ] 품질 리포트 생성 확인
  - [ ] 대시보드 배포 확인

---

#### Stage 6: Integration

- [ ] **Step 2.28**: 통합 테스트 실행
  - [ ] Integration Test 1: Marker Validation + Orchestration
  - [ ] Integration Test 2: Contract Validation + Orchestration
  - [ ] Integration Test 3: Updated Prompts + Orchestration
  - [ ] Integration Test 4: Orchestration + Quality Metrics
  - [ ] End-to-End Test: Full Pipeline
  - **참고**: 마커 생성은 에이전트가 수행, 오케스트레이션은 검증만 수행
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.29**: 성능 벤치마크
  - [ ] 콘텐츠 생성 시간 측정 (목표: 50-80분 유지)
  - [ ] 품질 점수 평균 측정 (목표: 75점 이상)
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 2.30**: 문서화 완료
  - [ ] 모든 가이드 문서 리뷰
  - [ ] README 업데이트
  - [ ] 사용자 매뉴얼 작성
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Milestone 6 검증**: 전체 통합 완료
  - [ ] 모든 통합 테스트 통과
  - [ ] 성능 기준 충족
  - [ ] 문서화 완료

---

### Phase 3: Operations (미착수)

- [ ] **Step 3.1**: 프로덕션 배포
  - [ ] v7 배포 계획 수립
  - [ ] v6 백업 생성
  - [ ] 점진적 롤아웃 실행
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 3.2**: 모니터링 설정
  - [ ] 품질 대시보드 모니터링
  - [ ] 오류 로그 모니터링
  - [ ] 성능 메트릭 추적
  - **담당**: [Answer]
  - **기한**: [Answer]

- [ ] **Step 3.3**: 지속적 개선
  - [ ] 에이전트 프롬프트 튜닝
  - [ ] 품질 기준 조정
  - [ ] 계약 및 표준 업데이트
  - **담당**: [Answer]
  - **기한**: [Answer]

## 질문 사항

### [Question 1] 실행 전략 선택
**질문**: 어떤 실행 전략을 선택하시겠습니까?

**옵션**:
- A: 순차 실행 (Sequential Execution) - 10주
- B: 병렬 실행 (Parallel Execution) - 9주
- C: 점진적 롤아웃 (Incremental Rollout) - 14주

**Answer**:
- B

---

### [Question 2] 팀 구성
**질문**: 각 유닛을 누가 담당하시겠습니까?

**옵션**:
- A: 단일 개발자가 모든 유닛 순차 수행
- B: 복수 개발자가 유닛 분담
- C: 외부 지원 활용

**Answer**:
- B와 유사, 각 유닛 별로 별도의 클로드 코드 세션이 실행

---

### [Question 3] Unit 1 - 마커 저장 위치
**질문**: Work Status Markers를 별도 파일로 분리할까요?

**Answer**:
[권장: 현재 구조 유지 (마크다운 내부 HTML 주석)]
- 권장안을 채택합니다.
---

### [Question 4] Unit 1 - 타임스탬프 형식
**질문**: ISO 8601 형식을 채택할까요?

**Answer**:
[권장: ISO 8601 채택]
- 권장안을 채택합니다.

---

### [Question 5] Unit 1 - 검증 수준
**질문**: 마커 검증을 언제 수행할까요?

**Answer**:
[권장: 사전+사후 검증 모두]
- 권장안을 채택합니다.
---

### [Question 6] Unit 2 - 계약 명세 형식
**질문**: 계약 명세 형식은?

**Answer**:
[권장: YAML frontmatter + 마크다운]
- 권장안을 채택합니다.

---

### [Question 7] Unit 2 - 계약 위반 처리
**질문**: Precondition 위반 시 처리 방법은?

**Answer**:
[권장: Fail-Fast]
- 권장안을 채택합니다.

---

### [Question 8] Unit 2 - visualization-writer 의존성
**질문**: visualization-writer는 필수인가요?

**Answer**:
[권장: 선택적 에이전트]
- 아니요 필수 에이전트 입니다. (A)

---

### [Question 9] Unit 3 - 프롬프트 상세도
**질문**: Input/Output Contract를 프롬프트에 얼마나 상세히 포함할까요?

**Answer**:
[권장: 요약 + 참조]

권장안에 동의하되 공식문서 [링크](https://docs.claude.com/en/docs/claude-code/sub-agents#quick-start)를 참고하세요

---

### [Question 10] Unit 3 - 오류 처리 자율성
**질문**: 에이전트가 오류를 자율적으로 처리하게 할까요?

**Answer**:
[권장: 즉시 종료]
- 권장안을 채택합니다.

---

### [Question 11] Unit 3 - UTF-8 인코딩 검증
**질문**: 에이전트가 UTF-8 인코딩을 직접 검증할까요?

**Answer**:
- UTF-8 관련해서 지금 수준의 쉘 스크립트 설정이 없으면 한글이 깨지는 문제가 발생합니다. 이 점을 주의하세요. 문서는 한글이 정상 작성 되어야 합니다.

---

### [Question 12] Unit 3 - 기존 프롬프트 백업
**질문**: 기존 프롬프트를 별도 백업할까요?

**Answer**:
- docs/aidlc-docs/ai-dlc-whitepaper-ko.md 에 따르면 프롬프트를 보존하도록 되어 있지 않나요?

---

### [Question 13] Unit 4 - v6와 v7 공존
**질문**: v6와 v7를 동시에 유지할까요?

**Answer**:
- 유지하세요 v6의 이름을 바꿀 필요가 있나요? 기존 스크립트를 유지하기 위해서 v*와 같은 이름을 사용하고 있는거 아닌가요? 그리고 새 버전을 작성하더라도 "cladue -p"로 프롬프트에서 서브에이전트를 언급해서 실행하는 방식은 유지해야 됩니다. 이는 이미 검증된 사항이니까 주의하세요.

---

### [Question 14] Unit 4 - 병렬 실행 우선순위
**질문**: 병렬 실행 기능을 Unit 4에 포함할까요?

**Answer**:
- 아니요, 이미 병렬 실행이 가능합니다. 파이프라인 내의 각 섹션은 병렬로 실행되면 안됩니다. 문서가 1개의 파일안에 각 섹션이 순서대로 작성되어야 하니까요. lock파일을 토픽별로 만들고 있기 때문에 동시에 실행되서 충돌되는 것을 막고 있기 때문에 다른 토픽에 대해서는 병렬로 실행이 가능합니다. 오케스트레이션하는 쉘 스크립트 자체가 주제별로 여러 프로세스로 실행되면 됩니다.

---

### [Question 15] Unit 4 - execution-summary.json 필수 여부
**질문**: 매 실행마다 execution-summary.json을 생성할까요?

**Answer**:
[권장: 항상 생성]
- 권장안을 채택합니다.

---

### [Question 16] Unit 4 - Claude CLI 래핑
**질문**: Claude CLI 호출을 래핑할까요?

**Answer**:
[권장: 함수로 래핑]
- 권장안을 적용하되 `$CLAUDE_PATH -p "..." --session-id ...`처럼 실행하는 방식은 유지하세요.

---

### [Question 17] Unit 5 - 품질 기준선
**질문**: 최소 품질 점수를 몇 점으로 설정할까요?

**Answer**:
- C: 90점 (엄격한 기준)

---

### [Question 18] Unit 5 - 섹션별 가중치
**질문**: 모든 섹션에 동일한 가중치를 부여할까요?

**Answer**:
[권장: 현재 방식 유지]
- 권장안을 채택합니다.

---

### [Question 19] Unit 5 - 품질 트렌드 저장
**질문**: 품질 측정 결과를 DB에 저장할까요?

**Answer**:
[권장: JSON 파일로 저장]
- 권장안을 채택합니다.

---

### [Question 20] Unit 5 - 실시간 품질 피드백
**질문**: 에이전트 실행 중 실시간으로 품질 점수를 표시할까요?

**Answer**:
[권장: 실시간 피드백]
- 권장안을 채택합니다.

## 다음 단계

1. **본 계획 검토**: 이 실행 계획을 검토하고 승인해주세요
2. **질문 답변**: 위 20개 질문에 답변해주세요
3. **팀 배정**: 각 유닛 담당자를 배정해주세요
4. **킥오프**: Unit 1 - Pipe Mechanism 표준화 작업 시작

## 승인

**검토자**: 이승우
**승인 날짜**: 2025-10-16
**서명**: 이승우

---

**프로젝트 시작일**: 2025-10-16
**예상 완료일**: 2026-10-20

## 부록: 참조 문서

- [Unit 1: Pipe Mechanism 표준화](./units/unit-01-pipe-mechanism.md)
- [Unit 2: Filter Contracts 명시화](./units/unit-02-filter-contracts.md)
- [Unit 3: Agent Prompts 개선](./units/unit-03-agent-prompts.md)
- [Unit 4: Orchestration 개선](./units/unit-04-orchestration.md)
- [Unit 5: Quality Metrics 구축](./units/unit-05-quality-metrics.md)
- [통합 계획](./units/integration_plan.md)
