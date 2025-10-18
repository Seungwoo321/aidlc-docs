# Unit 5: 품질 측정 시스템 구축 - Construction Phase 계획

## 프로젝트 개요

**목표**: Pass/Fail 이분법을 넘어 정량적이고 세분화된 품질 측정 시스템을 구축하여, 콘텐츠 품질을 객관적으로 평가하고 지속적 개선을 가능하게 한다.

**단계**: Phase 2 - Construction (구축)
- Phase 2.1: DDD 경량화 방식으로 도메인 모델 설계
- Phase 2.2: 논리적 설계 및 상세 설계
- Phase 2.3: 구현 및 테스트

**참조 문서**:
- `docs/aidlc-docs/inception/units/unit-05-quality-metrics.md` (Unit 5 정의)
- `docs/aidlc-docs/construction/unit-01-pipe-mechanism/domain_design.md` (Pipe 메커니즘)
- `docs/aidlc-docs/construction/unit-02-filter-contracts/domain_design.md` (Filter 계약)
- `docs/aidlc-docs/construction/unit-04-orchestration/domain_design.md` (Orchestration)

---

## Phase 2.1: DDD 도메인 모델 설계

### 작업 개요

**목적**: Unit 5 요구사항을 바탕으로 품질 측정 시스템의 도메인 모델을 DDD 경량화 방식으로 설계합니다.

**산출물**: `domain_design.md` (도메인 설계 문서)

**핵심 설계 원칙**:
- Quality Metrics는 Value Object (불변)
- Quality Score는 Aggregate Root
- Quality Measurement는 Domain Service
- Quality Specification은 Specification Pattern
- Quality Report는 Application Service

---

### Step 0: 준비 작업

- [ ] **Step 0.1**: Unit 5 Inception 문서 상세 분석
  - 목적 재확인: 정량적 품질 측정 시스템 구축
  - 범위 재확인: In Scope vs Out of Scope
  - 현재 문제점 정리: VALIDATION_SCORE 불명확, Pass/Fail만 제공
  - 개선 방향 정리: 세분화된 메트릭, 섹션별 점수, 리포트 생성
  - 성공 기준 확인: 정량화, 재현성, 유용성, 자동화
  - **Question 1-4 답변 검토**:
    - Q1: 최소 품질 점수 = **90점** (사용자 결정)
    - Q2: 섹션별 가중치 = 현재 방식 유지
    - Q3: 품질 트렌드 저장 = JSON 파일
    - Q4: 실시간 품질 피드백 = 각 에이전트 완료 후

- [ ] **Step 0.2**: Construction 폴더 준비
  - `docs/aidlc-docs/construction/unit-05-quality-metrics/` 디렉터리 생성
  - `plan.md` 작성 (현재 파일)

- [ ] **Step 0.3**: 현재 시스템 분석
  - 기존 품질 검증 방식 조사:
    - `test/test-overview.mjs` 파싱 테스트
    - `test/test-concepts.mjs` 파싱 테스트
    - `test/test-patterns.mjs` 파싱 테스트
    - `test/test-experiments.mjs` 파싱 테스트
    - `test/test-quiz-raw.mjs` 파싱 테스트
  - VALIDATION_SCORE 계산 로직 확인:
    - `scripts/content-generator-v7.sh`에서 어떻게 계산되는지 분석
  - Work Status Markers에서 VALIDATION_SCORE 사용 방식 확인

- [ ] **Step 0.4**: Unit 1-4 의존성 확인
  - **Unit 1 산출물** 확인:
    - Work Status Markers에 VALIDATION_SCORE 필드 정의
  - **Unit 2 산출물** 확인:
    - 각 에이전트 계약에서 품질 기준 참조
  - **Unit 3 산출물** 확인:
    - content-validator 프롬프트에서 품질 검증 방식
  - **Unit 4 산출물** 확인:
    - execution-summary.json에서 품질 데이터 집계 방식

- [ ] **Step 0.5**: 품질 메트릭 카테고리 확인
  - **5가지 메트릭 카테고리** (Unit 5 문서 기반):
    1. 구조적 품질 (Structure Quality): 25점
    2. 완성도 (Completeness): 30점
    3. 파싱 품질 (Parseability): 25점
    4. 콘텐츠 다양성 (Diversity): 10점
    5. 길이 적절성 (Length Adequacy): 10점
  - **총점**: 100점
  - **등급 기준** (사용자 결정 반영):
    - 90점 이상: Pass (COMPLETE)
    - 75-89점: Review (IMPROVEMENT_NEEDED)
    - 60-74점: Fail
    - 60점 미만: Critical

---

### Step 1: 도메인 모델 설계 (domain_design.md 작성)

- [ ] **Step 1.1**: 도메인 용어집 (Ubiquitous Language) 정의
  - Quality Metric: 품질 측정 항목
  - Quality Score: 품질 점수 (0-100)
  - Quality Grade: 품질 등급 (Pass/Review/Fail/Critical)
  - Quality Breakdown: 카테고리별 점수 분해
  - Quality Report: 품질 리포트
  - Quality Dashboard: 품질 대시보드
  - Quality History: 품질 이력
  - Improvement Priority: 개선 우선순위
  - Section Score: 섹션별 점수
  - Measurement Rule: 측정 규칙

[Question 1]
**질문**: Quality Metric의 세부 항목을 어느 수준까지 정의할까요?

**옵션**:
- A. 5가지 카테고리만 정의 (구조, 완성도, 파싱, 다양성, 길이)
- B. 5가지 카테고리 + 카테고리당 3-5개 세부 항목 정의
- C. 5가지 카테고리 + 세부 항목 + 측정 방법까지 모두 정의

**권장**: B (카테고리 + 세부 항목까지, 측정 방법은 logical_design.md에서)

[Answer 1]


- [ ] **Step 1.2**: 도메인 모델 다이어그램 설계
  - **핵심 엔티티 및 Value Object**:
    - QualityScore (Aggregate Root)
    - QualityMetric (Value Object)
    - QualityBreakdown (Value Object)
    - QualityGrade (Value Object)
    - ImprovementPriority (Value Object)
  - **Domain Service**:
    - QualityMeasurementService
    - QualityReportGenerator
  - **Specification**:
    - MinimumQualitySpecification (90점)
    - SectionQualitySpecification
  - **관계도**: Mermaid 다이어그램으로 표현

- [ ] **Step 1.3**: Bounded Context 정의
  - **Quality Measurement Context**:
    - 책임: 품질 측정, 점수 계산
    - 입력: Markdown 파일
    - 출력: QualityScore
  - **Quality Reporting Context**:
    - 책임: 리포트 생성, 대시보드 생성
    - 입력: QualityScore
    - 출력: Report (Markdown, HTML)
  - **Quality History Context**:
    - 책임: 품질 이력 저장, 트렌드 분석
    - 입력: QualityScore
    - 출력: Quality History JSON

[Question 2]
**질문**: Quality Measurement와 Quality Reporting을 하나의 스크립트로 통합할까요?

**옵션**:
- A. 통합 (`measure-quality.sh`에서 측정 + 리포트 생성)
- B. 분리 (`measure-quality.sh` + `generate-quality-report.sh`)
- C. 3단계 분리 (`measure-quality.sh` + `generate-report.sh` + `generate-dashboard.sh`)

**권장**: C (단일 책임 원칙, 각 스크립트가 독립적으로 실행 가능)

[Answer 2]


- [ ] **Step 1.4**: 도메인 이벤트 정의
  - **QualityMeasured**: 품질 측정 완료
  - **QualityReportGenerated**: 리포트 생성 완료
  - **QualityDashboardUpdated**: 대시보드 업데이트
  - **ImprovementSuggested**: 개선 제안 생성
  - 각 이벤트의 Payload 정의

- [ ] **Step 1.5**: 도메인 규칙 (Business Rules) 정의
  - **규칙 1**: 총점은 각 카테고리 점수의 합계 (100점 만점)
  - **규칙 2**: 90점 미만은 IMPROVEMENT_NEEDED
  - **규칙 3**: 섹션별 점수는 독립적으로 계산
  - **규칙 4**: 파싱 실패 시 해당 섹션 점수는 0점
  - **규칙 5**: 개선 우선순위는 Impact/Effort 비율로 결정
  - **규칙 6**: 품질 등급은 총점에 따라 자동 결정

[Question 3]
**질문**: 섹션별 점수가 너무 낮을 때 (예: 10점 미만) 전체 Pass를 막을까요?

**옵션**:
- A. 막지 않음 (총점 90점 이상이면 Pass)
- B. 막음 (모든 섹션 최소 50% 이상 + 총점 90점)
- C. 경고만 (Pass는 하되 Warning 표시)

**권장**: B (품질 균형 보장)

[Answer 3]


- [ ] **Step 1.6**: 도메인 서비스 책임 정의
  - **QualityMeasurementService**:
    - 책임: 5가지 카테고리 점수 측정
    - 입력: Markdown 파일 경로
    - 출력: QualityScore (Aggregate)
    - 주요 메서드:
      - `measureStructureQuality(file): number`
      - `measureCompleteness(file): number`
      - `measureParseability(file): number`
      - `measureDiversity(file): number`
      - `measureLengthAdequacy(file): number`
      - `calculateTotalScore(breakdown): QualityScore`
  - **QualityReportGenerator**:
    - 책임: Markdown/HTML 리포트 생성
    - 입력: QualityScore
    - 출력: Report 파일 (Markdown/HTML)
  - **QualityHistoryManager**:
    - 책임: 품질 이력 저장 및 조회
    - 입력: QualityScore
    - 출력: JSON 파일

- [ ] **Step 1.7**: 품질 메트릭 상세 정의 (5가지 카테고리)
  - **1. 구조적 품질 (25점)**:
    - 헤더 레벨 적절성 (5점)
    - 섹션 순서 (5점)
    - 마크다운 문법 (10점)
    - UTF-8 인코딩 (5점)
  - **2. 완성도 (30점)**:
    - 필수 섹션 존재 (15점)
    - 섹션 내 필수 요소 (15점)
  - **3. 파싱 품질 (25점)**:
    - Overview 파싱 (5점)
    - Concepts 파싱 (5점)
    - Patterns 파싱 (5점)
    - Experiments 파싱 (5점)
    - Quiz 파싱 (5점)
  - **4. 콘텐츠 다양성 (10점)**:
    - Core Concepts 난이도 균형 (5점)
    - Quiz 타입 다양성 (5점)
  - **5. 길이 적절성 (10점)**:
    - Overview 길이 (3점)
    - Core Concepts 길이 (3점)
    - Code Patterns 길이 (2점)
    - Quiz 길이 (2점)

- [ ] **Step 1.8**: Specification Pattern 설계
  - **MinimumQualitySpecification**:
    - `isSatisfiedBy(qualityScore): boolean`
    - 조건: `qualityScore.total >= 90`
  - **SectionMinimumQualitySpecification**:
    - `isSatisfiedBy(sectionScore): boolean`
    - 조건: 각 섹션 점수 >= 해당 섹션 만점의 50%
  - **CompositeQualitySpecification**:
    - `and(spec1, spec2): Specification`
    - `or(spec1, spec2): Specification`

- [ ] **Step 1.9**: Value Object 불변성 설계
  - **QualityScore** (불변):
    - `file: string`
    - `totalScore: number`
    - `breakdown: QualityBreakdown`
    - `grade: QualityGrade`
    - `timestamp: ISO8601`
    - `sessionId: string`
  - **QualityBreakdown** (불변):
    - `structure: number`
    - `completeness: number`
    - `parseability: number`
    - `diversity: number`
    - `length: number`
  - **QualityGrade** (열거형):
    - `Pass | Review | Fail | Critical`

- [ ] **Step 1.10**: 도메인 모델 검증
  - 모든 요구사항이 도메인 모델에 반영되었는지 확인
  - Unit 5 Inception 문서와 일치하는지 확인
  - 누락된 개념이 없는지 확인

---

### Step 2: 도메인 설계 문서 작성 완료

- [ ] **Step 2.1**: `domain_design.md` 최종 검토
  - 문서 구조 확인:
    1. 도메인 개요
    2. Ubiquitous Language
    3. Bounded Context
    4. 도메인 모델 다이어그램
    5. Value Objects
    6. Domain Services
    7. Specifications
    8. Domain Events
    9. Business Rules
    10. 설계 결정사항 (Design Decisions)
  - 모든 섹션이 완성되었는지 확인

- [ ] **Step 2.2**: 설계 리뷰 준비
  - 사용자에게 검토 요청
  - [Question 1-3] 답변 확인
  - 승인 후 다음 단계 진행

---

## Phase 2.2: 논리적 설계 및 상세 설계

**산출물**: `logical_design.md`

### Step 3: 논리적 설계

- [ ] **Step 3.1**: 품질 측정 알고리즘 설계
  - 각 메트릭별 측정 로직 상세 설계
  - Shell Script로 구현 가능한 방식 설계
  - 기존 테스트 스크립트 재사용 방안

- [ ] **Step 3.2**: 데이터 구조 설계
  - JSON 스키마 정의 (QualityScore, QualityHistory)
  - 파일 저장 구조 설계 (`logs/quality-history/`)
  - Report 형식 설계 (Markdown, HTML)

- [ ] **Step 3.3**: 스크립트 간 인터페이스 설계
  - `measure-quality.sh` 입출력 정의
  - `generate-quality-report.sh` 입출력 정의
  - `generate-quality-dashboard.sh` 입출력 정의
  - 스크립트 간 데이터 전달 방식 (JSON 파일)

[Question 4]
**질문**: 품질 측정 결과를 표준 출력(stdout)으로도 출력할까요?

**옵션**:
- A. JSON 파일만 생성 (조용한 실행)
- B. JSON 파일 + stdout에 요약 출력
- C. JSON 파일 + stdout에 전체 출력

**권장**: B (사용자 피드백 + 파이프라인 통합 가능)

[Answer 4]


- [ ] **Step 3.4**: content-validator 통합 설계
  - content-validator가 품질 측정을 어떻게 호출하는지 설계
  - IMPROVEMENT_NEEDED 생성 로직 설계
  - VALIDATION_SCORE 업데이트 방식 설계

- [ ] **Step 3.5**: 오류 처리 설계
  - 파싱 실패 시 처리 방식
  - 파일 없음/권한 오류 처리
  - 부분 측정 가능 여부 (일부 섹션만 측정)

- [ ] **Step 3.6**: 성능 최적화 설계
  - 불필요한 파일 읽기 최소화
  - 캐싱 전략 (동일 파일 재측정 방지)
  - 병렬 처리 가능 여부 (섹션별 독립 측정)

---

### Step 4: 상세 설계

- [ ] **Step 4.1**: `measure-quality.sh` 상세 설계
  - 함수 목록:
    - `measure_structure_quality(file): number`
    - `measure_completeness(file): number`
    - `measure_parseability(file): number`
    - `measure_diversity(file): number`
    - `measure_length_adequacy(file): number`
    - `calculate_total_score(breakdown): JSON`
    - `get_grade(score): string`
    - `save_quality_history(qualityScore): void`
  - 각 함수의 Pseudo-code 작성

- [ ] **Step 4.2**: `generate-quality-report.sh` 상세 설계
  - 입력: QualityScore JSON
  - 출력: Markdown Report
  - Report 템플릿 설계
  - Improvement Priorities 알고리즘 설계

- [ ] **Step 4.3**: `generate-quality-dashboard.sh` 상세 설계
  - 입력: Quality History JSON 파일들
  - 출력: HTML Dashboard
  - Chart.js 사용 방식
  - 차트 종류:
    - 전체 파일 품질 분포 (히스토그램)
    - 섹션별 평균 점수 (레이더 차트)
    - 시간별 품질 트렌드 (라인 차트)
    - 개선 필요 파일 목록 (테이블)

- [ ] **Step 4.4**: content-validator 프롬프트 업데이트 설계
  - 기존 프롬프트에 품질 측정 단계 추가
  - IMPROVEMENT_NEEDED 생성 로직 상세화
  - 개선 우선순위 결정 방식 명시

- [ ] **Step 4.5**: `logical_design.md` 최종 검토
  - 모든 알고리즘이 구현 가능한지 확인
  - Shell Script로 구현 가능한 방식인지 검증
  - 성능 병목 지점 파악

---

## Phase 2.3: 구현 및 테스트

**산출물**: 실제 스크립트 파일들

### Step 5: 품질 측정 스크립트 구현

- [ ] **Step 5.1**: `scripts/measure-quality.sh` 구현
  - 헤더 및 환경 설정
  - 5가지 측정 함수 구현
  - JSON 출력 구현
  - Quality History 저장 구현

- [ ] **Step 5.2**: 구조적 품질 측정 함수 구현
  - 헤더 레벨 체크
  - 섹션 순서 체크
  - 마크다운 문법 체크
  - UTF-8 인코딩 체크

- [ ] **Step 5.3**: 완성도 측정 함수 구현
  - 필수 섹션 존재 확인
  - 섹션 내 필수 요소 확인

- [ ] **Step 5.4**: 파싱 품질 측정 함수 구현
  - 기존 테스트 스크립트 재사용
  - 각 테스트 스크립트 실행 및 결과 수집

- [ ] **Step 5.5**: 콘텐츠 다양성 측정 함수 구현
  - Easy/Normal/Expert 길이 균형 체크
  - Quiz 타입 다양성 체크

- [ ] **Step 5.6**: 길이 적절성 측정 함수 구현
  - 각 섹션 줄 수 계산
  - 기준 범위와 비교

---

### Step 6: 품질 리포트 생성기 구현

- [ ] **Step 6.1**: `scripts/generate-quality-report.sh` 구현
  - JSON 입력 파싱
  - Markdown 템플릿 적용
  - Improvement Priorities 계산

- [ ] **Step 6.2**: Improvement Priorities 알고리즘 구현
  - Impact 계산 (점수 증가량)
  - Effort 추정 (Low/Medium/High)
  - 우선순위 정렬

- [ ] **Step 6.3**: Report 형식 구현
  - Score Breakdown 테이블
  - Section-Level Scores
  - Improvement Priorities
  - Quality Grade 요약

---

### Step 7: 품질 대시보드 생성기 구현

- [ ] **Step 7.1**: `scripts/generate-quality-dashboard.sh` 구현
  - Quality History 파일 수집
  - JSON 데이터 집계
  - HTML 템플릿 생성

- [ ] **Step 7.2**: Chart.js 통합
  - CDN 링크 추가
  - 히스토그램 차트 구현
  - 레이더 차트 구현
  - 라인 차트 구현

- [ ] **Step 7.3**: 대시보드 UI 구현
  - HTML 레이아웃
  - CSS 스타일링
  - 반응형 디자인

---

### Step 8: content-validator 통합

- [ ] **Step 8.1**: `.claude/agents/content-validator.md` 업데이트
  - Validation Process에 품질 측정 단계 추가
  - IMPROVEMENT_NEEDED 생성 로직 추가
  - VALIDATION_SCORE 업데이트 방식 명시

- [ ] **Step 8.2**: 통합 테스트
  - content-validator가 measure-quality.sh 호출 확인
  - VALIDATION_SCORE가 올바르게 기록되는지 확인
  - IMPROVEMENT_NEEDED가 올바르게 생성되는지 확인

---

### Step 9: 테스트 및 검증

- [ ] **Step 9.1**: `test/test-quality-metrics.sh` 구현
  - 각 측정 함수 단위 테스트
  - 전체 품질 측정 통합 테스트
  - Edge case 테스트 (빈 파일, 파싱 실패 등)

- [ ] **Step 9.2**: 실제 콘텐츠로 품질 측정 테스트
  - 고품질 콘텐츠 샘플 (90점 이상 예상)
  - 중간 품질 콘텐츠 샘플 (75-89점 예상)
  - 저품질 콘텐츠 샘플 (60-74점 예상)

- [ ] **Step 9.3**: 품질 리포트 검증
  - 리포트가 읽기 쉬운지 확인
  - Improvement Priorities가 유용한지 확인
  - 개선 제안이 실행 가능한지 확인

- [ ] **Step 9.4**: 품질 대시보드 검증
  - 차트가 올바르게 렌더링되는지 확인
  - 데이터가 정확한지 확인
  - 브라우저 호환성 확인

---

### Step 10: 문서화 및 최종 검토

- [ ] **Step 10.1**: 사용자 가이드 작성
  - `USAGE.md`: 스크립트 사용법
  - 예시 명령어
  - 출력 형식 설명

- [ ] **Step 10.2**: 품질 메트릭 명세 최종 작성
  - `docs/aidlc-docs/specifications/quality-metrics-spec.md`
  - 5가지 카테고리 상세 설명
  - 측정 방법 문서화

- [ ] **Step 10.3**: 코드 리뷰 및 정리
  - 코드 스타일 일관성 확인
  - 주석 추가/정리
  - 불필요한 코드 제거

- [ ] **Step 10.4**: 최종 통합 테스트
  - content-generator-v7.sh와 통합 테스트
  - 전체 파이프라인 동작 확인

---

### Step 11: 배포 준비

- [ ] **Step 11.1**: 스크립트 실행 권한 설정
  - `chmod +x scripts/measure-quality.sh`
  - `chmod +x scripts/generate-quality-report.sh`
  - `chmod +x scripts/generate-quality-dashboard.sh`

- [ ] **Step 11.2**: 품질 기준선 설정
  - 기존 고품질 콘텐츠로 기준선 설정
  - 최소 품질 점수 검증 (90점)

- [ ] **Step 11.3**: README 업데이트
  - 품질 측정 시스템 섹션 추가
  - 사용 예시 추가

---

## 예상 산출물

### 설계 문서 (3개)
1. `docs/aidlc-docs/construction/unit-05-quality-metrics/domain_design.md`
2. `docs/aidlc-docs/construction/unit-05-quality-metrics/logical_design.md`
3. `docs/aidlc-docs/construction/unit-05-quality-metrics/plan.md` (현재 파일)

### 명세 문서 (1개)
4. `docs/aidlc-docs/specifications/quality-metrics-spec.md`

### 스크립트 (3개)
5. `scripts/measure-quality.sh`
6. `scripts/generate-quality-report.sh`
7. `scripts/generate-quality-dashboard.sh`

### 테스트 (1개)
8. `test/test-quality-metrics.sh`

### 에이전트 업데이트 (1개)
9. `.claude/agents/content-validator.md` (업데이트)

### 사용자 문서 (1개)
10. `docs/aidlc-docs/construction/unit-05-quality-metrics/USAGE.md`

---

## 타임라인

**Phase 2.1 (현재)**: DDD 도메인 모델 설계
- Step 0: 준비 작업 (1일)
- Step 1-2: 도메인 모델 설계 (2일)
- **예상 기간**: 3일

**Phase 2.2**: 논리적 설계 및 상세 설계
- Step 3: 논리적 설계 (2일)
- Step 4: 상세 설계 (2일)
- **예상 기간**: 4일

**Phase 2.3**: 구현 및 테스트
- Step 5-7: 구현 (5일)
- Step 8: 통합 (1일)
- Step 9: 테스트 (2일)
- Step 10: 문서화 (1일)
- Step 11: 배포 준비 (1일)
- **예상 기간**: 10일

**총 예상 기간**: 17일 (Inception 문서의 9일 대비 상세 작업으로 증가)

---

## 리스크 및 완화 방안

| 리스크 | 영향 | 확률 | 완화 방안 |
|--------|------|------|-----------|
| 메트릭이 실제 품질을 반영하지 못함 | 높음 | 중간 | 실제 콘텐츠 샘플로 메트릭 검증, 피드백 반영 |
| 점수 계산 로직 복잡도 | 중간 | 높음 | 단계적 개발, 각 메트릭 독립 테스트 |
| 품질 기준이 너무 엄격 (90점) | 중간 | 중간 | 기존 고품질 콘텐츠를 기준선으로 설정, 필요시 조정 |
| 대시보드 유지보수 부담 | 낮음 | 낮음 | 정적 HTML + CDN, 서버 불필요 |
| Shell Script 성능 이슈 | 중간 | 낮음 | 불필요한 파일 읽기 최소화, 캐싱 전략 |

---

## 의존성

### 입력 의존성
- **Unit 1**: Work Status Markers에 VALIDATION_SCORE 기록
- **Unit 2**: 계약 명세에서 품질 기준 참조
- **Unit 3**: content-validator 프롬프트 업데이트
- **Unit 4**: execution-summary.json에서 품질 데이터 집계

### 출력 의존성
- 없음 (마지막 Unit)

---

## 성공 기준

1. **정량화**: 모든 품질 차원이 숫자로 측정 가능
2. **재현성**: 동일 파일은 항상 동일 점수
3. **유용성**: 품질 리포트를 보고 개선 방향 즉시 파악 가능
4. **자동화**: 수동 개입 없이 품질 측정 및 리포트 생성
5. **통합**: content-validator와 seamless 통합

---

## 다음 단계

**현재 단계**: Phase 2.1 - Step 0 (준비 작업)

**다음 단계**: Step 0.1 완료 후 사용자 검토 요청

**진행 방식**:
1. Step 0.1-0.5 완료
2. Step 1.1-1.10 완료 (`domain_design.md` 작성)
3. Step 2.1-2.2 완료 (설계 리뷰 요청)
4. **사용자 승인 후** Phase 2.2로 진행

---

**Note**: 이 계획은 AI-DLC 방법론을 따르며, 사용자 승인 없이 중요한 결정을 내리지 않습니다. 각 Question에 대한 답변을 받은 후 다음 단계로 진행합니다.
