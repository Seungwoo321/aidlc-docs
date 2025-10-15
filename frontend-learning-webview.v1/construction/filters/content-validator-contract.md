# content-validator Contract

**Version**: 1.0.0
**Created**: 2025-10-13
**Status**: Draft

---

## 1. 개요

### Filter 이름
`content-validator`

### 역할 및 책임
파이프라인의 **마지막 Filter**로서, 생성된 모든 학습 콘텐츠의 **품질을 검증**하고, 개선이 필요한 경우 구체적인 지시사항을 생성합니다. 100점 만점 기준으로 콘텐츠를 평가하며, 완벽한 경우에만 최종 완료 처리합니다.

**핵심 책임**:
- 5개 섹션 의미적 품질 검증 (Overview, Core Concepts, Code Patterns, Experiments, Quiz)
- 100점 만점 점수 산정
- 개선 항목 생성 (IMPROVEMENT_NEEDED)
- 최종 완료 처리 (100점) 또는 개선 요청 (< 100점)
- Work Status Markers 최종 관리

**검증 철학**:
- 객관적 체크리스트 기반 평가
- 건설적이고 구체적인 피드백
- 우선순위 기반 효율적 개선 (점수 차감 큰 것부터)

### Pipeline에서의 위치
```
category.yaml → ... → quiz-writer → [content-validator] → [COMPLETE or RETRY]
```

- **선행 Filter**: quiz-writer (마지막 콘텐츠 작성 Filter)
- **후행 Filter**: 없음 (최종 Filter)
- **출력**: 완료 또는 특정 Filter로 핸드오프 (개선 요청)

---

## 2. 입력 계약 (Input Contract)

### 필수 입력 데이터

#### 2.1 마크다운 파일
- **파일 경로**: `public/content/ko/{category}/{subcategory}/{topic-id}-{topic-name}.md`
- **Work Status Markers**: `CURRENT_AGENT: content-validator`, `PROGRESS: 대기중`

#### 2.2 전체 학습 콘텐츠
**5개 섹션 모두 존재**:
1. **Overview**: 학습 동기, 핵심 특징, 실무 영향
2. **Core Concepts**: Easy/Normal/Expert 3단계 + Visualization
3. **Code Patterns**: Short/Full Code + Explanation
4. **Experiments**: Instructions + Initial Code
5. **Quiz**: 8-12개 문제 (6가지 유형)

**목적**: 의미적 품질 검증

### 선행 조건 (Preconditions)
1. 모든 선행 Filter가 작업 완료
2. 5개 섹션 모두 존재
3. Work Status Markers에서 `CURRENT_AGENT: content-validator`
4. Parser 테스트 통과 (구조적 검증 완료)

---

## 3. 출력 계약 (Output Contract)

### 생성할 산출물

#### 3.1 검증 보고서 (로그 출력)
**형식**: 콘솔 출력 (마크다운 형식)

```markdown
## 📊 Content Quality Validation Report

### File Information
- **File**: [file-path]
- **Topic**: [topic-name]
- **Validation Attempt**: [nth attempt]
- **Validation Time**: [YYYY-MM-DD HH:MM]

### 📈 Semantic Validation
| Section | Score | Evaluation |
|---------|-------|------------|
| Overview | 18/20 | [Issues] |
| Concepts | 23/25 | [Issues] |
| Patterns | 20/20 | Perfect |
| Experiments | 14/15 | [Issues] |
| Quiz | 18/20 | [Issues] |

### 🎯 Overall Evaluation
- **Total Score**: 93/100
- **Grade**: Good [DONE]
- **Decision**: Needs improvement

### 💡 Improvement Recommendations
1. Overview: [Specific issue]
2. Concepts: [Specific issue]
...
```

#### 3.2 Work Status Markers 업데이트

**케이스 1: 100점 (완벽)**
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: -->
<!-- PROGRESS: 완료 -->
<!-- VALIDATION_SCORE: 100/100 -->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
[DONE] content-validator: 검증 완료 - 100점
[COMPLETE] 최종 완료 - 완벽한 콘텐츠 생성
-->
```

**케이스 2: 90-99점 (개선 필요)**
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: [first_improvement_target_agent] -->
<!-- PROGRESS: 대기중 -->
<!-- VALIDATION_SCORE: 93/100 -->
<!-- IMPROVEMENT_NEEDED:
  - concepts-writer: Add terminology explanation for Expert section (-5점)
  - quiz-writer: Improve difficulty distribution (-2점)
-->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
[DONE] content-validator: 검증 완료 - 93점 (개선 필요)
-->
```

**케이스 3: < 90점 (대폭 개선)**
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: [first_improvement_target_agent] -->
<!-- PROGRESS: 대기중 -->
<!-- VALIDATION_SCORE: 82/100 -->
<!-- IMPROVEMENT_NEEDED:
  - overview-writer: Rewrite learning motivation section (-8점)
  - concepts-writer: Complete revision of Easy explanation (-6점)
  - quiz-writer: Insufficient question type diversity (-4점)
-->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
[DONE] content-validator: 검증 완료 - 82점 (대폭 개선 필요)
-->
```

### 출력 형식

#### 3.2.1 점수 산정 기준

**총점 100점 = Overview(20) + Concepts(25) + Patterns(20) + Experiments(15) + Quiz(20)**

**(1) Overview (20점)**
- 명확한 주제 정의 (5점)
- 학습 동기 부여 (5점)
- 핵심 특징/개선사항 명시 (5점)
- 실무 적용 설명 (5점)

**(2) Core Concepts (25점)**
- 토픽 핵심 개념 선정 적절성 (5점)
- Easy: 중학생도 이해 가능 (5점)
- Normal: 자연어 중심 설명 충실성 (5점)
- Expert: 기술 용어 및 설명 (5점)
- Visualization 완전성 (5점):
  1. 메타데이터 존재 (1점)
  2. 컴포넌트 파일 존재 (1점)
  3. **컴포넌트 파일이 비어있지 않음** (1점):
     - Read tool로 파일 내용 확인
     - 최소 20줄 이상
     - "import React" 및 "export const" 포함
     - 빈 파일 또는 placeholder만 있으면 0점
  4. **index.ts에 export 존재** (2점):
     - Grep으로 `src/components/visualizations/index.ts`에서 컴포넌트명 검색
     - export 누락 시 0점, **추가 5점 차감** (Critical!)
     - 이유: export 없으면 UI에 "준비중" 표시됨

**(3) Code Patterns (20점)**
- 실용적 패턴 선정 (5점)
- shortCode/fullCode 구분 (5점)
- 코드 실행 가능성 (5점)
- 설명 충실성 (5점)

**(4) Experiments (15점)**
- 실습 목표 명확성 (5점)
- 단계별 지시사항 명확성 (5점)
- 코드 완전성 (TODO 없음) (5점)

**(5) Quiz (20점)**
- 문제 유형 다양성 (5점)
- 난이도 분포 균형 (5점)
- 답안 정확성 (5점)
- 적절한 문제 수 (8-12개) (5점)

#### 3.2.2 등급 판정

- **100점**: Perfect 🏆 → 최종 완료 (COMPLETE)
- **95-99점**: Excellent [COMPLETE] → 1차 개선 요청
- **90-94점**: Good [DONE] → 1차 개선 요청
- **85-89점**: Acceptable ⚠️ → 1-2차 개선 요청
- **85점 미만**: Needs Improvement [FAILED] → 대폭 개선 필요

#### 3.2.3 IMPROVEMENT_NEEDED 형식

```markdown
<!-- IMPROVEMENT_NEEDED:
  - [agent-name]: [Specific issue description] (-[points]점)
  - [agent-name]: [Specific issue description] (-[points]점)
-->
```

**규칙**:
- 점수 차감이 큰 항목부터 나열 (우선순위)
- 구체적이고 실행 가능한 지시사항
- 해당 agent명 명시
- 차감 점수 명시

### 후행 조건 (Postconditions)
1. 검증 보고서 생성 (로그 출력)
2. VALIDATION_SCORE 기록
3. 100점: PROGRESS: 완료, CURRENT_AGENT: (비움)
4. < 100점: IMPROVEMENT_NEEDED 생성, CURRENT_AGENT: (첫 번째 개선 대상 agent)

---

## 4. 품질 기준 (Quality Criteria)

### 구조적 요구사항

#### 4.1 검증 완전성
- ✅ 5개 섹션 모두 검증
- ✅ 각 섹션별 점수 산정
- ✅ 총점 계산 정확
- ❌ 섹션 누락 검증

#### 4.2 객관성
- ✅ 체크리스트 기반 평가
- ✅ 점수 기준 명확
- ❌ 주관적 평가

#### 4.3 피드백 구체성
- ✅ 구체적이고 실행 가능한 개선 사항
- ✅ 해당 agent명 명시
- ✅ 차감 점수 명시
- ❌ 모호한 피드백

### 내용적 요구사항

#### 4.4 Visualization 검증 (Critical)
**3단계 검증**:
1. **메타데이터 확인**: `### Visualization` 섹션 존재
2. **컴포넌트 파일 확인**:
   ```bash
   Read src/components/visualizations/{category}/{ComponentName}.tsx
   ```
   - 파일 존재 확인
   - 최소 20줄 이상
   - "import React" 및 "export const" 포함
3. **Export 확인** (Critical):
   ```bash
   Grep "ComponentName" src/components/visualizations/index.ts
   ```
   - export 문 존재 확인
   - 누락 시 **추가 5점 차감**

#### 4.5 코드 실행 가능성 검증
- Code Patterns의 Short/Full Code 실행 가능
- Experiments의 Initial Code 실행 가능
- Quiz의 코드 문제 syntax error 없음

#### 4.6 난이도 균형 검증
- **Core Concepts**: Easy/Normal/Expert 3단계 모두 존재
- **Quiz**: 1-2(30%), 3(40%), 4-5(30%) 분포

### 검증 체크리스트
- [ ] Overview 섹션 검증 (20점)
- [ ] Core Concepts 섹션 검증 (25점)
  - [ ] Visualization 3단계 검증 (메타데이터, 파일, export)
- [ ] Code Patterns 섹션 검증 (20점)
- [ ] Experiments 섹션 검증 (15점)
- [ ] Quiz 섹션 검증 (20점)
- [ ] 총점 계산 (100점 만점)
- [ ] VALIDATION_SCORE 기록
- [ ] 100점 미만 시 IMPROVEMENT_NEEDED 생성
- [ ] CURRENT_AGENT 업데이트

---

## 5. 오류 처리 (Error Handling)

### 오류 유형

#### 5.1 입력 오류
**오류**: 필수 섹션 누락
- **대응**: 해당 섹션 0점 처리, 개선 요청

**오류**: CURRENT_AGENT가 content-validator 아님
- **대응**: 작업 건너뛰기

#### 5.2 검증 오류
**오류**: Visualization 파일 존재하지 않음
- **대응**: Visualization 0점, 추가 5점 차감

**오류**: Visualization export 누락
- **대응**: Visualization 0점, 추가 5점 차감

#### 5.3 품질 오류
**오류**: 점수 계산 오류
- **대응**: 재계산 후 수정

---

## 6. 성능 기준 (Performance Criteria)

### 평균 처리 시간
- **추정 범위**: 5-10분
- **측정 항목**:
  - 5개 섹션 읽기 및 분석: 3-5분
  - 점수 산정 및 피드백 생성: 2-5분

### 출력 크기 범위
- **검증 보고서**: 50-100줄 (로그)
- **IMPROVEMENT_NEEDED**: 0-10개 항목

### 리소스 사용량
- **토큰 소비**: 2000-5000 토큰
- **API 호출**: 5-15회
  - Read (전체 파일, visualization 파일): 3-10회
  - Grep (visualization export): 0-5회
  - Edit (Work Status Markers): 1회

---

## 7. Work Status Markers 계약

### 시작 시 확인할 마커
```markdown
<!-- CURRENT_AGENT: content-validator -->
<!-- PROGRESS: 대기중 -->
```

### 작업 시작 시 업데이트
```markdown
<!-- PROGRESS: 진행중 -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
-->
```

### 완료 시 업데이트 (2가지 경로)

**(1) 100점: 최종 완료**
```markdown
<!-- CURRENT_AGENT: -->
<!-- PROGRESS: 완료 -->
<!-- VALIDATION_SCORE: 100/100 -->
<!-- HANDOFF LOG:
[previous logs]
[DONE] content-validator: 검증 완료 - 100점
[COMPLETE] 최종 완료 - 완벽한 콘텐츠 생성
-->
```

**(2) < 100점: 개선 요청**
```markdown
<!-- CURRENT_AGENT: [first-improvement-agent] -->
<!-- PROGRESS: 대기중 -->
<!-- VALIDATION_SCORE: [score]/100 -->
<!-- IMPROVEMENT_NEEDED:
  - [agent]: [issue] (-[points]점)
-->
<!-- HANDOFF LOG:
[previous logs]
[DONE] content-validator: 검증 완료 - [score]점 (개선 필요)
-->
```

---

## 8. 의존성

### 선행 Filter
- **quiz-writer**: 마지막 콘텐츠 작성 Filter
- **모든 Filter**: 전체 콘텐츠 검증 대상

### 후속 Filter
- 없음 (최종 Filter)
- **출력**: 완료 또는 특정 Filter로 핸드오프

### 외부 의존성
- **Visualization 파일**: `src/components/visualizations/{category}/{ComponentName}.tsx`
- **Visualization index**: `src/components/visualizations/index.ts`

---

## 9. 특수 고려사항

### 9.1 개선 우선순위
점수 차감이 큰 항목부터 개선:
1. Visualization export 누락: -10점 (5+5)
2. 필수 섹션 누락: -5~-8점
3. 코드 실행 불가: -5점
4. 설명 불충분: -2~-3점

### 9.2 개선 반복 전략
- 1차 시도: 90+ 점수면 fine-tuning
- 2-3차 시도: 점진적 개선
- 오케스트레이션 스크립트가 재시도 로직 담당
- content-validator는 점수만 측정

### 9.3 Visualization Critical Check
⚠️ **가장 흔한 실패**: index.ts export 누락
- 반드시 Grep으로 확인
- 누락 시 추가 5점 차감 (총 10점 손실)

---

## 10. 분석 근거 (Analysis Evidence)

### 프롬프트 파일 분석
**참고 파일**: `.claude/agents/content-validator.md`

→ 점수 기준, 검증 항목, 개선 전략 명시

### 실제 검증 사례 (추론)
- Visualization export 누락이 흔함
- 3단계 검증 필요 (메타데이터, 파일, export)

---

## 11. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2025-10-13 | 초기 계약 정의 |

---

## 12. 참고 문서

- `.claude/agents/content-validator.md`
- `docs/aidlc-docs/inception/units/unit-2-pipe-mechanism.md`
