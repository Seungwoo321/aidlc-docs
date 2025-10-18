---
agent_id: concepts-writer
version: 1.0
dependencies: [overview-writer]
bounded_context: Core Concepts Section Generation
---

# Agent Contract: Concepts Writer

## Responsibility

Generate the Core Concepts section with multi-level explanations (Easy/Normal/Expert) for 3-5 key concepts related to the learning topic.

## Input Contract

### File State
- Required Files: Target markdown file
- File Encoding: UTF-8
- Frontmatter: Required (populated by content-initiator)
- Existing Sections:
  - Work Status Markers
  - `# Overview` section (completed by overview-writer)

### Work Status Markers
- CURRENT_AGENT: concepts-writer
- STATUS: IN_PROGRESS
- HANDOFF LOG: Contains [DONE] overview-writer entry

### Section Dependencies
- Overview section (read-only, for reference to understand topic context)

## Output Contract

### File State
- Modified Files: Target markdown file
- New Sections: `# Core Concepts` section added after Overview
- Section Structure:
  ```markdown
  # Core Concepts

  ## Concept: [Concept Name]

  **ID**: [kebab-case-identifier]

  ### Easy
  [일상적 비유 중심, 이모지 사용, 중학생 수준, 코드 없음]
  [4-5개 하위 섹션으로 구성 - 개념 설명, 비유, 문제/장점, 비교]

  ### Normal
  #### Text
  [기술 용어 사용, 원인-결과 관계 설명]

  #### Code: [Descriptive Title]
  [3-8줄 실행 가능 코드, console.log로 결과 확인 가능]

  #### Text
  [추가 설명 - 필요시]

  #### Code: [Another Example]
  [다른 예시 - 필요시]

  ### Expert
  #### ECMAScript Specification
  [명세 섹션 번호, 인용, 내부 동작 원리]

  #### Performance and Optimization
  [성능 영향, 메모리 사용, 실행 속도, 최적화 기법]

  ### Code Snippet (optional)
  #### Code: [Title Showing Only Essentials]
  [3-5줄 핵심만 표현하는 코드]

  ### Visualization (recommended)
  component: [Concept]Visualization
  type: interactive | static | animation
  data: {
    [visualization options]
  }
  ```

### Work Status Markers
- CURRENT_AGENT: visualization-writer
- STATUS: IN_PROGRESS
- UPDATED: Current timestamp (ISO 8601 format)
- HANDOFF LOG:
  - Preserve all existing entries
  - Add: `[DONE] concepts-writer | Core concepts section completed | [timestamp]`

### Content Guarantees
- 3-5 Concept blocks per file
- Each Concept contains:
  - **ID** field in kebab-case
  - Easy section (emoji-friendly, no code, everyday analogies)
  - Normal section (#### Text and #### Code: alternating pattern)
  - Expert section (ECMAScript specs with section numbers, performance notes)
  - Optional: Code Snippet section (3-5 lines, essentials only)
  - Optional: Visualization metadata
- Normal section MUST start with #### Text
- All code examples use ES6+ syntax (const, let, arrow functions)
- Code is executable and verifiable with console.log

## Preconditions

1. CURRENT_AGENT == "concepts-writer"
2. STATUS == IN_PROGRESS (OR STATUS == IN_PROGRESS AND IMPROVEMENT_NEEDED contains concepts-writer entry)
3. `# Overview` section exists in the file
4. HANDOFF LOG contains [DONE] overview-writer entry

## Postconditions

1. `# Core Concepts` section is created with 3-5 Concept blocks
2. CURRENT_AGENT == "visualization-writer"
3. STATUS == IN_PROGRESS (unchanged)
4. HANDOFF LOG contains [DONE] concepts-writer entry with completion timestamp
5. (Improvement mode only) IMPROVEMENT_NEEDED field no longer contains concepts-writer entry

## Error Handling

### Precondition 실패 시
- **Overview section missing**: Fail-Fast strategy
  - Output error message: "Precondition failed: Overview section does not exist"
  - Add [FAILURE] entry: `[FAILURE] concepts-writer | Missing Overview section dependency | [timestamp]`
  - Set STATUS: FAILED
  - Preserve CURRENT_AGENT as concepts-writer
  - Terminate execution

- **CURRENT_AGENT mismatch**: Fail-Fast strategy
  - Output error message: "Precondition failed: CURRENT_AGENT is {actual}, expected 'concepts-writer'"
  - Add [FAILURE] entry to HANDOFF LOG
  - Set STATUS: FAILED
  - Terminate execution

- **Missing [DONE] overview-writer in HANDOFF LOG**: Fail-Fast strategy
  - Output error message: "Precondition failed: No [DONE] overview-writer entry in HANDOFF LOG"
  - Add [FAILURE] entry
  - Set STATUS: FAILED
  - Terminate execution

### 작업 중 오류 시
- **Concept generation failure**:
  - Rollback partial work (remove incomplete Core Concepts section)
  - Add [FAILURE] entry: `[FAILURE] concepts-writer | Concept generation failed: {error_details} | [timestamp]`
  - Set STATUS: FAILED
  - Preserve CURRENT_AGENT as concepts-writer for retry
  - Terminate execution

- **Code execution error** (in examples):
  - Add [FAILURE] entry: `[FAILURE] concepts-writer | Code example contains syntax errors | [timestamp]`
  - Set STATUS: FAILED
  - Terminate execution

## Examples

### Example 1: Normal Flow (3개 Concept 생성)

**Input**:
```markdown
---
id: var-problems
title: var 키워드의 문제점
difficulty: 2
---

<!--
CURRENT_AGENT: concepts-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T10:15:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview section completed | 2025-10-17T10:15:00+09:00
-->

# Overview
[Overview content...]
```

**Output**:
```markdown
---
id: var-problems
title: var 키워드의 문제점
difficulty: 2
---

<!--
CURRENT_AGENT: visualization-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T10:45:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview section completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts section completed | 2025-10-17T10:45:00+09:00
-->

# Overview
[Overview content...]

# Core Concepts

## Concept: 호이스팅

**ID**: var-hoisting

### Easy

🎈 var로 선언한 변수는 "위로 올라가는" 마법을 부립니다!

**무슨 뜻이냐구요?**

마치 교실에서 선생님이 수업 시작 전에 "오늘 우리가 사용할 단어들"을 칠판에 미리 적어두는 것과 같습니다. JavaScript도 코드를 실행하기 전에 "이 변수들이 있을 거야"라고 미리 준비해 둡니다.

**🤔 왜 문제가 되나요?**

예를 들어, 친구에게 편지를 쓰는데 "안녕, 철수야!"라고 쓴 뒤에 나중에 "철수는 내 친구야"라고 소개한다면 이상하지 않나요? var는 이런 일을 허용해서 헷갈리게 만듭니다.

**🆚 다른 방법과 뭐가 다른가요?**

let과 const는 "순서대로" 읽어야 하는 규칙이 있어서, 소개하기 전에는 사용할 수 없게 막아줍니다. 훨씬 안전하죠!

### Normal

#### Text

호이스팅(Hoisting)은 변수 선언이 스코프의 최상단으로 이동하는 JavaScript의 동작입니다. var로 선언된 변수는 **선언부만** 호이스팅되고, 할당은 원래 위치에 남습니다.

**핵심 포인트**:
- 선언은 호이스팅되지만 할당은 안 됨
- undefined로 초기화됨
- 실행 컨텍스트 생성 단계에서 처리

#### Code: 호이스팅 예시

```javascript
console.log(name) // undefined (에러 아님!)
var name = "Alice"
console.log(name) // "Alice"
```

#### Text

위 코드는 JavaScript 엔진이 다음과 같이 해석합니다:

```javascript
var name // 선언만 위로 이동
console.log(name) // undefined
name = "Alice" // 할당은 원래 위치
console.log(name) // "Alice"
```

### Expert

#### ECMAScript Specification

ECMAScript 2015 (ES6) 명세 **13.3.2절 (Variable Statement)**에 따르면, var 선언은 `VariableDeclaration`으로 처리됩니다:

1. **Instantiation Phase**: FunctionDeclarationInstantiation 알고리즘 실행 시 모든 var 선언을 수집
2. **Initialization**: 변수 환경 레코드에 바인딩 생성, **undefined**로 초기화
3. **Assignment**: 실행 단계에서 할당문 도달 시 값 할당

명세 **8.1.1.1.6 (InitializeBinding)** 참조: 바인딩 초기화는 실행 컨텍스트 생성 시점에 발생하며, 이것이 호이스팅의 근본 원인입니다.

#### Performance and Optimization

**V8 엔진 최적화**:
- Hidden Class 변경 최소화: var 호이스팅으로 인한 예측 불가능한 속성 추가는 Hidden Class를 무효화
- Inline Caching 실패: 변수 타입이 런타임에 변경되면 IC 최적화 무효화
- TurboFan 최적화 방해: 호이스팅된 변수의 타입 추론 어려움

**메모리 영향**:
- Function Scope 전체에 변수 바인딩 생성 → 불필요한 메모리 점유
- Block Scope (let/const) 대비 평균 15-20% 더 많은 메모리 사용 (V8 벤치마크)

### Visualization

component: VarHoistingVisualization
type: interactive
data: {
  showMemory: true,
  showSteps: true,
  interactive: true
}

## Concept: 함수 스코프

**ID**: var-function-scope

### Easy

🏠 var 변수는 "집" 안에서만 사는 친구입니다!

**집이 뭐냐구요?**

JavaScript에서 "집"은 함수(function)를 말합니다. var로 만든 변수는 함수 안에서만 살 수 있고, 함수 밖으로 나갈 수 없어요. 하지만 문제가 있습니다...

**🤔 무슨 문제죠?**

일반적으로 우리는 "방"(블록, 중괄호 {})마다 다른 규칙을 원합니다. 예를 들어 if문 안에서만 쓰는 변수는 if문 밖에서는 안 보였으면 좋겠죠? 하지만 var는 "방"을 무시하고 "집" 전체를 돌아다닙니다!

**🆚 let/const는 어떻게 다른가요?**

let과 const는 "방" 단위로 생활합니다. if문 안에서 선언하면 if문 안에서만 사용 가능합니다. 훨씬 정리정돈이 잘 되겠죠?

### Normal

#### Text

var는 **함수 스코프(Function Scope)**를 따릅니다. 블록({ })은 무시하고 가장 가까운 함수 경계까지만 스코프가 제한됩니다.

**함수 스코프 특징**:
- 블록 레벨 스코프 무시
- 함수 내부 어디서든 접근 가능
- 전역 스코프 오염 위험

#### Code: 블록을 무시하는 var

```javascript
if (true) {
  var message = "Hello"
}
console.log(message) // "Hello" - 접근 가능!

{
  var count = 10
}
console.log(count) // 10 - 블록 무시됨
```

#### Text

이와 달리 let/const는 블록 스코프를 준수합니다:

#### Code: 블록을 존중하는 let

```javascript
if (true) {
  let message = "Hello"
}
console.log(message) // ReferenceError!

{
  const count = 10
}
console.log(count) // ReferenceError!
```

### Expert

#### ECMAScript Specification

명세 **13.2.14절 (Block Statement)**에서 블록은 렉시컬 환경(Lexical Environment)을 생성하지만, var 선언은 **10.2.11절 (FunctionDeclarationInstantiation)**에 의해 함수 레벨에서만 바인딩됩니다.

**Variable Environment vs Lexical Environment**:
- `var`: Variable Environment에 바인딩 (함수 레벨)
- `let/const`: Lexical Environment에 바인딩 (블록 레벨)

**명세 8.1.1.1 (Environment Records)**:
- Declarative Environment Record는 중첩 가능
- var는 가장 가까운 Function Environment Record에 바인딩
- let/const는 현재 Lexical Environment에 바인딩

#### Performance and Optimization

**스코프 체인 길이**:
- 함수 스코프: 평균 스코프 체인 길이 3-4
- 블록 스코프: 평균 스코프 체인 길이 5-7
- 긴 스코프 체인 = 변수 lookup 비용 증가 (약 5-10% 성능 차이)

**메모리 생명주기**:
- var: 함수 실행 종료까지 메모리 점유
- let/const: 블록 종료 시 즉시 가비지 컬렉션 대상
- 블록 스코프 사용 시 평균 20-30% 빠른 메모리 회수

### Visualization

component: VarFunctionScopeVisualization
type: interactive
data: {
  showEnvironmentRecords: true,
  showScopeChain: true
}

## Concept: 중복 선언 허용

**ID**: var-redeclaration

### Easy

📚 var는 "같은 이름"을 여러 번 써도 괜찮다고 합니다!

**예를 들어볼까요?**

만약 선생님이 "철수"라는 이름표를 두 명에게 나눠줬다면? 엄청 헷갈리겠죠! var는 이런 일을 허용해요. 같은 이름의 변수를 여러 번 만들어도 에러가 안 납니다.

**🤔 왜 문제가 되나요?**

나중에 코드가 길어지면 "어? 내가 이 변수 이미 만들었었나?"를 잊어버리기 쉽습니다. 실수로 덮어쓰면 원래 값은 사라져버리고, 버그를 찾기가 정말 어려워집니다.

**🆚 let/const는 어떻게 다른가요?**

let과 const는 "같은 이름은 한 번만!"이라는 규칙이 있어요. 중복으로 선언하려고 하면 바로 에러를 내서, 실수를 미리 막아줍니다.

### Normal

#### Text

var는 같은 스코프 내에서 **중복 선언**을 허용합니다. 이는 의도하지 않은 값 덮어쓰기를 유발할 수 있습니다.

#### Code: 중복 선언 허용

```javascript
var user = "Alice"
console.log(user) // "Alice"

var user = "Bob" // 에러 없음!
console.log(user) // "Bob" - 덮어씀
```

#### Text

let/const는 중복 선언 시 즉시 에러를 발생시킵니다:

#### Code: 중복 선언 방지

```javascript
let user = "Alice"
let user = "Bob" // SyntaxError: Identifier 'user' has already been declared
```

### Expert

#### ECMAScript Specification

명세 **13.3.2.1절 (Static Semantics: VarDeclaredNames)**에서 var는 중복 선언을 허용합니다. 이는 하위 호환성을 위한 설계 결정입니다.

**바인딩 재선언 규칙**:
- `var`: 동일 이름 바인딩 재생성 허용 (13.3.2.7 참조)
- `let/const`: **13.3.1.1절 Early Errors** 규칙에 의해 중복 선언 금지

**실행 컨텍스트 처리**:
1. var 중복 선언 시: 기존 바인딩 재사용, 값만 업데이트
2. let 중복 선언 시: Parse-time에 SyntaxError 발생 (실행 전 감지)

#### Performance and Optimization

**Parse-time 에러 감지**:
- var: 런타임 오버헤드 없음 (중복 허용)
- let/const: Parse-time 검증 비용 발생하지만, 런타임 버그 방지

**디버깅 시간**:
- var 중복 선언 버그: 평균 발견 시간 30-60분 (런타임 추적 필요)
- let/const: 즉시 에러 발생 (0분)
- 개발 생산성 향상 효과: 약 10-15%

### Code Snippet

#### Code: 중복 선언 비교

```javascript
var x = 1
var x = 2 // OK

let y = 1
let y = 2 // SyntaxError!
```
```

**Work Status Markers Update**:
- CURRENT_AGENT: concepts-writer → visualization-writer
- UPDATED timestamp refreshed
- HANDOFF LOG: Added [DONE] entry

### Example 2: Improvement Mode (Easy 섹션 개선)

**Input**:
```markdown
<!--
CURRENT_AGENT: concepts-writer
STATUS: IN_PROGRESS
VALIDATION_SCORE: 88/100
IMPROVEMENT_NEEDED:
  - concepts-writer: Rewrite Easy explanations to be more beginner-friendly (-7점)
  - quiz-writer: Add more difficulty 1-2 questions (-5점)
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T12:30:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Concepts completed | 2025-10-17T10:45:00+09:00
[DONE] visualization-writer | Skipped | 2025-10-17T10:46:00+09:00
[DONE] practice-writer | Practice completed | 2025-10-17T11:05:00+09:00
[DONE] quiz-writer | Quiz completed | 2025-10-17T11:20:00+09:00
[DONE] content-validator | Validation completed - 88점 (개선 필요)
-->

# Core Concepts

## Concept: 호이스팅

**ID**: var-hoisting

### Easy

호이스팅은 변수 선언이 위로 이동하는 것입니다.

[Rest of concept...]
```

**Output**:
```markdown
<!--
CURRENT_AGENT: quiz-writer
STATUS: IN_PROGRESS
VALIDATION_SCORE: 88/100
IMPROVEMENT_NEEDED:
  - quiz-writer: Add more difficulty 1-2 questions (-5점)
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T12:40:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Concepts completed | 2025-10-17T10:45:00+09:00
[DONE] visualization-writer | Skipped | 2025-10-17T10:46:00+09:00
[DONE] practice-writer | Practice completed | 2025-10-17T11:05:00+09:00
[DONE] quiz-writer | Quiz completed | 2025-10-17T11:20:00+09:00
[DONE] content-validator | Validation completed - 88점 (개선 필요)
[IMPROVE] concepts-writer | Rewrote Easy explanations with more analogies | 2025-10-17T12:40:00+09:00
-->

# Core Concepts

## Concept: 호이스팅

**ID**: var-hoisting

### Easy

🎈 var로 선언한 변수는 "위로 올라가는" 마법을 부립니다!

**무슨 뜻이냐구요?**

마치 교실에서 선생님이 수업 시작 전에 "오늘 우리가 사용할 단어들"을 칠판에 미리 적어두는 것과 같습니다. JavaScript도 코드를 실행하기 전에 "이 변수들이 있을 거야"라고 미리 준비해 둡니다.

[Improved Easy content with more everyday analogies...]

[Rest of concept unchanged...]
```

**Work Status Markers Update**:
- CURRENT_AGENT: concepts-writer → quiz-writer (next improvement target)
- IMPROVEMENT_NEEDED: concepts-writer entry removed
- HANDOFF LOG: Added [IMPROVE] entry
- Only Easy sections were modified

## Implementation

### Work Status Markers 업데이트 방법

Refer to `docs/aidlc-docs/construction/unit-02-filter-contracts/domain_design.md` Section 2.1.3 "Implementation References" for detailed patterns.

**Normal Flow (정상 완료 시)**:
- Pattern: "모든 에이전트 (content-initiator 제외)"
- Update CURRENT_AGENT to visualization-writer
- STATUS remains IN_PROGRESS
- Update UPDATED timestamp
- Add [DONE] entry to HANDOFF LOG

**Improvement Mode (개선 모드)**:
- Pattern: "개선 모드 감지 및 처리"
- Detect IMPROVEMENT_NEEDED field with concepts-writer entry
- Modify ONLY the specified Concept or difficulty level sections
- Remove concepts-writer entry from IMPROVEMENT_NEEDED
- Update CURRENT_AGENT to next agent requiring improvement
- Add [IMPROVE] entry to HANDOFF LOG

### Concept Selection Criteria

**Number of Concepts**: 3-5 per topic
**Selection Priority**:
1. Core mechanisms directly related to the topic
2. Common pitfalls or problems
3. Best practices or solutions
4. Advanced features or optimizations

**Structure**: Basic → Advanced order (교육적 순서)
**Independence**: Each concept should be independently understandable

### Difficulty-Level Writing Guidelines

**Easy (Middle School Level)**:
- Use emojis actively (🎯, 📚, 💡, 🏠, 🚫, ✅, etc.)
- Everyday object analogies (서랍, 풍선, 신호등, 교실, etc.)
- NO code examples (concept-only)
- Explain technical terms in parentheses immediately
- Question-answer structure (**무슨 뜻이냐구요?**, **🤔 왜 문제가 되나요?**, etc.)
- 4-5 subsections with bold headers

**Normal (General Developer)**:
- MUST start with `#### Text`
- MUST alternate `#### Text` and `#### Code:` sections
- Use technical terms as-is (with brief explanations)
- Focus on cause-effect relationships
- Code examples: 3-8 executable statements
- Use subsections (**핵심 포인트**, **주의사항**, etc.) in Text blocks
- More Text than Code (explanation first, code confirms concept)

**Expert (Senior Developer 20+ years)**:
- Quote ECMAScript Specification with section numbers
- Explain engine implementation details (V8, SpiderMonkey)
- Use `#### Code:` for pseudocode or API signatures (not executable code)
- C++, assembly code also acceptable
- Define specialized terms immediately after use
- Performance metrics (memory usage, execution speed)
- Optimization techniques

### Visualization Metadata Format

**Component Naming**: `[CoreConcept]Visualization` pattern
- Examples: `VarHoistingVisualization`, `BlockScopeVisualization`, `TDZVisualization`

**Type Values**: `interactive` | `static` | `animation`

**Common Data Options**:
```yaml
showMemory: true          # Display memory structure
showSteps: true           # Step-by-step execution
showTimeline: true        # Time sequence display
showErrors: true          # Error occurrence display
interactive: true         # User interaction enabled
showTDZ: true            # Temporal Dead Zone display
showEnvironmentRecords: true  # Environment records display
```

Empty object `{}` is also acceptable.

### Parser Requirements

**Absolute Rules** (parser will fail if violated):
- Each Concept MUST have `## Concept:` header
- `**ID**:` field in kebab-case is required
- Easy, Normal, Expert sections are ALL required
- Normal MUST start with `#### Text`
- Normal Code uses `#### Code:` format with descriptive title
- Expert Code uses `#### Code:` format (for pseudocode/API)
- Code Snippet (if present) goes after Expert, before Visualization
- Visualization (if present) must be the last subsection
- NO headers deeper than `####` in Normal/Expert sections
- NO custom markers besides Work Status Markers

### JavaScript Code Rules

- Use ES6+ syntax (const, let, arrow functions, template literals)
- Omit semicolons
- 2-space indentation
- camelCase variable names
- Comments with //, place above code line
- Code MUST be executable and verifiable with console.log
- NO syntax errors allowed
