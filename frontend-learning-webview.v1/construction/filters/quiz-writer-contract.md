# quiz-writer Contract

**Version**: 1.0.0
**Created**: 2025-10-13
**Status**: Draft

---

## 1. 개요

### Filter 이름
`quiz-writer`

### 역할 및 책임
학습한 내용을 **검증**하기 위한 Quiz 섹션을 작성하는 역할을 합니다. 6가지 유형의 퀴즈 문제를 통해 학습자의 이해도를 평가하고, 점진적 힌트와 상세한 설명을 제공합니다.

**핵심 책임**:
- Quiz 섹션 작성 (8-12개 문제)
- 6가지 퀴즈 유형 구현 (multiple-choice, true-false, text-fill-in-blank, fill-in-the-blank, code-review, output-prediction)
- 난이도 분포 관리 (1-2: 30%, 3: 40%, 4-5: 30%)
- 점진적 힌트 제공 (방향 → 단서 → 거의 정답)
- Work Status Markers 관리

**평가 철학**:
- 명확한 정답 존재
- 학습 내용과 직접 연관
- 실무 상황 반영
- 암기가 아닌 이해 검증

### Pipeline에서의 위치
```
category.yaml → ... → practice-writer → [quiz-writer] → content-validator
```

- **선행 Filter**: practice-writer
- **후행 Filter**: content-validator (마지막 Filter)

---

## 2. 입력 계약 (Input Contract)

### 필수 입력 데이터

#### 2.1 마크다운 파일
- **파일 경로**: `public/content/ko/{category}/{subcategory}/{topic-id}-{topic-name}.md`
- **Work Status Markers**: `CURRENT_AGENT: quiz-writer`, `PROGRESS: 대기중`

#### 2.2 전체 학습 콘텐츠 (컨텍스트)
- **Overview**: 학습 목표 및 중요성
- **Core Concepts**: 핵심 개념 (3단계 난이도)
- **Code Patterns**: 코드 패턴 (Short/Full Code)
- **Experiments**: 실습 내용

**목적**: 퀴즈 문제 설계 및 난이도 조정

### 선행 조건 (Preconditions)
1. Overview, Core Concepts, Code Patterns, Experiments 모두 작성됨
2. Work Status Markers에서 `CURRENT_AGENT: quiz-writer`
3. Quiz 섹션이 없거나 비어 있음

---

## 3. 출력 계약 (Output Contract)

### 생성할 산출물

#### 3.1 Quiz 섹션
**위치**: Experiments 다음 (파일 끝)

**헤더**: `# Quiz` (H1, 파일당 1회만)

**개별 Question 구조**:
```markdown
## Question N: [Title]
**ID**: [kebab-case-identifier]
**Type**: [quiz-type]
**Difficulty**: [1-5]

### Question
[Question text, optionally with code block]

[Type-specific sections]

### Correct Answer
- [Answer]

### Explanation
[2-3 sentences explaining why]

### Hints
1. [Direction only]
2. [Specific clue]
3. [Almost answer]
```

### 출력 형식

#### 3.1.1 Quiz 유형별 구조

**(1) multiple-choice**
```markdown
### Question
[Question text]

### Options
- [Choice A]
- [Choice B]
- [Choice C]
- [Choice D]

### Correct Answer
- [Exact match of one Option]

### Explanation
[2-3 sentences]

### Hints
1. [Hint 1]
2. [Hint 2]
3. [Hint 3]
```

**(2) true-false**
```markdown
### Question
[Proposition or statement]

### Correct Answer
- True
또는
- False

### Explanation
[2-3 sentences]

### Hints
1. [Hint 1]
2. [Hint 2]
```

**(3) text-fill-in-blank**
```markdown
### Question
Fill in the blanks.

### Text
JavaScript의 {{blank1}}는 블록 스코프를 가집니다.

### Blanks
- blank1: let

### Correct Answer
- blank1: let

### Explanation
[2-3 sentences]

### Hints
1. [Hint 1]
2. [Hint 2]
```

**(4) fill-in-the-blank** (code blanks)
```markdown
### Question
```javascript
if (true) {
  ___(1)___ x = 1;
}
```

### Blanks
- blank1: let

### Correct Answer
- blank1: let

### Explanation
[2-3 sentences]

### Hints
1. [Hint 1]
2. [Hint 2]
```

**(5) code-review**
```markdown
### Question
다음 코드의 잠재적 문제점은 무엇인가요?

```javascript
var count = 0;
if (true) {
  var count = 1;
}
```

### Options
- var count가 재선언되어 문제가 발생할 수 있다
- if문이 잘못되었다
- count가 선언되지 않았다
- 문제가 없다

### Correct Answer
- var count가 재선언되어 문제가 발생할 수 있다

### Explanation
[2-3 sentences]

### Hints
1. [Hint 1]
2. [Hint 2]
```

**(6) output-prediction**
```markdown
### Question
다음 코드의 출력 결과를 예측하세요.

```javascript
console.log(typeof x);
var x = 5;
```

### Correct Answer
- Line 1: `undefined`

### Explanation
[2-3 sentences]

### Hints
1. [Hint 1]
2. [Hint 2]
```

### 후행 조건 (Postconditions)
1. Quiz 섹션 존재 (8-12개 문제)
2. 6가지 유형 각 1개 이상
3. 난이도 분포: 1-2(30%), 3(40%), 4-5(30%)
4. Parser 테스트 통과
5. Work Status Markers가 content-validator로 핸드오프됨

---

## 4. 품질 기준 (Quality Criteria)

### 구조적 요구사항

#### 4.1 공통 필수 필드 (Parser 검증)
- ✅ `## Question N:` 제목 (번호 + 콜론 + 제목)
- ✅ `**ID**:` kebab-case
- ✅ `**Type**:` 정확히 6가지 중 하나
- ✅ `**Difficulty**:` 1-5 숫자만
- ✅ `### Question` + 내용
- ✅ `### Correct Answer` + `-`로 시작하는 답
- ✅ `### Explanation` + 설명
- ✅ `### Hints` + 번호 목록
- ❌ 추가 필드 (Parser 실패)

#### 4.2 유형별 추가 필드
- **multiple-choice**: `### Options` + 4개 선택지 (`-`로 시작)
- **text-fill-in-blank**: `### Text` ({{blank1}} 형식) + `### Blanks`
- **fill-in-the-blank**: `### Blanks` (- blank1: answer 형식)
- **output-prediction**: (추가 필드 없음, Correct Answer에 Line 1: 형식 사용)
- **true-false**: (추가 필드 없음)
- **code-review**: `### Options` (multiple-choice와 동일, 코드 포함)

### 내용적 요구사항

#### 4.3 문제 품질
**좋은 문제**:
- ✅ 명확한 정답 존재
- ✅ 학습 내용과 직접 연관
- ✅ 실무 상황 반영
- ✅ 점진적 힌트 제공
- ✅ 상세한 설명

**피해야 할 문제**:
- ❌ 모호하거나 주관적인 답
- ❌ 단순 암기 확인
- ❌ 학습 범위 밖 내용
- ❌ 트릭 문제
- ❌ 매우 쉽거나 매우 어려운 문제만

#### 4.4 난이도 분포
- Difficulty 1-2 (기본 개념 확인): 30% (~2-4개)
- Difficulty 3 (응용 및 이해): 40% (~3-5개)
- Difficulty 4-5 (고급 및 문제 해결): 30% (~2-4개)

#### 4.5 유형 분포
- 최소 각 유형 1개 이상
- 총 8-12개 문제
- Core Concepts를 고르게 커버

#### 4.6 Hints 작성 규칙
- **Hint 1**: 방향만 제시 (무엇을 생각할지)
  - 예: "var의 스코프 특성을 생각해보세요"
- **Hint 2**: 구체적 단서 (어디를 볼지)
  - 예: "if 블록 내부의 var 선언을 주의깊게 보세요"
- **Hint 3**: 거의 정답 (한 단계만 더)
  - 예: "var는 재선언이 가능합니다"

#### 4.7 Explanation 작성 규칙
- 2-3문장으로 원인-결과 설명
- Multiple-choice: 각 선택지가 왜 맞고/틀린지
- Output-prediction/Code-review: 코드 실행 순서 설명

#### 4.8 JavaScript 코드 규칙
- ✅ ES6+ 문법 (const, let, arrow function, template literal)
- ✅ 세미콜론 생략
- ✅ 2칸 들여쓰기
- ✅ camelCase 변수명
- ✅ 실행 가능한 코드 (syntax error 없음)
- ❌ Code-review 유형 외에는 의도적 버그 금지

#### 4.9 코드 길이 (난이도별)
- Difficulty 1-2: 3-5줄
- Difficulty 3: 5-10줄
- Difficulty 4-5: 10-20줄

### 파서 테스트 검증

**테스트 파일**: `test/test-quiz-raw.mjs`

**검증 방법**:
```bash
npx tsx test/test-quiz-raw.mjs [file]
```

**성공 조건**:
- JSON 출력에 모든 Question 포함
- 각 문제에 필수 필드 모두 존재
- Parser 에러 없음

### 검증 체크리스트
- [ ] Quiz 섹션 존재 (8-12개 문제)
- [ ] 6가지 유형 각 1개 이상
- [ ] 난이도 분포 적절 (1-2: 30%, 3: 40%, 4-5: 30%)
- [ ] 모든 문제에 필수 필드 존재
- [ ] Correct Answer가 Options 중 하나와 정확히 일치 (multiple-choice)
- [ ] 코드 실행 가능 (syntax error 없음)
- [ ] Hints 3개 (최소 2개)
- [ ] Parser 테스트 통과

---

## 5. 오류 처리 (Error Handling)

### 오류 유형

#### 5.1 입력 오류
**오류**: Core Concepts 또는 Code Patterns 섹션 없음
- **대응**: 오류 로그, PROGRESS: 진행중 유지
- **메시지**: `Error: Cannot design quiz - missing learning content`

#### 5.2 생성 오류
**오류**: Parser 테스트 실패 (필수 필드 누락)
- **대응**: 누락된 필드 추가, 재작성 (최대 1회)

**오류**: Correct Answer가 Options와 불일치 (multiple-choice)
- **대응**: 정확한 선택지로 수정

#### 5.3 품질 오류
**오류**: 난이도 분포 불균형
- **대응**: 문제 추가/삭제하여 분포 조정

**오류**: 유형 중 하나 누락
- **대응**: 누락된 유형 문제 추가

### 재시도 전략
- **재시도 횟수**: 최대 1회
- **재시도 조건**: Parser 테스트 실패 (구조적 오류)

---

## 6. 성능 기준 (Performance Criteria)

### 평균 처리 시간
- **추정 범위**: 15-25분
- **측정 항목**:
  - 학습 콘텐츠 분석: 3-5분
  - 문제 설계 및 작성: 10-18분 (8-12개 문제)
  - Parser 테스트 검증: 1-2분

### 출력 크기 범위
- **Quiz 섹션**: 200-400줄
  - 문제당: 20-40줄
  - 총 8-12개 문제

### 리소스 사용량
- **토큰 소비**: 4000-10000 토큰
- **API 호출**: 5-20회

---

## 7. Work Status Markers 계약

### 시작 시 확인할 마커
```markdown
<!-- CURRENT_AGENT: quiz-writer -->
<!-- PROGRESS: 대기중 -->
```

### 완료 시 업데이트
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: content-validator -->
<!-- PROGRESS: 대기중 -->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
[DONE] quiz-writer: 완료 - [YYYY-MM-DD HH:MM]
-->
```

---

## 8. 의존성

### 선행 Filter
- **practice-writer**: Code Patterns, Experiments (문제 출처)
- **concepts-writer**: Core Concepts (개념 이해)
- **overview-writer**: Overview (학습 목표)

### 후속 Filter
- **content-validator**: 품질 검증 (최종 Filter)

### 외부 의존성
- **Parser 테스트**: `test/test-quiz-raw.mjs`
- **markdownParser.ts**: `parseQuiz` 함수

---

## 9. 특수 고려사항

### 9.1 Fill-in-blank 유형 차이
- **text-fill-in-blank**: 텍스트 빈칸 (`{{blank1}}` 형식)
- **fill-in-the-blank**: 코드 빈칸 (`___(1)___` 형식)

둘 다 `### Text` 및 `### Blanks` 섹션 사용.

### 9.2 Correct Answer 형식
- **Multiple-choice**: Options 중 하나와 **정확히 일치**
- **True-false**: `- True` 또는 `- False` (대소문자 정확)
- **Output-prediction**: `- Line 1: `value`` 형식
- **기타**: `- [answer]` 형식

### 9.3 UTF-8 인코딩
- 한글 퀴즈 작성 시 UTF-8 인코딩 필수

---

## 10. 분석 근거 (Analysis Evidence)

### 프롬프트 파일 분석
**참고 파일**: `.claude/agents/quiz-writer.md`

→ 6가지 유형 구조, 필수 필드, 난이도/유형 분포 명시

### 산출물 샘플 분석
**참고 파일**: `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md:1476-1625`

→ 실제 Quiz 섹션 형식 확인

---

## 11. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2025-10-13 | 초기 계약 정의 |

---

## 12. 참고 문서

- `.claude/agents/quiz-writer.md`
- `test/test-quiz-raw.mjs`
- `src/utils/markdownParser.ts`
