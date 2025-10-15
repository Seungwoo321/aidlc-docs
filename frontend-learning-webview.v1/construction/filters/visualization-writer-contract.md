# visualization-writer Contract

**Version**: 1.0.0
**Created**: 2025-10-13
**Status**: Draft

---

## 1. 개요

### Filter 이름
`visualization-writer`

### 역할 및 책임
학습 콘텐츠의 Core Concepts 섹션에 포함된 추상적 개념을 **인터랙티브 시각화 컴포넌트**로 구현하는 역할을 합니다. React TypeScript 컴포넌트를 생성하고, 렌더링 시스템에 통합합니다.

**핵심 책임**:
- Visualization 메타데이터 파싱
- React 컴포넌트 생성 (HTML/CSS 기반)
- index.ts 내보내기 등록 (Critical)
- 인터랙티브 기능 구현
- Work Status Markers 관리

**특수성**:
- 콘텐츠 작성이 아닌 **코드 생성**
- 파서 테스트 없음 (렌더링 로직으로 검증)
- 시각화는 선택적 (SKIP 가능)

### Pipeline에서의 위치
```
category.yaml → ... → concepts-writer → [visualization-writer] → practice-writer → ...
```

- **선행 Filter**: concepts-writer (Core Concepts 섹션 필요)
- **후행 Filter**: practice-writer

---

## 2. 입력 계약 (Input Contract)

### 필수 입력 데이터

#### 2.1 마크다운 파일
- **파일 경로**: `public/content/ko/{category}/{subcategory}/{topic-id}-{topic-name}.md`
- **Work Status Markers**: `CURRENT_AGENT: visualization-writer`, `PROGRESS: 대기중`

#### 2.2 Visualization 메타데이터 섹션
**위치**: Core Concepts 섹션 내부, 각 Concept의 Expert 섹션 이후

**형식**:
```markdown
### Visualization
- component: ComponentName
- type: interactive | static | animation
- data: {
  options (JSON 형식)
}
```

**예시**:
```markdown
### Visualization
- component: VarScopeVisualization
- type: interactive
- data: {}
```

#### 2.3 Concept 내용 (컨텍스트)
- **위치**: 동일한 Concept 내의 Easy/Normal/Expert 섹션
- **목적**: 시각화할 개념 이해
- **사용**: 컴포넌트 설계 및 설명 텍스트 작성

### 선행 조건 (Preconditions)
1. Core Concepts 섹션이 concepts-writer에 의해 작성됨
2. 최소 1개 이상의 `### Visualization` 섹션 존재
3. Work Status Markers에서 `CURRENT_AGENT: visualization-writer`
4. `src/components/visualizations/` 디렉토리 존재
5. `src/components/visualizations/index.ts` 파일 존재

---

## 3. 출력 계약 (Output Contract)

### 생성할 산출물

#### 3.1 React 컴포넌트 파일
**파일 경로**: `src/components/visualizations/{category}/{ComponentName}.tsx`

**카테고리별 디렉토리**:
- `variables/`: 변수 관련
- `functions/`: 함수 관련
- `async/`: 비동기 관련
- `objects/`: 객체 관련
- `content/`: 기타 (기존 컴포넌트 위치)

**컴포넌트 구조**:
```typescript
import React, { useState } from 'react';

interface ComponentNameProps {
  data?: any;
  isFullScreen?: boolean;
}

export const ComponentName: React.FC<ComponentNameProps> = ({ data }) => {
  // State management
  const [state, setState] = useState(initialValue);

  // Rendering
  return (
    <div style={{ /* Container styles */ }}>
      {/* Visualization content */}
    </div>
  );
};
```

**필수 요소**:
- TypeScript 인터페이스 (`ComponentNameProps`)
- `data?` 및 `isFullScreen?` props
- Export statement (`export const ComponentName`)
- HTML/CSS 기반 렌더링 (SVG 최소화)

#### 3.2 Index 파일 내보내기 (CRITICAL)
**파일**: `src/components/visualizations/index.ts`

**추가 형식**:
```typescript
export { ComponentName } from './[category]/ComponentName';
```

**예시**:
```typescript
export { VarScopeVisualization } from './variables/VarScopeVisualization';
```

**중요성**:
- ⚠️ **가장 흔한 실패 원인**
- 누락 시 React 앱에서 컴포넌트 import 실패
- UI에 "준비중" 폴백 표시됨

#### 3.3 마크다운 파일 (변경 없음)
- Visualization 메타데이터는 수정하지 않음
- Work Status Markers만 업데이트

### 출력 형식

#### 3.3.1 컴포넌트 스타일 가이드

**컨테이너 스타일**:
```javascript
style={{
  backgroundColor: '#f8fafc',
  border: '1px solid #e2e8f0',
  borderRadius: '12px',
  padding: '24px',
  marginTop: '16px'
}}
```

**제목 스타일**:
```javascript
style={{
  fontSize: '18px',
  fontWeight: '600',
  color: '#1e293b',
  marginBottom: '16px',
  textAlign: 'center'
}}
```

**버튼 스타일** (인터랙티브):
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

**코드 표시 영역**:
```javascript
style={{
  backgroundColor: '#1f2937',
  borderRadius: '6px',
  padding: '12px',
  fontFamily: 'Monaco, Menlo, monospace',
  fontSize: '12px',
  lineHeight: '1.6',
  whiteSpace: 'pre-wrap'
}}
```

#### 3.3.2 시각화 유형별 패턴

**Memory Diagrams**:
- 스택/힙 영역 구분
- 변수-값 관계 표시
- 참조 화살표 (선택)

**Execution Timeline**:
- 단계별 진행 표시
- 현재 단계 강조
- 이전/다음 버튼

**Comparison Tables**:
- 2-3개 항목 나란히 배치
- 차이점 색상 구분
- 탭 전환 가능

**Code Execution Simulator**:
- 코드와 결과 분리 표시
- 단계별 실행 상태
- 변수 값 변화 추적

### 후행 조건 (Postconditions)
1. TypeScript 컴파일 오류 없음
2. 컴포넌트 파일이 존재하고 비어있지 않음
3. `index.ts`에 export 문 존재
4. Work Status Markers가 practice-writer로 핸드오프됨
5. 시각화가 필요 없는 경우 SKIP 로그 존재

---

## 4. 품질 기준 (Quality Criteria)

### 구조적 요구사항

#### 4.1 TypeScript 타입 안정성
- ✅ Props 인터페이스 정의 (`ComponentNameProps`)
- ✅ `data?` 및 `isFullScreen?` props 포함
- ✅ 타입 에러 없이 컴파일
- ❌ any 타입 남용

#### 4.2 React 패턴 준수
- ✅ Hooks 규칙 준수 (조건문 밖에서 호출)
- ✅ State 관리 적절성
- ✅ Export 문 존재
- ❌ 컴포넌트 외부에서 Hook 호출

#### 4.3 파일 구조
- ✅ 올바른 디렉토리에 위치 (`src/components/visualizations/{category}/`)
- ✅ 파일명과 컴포넌트명 일치 (PascalCase)
- ✅ index.ts에 export 등록
- ❌ 빈 파일 생성

### 내용적 요구사항

#### 4.4 인터랙티브 기능 (type: interactive)
- ✅ 사용자 입력 반응 (버튼 클릭, 탭 전환 등)
- ✅ State 변경 시 UI 업데이트
- ✅ 엣지 케이스 처리
- ❌ 정적 이미지만 표시

#### 4.5 스타일 일관성
- ✅ 기존 컴포넌트와 일관된 색상 팔레트
- ✅ 반응형 레이아웃 고려
- ✅ 적절한 색상 대비 (접근성)
- ✅ 읽기 쉬운 폰트 크기
- ❌ 인라인 스타일 없이 className만 사용 (HTML/CSS 패턴이므로 인라인 허용)

#### 4.6 성능 최적화
- ✅ 불필요한 재렌더링 방지 (useState 적절 사용)
- ✅ 메모리 누수 방지 (useEffect cleanup)
- ❌ 복잡한 SVG 좌표 계산 (HTML/CSS 우선)

### 검증 방법

#### 파서 테스트 없음
- visualization-writer는 콘텐츠가 아닌 **코드 생성**
- 파서 테스트 대상 아님

#### 렌더링 로직 검증
1. **컴파일 검증**:
   ```bash
   npx tsc --noEmit
   ```
   → TypeScript 에러 없어야 함

2. **Import 검증**:
   ```typescript
   import { ComponentName } from '@/components/visualizations';
   ```
   → index.ts에 export 존재 확인

3. **브라우저 검증**:
   - React 앱 실행 후 해당 토픽 페이지 접근
   - "준비중" 폴백 표시되지 않음
   - 시각화 컴포넌트 정상 렌더링
   - 인터랙티브 기능 동작

### 검증 체크리스트
- [ ] TypeScript 컴파일 성공 (no errors)
- [ ] 컴포넌트 파일이 비어있지 않음 (최소 구현 존재)
- [ ] Props 인터페이스 정의됨
- [ ] Export statement 존재
- [ ] index.ts에 export 등록됨 (Critical)
- [ ] HTML/CSS 기반 렌더링 (SVG 최소)
- [ ] 인터랙티브 기능 동작 (type: interactive인 경우)
- [ ] 기존 컴포넌트와 스타일 일관성

---

## 5. 오류 처리 (Error Handling)

### 오류 유형

#### 5.1 입력 오류
**오류**: Visualization 섹션 없음
- **대응**: SKIP 처리, practice-writer로 핸드오프
- **HANDOFF LOG**: `[SKIP] visualization-writer: 건너뛰기 - {timestamp}`

**오류**: Visualization 메타데이터 파싱 실패
- **대응**: 오류 로그 출력, PROGRESS: 진행중 유지
- **메시지 형식**: `Error: Invalid visualization metadata format`

**오류**: CURRENT_AGENT가 visualization-writer 아님
- **대응**: 작업 건너뛰기, 아무 작업 안 함

#### 5.2 생성 오류
**오류**: 컴포넌트 파일 생성 실패
- **대응**: 오류 로그, PROGRESS: 진행중 유지
- **재시도**: 1회

**오류**: index.ts 업데이트 실패
- **대응**:
  - 오류 로그 출력
  - HANDOFF LOG에 실패 기록: `[FAIL] visualization-writer: index.ts 업데이트 실패`
  - PROGRESS: 진행중 유지 (수동 검토 필요)

#### 5.3 품질 오류
**오류**: TypeScript 컴파일 오류
- **대응**:
  - 컴파일 에러 로그 확인
  - 타입 에러 수정
  - 재작성 (최대 1회)

**오류**: 빈 컴포넌트 파일 생성
- **대응**:
  - 최소 구현 추가 (props interface + 기본 JSX)
  - Read tool로 파일 확인 후 재작성

### 재시도 전략
- **재시도 횟수**: 최대 1회
- **재시도 조건**:
  - 일시적 파일 I/O 오류
  - TypeScript 컴파일 에러 (타입 수정 가능 시)
- **재시도 간격**: 즉시

### 실패 시 처리
1. HANDOFF LOG에 실패 사유 기록
2. PROGRESS: 진행중 유지 (완료로 변경 금지)
3. 오케스트레이션 스크립트에 종료 코드 반환
4. 수동 검토 요청

---

## 6. 성능 기준 (Performance Criteria)

### 평균 처리 시간
- **추정 범위**: 5-15분 (LLM 코드 생성 시간)
- **측정 항목**:
  - Visualization 메타데이터 파싱: 1-2분
  - 컴포넌트 설계 및 생성: 3-10분
  - index.ts 업데이트: 1분
  - 검증 (컴파일, 파일 확인): 1-2분

### 출력 크기 범위
- **컴포넌트 파일**: 100-1500줄 (복잡도에 따라 차이)
  - 단순 컴포넌트 (VarScopeVisualization): ~300줄
  - 복잡한 컴포넌트 (MemoryStorageVisualization): ~1300줄
- **index.ts 추가**: 1줄 (`export { ... } from '...';`)

### 리소스 사용량
- **토큰 소비**: 2000-10000 토큰 (컴포넌트 복잡도에 따라)
  - 참고 컴포넌트 읽기: 500-2000 토큰
  - Concept 내용 읽기: 500-1000 토큰
  - 컴포넌트 생성: 1000-7000 토큰
- **API 호출**: 3-10회
  - Read (markdown, 참고 컴포넌트, index.ts): 3-5회
  - Write (컴포넌트 생성): 1회
  - Edit (index.ts 업데이트): 1회
  - Bash (컴파일 검증, 선택): 1-2회
- **메모리**: 중간 (컴포넌트 코드 생성)

---

## 7. Work Status Markers 계약

### 시작 시 확인할 마커

**필수 조건**:
```markdown
<!-- CURRENT_AGENT: visualization-writer -->
<!-- PROGRESS: 대기중 -->
```

**선택 조건 (개선 모드)**:
```markdown
<!-- IMPROVEMENT_NEEDED:
- visualization-writer: Improve component interaction (-4점)
-->
```

### 작업 시작 시 업데이트

```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: visualization-writer -->
<!-- PROGRESS: 진행중 -->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
-->
```

### 완료 시 업데이트

#### 케이스 1: 시각화 생성 완료
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: practice-writer -->
<!-- PROGRESS: 대기중 -->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
[DONE] visualization-writer: 완료 - [ComponentName] 생성
-->
```

**완료 조건**:
- ✅ 컴포넌트 파일 생성됨
- ✅ index.ts에 export 등록됨
- ✅ TypeScript 컴파일 성공
- ✅ Read/Grep으로 파일 확인됨

#### 케이스 2: 시각화 불필요 (SKIP)
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: practice-writer -->
<!-- PROGRESS: 대기중 -->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
[SKIP] visualization-writer: 건너뛰기 - [YYYY-MM-DD HH:MM]
-->
```

**SKIP 조건**:
- Visualization 섹션 없음
- 또는 concepts-writer가 시각화 불필요로 판단

#### 케이스 3: 실패 (수동 검토 필요)
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: visualization-writer -->
<!-- PROGRESS: 진행중 -->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
[FAIL] visualization-writer: index.ts 업데이트 실패 - [YYYY-MM-DD HH:MM]
-->
```

**실패 조건**:
- 컴포넌트 생성 실패 (재시도 후에도)
- index.ts 업데이트 실패
- TypeScript 컴파일 오류 (수정 불가)

### 개선 모드 처리

**개선 항목 확인**:
```markdown
<!-- IMPROVEMENT_NEEDED:
- visualization-writer: Improve component interaction (-4점)
-->
```

**개선 완료 후**:
- IMPROVEMENT_NEEDED에서 해당 항목 제거
- HANDOFF LOG에 개선 완료 기록:
  ```
  [IMPROVE] visualization-writer: 개선 완료 - component interaction improved
  ```

---

## 8. 의존성

### 선행 Filter
- **concepts-writer**: Core Concepts 섹션 생성 (Visualization 메타데이터 포함)

**의존 데이터**:
- Concept 제목 및 설명 (컨텍스트)
- Visualization 메타데이터 (component, type, data)

### 후속 Filter
- **practice-writer**: Practice 섹션 생성

**제공 데이터**:
- 생성된 시각화 컴포넌트 (간접적, 렌더링 시스템 통합)
- 마크다운 파일 (변경 없음, Work Status Markers만 업데이트)

### 외부 의존성
1. **React 렌더링 시스템**:
   - `src/components/visualizations/index.ts` (중앙 export)
   - React 앱의 시각화 렌더링 로직

2. **기존 컴포넌트 (참고)**:
   - `src/components/visualizations/variables/VarScopeVisualization.tsx`
   - `src/components/visualizations/variables/MemoryStorageVisualization.tsx`
   - 기타 스타일 패턴 참고용

3. **TypeScript 컴파일러**:
   - `tsconfig.json` 설정
   - 타입 검증

---

## 9. 특수 고려사항

### 9.1 시각화의 선택성
- 모든 Concept이 시각화를 필요로 하지 않음
- concepts-writer가 Visualization 섹션을 생략할 수 있음
- visualization-writer는 SKIP 처리 가능

### 9.2 HTML/CSS 우선 원칙
- SVG 사용 최소화 (좌표 계산 복잡도 때문)
- 인라인 스타일 적극 활용
- `style={{ }}` 패턴 사용

**이유**:
- LLM이 SVG 좌표 계산에 약함
- HTML/CSS는 레이아웃 엔진이 자동 계산
- 유지보수 용이

### 9.3 컴포넌트 재사용성
- `data` prop으로 설정 가능하게 설계 (현재는 주로 `{}`)
- `isFullScreen` prop 지원 (전체화면 모드)
- 다양한 토픽에서 재사용 가능하도록 범용성 고려

### 9.4 크리티컬 실패 포인트
⚠️ **가장 흔한 실패**: index.ts 내보내기 누락
- 컴포넌트 생성 후 **반드시** index.ts 업데이트
- Edit tool로 파일 끝에 export 문 추가
- Grep tool로 검증:
  ```bash
  grep "export { ComponentName }" src/components/visualizations/index.ts
  ```

### 9.5 UTF-8 인코딩
- 한글 주석 및 설명 사용 시 UTF-8 인코딩 필수
- Write tool 사용 시 자동 처리됨

---

## 10. 분석 근거 (Analysis Evidence)

### 프롬프트 파일 분석

**참고 파일**: `.claude/agents/visualization-writer.md`

#### 핵심 미션 (line 8-12)
```markdown
You are a specialist developer creating interactive visualization components for JavaScript learning content.

## Core Mission
Autonomously create visualization components by checking Work Status Markers.
```

→ **추출**: 역할이 명확함 (시각화 컴포넌트 개발자), Work Status Markers 기반 자율 작동

#### Visualization 메타데이터 파싱 (line 42-52)
```markdown
### 1. Parse Visualization Metadata
Find the ### Visualization section in the Markdown file:
```markdown
### Visualization
component: ComponentName
type: interactive/static/animation
data: {
  options
}
```
```

→ **추출**: 입력 형식 명확 (component, type, data 3개 필드)

#### 컴포넌트 구조 (line 74-93)
```typescript
import React, { useState } from 'react';

interface ComponentNameProps {
  data?: any;
  isFullScreen?: boolean;
}

export const ComponentName: React.FC<ComponentNameProps> = ({ data }) => {
  // State management
  const [state, setState] = useState(initialValue);

  // Rendering
  return (
    <div style={{ /* HTML/CSS-based styles */ }}>
      {/* Visualization content */}
    </div>
  );
};
```

→ **추출**: 출력 형식 (TypeScript, Props interface, HTML/CSS 기반)

#### 스타일 가이드 (line 95-143)
→ **추출**: 컨테이너, 제목, 버튼, 코드 영역 스타일 명세

#### Critical Requirements (line 216-237)
```markdown
⚠️ **You MUST complete ALL of the following before updating HANDOFF LOG to "완료"**

### 1. Component File Creation
- Create fully functional React component (NOT an empty file)

### 2. Index Export (CRITICAL - Most Common Failure Point)
- **MUST add export to** `src/components/visualizations/index.ts`
- **Why critical**: Without this export, the React app cannot import your component
- **Result of missing export**: App shows "준비중" fallback UI instead of visualization

### 3. Verification Before Handoff
- Use Read tool to confirm component file is not empty
- Use Grep tool to confirm export exists in index.ts
```

→ **추출**:
- 완료 조건 (컴포넌트 생성 + index.ts export + 검증)
- 가장 흔한 실패: index.ts 누락
- 검증 방법 (Read, Grep tools)

#### Handoff Rules (line 278-338)
→ **추출**: Work Status Markers 업데이트 패턴 (완료/SKIP/실패)

### 산출물 샘플 분석

**참고 파일**: `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md:104-107`

```markdown
### Visualization
- component: VarScopeVisualization
- type: interactive
- data: {}
```

→ **확인**: 실제 산출물의 메타데이터 형식

**참고 파일**: `src/components/visualizations/variables/VarScopeVisualization.tsx:1-313`

→ **확인**:
- Props interface 정의 (line 3-6)
- Tab-based interactive pattern (line 9, 44-78)
- HTML/CSS 기반 레이아웃 (line 25-311)
- 색상 코딩 패턴 (red/blue)

**참고 파일**: `src/components/visualizations/variables/MemoryStorageVisualization.tsx:1-1325`

→ **확인**:
- 복잡한 컴포넌트 예시 (~1300줄)
- 다중 탭 패턴 (overview, primitive, lifecycle, performance)
- GC 시뮬레이션 (step-by-step animation)

**참고 파일**: `src/components/visualizations/index.ts:1-25`

```typescript
export { VarScopeVisualization } from './variables/VarScopeVisualization';
export { MemoryStorageVisualization } from './variables/MemoryStorageVisualization';
// ...
```

→ **확인**: index.ts export 패턴

### 렌더링 로직 분석 (추론)
- 파서 테스트 없음 (visualization-writer는 콘텐츠가 아닌 코드 생성)
- React 앱이 `@/components/visualizations`에서 동적 import
- Visualization 메타데이터의 `component` 필드로 매칭

### 제대로 된 계약 정의

#### 개선 사항
1. **명확성**:
   - 입력 형식 명시 (component, type, data 3개 필드)
   - 출력 형식 명시 (TypeScript, Props interface, export)
   - Critical Requirement 강조 (index.ts export)

2. **완전성**:
   - 시각화 유형별 패턴 정의 (Memory Diagrams, Execution Timeline 등)
   - 스타일 가이드 포함 (일관성 유지)
   - SKIP 처리 조건 명확화

3. **검증 가능성**:
   - TypeScript 컴파일 검증
   - index.ts export 검증 (Grep)
   - 브라우저 렌더링 검증

4. **특수성 인식**:
   - 콘텐츠 작성 아닌 코드 생성
   - 파서 테스트 없음
   - 렌더링 로직으로 검증

---

## 11. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2025-10-13 | 초기 계약 정의 |

---

## 12. 참고 문서

- `.claude/agents/visualization-writer.md` (프롬프트 파일)
- `src/components/visualizations/variables/VarScopeVisualization.tsx` (샘플 컴포넌트)
- `src/components/visualizations/variables/MemoryStorageVisualization.tsx` (복잡한 샘플)
- `src/components/visualizations/index.ts` (중앙 export)
- `docs/aidlc-docs/inception/units/unit-2-pipe-mechanism.md` (Pipe 메커니즘)
