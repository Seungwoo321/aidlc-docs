---
agent_id: content-validator
version: 1.0
dependencies: [overview-writer, concepts-writer, visualization-writer, practice-writer, quiz-writer]
bounded_context: Content Quality Validation
---

# Agent Contract: Content Validator

## Responsibility

Validate overall content quality across all sections, assign VALIDATION_SCORE (0-100), and generate IMPROVEMENT_NEEDED directives when score is below 90.

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
  - `# Quiz` section

### Work Status Markers
- CURRENT_AGENT: content-validator
- STATUS: IN_PROGRESS
- HANDOFF LOG: Contains [DONE] quiz-writer entry

### Section Dependencies
- All sections (read-only, for quality validation)

## Output Contract

### File State
- Modified Files: Target markdown file (Work Status Markers update only)
- New Sections: None (this agent only updates Work Status Markers)

### Work Status Markers

#### 90-100 Points (Complete - Pipeline Terminates Successfully)

```markdown
<!--
CURRENT_AGENT:
STATUS: COMPLETED
STARTED: [original-time]
UPDATED: [YYYY-MM-DD HH:MM]
HANDOFF LOG:
[all previous entries]
[COMPLETE] content-validator | All content validated and approved - [score]점 | [timestamp]
VALIDATION_SCORE: [90-100]
-->
```

#### Below 90 Points (Improvement Needed - Pipeline Restarts from First Problematic Agent)

```markdown
<!--
CURRENT_AGENT: [first_improvement_target_agent]
STATUS: IN_PROGRESS
STARTED: [original-time]
UPDATED: [YYYY-MM-DD HH:MM]
HANDOFF LOG:
[all previous entries]
[DONE] content-validator | 검증 완료 - [score]점 (개선 필요) | [timestamp]
VALIDATION_SCORE: [0-89]
IMPROVEMENT_NEEDED:
  - [agent-name]: [specific improvement description] (-[points]점)
  - [agent-name]: [specific improvement description] (-[points]점)
  ...
-->
```

### Content Guarantees
- VALIDATION_SCORE is set (integer 0-100)
- If score < 90: IMPROVEMENT_NEEDED field is created with specific, actionable feedback
- If score >= 90: Pipeline completes, STATUS set to COMPLETED, CURRENT_AGENT cleared
- Validation report is generated (not stored in file, for logging only)

## Preconditions

1. CURRENT_AGENT == "content-validator"
2. STATUS == IN_PROGRESS
3. All required sections exist: Overview, Core Concepts, Code Patterns, Experiments, Quiz
4. HANDOFF LOG contains [DONE] quiz-writer entry

## Postconditions

### Score 90-100 (Pipeline Complete)
1. STATUS == COMPLETED
2. CURRENT_AGENT == "" (empty string - signals pipeline completion)
3. HANDOFF LOG contains [COMPLETE] entry
4. VALIDATION_SCORE is set (90-100)
5. NO IMPROVEMENT_NEEDED field (pipeline terminates successfully)

### Score Below 90 (Improvement Cycle)
1. STATUS == IN_PROGRESS (unchanged)
2. CURRENT_AGENT == [first agent in IMPROVEMENT_NEEDED list]
3. HANDOFF LOG contains [DONE] content-validator entry with score
4. VALIDATION_SCORE is set (0-89)
5. IMPROVEMENT_NEEDED field is created with 1+ improvement items
6. Each improvement item specifies agent, description, and point deduction

## Error Handling

### Precondition 실패 시
- **Missing required sections**: Fail-Fast strategy
  - Output error message: "Precondition failed: Required section(s) missing: {section_names}"
  - Add [FAILURE] entry: `[FAILURE] content-validator | Missing required sections: {list} | [timestamp]`
  - Set STATUS: FAILED
  - Preserve CURRENT_AGENT as content-validator
  - Terminate execution

- **CURRENT_AGENT mismatch**: Fail-Fast strategy
  - Output error message: "Precondition failed: CURRENT_AGENT is {actual}, expected 'content-validator'"
  - Add [FAILURE] entry to HANDOFF LOG
  - Set STATUS: FAILED
  - Terminate execution

- **Missing [DONE] quiz-writer**: Fail-Fast strategy
  - Output error message: "Precondition failed: No [DONE] quiz-writer entry in HANDOFF LOG"
  - Add [FAILURE] entry
  - Set STATUS: FAILED
  - Terminate execution

### 작업 중 오류 시
- **Validation process failure**:
  - Add [FAILURE] entry: `[FAILURE] content-validator | Validation process failed: {error_details} | [timestamp]`
  - Set STATUS: FAILED
  - Terminate execution

## Validation Criteria

### Scoring Breakdown

| Section | Points | Sub-criteria |
|---------|--------|--------------|
| **Overview** | 20 | Clear topic definition (5), Learning motivation (5), Key features specified (5), Practical application (5) |
| **Core Concepts** | 25 | Concept selection (5), Easy explanations (5), Normal explanations (5), Expert explanations (5), Visualization completeness (5) |
| **Code Patterns** | 20 | Pattern selection (5), Short/Full code distinction (5), Code executability (5), Explanation thoroughness (5) |
| **Experiments** | 15 | Practice goal clarity (5), Step-by-step instructions (5), Code completeness - no TODOs (5) |
| **Quiz** | 20 | Question type diversity (5), Difficulty distribution balance (5), Answer accuracy (5), Appropriate question count 8-12 (5) |
| **Total** | **100** | |

### Detailed Evaluation Criteria

#### Overview Section (20 points)
- **Clear topic definition** (5 points):
  - Introduction clearly defines the concept
  - Technical terms explained on first use
  - 0-2 pts: Vague or missing definition
  - 3-4 pts: Basic definition provided
  - 5 pts: Clear, comprehensive definition

- **Learning motivation** (5 points):
  - Explains why topic matters
  - Connects to real-world problems
  - 0-2 pts: No motivation provided
  - 3-4 pts: Generic motivation
  - 5 pts: Compelling, specific motivation

- **Key features specified** (5 points):
  - 4-5 bullet points present
  - Features are technically accurate
  - 0-2 pts: < 3 items or inaccurate
  - 3-4 pts: 3-4 items, mostly accurate
  - 5 pts: 4-5 items, all accurate

- **Practical application** (5 points):
  - 4-6 sentences explaining real impact
  - Concrete use cases provided
  - 0-2 pts: Missing or too generic
  - 3-4 pts: Present but lacks specifics
  - 5 pts: Detailed with concrete examples

#### Core Concepts Section (25 points)
- **Concept selection** (5 points):
  - 3-5 concepts chosen
  - Directly address topic's core mechanisms
  - 0-2 pts: < 3 concepts or off-topic
  - 3-4 pts: 3-5 concepts, somewhat relevant
  - 5 pts: 3-5 concepts, all highly relevant

- **Easy explanations** (5 points):
  - Middle school level understanding
  - Everyday analogies used
  - Emojis present
  - NO code examples
  - 0-2 pts: Too technical or has code
  - 3-4 pts: Mostly accessible, minor issues
  - 5 pts: Perfect for target audience

- **Normal explanations** (5 points):
  - #### Text and #### Code: alternating structure
  - Technical terms used appropriately
  - Code is executable (3-8 lines per block)
  - 0-2 pts: Missing structure or non-executable code
  - 3-4 pts: Structure present, minor code issues
  - 5 pts: Perfect structure and executable code

- **Expert explanations** (5 points):
  - ECMAScript specification quoted with section numbers
  - Engine implementation details provided
  - Performance impact mentioned
  - 0-2 pts: No specs or performance notes
  - 3-4 pts: Specs mentioned, lacks detail
  - 5 pts: Comprehensive with specs and performance

- **Visualization completeness** (5 points) - **DETAILED VERIFICATION REQUIRED**:
  1. Metadata exists in markdown (1 pt)
  2. Component file exists (1 pt)
  3. **Component file is NOT empty** (1 pt):
     - Use Read tool to verify file content
     - File must be at least 20 lines
     - Must contain "import React" and "export const"
     - Empty file or placeholder only → 0 points
  4. **Export exists in index.ts** (2 pts):
     - Use Grep tool to search for component name in `src/components/visualizations/index.ts`
     - Export missing → 0 points, **deduct 5 additional points**
     - **This is CRITICAL**: Without export, visualization shows "준비중" to users
  5. If no visualization metadata found: 3 pts (acceptable to skip)

#### Code Patterns Section (20 points)
- **Pattern selection** (5 points):
  - 2-4 patterns provided
  - Patterns address practical problems
  - 0-2 pts: < 2 patterns or impractical
  - 3-4 pts: 2-4 patterns, somewhat useful
  - 5 pts: 2-4 patterns, highly practical

- **Short/Full code distinction** (5 points):
  - Short Code: 3-5 lines, core concept only
  - Full Code: 10-20 lines, anti-pattern vs best practice
  - 0-2 pts: No clear distinction
  - 3-4 pts: Distinction exists, length issues
  - 5 pts: Perfect distinction and lengths

- **Code executability** (5 points):
  - All code executes without errors
  - Results verifiable with console.log
  - 0-2 pts: Multiple syntax errors
  - 3-4 pts: Minor errors or missing verification
  - 5 pts: All code executable and verifiable

- **Explanation thoroughness** (5 points):
  - Easy, Normal, Expert paragraphs all present
  - Each provides appropriate level of detail
  - 0-2 pts: Missing levels or too brief
  - 3-4 pts: All levels present, lacks depth
  - 5 pts: Comprehensive at all levels

#### Experiments Section (15 points)
- **Practice goal clarity** (5 points):
  - 1-3 experiments provided
  - Each has clear learning objective
  - 0-2 pts: < 1 experiment or unclear goals
  - 3-4 pts: 1-3 experiments, goals somewhat clear
  - 5 pts: 1-3 experiments, goals crystal clear

- **Step-by-step instructions** (5 points):
  - 5-8 instruction steps per experiment
  - Each step starts with imperative verb
  - Specifies line numbers or variable names
  - Expected results clearly stated
  - 0-2 pts: < 5 steps or too vague
  - 3-4 pts: 5-8 steps, somewhat specific
  - 5 pts: 5-8 steps, highly specific

- **Code completeness** (5 points):
  - Initial Code is 10-25 lines
  - Immediately executable (NO TODOs or empty functions)
  - Modification points marked with comments
  - 0-2 pts: TODOs or non-executable
  - 3-4 pts: Executable but lacks clarity
  - 5 pts: Complete and well-marked

#### Quiz Section (20 points)
- **Question type diversity** (5 points):
  - All 6 types represented (minimum 1 each)
  - Types: multiple-choice, true-false, text-fill-in-blank, fill-in-the-blank, code-review, output-prediction
  - 0-2 pts: < 4 types present
  - 3-4 pts: 4-5 types present
  - 5 pts: All 6 types present

- **Difficulty distribution balance** (5 points):
  - Target: 1-2 (30%), 3 (40%), 4-5 (30%)
  - 0-2 pts: Heavily skewed (> 50% in one range)
  - 3-4 pts: Slightly imbalanced
  - 5 pts: Meets target distribution (±10%)

- **Answer accuracy** (5 points):
  - All Correct Answers are accurate
  - Multiple-choice: Correct Answer matches one Option exactly
  - 0-2 pts: Multiple wrong answers
  - 3-4 pts: 1 wrong answer
  - 5 pts: All answers correct

- **Appropriate question count** (5 points):
  - 8-12 questions total
  - 0-2 pts: < 6 or > 15 questions
  - 3-4 pts: 6-7 or 13-15 questions
  - 5 pts: 8-12 questions

### Grade Interpretation

**Score Ranges**:
- **100 points**: Perfect content 🏆
- **95-99 points**: Excellent - [COMPLETE]
- **90-94 points**: Good - [COMPLETE]
- **85-89 points**: Acceptable ⚠️ (improvement recommended but optional)
- **Below 85 points**: Needs Improvement (improvement required)

**Decision Logic**:
- **Score >= 90**: Pipeline completes successfully
  - Set STATUS: COMPLETED
  - Set CURRENT_AGENT: "" (empty)
  - Add [COMPLETE] to HANDOFF LOG
  - NO IMPROVEMENT_NEEDED field

- **Score < 90**: Improvement cycle begins
  - Keep STATUS: IN_PROGRESS
  - Set CURRENT_AGENT: [first agent in improvement list]
  - Add [DONE] content-validator to HANDOFF LOG
  - Create IMPROVEMENT_NEEDED field with actionable items

## Examples

### Example 1: Perfect Score (100점 - Pipeline Complete)

**Input**:
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
[DONE] visualization-writer | VarHoistingVisualization 생성 | 2025-10-17T11:15:00+09:00
[DONE] practice-writer | Practice completed | 2025-10-17T11:45:00+09:00
[DONE] quiz-writer | Quiz completed | 2025-10-17T12:30:00+09:00
-->

# Overview
[Perfect content...]

# Core Concepts
[Perfect content with all 5 criteria met...]

# Code Patterns
[Perfect patterns...]

# Experiments
[Perfect experiments...]

# Quiz
[Perfect 10 questions with all 6 types...]
```

**Output**:
```markdown
<!--
CURRENT_AGENT:
STATUS: COMPLETED
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:00:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts completed | 2025-10-17T10:45:00+09:00
[DONE] visualization-writer | VarHoistingVisualization 생성 | 2025-10-17T11:15:00+09:00
[DONE] practice-writer | Practice completed | 2025-10-17T11:45:00+09:00
[DONE] quiz-writer | Quiz completed | 2025-10-17T12:30:00+09:00
[COMPLETE] content-validator | All content validated and approved - 100점 | 2025-10-17T13:00:00+09:00
VALIDATION_SCORE: 100
-->
```

**Validation Report** (logged, not in file):
```
## 📊 Content Quality Validation Report

### File Information
- File: var-problems.md
- Topic: var 키워드의 문제점
- Validation Time: 2025-10-17T13:00:00+09:00

### 📈 Semantic Validation
| Section | Score | Evaluation |
|---------|-------|------------|
| Overview | 20/20 | Perfect |
| Concepts | 25/25 | Perfect (visualization verified) |
| Patterns | 20/20 | Perfect |
| Experiments | 15/15 | Perfect |
| Quiz | 20/20 | Perfect |

### 🎯 Overall Evaluation
- Total Score: 100/100
- Grade: Perfect 🏆
- Decision: [COMPLETE] - Pipeline terminated successfully
```

### Example 2: Good Score (92점 - Pipeline Complete)

**Input**: [Content with minor issues]

**Output**:
```markdown
<!--
CURRENT_AGENT:
STATUS: COMPLETED
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:00:00+09:00
HANDOFF LOG:
[Previous entries...]
[COMPLETE] content-validator | All content validated and approved - 92점 | 2025-10-17T13:00:00+09:00
VALIDATION_SCORE: 92
-->
```

**Note**: Score >= 90 completes the pipeline even with minor issues.

### Example 3: Improvement Needed (87점)

**Input**: [Content with several issues]

**Output**:
```markdown
<!--
CURRENT_AGENT: concepts-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:00:00+09:00
HANDOFF LOG:
[Previous entries...]
[DONE] content-validator | 검증 완료 - 87점 (개선 필요) | 2025-10-17T13:00:00+09:00
VALIDATION_SCORE: 87
IMPROVEMENT_NEEDED:
  - concepts-writer: Add ECMAScript spec quotes to Expert sections (-8점)
  - practice-writer: Fix non-executable code in Pattern 2 (-5점)
-->
```

**Validation Report** (logged):
```
## 📊 Content Quality Validation Report

### 📈 Semantic Validation
| Section | Score | Evaluation |
|---------|-------|------------|
| Overview | 18/20 | Missing concrete use cases |
| Concepts | 17/25 | Expert sections lack spec quotes |
| Patterns | 15/20 | Pattern 2 code has syntax errors |
| Experiments | 14/15 | Minor instruction clarity issues |
| Quiz | 23/20 | Excellent |

### 🎯 Overall Evaluation
- Total Score: 87/100
- Grade: Acceptable ⚠️
- Decision: Improvement cycle initiated

### 💡 Improvement Recommendations (IMPROVEMENT_NEEDED)
1. concepts-writer: Add ECMAScript spec quotes to Expert sections (-8점)
2. practice-writer: Fix non-executable code in Pattern 2 (-5점)
```

**Work Status Markers Update**:
- CURRENT_AGENT: → concepts-writer (first in improvement list)
- STATUS: IN_PROGRESS (unchanged)
- VALIDATION_SCORE: 87 added
- IMPROVEMENT_NEEDED: Created with 2 items
- HANDOFF LOG: [DONE] entry added

### Example 4: Major Revision Needed (78점)

**Input**: [Content with significant issues]

**Output**:
```markdown
<!--
CURRENT_AGENT: overview-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:00:00+09:00
HANDOFF LOG:
[Previous entries...]
[DONE] content-validator | 검증 완료 - 78점 (개선 필요) | 2025-10-17T13:00:00+09:00
VALIDATION_SCORE: 78
IMPROVEMENT_NEEDED:
  - overview-writer: Rewrite learning motivation section (-10점)
  - concepts-writer: Complete revision of Easy explanations - add more everyday analogies (-6점)
  - visualization-writer: Component file is empty - must create actual implementation (-5점 추가 감점 포함)
  - quiz-writer: Add 3 more questions to reach minimum 8 (-7점)
-->
```

## Implementation

### Work Status Markers 업데이트 방법

Refer to `docs/aidlc-docs/construction/unit-02-filter-contracts/domain_design.md` Section 2.1.3.

**Score 90-100 (Pipeline Complete)**:
- Pattern: "content-validator 특수 케이스 (90-100점)"
- Set CURRENT_AGENT to "" (empty string)
- Set STATUS to COMPLETED
- Update UPDATED timestamp
- Add [COMPLETE] entry to HANDOFF LOG with score
- Set VALIDATION_SCORE field
- NO IMPROVEMENT_NEEDED field

**Score < 90 (Improvement Cycle)**:
- Pattern: "content-validator 특수 케이스 (90점 미만)"
- Set CURRENT_AGENT to first agent in IMPROVEMENT_NEEDED list
- STATUS remains IN_PROGRESS
- Update UPDATED timestamp
- Add [DONE] entry to HANDOFF LOG with score
- Set VALIDATION_SCORE field
- Create IMPROVEMENT_NEEDED field with specific items

### Validation Process Workflow

1. **Read all sections** from the markdown file
2. **Score each section** according to criteria (0-100 total)
3. **Generate validation report** (for logging)
4. **Determine grade** based on total score
5. **Update Work Status Markers**:
   - If score >= 90: Complete pipeline
   - If score < 90: Create improvement directives
6. **Output validation report** (to console/logs, not in file)

### Improvement Item Format

Each item in IMPROVEMENT_NEEDED must include:
- **Agent name**: Which agent should handle the improvement
- **Specific description**: Exact problem and expected fix
- **Point deduction**: How many points were lost

**Format**: `- [agent-name]: [specific description] (-[points]점)`

**Example**:
```yaml
IMPROVEMENT_NEEDED:
  - concepts-writer: Add ECMAScript spec quotes to Expert sections (-8점)
  - practice-writer: Fix syntax error in Pattern 2 Full Code (-5점)
  - quiz-writer: Add 2 more difficulty 1-2 questions (-7점)
```

### Verification Tools Usage

**For Visualization Verification** (most critical):
```typescript
// 1. Check component file exists and is not empty
Read tool → src/components/visualizations/[category]/[ComponentName].tsx
// Verify: >= 20 lines, contains "import React", "export const"

// 2. Check export exists in index.ts (CRITICAL)
Grep tool → search for component name in src/components/visualizations/index.ts
// If missing: -5 additional points + deduct visualization points
```

### Scoring Strategy

**Objective Assessment**:
- Use checklist-based evaluation to minimize subjectivity
- Each criterion has clear 0-2-3-4-5 point scale
- Document specific reasons for point deductions

**Constructive Feedback**:
- IMPROVEMENT_NEEDED items must be specific and actionable
- Focus on highest-impact improvements first
- Prioritize items with larger point deductions

**Efficient Improvement**:
- List agents in order of priority (most critical first)
- CURRENT_AGENT is set to first agent in list
- Agents process improvements sequentially

### Quality Assurance

**Content Validator Role**:
- Measures quality objectively
- Does NOT fix issues (improvement agents do that)
- Does NOT decide retry logic (orchestration script does that)
- ONLY: Score + Generate improvement directives (if needed)

**Orchestration Script Role**:
- Reads VALIDATION_SCORE and STATUS
- If STATUS == COMPLETED: Stop pipeline
- If STATUS == IN_PROGRESS: Restart from CURRENT_AGENT
- Handles retry limits and failure thresholds
