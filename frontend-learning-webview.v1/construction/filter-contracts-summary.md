# Filter Contracts Summary

**작성일**: 2025-10-13
**버전**: 1.0.0
**목적**: 7개 Filter의 I/O 관계 및 핵심 계약 요약

---

## 1. Filter I/O 관계 표

| # | Filter | 입력 | 출력 | 핵심 품질 기준 | 평균 시간 (추정) |
|---|--------|------|------|---------------|-----------------|
| 1 | content-initiator | category.yaml + 토픽 정보 | 초기 마크다운 파일 + Work Status Markers | 5개 필수 마커 존재 | 1-3초 |
| 2 | overview-writer | 초기 파일 (frontmatter + 마커) | # Overview 섹션 (Introduction + 3-4 subsections) | 4-6개 subsection, 50-100줄 | 3-7분 |
| 3 | concepts-writer | Overview 완료 파일 | # Core Concepts 섹션 (2-3 Concepts, Easy/Normal/Expert) | Concept당 3단계 필수, Visualization 메타데이터 | 10-20분 |
| 4 | visualization-writer | Concepts 완료 파일 | React 컴포넌트 (tsx) + index.ts export | 컴포넌트 비어있지 않음, index.ts export 존재 (Critical!) | 5-15분 |
| 5 | practice-writer | Concepts + Visualization 완료 파일 | # Code Patterns + # Experiments 섹션 | Pattern 6개 필드, Experiment 5개 필드, Parser 통과 | 10-20분 |
| 6 | quiz-writer | 모든 학습 섹션 완료 파일 | # Quiz 섹션 (8-12 문제, 6가지 유형) | 유형 다양성, 난이도 분포(1-2:30%, 3:40%, 4-5:30%), Parser 통과 | 15-25분 |
| 7 | content-validator | 완성된 콘텐츠 (5개 섹션) | 검증 보고서 + 점수 + 개선 항목 (선택) | 100점: 완료, < 100점: 개선 요청 | 5-10분 |

**총 소요 시간**: 약 50-80분 (1개 콘텐츠)

---

## 2. 데이터 흐름 다이어그램

```
[category.yaml]
    |
    | (토픽 정보)
    v
┌─────────────────────┐
│ content-initiator   │ Work Status Markers 초기화
│ (1-3초)             │
└─────────────────────┘
    | Frontmatter + Markers
    v
┌─────────────────────┐
│ overview-writer     │ # Overview (학습 동기, 핵심 특징)
│ (3-7분)             │
└─────────────────────┘
    | Overview 완료
    v
┌─────────────────────┐
│ concepts-writer     │ # Core Concepts (Easy/Normal/Expert × 2-3)
│ (10-20분)           │ + Visualization 메타데이터
└─────────────────────┘
    | Concepts 완료 + Viz 메타데이터
    v
┌─────────────────────┐
│ visualization-writer│ React 컴포넌트 생성 (src/components/visualizations/)
│ (5-15분)            │ + index.ts export 등록 (Critical!)
└─────────────────────┘
    | 시각화 통합 완료
    v
┌─────────────────────┐
│ practice-writer     │ # Code Patterns (Short/Full + Explanation)
│ (10-20분)           │ + # Experiments (Instructions + Initial Code)
└─────────────────────┘
    | Practice 완료
    v
┌─────────────────────┐
│ quiz-writer         │ # Quiz (8-12 문제, 6가지 유형)
│ (15-25분)           │
└─────────────────────┘
    | Quiz 완료
    v
┌─────────────────────┐
│ content-validator   │ 품질 검증 (100점 만점)
│ (5-10분)            │ 100점: ✅ 완료
└─────────────────────┘ < 100점: ⬅️ 개선 요청 (특정 Filter로 핸드오프)
    |
    v
[완성된 학습 콘텐츠]
(100점 달성 시)
```

---

## 3. Filter 핵심 계약 요약

### 3.1 content-initiator

**역할**: Pipeline 시작, Work Status Markers 초기화

**핵심 계약**:
- **입력**: category.yaml (토픽 정의)
- **출력**:
  - 초기 마크다운 파일 (`---\n---\n` frontmatter만)
  - Work Status Markers (5개 필수 마커)
- **다음 Filter**: overview-writer
- **금지 사항**: ❌ 콘텐츠 작성 (마커만 추가)

**Critical Point**: Work Status Markers 형식 정확성

---

### 3.2 overview-writer

**역할**: 학습 동기 부여, 주제 소개

**핵심 계약**:
- **입력**: 초기 파일 (frontmatter + Work Status Markers)
- **출력**:
  - `# Overview` 섹션
  - Introduction (1-2 단락, 3-5 문장)
  - 3-4개 subsection (H2)
  - 50-100줄
- **품질 기준**:
  - ❌ H3 이상 금지
  - ❌ 코드 블록 금지 (개념만)
  - ❌ 표 금지
- **다음 Filter**: concepts-writer

**Critical Point**: 학습 동기 부여 (왜 배워야 하는가)

---

### 3.3 concepts-writer

**역할**: 핵심 개념 3단계 난이도 설명 (프로젝트의 핵심 기능)

**핵심 계약**:
- **입력**: Overview 완료 파일
- **출력**:
  - `# Core Concepts` 섹션
  - 2-3개 Concept
  - 각 Concept: Easy/Normal/Expert 3단계 필수
  - Visualization 메타데이터 (선택)
- **품질 기준**:
  - **Easy**: 중학생 이해 가능, 일상 비유, 이모지, 코드 ❌
  - **Normal**: `#### Text` / `#### Code:` 교차 패턴, 5-10줄 코드
  - **Expert**: ECMAScript 명세 인용, V8 엔진 설명, 성능 영향
- **다음 Filter**: visualization-writer

**Critical Point**: 3단계 난이도 시스템 정확한 구현

---

### 3.4 visualization-writer

**역할**: 추상적 개념을 인터랙티브 시각화로 구체화

**핵심 계약**:
- **입력**: Concepts 완료 파일 (Visualization 메타데이터 포함)
- **출력**:
  - React 컴포넌트 (`src/components/visualizations/{category}/{ComponentName}.tsx`)
  - **index.ts export** (Critical!)
- **품질 기준**:
  - Props interface 정의 (`ComponentNameProps`)
  - HTML/CSS 기반 (SVG 최소화)
  - TypeScript 컴파일 성공
  - **index.ts export 존재** (가장 흔한 실패 원인)
- **다음 Filter**: practice-writer

**Critical Point**: index.ts export 누락 시 UI에 "준비중" 표시됨

---

### 3.5 practice-writer

**역할**: 실습으로 개념 체득 (이론 → 코드 확인 → 직접 실험)

**핵심 계약**:
- **입력**: Concepts + Visualization 완료 파일
- **출력**:
  - `# Code Patterns` 섹션 (2-3개 Pattern)
    - Short Code (3-5 statements) + Full Code (10-20 statements)
    - Easy/Normal/Expert Explanation
  - `# Experiments` 섹션 (1-2개 Experiment)
    - Instructions (5-8 steps) + Initial Code (10-25 lines)
- **품질 기준**:
  - Pattern 6개 필수 필드, Experiment 5개 필드
  - Anti-pattern vs Solution 대조
  - TODO는 instruction comment로만 (미완성 코드 ❌)
  - Parser 테스트 통과
- **다음 Filter**: quiz-writer

**Critical Point**: 실행 가능한 완전한 코드

---

### 3.6 quiz-writer

**역할**: 학습 내용 검증

**핵심 계약**:
- **입력**: 모든 학습 섹션 완료 파일
- **출력**:
  - `# Quiz` 섹션 (8-12개 문제)
  - 6가지 유형 (multiple-choice, true-false, text-fill-in-blank, fill-in-the-blank, code-review, output-prediction)
- **품질 기준**:
  - 유형 다양성 (각 유형 최소 1개)
  - 난이도 분포: 1-2(30%), 3(40%), 4-5(30%)
  - 점진적 힌트 (방향 → 단서 → 거의 정답)
  - Parser 테스트 통과
- **다음 Filter**: content-validator

**Critical Point**: 난이도 균형 및 유형 다양성

---

### 3.7 content-validator

**역할**: 최종 품질 검증 및 완료 처리

**핵심 계약**:
- **입력**: 완성된 콘텐츠 (5개 섹션)
- **출력**:
  - 검증 보고서 (100점 만점 점수)
  - **100점**: PROGRESS: 완료 (COMPLETE)
  - **< 100점**: IMPROVEMENT_NEEDED + 특정 Filter로 핸드오프
- **품질 기준**:
  - Overview(20) + Concepts(25) + Patterns(20) + Experiments(15) + Quiz(20)
  - **Visualization 3단계 검증**: 메타데이터 + 파일 존재 + **index.ts export** (Critical!)
- **다음 Filter**: 없음 (최종 Filter) 또는 개선 대상 Filter

**Critical Point**: Visualization index.ts export 누락 시 추가 5점 차감

---

## 4. Work Status Markers 흐름

```
[START] content-initiator
    | CURRENT_AGENT: overview-writer, PROGRESS: 대기중
    v
[DONE] overview-writer
    | CURRENT_AGENT: concepts-writer, PROGRESS: 대기중
    v
[DONE] concepts-writer
    | CURRENT_AGENT: visualization-writer, PROGRESS: 대기중
    v
[DONE] visualization-writer (또는 [SKIP])
    | CURRENT_AGENT: practice-writer, PROGRESS: 대기중
    v
[DONE] practice-writer
    | CURRENT_AGENT: quiz-writer, PROGRESS: 대기중
    v
[DONE] quiz-writer
    | CURRENT_AGENT: content-validator, PROGRESS: 대기중
    v
[DONE] content-validator
    |
    ├─ 100점: [COMPLETE] 최종 완료
    |          CURRENT_AGENT: (비움), PROGRESS: 완료
    |
    └─ < 100점: [WAITING] 개선 요청
               CURRENT_AGENT: [improvement-target-agent]
               IMPROVEMENT_NEEDED: [구체적 개선 사항]
               (해당 Filter로 핸드오프)
```

---

## 5. 주요 의존성 체인

### 5.1 콘텐츠 흐름
```
category.yaml (토픽 정의)
  → 초기 파일
    → Overview (학습 동기)
      → Core Concepts (3단계 개념)
        → Visualization (시각화)
          → Code Patterns + Experiments (실습)
            → Quiz (검증)
              → 품질 검증 (100점)
```

### 5.2 파일 흐름
```
public/content/ko/{category}/{subcategory}/{topic-id}.md
  ← content-initiator: 생성
  ← overview-writer: Overview 추가
  ← concepts-writer: Core Concepts 추가
  ← practice-writer: Code Patterns, Experiments 추가
  ← quiz-writer: Quiz 추가
  ← content-validator: 검증

+ src/components/visualizations/{category}/{ComponentName}.tsx
    ← visualization-writer: 생성
+ src/components/visualizations/index.ts
    ← visualization-writer: export 추가 (Critical!)
```

### 5.3 검증 흐름
```
Parser Tests (구조 검증)
  test-overview.mjs → Overview 섹션
  test-concepts.mjs → Core Concepts 섹션
  test-patterns.mjs → Code Patterns 섹션
  test-experiments.mjs → Experiments 섹션
  test-quiz-raw.mjs → Quiz 섹션

+

Semantic Validation (의미 검증)
  content-validator → 5개 섹션 품질 평가 (100점 만점)
```

---

## 6. Critical Points 요약

| Filter | Critical Point | 실패 시 영향 |
|--------|---------------|-------------|
| content-initiator | Work Status Markers 정확성 | Pipeline 시작 실패 |
| overview-writer | 학습 동기 부여 | 학습자 참여 저하 |
| concepts-writer | 3단계 난이도 구현 | 프로젝트 핵심 기능 미달성 |
| visualization-writer | **index.ts export** | UI에 "준비중" 표시 (사용자 경험 저하) |
| practice-writer | 실행 가능한 완전한 코드 | 학습자가 실습 불가 |
| quiz-writer | 난이도 균형 | 평가 신뢰도 저하 |
| content-validator | Visualization 3단계 검증 | 불완전한 콘텐츠 통과 |

---

## 7. 품질 보증 메커니즘

### 7.1 구조적 검증
- **Parser Tests**: 5개 섹션 구조 검증 (자동)
- **TypeScript Compiler**: Visualization 컴포넌트 타입 검증 (자동)

### 7.2 의미적 검증
- **content-validator**: 100점 만점 점수 산정 (자동)
  - Overview: 20점
  - Core Concepts: 25점 (Visualization 5점 포함)
  - Code Patterns: 20점
  - Experiments: 15점
  - Quiz: 20점

### 7.3 개선 메커니즘
- **IMPROVEMENT_NEEDED**: 구체적 개선 사항 기록
- **우선순위**: 점수 차감 큰 항목부터 개선
- **반복**: 100점 달성할 때까지 재시도

---

## 8. 성능 특성

### 8.1 처리 시간 분포
```
content-initiator:     ~2% (1-3초)
overview-writer:       ~8% (3-7분)
concepts-writer:       ~30% (10-20분)
visualization-writer:  ~18% (5-15분)
practice-writer:       ~25% (10-20분)
quiz-writer:           ~35% (15-25분)
content-validator:     ~12% (5-10분)
```

### 8.2 병목 지점
1. **quiz-writer** (가장 오래 소요)
2. **concepts-writer** (복잡도 높음)
3. **practice-writer** (코드 생성 많음)

---

## 9. 확장 가능성

### 9.1 새로운 Filter 추가
- Pipeline 중간에 삽입 가능
- 선행/후행 Filter의 I/O 계약만 맞추면 됨
- Work Status Markers 흐름 유지

### 9.2 Filter 수정
- 각 Filter가 독립적
- 한 Filter 수정 시 I/O 계약만 유지하면 다른 Filter 영향 없음

---

## 10. 참고 문서

- `aidlc-docs/construction/filters/content-initiator-contract.md`
- `aidlc-docs/construction/filters/overview-writer-contract.md`
- `aidlc-docs/construction/filters/concepts-writer-contract.md`
- `aidlc-docs/construction/filters/visualization-writer-contract.md`
- `aidlc-docs/construction/filters/practice-writer-contract.md`
- `aidlc-docs/construction/filters/quiz-writer-contract.md`
- `aidlc-docs/construction/filters/content-validator-contract.md`
- `docs/aidlc-docs/inception/units/unit-1-filter-contracts.md`
- `docs/aidlc-docs/inception/units/unit-2-pipe-mechanism.md`

---

**작성 완료**: 2025-10-13
