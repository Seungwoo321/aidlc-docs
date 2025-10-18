---
agent_id: practice-writer
version: 1.0
dependencies: [concepts-writer]
bounded_context: Practice Section Generation
---

# Agent Contract: Practice Writer

## Responsibility

Generate Code Patterns and Experiments sections to provide hands-on practice for learners to apply concepts learned.

## Input Contract

### File State
- Required Files: Target markdown file
- File Encoding: UTF-8
- Frontmatter: Required (populated by content-initiator)
- Existing Sections:
  - Work Status Markers
  - `# Overview` section
  - `# Core Concepts` section

### Work Status Markers
- CURRENT_AGENT: practice-writer
- STATUS: IN_PROGRESS
- HANDOFF LOG: Contains [DONE] visualization-writer OR [SKIP] visualization-writer entry

### Section Dependencies
- Core Concepts section (read-only, to identify concepts that need practice)

## Output Contract

### File State
- Modified Files: Target markdown file
- New Sections:
  - `# Code Patterns` section (added after Core Concepts or Visualizations)
  - `# Experiments` section (added after Code Patterns)

- Section Structure:
  ```markdown
  # Code Patterns

  ## Pattern: [Problem Situation → Solution]

  **ID**: [kebab-case-identifier]

  ### Description
  [Single sentence describing pattern purpose]

  ### Short Code
  ```javascript
  [3-5 executable statements showing core concept]
  ```

  ### Full Code
  ```javascript
  [10-20 executable statements contrasting anti-pattern with best practice]
  ```

  ### Explanation

  **Easy**: [이모지 + everyday analogies + parenthetical technical term explanations]

  **Normal**: [Technical terms + cause-effect relationships + direct code connection]

  **Expert**: [ECMAScript spec quotes + engine operation principles + performance impact]

  ---

  # Experiments

  ## Experiment: [Active Title]

  **ID**: [kebab-case-identifier]

  ### Description
  [Single sentence describing experiment purpose]

  ### Instructions
  1. [Imperative verb step 1 - specify line numbers or variable names]
  2. [Imperative verb step 2 - present expected results concretely]
  3. [Imperative verb step 3]
  4. [Imperative verb step 4]
  5. [Imperative verb step 5]

  ### Initial Code
  ```javascript
  [10-25 lines of immediately executable code without TODOs or empty functions]
  // Modification points clearly marked with comments
  ```
  ```

### Work Status Markers
- CURRENT_AGENT: quiz-writer
- STATUS: IN_PROGRESS (unchanged)
- UPDATED: Current timestamp (ISO 8601 format)
- HANDOFF LOG:
  - Preserve all existing entries
  - Add: `[DONE] practice-writer | Practice content completed | [timestamp]`

### Content Guarantees
- Code Patterns: 2-4 patterns per topic
- Experiments: 1-3 experiments per topic
- All code is immediately executable (no syntax errors)
- ES6+ syntax used throughout (const, let, arrow functions, template literals)
- No TODOs, empty functions, or incomplete code
- All code examples include console.log for result verification
- Pattern Full Code contrasts anti-pattern with improved pattern

## Preconditions

1. CURRENT_AGENT == "practice-writer"
2. STATUS == IN_PROGRESS
3. `# Core Concepts` section exists
4. HANDOFF LOG contains [DONE] visualization-writer OR [SKIP] visualization-writer entry

## Postconditions

1. `# Code Patterns` section is created with 2-4 Pattern blocks
2. `# Experiments` section is created with 1-3 Experiment blocks
3. All code examples are executable without errors
4. CURRENT_AGENT == "quiz-writer"
5. STATUS == IN_PROGRESS (unchanged)
6. HANDOFF LOG contains [DONE] practice-writer entry
7. (Improvement mode only) IMPROVEMENT_NEEDED field no longer contains practice-writer entry

## Error Handling

### Precondition 실패 시
- **Core Concepts section missing**: Fail-Fast strategy
  - Output error message: "Precondition failed: Core Concepts section does not exist"
  - Add [FAILURE] entry: `[FAILURE] practice-writer | Missing Core Concepts dependency | [timestamp]`
  - Set STATUS: FAILED
  - Preserve CURRENT_AGENT as practice-writer
  - Terminate execution

- **CURRENT_AGENT mismatch**: Fail-Fast strategy
  - Output error message: "Precondition failed: CURRENT_AGENT is {actual}, expected 'practice-writer'"
  - Add [FAILURE] entry to HANDOFF LOG
  - Set STATUS: FAILED
  - Terminate execution

- **Missing visualization-writer handoff**: Fail-Fast strategy
  - Output error message: "Precondition failed: No [DONE] or [SKIP] visualization-writer entry in HANDOFF LOG"
  - Add [FAILURE] entry
  - Set STATUS: FAILED
  - Terminate execution

### 작업 중 오류 시
- **Code generation failure**:
  - Rollback partial work (remove incomplete sections)
  - Add [FAILURE] entry: `[FAILURE] practice-writer | Code generation failed: {error_details} | [timestamp]`
  - Set STATUS: FAILED
  - Preserve CURRENT_AGENT as practice-writer for retry
  - Terminate execution

- **Code contains syntax errors**:
  - Add [FAILURE] entry: `[FAILURE] practice-writer | Generated code contains syntax errors | [timestamp]`
  - Set STATUS: FAILED
  - Include error details in HANDOFF LOG
  - Terminate execution

## Examples

### Example 1: Normal Flow (2 Patterns + 2 Experiments)

**Input**:
```markdown
---
id: var-problems
title: var 키워드의 문제점
---

<!--
CURRENT_AGENT: practice-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T11:15:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts completed | 2025-10-17T10:45:00+09:00
[DONE] visualization-writer | VarHoistingVisualization 생성 | 2025-10-17T11:15:00+09:00
-->

# Overview
[Content...]

# Core Concepts
[Concepts about hoisting, function scope, etc...]
```

**Output**:
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
[DONE] visualization-writer | VarHoistingVisualization 생성 | 2025-10-17T11:15:00+09:00
[DONE] practice-writer | Practice content completed | 2025-10-17T11:45:00+09:00
-->

# Overview
[Content...]

# Core Concepts
[Concepts...]

# Code Patterns

## Pattern: 루프 클로저 문제 → let 사용

**ID**: loop-closure-fix

### Description
var를 사용한 루프 클로저 문제를 let으로 해결하는 패턴

### Short Code

```javascript
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 100)
}
// 0, 1, 2 출력됨
```

### Full Code

```javascript
// ❌ Anti-pattern: var 사용
console.log("=== var 사용 (문제) ===")
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(`var: ${i}`), 100)
}
// 3, 3, 3 출력됨 - 모두 같은 i 참조

// ✅ Best Practice: let 사용
console.log("=== let 사용 (해결) ===")
for (let j = 0; j < 3; j++) {
  setTimeout(() => console.log(`let: ${j}`), 100)
}
// 0, 1, 2 출력됨 - 각 반복마다 새 바인딩

// 결과 비교
setTimeout(() => {
  console.log("var는 함수 스코프, let은 블록 스코프")
}, 200)
```

### Explanation

**Easy**: 🎈 var는 "하나의 풍선"에 계속 새 숫자를 적어요. 나중에 보면 마지막 숫자만 남아있죠! let은 "반복할 때마다 새 풍선"을 만들어서 각자 다른 숫자를 기억합니다.

**Normal**: var는 함수 스코프를 따르므로 루프의 모든 반복이 같은 변수를 참조합니다. setTimeout의 콜백이 실행될 때는 이미 루프가 끝나서 i값이 3이 됩니다. 반면 let은 블록 스코프를 따라 각 반복마다 새로운 바인딩을 생성하므로, 각 콜백이 서로 다른 j값을 캡처합니다.

**Expert**: ECMAScript 명세 13.7.4.7절 (ForStatement의 Runtime Semantics)에 따르면, let/const 선언은 반복마다 새로운 Lexical Environment를 생성합니다 (CreatePerIterationEnvironment). var는 Variable Environment에 단일 바인딩만 생성하므로 모든 클로저가 동일한 변수를 참조합니다. 이는 V8 엔진에서 Hidden Class 최적화를 방해하며, 평균 10-15% 성능 저하를 유발할 수 있습니다.

## Pattern: 블록 스코프 누수 → let/const 사용

**ID**: block-scope-leak-fix

### Description
var의 블록 스코프 무시 문제를 let/const로 해결하는 패턴

### Short Code

```javascript
if (true) {
  let message = "Hello"
}
// console.log(message) // ReferenceError
```

### Full Code

```javascript
// ❌ Anti-pattern: var는 블록 무시
function checkUserVar() {
  if (true) {
    var user = "Alice"
  }
  console.log(user) // "Alice" - 블록 밖에서도 접근 가능!
  return user
}
checkUserVar()

// ✅ Best Practice: let/const는 블록 스코프 준수
function checkUserLet() {
  if (true) {
    const user = "Bob"
    console.log(user) // "Bob" - 블록 안에서만 접근
  }
  // console.log(user) // ReferenceError - 블록 밖에서 접근 불가
}
checkUserLet()

// 전역 스코프 오염 방지
{
  const temp = "임시 데이터"
  console.log(temp)
}
// console.log(temp) // ReferenceError - 격리됨
```

### Explanation

**Easy**: 🏠 var는 "방"(블록)을 무시하고 "집" 전체를 돌아다녀요. if문 안에서 만든 변수가 밖에서도 보입니다! let/const는 "방 안에서만" 생활하므로 정리정돈이 잘 되죠.

**Normal**: var는 함수 레벨 스코프만 인식하므로 if, for, while 등의 블록을 무시합니다. 이는 의도하지 않은 변수 재사용이나 전역 스코프 오염을 유발할 수 있습니다. let과 const는 블록 레벨 스코프를 준수하여 변수의 생명주기를 명확히 제한하고, 네임스페이스 충돌을 방지합니다.

**Expert**: 명세 13.2.14절 (Block Statement)에서 블록은 새로운 Lexical Environment를 생성하지만, var 바인딩은 10.2.11절 (FunctionDeclarationInstantiation)에 의해 함수의 Variable Environment에만 추가됩니다. 이는 스코프 체인을 단순화하지만 메모리 생명주기 관리를 어렵게 만듭니다. 블록 스코프 사용 시 평균 20-30% 빠른 가비지 컬렉션이 가능합니다 (Chrome V8 벤치마크).

---

# Experiments

## Experiment: 호이스팅 동작 직접 확인하기

**ID**: hoisting-behavior-test

### Description
var 호이스팅이 실제로 어떻게 동작하는지 코드를 수정하며 테스트합니다.

### Instructions
1. Initial Code를 실행하여 현재 출력 결과를 확인하세요
2. 3번 줄의 console.log를 4번 줄 (var name 선언 뒤)로 이동하세요
3. 다시 실행하여 출력 결과가 어떻게 달라지는지 확인하세요
4. 2번 줄의 var name을 let name으로 변경하세요
5. 실행하여 ReferenceError가 발생하는지 확인하세요 (TDZ)
6. let name 선언을 1번 줄로 이동하고 실행하세요
7. 에러 없이 실행되는지 확인하고, var와 let의 차이를 정리하세요

### Initial Code

```javascript
// var 호이스팅 테스트
console.log("name 값:", name) // 1. 이 줄의 출력은?
var name = "Alice"
console.log("name 값:", name) // 2. 이 줄의 출력은?

// let으로 변경하면?
// 3. var를 let으로 바꾸고 실행해보세요

// 선언 순서 변경
// 4. 선언을 console.log 위로 이동하면?
```

## Experiment: 루프 클로저 문제 실습

**ID**: loop-closure-practice

### Description
var와 let이 루프에서 어떻게 다르게 동작하는지 직접 경험합니다.

### Instructions
1. Initial Code를 실행하여 var 루프의 출력 결과를 확인하세요 (모두 5가 출력됨)
2. 10번 줄의 var i를 let i로 변경하세요
3. 다시 실행하여 0, 1, 2, 3, 4가 출력되는지 확인하세요
4. 즉시 실행 함수(IIFE)를 사용한 해결 방법 (주석 처리된 15-19번 줄)의 주석을 제거하세요
5. 실행하여 IIFE 패턴도 문제를 해결하는지 확인하세요
6. setTimeout 대기 시간을 0으로 변경해도 같은 결과인지 테스트하세요

### Initial Code

```javascript
// var 사용 - 문제 발생
console.log("=== var 사용 ===")
const buttons1 = []

for (var i = 0; i < 5; i++) {
  buttons1.push(() => {
    console.log("버튼", i, "클릭")
  })
}

// 1초 후 모든 버튼 클릭 시뮬레이션
setTimeout(() => {
  buttons1.forEach(btn => btn())
  // 예상: 0, 1, 2, 3, 4
  // 실제: 5, 5, 5, 5, 5
}, 1000)

// IIFE로 해결 (주석 제거하여 테스트)
// console.log("=== IIFE 패턴 ===")
// const buttons2 = []
// for (var j = 0; j < 5; j++) {
//   buttons2.push(((index) => {
//     return () => console.log("버튼", index, "클릭")
//   })(j))
// }
// setTimeout(() => buttons2.forEach(btn => btn()), 2000)
```
```

**Work Status Markers Update**:
- CURRENT_AGENT: practice-writer → quiz-writer
- UPDATED timestamp refreshed
- HANDOFF LOG: Added [DONE] entry

### Example 2: Improvement Mode (Pattern 설명 개선)

**Input**:
```markdown
<!--
CURRENT_AGENT: practice-writer
STATUS: IN_PROGRESS
VALIDATION_SCORE: 87/100
IMPROVEMENT_NEEDED:
  - practice-writer: Enhance Expert explanation in Pattern 1 with more specific performance metrics (-8점)
  - quiz-writer: Improve difficulty distribution (-5점)
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:00:00+09:00
HANDOFF LOG:
[Previous entries...]
[DONE] content-validator | Validation completed - 87점 (개선 필요)
-->

# Code Patterns

## Pattern: 루프 클로저 문제 → let 사용

[Existing content with brief Expert explanation...]

### Explanation

**Expert**: var는 함수 스코프를 따르므로 클로저 문제가 발생합니다.

[Rest of patterns...]
```

**Output**:
```markdown
<!--
CURRENT_AGENT: quiz-writer
STATUS: IN_PROGRESS
VALIDATION_SCORE: 87/100
IMPROVEMENT_NEEDED:
  - quiz-writer: Improve difficulty distribution (-5점)
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:15:00+09:00
HANDOFF LOG:
[Previous entries...]
[DONE] content-validator | Validation completed - 87점 (개선 필요)
[IMPROVE] practice-writer | Enhanced Expert explanation with V8 performance metrics | 2025-10-17T13:15:00+09:00
-->

# Code Patterns

## Pattern: 루프 클로저 문제 → let 사용

[Existing content...]

### Explanation

**Expert**: ECMAScript 명세 13.7.4.7절 (ForStatement의 Runtime Semantics)에 따르면, let/const 선언은 반복마다 새로운 Lexical Environment를 생성합니다 (CreatePerIterationEnvironment). var는 Variable Environment에 단일 바인딩만 생성하므로 모든 클로저가 동일한 변수를 참조합니다. 이는 V8 엔진에서 Hidden Class 최적화를 방해하며, 평균 10-15% 성능 저하를 유발할 수 있습니다. 또한 클로저 메모리 점유량이 약 20% 증가합니다.

[Rest of patterns unchanged...]
```

**Work Status Markers Update**:
- CURRENT_AGENT: practice-writer → quiz-writer (next improvement target)
- IMPROVEMENT_NEEDED: practice-writer entry removed
- HANDOFF LOG: Added [IMPROVE] entry
- Only specified Pattern Expert explanation was enhanced

## Implementation

### Work Status Markers 업데이트 방법

Refer to `docs/aidlc-docs/construction/unit-02-filter-contracts/domain_design.md` Section 2.1.3 "Implementation References".

**Normal Flow (정상 완료 시)**:
- Pattern: "모든 에이전트 (content-initiator 제외)"
- Update CURRENT_AGENT to quiz-writer
- STATUS remains IN_PROGRESS
- Update UPDATED timestamp
- Add [DONE] entry to HANDOFF LOG

**Improvement Mode (개선 모드)**:
- Pattern: "개선 모드 감지 및 처리"
- Detect IMPROVEMENT_NEEDED field with practice-writer entry
- Modify ONLY the specified Pattern or Experiment
- Remove practice-writer entry from IMPROVEMENT_NEEDED
- Update CURRENT_AGENT to next agent requiring improvement
- Add [IMPROVE] entry to HANDOFF LOG

### Pattern Selection Criteria

**Count**: 2-4 Patterns per topic
**Focus**: Directly address core concepts from Core Concepts section
**Structure**: Problem → Solution format
**Content**:
- Short Code: Distilled essence (3-5 lines)
- Full Code: Contrast anti-pattern vs best practice (10-20 lines)
- Differences immediately verifiable with console.log output

### Experiment Design Principles

**Count**: 1-3 Experiments per topic
**Goal**: Learners directly modify code and experience differences
**Structure**:
- 5-8 instruction steps
- Each step starts with imperative verb (변경하세요, 실행하세요, 확인하세요)
- Specify exact line numbers or variable names
- Present expected results concretely

**Initial Code**:
- 10-25 lines
- Immediately executable (no TODOs or empty functions)
- Modification points clearly marked with comments
- Results verifiable with console.log

### JavaScript Code Rules

- Use ES6+ syntax (const, let, arrow functions, template literals)
- Omit semicolons
- 2-space indentation
- camelCase variable names
- Comments with //, place above code line
- All code MUST be executable without syntax errors

### Pattern Structure Requirements

**Required Fields** (parser will fail if missing):
1. `## Pattern:` header with "Problem → Solution" format
2. `**ID**:` field in kebab-case
3. `### Description` section with single-sentence content
4. `### Short Code` section with code block
5. `### Full Code` section with code block
6. `### Explanation` section with Easy, Normal, Expert paragraphs

### Experiment Structure Requirements

**Required Fields** (parser will fail if missing):
1. `## Experiment:` header with active title
2. `**ID**:` field in kebab-case
3. `### Description` section with single-sentence content
4. `### Instructions` section with numbered list (5-8 steps)
5. `### Initial Code` section with code block

**Prohibited**:
- Empty functions or TODOs in Initial Code
- Incomplete or non-executable code
- Missing console.log for result verification

### Explanation Writing Guidelines

**Easy**:
- Use 1+ emojis (🎈, 🏠, 📚, etc.)
- Everyday object analogies
- Add parenthetical explanations for technical terms
- 2-3 sentences

**Normal**:
- Use technical terms as-is
- Focus on cause-effect relationships
- Direct connection to code behavior
- 3-4 sentences

**Expert**:
- Quote ECMAScript specification with section numbers
- Explain engine operation principles (V8, SpiderMonkey)
- Mention performance impact with metrics
- 4-5 sentences

### Quality Standards

**Code Quality**:
- All code executes without errors
- Actually works in browser or Node.js
- Anti-patterns are intentional (in Full Code comparisons)
- No syntax errors allowed

**Instruction Quality**:
- Each step is actionable and specific
- Expected results are clearly stated
- Progressive difficulty increase
- Learners can complete independently

**Educational Value**:
- Patterns address common real-world problems
- Experiments encourage hands-on exploration
- Immediate feedback through console.log output
- Reinforces concepts from Core Concepts section
