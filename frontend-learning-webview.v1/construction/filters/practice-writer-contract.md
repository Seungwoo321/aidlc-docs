# practice-writer Contract

**Version**: 1.0.0
**Created**: 2025-10-13
**Status**: Draft

---

## 1. 개요

### Filter 이름
`practice-writer`

### 역할 및 책임
학습한 이론을 **실습으로 체득**하기 위한 Code Patterns와 Experiments 섹션을 작성하는 역할을 합니다. Core Concepts의 추상적 개념을 실행 가능한 코드로 구체화하고, 학습자가 직접 실험할 수 있는 환경을 제공합니다.

**핵심 책임**:
- Code Patterns 섹션 작성 (anti-pattern → solution pattern)
- Experiments 섹션 작성 (hands-on 실험)
- 즉시 실행 가능한 JavaScript 코드 제공
- 3단계 난이도 설명 (Easy/Normal/Expert)
- Work Status Markers 관리

**실습 철학**:
- 이론 → 코드 확인 → 직접 실험 순서
- 결과를 console.log로 즉시 확인
- 비교를 통한 학습 (before/after, anti-pattern/solution)

### Pipeline에서의 위치
```
category.yaml → ... → visualization-writer → [practice-writer] → quiz-writer → ...
```

- **선행 Filter**: visualization-writer (또는 concepts-writer)
- **후행 Filter**: quiz-writer

---

## 2. 입력 계약 (Input Contract)

### 필수 입력 데이터

#### 2.1 마크다운 파일
- **파일 경로**: `public/content/ko/{category}/{subcategory}/{topic-id}-{topic-name}.md`
- **Work Status Markers**: `CURRENT_AGENT: practice-writer`, `PROGRESS: 대기중`

#### 2.2 Core Concepts 섹션 (컨텍스트)
**위치**: `# Core Concepts` 섹션

**목적**: 실습할 개념 이해
- Easy/Normal/Expert 설명
- Code Snippet (있는 경우)
- Visualization (있는 경우)

**사용**: Pattern 및 Experiment 설계

#### 2.3 Overview 섹션 (컨텍스트)
**위치**: `# Overview` 섹션

**목적**: 학습 목표 및 중요성 파악

**사용**: 실무 시나리오 설계

### 선행 조건 (Preconditions)
1. Core Concepts 섹션이 concepts-writer에 의해 작성됨
2. Work Status Markers에서 `CURRENT_AGENT: practice-writer`
3. Code Patterns 섹션이 없거나 비어 있음
4. Experiments 섹션이 없거나 비어 있음

---

## 3. 출력 계약 (Output Contract)

### 생성할 산출물

#### 3.1 Code Patterns 섹션
**위치**: Core Concepts 다음, Experiments 이전

**헤더**: `# Code Patterns` (H1)

**개별 Pattern 구조**:
```markdown
## Pattern: [Title]
**ID**: [kebab-case-identifier]

### Description
[Single sentence describing pattern purpose]

### Short Code
```javascript
[3-5 executable statements]
```

### Full Code
```javascript
[10-20 executable statements with comments < 50%]
```

### Explanation
**Easy**: [Everyday analogy with emojis, parenthetical technical terms]

**Normal**: [Technical terms, cause-effect relationships, code connection]

**Expert**: [ECMAScript spec quotes, engine principles, performance impact]
```

**필수 요소**:
- Pattern 제목: `## Pattern:` 형식 (문제 → 해결 구조)
- ID: `**ID**:` 형식, kebab-case
- Description: `### Description` 다음 줄에 1문장
- Short Code: `### Short Code` 다음에 코드 블록
- Full Code: `### Full Code` 다음에 코드 블록
- Explanation: Easy/Normal/Expert 각 단락 (볼드 처리)

#### 3.2 Experiments 섹션
**위치**: Code Patterns 다음, Quiz 이전

**헤더**: `# Experiments` (H1)

**개별 Experiment 구조**:
```markdown
## Experiment: [Title]
**ID**: [kebab-case-identifier]

### Description
[Single sentence describing experiment purpose]

### Instructions
1. [Imperative verb] [specific action with line numbers/variables]
2. [Imperative verb] [action + expected result]
3. [Imperative verb] [action]
4. [Imperative verb] [action]
5. [Imperative verb] [action + comparison]
6. (선택) [Imperative verb] [reflection question]

### Initial Code
```javascript
[10-25 lines of complete, executable code]
[Modification points marked with // TODO: comments]
```
```

**필수 요소**:
- Experiment 제목: `## Experiment:` 형식 (능동 동사 사용)
- ID: `**ID**:` 형식, kebab-case
- Description: `### Description` 다음 줄에 1문장
- Instructions: `### Instructions` 다음에 번호 목록 (5-8개)
- Initial Code: `### Initial Code` 다음에 코드 블록

### 출력 형식

#### 3.2.1 Code Patterns 세부 규칙

**Title 형식**:
- "Problem → Solution" 구조
- 예: "var의 함수 스코프 문제 해결하기"
- 예: "var 호이스팅 문제와 TDZ 활용"

**Short Code**:
- 3-5개 실행 가능한 구문 (빈 줄, 주석 제외)
- 핵심 개념만 표현
- console.log로 결과 확인 가능

**예시**:
```javascript
// 문제: var는 블록 스코프를 무시
if (true) {
  var x = 1;
}
console.log(x); // 1 (접근 가능!)

// 해결: let/const는 블록 스코프 준수
if (true) {
  let y = 1;
}
// console.log(y); // ReferenceError
```

**Full Code**:
- 10-20개 실행 가능한 구문
- 주석이 코드 줄의 50% 이내
- Anti-pattern과 Solution pattern 대조
- console.log로 차이점 즉시 확인 가능
- const/let만 사용 (var 금지, 단 anti-pattern 예시는 제외)

**예시** (실무 시나리오):
```javascript
// 문제: var 사용
function processUserData(users) {
  for (var i = 0; i < users.length; i++) {
    var user = users[i];
    if (user.isActive) {
      var activeCount = (activeCount || 0) + 1;
    }
  }
  console.log(i); // users.length (블록 밖에서 접근!)
}

// 해결: let/const 사용
function processUserDataSafe(users) {
  let activeCount = 0;
  for (const user of users) {
    if (user.isActive) {
      activeCount++;
    }
  }
  return { activeCount };
}
```

**Explanation**:
- **Easy**: 이모지 1개 이상, 일상 비유, 기술 용어에 괄호 설명
  - 예: "var는 블록({}) 안에서 선언해도 블록 밖에서 사용할 수 있어요. 마치 울타리가 없는 것처럼요! 반면 let과 const는 블록 안에서만 사용할 수 있어요."
- **Normal**: 기술 용어 그대로, 원인-결과 관계, 코드 연결
  - 예: "var의 함수 스코프는 블록문 내부의 변수가 외부로 누출되는 문제를 일으킵니다. 이는 변수명 충돌, 의도하지 않은 값 덮어쓰기 등의 문제로 이어집니다."
- **Expert**: ECMAScript 명세 인용, 엔진 동작 원리, 성능 영향 언급
  - 예: "var의 함수 스코프는 VariableEnvironment의 Environment Record에 바인딩되어 블록 경계를 무시합니다. V8 엔진은 var 변수를 Context의 함수 레벨 슬롯에 할당하며..."

#### 3.2.2 Experiments 세부 규칙

**Title 형식**:
- 학습 목표 명확 표현
- 능동 동사 사용: "실험하기", "체험하기", "비교하기", "검증하기"
- 예: "var의 4가지 문제점 체험하기"
- 예: "블록 스코프와 함수 스코프 비교 실험"

**Instructions**:
- 5-8개 단계
- 각 단계는 명령형 동사로 시작
- 코드 내 특정 줄 번호나 변수명 지정
- 예상 결과를 구체적으로 제시
- 번호 목록 형식 (1부터 시작)

**예시**:
```markdown
1. 각 실험의 주석을 해제하고 결과를 확인하세요
2. var의 문제점이 어떻게 나타나는지 관찰하세요
3. let/const로 바꿔서 어떻게 해결되는지 비교하세요
4. 실제 프로젝트에서 이런 문제가 어떻게 발생할지 생각해보세요
```

**Initial Code**:
- 완전한 구현 (빈 함수나 미완성 코드 금지)
- 즉시 실행 가능
- 수정할 지점을 주석으로 명확히 표시
  - ✅ `// TODO: 주석을 해제하고 결과를 확인하세요`
  - ✅ `// TODO: var를 let으로 바꿔보세요`
  - ❌ `function foo() { /* TODO: 구현하세요 */ }` (미완성 코드)
- console.log로 결과 확인 가능
- 10-25줄

**예시**:
```javascript
// 실험 1: 함수 스코프 vs 블록 스코프
console.log('=== 스코프 실험 ===');

function scopeTest() {
  // TODO: 주석을 해제하고 var의 문제점을 확인하세요
  // console.log('블록 전 x:', x); // undefined (에러 아님!)

  if (true) {
    var x = 'var는 함수 스코프';
    let y = 'let은 블록 스코프';
    console.log('블록 내부:', x, y);
  }

  console.log('블록 외부 x:', x); // 접근 가능!
  // console.log('블록 외부 y:', y); // ReferenceError
}

scopeTest();
```

### 후행 조건 (Postconditions)
1. Code Patterns 섹션 존재 (1개 이상의 Pattern)
2. Experiments 섹션 존재 (1개 이상의 Experiment)
3. 모든 코드가 실행 가능 (syntax error 없음)
4. Parser 테스트 통과 (필수 필드 모두 존재)
5. Work Status Markers가 quiz-writer로 핸드오프됨

---

## 4. 품질 기준 (Quality Criteria)

### 구조적 요구사항

#### 4.1 Pattern 필수 필드 (Parser 검증)
- ✅ `## Pattern:` 제목
- ✅ `**ID**:` 형식의 ID
- ✅ `### Description` + 다음 줄 1문장
- ✅ `### Short Code` + 코드 블록
- ✅ `### Full Code` + 코드 블록
- ✅ `### Explanation` + Easy/Normal/Expert 단락
- ❌ Type, Difficulty, Hints 등 추가 필드 (parser 실패)

#### 4.2 Experiment 필수 필드 (Parser 검증)
- ✅ `## Experiment:` 제목
- ✅ `**ID**:` 형식의 ID
- ✅ `### Description` + 다음 줄 1문장
- ✅ `### Instructions` + 번호 목록
- ✅ `### Initial Code` + 코드 블록
- ❌ Type, Difficulty, Hints 등 추가 필드 (parser 실패)

#### 4.3 헤더 레벨 및 형식
- ✅ 섹션 헤더: `# Code Patterns`, `# Experiments` (H1)
- ✅ Pattern/Experiment 제목: `##` (H2)
- ✅ 서브 섹션: `###` (H3)
- ❌ H4 이상 사용 금지

### 내용적 요구사항

#### 4.4 Code Patterns 품질
**핵심 개념 반영**:
- ✅ Core Concepts의 개념을 코드로 직접 구현
- ✅ Anti-pattern과 Solution pattern 명확한 대조
- ✅ console.log로 차이점 즉시 확인 가능
- ❌ 개념과 무관한 코드

**코드 실행 가능성**:
- ✅ syntax error 없이 실행
- ✅ 복사-붙여넣기 후 즉시 실행 가능
- ✅ 외부 의존성 없음 (순수 JavaScript)
- ❌ 미완성 코드, TODO만 있는 함수

**설명 완전성**:
- ✅ Easy/Normal/Expert 3단계 모두 존재
- ✅ 각 단계가 적절한 난이도로 작성됨
- ❌ 한 단계라도 누락

#### 4.5 Experiments 품질
**Instructions 명확성**:
- ✅ 5-8개 단계
- ✅ 각 단계가 명령형 동사로 시작
- ✅ 구체적인 줄 번호나 변수명 지정
- ✅ 예상 결과 명시
- ❌ 모호한 지시사항

**Initial Code 완전성**:
- ✅ 완전한 구현 (즉시 실행 가능)
- ✅ 수정 지점이 주석으로 명확히 표시
- ✅ console.log로 결과 확인 가능
- ❌ 빈 함수나 미완성 코드
- ❌ 실행 불가능한 코드

**실험 설계**:
- ✅ 학습자가 직접 수정하며 차이를 경험
- ✅ 수정 전후 비교 가능
- ✅ 점진적 난이도 증가
- ❌ 수동적 관찰만 가능한 코드

#### 4.6 JavaScript 코드 규칙
- ✅ ES6+ 문법 (const, let, arrow function, template literal)
- ✅ 세미콜론 생략
- ✅ 2칸 들여쓰기
- ✅ camelCase 변수명
- ✅ `//` 주석 (코드 위에 위치)
- ❌ var 사용 (anti-pattern 예시 제외)
- ❌ 세미콜론 사용
- ❌ 4칸 들여쓰기

### 파서 테스트 검증

#### 4.7 Parser 호환성
**테스트 파일**: `test/test-patterns.mjs`, `test/test-experiments.mjs`

**검증 방법**:
```bash
npx tsx test/test-patterns.mjs [file]
npx tsx test/test-experiments.mjs [file]
```

**성공 조건**:
- JSON 출력에 모든 Pattern/Experiment 포함
- 각 항목에 필수 필드 모두 존재 (id, title, description, code, explanation 등)
- Parser 에러 없음

**실패 원인**:
- 필수 필드 누락
- 헤더 형식 불일치 (## Pattern: vs ## Code Pattern:)
- Description이 여러 줄로 작성됨
- 추가 필드 포함 (Type, Difficulty 등)

### 검증 체크리스트
- [ ] Code Patterns 섹션 존재 (최소 1개 Pattern)
- [ ] Experiments 섹션 존재 (최소 1개 Experiment)
- [ ] 모든 Pattern에 6개 필수 필드 존재
- [ ] 모든 Experiment에 5개 필수 필드 존재
- [ ] 모든 코드가 syntax error 없이 실행 가능
- [ ] Parser 테스트 통과 (test-patterns.mjs, test-experiments.mjs)
- [ ] Easy/Normal/Expert 설명이 적절한 난이도
- [ ] JavaScript 코드 규칙 준수 (ES6+, no semicolon, 2-space indent)

---

## 5. 오류 처리 (Error Handling)

### 오류 유형

#### 5.1 입력 오류
**오류**: Core Concepts 섹션 없음
- **대응**: 오류 로그 출력, PROGRESS: 진행중 유지
- **메시지 형식**: `Error: Core Concepts section missing - cannot design patterns`

**오류**: CURRENT_AGENT가 practice-writer 아님
- **대응**: 작업 건너뛰기, 아무 작업 안 함

#### 5.2 생성 오류
**오류**: Parser 테스트 실패 (필수 필드 누락)
- **대응**:
  - Parser 에러 로그 확인
  - 누락된 필드 추가
  - 재작성 (최대 1회)
- **재시도 조건**: 구조적 오류만

**오류**: 코드 syntax error
- **대응**:
  - 에러 메시지 확인
  - 코드 수정
  - 재작성 (최대 1회)

#### 5.3 품질 오류
**오류**: Explanation에 Easy/Normal/Expert 중 하나 누락
- **대응**: 누락된 단계 추가

**오류**: Instructions가 5개 미만
- **대응**: 단계 추가하여 5-8개 범위 맞춤

**오류**: Initial Code에 미완성 함수 포함
- **대응**: 완전한 구현으로 교체, TODO는 instruction comment로만 사용

### 재시도 전략
- **재시도 횟수**: 최대 1회
- **재시도 조건**:
  - Parser 테스트 실패 (구조적 오류)
  - Syntax error (수정 가능 시)
- **재시도 간격**: 즉시

### 실패 시 처리
1. HANDOFF LOG에 실패 사유 기록
2. PROGRESS: 진행중 유지 (완료로 변경 금지)
3. 오케스트레이션 스크립트에 종료 코드 반환
4. 수동 검토 요청

---

## 6. 성능 기준 (Performance Criteria)

### 평균 처리 시간
- **추정 범위**: 10-20분 (LLM 콘텐츠 생성 시간)
- **측정 항목**:
  - Core Concepts 분석: 2-3분
  - Pattern 설계 및 작성: 4-8분 (2-3개 Pattern)
  - Experiment 설계 및 작성: 3-6분 (1-2개 Experiment)
  - Parser 테스트 검증: 1-2분

### 출력 크기 범위
- **Code Patterns 섹션**: 150-300줄
  - Pattern당: 50-100줄
  - 일반적으로 2-3개 Pattern
- **Experiments 섹션**: 80-150줄
  - Experiment당: 40-75줄
  - 일반적으로 1-2개 Experiment

### 리소스 사용량
- **토큰 소비**: 3000-8000 토큰
  - Core Concepts 읽기: 1000-2000 토큰
  - Pattern 생성: 1500-4000 토큰
  - Experiment 생성: 500-2000 토큰
- **API 호출**: 5-15회
  - Read (markdown, Core Concepts): 1-3회
  - MultiEdit (Pattern, Experiment 작성): 2-6회
  - Bash (Parser 테스트, 선택): 2-4회
- **메모리**: 중간 (콘텐츠 생성)

---

## 7. Work Status Markers 계약

### 시작 시 확인할 마커

**필수 조건**:
```markdown
<!-- CURRENT_AGENT: practice-writer -->
<!-- PROGRESS: 대기중 -->
```

**선택 조건 (개선 모드)**:
```markdown
<!-- IMPROVEMENT_NEEDED:
- practice-writer: Enhance Pattern 2 explanation (-5점)
-->
```

### 작업 시작 시 업데이트

```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: practice-writer -->
<!-- PROGRESS: 진행중 -->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
-->
```

### 완료 시 업데이트

```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: quiz-writer -->
<!-- PROGRESS: 대기중 -->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
[DONE] practice-writer: 완료 - [YYYY-MM-DD HH:MM]
-->
```

**완료 조건**:
- ✅ Code Patterns 섹션 작성됨
- ✅ Experiments 섹션 작성됨
- ✅ Parser 테스트 통과
- ✅ 모든 코드 실행 가능

### 개선 모드 처리

**개선 항목 확인**:
```markdown
<!-- IMPROVEMENT_NEEDED:
- practice-writer: Enhance Pattern 2 explanation (-5점)
- practice-writer: Add more detailed Instructions in Experiment 1 (-3점)
-->
```

**개선 완료 후**:
- IMPROVEMENT_NEEDED에서 해당 항목 제거
- HANDOFF LOG에 개선 완료 기록:
  ```
  [IMPROVE] practice-writer: 개선 완료 - Pattern 2 explanation enhanced, Experiment 1 instructions detailed
  ```

---

## 8. 의존성

### 선행 Filter
- **concepts-writer**: Core Concepts 섹션 생성 (필수)
- **overview-writer**: Overview 섹션 생성 (컨텍스트)
- **visualization-writer**: 시각화 생성 (선택)

**의존 데이터**:
- Core Concepts (개념 이해)
- Easy/Normal/Expert 설명 (난이도 참고)
- Code Snippet (코드 예시 참고)

### 후속 Filter
- **quiz-writer**: Quiz 섹션 생성

**제공 데이터**:
- Code Patterns (퀴즈 문제 출처)
- Experiments (퀴즈 실습 연계)

### 외부 의존성
1. **Parser 테스트**:
   - `test/test-patterns.mjs` (Pattern 파싱)
   - `test/test-experiments.mjs` (Experiment 파싱)
   - `src/utils/markdownParser.ts` (파싱 로직)

2. **JavaScript 런타임**:
   - Node.js 환경 (코드 실행 검증)

---

## 9. 특수 고려사항

### 9.1 실습의 교육적 가치
- **이론 → 실습 연결**: Core Concepts의 추상적 개념을 구체적 코드로 구현
- **즉시 피드백**: console.log로 결과를 눈으로 확인
- **비교 학습**: Anti-pattern과 Solution을 대조하여 차이 체감
- **능동적 참여**: Experiments에서 직접 코드 수정하며 학습

### 9.2 Pattern vs Experiment 차이
**Pattern (코드 확인)**:
- 목적: 올바른 코드 패턴 제시
- 구조: Short Code + Full Code + Explanation
- 역할: "이렇게 작성하면 된다" 보여주기

**Experiment (직접 실험)**:
- 목적: 개념을 직접 경험
- 구조: Instructions + Initial Code
- 역할: "직접 해보면서 깨닫기"

### 9.3 TODO 주석의 올바른 사용
❌ **잘못된 사용** (미완성 코드):
```javascript
function calculateSum(arr) {
  // TODO: 구현하세요
}
```

✅ **올바른 사용** (instruction comment):
```javascript
function calculateSum(arr) {
  // TODO: 아래 주석을 해제하고 결과를 확인하세요
  // console.log('Sum:', arr.reduce((a, b) => a + b, 0))
  return arr.reduce((a, b) => a + b, 0)
}
```

### 9.4 Parser 의존성
- Parser는 **정확한 형식**을 요구
- 필드 추가/누락 시 파싱 실패
- 헤더 형식 (`## Pattern:`, `### Description`) 엄격히 준수

**주의사항**:
- ❌ `## Code Pattern:` (잘못된 헤더)
- ❌ `**Type**: practical` (불필요한 필드)
- ❌ Description이 여러 줄

### 9.5 UTF-8 인코딩
- 한글 콘텐츠 작성 시 UTF-8 인코딩 필수
- MultiEdit tool 사용 시 자동 처리됨

---

## 10. 분석 근거 (Analysis Evidence)

### 프롬프트 파일 분석

**참고 파일**: `.claude/agents/practice-writer.md`

#### 핵심 미션 (line 8-12)
```markdown
You are a specialist in designing practice-oriented programming educational content.

## Core Mission
Autonomously write Code Patterns and Experiments sections by checking Work Status Markers.
```

→ **추출**: 역할이 명확함 (실습 중심 교육 콘텐츠 설계), 두 섹션 작성

#### Code Patterns 구조 (line 61-94)
```markdown
Line 1: ## Pattern: [Title]
Line 3: **ID**: [identifier]
Line 5: ### Description
Line 6: Single sentence

### Short Code Section:
- 3-5 executable statements

### Full Code Section:
- 10-20 executable statements. Comments within 50% of code lines
- Contrast incorrect usage (anti-pattern) with correct usage
- Use only const or let (no var)

### Explanation Section:
Easy: Use 1+ emojis. Everyday object analogies.
Normal: Use technical terms as-is. Focus on cause-effect relationships.
Expert: Quote ECMAScript specification. Engine operation principles.
```

→ **추출**: 정확한 출력 형식, 3단계 난이도 설명

#### Experiments 구조 (line 96-127)
```markdown
Line 1: ## Experiment: [Title]
Line 3: **ID**: [identifier]
Line 5: ### Description
Line 6: Single sentence

### Instructions Section:
- 5-8 steps
- Each step starts with imperative verb

### Initial Code Section:
- Complete implementation without TODOs or empty functions
- Immediately executable code
- Modification points clearly marked with comments
```

→ **추출**: Experiments 형식, TODO는 instruction comment로만 사용

#### Parser Requirements (line 129-146)
```markdown
#### Code Patterns Required Fields (All Mandatory):
1. Pattern title: Must start with ## Pattern:
2. ID: Must use **ID**: format
3. Description: Must be one line under ### Description header
4. Short Code: Must be code block under ### Short Code header
5. Full Code: Must be code block under ### Full Code header
6. Explanation: Must have Easy, Normal, Expert paragraphs

#### Experiments Required Fields (All Mandatory):
1. Experiment title: Must start with ## Experiment:
2. ID: Must use **ID**: format
3. Description: Must be one line under ### Description header
4. Instructions: Must be numbered list under ### Instructions header
5. Initial Code: Must be code block under ### Initial Code header

Parser fails if any field is missing. Do not add fields like Type, Difficulty, Hints.
```

→ **추출**: 필수 필드 명확 (6개/5개), Parser 실패 조건

#### JavaScript 코드 규칙 (line 148-156)
```markdown
### JavaScript Code Rules:
- Use ES6+ syntax (const, let, arrow functions, template literals)
- Omit semicolons
- 2-space indentation
- camelCase variable names
- Comments with //, place above code line
```

→ **추출**: 코드 스타일 가이드

### 파서 테스트 분석

**참고 파일**: `test/test-patterns.mjs`, `test/test-experiments.mjs`

→ **확인**: 단순 출력 테스트 (parseMarkdown 호출 후 JSON 출력), 구조적 요구사항 제공

### 산출물 샘플 분석

**참고 파일**: `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md:809-908`

```markdown
# Code Patterns

## Pattern: var의 함수 스코프 문제 해결하기
**ID**: pattern-1

### Description
var의 함수 스코프 문제를 이해하고 let/const로 해결하는 패턴

### Short Code
```javascript
// 문제: var는 블록 스코프를 무시
if (true) {
  var x = 1;
}
console.log(x); // 1 (접근 가능!)

// 해결: let/const는 블록 스코프 준수
if (true) {
  let y = 1;
}
// console.log(y); // ReferenceError
```

### Full Code
[10-20줄 실무 시나리오 코드]

### Explanation
**Easy**: [이모지 + 일상 비유]
**Normal**: [기술 용어 + 원인-결과]
**Expert**: [ECMAScript 명세 + V8 엔진]
```

→ **확인**: 실제 산출물의 정확한 형식

**참고 파일**: `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md:1117-1196`

```markdown
# Experiments

## Experiment: var의 4가지 문제점 체험하기
**ID**: exp-1

### Description
var의 함수 스코프, 호이스팅, 클로저, 재선언 문제를 직접 실험해보세요

### Instructions
1. 각 실험의 주석을 해제하고 결과를 확인하세요
2. var의 문제점이 어떻게 나타나는지 관찰하세요
3. let/const로 바꿔서 어떻게 해결되는지 비교하세요
4. 실제 프로젝트에서 이런 문제가 어떻게 발생할지 생각해보세요

### Initial Code
```javascript
// 실험 1: 함수 스코프 vs 블록 스코프
console.log('=== 스코프 실험 ===');

function scopeTest() {
  // TODO: 주석을 해제하고 var의 문제점을 확인하세요
  // console.log('블록 전 x:', x);

  if (true) {
    var x = 'var는 함수 스코프';
    let y = 'let은 블록 스코프';
    console.log('블록 내부:', x, y);
  }

  console.log('블록 외부 x:', x); // 접근 가능!
  // console.log('블록 외부 y:', y); // ReferenceError
}

scopeTest();
```
```

→ **확인**: TODO는 instruction comment로 사용, 완전한 실행 가능 코드

### 제대로 된 계약 정의

#### 개선 사항
1. **명확성**:
   - Pattern 6개 필수 필드 명시
   - Experiment 5개 필수 필드 명시
   - TODO 올바른 사용법 구분

2. **완전성**:
   - JavaScript 코드 규칙 상세화
   - Pattern vs Experiment 차이 명확화
   - Parser 의존성 강조

3. **검증 가능성**:
   - Parser 테스트 실행 방법
   - 코드 실행 가능성 검증
   - 8개 체크리스트 항목

---

## 11. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2025-10-13 | 초기 계약 정의 |

---

## 12. 참고 문서

- `.claude/agents/practice-writer.md` (프롬프트 파일)
- `test/test-patterns.mjs` (Pattern 파서 테스트)
- `test/test-experiments.mjs` (Experiment 파서 테스트)
- `src/utils/markdownParser.ts` (파싱 로직)
- `docs/aidlc-docs/inception/units/unit-2-pipe-mechanism.md` (Pipe 메커니즘)
