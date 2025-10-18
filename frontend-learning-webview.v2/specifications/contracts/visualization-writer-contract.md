---
agent_id: visualization-writer
version: 1.0
dependencies: [concepts-writer]
bounded_context: Visualization Component Generation
---

# Agent Contract: Visualization Writer

## Responsibility

Create React visualization components based on Visualization metadata in Core Concepts section and export them to index.ts.

## Input Contract

### File State
- Required Files: Target markdown file
- File Encoding: UTF-8
- Frontmatter: Required (populated by content-initiator)
- Existing Sections:
  - Work Status Markers
  - `# Overview` section
  - `# Core Concepts` section (with Visualization metadata)

### Work Status Markers
- CURRENT_AGENT: visualization-writer
- STATUS: IN_PROGRESS
- HANDOFF LOG: Contains [DONE] concepts-writer entry

### Section Dependencies
- Core Concepts section (read-only, extract Visualization metadata from each Concept)

## Output Contract

### File State
- Modified Files:
  - Target markdown file (Work Status Markers update only)
  - React component file: `src/components/visualizations/[category]/[ComponentName].tsx`
  - Index file: `src/components/visualizations/index.ts`

- New Sections in Markdown: None (this agent only updates Work Status Markers)

- Component File Structure:
  ```typescript
  import React, { useState } from 'react';

  interface ComponentNameProps {
    data?: any;
    isFullScreen?: boolean;
  }

  export const ComponentName: React.FC<ComponentNameProps> = ({ data }) => {
    // State management
    const [state, setState] = useState(initialValue);

    // Rendering with HTML/CSS-based styles
    return (
      <div style={{ /* inline styles */ }}>
        {/* Visualization content */}
      </div>
    );
  };
  ```

### Work Status Markers
- CURRENT_AGENT: practice-writer
- STATUS: IN_PROGRESS (unchanged)
- UPDATED: Current timestamp (ISO 8601 format)
- HANDOFF LOG:
  - Preserve all existing entries
  - Add: `[DONE] visualization-writer | [ComponentName] 생성 | [timestamp]`
  - OR: `[SKIP] visualization-writer | No visualization needed | [timestamp]` (if no visualization metadata found)

### Content Guarantees
- **React component file is created and NOT empty** (minimum 20 lines)
- Component contains:
  - `import React` statement
  - Props interface definition (`ComponentNameProps`)
  - `export const ComponentName` with actual JSX rendering
- **index.ts contains export statement for the component** (CRITICAL)
- No TypeScript compilation errors
- Component follows HTML/CSS-based style patterns (minimize SVG usage)

## Preconditions

1. CURRENT_AGENT == "visualization-writer"
2. STATUS == IN_PROGRESS
3. `# Core Concepts` section exists in the markdown file
4. At least one Visualization metadata block exists in Core Concepts
5. HANDOFF LOG contains [DONE] concepts-writer entry

## Postconditions

1. React component file(s) created in appropriate category subdirectory
2. **index.ts updated with export statement(s)** (CRITICAL - without this, UI shows "준비중" fallback)
3. Component file is NOT empty (verified with Read tool, minimum 20 lines)
4. Export exists in index.ts (verified with Grep tool)
5. CURRENT_AGENT == "practice-writer"
6. STATUS == IN_PROGRESS (unchanged)
7. HANDOFF LOG contains [DONE] visualization-writer entry with component name(s)
8. (Improvement mode only) IMPROVEMENT_NEEDED field no longer contains visualization-writer entry

## Error Handling

### Precondition 실패 시
- **No Visualization metadata found**: NOT a failure, proceed with [SKIP]
  - Output message: "No visualization metadata found. Skipping visualization generation."
  - Add [SKIP] entry: `[SKIP] visualization-writer | No visualization needed | [timestamp]`
  - Update CURRENT_AGENT to practice-writer
  - Continue pipeline (NOT a failure)

- **CURRENT_AGENT mismatch**: Fail-Fast strategy
  - Output error message: "Precondition failed: CURRENT_AGENT is {actual}, expected 'visualization-writer'"
  - Add [FAILURE] entry to HANDOFF LOG
  - Set STATUS: FAILED
  - Terminate execution

- **Core Concepts section missing**: Fail-Fast strategy
  - Output error message: "Precondition failed: Core Concepts section does not exist"
  - Add [FAILURE] entry
  - Set STATUS: FAILED
  - Terminate execution

### 작업 중 오류 시
- **Component file creation failure**:
  - Add [FAILURE] entry: `[FAILURE] visualization-writer | Component creation failed: {error_details} | [timestamp]`
  - Set STATUS: FAILED
  - Preserve partial work for debugging
  - Terminate execution

- **index.ts update failure** (CRITICAL):
  - Add [FAILURE] entry: `[FAILURE] visualization-writer | index.ts export update failed: {error_details} | [timestamp]`
  - Set STATUS: FAILED
  - This is the MOST CRITICAL failure - without export, component is unusable
  - Terminate execution

- **TypeScript compilation errors**:
  - Add [FAILURE] entry: `[FAILURE] visualization-writer | TypeScript errors in component | [timestamp]`
  - Set STATUS: FAILED
  - Include error details in HANDOFF LOG
  - Terminate execution

## Examples

### Example 1: Normal Flow (컴포넌트 생성)

**Input**:
```markdown
---
id: var-problems
title: var 키워드의 문제점
---

<!--
CURRENT_AGENT: visualization-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T10:45:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts completed | 2025-10-17T10:45:00+09:00
-->

# Core Concepts

## Concept: 호이스팅

**ID**: var-hoisting

[Easy, Normal, Expert sections...]

### Visualization

component: VarHoistingVisualization
type: interactive
data: {
  showMemory: true,
  showSteps: true
}
```

**Output (Work Status Markers)**:
```markdown
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
```

**Created Files**:

1. `src/components/visualizations/variables/VarHoistingVisualization.tsx`:
```typescript
import React, { useState } from 'react';

interface VarHoistingVisualizationProps {
  data?: {
    showMemory?: boolean;
    showSteps?: boolean;
  };
  isFullScreen?: boolean;
}

export const VarHoistingVisualization: React.FC<VarHoistingVisualizationProps> = ({
  data = { showMemory: true, showSteps: true }
}) => {
  const [currentStep, setCurrentStep] = useState(0);

  const steps = [
    { phase: 'Creation Phase', code: 'var name', memory: { name: undefined } },
    { phase: 'Execution Phase', code: 'console.log(name)', memory: { name: undefined } },
    { phase: 'Assignment Phase', code: 'name = "Alice"', memory: { name: 'Alice' } },
  ];

  return (
    <div style={{
      backgroundColor: '#f8fafc',
      border: '1px solid #e2e8f0',
      borderRadius: '12px',
      padding: '24px',
      marginTop: '16px'
    }}>
      <h3 style={{
        fontSize: '18px',
        fontWeight: '600',
        color: '#1e293b',
        marginBottom: '16px',
        textAlign: 'center'
      }}>
        var 호이스팅 시각화
      </h3>

      {data.showSteps && (
        <div style={{ marginBottom: '16px' }}>
          <div style={{
            display: 'flex',
            gap: '8px',
            justifyContent: 'center'
          }}>
            {steps.map((step, index) => (
              <button
                key={index}
                onClick={() => setCurrentStep(index)}
                style={{
                  padding: '8px 16px',
                  borderRadius: '6px',
                  border: currentStep === index ? '2px solid #3b82f6' : '2px solid #e2e8f0',
                  backgroundColor: currentStep === index ? '#eff6ff' : '#fff',
                  color: currentStep === index ? '#2563eb' : '#64748b',
                  cursor: 'pointer',
                  fontWeight: '500'
                }}
              >
                {step.phase}
              </button>
            ))}
          </div>
        </div>
      )}

      <div style={{
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: '16px'
      }}>
        <div style={{
          backgroundColor: '#1f2937',
          borderRadius: '6px',
          padding: '12px',
          fontFamily: 'Monaco, Menlo, monospace',
          fontSize: '12px',
          color: '#e5e7eb',
          lineHeight: '1.6'
        }}>
          <div style={{ color: '#9ca3af', marginBottom: '8px' }}>코드:</div>
          <div style={{ color: '#34d399' }}>{steps[currentStep].code}</div>
        </div>

        {data.showMemory && (
          <div style={{
            backgroundColor: '#fef3c7',
            borderRadius: '6px',
            padding: '12px'
          }}>
            <div style={{
              fontWeight: '600',
              marginBottom: '8px',
              color: '#92400e'
            }}>
              메모리 상태:
            </div>
            <div style={{
              backgroundColor: '#fff',
              padding: '8px',
              borderRadius: '4px',
              fontFamily: 'Monaco, Menlo, monospace',
              fontSize: '12px'
            }}>
              name: {JSON.stringify(steps[currentStep].memory.name)}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
```

2. `src/components/visualizations/index.ts` (export added at end):
```typescript
// ... existing exports ...
export { VarHoistingVisualization } from './variables/VarHoistingVisualization';
```

**Verification**:
- Read tool confirms component file has 80+ lines
- Grep tool confirms export exists in index.ts

### Example 2: Skip Flow (Visualization 메타데이터 없음)

**Input**:
```markdown
<!--
CURRENT_AGENT: visualization-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T10:45:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts completed | 2025-10-17T10:45:00+09:00
-->

# Core Concepts

## Concept: 변수 선언

**ID**: variable-declaration

### Easy
[Content without Visualization section...]

### Normal
[Content...]

### Expert
[Content...]

(No ### Visualization section)
```

**Output**:
```markdown
<!--
CURRENT_AGENT: practice-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T10:46:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts completed | 2025-10-17T10:45:00+09:00
[SKIP] visualization-writer | No visualization needed | 2025-10-17T10:46:00+09:00
-->
```

**No Files Created**: Pipeline continues to practice-writer

### Example 3: Improvement Mode (컴포넌트 인터랙션 개선)

**Input**:
```markdown
<!--
CURRENT_AGENT: visualization-writer
STATUS: IN_PROGRESS
VALIDATION_SCORE: 91/100
IMPROVEMENT_NEEDED:
  - visualization-writer: Add reset button to VarHoistingVisualization (-4점)
  - quiz-writer: Add one more difficulty 5 question (-5점)
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:00:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts completed | 2025-10-17T10:45:00+09:00
[DONE] visualization-writer | VarHoistingVisualization 생성 | 2025-10-17T11:15:00+09:00
[DONE] practice-writer | Practice completed | 2025-10-17T11:45:00+09:00
[DONE] quiz-writer | Quiz completed | 2025-10-17T12:30:00+09:00
[DONE] content-validator | Validation completed - 91점 (개선 필요)
-->
```

**Output**:
```markdown
<!--
CURRENT_AGENT: quiz-writer
STATUS: IN_PROGRESS
VALIDATION_SCORE: 91/100
IMPROVEMENT_NEEDED:
  - quiz-writer: Add one more difficulty 5 question (-5점)
STARTED: 2025-10-17T10:00:00+09:00
UPDATED: 2025-10-17T13:10:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
[DONE] overview-writer | Overview completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core concepts completed | 2025-10-17T10:45:00+09:00
[DONE] visualization-writer | VarHoistingVisualization 생성 | 2025-10-17T11:15:00+09:00
[DONE] practice-writer | Practice completed | 2025-10-17T11:45:00+09:00
[DONE] quiz-writer | Quiz completed | 2025-10-17T12:30:00+09:00
[DONE] content-validator | Validation completed - 91점 (개선 필요)
[IMPROVE] visualization-writer | Added reset button to VarHoistingVisualization | 2025-10-17T13:10:00+09:00
-->
```

**Modified File**: `src/components/visualizations/variables/VarHoistingVisualization.tsx`
- Added reset button with `setCurrentStep(0)` onClick handler
- No changes to index.ts (export already exists)

## Implementation

### Work Status Markers 업데이트 방법

Refer to `docs/aidlc-docs/construction/unit-02-filter-contracts/domain_design.md` Section 2.1.3 "Implementation References" for detailed patterns.

**Normal Flow (정상 완료 시)**:
- Pattern: "모든 에이전트 (content-initiator 제외)"
- Update CURRENT_AGENT to practice-writer
- STATUS remains IN_PROGRESS
- Update UPDATED timestamp
- Add [DONE] entry with component name(s) to HANDOFF LOG

**Skip Flow (Visualization 메타데이터 없음)**:
- Pattern: Similar to normal flow but with [SKIP] event
- Update CURRENT_AGENT to practice-writer
- STATUS remains IN_PROGRESS
- Update UPDATED timestamp
- Add [SKIP] entry to HANDOFF LOG
- This is NOT a failure - pipeline continues normally

**Improvement Mode (개선 모드)**:
- Pattern: "개선 모드 감지 및 처리"
- Detect IMPROVEMENT_NEEDED field with visualization-writer entry
- Modify component file(s) as specified
- Remove visualization-writer entry from IMPROVEMENT_NEEDED
- Update CURRENT_AGENT to next agent requiring improvement
- Add [IMPROVE] entry to HANDOFF LOG

### Component File Location

Determine subdirectory based on topic category:

```
src/components/visualizations/
├── variables/       (변수 관련)
├── functions/       (함수 관련)
├── async/          (비동기 관련)
├── objects/        (객체 관련)
├── scope/          (스코프 관련)
├── types/          (타입 관련)
└── [category]/     (기타 카테고리)
```

Extract category from frontmatter or file path.

### Component Naming Convention

Follow `[CoreConcept]Visualization` pattern:
- Component name from metadata: `component: VarHoistingVisualization`
- File name matches component name: `VarHoistingVisualization.tsx`
- PascalCase required

### HTML/CSS Style Guide

**Container Styles**:
```javascript
style={{
  backgroundColor: '#f8fafc',
  border: '1px solid #e2e8f0',
  borderRadius: '12px',
  padding: '24px',
  marginTop: '16px'
}}
```

**Title Styles**:
```javascript
style={{
  fontSize: '18px',
  fontWeight: '600',
  color: '#1e293b',
  marginBottom: '16px',
  textAlign: 'center'
}}
```

**Button Styles**:
```javascript
style={{
  padding: '8px 16px',
  borderRadius: '6px',
  border: '2px solid #3b82f6',
  backgroundColor: '#eff6ff',
  color: '#2563eb',
  cursor: 'pointer',
  fontWeight: '500'
}}
```

**Code Display Area**:
```javascript
style={{
  backgroundColor: '#1f2937',
  borderRadius: '6px',
  padding: '12px',
  fontFamily: 'Monaco, Menlo, monospace',
  fontSize: '12px',
  lineHeight: '1.6',
  color: '#e5e7eb',
  whiteSpace: 'pre-wrap'
}}
```

### Interactive Features Patterns

**Step-by-step Progression**:
```javascript
const [currentStep, setCurrentStep] = useState(0);
const steps = [/* step data */];

const nextStep = () => setCurrentStep(prev =>
  Math.min(prev + 1, steps.length - 1)
);

const prevStep = () => setCurrentStep(prev =>
  Math.max(prev - 1, 0)
);
```

**Tab Switching**:
```javascript
const [selectedTab, setSelectedTab] = useState('tab1');
```

**Hover Effects**:
```javascript
const [hoveredItem, setHoveredItem] = useState<string | null>(null);
```

### Visualization Type Implementation

**Interactive** (`type: interactive`):
- User can click buttons, change tabs, or interact with UI
- State management with useState
- Event handlers (onClick, onMouseEnter, etc.)

**Static** (`type: static`):
- No state changes
- Pure display of information
- Diagrams, comparison tables

**Animation** (`type: animation`):
- Automatic state transitions
- Use setInterval or setTimeout
- Cleanup with useEffect return

### Critical Requirements Verification

**BEFORE marking as DONE, MUST verify**:

1. **Component file verification**:
```typescript
// Use Read tool to check:
// - File is NOT empty (minimum 20 lines)
// - Contains "import React"
// - Contains interface definition
// - Contains "export const ComponentName"
// - Has actual JSX rendering (not just placeholder)
```

2. **index.ts export verification** (MOST CRITICAL):
```typescript
// Use Grep tool to check:
// - Export statement exists in index.ts
// - Format: export { ComponentName } from './[category]/ComponentName';
// - Without this, UI shows "준비중" instead of visualization
```

**ONLY after both verifications pass**, update HANDOFF LOG to [DONE].

### Quality Standards

**Component Quality**:
- No TypeScript compilation errors
- Follow React hooks rules (hooks only in function body)
- Props interface defined
- Handle default values for data prop
- Responsive layout considerations

**Style Consistency**:
- Maintain consistency with existing components
- Use inline styles (avoid external CSS)
- Appropriate color contrast for accessibility
- Readable font sizes (minimum 12px)

**Feature Completeness**:
- Interactive features work properly
- UI updates correctly on state changes
- Handle edge cases (empty data, invalid values)
- Performance optimization (prevent unnecessary re-renders)

### Reference Existing Components

Before creating new components, analyze similar visualizations:
- Check `/src/components/visualizations/` subdirectories
- Prioritize HTML/CSS-based components over SVG
- Maintain style pattern consistency
- Reuse common patterns (step progression, tab switching, etc.)

### Error Prevention

**Common Mistakes to Avoid**:
1. Creating empty component files (minimum 20 lines required)
2. **Forgetting to add export to index.ts** (MOST COMMON FAILURE)
3. Using complex SVG coordinate calculations (prefer HTML/CSS)
4. Not defining props interface
5. Missing default values for data prop
6. Breaking React hooks rules
