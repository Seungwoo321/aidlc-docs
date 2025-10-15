# overview-writer Contract

**Version**: 1.0.0
**Created**: 2025-10-13
**Status**: Draft

---

## 1. 개요

### Filter 이름
`overview-writer`

### 역할 및 책임
학습 콘텐츠의 Overview 섹션을 작성하여 학습자에게 토픽의 개요, 중요성, 학습 목표를 전달합니다. 개념 중심의 간결한 설명으로 학습 동기를 부여하고, Core Concepts 섹션으로의 자연스러운 전환을 준비합니다.

**핵심 책임**:
- `# Overview` 섹션 작성
- Introduction paragraph(들) 작성
- 3-4개 하위 섹션 (`##` 레벨) 작성
- Work Status Markers 업데이트 및 다음 Filter로 핸드오프

### Pipeline에서의 위치
```
content-initiator → [overview-writer] → concepts-writer → ...
```

- **선행 Filter**: content-initiator
- **후행 Filter**: concepts-writer

---

## 2. 입력 계약 (Input Contract)

### 필수 입력 데이터

#### 2.1 파일 경로
- **형식**: `public/content/ko/{category}/{subcategory}/{topic-id}-{topic-name}.md`
- **예시**: `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md`
- **조건**: 파일이 존재하고, Work Status Markers가 있어야 함

#### 2.2 파일 구조
**최소 요구사항**:
```markdown
---
---

<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: overview-writer -->
<!-- PROGRESS: pending -->
<!-- STARTED: ... -->
<!-- UPDATED: ... -->
<!-- HANDOFF LOG: ... -->

```

- **Frontmatter**: 존재 (빈 frontmatter 가능)
- **Work Status Markers**: 존재, `CURRENT_AGENT`가 `overview-writer`
- **본문**: 비어 있음 (Overview 섹션 없음)

### Work Status Markers 확인

#### 실행 조건
```markdown
CURRENT_AGENT: overview-writer
```

**✅ 실행**:
- `CURRENT_AGENT`가 정확히 `overview-writer`

**❌ 건너뛰기**:
- `CURRENT_AGENT`가 다른 값 (예: `concepts-writer`)
- Overview 섹션이 이미 존재하고 개선 요청이 없음

#### 개선 모드 감지
```markdown
<!-- IMPROVEMENT_NEEDED:
- overview-writer: [구체적 개선 사항]
-->
```

- **조건**: `IMPROVEMENT_NEEDED` 필드에 `overview-writer` 항목 존재
- **동작**: 해당 부분만 수정, 개선 항목 제거

### 선행 조건 (Preconditions)
1. 파일이 존재함
2. Work Status Markers 존재
3. `CURRENT_AGENT`가 `overview-writer`
4. Overview 섹션 없음 (또는 개선 요청 있음)

---

## 3. 출력 계약 (Output Contract)

### 생성할 섹션

#### 3.1 Overview 섹션 구조

**필수 구조**:
```markdown
# Overview

[Introduction paragraph(s): 1-2 paragraphs]

## [Subsection 1 Title]

[Content: bullet points or paragraph]

## [Subsection 2 Title]

[Content: bullet points or paragraph]

## [Subsection 3 Title]

[Content: bullet points or paragraph]

[Optional: ## Subsection 4]
```

### 섹션 상세 명세

#### 3.2 Introduction Paragraph
**위치**: `# Overview` 헤더 바로 다음 (빈 줄 후)

**구조**:
- 1-2개 단락
- 3-5문장
- 헤더 없이 바로 시작

**내용 요구사항**:
1. **첫 문장**: 토픽 정의 또는 핵심 개념 설명
2. **후속 문장**: 중요성, 문제 해결, 맥락 제공
3. **기술 용어**: 첫 사용 시 간단한 설명 포함
4. **전제 지식**: 필요시 언급

**예시** (참고: `01-var-problems.md:6`):
```markdown
var는 JavaScript 초창기부터 사용되어온 변수 선언 키워드입니다.
오랫동안 유일한 선택지였지만, 시간이 지나면서 여러 문제점들이 드러났고,
ES6에서 let과 const가 도입된 이유가 되었습니다.
```

#### 3.3 하위 섹션 (Subsections)

**개수**: 3-4개 (최소 3개)

**헤딩 레벨**: `##` (정확히 2개 #)

**섹션 유형 (권장)**:
1. **핵심 특징/문제점 섹션** (필수)
   - 헤더 예시: `## 핵심 특징`, `## 주요 문제점`, `## 핵심 개선 사항`
   - 형식: 번호 목록 (1. 2. 3...) 또는 불릿 포인트 (-)
   - 개수: 4-5개 항목
   - 각 항목: 1-2줄
   - 내용: 기술적 장점 또는 문제점

2. **비교 섹션** (선택, 비교 토픽에만)
   - 헤더 예시: `## 주요 차이점`, `## var vs let`
   - 형식: 불릿 포인트 (번호 없음, 표 ❌)
   - 내용: 구 방식 vs 신 방식 대조

3. **실무 영향/중요성 섹션** (필수)
   - 헤더 예시: `## 실무에서의 영향`, `## 왜 중요한가?`, `## 실무에서의 장점`
   - 형식: 1개 단락 (4-6문장)
   - 내용: 실무 개발 이점, 구체적 use case, 성능/유지보수/코드 품질 측면

4. **학습 목표 섹션** (선택)
   - 헤더 예시: `## 학습 목표`
   - 형식: 1-2개 단락
   - 내용: 이 토픽을 통해 얻을 수 있는 역량

### 출력 형식 규칙

#### 3.4 금지 사항
- ❌ `###` 이상 깊은 헤딩 (오직 `#`과 `##`만)
- ❌ 코드 블록 (Overview는 개념만)
- ❌ 번호 목록 대신 표 사용
- ❌ 외부 파일 참조
- ❌ `<!-- WORK REQUEST: -->` 같은 커스텀 마커
- ❌ 섹션별 마커/주석 (Work Status Markers만)

#### 3.5 형식 규칙
- ✅ 불릿 포인트는 하이픈 (`-`) 사용
- ✅ 각 항목은 1-2줄로 간결하게
- ✅ 친근하지만 전문적인 톤
- ✅ 학습자에게 직접 언급 ❌
- ✅ 설명적 언어 (처방적 ❌)
- ✅ 개념 중심 (구체적 예시 최소화)

### 길이 기준

#### 3.6 섹션 길이
- **전체 Overview 섹션**: 50-100줄
- **Introduction paragraph**: 3-5문장
- **각 불릿 포인트**: 1-2줄
- **실무 영향 단락**: 4-6문장

### Work Status Markers 업데이트

#### 3.7 완료 시 업데이트
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: concepts-writer -->
<!-- PROGRESS: pending -->
<!-- STARTED: [original-time] -->
<!-- UPDATED: [YYYY-MM-DD HH:MM] -->
<!-- HANDOFF LOG:
[previous logs]
[DONE] overview-writer: 완료 - [YYYY-MM-DD HH:MM]
-->
```

**변경사항**:
1. `CURRENT_AGENT`: `overview-writer` → `concepts-writer`
2. `PROGRESS`: `진행중` → `대기중`
3. `UPDATED`: 현재 타임스탬프
4. `HANDOFF LOG`:
   - `[DONE] overview-writer: 완료 - [timestamp]` 추가

### 후행 조건 (Postconditions)
1. `# Overview` 섹션 존재
2. Introduction paragraph 존재
3. 최소 3개 하위 섹션 (`##` 레벨)
4. 코드 블록 없음
5. 50-100줄 길이
6. Work Status Markers 업데이트됨
7. `CURRENT_AGENT`가 `concepts-writer`
8. 다음 Filter 실행 가능 상태

---

## 4. 품질 기준 (Quality Criteria)

### 구조적 요구사항

#### 4.1 헤더 구조
- ✅ `# Overview` 정확히 일치 (대소문자, 공백)
- ✅ Introduction paragraph 바로 뒤에 (빈 줄 1개 후)
- ✅ 하위 섹션 `##` 레벨만 사용
- ✅ 최소 3개 하위 섹션
- ❌ `###`, `####` 등 사용

**파서 요구사항** (참고: `markdownParser.ts:263`):
```typescript
if (line === '# Overview') {
  currentSection = 'overview';
}
```
→ 정확히 `# Overview` 문자열 일치 필수

#### 4.2 Introduction 요구사항
- ✅ 1-2개 단락
- ✅ 3-5문장
- ✅ 헤더 없이 시작 (바로 본문)
- ✅ 첫 문장에 토픽 정의
- ❌ 헤더로 시작 (예: `## Introduction`)

#### 4.3 하위 섹션 요구사항
- ✅ 각 섹션 명확한 목적
- ✅ 불릿 포인트 또는 단락
- ✅ 일관된 형식
- ❌ 표 사용
- ❌ 코드 블록

### 내용적 요구사항

#### 4.4 설명 품질
- ✅ 명확하고 간결한 설명
- ✅ 전문 용어 첫 사용 시 설명
- ✅ 토픽의 "왜"에 집중
- ✅ 실무 관련성 언급
- ❌ 모호한 표현 (예: "좋은", "나쁜")
- ❌ 지나치게 기술적인 세부사항

#### 4.5 톤과 스타일
- ✅ 친근하면서 전문적
- ✅ 설명적 (explanatory)
- ✅ 개념 중심
- ❌ 직접 지시 (예: "~하세요")
- ❌ 학습자에게 직접 언급 (예: "당신은")
- ❌ 처방적 (prescriptive)

### 파싱 요구사항

#### 4.6 파서 호환성
**참고**: `src/utils/markdownParser.ts:289-316`

```typescript
function parseOverview(lines: string[]): string {
  // #### Code: 헤더 처리
  // #### 헤더 건너뛰기
  // 코드 블록 처리 (타이틀 포함)
  return processedContent.trim();
}
```

**호환성 확인**:
- ✅ `# Overview` 정확한 형식
- ✅ `##` 하위 섹션만 사용
- ⚠️ **불일치 발견**:
  - 프롬프트는 코드 블록 금지 (`.claude/agents/overview-writer.md:124`)
  - 파서는 코드 블록 처리 지원 (markdownParser.ts:307-308)
  - **계약 결정**: 코드 블록 금지 유지 (Overview는 개념만)

### 길이 요구사항

#### 4.7 섹션 길이
- ✅ 전체 50-100줄
- ✅ Introduction 3-5문장
- ✅ 각 불릿 1-2줄
- ✅ 실무 단락 4-6문장
- ❌ 50줄 미만 (너무 짧음)
- ❌ 100줄 초과 (너무 김)

### 검증 체크리스트
- [ ] `# Overview` 헤더 존재
- [ ] Introduction paragraph 존재 (1-2단락, 3-5문장)
- [ ] 최소 3개 `##` 레벨 하위 섹션
- [ ] 코드 블록 없음
- [ ] `###` 이상 깊은 헤딩 없음
- [ ] 전체 50-100줄
- [ ] 불릿 포인트 간결 (1-2줄)
- [ ] 실무 관련성 언급
- [ ] Work Status Markers 업데이트
- [ ] `CURRENT_AGENT`가 `concepts-writer`

---

## 5. 오류 처리 (Error Handling)

### 오류 유형

#### 5.1 입력 오류
**오류**: 파일이 존재하지 않음
- **대응**: 오류 메시지 출력, 종료
- **메시지**: `Error: File not found: {file_path}`

**오류**: Work Status Markers 없음
- **대응**: 오류 메시지 출력, 종료
- **메시지**: `Error: Work Status Markers not found`

**오류**: `CURRENT_AGENT`가 `overview-writer`가 아님
- **대응**: 건너뛰기, 로그 출력
- **메시지**: `Skip: CURRENT_AGENT is {current_agent}, not overview-writer`

**오류**: Overview 섹션이 이미 존재 (개선 요청 없음)
- **대응**: 건너뛰기, 로그 출력
- **메시지**: `Skip: Overview section already exists`

#### 5.2 생성 오류
**오류**: Overview 섹션 작성 실패
- **대응**: 오류 메시지 출력, 재시도 (최대 1회)
- **재시도 조건**: 일시적 API 오류

**오류**: 품질 기준 미달 (50줄 미만)
- **대응**: 경고 메시지 출력, 추가 콘텐츠 생성
- **메시지**: `Warning: Overview section too short ({lines} lines)`

#### 5.3 검증 오류
**오류**: 필수 하위 섹션 부족 (3개 미만)
- **대응**: 경고 메시지, 누락 섹션 추가
- **메시지**: `Warning: Only {count} subsections, minimum 3 required`

**오류**: 코드 블록 포함
- **대응**: 경고 메시지, 코드 블록 제거
- **메시지**: `Warning: Code blocks not allowed in Overview, removing`

**오류**: 깊은 헤딩 사용 (`###` 이상)
- **대응**: 경고 메시지, 헤딩 레벨 조정
- **메시지**: `Warning: Deep headings not allowed, converting to ##`

### 재시도 전략
- **재시도 횟수**: 최대 1회
- **재시도 조건**: API 오류, 일시적 네트워크 오류
- **재시도 간격**: 5초

### 실패 시 Work Status Markers 업데이트
```markdown
<!-- CURRENT_AGENT: overview-writer -->
<!-- PROGRESS: 실패 -->
<!-- HANDOFF LOG:
[previous logs]
[ERROR] overview-writer: 실패 - [error message] - [timestamp]
-->
```

---

## 6. 성능 기준 (Performance Criteria)

### 평균 처리 시간
- **추정 범위**: 20-40초
- **측정 항목**:
  - 파일 읽기 및 분석: 2-3초
  - Overview 섹션 생성: 15-30초
  - 검증 및 파일 쓰기: 3-5초

### 출력 크기 범위
- **Overview 섹션**: 50-100줄
- **문자 수**: 약 1,500-3,000자 (한글 기준)
- **단어 수**: 약 200-400 단어 (영어 기준으로 추정)

### 리소스 사용량
- **토큰 소비**: 약 500-1,000 tokens (입력 + 출력)
- **API 호출**: 1-2회 (생성 + 검증/재작성)
- **메모리**: 보통 (전체 파일 로드 + 생성 콘텐츠)

---

## 7. 분석 근거 (Analysis Evidence)

### 프롬프트 파일 분석

**참고 파일**: `.claude/agents/overview-writer.md`

#### Core Mission (line 8-12)
```markdown
Autonomously identify the next content file requiring an Overview section
by examining Work Status Markers, then write a high-quality Overview that
motivates learners and frames the topic effectively.
```
→ **추출**: 역할 명확 (Overview 작성, Work Status Markers 확인)

#### Operational Workflow (line 14-56)
```markdown
### 1. File Discovery and Selection
- Check CURRENT_AGENT: overview-writer
- Check IMPROVEMENT_NEEDED field

### 2. Work Initiation and Marker Updates
- Update PROGRESS to 진행중
```
→ **추출**: 입력 확인 절차, 마커 업데이트 규칙

#### Writing Specifications (line 59-93)
```markdown
### Strict Structure Requirements:
Line 1: # Overview
Line 2: Empty line
Line 3+: Introduction paragraph(s) (1-2 paragraphs)
Followed by: Subsections with ## level headers

### Subsection Composition:
1. Key Features/Problems Section (Required)
2. Comparison Section (Optional)
3. Practical Impact/Importance Section (Required)
```
→ **추출**: 정확한 출력 구조, 필수/선택 섹션

#### Content Quality Standards (line 94-113)
```markdown
### Length Guidelines:
- Total Overview section: 50-100 lines
- Introduction paragraph: 3-5 sentences
- Each bullet point: 1-2 lines
- Practical impact paragraph: 4-6 sentences

### Tone and Style:
- Friendly yet professional
- Don't directly address the learner
```
→ **추출**: 길이 기준, 톤 가이드라인

#### Parser Requirements (line 114-127)
```markdown
### Required Structure:
1. Must start with # Overview header
2. Introduction paragraph(s) immediately after

### Prohibited Elements:
- NO headers deeper than ## (no ### or deeper)
- NO code blocks (Overview is concept-only)
- NO numbered lists (use bullet points only)
```
→ **추출**: 파서 호환성, 금지 사항

#### Example (line 129-148)
```markdown
# Overview

var 키워드는 JavaScript에서 변수를 선언하는 초기 방식입니다. ...

## 핵심 문제점
- ...

## 실무에서의 영향
...
```
→ **추출**: 실제 출력 예시

#### Handoff Rules (line 163-200)
```markdown
### On Work Completion:
1. Change CURRENT_AGENT to "concepts-writer"
2. Change PROGRESS to "대기중"
3. Add completion record to HANDOFF LOG
```
→ **추출**: 핸드오프 절차

### 파서 테스트 분석

**참고 파일**: `test/test-overview.mjs` → `src/utils/markdownParser.ts`

#### splitIntoSections() (line 236-287)
```typescript
if (line === '# Overview') {
  currentSection = 'overview';
  continue;
}
```
→ **추출**: `# Overview` 정확한 문자열 일치 필요

#### parseOverview() (line 289-316)
```typescript
// Extract code titles from #### Code: headers
if (line.startsWith('#### Code: ')) {
  lastCodeTitle = line.replace('#### Code: ', '').trim();
}
// Skip other #### headers
else if (line.startsWith('#### ')) {
  // Skip
}
// Process code blocks with titles
else if (line.startsWith('```') && lastCodeTitle) {
  processedContent += `[TITLE:${lastCodeTitle}]\n${line}\n`;
}
```
→ **불일치 발견**: 파서는 코드 블록 처리 지원, 프롬프트는 금지
→ **계약 결정**: 코드 블록 금지 유지 (개념 중심)

### 산출물 샘플 분석

**참고 파일**: `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md:4-23`

```markdown
# Overview

var는 JavaScript 초창기부터 사용되어온 변수 선언 키워드입니다. ...

## var의 주요 문제점
1. **함수 스코프**: 블록이 아닌 함수 단위로만 스코프가 생성
2. **호이스팅 혼란**: ...

## 왜 이런 문제들이 중요한가?
- **버그의 온상**: ...

## 학습 목표
각 문제점을 실습을 통해 ...
```

→ **확인**:
- `# Overview` 정확한 형식
- Introduction paragraph 존재
- 3개 하위 섹션 (`##` 레벨)
- 번호 목록 + 불릿 포인트 혼용
- 코드 블록 없음
- 약 20줄 (이 샘플은 짧음)

**참고 파일**: `public/content/ko/javascript-core-concepts/01-variables/02-let-vs-var.md:9-29`

```markdown
# Overview

ES6에서 도입된 let은 ...

## let의 핵심 개선 사항
1. **블록 스코프**: ...

## var vs let 주요 차이점
- **스코프**: ...

## 실무에서의 장점
블록 스코프를 통한 ...
```

→ **확인**:
- 4개 하위 섹션 (패턴 확인)
- 번호 목록 + 불릿 포인트 + 단락 혼용
- 일관된 구조

### 제대로 된 계약 정의

#### 개선 사항

1. **명확성**:
   - "concise, engaging Overview" → 구체적인 구조와 길이 명시
   - 3-4개 하위 섹션, 각 섹션 유형과 형식 명시
   - Introduction paragraph 정확한 요구사항 (3-5문장)

2. **완전성**:
   - 필수 섹션 vs 선택 섹션 명확화
   - 불릿 포인트, 번호 목록, 단락 각각 허용 조건 명시
   - Work Status Markers 업데이트 정확한 절차

3. **검증 가능성**:
   - 10개 체크리스트 항목
   - 각 항목 명확한 ✅/❌ 기준
   - 길이 범위 (50-100줄)

4. **불일치 해결**:
   - 프롬프트 vs 파서 불일치 명시
   - 계약 결정: 코드 블록 금지 유지
   - 근거: Overview는 개념 중심

---

## 8. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2025-10-13 | 초기 계약 정의 |

---

## 9. 참고 문서

- `.claude/agents/overview-writer.md` (프롬프트 파일)
- `.claude/handoff-guide.md` (Work Status Markers 명세)
- `test/test-overview.mjs` (파서 테스트)
- `src/utils/markdownParser.ts:289-316` (parseOverview 함수)
- `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md` (샘플 1)
- `public/content/ko/javascript-core-concepts/01-variables/02-let-vs-var.md` (샘플 2)
