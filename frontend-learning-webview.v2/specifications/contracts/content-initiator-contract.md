---
agent_id: content-initiator
version: 1.0
dependencies: []
bounded_context: Content Initialization
---

# Agent Contract: Content Initiator

## Responsibility

Initialize Work Status Markers and populate frontmatter with topic metadata from category.yaml for the content generation pipeline.

## Input Contract

### File State
- Required Files: Target markdown file path (provided by orchestration script)
- File Encoding: UTF-8
- Frontmatter: May exist (created by script with `---\n---\n`) or file is empty
- Existing Sections: None (file is empty or contains only empty frontmatter)

### Category Metadata (from category.yaml)
- topic.id (required) - Topic identifier
- topic.title (required) - Topic title
- topic.description (required) - Topic description
- topic.difficulty (required, 1-5) - Difficulty level
- topic.prerequisites (optional, array) - Prerequisite topics
- topic.estimatedTime (optional, minutes) - Estimated learning time
- category, subcategory (derived from file path) - Category information

### Work Status Markers
- N/A (first execution)
- OR CURRENT_AGENT: content-initiator (restart scenario)

### Section Dependencies
- None

## Output Contract

### File State
- Modified Files: Target markdown file
- New Sections:
  - frontmatter (populated with topic metadata)
  - Work Status Markers (HTML comment block)
- Section Structure:
  ```markdown
  ---
  id: var-problems
  title: var 키워드의 문제점
  description: var의 호이스팅과 스코프 문제 이해
  difficulty: 2
  prerequisites:
    - variables-basics
  estimatedTime: 30
  category: javascript-core-concepts
  subcategory: 01-variables
  # Auto-generated from category.yaml - DO NOT EDIT MANUALLY
  ---

  <!--
  CURRENT_AGENT: overview-writer
  STATUS: PENDING
  STARTED: 2025-10-17T10:00:00+09:00
  UPDATED: 2025-10-17T10:00:00+09:00
  HANDOFF LOG:
  [START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
  -->
  ```

### Work Status Markers
- CURRENT_AGENT: overview-writer
- STATUS: PENDING
- STARTED: Current timestamp (ISO 8601 format)
- UPDATED: Current timestamp (ISO 8601 format)
- HANDOFF LOG:
  - `[START] pipeline | Content generation started | [timestamp]`

### Content Guarantees
- Work Status Markers exist at the top of the file (immediately after frontmatter)
- frontmatter is populated with topic metadata from category.yaml
- frontmatter includes auto-generation comment ("Auto-generated from category.yaml - DO NOT EDIT MANUALLY")
- category.yaml remains the single source of truth for topic metadata
- category and subcategory are derived from file path pattern: `public/content/ko/{category}/{subcategory}/{topic-id}.md`

## Preconditions

1. File path is valid and follows the pattern: `public/content/ko/{category}/{subcategory}/{topic-id}.md`
2. File does not exist OR is empty OR contains only empty frontmatter (`---\n---\n`)
3. (Restart scenario only) CURRENT_AGENT == "content-initiator" in Work Status Markers
4. category.yaml exists and contains metadata for the specified topic ID

## Postconditions

1. Work Status Markers are created at the top of the file
2. frontmatter is populated with all available topic metadata fields
3. CURRENT_AGENT == "overview-writer"
4. STATUS == PENDING
5. HANDOFF LOG contains [START] entry with pipeline initialization event

## Error Handling

### Precondition 실패 시
- **Invalid file path**: Output error message "Invalid file path format. Expected: public/content/ko/{category}/{subcategory}/{topic-id}.md", terminate execution
- **File already contains content**: Output warning message "File already contains content sections. Adding Work Status Markers only.", proceed to add markers without modifying existing content
- **category.yaml not found or topic ID missing**: Output error message "Cannot find topic metadata in category.yaml for ID: {topic-id}", terminate execution

### 작업 중 오류 시
- **File write failure**: Record [FAILURE] entry in HANDOFF LOG with error details, set STATUS: FAILED, terminate execution
- **Invalid metadata format**: Output error message "Invalid metadata format in category.yaml", terminate execution

## Examples

### Example 1: 신규 파일 초기화 및 frontmatter 자동 생성

**Input**:
- File path: `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md`
- category.yaml topic entry:
  ```yaml
  topics:
    - id: var-problems
      title: var 키워드의 문제점
      description: var의 호이스팅과 스코프 문제 이해
      difficulty: 2
      prerequisites:
        - variables-basics
      estimatedTime: 30
  ```
- File content: Empty file or `---\n---\n` (empty frontmatter)

**Output**:
```markdown
---
id: var-problems
title: var 키워드의 문제점
description: var의 호이스팅과 스코프 문제 이해
difficulty: 2
prerequisites:
  - variables-basics
estimatedTime: 30
category: javascript-core-concepts
subcategory: 01-variables
# Auto-generated from category.yaml - DO NOT EDIT MANUALLY
---

<!--
CURRENT_AGENT: overview-writer
STATUS: PENDING
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T10:00:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
-->
```

**Work Status Markers Update**:
- CURRENT_AGENT transitions from N/A → overview-writer
- HANDOFF LOG receives [START] event

### Example 2: 재시작 시나리오 (Pipeline 중단 후 재개)

**Input**:
- File path: `public/content/ko/javascript-core-concepts/01-variables/02-let-const.md`
- Existing file content:
  ```markdown
  ---
  id: let-const
  title: let과 const
  description: 블록 스코프 변수 선언
  difficulty: 2
  ---

  <!--
  CURRENT_AGENT: content-initiator
  STATUS: FAILED
  STARTED: 2025-10-17T09:00:00+09:00
  UPDATED: 2025-10-17T09:05:00+09:00
  HANDOFF LOG:
  [START] pipeline | Content generation started | 2025-10-17T09:00:00+09:00
  [FAILURE] content-initiator | File write error | 2025-10-17T09:05:00+09:00
  -->
  ```

**Output**:
```markdown
---
id: let-const
title: let과 const
description: 블록 스코프 변수 선언
difficulty: 2
category: javascript-core-concepts
subcategory: 01-variables
# Auto-generated from category.yaml - DO NOT EDIT MANUALLY
---

<!--
CURRENT_AGENT: overview-writer
STATUS: PENDING
STARTED: 2025-10-17T09:00:00+09:00
UPDATED: 2025-10-17T10:15:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T09:00:00+09:00
[FAILURE] content-initiator | File write error | 2025-10-17T09:05:00+09:00
[START] pipeline | Restarted after failure | 2025-10-17T10:15:00+09:00
-->
```

**Work Status Markers Update**:
- CURRENT_AGENT: content-initiator → overview-writer
- STATUS: FAILED → PENDING
- UPDATED timestamp refreshed
- HANDOFF LOG receives new [START] event for restart

## Implementation

### Work Status Markers 업데이트 방법

Refer to `docs/aidlc-docs/construction/unit-02-filter-contracts/domain_design.md` Section 2.1.3 "Implementation References" for detailed Work Status Markers update patterns.

**content-initiator 특수 케이스**:
- This is the only agent that does NOT follow the standard handoff pattern
- No previous agent exists (N/A)
- Creates initial HANDOFF LOG with [START] event
- Sets CURRENT_AGENT to next agent (overview-writer) immediately
- STATUS is always PENDING (never IN_PROGRESS for this agent)

### Timestamp Format
- Use ISO 8601 format: `YYYY-MM-DDTHH:MM:SS+09:00`
- Timezone: Asia/Seoul (UTC+09:00)

### File Path Pattern Parsing
```
public/content/ko/{category}/{subcategory}/{topic-id}.md
                  └─────┬────┘ └────┬─────┘  └────┬────┘
                    category    subcategory    topic-id
```

Extract category and subcategory from file path for frontmatter population.

### Frontmatter Population Priority
1. Read topic metadata from category.yaml using topic-id
2. Extract category and subcategory from file path
3. Merge all metadata fields
4. Add auto-generation comment
5. Write to file in YAML format
