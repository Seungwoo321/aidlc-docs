---
agent_id: quiz-writer
version: 1.0
dependencies: [overview-writer, concepts-writer, practice-writer]
bounded_context: Quiz Section Generation
---

# Agent Contract: Quiz Writer

## Responsibility

Generate Quiz section with diverse question types (8-12 questions) to validate learning outcomes across different difficulty levels.

## Input Contract

### File State
- Required Files: Target markdown file
- File Encoding: UTF-8
- Frontmatter: Required (populated by content-initiator)
- Existing Sections:
  - Work Status Markers
  - `# Overview` section
  - `# Core Concepts` section
  - `# Code Patterns` section
  - `# Experiments` section

### Work Status Markers
- CURRENT_AGENT: quiz-writer
- STATUS: IN_PROGRESS
- HANDOFF LOG: Contains [DONE] practice-writer entry

### Section Dependencies
- Overview section (read-only, for context)
- Core Concepts section (read-only, for concept-based questions)
- Practice section (read-only, for code-based questions)

## Output Contract

### File State
- Modified Files: Target markdown file
- New Sections: `# Quiz` section added after Experiments

- Section Structure:
  ```markdown
  # Quiz

  ## Question 1: [Title]

  **ID**: [kebab-case-identifier]
  **Type**: multiple-choice | true-false | text-fill-in-blank | fill-in-the-blank | code-review | output-prediction
  **Difficulty**: 1 | 2 | 3 | 4 | 5

  ### Question
  [Question text or code block]

  ### Options (for multiple-choice, code-review)
  - [Option 1]
  - [Option 2]
  - [Option 3]
  - [Option 4]

  ### Text (for text-fill-in-blank, fill-in-the-blank)
  [Text with {{blank1}}, {{blank2}} placeholders]

  ### Blanks (for text-fill-in-blank, fill-in-the-blank)
  - blank1: [answer1]
  - blank2: [answer2]

  ### Output Lines (for output-prediction)
  - [Line 1]
  - [Line 2]

  ### Correct Answer
  - [Exact answer matching one Option, or answer text, or output description]

  ### Explanation
  [2-3 sentences explaining cause-effect relationships and why answer is correct]

  ### Hints
  1. [Direction hint - what to think about]
  2. [Specific clue - where to look]
  3. [Near-answer hint - one more step to solution]
  ```

### Work Status Markers
- CURRENT_AGENT: content-validator
- STATUS: IN_PROGRESS (unchanged)
- UPDATED: Current timestamp (ISO 8601 format)
- HANDOFF LOG:
  - Preserve all existing entries
  - Add: `[DONE] quiz-writer | Quiz section completed | [timestamp]`

### Content Guarantees
- Total questions: 8-12
- Question type distribution: Minimum 1 question per type (6 types total)
- Difficulty distribution:
  - Difficulty 1-2: 30% (basic concept verification)
  - Difficulty 3: 40% (application and understanding)
  - Difficulty 4-5: 30% (advanced and problem solving)
- All code in questions is executable without syntax errors
- Each question has exactly 3 hints (progressive difficulty)
- Correct Answer MUST exactly match one Option (for multiple-choice/code-review)

## Preconditions

1. CURRENT_AGENT == "quiz-writer"
2. STATUS == IN_PROGRESS
3. `# Overview`, `# Core Concepts`, and `# Code Patterns` sections exist
4. HANDOFF LOG contains [DONE] practice-writer entry

## Postconditions

1. `# Quiz` section is created with 8-12 Question blocks
2. All 6 question types are represented (minimum 1 each)
3. Difficulty distribution meets 30%/40%/30% target
4. All code questions are executable
5. CURRENT_AGENT == "content-validator"
6. STATUS == IN_PROGRESS (unchanged)
7. HANDOFF LOG contains [DONE] quiz-writer entry
8. (Improvement mode only) IMPROVEMENT_NEEDED field no longer contains quiz-writer entry

## Error Handling

### Precondition 실패 시
- **Missing required sections**: Fail-Fast strategy
  - Output error message: "Precondition failed: Required section(s) missing: {section_names}"
  - Add [FAILURE] entry: `[FAILURE] quiz-writer | Missing required sections | [timestamp]`
  - Set STATUS: FAILED
  - Preserve CURRENT_AGENT as quiz-writer
  - Terminate execution

- **CURRENT_AGENT mismatch**: Fail-Fast strategy
  - Output error message: "Precondition failed: CURRENT_AGENT is {actual}, expected 'quiz-writer'"
  - Add [FAILURE] entry to HANDOFF LOG
  - Set STATUS: FAILED
  - Terminate execution

- **Missing [DONE] practice-writer**: Fail-Fast strategy
  - Output error message: "Precondition failed: No [DONE] practice-writer entry in HANDOFF LOG"
  - Add [FAILURE] entry
  - Set STATUS: FAILED
  - Terminate execution

### 작업 중 오류 시
- **Quiz generation failure**:
  - Rollback partial work (remove incomplete Quiz section)
  - Add [FAILURE] entry: `[FAILURE] quiz-writer | Quiz generation failed: {error_details} | [timestamp]`
  - Set STATUS: FAILED
  - Preserve CURRENT_AGENT as quiz-writer for retry
  - Terminate execution

- **Code syntax errors in questions**:
  - Add [FAILURE] entry: `[FAILURE] quiz-writer | Quiz code contains syntax errors | [timestamp]`
  - Set STATUS: FAILED
  - Terminate execution

- **Incorrect answer format** (e.g., Correct Answer doesn't match any Option):
  - Add [FAILURE] entry: `[FAILURE] quiz-writer | Answer validation failed | [timestamp]`
  - Set STATUS: FAILED
  - Terminate execution

## Examples

### Example 1: Normal Flow (10 questions, all 6 types)

**Input**:
```markdown
---
id: var-problems
title: var 키워드의 문제점
---

<!--
CURRENT_AGENT: quiz-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T11:45:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts completed | 2025-10-17T10:45:00+09:00
[DONE] visualization-writer | Skipped | 2025-10-17T10:46:00+09:00
[DONE] practice-writer | Practice completed | 2025-10-17T11:45:00+09:00
-->

# Overview
[Content...]

# Core Concepts
[Concepts...]

# Code Patterns
[Patterns...]

# Experiments
[Experiments...]
```

**Output** (abbreviated, showing question type examples):
```markdown
<!--
CURRENT_AGENT: content-validator
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T12:30:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts completed | 2025-10-17T10:45:00+09:00
[DONE] visualization-writer | Skipped | 2025-10-17T10:46:00+09:00
[DONE] practice-writer | Practice completed | 2025-10-17T11:45:00+09:00
[DONE] quiz-writer | Quiz section completed | 2025-10-17T12:30:00+09:00
-->

[Previous sections...]

# Quiz

## Question 1: var의 기본 특징

**ID**: var-basic-feature
**Type**: multiple-choice
**Difficulty**: 2

### Question
var 키워드의 특징으로 올바르지 않은 것은?

### Options
- var는 함수 스코프를 따릅니다
- var는 호이스팅됩니다
- var는 블록 스코프를 따릅니다
- var는 중복 선언을 허용합니다

### Correct Answer
- var는 블록 스코프를 따릅니다

### Explanation
var는 함수 스코프를 따르며 블록 스코프를 무시합니다. 블록 스코프를 따르는 것은 let과 const의 특징입니다. var는 호이스팅되고 중복 선언도 허용합니다.

### Hints
1. var와 let/const의 스코프 차이를 생각해보세요
2. if문이나 for문의 블록 안에서 var를 선언하면 어떻게 되나요?
3. Core Concepts의 "함수 스코프" 섹션을 참고하세요

## Question 2: 호이스팅 동작

**ID**: hoisting-true-false
**Type**: true-false
**Difficulty**: 1

### Question
var로 선언한 변수는 선언과 초기화가 모두 호이스팅됩니다.

### Correct Answer
- false

### Explanation
var 선언은 호이스팅되지만, 초기화(할당)는 호이스팅되지 않습니다. 선언부만 스코프 맨 위로 이동하고 undefined로 초기화되며, 할당은 원래 위치에서 실행됩니다.

### Hints
1. 호이스팅된 변수의 초기값은 무엇인가요?
2. console.log를 선언 전에 실행하면 어떤 값이 나오나요?
3. undefined가 나온다면 할당은 호이스팅되지 않은 것입니다

## Question 3: 스코프 키워드 완성

**ID**: scope-keyword-fill
**Type**: text-fill-in-blank
**Difficulty**: 2

### Question
Fill in the blanks.

### Text
var는 {{blank1}} 스코프를 따르지만, let과 const는 {{blank2}} 스코프를 따릅니다.

### Blanks
- blank1: 함수
- blank2: 블록

### Correct Answer
- 함수, 블록

### Explanation
var는 함수 레벨 스코프를 가지므로 함수 경계까지만 스코프가 제한됩니다. 반면 let과 const는 블록 레벨 스코프를 가져 중괄호({ }) 단위로 스코프가 구분됩니다.

### Hints
1. var가 무시하는 것은 무엇이고, 인식하는 경계는 무엇인가요?
2. let/const가 존중하는 단위는 무엇인가요?
3. Core Concepts의 "함수 스코프" vs "블록 스코프" 비교를 보세요

## Question 4: 호이스팅 코드 완성

**ID**: hoisting-code-fill
**Type**: fill-in-the-blank
**Difficulty**: 3

### Question
Fill in the blanks to demonstrate var hoisting behavior.

### Text
```javascript
console.log({{blank1}}) // undefined
{{blank2}} name = "Alice"
console.log(name) // "Alice"
```

### Blanks
- blank1: name
- blank2: var

### Correct Answer
- name, var

### Explanation
var 호이스팅으로 인해 선언 전에 변수를 참조해도 에러가 발생하지 않고 undefined를 반환합니다. 선언부(var name)는 스코프 최상단으로 호이스팅되지만, 할당("Alice")은 원래 위치에 남습니다.

### Hints
1. 호이스팅된 변수를 선언 전에 참조하면 어떤 값이 나오나요?
2. undefined를 출력하려면 어떤 변수를 참조해야 할까요?
3. 두 번째 빈칸은 변수를 선언하는 키워드입니다

## Question 5: 루프 클로저 문제

**ID**: loop-closure-review
**Type**: code-review
**Difficulty**: 4

### Question
```javascript
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 100)
}
```

### Options
- 0, 1, 2가 순서대로 출력됩니다
- 3, 3, 3이 출력됩니다
- undefined가 3번 출력됩니다
- ReferenceError가 발생합니다

### Correct Answer
- 3, 3, 3이 출력됩니다

### Explanation
var는 함수 스코프를 따르므로 루프의 모든 반복이 같은 i 변수를 참조합니다. setTimeout 콜백이 실행될 때는 루프가 이미 끝나서 i값이 3이 되어 있으므로, 모든 콜백이 3을 출력합니다. let을 사용하면 각 반복마다 새로운 바인딩이 생성되어 0, 1, 2가 출력됩니다.

### Hints
1. setTimeout 콜백은 언제 실행되나요? (루프 진행 중? 종료 후?)
2. 루프가 끝났을 때 i의 값은 얼마인가요?
3. var는 모든 반복에서 같은 변수를 참조합니다

## Question 6: 블록 스코프 출력 예측

**ID**: block-scope-output
**Type**: output-prediction
**Difficulty**: 3

### Question
```javascript
if (true) {
  var x = 10
}
console.log(x)

if (true) {
  let y = 20
}
console.log(y)
```

### Output Lines
- 10
- ReferenceError: y is not defined

### Correct Answer
- 10, ReferenceError

### Explanation
var는 블록 스코프를 무시하므로 if문 밖에서도 x에 접근 가능하여 10이 출력됩니다. 반면 let은 블록 스코프를 준수하므로 if문 블록을 벗어나면 y에 접근할 수 없어 ReferenceError가 발생합니다.

### Hints
1. var는 블록({ })을 어떻게 처리하나요?
2. let은 블록 밖에서 접근 가능한가요?
3. 블록 밖에서 접근 시도하면 어떤 에러가 발생하나요?

## Question 7: 중복 선언 동작

**ID**: redeclaration-behavior
**Type**: multiple-choice
**Difficulty**: 2

### Question
다음 코드의 실행 결과는?

```javascript
var user = "Alice"
var user = "Bob"
console.log(user)
```

### Options
- "Alice"가 출력됩니다
- "Bob"이 출력됩니다
- SyntaxError가 발생합니다
- undefined가 출력됩니다

### Correct Answer
- "Bob"이 출력됩니다

### Explanation
var는 같은 스코프 내에서 중복 선언을 허용합니다. 두 번째 선언이 첫 번째 값을 덮어쓰므로 "Bob"이 출력됩니다. let이나 const를 사용하면 중복 선언 시 SyntaxError가 발생하여 이런 실수를 방지할 수 있습니다.

### Hints
1. var는 중복 선언을 허용하나요?
2. 두 번째 선언이 첫 번째 값에 어떤 영향을 주나요?
3. 마지막 할당된 값이 무엇인지 확인하세요

## Question 8: TDZ 개념

**ID**: tdz-concept
**Type**: true-false
**Difficulty**: 4

### Question
var로 선언한 변수는 TDZ(Temporal Dead Zone)가 존재하지 않습니다.

### Correct Answer
- true

### Explanation
TDZ는 let/const의 특징으로, 스코프 시작부터 선언 지점까지의 영역을 말합니다. var는 호이스팅 시 undefined로 초기화되므로 TDZ가 없으며, 선언 전에도 참조 가능합니다 (undefined 반환). let/const는 초기화되지 않은 상태로 호이스팅되어 TDZ에서 참조 시 ReferenceError가 발생합니다.

### Hints
1. var를 선언 전에 참조하면 어떻게 되나요?
2. let을 선언 전에 참조하면 어떻게 되나요?
3. undefined vs ReferenceError의 차이를 생각해보세요

## Question 9: 전역 스코프 오염

**ID**: global-scope-pollution
**Type**: code-review
**Difficulty**: 5

### Question
```javascript
function calculateTotal() {
  for (var i = 0; i < 10; i++) {
    sum += i
  }
  return sum
}
```

이 코드의 가장 큰 문제점은 무엇인가요?

### Options
- var 대신 let을 사용해야 합니다
- sum 변수가 선언되지 않아 전역 변수로 생성됩니다
- i의 초기값이 잘못되었습니다
- 함수가 값을 반환하지 않습니다

### Correct Answer
- sum 변수가 선언되지 않아 전역 변수로 생성됩니다

### Explanation
sum 변수가 선언 없이 사용되어 암묵적 전역 변수로 생성됩니다. 이는 의도하지 않은 전역 스코프 오염을 초래하며, 다른 코드와 충돌할 수 있습니다. var sum = 0 또는 let sum = 0으로 명시적 선언이 필요합니다. var i 대신 let i를 사용하는 것도 좋지만, 이 코드의 가장 심각한 문제는 sum의 암묵적 전역 생성입니다.

### Hints
1. sum 변수는 어디에 선언되어 있나요?
2. 선언 없이 변수에 값을 할당하면 어떻게 되나요?
3. strict mode에서는 이런 코드가 허용될까요?

## Question 10: 최선의 실무 방법

**ID**: best-practice
**Type**: multiple-choice
**Difficulty**: 3

### Question
현대 JavaScript 개발에서 변수 선언 시 권장되는 방법은?

### Options
- 모든 변수를 var로 선언합니다
- 재할당이 필요한 변수는 let, 상수는 const를 사용합니다
- 모든 변수를 const로 선언합니다
- var와 let을 섞어서 사용합니다

### Correct Answer
- 재할당이 필요한 변수는 let, 상수는 const를 사용합니다

### Explanation
기본적으로 const를 사용하고, 재할당이 필요한 경우에만 let을 사용하는 것이 모던 JavaScript의 베스트 프랙티스입니다. const는 의도하지 않은 재할당을 방지하고, let은 블록 스코프로 변수 범위를 명확히 합니다. var는 호이스팅과 함수 스코프 문제로 인해 사용을 피해야 합니다.

### Hints
1. const와 let의 주요 차이점은 무엇인가요?
2. 값이 변하지 않는 변수에는 어떤 키워드가 적합할까요?
3. var를 피해야 하는 이유를 생각해보세요
```

**Work Status Markers Update**:
- CURRENT_AGENT: quiz-writer → content-validator
- UPDATED timestamp refreshed
- HANDOFF LOG: Added [DONE] entry

**Question Statistics**:
- Total: 10 questions
- Types: multiple-choice (4), true-false (2), text-fill-in-blank (1), fill-in-the-blank (1), code-review (2), output-prediction (1)
- Difficulty: 1 (1), 2 (3), 3 (3), 4 (2), 5 (1) = 10%/30%/30%/20%/10%

### Example 2: Improvement Mode (난이도 분포 개선)

**Input**:
```markdown
<!--
CURRENT_AGENT: quiz-writer
STATUS: IN_PROGRESS
VALIDATION_SCORE: 89/100
IMPROVEMENT_NEEDED:
  - quiz-writer: Add 2 more difficulty 1-2 questions (-6점)
  - overview-writer: Improve motivation section (-5점)
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:30:00+09:00
HANDOFF LOG:
[Previous entries...]
[DONE] content-validator | Validation completed - 89점 (개선 필요)
-->

# Quiz

[Existing 8 questions with difficulty: 3(4), 4(2), 5(2)]
```

**Output**:
```markdown
<!--
CURRENT_AGENT: overview-writer
STATUS: IN_PROGRESS
VALIDATION_SCORE: 89/100
IMPROVEMENT_NEEDED:
  - overview-writer: Improve motivation section (-5점)
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:45:00+09:00
HANDOFF LOG:
[Previous entries...]
[DONE] content-validator | Validation completed - 89점 (개선 필요)
[IMPROVE] quiz-writer | Added 2 difficulty 1-2 questions | 2025-10-17T13:45:00+09:00
-->

# Quiz

[Previous 8 questions unchanged]

## Question 9: var 키워드 기본 개념

**ID**: var-keyword-basic
**Type**: true-false
**Difficulty**: 1

### Question
var는 JavaScript에서 변수를 선언하는 키워드입니다.

### Correct Answer
- true

[Rest of question...]

## Question 10: 호이스팅 발생 여부

**ID**: hoisting-occurrence
**Type**: multiple-choice
**Difficulty**: 2

### Question
var로 선언한 변수에 대해 호이스팅이 발생하나요?

### Options
- 항상 발생합니다
- 전역 스코프에서만 발생합니다
- 함수 스코프에서만 발생합니다
- 발생하지 않습니다

### Correct Answer
- 항상 발생합니다

[Rest of question...]
```

**Work Status Markers Update**:
- CURRENT_AGENT: quiz-writer → overview-writer (next improvement target)
- IMPROVEMENT_NEEDED: quiz-writer entry removed
- HANDOFF LOG: Added [IMPROVE] entry
- 2 new easy questions added

## Implementation

### Work Status Markers 업데이트 방법

Refer to `docs/aidlc-docs/construction/unit-02-filter-contracts/domain_design.md` Section 2.1.3.

**Normal Flow (정상 완료 시)**:
- Pattern: "모든 에이전트 (content-initiator 제외)"
- Update CURRENT_AGENT to content-validator
- STATUS remains IN_PROGRESS
- Update UPDATED timestamp
- Add [DONE] entry to HANDOFF LOG

**Improvement Mode (개선 모드)**:
- Pattern: "개선 모드 감지 및 처리"
- Detect IMPROVEMENT_NEEDED field with quiz-writer entry
- Modify, add, or remove questions as specified
- Remove quiz-writer entry from IMPROVEMENT_NEEDED
- Update CURRENT_AGENT to next agent requiring improvement
- Add [IMPROVE] entry to HANDOFF LOG

### Question Type Requirements

#### 1. multiple-choice
**Required Sections**: Question, Options (4 items), Correct Answer, Explanation, Hints
**Format**: Correct Answer MUST exactly match one Option
**Use Case**: Conceptual understanding, multiple valid-looking choices

#### 2. true-false
**Required Sections**: Question, Correct Answer (- true or - false only), Explanation, Hints
**Format**: Question is a proposition or statement
**Use Case**: Verify binary facts, common misconceptions

#### 3. text-fill-in-blank
**Required Sections**: Question ("Fill in the blanks."), Text (with {{blank1}}, {{blank2}}), Blanks (- blank1: answer format), Correct Answer, Explanation, Hints
**Format**: Use {{blankN}} placeholders, map in Blanks section
**Use Case**: Key terminology, concepts

#### 4. fill-in-the-blank
**Required Sections**: Question ("Fill in the blanks."), Text (code with {{blank1}}, {{blank2}}), Blanks (- blank1: answer format), Correct Answer, Explanation, Hints
**Format**: Code blocks with {{blankN}} placeholders
**Use Case**: Code completion, syntax practice

#### 5. code-review
**Required Sections**: Question (with code block), Options (4 items), Correct Answer, Explanation, Hints
**Format**: Same as multiple-choice but Question contains code
**Use Case**: Identify issues/improvements in code

#### 6. output-prediction
**Required Sections**: Question (with code block), Output Lines (each starting with -), Correct Answer, Explanation, Hints
**Format**: Predict execution result
**Use Case**: Understanding code execution flow

### Difficulty Guidelines

**Difficulty 1** (Basic recall):
- Simple fact verification
- Direct concept questions
- Code: 3-5 lines
- Example: "var는 변수를 선언하는 키워드입니다. (true/false)"

**Difficulty 2** (Understanding):
- Requires basic understanding
- Single concept application
- Code: 5-10 lines
- Example: "var의 스코프는? (multiple-choice)"

**Difficulty 3** (Application):
- Apply concepts to new scenarios
- Combine 2 concepts
- Code: 5-10 lines
- Example: Predict output of hoisting code

**Difficulty 4** (Analysis):
- Analyze complex interactions
- Identify subtle bugs
- Code: 10-15 lines
- Example: Loop closure problem analysis

**Difficulty 5** (Synthesis/Evaluation):
- Multi-step reasoning
- Edge cases, optimizations
- Code: 10-20 lines
- Example: Global scope pollution in complex code

### Content Quality Standards

**Question Characteristics**:
- Clear and unambiguous wording
- Directly related to learned content
- Represents practical situations
- Has one definitively correct answer

**Avoid**:
- Ambiguous or subjective answers
- Pure memorization checks
- Content beyond learning scope
- Trick questions
- Only very easy OR very difficult (must have distribution)

**Hints Structure**:
1. **Hint 1**: Direction only (what to think about, which concept)
2. **Hint 2**: Specific clue (where to look, what to compare)
3. **Hint 3**: Almost answer level (one more logical step to solution)

**Explanation Guidelines**:
- 2-3 sentences
- State cause-effect relationships
- For multiple-choice: explain why correct answer is right AND why others are wrong
- For output-prediction/code-review: explain code execution order

### JavaScript Code Rules

- Use ES6+ syntax (const, let, arrow functions, template literals)
- Omit semicolons
- 2-space indentation
- camelCase variable names
- Code MUST be executable without syntax errors
- Intentional bugs only in code-review type questions

### Question Count and Distribution

**Total**: 8-12 questions (ideal: 10)
**Type Distribution**: Minimum 1 of each type (6 types)
**Difficulty Distribution**:
- 1-2: 30% (3 questions if total is 10)
- 3: 40% (4 questions if total is 10)
- 4-5: 30% (3 questions if total is 10)

### Parser Requirements

**Common Required Fields for ALL Types**:
1. `## Question N:` format with question number and title
2. `**ID**:` kebab-case identifier
3. `**Type**:` exactly one of 6 types
4. `**Difficulty**:` 1-5 number only
5. `### Question` header and content
6. `### Correct Answer` header and answer starting with -
7. `### Explanation` header and explanation
8. `### Hints` header and numbered list (exactly 3 hints)

**Type-Specific Required Fields**:
- multiple-choice / code-review: `### Options` (4 items starting with -)
- text-fill-in-blank / fill-in-the-blank: `### Text` with {{blankN}}, `### Blanks` with - blankN: format
- output-prediction: `### Output Lines` (each starting with -)

**Parser will fail if any required field is missing.**
