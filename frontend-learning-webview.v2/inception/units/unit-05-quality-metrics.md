# Unit 5: 품질 측정 시스템 구축

## 개요

**목적**: Pass/Fail 이분법을 넘어 정량적이고 세분화된 품질 측정 시스템을 구축하여, 콘텐츠 품질을 객관적으로 평가하고 지속적 개선을 가능하게 한다.

**현재 문제점**:
- VALIDATION_SCORE가 0-100점이지만 계산 기준 불명확
- Pass/Fail만 제공하여 "어느 정도 좋은지" 알 수 없음
- 섹션별 품질 편차 파악 불가
- 개선 우선순위 결정 어려움
- 품질 트렌드 추적 불가

**개선 방향**:
- 세분화된 품질 메트릭 정의 (구조, 완성도, 파싱, 다양성 등)
- 섹션별 품질 점수 제공
- 품질 리포트 자동 생성
- 품질 트렌드 대시보드
- 개선 제안 우선순위화

## 범위

### In Scope
1. **품질 메트릭 정의**
   - 구조적 품질 (Structure Quality): 헤더 구조, 마크다운 형식
   - 완성도 (Completeness): 필수 요소 존재 여부
   - 파싱 품질 (Parseability): 파서 테스트 통과 여부
   - 콘텐츠 다양성 (Diversity): 3단계 난이도, 퀴즈 타입 다양성
   - 길이 적절성 (Length Adequacy): 최소/최대 길이 기준 충족

2. **품질 측정 스크립트 개발**
   - 섹션별 품질 점수 계산
   - 종합 품질 점수 계산
   - 품질 리포트 생성 (JSON, 마크다운)

3. **품질 대시보드 생성**
   - HTML 대시보드로 품질 시각화
   - 섹션별 점수 차트
   - 시간별 품질 트렌드

4. **개선 우선순위 알고리즘**
   - 가장 개선 효과가 큰 영역 식별
   - content-validator가 사용할 개선 제안 생성

5. **품질 기준선 설정**
   - 최소 품질 기준 (Minimum Viable Quality)
   - 목표 품질 기준 (Target Quality)
   - 우수 품질 기준 (Excellent Quality)

### Out of Scope
- AI 모델 평가 (콘텐츠만 평가, 모델 자체는 평가 X)
- 사용자 만족도 조사 (시스템 품질만, UX는 Out of Scope)
- 실시간 모니터링 (배치 분석만)

## 아키텍처 컨텍스트

**Pipeline Architecture 관점**:
- **Quality Sink**: 파이프라인 마지막 단계에서 품질 수집
- **Feedback Loop**: 품질 점수를 content-validator에게 피드백

**DDD 경량화 관점**:
- **Domain Metrics**: 품질 메트릭이 도메인 지식 표현
- **Value Object**: 품질 점수가 Value Object
- **Specification Pattern**: 품질 기준이 Specification

## 작업 항목

### 1. 품질 메트릭 명세 작성
**예상 산출물**: `docs/aidlc-docs/specifications/quality-metrics-spec.md`

**메트릭 카테고리**:

#### 1.1 구조적 품질 (Structure Quality) - 25점
- 헤더 레벨 적절성 (5점)
  - `#` 섹션 헤더만 사용 (개요, 콘텐츠, 패턴, 실험, 퀴즈)
  - `##` 하위 섹션 적절
  - `###` 이상 사용 금지 (Overview에서)
- 섹션 순서 (5점)
  - Overview → Core Concepts → Code Patterns → Experiments → Quiz 순서 준수
- 마크다운 문법 (10점)
  - 리스트 형식 올바름
  - 코드 블록 형식 올바름
  - 링크 형식 올바름
- UTF-8 인코딩 (5점)
  - 한글 정상 표시

#### 1.2 완성도 (Completeness) - 30점
- 필수 섹션 존재 (15점)
  - Overview (3점)
  - Core Concepts (3점)
  - Code Patterns (3점)
  - Experiments (3점)
  - Quiz (3점)
- 섹션 내 필수 요소 (15점)
  - Overview: 소개 문단, 핵심 특징, 실무 영향 (5점)
  - Core Concepts: 최소 3개 Concept, 각 Concept에 Easy/Normal/Expert (5점)
  - Code Patterns: 최소 3개 패턴 (2점)
  - Experiments: 최소 2개 실험 (2점)
  - Quiz: 최소 5개 문제 (1점)

#### 1.3 파싱 품질 (Parseability) - 25점
- Overview 파싱 (5점)
- Concepts 파싱 (5점)
- Patterns 파싱 (5점)
- Experiments 파싱 (5점)
- Quiz 파싱 (5점)

#### 1.4 콘텐츠 다양성 (Diversity) - 10점
- Core Concepts 난이도 균형 (5점)
  - Easy/Normal/Expert 길이 균형
- Quiz 타입 다양성 (5점)
  - 최소 3가지 타입 (multiple-choice, true-false, fill-in-the-blank 등)

#### 1.5 길이 적절성 (Length Adequacy) - 10점
- Overview: 50-100줄 (3점)
- Core Concepts: Concept당 최소 50줄 (3점)
- Code Patterns: 패턴당 최소 20줄 (2점)
- Quiz: 문제당 최소 10줄 (2점)

**총점: 100점**

### 2. 품질 측정 스크립트 개발
**예상 산출물**: `scripts/measure-quality.sh`

**스크립트 기능**:
```bash
#!/bin/bash
# Usage: ./scripts/measure-quality.sh [file.md]

# 1. 구조적 품질 측정
measure_structure_quality() {
    local file=$1
    local score=0

    # 헤더 레벨 체크
    # 섹션 순서 체크
    # 마크다운 문법 체크
    # UTF-8 인코딩 체크

    echo $score
}

# 2. 완성도 측정
measure_completeness() {
    local file=$1
    local score=0

    # 필수 섹션 존재 확인
    # 섹션 내 필수 요소 확인

    echo $score
}

# 3. 파싱 품질 측정
measure_parseability() {
    local file=$1
    local score=0

    # 각 테스트 스크립트 실행
    npx tsx test/test-overview.mjs "$file" && ((score+=5))
    npx tsx test/test-concepts.mjs "$file" && ((score+=5))
    npx tsx test/test-patterns.mjs "$file" && ((score+=5))
    npx tsx test/test-experiments.mjs "$file" && ((score+=5))
    npx tsx test/test-quiz-raw.mjs "$file" && ((score+=5))

    echo $score
}

# 4. 다양성 측정
measure_diversity() {
    local file=$1
    local score=0

    # Easy/Normal/Expert 균형
    # Quiz 타입 다양성

    echo $score
}

# 5. 길이 적절성 측정
measure_length_adequacy() {
    local file=$1
    local score=0

    # 각 섹션 줄 수 계산

    echo $score
}

# 종합 점수 계산
calculate_total_score() {
    local file=$1

    local structure=$(measure_structure_quality "$file")
    local completeness=$(measure_completeness "$file")
    local parseability=$(measure_parseability "$file")
    local diversity=$(measure_diversity "$file")
    local length=$(measure_length_adequacy "$file")

    local total=$((structure + completeness + parseability + diversity + length))

    # JSON 출력
    cat <<EOF
{
  "file": "$file",
  "total_score": $total,
  "breakdown": {
    "structure": $structure,
    "completeness": $completeness,
    "parseability": $parseability,
    "diversity": $diversity,
    "length": $length
  },
  "grade": "$(get_grade $total)",
  "timestamp": "$(date +"%Y-%m-%dT%H:%M:%S%z")"
}
EOF
}

# 등급 결정
get_grade() {
    local score=$1
    if [ $score -ge 90 ]; then echo "Excellent"
    elif [ $score -ge 75 ]; then echo "Good"
    elif [ $score -ge 60 ]; then echo "Acceptable"
    else echo "Needs Improvement"; fi
}

# 메인
main() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file"
        exit 1
    fi

    calculate_total_score "$file"
}

main "$@"
```

### 3. 품질 리포트 생성기 개발
**예상 산출물**: `scripts/generate-quality-report.sh`

**리포트 형식**:
```markdown
# Content Quality Report

**File**: public/content/ko/.../file.md
**Generated**: 2025-10-16T10:00:00Z
**Total Score**: 87/100 (Good)

## Score Breakdown

| Category | Score | Max | Percentage |
|----------|-------|-----|------------|
| Structure Quality | 22 | 25 | 88% |
| Completeness | 28 | 30 | 93% |
| Parseability | 25 | 25 | 100% |
| Diversity | 7 | 10 | 70% |
| Length Adequacy | 5 | 10 | 50% |

## Section-Level Scores

### Overview: 18/20 (90%)
- ✅ Section exists
- ✅ Parser test passed
- ✅ Required subsections present
- ⚠️  Length slightly below target (45 lines, target: 50-100)

### Core Concepts: 45/50 (90%)
- ✅ Section exists
- ✅ Parser test passed
- ✅ 3 concepts defined
- ✅ Easy/Normal/Expert all present
- ⚠️  Expert level slightly short in Concept 2

### Code Patterns: 18/20 (90%)
- ✅ Section exists
- ✅ Parser test passed
- ✅ 5 patterns defined
- ⚠️  Pattern 3 missing Full Code

### Experiments: 16/20 (80%)
- ✅ Section exists
- ✅ Parser test passed
- ✅ 3 experiments defined
- ❌ Experiment 2 missing Instructions

### Quiz: 16/20 (80%)
- ✅ Section exists
- ✅ Parser test passed
- ✅ 10 questions defined
- ⚠️  Only 2 question types (need 3+)

## Improvement Priorities

1. **High Priority**: Add third quiz type (e.g., code-review or output-prediction)
   - Impact: +5 points
   - Effort: Low

2. **Medium Priority**: Expand Experiment 2 Instructions
   - Impact: +4 points
   - Effort: Medium

3. **Low Priority**: Lengthen Overview to 50+ lines
   - Impact: +2 points
   - Effort: Low

## Quality Grade: Good

This content meets quality standards for publication. Consider addressing high-priority improvements for excellence.
```

### 4. 품질 대시보드 생성
**예상 산출물**: `scripts/generate-quality-dashboard.sh` → `logs/quality-dashboard.html`

**대시보드 구성 요소**:
- 전체 파일 품질 분포 (히스토그램)
- 섹션별 평균 점수 (레이더 차트)
- 최근 10개 파일 품질 트렌드 (라인 차트)
- 개선 필요 파일 목록 (테이블)

**기술 스택**: HTML + Chart.js (CDN)

### 5. content-validator 통합
**content-validator.md 프롬프트 업데이트**:
```markdown
## Validation Process

### Step 1: Run Quality Measurement
Execute: `./scripts/measure-quality.sh [file]`

### Step 2: Analyze Score Breakdown
- If total score >= 90: Mark as COMPLETE, no improvements needed
- If 75 <= score < 90: Identify top 3 improvement priorities
- If score < 75: Identify all issues

### Step 3: Generate IMPROVEMENT_NEEDED
For each issue with impact >= 5 points:
- [agent-name]: [specific issue] (-[points] points)

### Step 4: Update Work Status Markers
- Set VALIDATION_SCORE to total score
- Add IMPROVEMENT_NEEDED field if score < 90
- Set CURRENT_AGENT to first improvement target agent or empty
```

## 의존성

### 입력 의존성
- **Unit 1**: Work Status Markers에 VALIDATION_SCORE 기록
- **Unit 2**: 계약 명세에서 품질 기준 참조
- **Unit 3**: content-validator 프롬프트 업데이트
- **Unit 4**: execution-summary.json에서 품질 데이터 집계

### 출력 의존성
- 없음 (마지막 Unit)

## 성공 기준

1. **정량화**: 모든 품질 차원이 숫자로 측정 가능
2. **재현성**: 동일 파일은 항상 동일 점수
3. **유용성**: 품질 리포트를 보고 개선 방향 즉시 파악 가능
4. **자동화**: 수동 개입 없이 품질 측정 및 리포트 생성

## 예상 산출물 리스트

1. `docs/aidlc-docs/specifications/quality-metrics-spec.md`
2. `scripts/measure-quality.sh`
3. `scripts/generate-quality-report.sh`
4. `scripts/generate-quality-dashboard.sh`
5. `logs/quality-dashboard.html` (생성 예시)
6. `.claude/agents/content-validator.md` (업데이트)
7. `test/test-quality-metrics.sh` (품질 측정 로직 테스트)

## 예상 작업 기간

- 메트릭 명세 작성: 1일
- 측정 스크립트 개발: 3일
- 리포트 생성기 개발: 1일
- 대시보드 개발: 2일
- content-validator 통합: 1일
- 테스트 및 보정: 1일
- **총 예상: 9일**

## 리스크 및 완화 방안

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| 메트릭이 실제 품질을 반영하지 못함 | 높음 | 실제 콘텐츠 샘플로 메트릭 검증 |
| 점수 계산 로직 복잡도 | 중간 | 단계적 개발, 각 메트릭 독립 테스트 |
| 품질 기준이 너무 엄격 | 중간 | 기존 고품질 콘텐츠를 기준선으로 설정 |
| 대시보드 유지보수 부담 | 낮음 | 정적 HTML + CDN, 서버 불필요 |

## 질문 사항

### Question 1: 품질 기준선 ✅ 결정됨 (권장과 다름)
**질문**: 최소 품질 점수를 몇 점으로 설정할까요?

**최종 결정**: **C - 90점 (엄격한 기준)**

**⚠️ 중요 변경 사항** (사용자 답변):
- 권장 75점 대신 **90점 채택**
- 고품질 콘텐츠 보장 우선

**구현 영향**:
1. **content-validator 프롬프트 업데이트**:
   ```markdown
   ### Step 2: Analyze Score Breakdown
   - If total score >= 90: Mark as COMPLETE, no improvements needed
   - If 75 <= score < 90: Identify top 3 improvement priorities
   - If score < 75: Identify all issues
   ```

2. **품질 등급 기준 조정**:
   ```bash
   get_grade() {
       local score=$1
       if [ $score -ge 90 ]; then echo "Pass"        # 90점 이상 = Pass
       elif [ $score -ge 75 ]; then echo "Review"     # 75-89점 = Review 필요
       elif [ $score -ge 60 ]; then echo "Fail"       # 60-74점 = Fail
       else echo "Critical"; fi                       # 60점 미만 = Critical
   }
   ```

3. **예상 영향**:
   - 콘텐츠 생성 시간 증가 가능 (개선 반복 필요)
   - 최종 콘텐츠 품질 보장
   - content-validator의 개선 지시 빈도 증가

---

### Question 2: 섹션별 가중치 ✅ 결정됨
**질문**: 모든 섹션에 동일한 가중치를 부여할까요?

**최종 결정**: **현재 방식 유지**

**가중치 분배**:
- 구조적 품질 (Structure Quality): 25점
- 완성도 (Completeness): 30점
- 파싱 품질 (Parseability): 25점
- 콘텐츠 다양성 (Diversity): 10점
- 길이 적절성 (Length Adequacy): 10점

**근거**: 모든 섹션이 학습 경험에 중요하므로 균형 유지

---

### Question 3: 품질 트렌드 저장 ✅ 결정됨
**질문**: 품질 측정 결과를 DB에 저장할까요?

**최종 결정**: **A - JSON 파일로 저장**

**저장 구조**:
```
logs/quality-history/
├── 2025-10-16-topic-001.json
├── 2025-10-16-topic-002.json
└── ...
```

**JSON 형식**:
```json
{
  "file": "public/content/ko/.../file.md",
  "timestamp": "2025-10-16T10:00:00+09:00",
  "total_score": 87,
  "breakdown": {
    "structure": 22,
    "completeness": 28,
    "parseability": 25,
    "diversity": 7,
    "length": 5
  },
  "grade": "Review",
  "session_id": "uuid"
}
```

**장점**:
- 단순하고 버전 관리 용이
- Git으로 이력 추적 가능
- 외부 DB 불필요

---

### Question 4: 실시간 품질 피드백 ✅ 결정됨
**질문**: 에이전트 실행 중 실시간으로 품질 점수를 표시할까요?

**최종 결정**: **A - 실시간 피드백 (각 에이전트 완료 후)**

**동작 방식**:
1. **각 에이전트 완료 시**:
   ```bash
   # overview-writer 완료 후
   log_info "✅ overview-writer completed"
   overview_score=$(measure_overview_quality "$file")
   log_info "📊 Overview score: $overview_score/20"
   ```

2. **섹션별 점수 표시**:
   - Overview 완료: 18/20 (90%)
   - Concepts 완료: 45/50 (90%)
   - ...

3. **최종 종합 점수**:
   - 모든 에이전트 완료 후 전체 점수 요약 표시

**장점**:
- 빠른 이슈 발견 및 조기 대응 가능
- 에이전트별 품질 추적 용이
- 개선 필요 시점을 즉시 파악
