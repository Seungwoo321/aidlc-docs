# Construction Phase - 작업 계획서

**목표**: 제대로 된 7개 Filter 계약 문서 작성 (향후 올바른 구현의 사양)

**작성일**: 2025-10-13
**단계**: Construction Phase - Unit 1 (Filter 계약 명시화)

---

## 작업 단계

### 1단계: 분석 대상 파일 확인 및 이해

- [ ] 7개 에이전트 프롬프트 파일 목록 확인 (`.claude/agents/*.md`)
- [ ] 파서 테스트 파일 목록 확인 (`test/test-*.mjs`)
- [ ] 실제 산출물 샘플 디렉터리 확인 (`public/content/ko/`)
- [ ] 각 파일의 역할과 관계 이해

**예상 소요 시간**: 30분

---

### 2단계: 계약 정의 방법론 수립

#### 2.1 에이전트 프롬프트 분석 방법

- [x] 각 프롬프트에서 참고할 정보 정의:
  * 역할 및 책임 (힌트)
  * 입력 데이터 (참고)
  * 출력 형식 (참고)
  * Work Status Markers 언급
  * 품질 가이드라인 (참고)
  * 주의사항 및 제약

**주의**: 현재 프롬프트는 참고 수준, 제대로 된 계약은 직접 정의

**방법론 수립 완료**:
- overview-writer.md 샘플 분석 완료
- 프롬프트 구조 매핑 완료 (Core Mission, Workflow, Specifications 등)
- 계약 항목별 정보 추출 방법 정의

#### 2.2 파서 테스트 분석 방법

- [x] 테스트 파일(파서 함수)에서 추출할 정보 정의:
  * 파싱 가능한 구조적 요구사항 (필수 섹션, 헤딩 레벨)
  * 파서가 인식하는 마크다운 패턴
  * 파싱 성공 조건 (최소 구조)

**주의**: 5개 파서 테스트는 자동 검증이 아니라 결과 출력만 함
- 파싱 함수 호출 → 결과만 표시
- LLM이 출력 보고 판단하는 구조
- **구조적 요구사항만 추출 가능**
- 품질 기준은 에이전트 프롬프트와 산출물 샘플에서 추출

**방법론 수립 완료**:
- markdownParser.ts 분석 완료 (parseOverview 함수 등)
- 구조적 요구사항 추출 방법 정의
- **불일치 발견**: 프롬프트(코드 블록 금지) vs 파서(코드 블록 처리) → 계약 정의 시 해결 필요

#### 2.3 산출물 샘플 분석 방법

- [x] 실제 생성된 콘텐츠에서 참고할 정보:
  * 실제 출력 형식 (참고)
  * 평균 길이 (참고)
  * Work Status Markers 사용 패턴
  * 섹션 구조 (참고)

**주의**: 샘플은 현재 상태 확인용, 제대로 된 계약은 직접 정의

**방법론 수립 완료**:
- 3개 샘플 확인 (01-03 토픽)
- 각 섹션 분석 방법 정의
- Work Status Markers 패턴 추출 방법 정의
- 불일치 식별 방법 정의

**예상 소요 시간**: 1시간

---

### 3단계: Filter 계약 문서 작성 순서 결정

#### 작성 순서 (파이프라인 순서대로)

1. [x] **content-initiator** (첫 번째 Filter) - 준비 완료
   - 입력: category.yaml, 토픽 정보
   - 출력: 초기 마크다운 파일, Work Status Markers

2. [x] **overview-writer** - 준비 완료
   - 입력: 초기 파일 + Work Request Marker
   - 출력: ## 개요 섹션

3. [x] **concepts-writer** - 준비 완료
   - 입력: overview 완료된 파일
   - 출력: ## 핵심 개념 섹션

4. [x] **visualization-writer** ⚠️ 특수 처리 - 준비 완료
   - 입력: concepts 완료된 파일
   - 출력: 시각화 컴포넌트 정보
   - **주의**: 파서 테스트 없음 → 샘플 + 렌더링 로직 분석하여 계약 생성

5. [x] **practice-writer** - 준비 완료
   - 입력: concepts + visualization 완료된 파일
   - 출력: ## 실습 섹션

6. [x] **quiz-writer** - 준비 완료
   - 입력: 모든 학습 섹션 완료된 파일
   - 출력: ## 퀴즈 섹션

7. [x] **content-validator** (마지막 Filter) - 준비 완료
   - 입력: 완성된 콘텐츠
   - 출력: 검증 결과, 개선 지시

[Question] 이 순서가 적절한가요? 다른 순서로 작성하는 것이 더 효율적일까요?

[Answer] 승인됨 - 파이프라인 순서대로 작성

**3단계 완료**: 작성 순서 확정, 이제 4단계(각 Filter 계약 문서 작성)로 진행

**예상 소요 시간**: 각 Filter당 2-3시간, 총 14-21시간 (2-3일)

---

### 4단계: 각 Filter 계약 문서 작성

**진행 상태**: 완료 ✅
- [x] content-initiator-contract.md (완료)
- [x] overview-writer-contract.md (완료)
- [x] concepts-writer-contract.md (완료)
- [x] visualization-writer-contract.md (완료)
- [x] practice-writer-contract.md (완료)
- [x] quiz-writer-contract.md (완료)
- [x] content-validator-contract.md (완료)

**완료 시각**: 2025-10-13 (약 6시간 소요)

각 Filter에 대해 다음 섹션을 포함한 계약 문서 작성:

#### 문서 구조 템플릿

```markdown
# {Filter명} Contract

## 1. 개요
- Filter 이름
- 역할 및 책임
- Pipeline에서의 위치

## 2. 입력 계약 (Input Contract)
- 필수 입력 데이터
- 입력 파일 경로
- 필수 섹션 (선행 Filter의 출력)
- Work Status Markers 확인
- 선행 조건 (Preconditions)

## 3. 출력 계약 (Output Contract)
- 생성할 섹션
- 섹션 구조 (하위 섹션)
- 최소/최대 길이
- Work Status Markers 업데이트
- 후행 조건 (Postconditions)

## 4. 품질 기준 (Quality Criteria)
- 파서 테스트 항목 (test/test-*.mjs 기반)
- 구조적 요구사항
- 내용적 요구사항
- 검증 체크리스트

## 5. 오류 처리 (Error Handling)
- 오류 유형 (입력 오류, 생성 오류, 검증 오류)
- 오류 메시지 형식
- 재시도 전략
- 실패 시 Work Status Markers 업데이트

## 6. 성능 기준 (Performance Criteria)
- 평균 처리 시간 (추정 범위, 이후 측정으로 정밀화)
- 출력 크기 범위
- 리소스 사용량 (토큰 소비 등)

## 7. 분석 근거 (Analysis Evidence)
- 프롬프트 파일에서 참고한 정보
- 파서 테스트에서 참고한 정보
- 실제 산출물 샘플 분석 결과
- 파일명:줄번호 참조 (참고한 부분 명시)
```

[Question] 각 섹션의 상세 수준은 어느 정도가 적절한가요? 예시를 포함해야 할까요?

[Answer] 승인됨 - 옵션 B (상세 + 예시)
- 각 계약 항목에 상세 설명 포함
- 실제 마크다운 예시 포함 (입력/출력 형식)
- 파일 경로와 줄번호 참조 포함
- Filter 계약은 설계 문서 (design doc) 표준 적용

[Question] 성능 기준의 평균 처리 시간은 실제로 측정해야 하나요, 아니면 추정으로 작성해도 되나요?

[Answer] 승인됨 - D-2 Revised (개발 단계 반복 측정)
- 측정 범위: AI-DLC 개발 사이클 동안만 (Bolt 1, 2, 3...), 시스템 완성 후 일상 모니터링 ❌
- 측정 목적: 성능 베이스라인 확보 + 대량 생산 작업시간 예상 근거
- 1차 측정: Unit 5 완료 직후 (10-20개 콘텐츠)
- Filter 계약 문서: 초기 추정 범위 기재 (예: 30-60초), 이후 Bolt에서 정밀화
- 종료: 품질 목표 달성 & 충분한 성능 데이터 확보 시

---

### 5단계: 통합 요약 문서 작성

**진행 상태**: 완료 ✅
- [x] `filter-contracts-summary.md` 작성
- [x] 7개 Filter의 I/O 관계를 표 형식으로 정리
- [x] 데이터 흐름 다이어그램 (텍스트 기반)
- [x] 각 Filter의 핵심 계약 요약

**완료 시각**: 2025-10-13

**표 형식 예시**:

```markdown
| Filter | 입력 | 출력 | 품질 기준 | 평균 시간 |
|--------|------|------|-----------|-----------|
| content-initiator | category.yaml | 초기 파일 + 마커 | 파일 생성 | 5초 |
| overview-writer | 초기 파일 | ## 개요 (4개 하위) | 4개 섹션 필수 | 30초 |
| ... | ... | ... | ... | ... |
```

**예상 소요 시간**: 2시간

---

### 6단계: 계약 완전성 및 일관성 검증

**진행 상태**: 완료 ✅
- [x] 각 Filter의 출력 계약과 다음 Filter의 입력 계약 일치 확인
- [x] Work Status Markers 흐름 일관성 확인
- [x] 품질 기준이 명확하고 검증 가능한지 확인
- [x] 용어 및 개념 일관성 확인
- [x] 누락된 계약 항목 확인
- [x] **계약의 실행 가능성 확인** (Unit 3, 4에서 구현 가능한가?)

**완료 시각**: 2025-10-13
**검증 결과**: 7개 항목 모두 통과 ✅

**검증 체크리스트**:
- [ ] Filter N의 출력 = Filter N+1의 입력 (명확히 정의됨)
- [ ] 모든 Work Status Markers가 정의됨
- [ ] 품질 기준이 명확하고 검증 가능
- [ ] 7개 계약 문서의 형식 일관성
- [ ] 용어 일관성 (필터, 에이전트, 서브에이전트 등)
- [ ] **계약 완전성** (불완전한 부분 없음)

**예상 소요 시간**: 1-2시간

---

### 7단계: 문서 최종 검토 및 승인 요청

**진행 상태**: 완료 ✅
- [x] 각 계약 문서 품질 확인
  * 명확성: 모호함 없이 명시적 ✅
  * 완전성: 누락 없이 완전 ✅
  * 실행 가능성: Unit 3, 4에서 구현 가능 ✅
- [x] 요약 문서 완성도 확인 ✅
- [x] 맞춤법 및 형식 검토 ✅
- [x] 파일 경로 및 링크 확인 ✅
- [x] **사양 문서로서의 적합성 확인** ✅
- [x] 사용자 최종 검토 요청 ✅
- [x] 사용자 승인 완료 ✅

**완료 시각**: 2025-10-13
**승인 상태**: ✅ 승인됨

**예상 소요 시간**: 30분

---

## 분석 대상 파일 (참고용)

### 에이전트 프롬프트 (7개)
```
.claude/agents/content-initiator.md
.claude/agents/overview-writer.md
.claude/agents/concepts-writer.md
.claude/agents/visualization-writer.md
.claude/agents/practice-writer.md
.claude/agents/quiz-writer.md
.claude/agents/content-validator.md
```

### 파서 테스트 (5개)
```
test/test-overview.mjs
test/test-concepts.mjs
test/test-patterns.mjs (practice)
test/test-experiments.mjs (practice)
test/test-quiz-raw.mjs
```

**특이사항**:
- 5개 파서 테스트는 구조적 요구사항만 추출 (자동 검증 없음)
- test-visualization-component.mjs, test-visualization-parsing.mjs는 제외 (검증 안 됨, 표준 패턴 없음)

[Question] 다른 테스트 파일도 분석해야 하나요? (예: test-metadata.mjs 등)

[Answer] 승인됨 - 5개 파서 테스트만 분석
- 분석 대상: test-overview.mjs, test-concepts.mjs, test-patterns.mjs, test-experiments.mjs, test-quiz-raw.mjs
- 제외: test-visualization-*.mjs (검증 안 됨, 표준 패턴 없음)
- 추출 범위: 구조적 요구사항만 (자동 검증 규칙 없음)

### 산출물 샘플
```
public/content/ko/javascript-core-concepts/01-variables/*.md
```

[Question] 어떤 카테고리/서브카테고리의 샘플을 분석해야 하나요? 여러 개를 분석해야 할까요?

[Answer] 승인됨 - 검증된 샘플만 분석
- 분석 대상: public/content/ko/javascript-core-concepts/01-variables/ 하위 01-03 토픽
  * 01-var-problems.md
  * 02-let-vs-var.md
  * 03-const-immutability.md
- 제약사항:
  * 3개 샘플로 통계적 신뢰도는 낮음
  * 현재 구현 상태 참고용
  * **목적**: 제대로 된 계약 정의 (참고만, 그대로 문서화 ❌)
- 필요시 조치: 계약 정의 시 추가 참고 자료 필요하면 요청

---

## 산출물 목록

### 주요 산출물 (8개)

1. `aidlc-docs/construction/filters/content-initiator-contract.md`
2. `aidlc-docs/construction/filters/overview-writer-contract.md`
3. `aidlc-docs/construction/filters/concepts-writer-contract.md`
4. `aidlc-docs/construction/filters/visualization-writer-contract.md`
5. `aidlc-docs/construction/filters/practice-writer-contract.md`
6. `aidlc-docs/construction/filters/quiz-writer-contract.md`
7. `aidlc-docs/construction/filters/content-validator-contract.md`
8. `aidlc-docs/construction/filter-contracts-summary.md`

---

## 중요 원칙

### 🎯 Unit 1의 본질적 목표
**제대로 된 7개 Filter 계약 문서 작성**
- 이 문서 = 향후 올바른 구현의 사양(specification)
- 이 문서 = Unit 3, 4 개선의 기준
- **문서가 제대로 되어야 함** ← 핵심 책임

### 📖 현재 구현의 위치
**참고 수준**
- 에이전트 프롬프트: 힌트, 아이디어
- 파서 테스트: 구조 패턴 참고
- 산출물 샘플: 현재 상태 확인
- 렌더링 로직: 동작 방식 이해
- **하지만**: 불완전하므로 그대로 따라서는 안 됨

### ✅ 해야 할 것
- **제대로 된 계약 문서 작성**
  * 명확한 I/O 계약 정의
  * 검증 가능한 품질 기준 정의
  * 실행 가능한 사양 작성
  * 완전성 확보
- **현재 구현 참고**
  * 참고하되 맹신하지 않음
  * 불완전한 부분은 보완/생성
  * 파일명:줄번호 참조 명시
- **문서 품질 최우선**
  * 명확성, 완전성, 실행 가능성

### ❌ 하지 말아야 할 것
- 현재 구현을 **그대로 문서화** (참고 수준일 뿐)
- 불완전한 계약을 **그대로 수용**
- 추측으로 계약 **작성** (분석 근거 필수)
- 기존 코드 **수정** (문서 작성만)

### 📋 작업 흐름
```
현재 구현 분석 (참고)
    ↓
제대로 된 계약 정의
    ↓
명시적 계약 문서 작성
    ↓
(향후) Unit 3, 4에서 이 문서 기반으로 구현 개선
```

---

## 예상 소요 시간 총계

- 1단계: 30분
- 2단계: 1시간
- 3단계: 0분 (순서 결정만)
- 4단계: 14-21시간 (2-3일)
- 5단계: 2시간
- 6단계: 1-2시간
- 7단계: 30분

**총**: 19-25시간 (약 2.5-3일)

---

## 다음 단계

계획 승인 후:
1. 1단계부터 순차적으로 실행
2. 각 단계 완료 시 체크박스 체크
3. 질문사항 답변 받은 후 해당 단계 진행
4. 7단계 완료 후 Unit 2 (Pipe 메커니즘 명시화)로 진행

---

## 참고 문서

- `docs/aidlc-docs/inception/units/unit-1-filter-contracts.md` (Unit 1 정의)
- `docs/aidlc-docs/prompts/03-construction-filter-contracts.md` (프롬프트 3)
- `.claude/handoff-guide.md` (에이전트 협업 가이드)

---

**작성 완료**: 2025-10-13
**검토 요청**: 계획 검토 및 질문 답변 부탁드립니다.
