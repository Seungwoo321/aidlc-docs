# concepts-writer Contract

**Version**: 1.0.0
**Created**: 2025-10-13
**Status**: Draft

---

## 1. 개요

### Filter 이름
`concepts-writer`

### 역할 및 책임
학습 콘텐츠의 Core Concepts 섹션을 작성하여 3단계 난이도(Easy/Normal/Expert)로 핵심 개념을 설명합니다. 각 학습자의 수준에 맞는 설명을 제공하고, 시각화를 통해 추상적인 개념을 구체화합니다.

**핵심 책임**:
- `# Core Concepts` 섹션 작성
- 3-5개 Concept 정의 및 작성
- 각 Concept마다 Easy/Normal/Expert 3단계 설명
- Code Snippet 및 Visualization 추가 (권장)
- Work Status Markers 업데이트 및 핸드오프

**3단계 난이도 시스템** (이 프로젝트의 핵심):
- **Easy**: 중학생도 이해 가능 (일상 비유, 이모지, 코드 없음)
- **Normal**: 일반 개발자 수준 (기술 용어 + 간단한 코드)
- **Expert**: 20년+ 전문가 수준 (ECMAScript 명세, 엔진 구현)

### Pipeline에서의 위치
```
overview-writer → [concepts-writer] → visualization-writer → ...
```

- **선행 Filter**: overview-writer
- **후행 Filter**: visualization-writer

---

## 2. 입력 계약 (Input Contract)

### 필수 입력 데이터

#### 2.1 파일 구조
```markdown
---
---

<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: concepts-writer -->
<!-- PROGRESS: pending -->
...

# Overview
[Overview content]

```

- **Frontmatter**: 존재
- **Work Status Markers**: 존재, `CURRENT_AGENT`가 `concepts-writer`
- **Overview 섹션**: 완료됨
- **Core Concepts 섹션**: 없음 (또는 개선 요청 있음)

### Work Status Markers 확인

#### 실행 조건
```markdown
CURRENT_AGENT: concepts-writer
```

**✅ 실행**:
- `CURRENT_AGENT`가 정확히 `concepts-writer`
- Core Concepts 섹션 없음

**❌ 건너뛰기**:
- `CURRENT_AGENT`가 다른 값
- Core Concepts 섹션 존재 (개선 요청 없음)

#### 개선 모드 감지
```markdown
<!-- IMPROVEMENT_NEEDED:
- concepts-writer: Easy 섹션 전면 재작성 (-6점)
-->
```

### 선행 조건 (Preconditions)
1. 파일 존재
2. Work Status Markers 존재
3. `CURRENT_AGENT`가 `concepts-writer`
4. Overview 섹션 완료
5. Core Concepts 섹션 없음 (또는 개선 요청)

---

## 3. 출력 계약 (Output Contract)

### 생성할 섹션

#### 3.1 Core Concepts 섹션 전체 구조

```markdown
# Core Concepts

## Concept: [Concept 1 Title]
**ID**: [concept-id-1]

### Easy
[일상 비유 중심 설명, 이모지 사용, 코드 없음]

### Normal
#### Text
[기술 용어 설명]

#### Code: [Descriptive Title]
```javascript
[5-10줄 코드]
```

#### Text
[추가 설명]

### Expert
[ECMAScript 명세, 엔진 구현, 성능]

### Code Snippet
#### Code: [Title]
```javascript
[3-5줄 핵심 코드]
```

### Visualization
- component: [Concept1]Visualization
- type: interactive
- data: {}

## Concept: [Concept 2 Title]
...
```

### 3.2 Concept 개수
- **최소**: 3개
- **최대**: 5개
- **권장**: 3-4개
- **구조**: 기본 → 고급 순서

### 3.3 각 Concept 구조

#### Concept 헤더
```markdown
## Concept: [Concept Title]
**ID**: [kebab-case-identifier]
```

**제목 규칙**:
- 명확하고 구체적
- 토픽의 핵심 개념 표현
- 15-50자

**ID 규칙**:
- kebab-case (소문자 + 하이픈)
- 의미 있는 이름
- 예: `function-scope-problem`, `hoisting-issue`

#### 3.4 Easy 섹션 (필수)

**헤딩**: `### Easy`

**필수 구성 요소**:
1. **한 줄 개념 요약** (첫 문장)
2. **🎈🏃‍♂️🎭 비유 중심 설명** (메인)
3. **🤔💡 문제/장점 설명** (중요성)
4. **🆚 다른 개념과 비교** (차이점)

**작성 원칙**:
- **이모지**: 보조 수단으로만 사용 (과도하지 않게)
- **일상 비유**: 서랍, 풍선, 신호등, 방 정리, 상자 등
- **기술 용어**: 사용 즉시 쉬운 말로 설명
- **코드 절대 금지**
- **하위 섹션**: **굵은 제목** 으로 구분

**예시** (참고: `01-var-problems.md:30-46`):
```markdown
### Easy
var로 선언한 변수는 블록({})을 무시하고 함수 전체에서 사용할 수 있어요.

**📦 상자 속의 상자 문제**
여러분이 방을 정리한다고 생각해보세요. 큰 방(함수) 안에 작은 수납 상자들(블록)이 있어요...

**🚨 실제로 어떤 문제가 생기나요?**
1. **if문 문제**: ...
2. **for문 문제**: ...

**💡 왜 이렇게 이상하게 만들었을까요?**
JavaScript가 1995년에 ...
```

**길이**: 10-25줄

#### 3.5 Normal 섹션 (필수)

**헤딩**: `### Normal`

**필수 구조**: `#### Text`와 `#### Code:` 교차

**정확한 패턴**:
```markdown
### Normal

#### Text
[기술 용어 설명, 원인-결과 관계]

#### Code: [Descriptive Title]
```javascript
[5-10줄 실행 가능 코드]
```

#### Text
[추가 설명 또는 요약]

#### Code: [Another Example]
```javascript
[코드]
```
```

**Text 작성 규칙**:
- 기술 용어 그대로 사용
- 원인-결과 관계 중심
- **굵은 하위 제목** 사용 가능
- 불릿 포인트로 요약

**Code 작성 규칙**:
- **3-8줄 실행 가능 코드** (10줄 초과 ❌)
- 주석은 핵심 부분만 (전체의 20% 미만)
- **설명이 코드보다 많아야 함**
- 복잡한 로직은 여러 Code 블록으로 분할
- ES6+ 문법 사용 (const, let, arrow function)
- console.log로 결과 확인 가능

**Code 헤더**:
- `#### Code: [Descriptive Title]`
- 제목은 코드가 무엇을 보여주는지 설명
- 예: `#### Code: var의 함수 스코프 예시`

**예시** (참고: `01-var-problems.md:48-74`):
```markdown
### Normal

#### Text
var는 함수 레벨 스코프를 가지므로 ...

**함수 스코프의 동작 원리**
var로 선언된 변수는 가장 가까운 함수 경계까지만 인식합니다.

#### Code: var의 함수 스코프 예시
```javascript
function example() {
  if (true) {
    var x = 1;
  }
  console.log(x); // 1
}
```

#### Text
**주요 문제점**
1. 블록 내 선언이 외부로 노출
2. 반복문 변수가 외부에 남음
3. 변수명 충돌 시 덮어써짐
```

**길이**: 15-40줄

#### 3.6 Expert 섹션 (필수)

**헤딩**: `### Expert`

**필수 구성 요소**:
1. **ECMAScript 명세 관점** 하위 섹션
2. 명세 섹션 번호 및 내용 인용
3. **V8 엔진 구현** 하위 섹션 (선택)
4. **성능과 최적화** 하위 섹션

**작성 규칙**:
- 이론과 원리 중심
- ECMAScript 명세 인용 (섹션 번호 포함)
- 엔진 구현 상세 설명
- 전문 용어 사용 후 즉시 정의
- 성능 영향 항상 언급
- 메모리 사용량 또는 실행 속도 언급

**Code 사용** (선택):
- `#### Code: [Pseudocode/API]`
- 실행 불가능한 설명용 코드
- ECMAScript 내부 연산 표현
- C++ 코드 또는 어셈블리도 가능

**예시** (참고: `01-var-problems.md:75-93`):
```markdown
### Expert
var의 함수 스코프는 ECMAScript 명세의 실행 환경 모델에서 ...

**ECMAScript 명세 기반 스코프 바인딩 메커니즘**
ECMAScript 명세 13.3.2절 변수 문(Variable Statement)에 따르면, ...

**V8 엔진의 구현과 최적화 전략:**
1. **컨텍스트 슬롯 할당**: ...
2. **블록 컨텍스트 생략**: CreateBlockContext 바이트코드를 ...
3. **TurboFan 최적화**:
   - Phi 노드 제거: SSA 형태에서 ...
   - LoadElimination: 중복된 변수 로드를 제거하여 ...

**성능과 메모리 영향**
전역 var의 사용은 심각한 성능 저하를 일으킬 수 있습니다. ...
```

**길이**: 20-50줄

#### 3.7 Code Snippet 섹션 (선택)

**위치**: Expert 섹션 다음, Visualization 전

**헤딩**: `### Code Snippet`

**구조**:
```markdown
### Code Snippet
#### Code: [핵심만 보여주는 제목]
```javascript
[3-5줄 핵심 코드]
```
```

**작성 규칙**:
- 3-5줄만 (5줄 초과 ❌)
- 핵심 개념 한눈에 표현
- 주석 없는 깔끔한 코드
- 실행 가능

**예시** (참고: `01-var-problems.md:95-102`):
```markdown
### Code Snippet
#### Code: 함수 스코프 문제 예시
```javascript
if (true) {
  var x = 10;
}
console.log(x); // 10
```
```

#### 3.8 Visualization 섹션 (권장)

**위치**: 각 Concept의 마지막

**헤딩**: `### Visualization`

**정확한 형식**:
```markdown
### Visualization
- component: [Concept]Visualization
- type: interactive | static | animation
- data: {
    [key]: [value],
    ...
  }
```

**필수 필드**:
- `component`: 컴포넌트 이름
- `type`: 시각화 유형
- `data`: 시각화 옵션 (객체 형식)

**component 네이밍**:
- 패턴: `[CoreConcept]Visualization`
- 예: `VarScopeVisualization`, `HoistingVisualization`, `TDZVisualization`

**type 값**:
- `interactive`: 사용자 인터랙션 가능
- `static`: 정적 다이어그램
- `animation`: 자동 애니메이션

**data 옵션 (참고)**:
- `showMemory`: 메모리 구조 표시
- `showSteps`: 단계별 실행 표시
- `showTimeline`: 시간 순서 표시
- `showErrors`: 에러 발생 표시
- `interactive`: 인터랙션 가능
- `showTDZ`: TDZ 영역 표시
- `{}`: 빈 객체도 가능

**예시** (참고: `01-var-problems.md:104-107`):
```markdown
### Visualization
- component: VarScopeVisualization
- type: interactive
- data: {}
```

### Work Status Markers 업데이트

#### 3.9 완료 시 업데이트
```markdown
<!-- CURRENT_AGENT: visualization-writer -->
<!-- PROGRESS: pending -->
<!-- STARTED: [original] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
[DONE] concepts-writer: 완료 - [YYYY-MM-DD HH:MM]
-->
```

### 후행 조건 (Postconditions)
1. `# Core Concepts` 섹션 존재
2. 3-5개 Concept 존재
3. 각 Concept:
   - `## Concept: [Title]` 헤더
   - `**ID**: [id]` 필드
   - `### Easy` 섹션 (코드 없음)
   - `### Normal` 섹션 (Text/Code 교차)
   - `### Expert` 섹션
   - `### Code Snippet` (선택)
   - `### Visualization` (권장)
4. Work Status Markers 업데이트
5. `CURRENT_AGENT`가 `visualization-writer`

---

## 4. 품질 기준 (Quality Criteria)

### 구조적 요구사항

#### 4.1 섹션 헤더
- ✅ `# Core Concepts` 정확히 일치
- ✅ 각 Concept: `## Concept: [Title]`
- ✅ 각 난이도: `### Easy`, `### Normal`, `### Expert`
- ✅ Normal 내 하위: `#### Text`, `#### Code: [Title]`
- ❌ 헤더 오타, 대소문자 불일치

**파서 요구사항** (참고: `markdownParser.ts:327-338`):
```typescript
if (line.startsWith('## Concept:')) {
  currentConcept = {
    title: line.replace('## Concept:', '').trim(),
    easy: '', normal: '', expert: ''
  };
}
```
→ 정확히 `## Concept:` 문자열 일치 필수

#### 4.2 필수 필드
- ✅ 각 Concept에 `**ID**: [id]` 필드
- ✅ ID는 kebab-case
- ✅ Easy/Normal/Expert 섹션 모두 존재
- ❌ 필드 누락 시 파서 실패

**파서 요구사항** (참고: `markdownParser.ts:344-346`):
```typescript
if (line.startsWith('**ID**:')) {
  currentConcept.id = line.replace('**ID**:', '').trim();
}
```

#### 4.3 Normal 섹션 구조
- ✅ 첫 시작은 `#### Text`
- ✅ `#### Code: [Title]` 형식 (콜론 필수)
- ✅ Text와 Code 교차
- ❌ `#### Code` (제목 없음)
- ❌ Code로 시작

**프롬프트 지침** (참고: `.claude/agents/concepts-writer.md:88-94`):
```markdown
#### #### Text and #### Code Alternating Structure Required
Exact pattern:
1. #### Text
2. #### Code: [Descriptive Title]
3. #### Text (if needed)
```

#### 4.4 Concept 개수
- ✅ 3-5개
- ⚠️ 2개 이하: 경고
- ⚠️ 6개 이상: 경고

### 내용적 요구사항

#### 4.5 Easy 섹션 품질
- ✅ 이모지 사용 (보조 수단)
- ✅ 일상 비유 (서랍, 풍선, 방 등)
- ✅ 기술 용어 즉시 쉬운 말로 설명
- ✅ 코드 없음
- ❌ 기술 용어만 나열
- ❌ 코드 포함

#### 4.6 Normal 섹션 품질
- ✅ 5-10줄 코드 (각 Code 블록)
- ✅ 실행 가능한 코드
- ✅ ES6+ 문법 (const, let, arrow)
- ✅ console.log로 결과 확인 가능
- ✅ 설명 > 코드 (설명이 더 많음)
- ❌ 10줄 초과 코드
- ❌ 주석이 20% 초과
- ❌ 코드만 있고 설명 부족

#### 4.7 Expert 섹션 품질
- ✅ ECMAScript 명세 인용
- ✅ 명세 섹션 번호 포함
- ✅ 엔진 구현 설명 (V8 등)
- ✅ 성능 영향 언급
- ✅ 전문 용어 정의
- ❌ 명세 인용 없음
- ❌ 성능 언급 없음

#### 4.8 Code Snippet 품질
- ✅ 3-5줄만
- ✅ 핵심 개념 표현
- ✅ 주석 없이 깔끔
- ❌ 5줄 초과

#### 4.9 Visualization 형식
- ✅ 3개 필드 (component, type, data)
- ✅ data는 객체 형식 `{}`
- ✅ component 네이밍: `[Concept]Visualization`
- ❌ 필드 누락
- ❌ data가 객체 아님

### 코딩 스타일

#### 4.10 JavaScript 규칙
- ✅ ES6+ 문법
- ✅ const, let (var ❌)
- ✅ Arrow functions
- ✅ Template literals
- ✅ 세미콜론 생략
- ✅ 2-space 들여쓰기
- ✅ camelCase 변수명
- ✅ 주석은 `//`, 코드 위에 배치

### 파싱 요구사항

#### 4.11 파서 호환성
**참고**: `src/utils/markdownParser.ts:319-686`

**parseCoreConcepts() 함수**:
- `## Concept:` 정확한 매칭 (line 327)
- `**ID**:` 정확한 매칭 (line 344)
- `### Easy`, `### Normal`, `### Expert` 순서대로 파싱 (line 350-423)
- `#### Text`, `#### Code: [Title]` 패턴 인식 (line 371-374)
- `### Code Snippet`, `### Visualization` 선택 섹션 파싱 (line 426-677)

**중요**: 필수 필드 누락 시 파서 실패

### 검증 체크리스트
- [ ] `# Core Concepts` 헤더 존재
- [ ] 3-5개 Concept 존재
- [ ] 각 Concept에 `## Concept: [Title]` 헤더
- [ ] 각 Concept에 `**ID**: [kebab-case]` 필드
- [ ] 각 Concept에 Easy/Normal/Expert 모두 존재
- [ ] Easy에 코드 없음, 비유 중심
- [ ] Normal 첫 시작 `#### Text`
- [ ] Normal에 `#### Code: [Title]` 형식
- [ ] Expert에 ECMAScript 명세 인용
- [ ] Code Snippet 3-5줄 (있는 경우)
- [ ] Visualization 올바른 형식 (있는 경우)
- [ ] Work Status Markers 업데이트
- [ ] `CURRENT_AGENT`가 `visualization-writer`

---

## 5. 오류 처리 (Error Handling)

### 오류 유형

#### 5.1 입력 오류
**오류**: `CURRENT_AGENT`가 `concepts-writer`가 아님
- **대응**: 건너뛰기
- **메시지**: `Skip: CURRENT_AGENT is {agent}`

**오류**: Overview 섹션 없음
- **대응**: 오류 출력, 종료
- **메시지**: `Error: Overview section missing, cannot proceed`

**오류**: Core Concepts 섹션 이미 존재 (개선 요청 없음)
- **대응**: 건너뛰기
- **메시지**: `Skip: Core Concepts already exists`

#### 5.2 생성 오류
**오류**: Concept 생성 실패
- **대응**: 재시도 (최대 1회)
- **재시도 조건**: API 오류

**오류**: Concept 개수 부족 (2개 이하)
- **대응**: 경고, 추가 Concept 생성
- **메시지**: `Warning: Only {count} concepts, minimum 3 required`

#### 5.3 검증 오류
**오류**: Easy 섹션에 코드 포함
- **대응**: 경고, 코드 제거
- **메시지**: `Warning: Code found in Easy section, removing`

**오류**: Normal 섹션 Code로 시작
- **대응**: 경고, Text 섹션 추가
- **메시지**: `Warning: Normal must start with #### Text`

**오류**: Expert 섹션에 명세 인용 없음
- **대응**: 경고, 명세 인용 추가
- **메시지**: `Warning: ECMAScript specification citation missing in Expert`

**오류**: 필수 필드 누락 (ID, Easy, Normal, Expert)
- **대응**: 오류, 해당 Concept 재생성
- **메시지**: `Error: Missing required field: {field}`

**오류**: Visualization 형식 오류
- **대응**: 경고, 형식 수정
- **메시지**: `Warning: Visualization data must be object format`

### 재시도 전략
- **재시도 횟수**: 최대 1회
- **재시도 조건**: API 오류만
- **재시도 간격**: 5초

### 실패 시 Work Status Markers
```markdown
<!-- CURRENT_AGENT: concepts-writer -->
<!-- PROGRESS: 실패 -->
<!-- HANDOFF LOG:
[ERROR] concepts-writer: 실패 - {error} - [timestamp]
-->
```

---

## 6. 성능 기준 (Performance Criteria)

### 평균 처리 시간
- **추정 범위**: 60-120초 (1-2분)
- **측정 항목**:
  - 파일 읽기 및 분석: 3-5초
  - Concept 생성 (3-5개): 50-100초
  - 검증 및 파일 쓰기: 7-15초

### 출력 크기 범위
- **Core Concepts 섹션**: 150-400줄
- **각 Concept**: 40-100줄
  - Easy: 10-25줄
  - Normal: 15-40줄
  - Expert: 20-50줄
  - Code Snippet: 5-10줄
  - Visualization: 3-5줄

### 리소스 사용량
- **토큰 소비**: 약 3,000-6,000 tokens (입력 + 출력)
- **API 호출**: 3-5회 (각 난이도별 또는 Concept별)
- **메모리**: 높음 (대량 콘텐츠 생성)

---

## 7. 분석 근거 (Analysis Evidence)

### 프롬프트 파일 분석

**참고 파일**: `.claude/agents/concepts-writer.md`

#### Core Mission (line 8-12)
```markdown
Autonomously identify the next content file requiring a Core Concepts section
by examining Work Status Markers, then create high-quality, multi-level concept
explanations with visualizations.
```
→ **추출**: 3단계 난이도 + 시각화

#### Concept Structure (line 59-70)
```markdown
Line 1: # Core Concepts
Line 3: ## Concept: [Concept Name]
Line 5: **ID**: [identifier]
  - Use kebab-case
```
→ **추출**: 정확한 헤더 형식, ID 규칙

#### Easy Section Rules (line 71-85)
```markdown
**Required Components**:
1. One-line concept summary
2. 🎈🏃‍♂️🎭 Analogy-centered explanation
3. 🤔💡 Problem/advantage explanation
4. 🆚 Comparison

**Writing Principles**:
- Emojis as supporting aids only
- Everyday analogies
- Absolutely NO code
```
→ **추출**: Easy 섹션 구성 요소, 코드 금지

#### Normal Section Rules (line 86-108)
```markdown
#### #### Text and #### Code Alternating Structure Required

Exact pattern:
1. #### Text
2. #### Code: [Descriptive Title]

**Code Writing Rules**:
- 3-8 executable statements (never exceed 10)
- Comments only on key parts (less than 20%)
- More Text than Code
```
→ **추출**: Text/Code 교차 패턴, 코드 길이 제한

#### Expert Section Rules (line 109-126)
```markdown
Required Components:
1. ECMAScript Specification Perspective
2. Specification section numbers and content citations
3. V8 Engine Implementation (optional)
4. Performance and Optimization

Text Writing Rules:
- Always mention performance implications
- Include memory usage or execution speed metrics
```
→ **추출**: 명세 인용 필수, 성능 언급 필수

#### Visualization Format (line 136-150)
```markdown
Exact format:
- component: [Concept]Visualization
- type: interactive or static or animation
- data: {
    visualization options
  }
```
→ **추출**: 정확한 형식, 3개 필드

#### Concept Selection (line 172-177)
```markdown
- Count: 3-5 core concepts
- Structure: Basic → Advanced order
- Independence: Each concept is independently understandable
```
→ **추출**: 개수 범위, 순서

### 파서 테스트 분석

**참고 파일**: `test/test-concepts.mjs` → `src/utils/markdownParser.ts`

#### parseCoreConcepts() (line 319-686)

**Concept 파싱** (line 327-338):
```typescript
if (line.startsWith('## Concept:')) {
  if (currentConcept && currentConcept.id) {
    concepts.push(currentConcept as CoreConcept);
  }
  currentConcept = {
    title: line.replace('## Concept:', '').trim(),
    easy: '', normal: '', expert: ''
  };
}
```
→ **추출**: `## Concept:` 정확한 매칭

**ID 파싱** (line 344-347):
```typescript
if (line.startsWith('**ID**:')) {
  currentConcept.id = line.replace('**ID**:', '').trim();
}
```
→ **추출**: `**ID**:` 정확한 매칭

**Easy 파싱** (line 350-361):
```typescript
if (line === '### Easy') {
  i++;
  let easyContent = '';
  while (i < lines.length && !lines[i].startsWith('### ')) {
    easyContent += lines[i] + '\n';
    i++;
  }
  currentConcept.easy = easyContent.trim();
}
```
→ **추출**: `### Easy` 정확한 매칭, 다음 `###`까지 내용

**Normal 파싱** (line 364-392):
```typescript
if (line === '### Normal') {
  // Extract code titles from #### Code: headers
  if (lines[i].startsWith('#### Code: ')) {
    lastCodeTitle = lines[i].replace('#### Code: ', '').trim();
  }
  else if (lines[i].startsWith('#### ')) {
    // Skip all headers like #### Text
  }
  // Process code blocks with titles
  else if (lines[i].startsWith('```') && lastCodeTitle) {
    normalContent += `[TITLE:${lastCodeTitle}]\n${lines[i]}\n`;
  }
}
```
→ **추출**: `#### Code: [Title]` 패턴 인식, `#### Text` 건너뜀

**Expert 파싱** (line 395-423):
- Normal과 동일한 패턴
- `### Expert` 매칭

**Code Snippet 파싱** (line 426-445):
```typescript
if (line === '### Code Snippet') {
  // Extract title and code block
}
```

**Visualization 파싱** (line 448-677):
```typescript
if (line === '### Visualization') {
  // Parse component, type, data fields
}
```
→ **추출**: 3개 필드 파싱, data 객체 파싱 로직 복잡

### 산출물 샘플 분석

**참고 파일**: `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md:25-124`

**Concept 1: 함수 스코프 문제** (line 27-108):
- `## Concept: var의 함수 스코프 문제`
- `**ID**: concept-1`
- `### Easy` (line 30-46): 이모지, 비유, 코드 없음
- `### Normal` (line 48-74): Text/Code 교차, 5줄 코드
- `### Expert` (line 75-93): ECMAScript 명세, V8 엔진, 성능
- `### Code Snippet` (line 95-102): 5줄 핵심 코드
- `### Visualization` (line 104-107): 올바른 형식

→ **확인**: 계약에 맞는 완전한 구조

**Concept 2: 호이스팅 문제** (line 109-124):
- 동일한 패턴 반복

→ **확인**: 일관된 구조

### 제대로 된 계약 정의

#### 개선 사항

1. **명확성**:
   - "multi-level concept explanations" → 정확한 Easy/Normal/Expert 구조 명시
   - 각 난이도별 구체적인 작성 규칙 정의
   - Normal 섹션 Text/Code 교차 패턴 명확화

2. **완전성**:
   - 각 난이도별 필수 구성 요소 명시
   - Code 길이 제한 (3-8줄, 10줄 초과 ❌)
   - Visualization 3개 필드 (component, type, data) 명시
   - Concept 개수 범위 (3-5개)

3. **검증 가능성**:
   - 13개 체크리스트 항목
   - 각 난이도별 품질 기준
   - 파서 호환성 확인 항목

4. **3단계 난이도 시스템** (프로젝트 핵심):
   - Easy: 중학생 수준, 일상 비유, 코드 없음
   - Normal: 일반 개발자, 기술 용어 + 간단한 코드
   - Expert: 전문가, ECMAScript 명세 + 엔진 구현

---

## 8. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2025-10-13 | 초기 계약 정의 |

---

## 9. 참고 문서

- `.claude/agents/concepts-writer.md` (프롬프트 파일)
- `.claude/handoff-guide.md` (Work Status Markers 명세)
- `test/test-concepts.mjs` (파서 테스트)
- `src/utils/markdownParser.ts:319-686` (parseCoreConcepts 함수)
- `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md` (샘플 1)
- `public/content/ko/javascript-core-concepts/01-variables/02-let-vs-var.md` (샘플 2)
- `CLAUDE.md` (프로젝트 개요 - 3단계 난이도 시스템)
