# Unit 3: Agent Prompts 개선 - DDD 경량화 도메인 설계

**작성일**: 2025-10-17
**작성자**: AI System Architect
**버전**: 1.0
**상태**: 진행 중 (Section 1 작성 중)

---

## Section 1: 프롬프트 도메인 개요 (Prompt Domain Overview)

### 1.1 프롬프트의 역할 정의

#### 1.1.1 Filter 실행 명세로서의 프롬프트

**정의**: 에이전트 프롬프트는 Filter의 실행 로직을 정의하는 Published Language입니다.

**Pipe & Filter 아키텍처 관점**:
- **Pipe**: Work Status Markers (마크다운 파일 상단 HTML 주석)
- **Filter**: 에이전트 (콘텐츠 생성 단위)
- **Filter 명세**: 에이전트 프롬프트 (`.claude/agents/*.md`)

**프롬프트의 핵심 책임**:
1. **입력 명세 (Input Specification)**: Filter가 읽어야 할 데이터 정의
2. **처리 로직 (Processing Logic)**: Filter가 수행할 작업 지시
3. **출력 명세 (Output Specification)**: Filter가 생성할 데이터 정의
4. **품질 기준 (Quality Standards)**: 출력물이 만족해야 할 조건

**비유**:
```
프롬프트 : 에이전트 = 악보 : 연주자
```
- 악보(프롬프트)는 연주자(에이전트)가 어떻게 연주(작업)해야 하는지 정확히 기술
- 악보가 명확하면 누구든지 동일한 연주 가능 (재현 가능성)
- 악보가 모호하면 연주자마다 다른 해석 (일관성 결여)

#### 1.1.2 Published Language로서의 프롬프트

**Published Language 정의** (DDD):
> "A well-documented shared language that describes an external system or data format, used for integration between bounded contexts."

**프롬프트가 Published Language인 이유**:
1. **공개된 인터페이스**: 모든 에이전트가 따라야 할 표준 정의
2. **문서화된 언어**: 프롬프트 자체가 에이전트의 명세 문서
3. **컨텍스트 간 통합**: Agent Prompts Context ↔ Orchestration Context 통신 수단
4. **버전 관리**: 프롬프트 변경 = API 변경으로 취급

**Published Language의 구성 요소**:
- **용어 정의 (Terminology)**: CURRENT_AGENT, HANDOFF LOG, Precondition, Postcondition
- **형식 표준 (Format Standards)**: Work Status Markers 형식, HANDOFF LOG 엔트리 형식
- **프로토콜 (Protocol)**: Handoff Protocol, Error Handling Protocol
- **계약 (Contract)**: Input Contract, Output Contract

**Unit 2와의 관계**:
```
Unit 2 Filter Contracts (계약) → Unit 3 Agent Prompts (프롬프트)
   "무엇을 해야 하는가"  →  "어떻게 해야 하는가"
```

#### 1.1.3 자기 문서화 (Self-Documenting) 에이전트

**자기 문서화 원칙**:
> "프롬프트만 읽으면 에이전트가 무엇을 하는지, 어떻게 동작하는지 100% 이해 가능해야 한다."

**자기 문서화의 장점**:
1. **외부 문서 불필요**: 별도의 API 문서나 사용 설명서 불필요
2. **신뢰할 수 있는 단일 출처 (Single Source of Truth)**: 프롬프트가 유일한 정보원
3. **버전 관리 간소화**: 프롬프트 변경 = 동작 변경 = 문서 업데이트 (동시 발생)
4. **온보딩 시간 단축**: 새로운 개발자가 프롬프트만 읽으면 이해 가능

**자기 문서화를 위한 프롬프트 구성 요소**:
- **Role & Responsibility**: 에이전트의 역할 명확히 정의
- **Input Contract**: 무엇을 입력받는가?
- **Output Contract**: 무엇을 출력하는가?
- **Execution Instructions**: 어떤 순서로 작업하는가?
- **Critical Constraints**: 절대 하지 말아야 할 것 (DO NOT)
- **Error Handling**: 오류 시 어떻게 처리하는가?
- **Examples**: 구체적인 입출력 예시

**현재 프롬프트의 자기 문서화 수준 평가**:
| 에이전트 | 자기 문서화 수준 | 개선 필요 사항 |
|---------|----------------|----------------|
| content-initiator | ⭐⭐⭐ (양호) | I/O Contract 명시 필요 |
| overview-writer | ⭐⭐⭐⭐ (우수) | Preconditions 체크리스트화 필요 |
| concepts-writer | ⭐⭐⭐⭐⭐ (탁월) | 현재 수준 유지 |
| visualization-writer | ⭐⭐⭐⭐ (우수) | Error Handling 보완 필요 |
| practice-writer | ⭐⭐⭐⭐ (우수) | Preconditions 명시 필요 |
| quiz-writer | ⭐⭐⭐⭐ (우수) | Error Handling 보완 필요 |
| content-validator | ⭐⭐⭐ (양호) | I/O Contract 체계화 필요 |

---

### 1.2 프롬프트 아키텍처 원칙

#### 1.2.1 단일 책임 원칙 (Single Responsibility Principle)

**원칙**:
> "한 에이전트는 하나의 명확한 책임만 가져야 한다."

**적용 사례**:
- ✅ **overview-writer**: Overview 섹션만 작성
- ✅ **concepts-writer**: Core Concepts 섹션만 작성
- ✅ **visualization-writer**: React 컴포넌트만 생성
- ❌ **잘못된 예**: "overview-concepts-writer" (2개 책임 혼재)

**단일 책임 원칙의 이점**:
1. **명확한 책임 경계**: 각 에이전트가 무엇을 해야 하는지 명확
2. **독립적 개선 가능**: 한 에이전트 수정 시 다른 에이전트 영향 최소화
3. **재사용성**: 단일 책임 에이전트는 다른 파이프라인에서도 재사용 가능
4. **테스트 용이성**: 입출력이 명확하여 단위 테스트 작성 쉬움

**Claude Code 공식 가이드와의 정합성**:
> "Create focused subagents with single, clear responsibilities rather than trying to make one subagent do everything."

#### 1.2.2 명시적 계약 (Explicit Contract)

**원칙**:
> "에이전트의 입출력은 명시적으로 정의되어야 하며, 암묵적 가정이 없어야 한다."

**명시적 계약의 구성 요소**:
1. **Input Contract**:
   - File State: 어떤 파일이 필요한가?
   - Work Status Markers: CURRENT_AGENT는 무엇이어야 하는가?
   - Section Dependencies: 어떤 섹션이 이미 존재해야 하는가?

2. **Output Contract**:
   - File Modifications: 어떤 섹션을 추가/수정하는가?
   - Work Status Markers Updates: CURRENT_AGENT를 무엇으로 바꾸는가?
   - Content Guarantees: 출력물의 품질 기준은 무엇인가?

**암묵적 가정 제거의 중요성**:
```markdown
❌ 나쁜 예 (암묵적 가정):
"Overview 섹션을 작성하세요."
→ 질문: Overview가 어떤 형식이어야 하는지? 길이는? 필수 하위 섹션은?

✅ 좋은 예 (명시적 계약):
"Overview 섹션을 작성하세요.
- 형식: # Overview (H1 헤더)
- 길이: 50-100줄
- 필수 하위 섹션: ## 핵심 특징, ## 실무에서의 영향
- 금지 사항: 코드 블록 사용 금지"
```

**Unit 2 계약과의 통합**:
- Unit 2 계약이 "무엇을 (What)" 정의
- Unit 3 프롬프트가 "어떻게 (How)" 정의
- 프롬프트는 Unit 2 계약을 요약하고 참조

#### 1.2.3 오류 조기 발견 (Fail-Fast)

**원칙**:
> "Precondition 실패 시 즉시 중단하고 명확한 오류 메시지를 출력한다."

**Fail-Fast 전략의 3단계**:
1. **Precondition 검증**: 작업 시작 전 모든 조건 확인
2. **즉시 중단**: 조건 불만족 시 작업 수행하지 않고 즉시 종료
3. **명확한 오류**: 무엇이 잘못되었는지, 어떻게 고쳐야 하는지 명시

**Fail-Fast vs Fail-Safe 비교**:
| 구분 | Fail-Fast | Fail-Safe |
|------|-----------|-----------|
| **정의** | 오류 발견 즉시 중단 | 오류 무시하고 계속 진행 |
| **장점** | 버그 조기 발견, 명확한 오류 지점 | 시스템 중단 없음 |
| **단점** | 시스템 중단 발생 | 버그 은폐, 디버깅 어려움 |
| **적용** | **콘텐츠 생성 파이프라인 (채택)** | 미션 크리티컬 시스템 |

**Fail-Fast 적용 예시**:
```markdown
## Precondition 검증

if CURRENT_AGENT != "overview-writer":
    ERROR: "Precondition failed: CURRENT_AGENT is '{actual}', expected 'overview-writer'"
    Add HANDOFF LOG: [FAILURE] overview-writer | Precondition failed | timestamp
    Set STATUS: FAILED
    EXIT 1
```

**Unit 3 Inception 문서 결정 (Question 2)**:
> "A - 오류 발생 시 즉시 종료 (Fail-Fast)"

#### 1.2.4 일관된 용어 (Ubiquitous Language)

**원칙**:
> "모든 프롬프트에서 동일한 용어를 동일한 의미로 사용한다."

**Ubiquitous Language 목록** (Unit 1에서 정의):
| 용어 | 정의 | 사용 예시 |
|------|------|----------|
| **Pipe** | 에이전트 간 데이터 전달 통로 | Work Status Markers |
| **Filter** | 데이터를 처리하는 단위 | 에이전트 (overview-writer 등) |
| **CURRENT_AGENT** | 현재 작업 중인 에이전트 | CURRENT_AGENT: overview-writer |
| **HANDOFF LOG** | 파이프라인 실행 이력 | [DONE] overview-writer \| ... |
| **Precondition** | 작업 시작 전 검증 조건 | CURRENT_AGENT == "overview-writer" |
| **Postcondition** | 작업 완료 후 보장 사항 | # Overview 섹션 생성됨 |
| **Handoff** | 다음 에이전트로 작업 전달 | CURRENT_AGENT 업데이트 |
| **Fail-Fast** | 오류 발견 즉시 중단 | Precondition 실패 시 EXIT 1 |

**용어 일관성 검증 방법**:
- 프롬프트 검증 스크립트에서 용어 일관성 체크
- 예: "대기중" vs "PENDING" → "PENDING"으로 통일

---

### 1.3 프롬프트와 계약의 관계

#### 1.3.1 계약 (Contract): What (무엇을 해야 하는가)

**Unit 2 Filter Contracts의 역할**:
- **인터페이스 정의**: 에이전트가 "무엇을" 해야 하는지 정의
- **입출력 명세**: 에이전트가 "무엇을" 받고 "무엇을" 생성하는지
- **품질 기준**: 출력물이 "무엇을" 만족해야 하는지

**계약 문서의 구성** (Unit 2):
```markdown
## Input Contract
- File State: 필요한 파일 및 섹션
- Work Status Markers: CURRENT_AGENT, STATUS 조건
- Section Dependencies: 의존하는 이전 섹션

## Output Contract
- File Modifications: 생성/수정할 섹션
- Work Status Markers Updates: 업데이트할 마커 필드
- Content Guarantees: 품질 보장 사항

## Preconditions
1. CURRENT_AGENT == "overview-writer"
2. STATUS == PENDING or IN_PROGRESS
3. frontmatter exists

## Postconditions
1. # Overview section created
2. CURRENT_AGENT == "concepts-writer"
3. HANDOFF LOG contains [DONE] entry
```

#### 1.3.2 프롬프트 (Prompt): How (어떻게 해야 하는가)

**Unit 3 Agent Prompts의 역할**:
- **실행 지시**: 에이전트가 "어떻게" 작업해야 하는지 지시
- **작업 순서**: "어떤 순서로" 작업을 수행하는지
- **제약 사항**: "무엇을 하지 말아야 하는지" (DO NOT)

**프롬프트의 구성** (Unit 3):
```markdown
## Role & Responsibility
에이전트의 역할: Overview 섹션 작성

## Input Contract (Unit 2 요약)
- CURRENT_AGENT: overview-writer
- STATUS: PENDING or IN_PROGRESS
- 참조: `contracts/overview-writer-contract.md`

## Output Contract (Unit 2 요약)
- 생성 섹션: # Overview
- CURRENT_AGENT 업데이트: concepts-writer
- 참조: `contracts/overview-writer-contract.md`

## Execution Instructions
### Step 1: Validate Preconditions
- [ ] CURRENT_AGENT == "overview-writer" 확인
- [ ] frontmatter 존재 확인

### Step 2: Generate Overview Section
- Introduction paragraph 작성 (3-5 sentences)
- ## 핵심 특징 작성 (4-5 bullet points)
- ## 실무에서의 영향 작성 (4-6 sentences)

### Step 3: Update Work Status Markers
- [ ] HANDOFF LOG에 [DONE] 엔트리 추가
- [ ] CURRENT_AGENT를 "concepts-writer"로 변경
- [ ] UPDATED 타임스탬프 갱신

### Step 4: Validate Postconditions
- [ ] # Overview 섹션 존재 확인
- [ ] 섹션 길이 50-100줄 확인

## Critical Constraints (DO NOT)
- 다른 섹션 (Core Concepts, Practice, Quiz) 수정 금지
- 코드 블록 사용 금지
- Work Status Markers 외부에 마커 추가 금지
```

#### 1.3.3 계약 → 프롬프트 변환 패턴

**변환 원칙**:
1. **요약 + 참조**: 계약의 핵심 내용만 요약하고 상세 내용은 계약 문서 참조
2. **체크리스트화**: Preconditions/Postconditions를 실행 가능한 체크리스트로 변환
3. **단계화**: 작업을 순차적 단계로 분해 (Step 1, Step 2, ...)
4. **구체화**: 추상적 요구사항을 구체적 지시로 변환

**변환 예시 1: Preconditions**
```markdown
Unit 2 계약:
## Preconditions
1. CURRENT_AGENT == "overview-writer"
2. STATUS == PENDING or IN_PROGRESS
3. frontmatter exists

↓ 변환 ↓

Unit 3 프롬프트:
### Step 1: Validate Preconditions
- [ ] Check CURRENT_AGENT matches "overview-writer"
  - If not: Add [FAILURE] to HANDOFF LOG, EXIT 1
- [ ] Check STATUS is PENDING or IN_PROGRESS
  - If not: Add [FAILURE] to HANDOFF LOG, EXIT 1
- [ ] Verify frontmatter exists
  - If not: Add [FAILURE] to HANDOFF LOG, EXIT 1
```

**변환 예시 2: Output Contract**
```markdown
Unit 2 계약:
## Output Contract
- File Modifications: Add # Overview section
- Content Guarantees: 50-100 lines, no code blocks

↓ 변환 ↓

Unit 3 프롬프트:
### Step 2: Generate Overview Section
Write the # Overview section with:
- Introduction paragraph (3-5 sentences)
- ## 핵심 특징 subsection (4-5 bullets)
- ## 실무에서의 영향 subsection (4-6 sentences)

Quality Standards:
- Total length: 50-100 lines
- NO code blocks
- NO headers deeper than ##
```

**변환 매핑 테이블**:
| Unit 2 계약 요소 | Unit 3 프롬프트 요소 | 변환 방법 |
|------------------|---------------------|----------|
| Input Contract | Precondition 체크리스트 | 검증 단계로 변환 |
| Output Contract | Execution Instructions | 작업 단계로 변환 |
| Preconditions | Step 1: Validate Preconditions | 체크리스트화 |
| Postconditions | Step 4: Validate Postconditions | 검증 단계로 변환 |
| Content Guarantees | Quality Standards | 품질 기준으로 변환 |
| Error Handling | Error Handling 섹션 | Fail-Fast 지시로 변환 |
| Examples | Examples 섹션 | 그대로 포함 또는 확장 |

---

### 1.4 프롬프트 품질 기준

#### 1.4.1 완전성 (Completeness)

**정의**: 프롬프트에 에이전트가 작업하는 데 필요한 모든 정보가 포함되어 있는가?

**완전성 체크리스트**:
- [ ] **Role & Responsibility**: 에이전트 역할 명확히 정의됨
- [ ] **Input Contract**: 무엇을 입력받는지 명시됨
- [ ] **Output Contract**: 무엇을 출력하는지 명시됨
- [ ] **Execution Instructions**: 작업 순서가 단계별로 기술됨
- [ ] **Preconditions**: 작업 시작 전 검증 조건 명시됨
- [ ] **Postconditions**: 작업 완료 후 보장 사항 명시됨
- [ ] **Critical Constraints**: DO/DO NOT 명시됨
- [ ] **Error Handling**: 오류 시나리오 및 처리 방법 명시됨
- [ ] **Quality Standards**: 출력물 품질 기준 명시됨
- [ ] **Examples**: 입출력 예시 포함됨
- [ ] **References**: 관련 문서 링크 포함됨

**불완전한 프롬프트의 문제점**:
- 에이전트가 추측하여 작동 → 일관성 결여
- 암묵적 가정 → 버그 발생
- 디버깅 어려움 → 유지보수 비용 증가

#### 1.4.2 명확성 (Clarity)

**정의**: 프롬프트가 모호하지 않고 명확한가?

**명확성 기준**:
- **용어 일관성**: 동일한 개념에 동일한 용어 사용
- **구체성**: 추상적 표현 대신 구체적 지시
- **모호성 제거**: 해석의 여지가 없는 표현

**명확성 개선 예시**:
```markdown
❌ 모호한 표현:
"Overview를 잘 작성하세요."

✅ 명확한 표현:
"Overview 섹션을 다음 구조로 작성하세요:
- # Overview (H1 헤더)
- Introduction paragraph (3-5 sentences)
- ## 핵심 특징 (4-5 bullet points)
- ## 실무에서의 영향 (4-6 sentences)
- 총 길이: 50-100줄"
```

#### 1.4.3 일관성 (Consistency)

**정의**: 7개 프롬프트 간 구조, 용어, 스타일이 일관되는가?

**일관성 체크 항목**:
- [ ] **구조 일관성**: 모든 프롬프트가 동일한 섹션 구조 사용
- [ ] **용어 일관성**: Ubiquitous Language 사용
- [ ] **형식 일관성**: 마커 형식, 타임스탬프 형식 동일
- [ ] **스타일 일관성**: 지시 어조, 문체 동일

**현재 프롬프트의 일관성 문제**:
| 문제 | 현재 상태 | 목표 |
|------|-----------|------|
| HANDOFF LOG 이벤트 | `[WAITING]`, `[DONE]` | Unit 1: `START`, `DONE`, `IMPROVE`, `FAILURE`, `SKIP`, `COMPLETE` |
| Precondition 표현 | 일부만 명시 | 모든 프롬프트에 체크리스트 형식으로 명시 |
| Error Handling | 일부 누락 | 모든 프롬프트에 Fail-Fast 전략 명시 |

#### 1.4.4 검증 가능성 (Verifiability)

**정의**: 프롬프트가 올바르게 작성되었는지 자동으로 검증 가능한가?

**검증 가능한 요소**:
1. **Frontmatter 필드**: name, version, description, tools 존재 확인
2. **필수 섹션**: Role, Input Contract, Output Contract, Execution Instructions 존재 확인
3. **용어 일관성**: Ubiquitous Language 사용 확인
4. **프롬프트 길이**: 200-400줄 범위 확인 (Question 2 답변)

**자동 검증 스크립트 명세** (Section 9에서 상세 설계):
```bash
# scripts/lib/validate-prompts.sh
validate_prompt() {
    local prompt_file="$1"

    # Frontmatter 검증
    check_frontmatter_fields "$prompt_file"

    # 필수 섹션 검증
    check_required_sections "$prompt_file"

    # 길이 검증
    check_prompt_length "$prompt_file" 200 400

    # 용어 일관성 검증
    check_ubiquitous_language "$prompt_file"
}
```

---

## Section 1 완료

**작성 내용 요약**:
- 1.1 프롬프트의 역할 정의 (Filter 명세, Published Language, 자기 문서화)
- 1.2 프롬프트 아키텍처 원칙 (단일 책임, 명시적 계약, Fail-Fast, Ubiquitous Language)
- 1.3 프롬프트와 계약의 관계 (What vs How, 변환 패턴)
- 1.4 프롬프트 품질 기준 (완전성, 명확성, 일관성, 검증 가능성)

**다음 섹션**: Section 2 - 프롬프트 템플릿 구조

---

## Section 2: 프롬프트 템플릿 구조 (Prompt Template Structure)

### 2.1 YAML Frontmatter 구조

#### 2.1.1 Frontmatter 필드 정의

**표준 Frontmatter 형식** (Claude Code):
```yaml
---
name: agent-name
version: semantic-version
description: One-line agent description
tools: [Tool1, Tool2, ...]
model: model-name
---
```

**각 필드 상세**:

| 필드 | 타입 | 필수 | 설명 | 예시 |
|------|------|------|------|------|
| **name** | string | ✅ | 에이전트 고유 식별자, 소문자+하이픈 | `overview-writer` |
| **version** | string | ✅ | 시맨틱 버저닝 (MAJOR.MINOR.PATCH) | `5.0.0` |
| **description** | string | ✅ | 에이전트의 역할을 한 문장으로 설명 | `When content files need motivating Overview sections` |
| **tools** | array | ✅ | 사용 가능한 Claude Code 도구 목록 | `[Read, MultiEdit, Grep]` |
| **model** | string | ⚪ | 사용할 AI 모델 (기본값: sonnet) | `sonnet` 또는 `opus` |

#### 2.1.2 name 필드 규칙

**명명 규칙**:
- **패턴**: `[a-z-]+` (소문자, 하이픈만 허용)
- **형식**: `{역할}-{타입}` (예: `overview-writer`, `content-validator`)
- **일관성**: Unit 1, Unit 2에서 사용하는 에이전트 이름과 100% 일치해야 함

**현재 7개 에이전트 이름**:
1. `content-initiator` - 콘텐츠 파일 초기화
2. `overview-writer` - Overview 섹션 작성
3. `concepts-writer` - Core Concepts 섹션 작성
4. `visualization-writer` - React 시각화 컴포넌트 생성
5. `practice-writer` - Practice 섹션 (Patterns + Experiments) 작성
6. `quiz-writer` - Quiz 섹션 작성
7. `content-validator` - 콘텐츠 품질 검증 및 개선 지시

**name 필드 검증**:
```bash
# 유효한 name인지 검증
if [[ ! "$name" =~ ^[a-z-]+$ ]]; then
    echo "ERROR: Invalid name format. Use lowercase letters and hyphens only."
    exit 1
fi
```

#### 2.1.3 version 필드 규칙

**시맨틱 버저닝 규칙** (SemVer):
- **MAJOR**: Breaking Change (프롬프트 구조 변경, 계약 변경)
- **MINOR**: 새 기능 추가 (하위 호환)
- **PATCH**: 버그 수정 (하위 호환)

**버전 업그레이드 시나리오**:
| 변경 유형 | 예시 | 버전 변경 |
|-----------|------|----------|
| Breaking Change | I/O Contract 변경, 필수 섹션 추가 | `5.0.0` → `6.0.0` |
| 새 기능 추가 | 선택적 섹션 추가, Quality Standards 보강 | `5.0.0` → `5.1.0` |
| 버그 수정 | 오타 수정, 명확성 개선 | `5.0.0` → `5.0.1` |

**현재 프롬프트 버전**:
- content-initiator: 버전 없음 → `1.0.0`으로 추가 필요
- overview-writer: `5.0.0`
- concepts-writer: `6.0.0`
- visualization-writer: `1.0.0`
- practice-writer: `7.0.0`
- quiz-writer: `3.0.0`
- content-validator: `1.0.0`

#### 2.1.4 description 필드 작성 가이드

**작성 원칙**:
1. **간결성**: 한 문장 (10-15 단어)
2. **명확성**: 에이전트가 "무엇을" 하는지 명시
3. **일관성**: "When ... need ..." 패턴 사용 (현재 패턴 유지)

**description 패턴**:
```
"When {대상} need {결과물} to {목적}"
```

**현재 description 분석 및 개선**:
| 에이전트 | 현재 description | 평가 | 개선안 |
|---------|-----------------|------|--------|
| content-initiator | "Initialize new content files or restart interrupted content generation pipeline" | ✅ 명확 | 유지 |
| overview-writer | "When content files need motivating Overview sections to frame learning topics" | ✅ 패턴 일치 | 유지 |
| concepts-writer | "When concepts need 3-level difficulty explanations (Easy/Normal/Expert) and visualizations" | ✅ 패턴 일치 | 유지 |
| visualization-writer | "When abstract concepts need interactive visualizations for better understanding" | ✅ 패턴 일치 | 유지 |
| practice-writer | "When learners need hands-on Code Patterns and interactive Experiments to apply concepts" | ✅ 패턴 일치 | 유지 |
| quiz-writer | "When learning outcomes need validation through diverse quiz question types" | ✅ 패턴 일치 | 유지 |
| content-validator | "When completed content requires final quality validation before marking as complete" | ✅ 패턴 일치 | 유지 |

#### 2.1.5 tools 필드 설정

**사용 가능한 Claude Code 도구**:
- `Read`: 파일 읽기
- `Write`: 파일 생성 (새 파일만)
- `Edit`: 파일 편집 (기존 파일)
- `MultiEdit`: 여러 파일 동시 편집
- `Grep`: 콘텐츠 검색
- `Glob`: 파일 패턴 매칭
- `Bash`: 쉘 명령 실행

**에이전트별 최소 권한 원칙**:
| 에이전트 | 필요 도구 | 이유 |
|---------|----------|------|
| content-initiator | `[Read, Edit]` | 파일 읽기 + Work Status Markers 초기화 |
| overview-writer | `[Read, MultiEdit]` | 파일 읽기 + Overview 섹션 + WSM 업데이트 |
| concepts-writer | `[Read, MultiEdit, Grep]` | 파일 읽기 + Concepts 섹션 + 자동 파일 탐색 |
| visualization-writer | `[Read, MultiEdit, Grep]` | 파일 읽기 + React 컴포넌트 생성 + index.ts 업데이트 + 자동 탐색 |
| practice-writer | `[Read, MultiEdit, Grep]` | 파일 읽기 + Practice 섹션 + 자동 탐색 |
| quiz-writer | `[Read, MultiEdit, Grep]` | 파일 읽기 + Quiz 섹션 + 자동 탐색 |
| content-validator | `[Read, MultiEdit, Grep]` | 파일 읽기 + VALIDATION_SCORE + IMPROVEMENT_NEEDED + 자동 탐색 |

**tools 필드 최적화 원칙** (Claude Code Best Practice):
> "Limit tool access to only necessary capabilities"

#### 2.1.6 Unit 2 계약 frontmatter와의 관계

**Unit 2 계약 frontmatter 예시**:
```yaml
---
agent_id: overview-writer
version: 1.0
dependencies: [content-initiator]
bounded_context: Overview Section Generation
---
```

**Unit 3 프롬프트 frontmatter 예시**:
```yaml
---
name: overview-writer
version: 5.0.0
description: When content files need motivating Overview sections to frame learning topics
tools: [Read, MultiEdit]
model: sonnet
---
```

**필드 매핑**:
| Unit 2 계약 필드 | Unit 3 프롬프트 필드 | 관계 |
|------------------|---------------------|------|
| `agent_id` | `name` | 동일한 값 (에이전트 식별자) |
| `version` | `version` | 독립적 (계약 버전 ≠ 프롬프트 버전) |
| `dependencies` | (본문에서 Section Dependencies로 기술) | 프롬프트 본문 Input Contract에 포함 |
| `bounded_context` | (본문에서 Role & Responsibility로 기술) | 프롬프트 본문 첫 섹션에 포함 |

---

### 2.2 Markdown 본문 섹션 구조

#### 2.2.1 표준 섹션 순서

**모든 에이전트 프롬프트가 따라야 할 섹션 순서**:

1. **Role & Responsibility** (필수)
2. **Input Contract** (필수)
3. **Output Contract** (필수)
4. **Execution Instructions** (필수)
5. **Critical Constraints** (필수)
6. **Error Handling** (필수)
7. **Handoff Protocol** (필수)
8. **Quality Standards** (필수)
9. **Examples** (권장)
10. **References** (권장)

**섹션 순서의 의미**:
- 1-3: **계약 명세** (무엇을 받고, 무엇을 생성하는가)
- 4: **실행 로직** (어떻게 작업하는가)
- 5-6: **제약 및 오류 처리** (무엇을 하지 말고, 오류 시 어떻게 하는가)
- 7-8: **핸드오프 및 품질** (다음 에이전트로 어떻게 전달하고, 품질은 무엇인가)
- 9-10: **예시 및 참조** (구체적 사례 및 관련 문서)

#### 2.2.2 섹션별 상세 구조

##### Section 1: Role & Responsibility (필수)

**목적**: 에이전트의 역할과 책임을 명확히 정의

**내용**:
- 에이전트가 담당하는 작업 (1-2 문장)
- Bounded Context 명시 (DDD)
- 다른 에이전트와의 차이점 (필요 시)

**템플릿**:
```markdown
## Role & Responsibility

**Primary Role**: [에이전트의 주요 역할]

**Bounded Context**: [에이전트가 담당하는 Context]

**Scope**:
- [에이전트가 하는 일 1]
- [에이전트가 하는 일 2]
- [에이전트가 하는 일 3]
```

**예시 (overview-writer)**:
```markdown
## Role & Responsibility

**Primary Role**: Generate the Overview section that motivates learners and introduces the learning topic with key features and practical impact.

**Bounded Context**: Overview Section Generation

**Scope**:
- Create # Overview header and structure
- Write introduction paragraph explaining topic and why it matters
- List key features or problems as bullet points
- Explain practical impact in real-world development
```

##### Section 2: Input Contract (필수)

**목적**: 에이전트가 작업을 시작하기 위해 필요한 입력 정의

**내용** (Unit 2 계약에서 요약):
1. **File State**: 필요한 파일 및 섹션
2. **Work Status Markers**: CURRENT_AGENT, STATUS 조건
3. **Section Dependencies**: 이전 에이전트 출력물

**템플릿**:
```markdown
## Input Contract

### File State
- Required Files: [필요한 파일 목록]
- File Encoding: UTF-8
- Existing Sections: [존재해야 할 섹션]

### Work Status Markers
- CURRENT_AGENT: [에이전트 이름]
- STATUS: PENDING (normal flow) or IN_PROGRESS (improvement mode)
- HANDOFF LOG: Contains [이전 엔트리 조건]

### Section Dependencies
- [의존하는 섹션 1] (by [이전 에이전트])
- [의존하는 섹션 2] (by [이전 에이전트])

**참조**: `docs/aidlc-docs/specifications/contracts/[agent-name]-contract.md`
```

**Question 1 답변 반영**: **B (요약 + 참조)**
- 핵심 내용만 요약
- 상세 내용은 Unit 2 계약 문서 참조

##### Section 3: Output Contract (필수)

**목적**: 에이전트가 생성할 출력 정의

**내용** (Unit 2 계약에서 요약):
1. **File Modifications**: 추가/수정할 섹션
2. **Work Status Markers Updates**: 업데이트할 마커 필드
3. **Content Guarantees**: 출력물 품질 보장

**템플릿**:
```markdown
## Output Contract

### File Modifications
- Modified Files: [수정할 파일]
- New Sections: [추가할 섹션]
- Section Structure:
  \`\`\`markdown
  [섹션 구조 예시]
  \`\`\`

### Work Status Markers Updates
- CURRENT_AGENT: [다음 에이전트 이름]
- STATUS: [업데이트할 STATUS]
- UPDATED: Current timestamp (ISO 8601)
- HANDOFF LOG: Add `[EVENT_TYPE] [agent-name] | [message] | [timestamp]`

### Content Guarantees
- [보장 사항 1]
- [보장 사항 2]
- [보장 사항 3]

**참조**: `docs/aidlc-docs/specifications/contracts/[agent-name]-contract.md`
```

##### Section 4: Execution Instructions (필수)

**목적**: 에이전트가 작업을 수행하는 단계별 지시

**구조**: 4단계 표준 워크플로우
1. **Step 1**: Validate Preconditions
2. **Step 2**: Perform Work
3. **Step 3**: Update Work Status Markers
4. **Step 4**: Validate Postconditions

**템플릿**:
```markdown
## Execution Instructions

### Step 1: Validate Preconditions
- [ ] Check CURRENT_AGENT matches "[agent-name]"
- [ ] Check STATUS is PENDING or IN_PROGRESS
- [ ] Verify [필수 입력 조건]
- [ ] If any precondition fails: Add [FAILURE] to HANDOFF LOG, EXIT 1

### Step 2: Perform Work
[에이전트별 구체적 작업 단계]
- [작업 1]
- [작업 2]
- [작업 3]

### Step 3: Update Work Status Markers
- [ ] Add HANDOFF LOG entry: `[DONE] [agent-name] | [message] | [timestamp]`
- [ ] Update CURRENT_AGENT to "[next-agent]"
- [ ] Update UPDATED timestamp (ISO 8601 format)
- [ ] (If improvement mode) Remove [agent-name] from IMPROVEMENT_NEEDED

### Step 4: Validate Postconditions
- [ ] Verify [출력 섹션] exists
- [ ] Verify [품질 기준] satisfied
- [ ] If any postcondition fails: Add [FAILURE] to HANDOFF LOG, EXIT 1
```

**Claude Code Best Practice 반영**: 단계별 지시 (numbered steps), 체크리스트 형식

##### Section 5: Critical Constraints (필수)

**목적**: 에이전트가 절대 하지 말아야 할 것 명시

**구조**: DO / DO NOT 명확히 구분

**템플릿**:
```markdown
## Critical Constraints

### DO
- [반드시 해야 할 것 1]
- [반드시 해야 할 것 2]
- [반드시 해야 할 것 3]

### DO NOT
- [절대 하지 말아야 할 것 1]
- [절대 하지 말아야 할 것 2]
- [절대 하지 말아야 할 것 3]
```

**공통 DO NOT 항목** (모든 에이전트):
- 다른 에이전트가 담당하는 섹션 수정 금지
- Work Status Markers 외부에 마커 추가 금지
- HANDOFF LOG 기존 엔트리 수정/삭제 금지

##### Section 6: Error Handling (필수)

**목적**: 오류 시나리오 및 처리 방법 명시

**내용**: Fail-Fast 전략 적용

**템플릿**:
```markdown
## Error Handling

### Precondition 실패 시
- **CURRENT_AGENT mismatch**:
  - Output: "ERROR: Precondition failed: CURRENT_AGENT is '{actual}', expected '[agent-name]'"
  - Add HANDOFF LOG: `[FAILURE] [agent-name] | Precondition failed: CURRENT_AGENT mismatch | [timestamp]`
  - Set STATUS: FAILED
  - EXIT 1

- **[다른 Precondition 실패]**:
  - [동일한 Fail-Fast 패턴]

### 작업 중 오류 시
- **[오류 시나리오 1]**:
  - Rollback partial work (if applicable)
  - Add HANDOFF LOG: `[FAILURE] [agent-name] | [error-message] | [timestamp]`
  - Set STATUS: FAILED
  - EXIT 1

### Postcondition 실패 시
- **[출력 섹션 없음]**:
  - [동일한 Fail-Fast 패턴]
```

**Unit 3 Inception Question 2 반영**: Fail-Fast 전략 채택

##### Section 7: Handoff Protocol (필수)

**목적**: 다음 에이전트로 작업을 전달하는 방법 명시

**내용**: Unit 1 명세 준수

**템플릿**:
```markdown
## Handoff Protocol

### Event Types
Use appropriate event type in HANDOFF LOG:
- **DONE**: Normal completion (first time)
- **IMPROVE**: Improvement completion (after IMPROVEMENT_NEEDED)
- **SKIP**: Skip this agent (optional section)
- **FAILURE**: Execution failure

### HANDOFF LOG Format
\`\`\`
[EVENT_TYPE] agent-name | message | YYYY-MM-DDTHH:MM:SS+09:00
\`\`\`

### Normal Flow
1. Add `[DONE] [agent-name] | [message] | [timestamp]` to HANDOFF LOG
2. Update CURRENT_AGENT to "[next-agent]"
3. Update UPDATED timestamp

### Improvement Mode
1. Check IMPROVEMENT_NEEDED contains [agent-name] entry
2. Modify ONLY the sections mentioned in feedback
3. Add `[IMPROVE] [agent-name] | [message] | [timestamp]` to HANDOFF LOG
4. Remove [agent-name] entry from IMPROVEMENT_NEEDED
5. Update CURRENT_AGENT to next improvement target or [next-agent]
```

**Unit 1 명세 반영**: 6개 EVENT_TYPE (START, DONE, IMPROVE, FAILURE, SKIP, COMPLETE)

##### Section 8: Quality Standards (필수)

**목적**: 출력물이 만족해야 할 품질 기준 명시

**템플릿**:
```markdown
## Quality Standards

### Content Quality
- [품질 기준 1]
- [품질 기준 2]
- [품질 기준 3]

### Structure Quality
- [구조 품질 기준 1]
- [구조 품질 기준 2]

### Parser Requirements
**Absolute Rules** (parser will fail if violated):
- [파서 필수 규칙 1]
- [파서 필수 규칙 2]
- [파서 필수 규칙 3]
```

##### Section 9: Examples (권장)

**목적**: 구체적인 입출력 예시 제공

**템플릿**:
```markdown
## Examples

### Example 1: Normal Flow
**Input**:
\`\`\`markdown
[입력 예시]
\`\`\`

**Output**:
\`\`\`markdown
[출력 예시]
\`\`\`

### Example 2: Improvement Mode
[동일한 패턴]

### Example 3: Precondition Failure
[동일한 패턴]
```

**Claude Code Best Practice 반영**: 구체적 출력 예시 제공

##### Section 10: References (권장)

**목적**: 관련 문서 링크 제공

**템플릿**:
```markdown
## References

- **Contract Specification**: `docs/aidlc-docs/specifications/contracts/[agent-name]-contract.md`
- **Work Status Markers Spec**: `docs/aidlc-docs/specifications/work-status-markers-spec.md`
- **Handoff Guide**: `docs/aidlc-docs/guides/agent-handoff-guide.md`
- **Unit 1 Domain Design**: `docs/aidlc-docs/construction/unit-01-pipe-mechanism/domain_design.md`
- **Unit 2 Domain Design**: `docs/aidlc-docs/construction/unit-02-filter-contracts/domain_design.md`
```

---

### 2.3 섹션별 작성 가이드라인

#### 2.3.1 필수 섹션 vs 선택 섹션

**필수 섹션** (8개):
1. Role & Responsibility
2. Input Contract
3. Output Contract
4. Execution Instructions
5. Critical Constraints
6. Error Handling
7. Handoff Protocol
8. Quality Standards

**권장 섹션** (2개):
9. Examples
10. References

**검증 방법**:
```bash
# 필수 섹션 존재 확인
required_sections=(
    "Role & Responsibility"
    "Input Contract"
    "Output Contract"
    "Execution Instructions"
    "Critical Constraints"
    "Error Handling"
    "Handoff Protocol"
    "Quality Standards"
)

for section in "${required_sections[@]}"; do
    if ! grep -q "^## $section" "$prompt_file"; then
        echo "ERROR: Required section '$section' not found"
        exit 1
    fi
done
```

#### 2.3.2 섹션별 권장 길이

**Question 2 답변**: B (중간 - 200-400줄)

**섹션별 길이 가이드**:
| 섹션 | 권장 길이 | 비율 |
|------|----------|------|
| Role & Responsibility | 10-20줄 | 5% |
| Input Contract | 20-40줄 | 10% |
| Output Contract | 20-40줄 | 10% |
| Execution Instructions | 60-100줄 | 30% |
| Critical Constraints | 20-30줄 | 8% |
| Error Handling | 40-60줄 | 15% |
| Handoff Protocol | 30-40줄 | 10% |
| Quality Standards | 20-30줄 | 8% |
| Examples | 30-50줄 | (선택) |
| References | 5-10줄 | (선택) |

**총 길이**: 220-360줄 (Examples 제외) → 200-400줄 목표 달성

---

### 2.4 프롬프트 타입별 변형

#### 2.4.1 일반 에이전트 프롬프트 (4개)

**대상 에이전트**:
- overview-writer
- concepts-writer
- practice-writer
- quiz-writer

**특징**:
- 콘텐츠 생성이 주 목적
- Input: CURRENT_AGENT 확인 + 이전 섹션 존재
- Output: 새 섹션 추가 + CURRENT_AGENT 업데이트
- Improvement Mode 지원

**표준 Execution Instructions**:
1. Validate Preconditions
2. Generate [Section Name] Section
3. Update Work Status Markers
4. Validate Postconditions

#### 2.4.2 특수 에이전트 프롬프트 (3개)

##### content-initiator

**특수성**:
- 의존성 없음 (첫 번째 에이전트)
- Work Status Markers 초기화
- 콘텐츠 생성 없음 (마커만)

**Execution Instructions 변형**:
1. ~~Validate Preconditions~~ (CURRENT_AGENT 확인 불필요)
2. Initialize Work Status Markers
3. Set CURRENT_AGENT to "overview-writer"

##### visualization-writer

**특수성**:
- React 컴포넌트 파일 생성 (별도 파일)
- `src/components/visualizations/index.ts` 업데이트 필수
- 시각화 없으면 SKIP 가능

**Critical Constraints 추가**:
- **DO**: index.ts에 export 반드시 추가
- **DO NOT**: Concepts 텍스트 수정 금지 (메타데이터만 추가)

##### content-validator

**특수성**:
- 모든 섹션 검증
- VALIDATION_SCORE 설정
- IMPROVEMENT_NEEDED 생성 (필요 시)
- 조건부 출력: COMPLETE or IMPROVE

**Execution Instructions 변형**:
1. Validate Preconditions
2. Validate All Sections (Quality Check)
3. Calculate VALIDATION_SCORE
4. **If score >= 90**: Add [COMPLETE], Set CURRENT_AGENT to ""
5. **If score < 90**: Add [DONE], Set IMPROVEMENT_NEEDED, Set CURRENT_AGENT to first improvement target

---

## Section 2 완료

**작성 내용 요약**:
- 2.1 YAML Frontmatter 구조 (name, version, description, tools, model)
- 2.2 Markdown 본문 섹션 구조 (10개 섹션 상세)
- 2.3 섹션별 작성 가이드라인 (필수/선택, 권장 길이)
- 2.4 프롬프트 타입별 변형 (일반 vs 특수)

**다음 섹션**: Section 3 - I/O Contract 통합 패턴

---

## Section 3: I/O Contract 통합 패턴 (I/O Contract Integration Patterns)

### 3.1 Contract-to-Prompt 변환 원칙

#### 3.1.1 변환의 목적

**Why**: 왜 Unit 2 계약을 Unit 3 프롬프트로 변환하는가?

**계약 (Contract)의 한계**:
- **선언적 (Declarative)**: "무엇을" 해야 하는지만 정의
- **검증 중심**: Preconditions/Postconditions로 올바름 검증
- **인터페이스 명세**: 에이전트 간 경계 정의

**프롬프트 (Prompt)의 필요성**:
- **절차적 (Procedural)**: "어떻게" 해야 하는지 지시
- **실행 중심**: Step-by-step으로 작업 수행
- **구현 명세**: AI 에이전트가 따라야 할 구체적 지시

**비유**:
```
계약 : 프롬프트 = 건축 설계도 : 시공 지침서
```
- 건축 설계도(계약): 방이 몇 개, 어디에 위치 → What
- 시공 지침서(프롬프트): 기초 → 골조 → 내장 순서 → How

#### 3.1.2 변환 범위 결정 (Question 1 답변 적용)

**Question 1**: I/O Contract를 프롬프트에 어떻게 통합할 것인가?
**Answer**: **B (요약 + 참조)** - 계약의 핵심 내용만 요약하고 상세 내용은 계약 문서 참조

**변환 범위 원칙**:

1. **요약 대상** (프롬프트에 포함):
   - **필수 조건**: CURRENT_AGENT 값, STATUS 조건, 필수 섹션
   - **출력 구조**: 생성할 섹션 이름, 헤더 구조
   - **핵심 제약**: 금지 사항 (DO NOT)

2. **참조 대상** (계약 문서 링크):
   - **상세 명세**: 섹션별 세부 형식, 파서 규칙
   - **예시**: Normal Flow, Improvement Mode 예시
   - **오류 시나리오**: 모든 오류 케이스와 메시지

**변환 비율 가이드**:
| 계약 요소 | 프롬프트 포함 비율 | 이유 |
|-----------|-------------------|------|
| Input Contract | 30-40% | 필수 조건만, 상세는 참조 |
| Output Contract | 30-40% | 구조만, 품질 기준은 참조 |
| Preconditions | 100% | 체크리스트로 변환하여 모두 포함 |
| Postconditions | 100% | 검증 단계로 변환하여 모두 포함 |
| Examples | 0-20% | 대표 예시 1개만, 나머지는 참조 |

**Question 1의 A, C 옵션을 선택하지 않은 이유**:
- **A (전체 복사)**: 프롬프트가 너무 길어짐 (600-800줄) → Question 2 목표 (200-400줄) 위배
- **C (참조만)**: 프롬프트만으로 작업 불가 → 자기 문서화 원칙 위배

#### 3.1.3 변환 시 일관성 유지

**용어 일관성**:
- 계약과 프롬프트에서 **동일한 용어** 사용
- 예: 계약에서 "CURRENT_AGENT" → 프롬프트에서도 "CURRENT_AGENT" (변역 금지)

**구조 일관성**:
- 계약의 섹션 순서 → 프롬프트의 섹션 순서
- Input Contract → Output Contract → Preconditions → Postconditions

**형식 일관성**:
- ISO 8601 타임스탬프
- HANDOFF LOG 엔트리 형식
- 체크리스트 형식

---

### 3.2 Input Contract 프롬프트 표현

#### 3.2.1 File State → 프롬프트 지시문 변환

**Unit 2 계약 예시** (overview-writer-contract.md):
```markdown
## Input Contract

### File State
- Required Files: Target markdown file with frontmatter and Work Status Markers
- File Encoding: UTF-8
- Frontmatter: Required (populated by content-initiator)
- Existing Sections: Work Status Markers only (no content sections yet)
```

**Unit 3 프롬프트 변환**:
```markdown
## Input Contract

### File State
- **Required Files**: Target markdown file (`.md`)
- **File Encoding**: UTF-8 (ensure Korean content compatibility)
- **Frontmatter**: Must exist with `id`, `title`, `difficulty` fields
- **Existing Sections**: Work Status Markers (HTML comment at top)

**참조**: `docs/aidlc-docs/specifications/contracts/overview-writer-contract.md` Section "Input Contract"
```

**변환 원칙**:
1. **필수 파일 명시**: "Target markdown file" → 구체적 파일 타입
2. **인코딩 강조**: UTF-8 (Question 4 결정사항)
3. **존재 조건 명시**: Frontmatter 필수 필드
4. **참조 링크 추가**: 상세 내용은 계약 문서 참조

#### 3.2.2 Work Status Markers → 검증 단계 변환

**Unit 2 계약 예시**:
```markdown
### Work Status Markers
- CURRENT_AGENT: overview-writer
- STATUS: PENDING (normal flow) or IN_PROGRESS (improvement mode)
- HANDOFF LOG: Contains [START] entry from pipeline initialization
```

**Unit 3 프롬프트 변환**:
```markdown
### Work Status Markers (Expected State)
- **CURRENT_AGENT**: `overview-writer` (MUST match)
- **STATUS**: `PENDING` (normal flow) or `IN_PROGRESS` (improvement mode)
- **HANDOFF LOG**: Must contain `[START]` entry

**Validation**: These conditions will be checked in Step 1 (Precondition validation).

**참조**: `docs/aidlc-docs/specifications/work-status-markers-spec.md`
```

**Execution Instructions에서 검증 단계로 연결**:
```markdown
## Execution Instructions

### Step 1: Validate Preconditions

#### 1.1 Validate Work Status Markers
- [ ] Check CURRENT_AGENT == "overview-writer"
  - If not: ERROR "Precondition failed: CURRENT_AGENT is '{actual}', expected 'overview-writer'"
  - Add `[FAILURE] overview-writer | Precondition failed: CURRENT_AGENT mismatch | [timestamp]`
  - Set STATUS: FAILED
  - EXIT 1

- [ ] Check STATUS is PENDING or IN_PROGRESS
  - If IN_PROGRESS: Check IMPROVEMENT_NEEDED contains overview-writer entry (improvement mode)
  - If PENDING: Normal flow
  - If neither: EXIT 1

- [ ] Verify HANDOFF LOG contains [START] entry
  - If not: ERROR "Precondition failed: No [START] entry in HANDOFF LOG"
  - EXIT 1
```

**변환 핵심**:
1. **Expected State 명시**: 무엇이어야 하는지 명확히
2. **검증 연결**: "Step 1에서 검증" 명시
3. **Fail-Fast 적용**: 각 조건마다 실패 시 즉시 종료 지시

#### 3.2.3 Section Dependencies → 명확화

**Unit 2 계약 예시**:
```markdown
### Section Dependencies
- None (first content section in the pipeline)
```

**Unit 3 프롬프트 변환** (overview-writer):
```markdown
### Section Dependencies
- **Previous Sections**: None (first content section)
- **Required by**: content-initiator (frontmatter + Work Status Markers must be initialized)

**Implication**: You can assume frontmatter and Work Status Markers exist and are valid.
```

**Unit 2 계약 예시** (concepts-writer):
```markdown
### Section Dependencies
- # Overview section (by overview-writer)
```

**Unit 3 프롬프트 변환** (concepts-writer):
```markdown
### Section Dependencies
- **Previous Sections**: `# Overview` (by overview-writer)
- **Required by**: overview-writer must have completed successfully

**Validation**: In Step 1, verify `# Overview` section exists.
```

**변환 원칙**:
1. **의존 에이전트 명시**: "by [agent-name]"
2. **검증 필요성 명시**: Step 1에서 확인
3. **가정 명시**: 무엇을 가정할 수 있는지

---

### 3.3 Output Contract 프롬프트 표현

#### 3.3.1 File Modifications → 작업 단계 변환

**Unit 2 계약 예시**:
```markdown
## Output Contract

### File Modifications
- Modified Files: Target markdown file
- New Sections: `# Overview` section added
- Section Structure:
  ```markdown
  # Overview

  [Introduction paragraph(s) - 3-5 sentences]

  ## 핵심 특징 (또는 핵심 문제점)
  - [Feature or problem 1]
  - [Feature or problem 2]
  - [Feature or problem 3]
  - [Feature or problem 4]

  ## 실무에서의 영향 (또는 왜 중요한가?)
  [Practical impact paragraph - 4-6 sentences]
  ```
```

**Unit 3 프롬프트 변환**:
```markdown
## Output Contract

### File Modifications
- **Modified Files**: Target markdown file (in-place edit)
- **New Sections**: `# Overview` section added after Work Status Markers

**참조**: `docs/aidlc-docs/specifications/contracts/overview-writer-contract.md` Section "Output Contract"
```

**Execution Instructions에서 작업 단계로 변환**:
```markdown
### Step 2: Generate Overview Section

#### 2.1 Create Section Header
Write the following structure immediately after Work Status Markers:

\`\`\`markdown
# Overview
\`\`\`

#### 2.2 Write Introduction Paragraph
- 3-5 sentences
- First sentence: Define the topic or explain core concept
- Subsequent sentences: Explain why it matters and what problems it solves

#### 2.3 Write Key Features/Problems Subsection
Choose one of:
- `## 핵심 특징` (for positive features)
- `## 핵심 문제점` (for problems/limitations)

Write 4-5 bullet points (one line each):
- Use **bold** for key terms
- Focus on technical advantages or problems

#### 2.4 Write Practical Impact Subsection
Choose one of:
- `## 실무에서의 영향`
- `## 왜 중요한가?`

Write 4-6 sentences in paragraph form:
- Include concrete use cases or scenarios
- Address performance, maintainability, or code quality
- Connect to real-world development practices
```

**변환 핵심**:
1. **구조 요약**: Output Contract에는 섹션 이름만
2. **상세 지시**: Execution Instructions에서 단계별 작성 방법
3. **참조 제공**: 전체 구조 예시는 계약 문서 참조

#### 3.3.2 Work Status Markers Updates → 업데이트 지시문 변환

**Unit 2 계약 예시**:
```markdown
### Work Status Markers
- CURRENT_AGENT: concepts-writer
- STATUS: IN_PROGRESS
- UPDATED: Current timestamp (ISO 8601 format)
- HANDOFF LOG:
  - Preserve all existing entries
  - Add: `[DONE] overview-writer | Overview section completed | [timestamp]`
```

**Unit 3 프롬프트 변환**:
```markdown
### Work Status Markers Updates
- **CURRENT_AGENT**: Update to `concepts-writer`
- **STATUS**: Update to `IN_PROGRESS`
- **UPDATED**: Update to current timestamp (ISO 8601: `YYYY-MM-DDTHH:MM:SS+09:00`)
- **HANDOFF LOG**: Add entry (preserve all existing entries)

**참조**: `docs/aidlc-docs/specifications/work-status-markers-spec.md`
```

**Execution Instructions에서 업데이트 단계로 변환**:
```markdown
### Step 3: Update Work Status Markers

#### 3.1 Read Current Work Status Markers
Parse the HTML comment at the top of the file to extract current values.

#### 3.2 Prepare HANDOFF LOG Entry
Format:
\`\`\`
[DONE] overview-writer | Overview section completed | YYYY-MM-DDTHH:MM:SS+09:00
\`\`\`

**Normal Flow**: Use `[DONE]`
**Improvement Mode**: Use `[IMPROVE]`

#### 3.3 Update Work Status Markers
Replace the HTML comment with updated values:

\`\`\`markdown
<!--
CURRENT_AGENT: concepts-writer
STATUS: IN_PROGRESS
STARTED: [preserve original value]
UPDATED: [current timestamp]
HANDOFF LOG:
[preserve all existing entries]
[DONE] overview-writer | Overview section completed | [timestamp]
-->
\`\`\`

#### 3.4 (Improvement Mode Only) Remove from IMPROVEMENT_NEEDED
If IMPROVEMENT_NEEDED field exists and contains overview-writer entry:
- Remove the overview-writer line from IMPROVEMENT_NEEDED
- If IMPROVEMENT_NEEDED becomes empty, remove the field entirely
```

**변환 핵심**:
1. **업데이트 대상 명시**: 어떤 필드를 어떻게 바꾸는지
2. **형식 강조**: ISO 8601 타임스탬프
3. **조건부 로직**: Normal Flow vs Improvement Mode 구분
4. **보존 지시**: 기존 엔트리 보존 강조

#### 3.3.3 Content Guarantees → 품질 기준 변환

**Unit 2 계약 예시**:
```markdown
### Content Guarantees
- Overview section length: 50-100 lines
- Introduction paragraph: 3-5 sentences
  - First sentence: Define the topic or explain core concept
  - Subsequent sentences: Explain why it matters and what problems it solves
- Key features/problems: 4-5 bullet points (one line each)
- Practical impact paragraph: 4-6 sentences with concrete use cases
```

**Unit 3 프롬프트 변환**:
```markdown
### Content Guarantees
- **Section Length**: 50-100 lines
- **Introduction**: 3-5 sentences (definition + why it matters)
- **Key Features/Problems**: 4-5 bullet points
- **Practical Impact**: 4-6 sentences with concrete use cases

**참조**: `docs/aidlc-docs/specifications/contracts/overview-writer-contract.md` Section "Content Guarantees"
```

**Quality Standards 섹션으로 확장**:
```markdown
## Quality Standards

### Content Quality
- **Length**: 50-100 lines total
- **Introduction Paragraph**:
  - 3-5 sentences
  - First sentence: Define topic clearly
  - Explain why it matters
- **Key Features/Problems**:
  - 4-5 bullet points
  - One line per bullet
  - Use **bold** for key terms
- **Practical Impact**:
  - 4-6 sentences in paragraph form
  - Include concrete use cases
  - Address performance, maintainability, or code quality

### Structure Quality
- H1 header: `# Overview` (exactly)
- H2 headers: `##` only (no deeper)
- NO code blocks
- NO numbered lists (bullet points only)

### Parser Requirements
**Absolute Rules** (parser will fail if violated):
- Must start with `# Overview` header (H1)
- Introduction paragraph immediately after (no H2 header)
- Subsections use `##` level headers (H2) only
- NO headers deeper than `##` (no `###` or deeper)
- NO code blocks
- NO numbered lists
```

**변환 핵심**:
1. **요약**: Output Contract에는 핵심 보장 사항만
2. **상세화**: Quality Standards에서 구체적 기준
3. **파서 규칙**: 파서가 검증하는 절대 규칙 명시

---

### 3.4 Preconditions/Postconditions 검증 지시

#### 3.4.1 Preconditions → 체크리스트 생성

**Unit 2 계약 예시**:
```markdown
## Preconditions

1. CURRENT_AGENT == "overview-writer"
2. STATUS == PENDING (normal flow) OR STATUS == IN_PROGRESS AND IMPROVEMENT_NEEDED contains overview-writer entry (improvement mode)
3. frontmatter exists and is populated with topic metadata
4. HANDOFF LOG contains [START] entry
```

**Unit 3 프롬프트 변환**:
```markdown
## Execution Instructions

### Step 1: Validate Preconditions

**IMPORTANT**: Use Fail-Fast strategy. If any precondition fails, add [FAILURE] to HANDOFF LOG and EXIT 1 immediately.

#### Precondition Checklist:

- [ ] **PC-1: CURRENT_AGENT matches**
  - Check: `CURRENT_AGENT == "overview-writer"`
  - If fails:
    - Output: `ERROR: Precondition failed: CURRENT_AGENT is '{actual}', expected 'overview-writer'`
    - Add HANDOFF LOG: `[FAILURE] overview-writer | Precondition failed: CURRENT_AGENT mismatch | [timestamp]`
    - Set STATUS: FAILED
    - EXIT 1

- [ ] **PC-2: STATUS is valid**
  - Check: `STATUS == PENDING` (normal flow) OR `STATUS == IN_PROGRESS AND IMPROVEMENT_NEEDED contains overview-writer` (improvement mode)
  - If fails:
    - Output: `ERROR: Precondition failed: STATUS is '{actual}', expected 'PENDING' or 'IN_PROGRESS' with IMPROVEMENT_NEEDED`
    - Add HANDOFF LOG: `[FAILURE] overview-writer | Precondition failed: Invalid STATUS | [timestamp]`
    - Set STATUS: FAILED
    - EXIT 1

- [ ] **PC-3: Frontmatter exists**
  - Check: YAML frontmatter exists with fields `id`, `title`, `difficulty`
  - If fails:
    - Output: `ERROR: Precondition failed: frontmatter is missing or incomplete`
    - Add HANDOFF LOG: `[FAILURE] overview-writer | Precondition failed: Missing frontmatter | [timestamp]`
    - Set STATUS: FAILED
    - EXIT 1

- [ ] **PC-4: HANDOFF LOG contains [START] entry**
  - Check: HANDOFF LOG contains at least one `[START]` entry
  - If fails:
    - Output: `ERROR: Precondition failed: No [START] entry in HANDOFF LOG`
    - Add HANDOFF LOG: `[FAILURE] overview-writer | Precondition failed: Missing [START] entry | [timestamp]`
    - Set STATUS: FAILED
    - EXIT 1
```

**변환 원칙**:
1. **체크리스트 형식**: 각 조건에 체크박스 (- [ ])
2. **조건 식별자**: PC-1, PC-2, ... (Precondition-N)
3. **검증 로직**: "Check: [조건 식]" 명시
4. **실패 처리**: Fail-Fast 전략 적용 (Output, HANDOFF LOG, EXIT 1)
5. **명확한 오류 메시지**: 무엇이 잘못되었는지, 기대값과 실제값

#### 3.4.2 Postconditions → 검증 단계 명시

**Unit 2 계약 예시**:
```markdown
## Postconditions

1. `# Overview` section is created and complete
2. CURRENT_AGENT == "concepts-writer"
3. STATUS == IN_PROGRESS
4. HANDOFF LOG contains [DONE] overview-writer entry with completion timestamp
5. (Improvement mode only) IMPROVEMENT_NEEDED field no longer contains overview-writer entry
```

**Unit 3 프롬프트 변환**:
```markdown
### Step 4: Validate Postconditions

**IMPORTANT**: Verify output quality before completing. If any postcondition fails, rollback work and EXIT 1.

#### Postcondition Checklist:

- [ ] **PO-1: Overview section exists**
  - Check: File contains `# Overview` header
  - Check: Section has Introduction paragraph + 2 subsections (## 핵심 특징/문제점, ## 실무에서의 영향)
  - If fails:
    - Output: `ERROR: Postcondition failed: Overview section is missing or incomplete`
    - Rollback: Remove incomplete Overview section
    - Add HANDOFF LOG: `[FAILURE] overview-writer | Postcondition failed: Incomplete Overview | [timestamp]`
    - Set STATUS: FAILED
    - EXIT 1

- [ ] **PO-2: CURRENT_AGENT updated**
  - Check: `CURRENT_AGENT == "concepts-writer"`
  - If fails:
    - Output: `ERROR: Postcondition failed: CURRENT_AGENT not updated correctly`
    - EXIT 1

- [ ] **PO-3: STATUS updated**
  - Check: `STATUS == IN_PROGRESS`
  - If fails:
    - Output: `ERROR: Postcondition failed: STATUS not updated correctly`
    - EXIT 1

- [ ] **PO-4: HANDOFF LOG entry added**
  - Check: HANDOFF LOG contains `[DONE] overview-writer` or `[IMPROVE] overview-writer` entry
  - Check: Entry has valid ISO 8601 timestamp
  - If fails:
    - Output: `ERROR: Postcondition failed: HANDOFF LOG entry missing or malformed`
    - EXIT 1

- [ ] **PO-5: (Improvement mode only) IMPROVEMENT_NEEDED cleared**
  - If IMPROVEMENT_NEEDED existed before:
    - Check: IMPROVEMENT_NEEDED no longer contains overview-writer entry
    - If fails:
      - Output: `ERROR: Postcondition failed: IMPROVEMENT_NEEDED not cleared`
      - EXIT 1

- [ ] **PO-6: Content quality standards met**
  - Check: Section length is 50-100 lines
  - Check: NO code blocks in Overview section
  - Check: NO headers deeper than `##`
  - If fails:
    - Output: `ERROR: Postcondition failed: Content quality standards not met`
    - List violations
    - EXIT 1
```

**변환 원칙**:
1. **체크리스트 형식**: 각 조건에 체크박스
2. **조건 식별자**: PO-1, PO-2, ... (Postcondition-N)
3. **검증 로직**: "Check: [조건 식]" 명시
4. **롤백 지시**: 실패 시 부분 작업 제거
5. **조건부 검증**: "(Improvement mode only)" 같은 조건 명시

#### 3.4.3 Preconditions/Postconditions 체크리스트 표준 형식

**표준 형식**:
```markdown
- [ ] **[ID]: [조건 요약]**
  - Check: [검증 조건 (코드 형식)]
  - If fails:
    - Output: `ERROR: [Precondition|Postcondition] failed: [상세 메시지]`
    - [추가 작업 (Rollback, 로그 추가 등)]
    - Add HANDOFF LOG: `[FAILURE] [agent-name] | [실패 이유] | [timestamp]`
    - Set STATUS: FAILED
    - EXIT 1
```

**ID 규칙**:
- Precondition: `PC-1`, `PC-2`, `PC-3`, ...
- Postcondition: `PO-1`, `PO-2`, `PO-3`, ...

**Output 메시지 형식**:
```
ERROR: [Precondition|Postcondition] failed: [필드명] is '[실제값]', expected '[기대값]'
```

**HANDOFF LOG 형식** (실패 시):
```
[FAILURE] [agent-name] | [Precondition|Postcondition] failed: [이유] | YYYY-MM-DDTHH:MM:SS+09:00
```

---

### 3.5 변환 패턴 요약

#### 3.5.1 계약 요소 → 프롬프트 섹션 매핑표

| Unit 2 계약 요소 | Unit 3 프롬프트 섹션 | 변환 방법 | 포함 비율 |
|------------------|---------------------|----------|----------|
| **Input Contract** | **Input Contract** (요약) | 필수 조건만 요약, 참조 링크 추가 | 30-40% |
| ├─ File State | Input Contract > File State | 필수 파일, 인코딩 명시 | 40% |
| ├─ Work Status Markers | Input Contract > Work Status Markers | Expected State 명시, Step 1 검증 연결 | 30% |
| └─ Section Dependencies | Input Contract > Section Dependencies | 의존 에이전트 명시, 가정 명시 | 30% |
| **Output Contract** | **Output Contract** (요약) | 생성 섹션만 요약, 참조 링크 추가 | 30-40% |
| ├─ File Modifications | Output Contract > File Modifications | 섹션 이름만, 구조는 Execution Instructions에 | 20% |
| ├─ Work Status Markers Updates | Output Contract > Work Status Markers Updates | 업데이트 대상 명시, Step 3 연결 | 40% |
| └─ Content Guarantees | Output Contract > Content Guarantees (요약) + Quality Standards (상세) | 핵심 보장만 요약, 상세는 Quality Standards | 30% 요약 + 100% 상세 |
| **Preconditions** | **Execution Instructions > Step 1** | 체크리스트화 (PC-1, PC-2, ...), Fail-Fast 적용 | 100% |
| **Postconditions** | **Execution Instructions > Step 4** | 체크리스트화 (PO-1, PO-2, ...), 검증 로직 | 100% |
| **Error Handling** | **Error Handling** | Fail-Fast 전략, 오류 시나리오별 처리 | 60% (대표 시나리오) |
| **Examples** | **Examples** | 대표 예시 1-2개, 나머지는 참조 | 10-20% |

#### 3.5.2 4단계 변환 워크플로우

**Step 1: 계약 분석**
- [ ] Unit 2 계약 문서 읽기 (`contracts/[agent-name]-contract.md`)
- [ ] 필수 요소 식별: Input/Output Contract, Preconditions, Postconditions
- [ ] 에이전트 특수성 파악 (일반 vs 특수)

**Step 2: 프롬프트 골격 생성**
- [ ] YAML Frontmatter 작성 (name, version, description, tools, model)
- [ ] 10개 표준 섹션 생성 (Role, Input, Output, Execution, Constraints, Error, Handoff, Quality, Examples, References)

**Step 3: 계약 내용 요약 및 변환**
- [ ] Input Contract → 요약 + 참조 링크
- [ ] Output Contract → 요약 + 참조 링크
- [ ] Preconditions → Step 1 체크리스트
- [ ] Postconditions → Step 4 체크리스트
- [ ] Content Guarantees → Quality Standards 상세화

**Step 4: 실행 지시 작성**
- [ ] Step 2 (Perform Work) 에이전트별 구체적 작업 단계 작성
- [ ] Step 3 (Update WSM) Work Status Markers 업데이트 지시
- [ ] Critical Constraints (DO/DO NOT) 명시
- [ ] Error Handling (Fail-Fast) 시나리오별 처리

#### 3.5.3 변환 시 주의사항

**DO**:
- ✅ **용어 일관성**: 계약과 프롬프트에서 동일한 용어 사용
- ✅ **참조 링크**: 상세 내용은 계약 문서 참조 링크 제공
- ✅ **체크리스트화**: Preconditions/Postconditions를 실행 가능한 체크리스트로
- ✅ **Fail-Fast**: 모든 검증 실패 시 즉시 EXIT 1
- ✅ **타임스탬프**: ISO 8601 형식 명시 (`YYYY-MM-DDTHH:MM:SS+09:00`)

**DO NOT**:
- ❌ **전체 복사**: 계약 내용 전체를 프롬프트에 복사 금지 (Question 1 결정)
- ❌ **용어 변경**: "CURRENT_AGENT"를 "현재 에이전트" 같은 번역 금지
- ❌ **암묵적 가정**: "파일을 잘 읽어서" 같은 모호한 표현 금지
- ❌ **예시 생략**: Preconditions/Postconditions 실패 시 오류 메시지 예시 필수
- ❌ **참조 누락**: Output Contract 요약 시 참조 링크 누락 금지

---

## Section 3 완료

**작성 내용 요약**:
- 3.1 Contract-to-Prompt 변환 원칙 (목적, 범위, 일관성)
- 3.2 Input Contract 프롬프트 표현 (File State, Work Status Markers, Section Dependencies)
- 3.3 Output Contract 프롬프트 표현 (File Modifications, WSM Updates, Content Guarantees)
- 3.4 Preconditions/Postconditions 검증 지시 (체크리스트, 표준 형식)
- 3.5 변환 패턴 요약 (매핑표, 워크플로우, 주의사항)

**핵심 결정 사항**:
- Question 1 답변 (B: 요약 + 참조) 반영
- Preconditions/Postconditions 100% 체크리스트화
- Fail-Fast 전략 모든 검증 단계에 적용
- 표준 ID 규칙: PC-N (Precondition), PO-N (Postcondition)

**다음 섹션**: Section 4 - 에이전트 책임 경계

---

## Section 4: 에이전트 책임 경계 (Agent Responsibility Boundaries)

### 4.1 Bounded Context 기반 책임 정의

#### 4.1.1 Bounded Context 개념 (DDD)

**정의** (Eric Evans):
> "A Bounded Context is a specific responsibility enforced by explicit boundaries. The boundary separates one model from another, preventing the corruption of concepts."

**콘텐츠 생성 파이프라인에서의 적용**:
- 각 에이전트 = 하나의 Bounded Context
- 경계 = 에이전트가 소유하고 수정할 수 있는 섹션
- 경계 밖 = 읽기 전용 또는 접근 금지

**경계의 중요성**:
1. **책임 명확화**: 각 에이전트가 무엇을 수정할 수 있는지 명확
2. **충돌 방지**: 여러 에이전트가 동일 섹션 수정 방지
3. **디버깅 용이**: 문제 발생 시 책임 에이전트 즉시 파악
4. **독립 개선**: 한 에이전트 수정 시 다른 에이전트 영향 최소화

#### 4.1.2 7개 에이전트의 Bounded Context

**Unit 2 Section 1.4 참조**: 각 에이전트의 Bounded Context 정의

| 에이전트 | Bounded Context | 소유 데이터 | 접근 가능 자원 |
|---------|-----------------|-----------|---------------|
| **content-initiator** | Content Initialization | Work Status Markers (초기), frontmatter | category.yaml (읽기), 파일 (쓰기) |
| **overview-writer** | Overview Section Generation | `# Overview` 섹션 전체 | WSM (읽기/쓰기), frontmatter (읽기) |
| **concepts-writer** | Core Concepts Section Generation | `# Core Concepts` 섹션 전체 | WSM (읽기/쓰기), Overview (읽기) |
| **visualization-writer** | Visualization Component Generation | React 컴포넌트 파일, `index.ts` | WSM (읽기/쓰기), Core Concepts (읽기) |
| **practice-writer** | Practice Section Generation | `# Practice` 섹션 전체 | WSM (읽기/쓰기), Core Concepts (읽기) |
| **quiz-writer** | Quiz Section Generation | `# Quiz` 섹션 전체 | WSM (읽기/쓰기), 모든 학습 섹션 (읽기) |
| **content-validator** | Content Quality Validation | VALIDATION_SCORE, IMPROVEMENT_NEEDED | WSM (읽기/쓰기), 모든 섹션 (읽기) |

#### 4.1.3 Context 경계 내 허용 작업

**원칙**: 에이전트는 자신의 Bounded Context 내에서만 쓰기 권한을 가진다.

**content-initiator** (Content Initialization):
- ✅ **허용**: Work Status Markers 초기화 (CURRENT_AGENT, STATUS, STARTED, HANDOFF LOG)
- ✅ **허용**: frontmatter 생성 (category.yaml 기반)
- ✅ **허용**: 파일 생성 (존재하지 않을 경우)
- ❌ **금지**: 콘텐츠 섹션 생성 (Overview, Core Concepts 등)

**overview-writer** (Overview Section Generation):
- ✅ **허용**: `# Overview` 섹션 생성 (헤더 ~ 다음 섹션 직전)
- ✅ **허용**: `## 핵심 특징`, `## 실무에서의 영향` 하위 섹션 생성
- ✅ **허용**: Work Status Markers 업데이트 (CURRENT_AGENT, UPDATED, HANDOFF LOG)
- ❌ **금지**: 다른 섹션 (Core Concepts, Practice, Quiz) 수정
- ❌ **금지**: frontmatter 수정

**concepts-writer** (Core Concepts Section Generation):
- ✅ **허용**: `# Core Concepts` 섹션 생성
- ✅ **허용**: 각 Concept별 Easy/Normal/Expert 하위 섹션 생성
- ✅ **허용**: 시각화 메타데이터 추가 (`<!-- VISUAL: component-name -->`)
- ✅ **허용**: Work Status Markers 업데이트
- ❌ **금지**: Overview 섹션 수정
- ❌ **금지**: React 컴포넌트 파일 생성 (visualization-writer 책임)

**visualization-writer** (Visualization Component Generation):
- ✅ **허용**: React 컴포넌트 파일 생성 (`src/components/visualizations/[name].tsx`)
- ✅ **허용**: `src/components/visualizations/index.ts` 업데이트 (export 추가)
- ✅ **허용**: Work Status Markers 업데이트
- ❌ **금지**: Core Concepts 텍스트 수정 (메타데이터 추가만 허용)
- ❌ **금지**: 다른 에이전트 소유 섹션 수정

**practice-writer** (Practice Section Generation):
- ✅ **허용**: `# Practice` 섹션 생성
- ✅ **허용**: `## Code Patterns`, `## Experiments` 하위 섹션 생성
- ✅ **허용**: Work Status Markers 업데이트
- ❌ **금지**: Core Concepts 섹션 수정
- ❌ **금지**: Quiz 섹션 수정

**quiz-writer** (Quiz Section Generation):
- ✅ **허용**: `# Quiz` 섹션 생성
- ✅ **허용**: 6가지 퀴즈 타입 (multiple-choice, true-false, fill-in-the-blank, code-output, drag-and-drop, sorting) 생성
- ✅ **허용**: Work Status Markers 업데이트
- ❌ **금지**: 학습 섹션 (Overview, Core Concepts, Practice) 수정

**content-validator** (Content Quality Validation):
- ✅ **허용**: VALIDATION_SCORE 필드 추가/수정
- ✅ **허용**: IMPROVEMENT_NEEDED 필드 추가/수정
- ✅ **허용**: CURRENT_AGENT 업데이트 (개선 대상 또는 빈 문자열)
- ✅ **허용**: STATUS 업데이트 (COMPLETED 또는 IN_PROGRESS)
- ❌ **금지**: 콘텐츠 섹션 직접 수정 (다른 에이전트에 개선 요청만 가능)

#### 4.1.4 Context 경계 외 금지 작업

**절대 금지 사항** (모든 에이전트 공통):

1. **다른 에이전트 소유 섹션 수정**:
   ```markdown
   ❌ overview-writer가 Core Concepts 섹션 수정
   ❌ concepts-writer가 Overview 섹션 수정
   ❌ practice-writer가 Quiz 섹션 수정
   ```

2. **Work Status Markers 외부에 마커 추가**:
   ```markdown
   ❌ 콘텐츠 중간에 <!-- CURRENT_AGENT: ... --> 추가
   ❌ 섹션 내부에 STATUS 마커 삽입
   ```

3. **HANDOFF LOG 기존 엔트리 수정/삭제**:
   ```markdown
   ❌ [DONE] overview-writer | ... → 수정 금지
   ❌ [FAILURE] concepts-writer | ... → 삭제 금지
   ```

4. **다음 에이전트 출력물 미리 생성**:
   ```markdown
   ❌ overview-writer가 Core Concepts 섹션 미리 생성
   ```

5. **category.yaml 수정**:
   ```markdown
   ❌ 모든 에이전트는 category.yaml 읽기 전용
   ```

**경계 위반 예시 및 수정**:

**위반 예시 1**:
```markdown
<!-- overview-writer 프롬프트 (잘못된 예) -->
## Step 2: Generate Overview Section
- Write # Overview section
- **Also write # Core Concepts section** ← 경계 위반!
```

**수정**:
```markdown
## Step 2: Generate Overview Section
- Write # Overview section ONLY
- DO NOT write any other sections (Core Concepts, Practice, Quiz)
```

**위반 예시 2**:
```markdown
<!-- concepts-writer 프롬프트 (잘못된 예) -->
## Step 2: Generate Core Concepts Section
- If Overview is too short, extend it ← 경계 위반!
- Write # Core Concepts section
```

**수정**:
```markdown
## Step 2: Generate Core Concepts Section
- Read # Overview section (READ-ONLY)
- Write # Core Concepts section
- DO NOT modify Overview section (even if it seems incomplete)
```

---

### 4.2 DO/DO NOT 표준화

#### 4.2.1 DO 섹션 작성 패턴

**목적**: 에이전트가 반드시 해야 할 것을 명시

**작성 원칙**:
1. **구체적 동사 사용**: "생성하라", "업데이트하라", "검증하라"
2. **범위 명시**: "어디에", "무엇을", "어떻게"
3. **조건 명시**: "~인 경우에만", "~일 때"

**표준 템플릿**:
```markdown
## Critical Constraints

### DO
- **[동사] [대상]**: [상세 설명]
  - 예: Write [section-name] section in [location]
  - 예: Update [field-name] to [value]
- **[동사] [대상] when [조건]**:
  - 예: Add HANDOFF LOG entry when work is completed
- **[동사] [대상] before [시점]**:
  - 예: Validate Preconditions before performing work
```

**DO 섹션 예시** (overview-writer):
```markdown
### DO
- **Write `# Overview` section** immediately after Work Status Markers
  - Include introduction paragraph (3-5 sentences)
  - Include `## 핵심 특징` or `## 핵심 문제점` subsection
  - Include `## 실무에서의 영향` subsection
- **Update Work Status Markers** after completing work:
  - Add `[DONE]` or `[IMPROVE]` entry to HANDOFF LOG
  - Update CURRENT_AGENT to `concepts-writer`
  - Update UPDATED timestamp (ISO 8601)
- **Read frontmatter** to understand the topic:
  - Use `id`, `title`, `difficulty` fields for context
- **Ensure UTF-8 encoding** for all Korean content
- **Validate Postconditions** before marking work complete
```

#### 4.2.2 DO NOT 섹션 작성 패턴

**목적**: 에이전트가 절대 하지 말아야 할 것을 명시

**작성 원칙**:
1. **명확한 금지**: "~하지 마라" (강한 어조)
2. **이유 명시**: 왜 금지되는지 (선택적)
3. **대안 제시**: 대신 무엇을 해야 하는지 (선택적)

**표준 템플릿**:
```markdown
### DO NOT
- **DO NOT [동사] [대상]**: [이유 (선택적)]
  - 예: DO NOT modify [section-name] section (owned by [agent-name])
- **NEVER [동사] [대상]**: [강조]
  - 예: NEVER delete existing HANDOFF LOG entries
- **DO NOT [동사] [대상] unless [예외 조건]**:
  - 예: DO NOT skip validation unless explicitly instructed
```

**DO NOT 섹션 예시** (overview-writer):
```markdown
### DO NOT
- **DO NOT modify other sections**:
  - DO NOT modify `# Core Concepts` section (owned by concepts-writer)
  - DO NOT modify `# Practice` section (owned by practice-writer)
  - DO NOT modify `# Quiz` section (owned by quiz-writer)
- **DO NOT modify frontmatter fields**:
  - frontmatter is read-only after initialization by content-initiator
- **NEVER add markers outside Work Status Markers**:
  - All markers must be within the HTML comment at the top of the file
- **NEVER modify or delete existing HANDOFF LOG entries**:
  - Only append new entries
  - Preserve all existing entries exactly as-is
- **DO NOT create code blocks in Overview section**:
  - Overview is concept-only, no code examples
- **DO NOT use headers deeper than `##`**:
  - Only `#` (H1) and `##` (H2) allowed in Overview
```

#### 4.2.3 공통 금지 사항 (모든 에이전트)

**모든 프롬프트에 포함되어야 할 공통 DO NOT**:

```markdown
### DO NOT (Common to All Agents)

- **DO NOT modify sections owned by other agents**:
  - Each agent has exclusive write access to its own section
  - Refer to Bounded Context table in Section 4.1.2

- **DO NOT add markers outside Work Status Markers**:
  - All metadata must be within `<!-- ... -->` HTML comment at the top
  - No inline markers (e.g., `<!-- STATUS: ... -->`) in content sections

- **NEVER modify or delete existing HANDOFF LOG entries**:
  - HANDOFF LOG is append-only
  - Existing entries are immutable audit trail

- **DO NOT modify category.yaml**:
  - category.yaml is single source of truth
  - Read-only for all agents

- **DO NOT skip Precondition validation**:
  - Always validate Preconditions before performing work
  - Use Fail-Fast strategy (EXIT 1 on failure)

- **DO NOT skip Postcondition validation**:
  - Always validate Postconditions before marking work complete
  - Rollback partial work if validation fails
```

**프롬프트 작성 시 적용 방법**:
1. 공통 DO NOT을 모든 프롬프트에 포함
2. 에이전트별 특수 DO NOT을 추가
3. 중복 제거 (공통 + 특수)

---

### 4.3 에이전트 간 협업 규칙

#### 4.3.1 이전 에이전트 출력물 사용 방법 (읽기 전용)

**원칙**: Customer는 Supplier의 출력물을 읽기 전용으로 사용

**Customer-Supplier Relationship** (Unit 2 Section 1.3.3):
```
content-initiator (Supplier)
    ↓
overview-writer (Customer → Supplier)
    ↓
concepts-writer (Customer → Supplier)
    ↓
visualization-writer (Customer → Supplier)
    ↓
practice-writer (Customer → Supplier)
    ↓
quiz-writer (Customer → Supplier)
    ↓
content-validator (Customer)
```

**읽기 전용 사용 패턴**:

**개념적 참조**:
```markdown
<!-- concepts-writer 프롬프트 -->
## Input Contract

### Section Dependencies
- **Previous Sections**: `# Overview` (by overview-writer)
- **Usage**: Read Overview to understand topic context
- **Constraint**: READ-ONLY - DO NOT modify Overview content
```

**구체적 지시**:
```markdown
## Execution Instructions

### Step 2: Generate Core Concepts Section

#### 2.1 Read Overview Section (READ-ONLY)
- Read `# Overview` section to understand:
  - Topic definition (introduction paragraph)
  - Key features or problems
  - Practical impact
- Use this context to write appropriate difficulty levels

**IMPORTANT**: DO NOT modify Overview section content
```

**에이전트별 읽기 의존성**:

| 에이전트 | 읽기 가능 섹션 | 사용 목적 |
|---------|--------------|----------|
| content-initiator | category.yaml | frontmatter 생성 |
| overview-writer | frontmatter | 주제 정보 파악 |
| concepts-writer | frontmatter, Overview | 주제 컨텍스트 + 개념 깊이 결정 |
| visualization-writer | frontmatter, Core Concepts | 시각화 대상 식별 |
| practice-writer | frontmatter, Core Concepts | 실습 난이도 결정 |
| quiz-writer | frontmatter, Overview, Core Concepts, Practice | 퀴즈 범위 및 난이도 결정 |
| content-validator | frontmatter, 모든 섹션 | 품질 검증 |

**읽기 전용 위반 방지 지시**:

```markdown
## Critical Constraints

### DO
- **Read [section-name] section** to understand [purpose]

### DO NOT
- **DO NOT modify [section-name] section content**
  - This section is owned by [owner-agent]
  - You have READ-ONLY access
  - If improvement is needed, request it via IMPROVEMENT_NEEDED (content-validator only)
```

#### 4.3.2 다음 에이전트로 핸드오프 방법

**핸드오프 정의**:
> "현재 에이전트가 작업 완료 후 다음 에이전트에게 제어를 이전하는 행위"

**핸드오프 메커니즘**: Work Status Markers의 CURRENT_AGENT 업데이트

**표준 핸드오프 절차** (모든 에이전트):

```markdown
### Step 3: Update Work Status Markers

#### 3.1 Prepare HANDOFF LOG Entry
Format:
\`\`\`
[DONE] [agent-name] | [message] | YYYY-MM-DDTHH:MM:SS+09:00
\`\`\`

**Normal Flow**: Use `[DONE]`
**Improvement Mode**: Use `[IMPROVE]`

#### 3.2 Update CURRENT_AGENT
- **Normal Flow**: Set CURRENT_AGENT to `[next-agent]`
- **Improvement Mode**: Set CURRENT_AGENT to next improvement target (or [next-agent] if no more improvements)

Next Agent Mapping:
- content-initiator → overview-writer
- overview-writer → concepts-writer
- concepts-writer → visualization-writer
- visualization-writer → practice-writer
- practice-writer → quiz-writer
- quiz-writer → content-validator
- content-validator → "" (empty string, pipeline complete)

#### 3.3 Update UPDATED Timestamp
- Use ISO 8601 format: `YYYY-MM-DDTHH:MM:SS+09:00`
- Example: `2025-10-17T14:30:00+09:00`

#### 3.4 Replace Work Status Markers
Replace the entire HTML comment at the top of the file with updated values.
```

**핸드오프 체크리스트** (Postcondition):

```markdown
### Step 4: Validate Postconditions

- [ ] **PO-2: CURRENT_AGENT updated correctly**
  - Check: `CURRENT_AGENT == "[next-agent]"`
  - If fails: EXIT 1

- [ ] **PO-4: HANDOFF LOG entry added**
  - Check: HANDOFF LOG contains `[DONE] [agent-name]` or `[IMPROVE] [agent-name]` entry
  - Check: Entry has valid ISO 8601 timestamp
  - If fails: EXIT 1
```

**특수 케이스**:

1. **visualization-writer**: 시각화 없으면 SKIP 가능
   ```markdown
   ### Step 3: Update Work Status Markers

   **If no visualization needed**:
   - Add HANDOFF LOG: `[SKIP] visualization-writer | No visualization needed | [timestamp]`
   - Set CURRENT_AGENT to `practice-writer`

   **If visualization created**:
   - Add HANDOFF LOG: `[DONE] visualization-writer | [message] | [timestamp]`
   - Set CURRENT_AGENT to `practice-writer`
   ```

2. **content-validator**: 파이프라인 종료
   ```markdown
   ### Step 3: Update Work Status Markers

   **If VALIDATION_SCORE >= 90**:
   - Add HANDOFF LOG: `[COMPLETE] content-validator | Validation passed (score: [score]) | [timestamp]`
   - Set CURRENT_AGENT to `""` (empty string)
   - Set STATUS to `COMPLETED`

   **If VALIDATION_SCORE < 90**:
   - Add HANDOFF LOG: `[DONE] content-validator | Validation completed - improvements needed | [timestamp]`
   - Set CURRENT_AGENT to first improvement target (e.g., `overview-writer`)
   - Set IMPROVEMENT_NEEDED field
   ```

#### 4.3.3 개선 모드에서의 협업 (IMPROVEMENT_NEEDED)

**개선 모드 정의**:
> "content-validator가 품질 검증 후 특정 에이전트에게 개선을 요청하는 모드"

**개선 모드 트리거 조건**:
```markdown
VALIDATION_SCORE < 90
```

**IMPROVEMENT_NEEDED 필드 형식**:
```markdown
IMPROVEMENT_NEEDED:
  - [agent-name]: [improvement request] ([impact on score])
  - [agent-name]: [improvement request] ([impact on score])
```

**예시**:
```markdown
VALIDATION_SCORE: 85/100
IMPROVEMENT_NEEDED:
  - overview-writer: Add more concrete practical use cases in impact section (-5점)
  - concepts-writer: Expert level needs more ECMAScript specification details (-7점)
  - quiz-writer: Improve difficulty distribution (too many easy questions) (-3점)
```

**개선 모드 핸드오프 순서**:
```
content-validator
    ↓ (VALIDATION_SCORE < 90)
첫 번째 개선 대상 (e.g., overview-writer)
    ↓ (개선 완료)
두 번째 개선 대상 (e.g., concepts-writer)
    ↓ (개선 완료)
세 번째 개선 대상 (e.g., quiz-writer)
    ↓ (모든 개선 완료)
content-validator (재검증)
```

**에이전트별 개선 모드 처리**:

**Precondition 검증** (개선 모드 감지):
```markdown
### Step 1: Validate Preconditions

- [ ] **PC-2: STATUS is valid**
  - Check: `STATUS == PENDING` (normal flow) OR `STATUS == IN_PROGRESS AND IMPROVEMENT_NEEDED contains [agent-name]` (improvement mode)
  - If STATUS == IN_PROGRESS:
    - **Improvement Mode Detected**: Read IMPROVEMENT_NEEDED field
    - Extract improvement request for [agent-name]
  - If fails: EXIT 1
```

**작업 수행** (개선 대상만 수정):
```markdown
### Step 2: Perform Work

**Normal Flow**:
- Generate [section-name] section from scratch

**Improvement Mode**:
- Read existing [section-name] section
- Read IMPROVEMENT_NEEDED entry for [agent-name]
- Modify ONLY the parts mentioned in improvement request
- DO NOT rewrite entire section (preserve well-written parts)
```

**HANDOFF LOG 엔트리** (IMPROVE 이벤트):
```markdown
### Step 3: Update Work Status Markers

**Improvement Mode**:
- Add HANDOFF LOG: `[IMPROVE] [agent-name] | [what was improved] | [timestamp]`
  - Example: `[IMPROVE] overview-writer | Added concrete practical use cases | 2025-10-17T15:00:00+09:00`
```

**IMPROVEMENT_NEEDED 클리어**:
```markdown
#### 3.4 (Improvement Mode Only) Remove from IMPROVEMENT_NEEDED

If IMPROVEMENT_NEEDED field exists and contains [agent-name] entry:
- Remove the [agent-name] line from IMPROVEMENT_NEEDED
- If IMPROVEMENT_NEEDED becomes empty, remove the field entirely
```

**다음 에이전트 결정**:
```markdown
#### 3.2 Update CURRENT_AGENT

**Improvement Mode**:
- If IMPROVEMENT_NEEDED has more entries after removing [agent-name]:
  - Set CURRENT_AGENT to next improvement target
  - Example: If IMPROVEMENT_NEEDED still has `concepts-writer` entry, set CURRENT_AGENT to `concepts-writer`
- If IMPROVEMENT_NEEDED is now empty:
  - Set CURRENT_AGENT to `content-validator` (for re-validation)
```

**개선 모드 완료 흐름**:
```markdown
1. content-validator sets IMPROVEMENT_NEEDED (3 agents)
2. CURRENT_AGENT → overview-writer (first improvement target)
3. overview-writer completes, removes itself from IMPROVEMENT_NEEDED
4. CURRENT_AGENT → concepts-writer (second improvement target)
5. concepts-writer completes, removes itself from IMPROVEMENT_NEEDED
6. CURRENT_AGENT → quiz-writer (third improvement target)
7. quiz-writer completes, removes itself from IMPROVEMENT_NEEDED
8. IMPROVEMENT_NEEDED is empty
9. CURRENT_AGENT → content-validator (re-validation)
10. content-validator validates again
    - If score >= 90: COMPLETE
    - If score < 90: Create new IMPROVEMENT_NEEDED (repeat cycle)
```

---

## Section 4 완료

**작성 내용 요약**:
- 4.1 Bounded Context 기반 책임 정의 (7개 에이전트 Context, 허용 작업, 금지 작업)
- 4.2 DO/DO NOT 표준화 (작성 패턴, 공통 금지 사항)
- 4.3 에이전트 간 협업 규칙 (읽기 전용 사용, 핸드오프, 개선 모드)

**핵심 원칙**:
- 각 에이전트 = 하나의 Bounded Context
- Context 경계 내에서만 쓰기 권한
- 이전 에이전트 출력물은 읽기 전용
- 핸드오프는 CURRENT_AGENT 업데이트로 구현
- 개선 모드는 IMPROVEMENT_NEEDED 기반 순환 처리

**다음 섹션**: Section 5 - Work Status Markers 조작 표준화

---

## Section 5: Work Status Markers 조작 표준화 (WSM Manipulation Standards)

### 5.1 마커 조작 책임 명확화

#### 5.1.1 에이전트 vs Orchestration 책임 분리

**원칙** (Unit 1 Section 3.1, Unit 2 Section 4.4.3):
> "에이전트는 자신의 작업 결과만 기록하고, 외부 이벤트는 Orchestration이 기록한다."

**책임 분리 이유**:
1. **단일 책임 원칙**: 에이전트는 콘텐츠 생성에만 집중
2. **관심사 분리**: 파이프라인 관리는 Orchestration 책임
3. **일관성 보장**: 외부 이벤트는 Orchestration이 일관되게 기록
4. **디버깅 용이**: 문제 발생 시 책임 주체 명확

**책임 매트릭스**:

| EVENT_TYPE | 기록 주체 | 시점 | 예시 |
|------------|----------|------|------|
| **START** | Orchestration | 파이프라인 시작 | `[START] pipeline \| Content generation started \| [timestamp]` |
| **DONE** | Agent | 작업 정상 완료 (첫 시도) | `[DONE] overview-writer \| Overview section completed \| [timestamp]` |
| **IMPROVE** | Agent | 작업 개선 완료 | `[IMPROVE] overview-writer \| Added concrete use cases \| [timestamp]` |
| **SKIP** | Agent 또는 Orchestration | 작업 건너뜀 | `[SKIP] visualization-writer \| No visualization needed \| [timestamp]` |
| **FAILURE** | Orchestration | 에이전트 실행 실패 (외부) | `[FAILURE] concepts-writer \| Agent timeout after 10 minutes \| [timestamp]` |
| **COMPLETE** | Agent (content-validator) | 파이프라인 완료 | `[COMPLETE] content-validator \| Validation passed (95점) \| [timestamp]` |

#### 5.1.2 에이전트 책임: 작업 결과 기록 (DONE, IMPROVE)

**에이전트가 기록하는 이벤트**:

**1. DONE 이벤트** (Normal Flow 완료):
```markdown
[DONE] [agent-name] | [completion message] | YYYY-MM-DDTHH:MM:SS+09:00
```

**기록 시점**:
- Postconditions 검증 통과 후
- CURRENT_AGENT를 다음 에이전트로 업데이트하기 직전

**예시**:
```markdown
[DONE] overview-writer | Overview section completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core Concepts with 3 difficulty levels completed | 2025-10-17T10:45:00+09:00
[DONE] quiz-writer | 10 quiz questions across 6 types completed | 2025-10-17T11:20:00+09:00
```

**2. IMPROVE 이벤트** (Improvement Mode 완료):
```markdown
[IMPROVE] [agent-name] | [what was improved] | YYYY-MM-DDTHH:MM:SS+09:00
```

**기록 시점**:
- IMPROVEMENT_NEEDED에 포함된 에이전트가 개선 완료 후
- 자신을 IMPROVEMENT_NEEDED에서 제거하기 직전

**예시**:
```markdown
[IMPROVE] overview-writer | Added concrete practical use cases in impact section | 2025-10-17T15:00:00+09:00
[IMPROVE] concepts-writer | Enhanced Expert level with ECMAScript specification details | 2025-10-17T15:15:00+09:00
```

**3. SKIP 이벤트** (선택 작업 생략):
```markdown
[SKIP] [agent-name] | [skip reason] | YYYY-MM-DDTHH:MM:SS+09:00
```

**기록 시점**:
- 선택적 작업을 수행하지 않기로 결정한 경우 (예: visualization-writer)

**예시**:
```markdown
[SKIP] visualization-writer | No visualization needed for this topic | 2025-10-17T10:46:00+09:00
```

**4. COMPLETE 이벤트** (파이프라인 완료):
```markdown
[COMPLETE] content-validator | Validation passed (score: [score]) | YYYY-MM-DDTHH:MM:SS+09:00
```

**기록 주체**: content-validator만 (특수 케이스)

**예시**:
```markdown
[COMPLETE] content-validator | Validation passed (score: 95) | 2025-10-17T11:30:00+09:00
```

#### 5.1.3 Orchestration 책임: 외부 이벤트 기록 (START, FAILURE)

**Orchestration이 기록하는 이벤트**:

**1. START 이벤트** (파이프라인 시작):
```markdown
[START] pipeline | Content generation started | YYYY-MM-DDTHH:MM:SS+09:00
```

**기록 시점**:
- content-initiator 실행 전
- Orchestration 스크립트가 파이프라인 시작 시

**예시**:
```markdown
[START] pipeline | Content generation started | 2025-10-17T10:00:00+09:00
```

**2. FAILURE 이벤트** (외부 실패):
```markdown
[FAILURE] [agent-name] | [external failure reason] | YYYY-MM-DDTHH:MM:SS+09:00
```

**기록 시점**:
- 에이전트 실행 타임아웃
- 에이전트 프로세스 크래시
- 시스템 오류 (디스크 풀, 메모리 부족 등)

**예시**:
```markdown
[FAILURE] concepts-writer | Agent timeout after 10 minutes | 2025-10-17T10:50:00+09:00
[FAILURE] quiz-writer | Agent process crashed (exit code: 137) | 2025-10-17T11:25:00+09:00
[FAILURE] practice-writer | Disk full error while writing Practice section | 2025-10-17T11:10:00+09:00
```

**FAILURE vs 에이전트 내부 EXIT 1 비교**:

| 구분 | FAILURE (Orchestration) | EXIT 1 (Agent 내부) |
|------|-------------------------|---------------------|
| **발생 원인** | 외부 요인 (타임아웃, 크래시, 시스템 오류) | 내부 검증 실패 (Precondition, Postcondition) |
| **기록 주체** | Orchestration | Agent (EXIT 전 HANDOFF LOG 기록) |
| **HANDOFF LOG** | Orchestration이 추가 | Agent가 추가 후 EXIT 1 |
| **STATUS** | Orchestration이 FAILED로 변경 | Agent가 FAILED로 변경 후 EXIT 1 |
| **예시** | 10분 타임아웃, 프로세스 크래시 | CURRENT_AGENT 불일치, Overview 섹션 없음 |

**에이전트 내부 실패 예시** (에이전트가 기록):
```markdown
[FAILURE] overview-writer | Precondition failed: CURRENT_AGENT is 'concepts-writer', expected 'overview-writer' | 2025-10-17T10:05:00+09:00
```
→ 이 경우 에이전트가 HANDOFF LOG에 기록 후 EXIT 1

---

### 5.2 HANDOFF LOG 기록 패턴

#### 5.2.1 이벤트 타입별 기록 형식

**표준 형식** (Unit 1 명세):
```
[EVENT_TYPE] actor | message | YYYY-MM-DDTHH:MM:SS+09:00
```

**필드 설명**:
- `[EVENT_TYPE]`: START, DONE, IMPROVE, SKIP, FAILURE, COMPLETE (대문자, 대괄호 포함)
- `actor`: 이벤트 주체 (에이전트 이름 또는 "pipeline")
- `message`: 이벤트 설명 (간결한 한 줄)
- `timestamp`: ISO 8601 형식 (+09:00 타임존 포함)

**이벤트 타입별 상세**:

**START**:
```markdown
Format: [START] pipeline | Content generation started | [timestamp]
Actor: pipeline (고정)
Message: "Content generation started" (고정)
```

**DONE**:
```markdown
Format: [DONE] [agent-name] | [section-name] completed | [timestamp]
Actor: agent-name (overview-writer, concepts-writer, ...)
Message Pattern: "[section-name] completed" or "[section-name] with [details] completed"
```

**예시**:
```markdown
[DONE] overview-writer | Overview section completed | 2025-10-17T10:15:00+09:00
[DONE] concepts-writer | Core Concepts with 3 difficulty levels completed | 2025-10-17T10:45:00+09:00
[DONE] visualization-writer | Created ClosureVisualization component | 2025-10-17T10:50:00+09:00
```

**IMPROVE**:
```markdown
Format: [IMPROVE] [agent-name] | [what was improved] | [timestamp]
Actor: agent-name
Message Pattern: "[Improvement description]" (구체적으로)
```

**예시**:
```markdown
[IMPROVE] overview-writer | Added concrete practical use cases in impact section | 2025-10-17T15:00:00+09:00
[IMPROVE] concepts-writer | Enhanced Expert level with ECMAScript specification details | 2025-10-17T15:15:00+09:00
[IMPROVE] quiz-writer | Improved difficulty distribution (added more level 3-4 questions) | 2025-10-17T15:30:00+09:00
```

**SKIP**:
```markdown
Format: [SKIP] [agent-name] | [skip reason] | [timestamp]
Actor: agent-name
Message Pattern: "[Reason for skipping]"
```

**예시**:
```markdown
[SKIP] visualization-writer | No visualization needed for this topic | 2025-10-17T10:46:00+09:00
[SKIP] visualization-writer | Topic is too abstract for visualization | 2025-10-17T10:46:00+09:00
```

**FAILURE**:
```markdown
Format: [FAILURE] [agent-name or actor] | [failure reason] | [timestamp]
Actor: agent-name (내부 실패) or "orchestration" (외부 실패)
Message Pattern: "[Failure type]: [details]"
```

**예시 (에이전트 내부 실패)**:
```markdown
[FAILURE] overview-writer | Precondition failed: CURRENT_AGENT mismatch | 2025-10-17T10:05:00+09:00
[FAILURE] concepts-writer | Postcondition failed: Core Concepts section missing | 2025-10-17T10:50:00+09:00
```

**예시 (Orchestration 외부 실패)**:
```markdown
[FAILURE] concepts-writer | Agent timeout after 10 minutes | 2025-10-17T10:50:00+09:00
[FAILURE] quiz-writer | Agent process crashed (exit code: 137) | 2025-10-17T11:25:00+09:00
```

**COMPLETE**:
```markdown
Format: [COMPLETE] content-validator | Validation passed (score: [score]) | [timestamp]
Actor: content-validator (고정)
Message Pattern: "Validation passed (score: [score])"
```

**예시**:
```markdown
[COMPLETE] content-validator | Validation passed (score: 95) | 2025-10-17T11:30:00+09:00
[COMPLETE] content-validator | Validation passed (score: 92) | 2025-10-17T15:45:00+09:00
```

#### 5.2.2 타임스탬프 형식 (ISO 8601)

**표준 형식**:
```
YYYY-MM-DDTHH:MM:SS+09:00
```

**필드 설명**:
- `YYYY`: 4자리 연도 (예: 2025)
- `MM`: 2자리 월 (01-12)
- `DD`: 2자리 일 (01-31)
- `T`: 날짜와 시간 구분자 (고정)
- `HH`: 2자리 시간 (00-23, 24시간 형식)
- `MM`: 2자리 분 (00-59)
- `SS`: 2자리 초 (00-59)
- `+09:00`: 타임존 (한국 표준시 고정)

**예시**:
```
2025-10-17T10:00:00+09:00  ✅ 올바름
2025-10-17T14:30:45+09:00  ✅ 올바름
2025-10-17 10:00:00        ❌ T 구분자 없음
2025-10-17T10:00:00        ❌ 타임존 없음
10/17/2025 10:00 AM        ❌ 잘못된 형식
```

**프롬프트 지시문 예시**:
```markdown
### Step 3: Update Work Status Markers

#### 3.2 Prepare HANDOFF LOG Entry

**Timestamp Format**: Use ISO 8601 with +09:00 timezone
- Format: `YYYY-MM-DDTHH:MM:SS+09:00`
- Example: `2025-10-17T14:30:00+09:00`
- Get current time and format it correctly
```

#### 5.2.3 메시지 작성 가이드라인

**메시지 작성 원칙**:
1. **간결성**: 한 줄로 요약 (50-80자 권장)
2. **명확성**: 무엇을 했는지 명확히
3. **일관성**: 동일한 이벤트 타입은 유사한 패턴 사용
4. **구체성**: 추상적 표현 대신 구체적 내용

**좋은 메시지 vs 나쁜 메시지**:

| 이벤트 | ❌ 나쁜 메시지 | ✅ 좋은 메시지 |
|--------|---------------|---------------|
| DONE | "작업 완료" | "Overview section completed" |
| DONE | "Concepts 섹션 작성함" | "Core Concepts with 3 difficulty levels completed" |
| IMPROVE | "개선 완료" | "Added concrete practical use cases in impact section" |
| IMPROVE | "Expert 레벨 보강" | "Enhanced Expert level with ECMAScript specification details" |
| SKIP | "건너뜀" | "No visualization needed for this topic" |
| FAILURE | "오류 발생" | "Precondition failed: CURRENT_AGENT mismatch" |

**메시지 패턴 (에이전트별)**:

**overview-writer**:
- DONE: "Overview section completed"
- IMPROVE: "Added [what] in [where] section"

**concepts-writer**:
- DONE: "Core Concepts with 3 difficulty levels completed"
- IMPROVE: "Enhanced [difficulty-level] level with [what]"

**visualization-writer**:
- DONE: "Created [ComponentName] component"
- SKIP: "No visualization needed for this topic"

**practice-writer**:
- DONE: "Practice section with [N] patterns and [M] experiments completed"
- IMPROVE: "Added [what] to [where]"

**quiz-writer**:
- DONE: "[N] quiz questions across [M] types completed"
- IMPROVE: "Improved difficulty distribution ([what changed])"

**content-validator**:
- DONE: "Validation completed - improvements needed"
- COMPLETE: "Validation passed (score: [score])"

---

### 5.3 CURRENT_AGENT 업데이트 규칙

#### 5.3.1 정상 완료 시: 다음 에이전트로 업데이트

**규칙**:
> "에이전트는 작업 완료 후 CURRENT_AGENT를 다음 에이전트로 업데이트한다."

**Next Agent Mapping** (Section 4.3.2 참조):
```
content-initiator    → overview-writer
overview-writer      → concepts-writer
concepts-writer      → visualization-writer
visualization-writer → practice-writer
practice-writer      → quiz-writer
quiz-writer          → content-validator
content-validator    → "" (empty string, if VALIDATION_SCORE >= 90)
```

**프롬프트 지시문 템플릿**:
```markdown
### Step 3: Update Work Status Markers

#### 3.2 Update CURRENT_AGENT

**Normal Flow**:
- Set CURRENT_AGENT to `[next-agent]`

**Next Agent**: `[next-agent-name]`
```

**예시 (overview-writer)**:
```markdown
#### 3.2 Update CURRENT_AGENT

**Normal Flow**:
- Set CURRENT_AGENT to `concepts-writer`

**Next Agent**: `concepts-writer`
```

#### 5.3.2 개선 모드: 첫 번째 개선 대상 에이전트로 업데이트

**규칙**:
> "에이전트는 자신의 개선 완료 후, IMPROVEMENT_NEEDED에 남아있는 첫 번째 에이전트로 CURRENT_AGENT를 업데이트한다."

**IMPROVEMENT_NEEDED 처리 로직**:

**Case 1**: 개선 대상이 더 남아있음
```markdown
# Before (content-validator가 설정)
IMPROVEMENT_NEEDED:
  - overview-writer: Add more concrete use cases (-5점)
  - concepts-writer: Expert level needs more details (-7점)
  - quiz-writer: Improve difficulty distribution (-3점)

# After overview-writer completes
IMPROVEMENT_NEEDED:
  - concepts-writer: Expert level needs more details (-7점)
  - quiz-writer: Improve difficulty distribution (-3점)

CURRENT_AGENT: concepts-writer  ← 다음 개선 대상
```

**Case 2**: 자신이 마지막 개선 대상
```markdown
# Before
IMPROVEMENT_NEEDED:
  - quiz-writer: Improve difficulty distribution (-3점)

# After quiz-writer completes
IMPROVEMENT_NEEDED:
  (field removed - empty)

CURRENT_AGENT: content-validator  ← 재검증
```

**프롬프트 지시문 템플릿**:
```markdown
#### 3.2 Update CURRENT_AGENT

**Improvement Mode**:
- If IMPROVEMENT_NEEDED has more entries after removing [agent-name]:
  - Set CURRENT_AGENT to next improvement target
  - Example: If IMPROVEMENT_NEEDED still has `concepts-writer` entry, set CURRENT_AGENT to `concepts-writer`
- If IMPROVEMENT_NEEDED is now empty:
  - Set CURRENT_AGENT to `content-validator` (for re-validation)
```

#### 5.3.3 최종 완료 시 (content-validator): 빈 문자열로 설정

**규칙** (content-validator 전용):
> "VALIDATION_SCORE >= 90이면 CURRENT_AGENT를 빈 문자열로 설정하여 파이프라인 완료를 표시한다."

**조건부 로직**:
```markdown
### Step 3: Update Work Status Markers

#### 3.2 Update CURRENT_AGENT

**If VALIDATION_SCORE >= 90** (pipeline complete):
- Add HANDOFF LOG: `[COMPLETE] content-validator | Validation passed (score: [score]) | [timestamp]`
- Set CURRENT_AGENT to `""` (empty string)
- Set STATUS to `COMPLETED`

**If VALIDATION_SCORE < 90** (improvement needed):
- Add HANDOFF LOG: `[DONE] content-validator | Validation completed - improvements needed | [timestamp]`
- Set CURRENT_AGENT to first improvement target (e.g., `overview-writer`)
- Set IMPROVEMENT_NEEDED field
- Keep STATUS as `IN_PROGRESS`
```

**CURRENT_AGENT 빈 문자열의 의미**:
- 파이프라인 완료
- 더 이상 실행할 에이전트 없음
- Orchestration은 이를 감지하여 파이프라인 종료

---

### 5.4 STATUS 업데이트 규칙

#### 5.4.1 STATUS 전이 다이어그램

**정상 흐름**:
```
PENDING (초기)
    ↓ (content-initiator 시작)
IN_PROGRESS
    ↓ (content-validator 검증 통과, score >= 90)
COMPLETED (최종)
```

**실패 흐름**:
```
PENDING or IN_PROGRESS
    ↓ (Precondition 실패 또는 외부 오류)
FAILED
```

**개선 흐름**:
```
IN_PROGRESS
    ↓ (content-validator 검증, score < 90)
IN_PROGRESS (유지)
    ↓ (모든 개선 완료 후 재검증, score >= 90)
COMPLETED
```

#### 5.4.2 STATUS 값 정의 (Unit 1 명세)

| STATUS | 의미 | 설정 주체 | 설정 시점 |
|--------|------|----------|----------|
| **PENDING** | 파이프라인 시작 전 | content-initiator | Work Status Markers 초기화 시 |
| **IN_PROGRESS** | 파이프라인 실행 중 | content-initiator | 첫 에이전트(overview-writer)로 핸드오프 시 |
| **COMPLETED** | 파이프라인 완료 | content-validator | VALIDATION_SCORE >= 90일 때 |
| **FAILED** | 파이프라인 실패 | Agent 또는 Orchestration | Precondition 실패, 외부 오류 발생 시 |

#### 5.4.3 에이전트별 STATUS 업데이트 패턴

**content-initiator** (특수 케이스):
```markdown
### Step 2: Initialize Work Status Markers

Set initial values:
- CURRENT_AGENT: overview-writer
- STATUS: PENDING
- STARTED: [current timestamp]
- UPDATED: [current timestamp]
- HANDOFF LOG:
  [START] pipeline | Content generation started | [timestamp]
```

**일반 에이전트** (overview-writer, concepts-writer, ...):
```markdown
### Step 3: Update Work Status Markers

**Do NOT modify STATUS**:
- STATUS remains `IN_PROGRESS`
- Only content-validator can change STATUS to COMPLETED or FAILED
```

**content-validator** (특수 케이스):
```markdown
### Step 3: Update Work Status Markers

**If VALIDATION_SCORE >= 90**:
- Set STATUS to `COMPLETED`
- Set CURRENT_AGENT to `""`

**If VALIDATION_SCORE < 90**:
- Keep STATUS as `IN_PROGRESS`
- Set CURRENT_AGENT to first improvement target
```

**실패 시** (모든 에이전트):
```markdown
### Error Handling

**On Precondition Failure**:
- Add [FAILURE] entry to HANDOFF LOG
- Set STATUS to `FAILED`
- EXIT 1

**On Postcondition Failure**:
- Add [FAILURE] entry to HANDOFF LOG
- Set STATUS to `FAILED`
- EXIT 1
```

#### 5.4.4 STATUS와 CURRENT_AGENT 일관성 규칙

**일관성 규칙**:

| STATUS | CURRENT_AGENT | 유효성 | 의미 |
|--------|---------------|--------|------|
| PENDING | overview-writer | ✅ | 초기 상태, 첫 에이전트 대기 |
| IN_PROGRESS | overview-writer, concepts-writer, ... | ✅ | 파이프라인 실행 중 |
| IN_PROGRESS | "" (empty) | ❌ | 불일치 (에러 상태) |
| COMPLETED | "" (empty) | ✅ | 파이프라인 정상 완료 |
| COMPLETED | overview-writer | ❌ | 불일치 (에러 상태) |
| FAILED | (any value) | ✅ | 실패 지점 표시 |

**검증 로직** (Orchestration 또는 디버깅 시 사용):
```bash
# STATUS와 CURRENT_AGENT 일관성 검증
check_consistency() {
    local status="$1"
    local current_agent="$2"

    if [[ "$status" == "COMPLETED" && "$current_agent" != "" ]]; then
        echo "ERROR: Inconsistency - STATUS is COMPLETED but CURRENT_AGENT is not empty"
        return 1
    fi

    if [[ "$status" == "IN_PROGRESS" && "$current_agent" == "" ]]; then
        echo "ERROR: Inconsistency - STATUS is IN_PROGRESS but CURRENT_AGENT is empty"
        return 1
    fi

    return 0
}
```

---

## Section 5 완료

**작성 내용 요약**:
- 5.1 마커 조작 책임 명확화 (에이전트 vs Orchestration 책임 분리, 책임 매트릭스)
- 5.2 HANDOFF LOG 기록 패턴 (6개 이벤트 타입별 형식, 타임스탬프, 메시지 가이드라인)
- 5.3 CURRENT_AGENT 업데이트 규칙 (정상 완료, 개선 모드, 최종 완료)
- 5.4 STATUS 업데이트 규칙 (전이 다이어그램, 에이전트별 패턴, 일관성 규칙)

**핵심 원칙**:
- 에이전트는 자신의 작업 결과만 기록 (DONE, IMPROVE, SKIP, COMPLETE)
- Orchestration은 외부 이벤트 기록 (START, FAILURE)
- ISO 8601 타임스탬프 필수 (`YYYY-MM-DDTHH:MM:SS+09:00`)
- STATUS는 content-validator만 COMPLETED로 변경 가능
- CURRENT_AGENT 빈 문자열 = 파이프라인 완료

**다음 섹션**: Section 6 - 오류 처리 표준화

---

## Section 6: 오류 처리 표준화 (Error Handling Standardization)

### 6.1 Fail-Fast 전략

#### 6.1.1 Fail-Fast 정의 및 원칙

**정의**:
> "오류를 발견하는 즉시 작업을 중단하고, 명확한 오류 메시지를 출력하며, 시스템을 안전한 상태로 만든 후 종료하는 전략"

**Fail-Fast의 핵심 원칙**:
1. **조기 검증**: 작업 시작 전 모든 Preconditions 검증
2. **즉시 중단**: 조건 불만족 시 작업 수행하지 않고 즉시 EXIT 1
3. **명확한 오류**: 무엇이 잘못되었는지, 어떻게 고쳐야 하는지 명시
4. **안전한 상태**: 부분 작업 롤백, STATUS를 FAILED로 설정
5. **감사 기록**: HANDOFF LOG에 [FAILURE] 엔트리 추가

**Fail-Fast vs Fail-Safe 비교** (Section 1.2.3 재확인):

| 구분 | Fail-Fast | Fail-Safe |
|------|-----------|-----------|
| **정의** | 오류 발견 즉시 중단 | 오류 무시하고 계속 진행 |
| **장점** | 버그 조기 발견, 명확한 오류 지점 | 시스템 중단 없음 |
| **단점** | 시스템 중단 발생 | 버그 은폐, 디버깅 어려움 |
| **적용** | **콘텐츠 생성 파이프라인 (채택)** | 미션 크리티컬 시스템 |
| **예시** | CURRENT_AGENT 불일치 시 즉시 EXIT 1 | CURRENT_AGENT 불일치해도 계속 진행 (권장 안 함) |

**Fail-Fast 채택 이유** (Unit 3 Inception Question 2):
- 콘텐츠 품질 보장: 잘못된 상태에서 생성된 콘텐츠는 무의미
- 디버깅 용이: 오류 발생 지점 즉시 파악
- 데이터 무결성: 부분 작업으로 인한 파일 손상 방지

#### 6.1.2 Precondition 실패 시 즉시 중단

**Precondition 검증 시점**:
```markdown
## Execution Instructions

### Step 1: Validate Preconditions

**IMPORTANT**: Use Fail-Fast strategy. If any precondition fails, add [FAILURE] to HANDOFF LOG and EXIT 1 immediately.
```

**Precondition 실패 시 처리 절차**:

1. **오류 메시지 출력**:
```
ERROR: Precondition failed: [상세 메시지]
```

2. **HANDOFF LOG 엔트리 추가**:
```markdown
[FAILURE] [agent-name] | Precondition failed: [이유] | [timestamp]
```

3. **STATUS 업데이트**:
```
STATUS: FAILED
```

4. **즉시 종료**:
```
EXIT 1
```

**Precondition 검증 템플릿**:
```markdown
### Step 1: Validate Preconditions

- [ ] **PC-1: [조건 이름]**
  - Check: `[검증 조건]`
  - If fails:
    - Output: `ERROR: Precondition failed: [상세 메시지]`
    - Add HANDOFF LOG: `[FAILURE] [agent-name] | Precondition failed: [이유] | [timestamp]`
    - Set STATUS: FAILED
    - EXIT 1
```

**예시** (overview-writer):
```markdown
- [ ] **PC-1: CURRENT_AGENT matches**
  - Check: `CURRENT_AGENT == "overview-writer"`
  - If fails:
    - Output: `ERROR: Precondition failed: CURRENT_AGENT is 'concepts-writer', expected 'overview-writer'`
    - Add HANDOFF LOG: `[FAILURE] overview-writer | Precondition failed: CURRENT_AGENT mismatch | 2025-10-17T10:05:00+09:00`
    - Set STATUS: FAILED
    - EXIT 1
```

#### 6.1.3 명확한 오류 메시지 출력

**오류 메시지 형식**:
```
ERROR: [오류 타입] - [상세 설명]
```

**오류 메시지 작성 원칙**:
1. **구체성**: "오류 발생" 대신 "CURRENT_AGENT is 'X', expected 'Y'"
2. **실행 가능성**: 어떻게 고쳐야 하는지 힌트 제공 (선택적)
3. **일관성**: 동일한 오류 타입은 동일한 형식 사용
4. **간결성**: 한 줄로 요약 (필요 시 2-3줄)

**좋은 오류 메시지 vs 나쁜 오류 메시지**:

| 오류 타입 | ❌ 나쁜 메시지 | ✅ 좋은 메시지 |
|-----------|---------------|---------------|
| Precondition 실패 | "오류 발생" | "ERROR: Precondition failed: CURRENT_AGENT is 'concepts-writer', expected 'overview-writer'" |
| 필수 섹션 없음 | "섹션 없음" | "ERROR: Precondition failed: frontmatter is missing" |
| Postcondition 실패 | "검증 실패" | "ERROR: Postcondition failed: Overview section is missing or incomplete" |
| 파일 쓰기 실패 | "파일 오류" | "ERROR: File write error: Permission denied for /path/to/file.md" |

**오류 메시지 예시** (에이전트별):

**overview-writer**:
```
ERROR: Precondition failed: CURRENT_AGENT is 'concepts-writer', expected 'overview-writer'
ERROR: Precondition failed: frontmatter is missing
ERROR: Postcondition failed: Overview section is missing or incomplete
ERROR: Postcondition failed: Section length is 150 lines, expected 50-100 lines
```

**concepts-writer**:
```
ERROR: Precondition failed: Overview section not found (required by concepts-writer)
ERROR: Postcondition failed: Core Concepts section is missing
ERROR: Postcondition failed: Easy difficulty level is missing
```

#### 6.1.4 HANDOFF LOG에 FAILURE 기록

**FAILURE 엔트리 형식** (Section 5.2.1 참조):
```
[FAILURE] [agent-name] | [failure reason] | YYYY-MM-DDTHH:MM:SS+09:00
```

**FAILURE 메시지 패턴**:
- **Precondition 실패**: "Precondition failed: [이유]"
- **Postcondition 실패**: "Postcondition failed: [이유]"
- **작업 중 오류**: "[오류 타입]: [상세]"

**FAILURE 엔트리 예시**:
```markdown
[FAILURE] overview-writer | Precondition failed: CURRENT_AGENT mismatch | 2025-10-17T10:05:00+09:00
[FAILURE] concepts-writer | Postcondition failed: Core Concepts section missing | 2025-10-17T10:50:00+09:00
[FAILURE] quiz-writer | Content generation failed: Unable to parse frontmatter | 2025-10-17T11:25:00+09:00
```

**HANDOFF LOG 기록 시점**:
- 오류 메시지 출력 직후
- STATUS를 FAILED로 설정하기 전
- EXIT 1 직전

---

### 6.2 오류 시나리오 분류

#### 6.2.1 Precondition 실패

**정의**: 작업 시작 전 필수 조건이 충족되지 않음

**주요 Precondition 실패 시나리오**:

**1. CURRENT_AGENT 불일치**:
```markdown
**시나리오**: CURRENT_AGENT가 자신이 아닌 다른 에이전트로 설정됨

**원인**:
- 이전 에이전트가 CURRENT_AGENT를 잘못 업데이트
- Orchestration이 잘못된 에이전트 실행
- 수동 편집으로 CURRENT_AGENT 변경

**오류 메시지**:
ERROR: Precondition failed: CURRENT_AGENT is 'concepts-writer', expected 'overview-writer'

**HANDOFF LOG**:
[FAILURE] overview-writer | Precondition failed: CURRENT_AGENT mismatch | [timestamp]

**복구 방법**:
- CURRENT_AGENT를 올바른 값으로 수정
- 또는 올바른 에이전트 실행
```

**2. 필수 섹션 없음**:
```markdown
**시나리오**: 이전 에이전트가 생성해야 할 섹션이 존재하지 않음

**원인**:
- 이전 에이전트 실패 후 파일 손상
- 수동 편집으로 섹션 삭제
- 이전 에이전트가 섹션 생성 건너뜀

**오류 메시지**:
ERROR: Precondition failed: Overview section not found (required by concepts-writer)

**HANDOFF LOG**:
[FAILURE] concepts-writer | Precondition failed: Missing Overview section | [timestamp]

**복구 방법**:
- 이전 에이전트(overview-writer) 재실행
```

**3. frontmatter 없음**:
```markdown
**시나리오**: YAML frontmatter가 없거나 필수 필드 누락

**원인**:
- content-initiator 실패
- 수동 편집으로 frontmatter 삭제
- 파일 손상

**오류 메시지**:
ERROR: Precondition failed: frontmatter is missing or incomplete

**HANDOFF LOG**:
[FAILURE] overview-writer | Precondition failed: Missing frontmatter | [timestamp]

**복구 방법**:
- content-initiator 재실행
- 또는 수동으로 frontmatter 복구
```

**4. HANDOFF LOG [START] 엔트리 없음**:
```markdown
**시나리오**: HANDOFF LOG에 [START] 엔트리가 없음

**원인**:
- Work Status Markers 손상
- Orchestration이 [START] 기록 실패

**오류 메시지**:
ERROR: Precondition failed: No [START] entry in HANDOFF LOG

**HANDOFF LOG**:
[FAILURE] overview-writer | Precondition failed: Missing [START] entry | [timestamp]

**복구 방법**:
- HANDOFF LOG에 [START] 엔트리 수동 추가
```

#### 6.2.2 작업 중 오류

**정의**: 작업 수행 중 예상치 못한 오류 발생

**주요 작업 중 오류 시나리오**:

**1. 콘텐츠 생성 실패**:
```markdown
**시나리오**: AI 모델이 콘텐츠 생성에 실패하거나 부적절한 출력 생성

**원인**:
- AI 모델 오류 (API timeout, rate limit)
- 프롬프트 지시사항 불명확
- 입력 데이터 부족 또는 손상

**오류 메시지**:
ERROR: Content generation failed: AI model timeout after 5 minutes

**HANDOFF LOG**:
[FAILURE] concepts-writer | Content generation failed: Model timeout | [timestamp]

**처리 방법**:
- Rollback partial work (remove incomplete section)
- Set STATUS: FAILED
- EXIT 1
```

**2. 파일 쓰기 실패**:
```markdown
**시나리오**: 파일 시스템 오류로 파일 쓰기 실패

**원인**:
- 디스크 풀 (disk full)
- 권한 부족 (permission denied)
- 파일 락 (file locked by another process)

**오류 메시지**:
ERROR: File write error: Permission denied for /path/to/file.md

**HANDOFF LOG**:
[FAILURE] overview-writer | File write error: Permission denied | [timestamp]

**처리 방법**:
- Do NOT rollback (file write failed, nothing written)
- Set STATUS: FAILED
- EXIT 1
```

**3. 파싱 실패**:
```markdown
**시나리오**: frontmatter, Work Status Markers, 또는 기존 섹션 파싱 실패

**원인**:
- YAML 형식 오류 (frontmatter)
- HTML 주석 형식 오류 (Work Status Markers)
- 마크다운 구조 손상

**오류 메시지**:
ERROR: Parsing failed: Unable to parse frontmatter (invalid YAML syntax)

**HANDOFF LOG**:
[FAILURE] overview-writer | Parsing failed: Invalid frontmatter YAML | [timestamp]

**처리 방법**:
- Set STATUS: FAILED
- EXIT 1
```

#### 6.2.3 Postcondition 실패

**정의**: 작업 완료 후 출력물이 기대한 상태가 아님

**주요 Postcondition 실패 시나리오**:

**1. 출력 섹션 없음**:
```markdown
**시나리오**: 생성해야 할 섹션이 파일에 존재하지 않음

**원인**:
- 콘텐츠 생성 로직 버그
- 파일 쓰기 중 부분 실패
- 잘못된 섹션 위치 (다른 곳에 작성)

**오류 메시지**:
ERROR: Postcondition failed: Overview section is missing or incomplete

**HANDOFF LOG**:
[FAILURE] overview-writer | Postcondition failed: Incomplete Overview | [timestamp]

**처리 방법**:
- Rollback: Remove incomplete Overview section
- Set STATUS: FAILED
- EXIT 1
```

**2. CURRENT_AGENT 업데이트 실패**:
```markdown
**시나리오**: CURRENT_AGENT가 다음 에이전트로 업데이트되지 않음

**원인**:
- Work Status Markers 업데이트 로직 버그
- 파일 쓰기 중 부분 실패

**오류 메시지**:
ERROR: Postcondition failed: CURRENT_AGENT not updated correctly

**HANDOFF LOG**:
[FAILURE] overview-writer | Postcondition failed: CURRENT_AGENT not updated | [timestamp]

**처리 방법**:
- Set STATUS: FAILED
- EXIT 1
```

**3. HANDOFF LOG 엔트리 없음**:
```markdown
**시나리오**: 자신의 [DONE] 또는 [IMPROVE] 엔트리가 HANDOFF LOG에 없음

**원인**:
- HANDOFF LOG 업데이트 로직 버그
- 파일 쓰기 중 부분 실패

**오류 메시지**:
ERROR: Postcondition failed: HANDOFF LOG entry missing or malformed

**HANDOFF LOG**:
[FAILURE] overview-writer | Postcondition failed: Missing HANDOFF LOG entry | [timestamp]

**처리 방법**:
- Set STATUS: FAILED
- EXIT 1
```

**4. 품질 기준 미달**:
```markdown
**시나리오**: 생성된 콘텐츠가 품질 기준을 만족하지 못함

**원인**:
- 콘텐츠 길이 초과/미달
- 금지된 요소 포함 (코드 블록, 깊은 헤더 등)
- 필수 하위 섹션 누락

**오류 메시지**:
ERROR: Postcondition failed: Content quality standards not met
- Section length is 150 lines, expected 50-100 lines
- Code blocks found in Overview section (not allowed)

**HANDOFF LOG**:
[FAILURE] overview-writer | Postcondition failed: Quality standards not met | [timestamp]

**처리 방법**:
- Rollback: Remove non-compliant section
- Set STATUS: FAILED
- EXIT 1
```

---

### 6.3 오류 메시지 형식 표준화

#### 6.3.1 표준 오류 메시지 형식

**형식**:
```
ERROR: [오류 타입] - [상세 설명]
```

**오류 타입 분류**:
1. **Precondition failed**: Precondition 검증 실패
2. **Postcondition failed**: Postcondition 검증 실패
3. **Content generation failed**: 콘텐츠 생성 중 오류
4. **File write error**: 파일 쓰기 오류
5. **Parsing failed**: 파싱 오류
6. **Validation failed**: 검증 오류

**상세 설명 패턴**:
- **비교 오류**: "[실제값] is '[actual]', expected '[expected]'"
- **누락 오류**: "[대상] is missing"
- **형식 오류**: "[대상] format is invalid"
- **품질 오류**: "[품질 기준] not met: [상세]"

#### 6.3.2 오류 타입별 메시지 패턴

**Precondition failed**:
```
ERROR: Precondition failed: CURRENT_AGENT is 'concepts-writer', expected 'overview-writer'
ERROR: Precondition failed: frontmatter is missing or incomplete
ERROR: Precondition failed: STATUS is 'COMPLETED', expected 'PENDING' or 'IN_PROGRESS'
ERROR: Precondition failed: Overview section not found (required by concepts-writer)
ERROR: Precondition failed: No [START] entry in HANDOFF LOG
```

**Postcondition failed**:
```
ERROR: Postcondition failed: Overview section is missing or incomplete
ERROR: Postcondition failed: CURRENT_AGENT not updated correctly
ERROR: Postcondition failed: HANDOFF LOG entry missing or malformed
ERROR: Postcondition failed: Content quality standards not met
  - Section length is 150 lines, expected 50-100 lines
  - Code blocks found (not allowed)
```

**Content generation failed**:
```
ERROR: Content generation failed: AI model timeout after 5 minutes
ERROR: Content generation failed: Invalid response from AI model
ERROR: Content generation failed: Insufficient context to generate Expert level content
```

**File write error**:
```
ERROR: File write error: Permission denied for /path/to/file.md
ERROR: File write error: Disk full (no space left on device)
ERROR: File write error: File is locked by another process
```

**Parsing failed**:
```
ERROR: Parsing failed: Unable to parse frontmatter (invalid YAML syntax)
ERROR: Parsing failed: Work Status Markers not found in file
ERROR: Parsing failed: HANDOFF LOG format is invalid
```

**Validation failed**:
```
ERROR: Validation failed: Section length is 150 lines, expected 50-100 lines
ERROR: Validation failed: Code blocks found in Overview section (not allowed)
ERROR: Validation failed: Required subsection '## 핵심 특징' is missing
```

#### 6.3.3 에이전트별 오류 메시지 예시

**content-initiator**:
```
ERROR: Precondition failed: category.yaml not found
ERROR: File write error: Permission denied for target file
ERROR: Parsing failed: category.yaml has invalid YAML syntax
```

**overview-writer**:
```
ERROR: Precondition failed: CURRENT_AGENT is 'concepts-writer', expected 'overview-writer'
ERROR: Precondition failed: frontmatter is missing
ERROR: Content generation failed: Unable to generate Overview content
ERROR: Postcondition failed: Overview section is missing or incomplete
ERROR: Postcondition failed: Section length is 150 lines, expected 50-100 lines
```

**concepts-writer**:
```
ERROR: Precondition failed: Overview section not found
ERROR: Content generation failed: Unable to generate Expert level content
ERROR: Postcondition failed: Core Concepts section is missing
ERROR: Postcondition failed: Easy difficulty level is missing
```

**visualization-writer**:
```
ERROR: Precondition failed: Core Concepts section not found
ERROR: Content generation failed: Unable to generate React component
ERROR: File write error: Cannot write to src/components/visualizations/
ERROR: Postcondition failed: Component file not created
ERROR: Postcondition failed: index.ts not updated with new export
```

**practice-writer**:
```
ERROR: Precondition failed: Core Concepts section not found
ERROR: Content generation failed: Unable to generate code patterns
ERROR: Postcondition failed: Practice section is missing
ERROR: Postcondition failed: Minimum pattern count not met (found 1, expected 2)
```

**quiz-writer**:
```
ERROR: Precondition failed: Learning sections (Overview, Core Concepts, Practice) not found
ERROR: Content generation failed: Unable to generate quiz questions
ERROR: Postcondition failed: Quiz section is missing
ERROR: Postcondition failed: Minimum question count not met (found 6, expected 8)
ERROR: Postcondition failed: Difficulty distribution invalid (all questions are level 1-2)
```

**content-validator**:
```
ERROR: Precondition failed: Content sections (Overview, Core Concepts, Practice, Quiz) not complete
ERROR: Validation failed: VALIDATION_SCORE calculation error
ERROR: Postcondition failed: VALIDATION_SCORE not set
ERROR: Postcondition failed: IMPROVEMENT_NEEDED format invalid
```

---

### 6.4 오류 복구 지침

#### 6.4.1 에이전트는 복구 시도 없음 (Fail-Fast)

**원칙**:
> "에이전트는 오류 발생 시 복구를 시도하지 않고 즉시 실패한다. 복구는 Orchestration의 책임이다."

**에이전트가 하지 말아야 할 것**:
- ❌ **재시도 (Retry)**: 실패한 작업을 자동으로 다시 시도하지 않음
- ❌ **대체 로직 (Fallback)**: 오류 시 대체 방법으로 우회하지 않음
- ❌ **부분 완료 (Partial Completion)**: 일부만 성공해도 전체 실패로 처리
- ❌ **오류 무시 (Error Suppression)**: 오류를 숨기고 계속 진행하지 않음

**에이전트가 해야 할 것**:
- ✅ **명확한 오류 보고**: 무엇이 잘못되었는지 정확히 보고
- ✅ **안전한 상태 유지**: HANDOFF LOG 기록, STATUS: FAILED 설정
- ✅ **부분 작업 롤백**: 불완전한 출력물 제거 (가능한 경우)
- ✅ **즉시 종료**: EXIT 1

**잘못된 예** (복구 시도):
```markdown
<!-- 잘못된 프롬프트 -->
### Step 1: Validate Preconditions

- [ ] Check CURRENT_AGENT == "overview-writer"
  - If not: Try to fix CURRENT_AGENT automatically ← ❌ 복구 시도 금지!
```

**올바른 예** (Fail-Fast):
```markdown
### Step 1: Validate Preconditions

- [ ] Check CURRENT_AGENT == "overview-writer"
  - If not:
    - Output: ERROR message
    - Add [FAILURE] to HANDOFF LOG
    - Set STATUS: FAILED
    - EXIT 1 ← ✅ 즉시 실패
```

#### 6.4.2 Orchestration에서 재시도 또는 복구 처리

**Orchestration 책임**:
1. **에이전트 실행 모니터링**: 에이전트 exit code 확인
2. **실패 감지**: EXIT 1 또는 타임아웃 감지
3. **복구 전략 결정**: 재시도 여부, 수동 개입 필요 여부 판단
4. **재시도 실행**: 일시적 오류인 경우 에이전트 재실행
5. **알림**: 반복 실패 시 사용자에게 알림

**Orchestration 복구 전략**:

**전략 1: 자동 재시도** (Retry):
```bash
# Orchestration 스크립트 (예시)
max_retries=3
retry_count=0

while [[ $retry_count -lt $max_retries ]]; do
    # 에이전트 실행
    claude code -a overview-writer --file "$file"
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo "Agent overview-writer succeeded"
        break
    else
        retry_count=$((retry_count + 1))
        echo "Agent overview-writer failed (attempt $retry_count/$max_retries)"

        if [[ $retry_count -lt $max_retries ]]; then
            echo "Retrying in 5 seconds..."
            sleep 5
        fi
    fi
done

if [[ $retry_count -eq $max_retries ]]; then
    echo "ERROR: Agent overview-writer failed after $max_retries attempts"
    # 외부 FAILURE 기록
    add_handoff_log "[FAILURE] overview-writer | Agent failed after $max_retries retries | $(date -Iseconds)"
    exit 1
fi
```

**전략 2: 조건부 재시도**:
```bash
# 특정 오류만 재시도
if grep -q "AI model timeout" "$file"; then
    echo "Detected timeout error, retrying..."
    claude code -a overview-writer --file "$file"
elif grep -q "Precondition failed" "$file"; then
    echo "Precondition failed, fixing before retry..."
    # Precondition 수정 로직
    fix_preconditions "$file"
    claude code -a overview-writer --file "$file"
else
    echo "Unknown error, manual intervention required"
    exit 1
fi
```

**전략 3: 수동 개입 요청**:
```bash
# 자동 복구 불가능한 경우
if grep -q "Postcondition failed: Quality standards not met" "$file"; then
    echo "ERROR: Quality standards not met"
    echo "Manual review required:"
    echo "  - File: $file"
    echo "  - Agent: overview-writer"
    echo "  - Issue: Generated content does not meet quality standards"
    echo ""
    echo "Please review the file and either:"
    echo "  1. Manually fix the content"
    echo "  2. Adjust quality standards in the contract"
    echo "  3. Re-run the agent with different instructions"
    exit 1
fi
```

**전략 4: 롤백 후 재시도**:
```bash
# 파일 상태 복원 후 재시도
if [[ $exit_code -ne 0 ]]; then
    echo "Agent failed, rolling back to last known good state..."

    # Git 사용 시
    git checkout HEAD -- "$file"

    # 또는 백업 파일 사용 시
    cp "$file.backup" "$file"

    echo "Retrying with clean state..."
    claude code -a overview-writer --file "$file"
fi
```

#### 6.4.3 복구 불가능한 오류

**복구 불가능한 오류** (수동 개입 필요):

1. **데이터 손상**:
   - category.yaml 손상
   - frontmatter 구조 손상
   - Work Status Markers 완전 손실

2. **파일 시스템 오류**:
   - 디스크 풀 (disk full)
   - 권한 부족 (permission denied)
   - 파일 시스템 읽기 전용

3. **설정 오류**:
   - 프롬프트 지시사항 불명확
   - 계약과 프롬프트 불일치
   - 에이전트 버전 불일치

4. **품질 기준 위반** (반복):
   - 여러 번 재시도해도 품질 기준 미달
   - AI 모델이 요구사항 이해 못함

**수동 개입 절차**:
1. **오류 분석**: HANDOFF LOG 및 오류 메시지 검토
2. **근본 원인 파악**: 왜 실패했는지 분석
3. **수정 조치**: 파일 복구, 설정 수정, 프롬프트 개선 등
4. **재실행**: 수정 후 에이전트 재실행
5. **검증**: 성공적으로 완료되었는지 확인

---

## Section 6 완료

**작성 내용 요약**:
- 6.1 Fail-Fast 전략 (정의, 원칙, Precondition 실패 시 처리, 명확한 오류 메시지, FAILURE 기록)
- 6.2 오류 시나리오 분류 (Precondition 실패, 작업 중 오류, Postcondition 실패)
- 6.3 오류 메시지 형식 표준화 (표준 형식, 오류 타입별 패턴, 에이전트별 예시)
- 6.4 오류 복구 지침 (에이전트는 복구 없음, Orchestration 복구 전략, 복구 불가능한 오류)

**핵심 원칙**:
- Fail-Fast: 오류 발견 즉시 EXIT 1
- 에이전트는 복구 시도하지 않음 (Orchestration 책임)
- 명확한 오류 메시지 필수 (ERROR: [타입] - [상세])
- HANDOFF LOG에 [FAILURE] 기록 필수
- STATUS: FAILED 설정 후 종료

**다음 섹션**: Section 7 - UTF-8 인코딩 보장 전략

---

## 7. UTF-8 인코딩 보장 전략 (UTF-8 Encoding Strategy)

### 목적

한글 콘텐츠의 정확한 작성과 저장을 보장하기 위해 프롬프트와 Orchestration 수준에서 UTF-8 인코딩을 명시적으로 요구하고 검증합니다.

**배경**:
- 학습 콘텐츠는 주로 한국어로 작성됨
- 한글 문자 깨짐은 학습자 경험을 심각하게 저해
- AI 에이전트의 기본 동작만으로는 UTF-8 보장 불충분
- 명시적 지시와 환경 설정이 필수

**목표**:
1. 모든 한글 콘텐츠가 UTF-8로 올바르게 작성됨
2. 파일 저장 시 UTF-8 인코딩 유지
3. 인코딩 오류 조기 감지 및 수정

---

### 7.1 한글 콘텐츠 작성 요구사항

#### 7.1.1 필수 요구사항

모든 에이전트는 다음 요구사항을 준수해야 합니다:

| 요구사항 | 설명 | 검증 방법 |
|----------|------|-----------|
| **UTF-8 인코딩** | 모든 한글 콘텐츠를 UTF-8로 작성 | `file -b --mime-encoding [파일]` |
| **한글 정확성** | 한글 문자 깨짐 없음 (�, □, ? 등 없음) | 육안 검사 + 정규식 검색 |
| **일관성** | 파일 전체에 단일 인코딩 사용 | 인코딩 감지 도구 |
| **특수문자 처리** | 한글과 함께 사용되는 특수문자 정상 표시 | 테스트 케이스 실행 |

**한글이 사용되는 주요 위치**:
- Overview 섹션: 개요 설명, 핵심 특징, 실무 영향
- Core Concepts 섹션: Easy/Normal/Expert 설명
- Practice 섹션: Code Patterns 설명, Experiments 지시사항
- Quiz 섹션: 질문, 선택지, 해설
- Work Status Markers: HANDOFF LOG 메시지

#### 7.1.2 금지 사항

다음 인코딩 관련 문제를 절대 허용하지 않습니다:

❌ **DO NOT**:
- **한글 깨짐 문자 포함**: �, □, ?, \uFFFD 등
- **잘못된 인코딩**: EUC-KR, CP949, ISO-8859-1 등
- **혼합 인코딩**: 파일 내 여러 인코딩 혼용
- **ASCII 변환**: 한글을 ASCII로 변환 (예: "한글" → "hangul")
- **HTML 엔티티**: 한글을 HTML 엔티티로 인코딩 (예: "한" → "&#xD55C;")

**예시 - 잘못된 출력**:
```markdown
# Overview

var Å°¿öµåÀÇ ¹®Á¦Á¡  # ❌ 잘못된 인코딩 (EUC-KR)
```

**예시 - 올바른 출력**:
```markdown
# Overview

var 키워드의 문제점  # ✅ 올바른 UTF-8 인코딩
```

#### 7.1.3 품질 기준

**Acceptance Criteria**:
1. `file -b --mime-encoding [파일]` 결과가 `utf-8` 또는 `us-ascii`
2. 한글 깨짐 문자 정규식 매치 없음: `[�\uFFFD□?]{1,}`
3. 모든 한글 문장 육안으로 정상 확인 가능
4. 특수문자(괄호, 따옴표 등)와 한글 조합 정상 표시

---

### 7.2 프롬프트 지시문

#### 7.2.1 표준 UTF-8 지시문 (모든 프롬프트 공통)

모든 에이전트 프롬프트에 다음 지시문을 포함해야 합니다:

**템플릿**:
```markdown
## Constraints

### UTF-8 Encoding (필수)

**CRITICAL**: All Korean content MUST be written in UTF-8 encoding.

- **Write Korean text naturally**: 한글 콘텐츠를 자연스럽게 작성하세요.
- **No encoding conversion**: Do NOT convert Korean characters to any other encoding.
- **No garbled characters**: Ensure no garbled characters (�, □, ?, \uFFFD) appear in Korean text.
- **Verify after writing**: After writing Korean content, verify that all Korean characters are displayed correctly.

If you encounter encoding issues:
1. Report immediately with error message
2. Do NOT proceed with garbled content
3. Set STATUS: FAILED and EXIT 1
```

**위치**: `## Constraints` 섹션의 첫 번째 서브섹션

**강조 수준**:
- `**CRITICAL**` 태그 사용 (가장 높은 우선순위)
- UTF-8 지시문을 다른 제약사항보다 먼저 배치
- 구체적 예시 포함 (금지 문자 명시)

#### 7.2.2 에이전트별 맞춤 지시문

각 에이전트의 한글 콘텐츠 특성에 맞는 추가 지시문:

**content-initiator**:
```markdown
### UTF-8 Encoding for Frontmatter

- Ensure `title` field in frontmatter is UTF-8 encoded
- Example: `title: var 키워드의 문제점` (correct UTF-8)
```

**overview-writer**:
```markdown
### UTF-8 Encoding for Overview

- Overview section contains 50-100 lines of Korean text
- All headings (핵심 특징, 실무에서의 영향) must be UTF-8
- Verify bullet points with Korean text are not garbled
```

**concepts-writer**:
```markdown
### UTF-8 Encoding for Concepts

- Easy/Normal/Expert explanations are primarily in Korean
- Verify all three difficulty levels display Korean correctly
- Technical terms in English, explanations in Korean (both UTF-8)
```

**practice-writer**:
```markdown
### UTF-8 Encoding for Practice

- Code Pattern descriptions in Korean
- Experiment instructions in Korean
- Comments in code blocks can be Korean (ensure UTF-8)
```

**quiz-writer**:
```markdown
### UTF-8 Encoding for Quiz

- Questions, choices, explanations all in Korean
- 8-12 quiz items with Korean text
- Verify each quiz item's Korean content is not garbled
```

**content-validator**:
```markdown
### UTF-8 Encoding Validation

- Check all Korean content sections for encoding issues
- Add to IMPROVEMENT_NEEDED if garbled characters found
- Deduct -10 points for any encoding errors
```

#### 7.2.3 오류 감지 지시문

프롬프트에 다음 자가 진단 지시문을 포함:

```markdown
## Error Handling

### Encoding Error Detection

**Self-Check**: Before marking work as complete, verify:
- [ ] No garbled Korean characters (�, □, ?, \uFFFD)
- [ ] All Korean sentences are readable
- [ ] File encoding is UTF-8 (use `file` command if available)

If encoding errors detected:
1. Output error message: `ERROR: Encoding Error - Korean characters are garbled`
2. Add HANDOFF LOG: `[FAILURE] {agent} | UTF-8 encoding error detected | [timestamp]`
3. Set STATUS: FAILED
4. EXIT 1

**DO NOT proceed with garbled content** - Orchestration will retry with correct encoding.
```

---

### 7.3 Orchestration 환경 설정

#### 7.3.1 환경 변수 설정

**필수 환경 변수** (`content-generator-v6.sh`에서 설정):

```bash
# UTF-8 인코딩 보장을 위한 환경 변수
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8
export LC_CTYPE=ko_KR.UTF-8

# Python의 경우
export PYTHONIOENCODING=utf-8

# 확인
echo "Locale settings:"
locale
```

**설정 위치**: 스크립트 최상단 (에이전트 실행 전)

**검증**:
```bash
# locale 명령어로 확인
if ! locale | grep -q "UTF-8"; then
    echo "ERROR: Locale is not set to UTF-8"
    exit 1
fi
```

#### 7.3.2 파일 인코딩 사후 검증

**검증 스크립트** (에이전트 실행 후):

```bash
# 함수 정의
verify_utf8_encoding() {
    local file="$1"

    # 방법 1: file 명령어 사용
    local encoding=$(file -b --mime-encoding "$file")

    if [[ "$encoding" != "utf-8" && "$encoding" != "us-ascii" ]]; then
        echo "ERROR: File encoding is $encoding, expected utf-8"
        return 1
    fi

    # 방법 2: 한글 깨짐 문자 검색
    if grep -q $'[\uFFFD�]' "$file"; then
        echo "ERROR: Garbled characters detected in file"
        return 1
    fi

    echo "UTF-8 encoding verified for $file"
    return 0
}

# 사용 예시
if ! verify_utf8_encoding "$output_file"; then
    echo "Rolling back to backup..."
    cp "$output_file.backup" "$output_file"
    exit 1
fi
```

**실행 시점**: 각 에이전트 실행 후, 다음 에이전트로 넘어가기 전

#### 7.3.3 Orchestration 오류 처리

**인코딩 오류 감지 시 처리**:

```bash
# content-generator-v6.sh에 추가
run_agent_with_encoding_check() {
    local agent_name="$1"
    local file="$2"

    # 백업 생성
    cp "$file" "$file.backup"

    # 에이전트 실행
    claude code -a "$agent_name" --file "$file"
    local exit_code=$?

    # 인코딩 검증
    if ! verify_utf8_encoding "$file"; then
        echo "ERROR: Agent $agent_name produced invalid UTF-8 encoding"

        # 백업 복원
        cp "$file.backup" "$file"

        # HANDOFF LOG에 기록 (Orchestration 책임)
        local timestamp=$(date +"%Y-%m-%dT%H:%M:%S%:z")
        add_handoff_log "$file" "[FAILURE] $agent_name | UTF-8 encoding verification failed | $timestamp"

        # STATUS: FAILED 설정
        update_work_status_marker "$file" "STATUS" "FAILED"

        return 1
    fi

    # 백업 삭제 (성공 시)
    rm "$file.backup"

    return $exit_code
}
```

**재시도 전략**:
1. 첫 시도 실패 → 백업 복원 후 재시도 (최대 3회)
2. 3회 실패 → 수동 개입 필요 알림
3. 로그 파일에 인코딩 오류 상세 기록

---

### 7.4 검증 및 오류 감지

#### 7.4.1 자동 검증 체크리스트

**정적 검증** (파일 스캔):

```bash
# 검증 스크립트: scripts/lib/validate-encoding.sh

validate_encoding() {
    local file="$1"
    local errors=0

    echo "Validating UTF-8 encoding for: $file"

    # Check 1: File encoding
    local encoding=$(file -b --mime-encoding "$file")
    if [[ "$encoding" != "utf-8" && "$encoding" != "us-ascii" ]]; then
        echo "❌ FAIL: Encoding is $encoding (expected utf-8)"
        ((errors++))
    else
        echo "✅ PASS: File encoding is $encoding"
    fi

    # Check 2: Garbled characters
    if grep -qP '[�\uFFFD□]' "$file"; then
        echo "❌ FAIL: Garbled characters found"
        grep -nP '[�\uFFFD□]' "$file" | head -5
        ((errors++))
    else
        echo "✅ PASS: No garbled characters detected"
    fi

    # Check 3: Korean text presence (샘플링)
    local korean_count=$(grep -oP '[가-힣]+' "$file" | wc -l)
    if [[ $korean_count -lt 10 ]]; then
        echo "⚠️  WARN: Only $korean_count Korean words found (expected more)"
    else
        echo "✅ PASS: $korean_count Korean words found"
    fi

    # Check 4: Frontmatter title encoding
    local title=$(grep "^title:" "$file" | head -1)
    if echo "$title" | grep -qP '[가-힣]+'; then
        echo "✅ PASS: Frontmatter title contains Korean"
    else
        echo "⚠️  WARN: Frontmatter title has no Korean"
    fi

    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "❌ VALIDATION FAILED: $errors error(s) found"
        return 1
    else
        echo ""
        echo "✅ VALIDATION PASSED: No encoding errors"
        return 0
    fi
}

# 사용 예시
if ! validate_encoding "$file"; then
    exit 1
fi
```

#### 7.4.2 오류 감지 패턴

**한글 깨짐 패턴 정규식**:

| 패턴 | 정규식 | 설명 |
|------|--------|------|
| Replacement Character | `[\uFFFD�]` | UTF-8 디코딩 실패 |
| Box Character | `□` | 폰트 미지원 또는 인코딩 오류 |
| Question Mark | `\?{2,}` | 연속된 물음표 (인코딩 오류 의심) |
| Mojibake Pattern | `[À-ÿ]{4,}` | EUC-KR을 ISO-8859-1로 잘못 해석 |

**검색 명령어**:
```bash
# 모든 깨짐 패턴 검색
grep -nP '[\uFFFD�□]|[À-ÿ]{4,}' "$file"

# 한글이 있어야 할 위치에 없는 경우 감지
if ! grep -q "^title:.*[가-힣]" "$file"; then
    echo "ERROR: Title should contain Korean but doesn't"
fi
```

#### 7.4.3 인코딩 오류 메시지 형식

**표준 오류 메시지**:
```
ERROR: Encoding Error - [구체적 문제]
```

**에이전트별 오류 메시지 예시**:

```markdown
# content-initiator
ERROR: Encoding Error - Frontmatter title contains garbled characters

# overview-writer
ERROR: Encoding Error - Overview section has garbled Korean text at line 25

# concepts-writer
ERROR: Encoding Error - Easy explanation contains replacement characters (�)

# practice-writer
ERROR: Encoding Error - Code Pattern description has encoding issues

# quiz-writer
ERROR: Encoding Error - Quiz question 3 contains garbled characters

# content-validator
ERROR: Encoding Error - Multiple sections have UTF-8 encoding issues
```

**HANDOFF LOG 형식**:
```
[FAILURE] overview-writer | UTF-8 encoding error: garbled characters at line 25 | 2025-10-17T14:30:00+09:00
```

#### 7.4.4 사후 검증 통합

**content-generator-v6.sh 통합 예시**:

```bash
# 에이전트 실행 후 검증
for agent in overview-writer concepts-writer visualization-writer practice-writer quiz-writer; do
    echo "Running agent: $agent"

    # 에이전트 실행
    claude code -a "$agent" --file "$file"
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo "Agent $agent failed with exit code $exit_code"
        exit 1
    fi

    # UTF-8 인코딩 검증 (CRITICAL)
    if ! ./scripts/lib/validate-encoding.sh "$file"; then
        echo "ERROR: UTF-8 encoding validation failed after $agent"

        # 백업 복원
        if [[ -f "$file.backup" ]]; then
            cp "$file.backup" "$file"
            echo "Rolled back to backup"
        fi

        # 재시도 또는 종료
        exit 1
    fi

    echo "Agent $agent completed successfully with valid UTF-8 encoding"
done
```

---

### 7.5 실전 예시

#### 7.5.1 정상 케이스 (UTF-8 성공)

**시나리오**: overview-writer가 한글 콘텐츠를 올바르게 생성

**입력**: category.yaml에서 "var 키워드의 문제점" 토픽

**에이전트 출력**:
```markdown
---
id: var-problems
title: var 키워드의 문제점
difficulty: 2
---

<!--
CURRENT_AGENT: concepts-writer
STATUS: IN_PROGRESS
...
-->

# Overview

var 키워드는 JavaScript에서 변수를 선언하는 초기 방법입니다. 그러나 호이스팅과 스코프 문제로 인해 현대 JavaScript 개발에서는 바람직하지 않은 결과를 초래하는 경우가 많습니다.

## 핵심 문제점

- **호이스팅**: var 선언이 스코프 맨 위로 끌어올려짐
- **함수 스코프**: 블록 스코프를 무시하여 예상치 못한 동작 야기
```

**검증 결과**:
```bash
$ file -b --mime-encoding var-problems.md
utf-8

$ grep -P '[�\uFFFD□]' var-problems.md
# (결과 없음)

✅ PASS: UTF-8 encoding verified
```

#### 7.5.2 오류 케이스 (인코딩 실패)

**시나리오**: overview-writer가 한글 콘텐츠를 잘못된 인코딩으로 생성

**에이전트 출력** (문제):
```markdown
# Overview

var Å°¿öµåÀÇ ¹®Á¦Á¡  # ❌ EUC-KR을 UTF-8로 잘못 읽음
```

**검증 결과**:
```bash
$ ./scripts/lib/validate-encoding.sh var-problems.md

Validating UTF-8 encoding for: var-problems.md
✅ PASS: File encoding is utf-8
❌ FAIL: Garbled characters found
var-problems.md:15:var Å°¿öµåÀÇ ¹®Á¦Á¡

❌ VALIDATION FAILED: 1 error(s) found
```

**Orchestration 처리**:
```bash
ERROR: UTF-8 encoding validation failed after overview-writer
Rolled back to backup
Retrying (attempt 2/3)...

# 재시도 후 성공
✅ PASS: UTF-8 encoding verified
Agent overview-writer completed successfully with valid UTF-8 encoding
```

**HANDOFF LOG**:
```markdown
<!--
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T14:00:00+09:00
[FAILURE] overview-writer | UTF-8 encoding verification failed | 2025-10-17T14:05:00+09:00
[DONE] overview-writer | Overview section completed | 2025-10-17T14:08:00+09:00
-->
```

#### 7.5.3 복구 불가 케이스

**시나리오**: 3회 재시도 후에도 인코딩 오류 지속

**Orchestration 출력**:
```bash
Attempt 1/3: UTF-8 encoding validation failed
Attempt 2/3: UTF-8 encoding validation failed
Attempt 3/3: UTF-8 encoding validation failed

ERROR: Agent overview-writer failed to produce valid UTF-8 after 3 attempts
MANUAL INTERVENTION REQUIRED

Possible causes:
1. AI model not following UTF-8 encoding instructions
2. System locale not set to UTF-8 (check: locale)
3. Prompt instructions unclear or incomplete
4. File system encoding issues

Recommended actions:
1. Check system locale: locale | grep UTF-8
2. Review agent prompt UTF-8 instructions
3. Manually edit the file with correct encoding
4. Re-run the pipeline from this agent

File location: public/content/ko/javascript-core-concepts/variables/var-problems.md
HANDOFF LOG location: Same file (HTML comment at top)
```

**수동 개입 절차**:
1. `locale` 명령어로 시스템 설정 확인
2. 프롬프트 지시문 검토 (UTF-8 지시가 명확한가?)
3. 파일을 텍스트 에디터로 열어 한글 확인
4. 필요 시 프롬프트 개선 후 재실행

---

## Section 7 완료

**작성 내용 요약**:
- 7.1 한글 콘텐츠 작성 요구사항 (필수 요구사항, 금지 사항, 품질 기준)
- 7.2 프롬프트 지시문 (표준 UTF-8 지시문, 에이전트별 맞춤 지시문, 오류 감지 지시문)
- 7.3 Orchestration 환경 설정 (환경 변수, 사후 검증, 오류 처리)
- 7.4 검증 및 오류 감지 (자동 검증 체크리스트, 오류 감지 패턴, 오류 메시지 형식, 사후 검증 통합)
- 7.5 실전 예시 (정상 케이스, 오류 케이스, 복구 불가 케이스)

**핵심 원칙**:
- CRITICAL: 모든 한글 콘텐츠는 UTF-8 필수
- 프롬프트에 명시적 UTF-8 지시문 포함 (`## Constraints` 최우선)
- Orchestration 환경 변수: `LANG=ko_KR.UTF-8`, `LC_ALL=ko_KR.UTF-8`
- 사후 검증 필수: `file -b --mime-encoding` + 한글 깨짐 패턴 검색
- 인코딩 오류 감지 시: 백업 복원 → 재시도 (최대 3회) → 수동 개입

**다음 섹션**: Section 8 - 7개 에이전트 프롬프트 설계

---

## 8. 7개 에이전트 프롬프트 설계 (7 Agent Prompt Designs)

### 목적

각 에이전트의 특성과 책임에 맞춘 구체적인 프롬프트 설계를 제공합니다. Section 1-7에서 정의한 원칙들을 각 에이전트에 적용하고, Unit 2 계약을 프롬프트로 변환합니다.

**설계 범위**:
- 7개 에이전트: content-initiator, overview-writer, concepts-writer, visualization-writer, practice-writer, quiz-writer, content-validator
- 각 에이전트별 프롬프트 구조, 핵심 지시사항, DO/DO NOT, 예시

**설계 원칙** (Section 1-7 반영):
1. Unit 2 계약 기반 (Input/Output Contract 통합)
2. Bounded Context 명확화 (Section 4)
3. Work Status Markers 조작 표준 (Section 5)
4. Fail-Fast 오류 처리 (Section 6)
5. UTF-8 인코딩 보장 (Section 7)

---

### 8.1 content-initiator 프롬프트 설계

#### 8.1.1 에이전트 개요

**역할**: 콘텐츠 파일 초기화 및 Work Status Markers 생성

**특수성**:
- 파이프라인의 첫 번째 에이전트 (의존성 없음)
- Work Status Markers를 최초로 생성
- category.yaml에서 메타데이터 읽어 frontmatter 자동 생성
- 콘텐츠 섹션은 작성하지 않음 (마커와 frontmatter만)

**Bounded Context**: Content Initialization
- 소유 데이터: frontmatter, Work Status Markers (초기 상태)
- 접근 자원: category.yaml (읽기), 출력 파일 (쓰기)

**참조 계약**: `docs/aidlc-docs/specifications/contracts/content-initiator-contract.md`

#### 8.1.2 프롬프트 구조 요약

```yaml
---
name: content-initiator
version: 2.0.0
description: Initialize content file with frontmatter and Work Status Markers
tools: [Read, Write]
model: claude-sonnet-4
---
```

**섹션 구성** (총 200-300줄 예상):
1. Role and Responsibility
2. Input Contract (요약)
3. Output Contract (요약)
4. Execution Instructions (단계별 지시)
5. Constraints (UTF-8 우선)
6. Error Handling (Precondition/Postcondition)
7. Handoff Protocol
8. Examples

#### 8.1.3 핵심 지시사항

**Input Contract (요약)**:
```markdown
## Input Contract

You will receive:
- `--category-yaml`: Path to category.yaml file
- `--topic-id`: Topic ID to initialize (e.g., "var-problems")
- `--output-file`: Path where the content file will be created

**Preconditions** (verify before starting):
- PC-1: category.yaml file exists and is readable
- PC-2: Topic ID exists in category.yaml
- PC-3: Output file does NOT exist (prevent overwriting)

Refer to Unit 2 contract for detailed specifications:
`docs/aidlc-docs/specifications/contracts/content-initiator-contract.md`
```

**Output Contract (요약)**:
```markdown
## Output Contract

You will create a new markdown file with:

1. **Frontmatter** (YAML):
   ```yaml
   ---
   id: [topic-id]
   title: [Korean title from category.yaml]
   difficulty: [1-5]
   estimated_time: [minutes]
   prerequisites: [list]
   ---
   ```

2. **Work Status Markers** (HTML comment):
   ```markdown
   <!--
   CURRENT_AGENT: overview-writer
   STATUS: PENDING
   STARTED: [ISO 8601 timestamp]
   UPDATED: [ISO 8601 timestamp]
   HANDOFF LOG:
   [START] pipeline | Content generation started | [timestamp]
   -->
   ```

3. **No content sections** (only frontmatter + markers)

**Postconditions** (verify after completion):
- PO-1: Output file created successfully
- PO-2: Frontmatter is valid YAML
- PO-3: CURRENT_AGENT is "overview-writer"
- PO-4: STATUS is "PENDING"
- PO-5: HANDOFF LOG contains [START] entry
```

**Execution Instructions**:
```markdown
## Execution Instructions

Follow these steps in order:

### Step 1: Verify Preconditions

- [ ] PC-1: Check category.yaml exists (`Read` tool)
- [ ] PC-2: Parse category.yaml and find topic by ID
- [ ] PC-3: Check output file does NOT exist (fail if exists)

If any precondition fails, follow error handling (Section 6).

### Step 2: Extract Topic Metadata

From category.yaml, extract:
- `title`: Korean title (ensure UTF-8)
- `difficulty`: 1-5
- `estimated_time`: minutes
- `prerequisites`: list of topic IDs

### Step 3: Generate Frontmatter

Create YAML frontmatter:
```yaml
---
id: [topic-id]
title: [title from category.yaml]
difficulty: [difficulty]
estimated_time: [estimated_time]
prerequisites: [prerequisites array]
---
```

**CRITICAL**: Ensure `title` is UTF-8 encoded Korean text.

### Step 4: Generate Work Status Markers

Create HTML comment with initial state:
```markdown
<!--
CURRENT_AGENT: overview-writer
STATUS: PENDING
STARTED: [current timestamp in ISO 8601: YYYY-MM-DDTHH:MM:SS+09:00]
UPDATED: [same as STARTED]
HANDOFF LOG:
[START] pipeline | Content generation started | [timestamp]
-->
```

**Timestamp format**: ISO 8601 with +09:00 timezone.

### Step 5: Write Output File

Use `Write` tool to create the file with:
1. Frontmatter (YAML)
2. Blank line
3. Work Status Markers (HTML comment)
4. Blank line
5. (No content sections)

### Step 6: Verify Postconditions

- [ ] PO-1: File created successfully
- [ ] PO-2: Frontmatter is valid YAML
- [ ] PO-3: CURRENT_AGENT is "overview-writer"
- [ ] PO-4: STATUS is "PENDING"
- [ ] PO-5: HANDOFF LOG has [START] entry

If any postcondition fails, follow error handling.

### Step 7: Report Success

Output:
```
SUCCESS: Content file initialized
File: [output-file]
Topic: [topic-id] - [title]
Next agent: overview-writer
```

EXIT 0
```

#### 8.1.4 DO / DO NOT

**DO**:
- ✅ **Extract metadata from category.yaml** accurately
- ✅ **Generate valid YAML frontmatter** with all required fields
- ✅ **Create Work Status Markers** with correct initial state
- ✅ **Set CURRENT_AGENT to "overview-writer"** (next agent)
- ✅ **Set STATUS to "PENDING"** (not started)
- ✅ **Use ISO 8601 timestamp** with +09:00 timezone
- ✅ **Ensure Korean title is UTF-8** encoded
- ✅ **Verify output file does NOT exist** before writing (PC-3)

**DO NOT**:
- ❌ **DO NOT overwrite existing files** (fail if file exists)
- ❌ **DO NOT create content sections** (only frontmatter + markers)
- ❌ **DO NOT modify category.yaml** (read-only)
- ❌ **DO NOT proceed if topic ID not found** in category.yaml
- ❌ **DO NOT use relative timestamps** (e.g., "now", "today")
- ❌ **DO NOT set STATUS to "IN_PROGRESS"** (this agent doesn't do content work)
- ❌ **DO NOT add [DONE] entry to HANDOFF LOG** (only [START])

#### 8.1.5 Constraints

```markdown
## Constraints

### UTF-8 Encoding (필수)

**CRITICAL**: Korean title in frontmatter MUST be UTF-8 encoded.

- **Extract Korean title from category.yaml**: Preserve UTF-8 encoding
- **Write to frontmatter**: Ensure `title: [한글 제목]` is UTF-8
- **No garbled characters**: Verify no �, □, ? in title

If encoding issues detected:
1. Output error: `ERROR: Encoding Error - Frontmatter title contains garbled characters`
2. Add HANDOFF LOG: `[FAILURE] content-initiator | UTF-8 encoding error | [timestamp]`
3. Set STATUS: FAILED
4. EXIT 1

### File Overwrite Prevention

- **NEVER overwrite existing files**: Check file existence before writing
- If file exists, fail with error: `ERROR: Precondition failed - Output file already exists`

### Timestamp Format

- **ISO 8601 only**: `YYYY-MM-DDTHH:MM:SS+09:00`
- Example: `2025-10-17T14:30:00+09:00`
```

#### 8.1.6 오류 처리

```markdown
## Error Handling

### Precondition Failures

**PC-1: category.yaml does not exist**:
```
ERROR: Precondition failed - category.yaml not found at [path]
```
- Add HANDOFF LOG: `[FAILURE] content-initiator | category.yaml not found | [timestamp]`
- EXIT 1

**PC-2: Topic ID not found in category.yaml**:
```
ERROR: Precondition failed - Topic ID '[topic-id]' not found in category.yaml
```
- Add HANDOFF LOG: `[FAILURE] content-initiator | Topic ID not found | [timestamp]`
- EXIT 1

**PC-3: Output file already exists**:
```
ERROR: Precondition failed - Output file already exists: [output-file]
```
- Add HANDOFF LOG: `[FAILURE] content-initiator | File already exists | [timestamp]`
- EXIT 1

### Work Errors

**Metadata extraction failure**:
```
ERROR: Content generation failed - Unable to parse category.yaml
```
- EXIT 1 (no file created)

**File write failure**:
```
ERROR: File write error - Unable to create output file: [error details]
```
- EXIT 1

### Postcondition Failures

**PO-2: Invalid YAML frontmatter**:
```
ERROR: Postcondition failed - Generated frontmatter is not valid YAML
```
- Remove partially created file (rollback)
- EXIT 1
```

#### 8.1.7 Handoff Protocol

```markdown
## Handoff Protocol

### No Previous Agent

This is the FIRST agent in the pipeline, so there is no previous agent to check.

### Next Agent: overview-writer

After successful completion:
- Set `CURRENT_AGENT: overview-writer`
- Set `STATUS: PENDING` (overview-writer hasn't started)
- Add `[START]` entry to HANDOFF LOG

**HANDOFF LOG entry**:
```
[START] pipeline | Content generation started | [timestamp]
```

**Do NOT add [DONE] entry** - content-initiator doesn't do content work, only initialization.
```

#### 8.1.8 예시

**Example: Normal Flow**

**Input**:
- category-yaml: `public/content/ko/javascript-core-concepts/variables/category.yaml`
- topic-id: `var-problems`
- output-file: `public/content/ko/javascript-core-concepts/variables/var-problems.md`

**category.yaml excerpt**:
```yaml
topics:
  - id: var-problems
    title: var 키워드의 문제점
    difficulty: 2
    estimated_time: 15
    prerequisites: []
```

**Output file created**:
```markdown
---
id: var-problems
title: var 키워드의 문제점
difficulty: 2
estimated_time: 15
prerequisites: []
---

<!--
CURRENT_AGENT: overview-writer
STATUS: PENDING
STARTED: 2025-10-17T14:00:00+09:00
UPDATED: 2025-10-17T14:00:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T14:00:00+09:00
-->

```

**Success output**:
```
SUCCESS: Content file initialized
File: public/content/ko/javascript-core-concepts/variables/var-problems.md
Topic: var-problems - var 키워드의 문제점
Next agent: overview-writer
```

---

### 8.2 overview-writer 프롬프트 설계

#### 8.2.1 에이전트 개요

**역할**: Overview 섹션 작성 (학습 동기 부여, 토픽 소개)

**특성**:
- 첫 번째 콘텐츠 작성 에이전트
- frontmatter와 Work Status Markers 읽기
- Overview 섹션 생성 (50-100줄)
- 다음 에이전트로 핸드오프 (concepts-writer)

**Bounded Context**: Overview Section Generation
- 소유 데이터: `# Overview` 섹션 전체
- 접근 자원: frontmatter (읽기), Work Status Markers (읽기/쓰기)

**참조 계약**: `docs/aidlc-docs/specifications/contracts/overview-writer-contract.md`

#### 8.2.2 프롬프트 구조 요약

```yaml
---
name: overview-writer
version: 6.0.0
description: Generate Overview section that motivates learners
tools: [Read, Edit]
model: claude-sonnet-4
---
```

**섹션 구성** (총 300-400줄 예상):
1. Role and Responsibility
2. Input Contract
3. Output Contract
4. Execution Instructions
5. Constraints (UTF-8 최우선)
6. Error Handling
7. Handoff Protocol
8. Quality Standards
9. Examples

#### 8.2.3 핵심 지시사항

**Input Contract (요약)**:
```markdown
## Input Contract

**File State**:
- Target markdown file with frontmatter and Work Status Markers
- File encoding: UTF-8
- Frontmatter: Required (populated by content-initiator)
- Existing sections: Work Status Markers only (no content sections yet)

**Work Status Markers**:
- `CURRENT_AGENT: overview-writer` (MUST match)
- `STATUS: PENDING` (normal flow) OR `IN_PROGRESS` (improvement mode)
- `HANDOFF LOG`: Contains `[START]` entry

**Section Dependencies**:
- None (first content section in the pipeline)

**Preconditions**:
- PC-1: `CURRENT_AGENT == "overview-writer"`
- PC-2: `STATUS == PENDING` OR (`STATUS == IN_PROGRESS` AND IMPROVEMENT_NEEDED contains overview-writer)
- PC-3: frontmatter exists and is valid
- PC-4: HANDOFF LOG contains `[START]` entry
```

**Output Contract (요약)**:
```markdown
## Output Contract

**File Modifications**:
- Add `# Overview` section after Work Status Markers
- Update Work Status Markers

**Section Structure**:
```markdown
# Overview

[Introduction paragraph(s) - 3-5 sentences]

## 핵심 특징 (또는 핵심 문제점)
- [Feature/problem 1]
- [Feature/problem 2]
- [Feature/problem 3]
- [Feature/problem 4]

## 실무에서의 영향 (또는 왜 중요한가?)
[Practical impact paragraph - 4-6 sentences]
```

**Work Status Markers Updates**:
- `CURRENT_AGENT: concepts-writer` (next agent)
- `STATUS: IN_PROGRESS`
- `UPDATED: [current timestamp]`
- HANDOFF LOG: Add `[DONE] overview-writer | Overview section completed | [timestamp]`

**Content Guarantees**:
- Overview section: 50-100 lines
- Introduction: 3-5 sentences
- Key features/problems: 4-5 bullet points
- Practical impact: 4-6 sentences

**Postconditions**:
- PO-1: `# Overview` section exists and is complete
- PO-2: `CURRENT_AGENT == "concepts-writer"`
- PO-3: `STATUS == IN_PROGRESS`
- PO-4: HANDOFF LOG contains `[DONE] overview-writer` entry
```

**Execution Instructions**:
```markdown
## Execution Instructions

### Step 1: Verify Preconditions

- [ ] PC-1: Read file and verify `CURRENT_AGENT == "overview-writer"`
- [ ] PC-2: Verify `STATUS == PENDING` (normal) OR improvement mode
- [ ] PC-3: Verify frontmatter exists (has `id`, `title`, `difficulty`)
- [ ] PC-4: Verify HANDOFF LOG contains `[START]` entry

If any fails, output error and EXIT 1 (see Error Handling).

### Step 2: Analyze Topic from Frontmatter

Extract topic information:
- `title`: What concept to explain
- `difficulty`: 1-5 (adjust tone accordingly)
- `prerequisites`: Related concepts to reference

### Step 3: Write Overview Section

Create `# Overview` section with 3 parts:

**Part 1: Introduction (3-5 sentences)**:
- First sentence: Define the topic or core concept
- Next sentences: Explain why it matters, what problems it solves
- Use natural Korean (한글), UTF-8 encoding

**Part 2: Key Features or Problems (4-5 bullets)**:
- Use `## 핵심 특징` for positive features
- Use `## 핵심 문제점` for problems/limitations
- One line per bullet, bold key terms: `**term**`

**Part 3: Practical Impact (4-6 sentences)**:
- Use `## 실무에서의 영향` or `## 왜 중요한가?`
- Explain real-world benefits, use cases
- Address performance, maintainability, or code quality

**Length target**: 50-100 lines total

### Step 4: Insert Overview Section

Use `Edit` tool to add `# Overview` section:
- Position: After Work Status Markers, before any other sections
- Ensure UTF-8 encoding for all Korean text

### Step 5: Update Work Status Markers

Update the HTML comment at top of file:

**Changes**:
```markdown
CURRENT_AGENT: concepts-writer
STATUS: IN_PROGRESS
UPDATED: [current timestamp ISO 8601]
HANDOFF LOG:
[existing entries...]
[DONE] overview-writer | Overview section completed | [timestamp]
```

**Improvement mode**: If `IMPROVEMENT_NEEDED` contains overview-writer entry, use `[IMPROVE]` instead of `[DONE]` and remove that entry.

### Step 6: Verify Postconditions

- [ ] PO-1: `# Overview` section exists with all 3 parts
- [ ] PO-2: `CURRENT_AGENT == "concepts-writer"`
- [ ] PO-3: `STATUS == IN_PROGRESS`
- [ ] PO-4: HANDOFF LOG has `[DONE] overview-writer` entry
- [ ] PO-5: All Korean text is UTF-8 (no �, □, ?)

If any fails, rollback changes and EXIT 1.

### Step 7: Report Success

Output:
```
SUCCESS: Overview section completed
Lines written: [count]
Next agent: concepts-writer
```

EXIT 0
```

#### 8.2.4 DO / DO NOT

**DO**:
- ✅ **Write `# Overview` section** immediately after Work Status Markers
- ✅ **Use natural Korean language** (한글 콘텐츠, UTF-8)
- ✅ **Include all 3 parts**: Introduction, Key Features/Problems, Practical Impact
- ✅ **Update CURRENT_AGENT to "concepts-writer"**
- ✅ **Update STATUS to "IN_PROGRESS"**
- ✅ **Add [DONE] entry to HANDOFF LOG** with timestamp
- ✅ **Verify UTF-8 encoding** (no garbled characters)
- ✅ **Keep section length 50-100 lines**

**DO NOT**:
- ❌ **DO NOT modify frontmatter** (read-only for this agent)
- ❌ **DO NOT modify other sections** (if they exist, e.g., improvement mode)
- ❌ **NEVER delete or modify existing HANDOFF LOG entries** (append-only)
- ❌ **DO NOT add code blocks** (Overview is concept-only, no code)
- ❌ **DO NOT use headers deeper than `##`** (H1: Overview, H2: subsections)
- ❌ **DO NOT proceed if CURRENT_AGENT != "overview-writer"** (Fail-Fast)

#### 8.2.5 Constraints

```markdown
## Constraints

### UTF-8 Encoding (필수)

**CRITICAL**: Overview section contains 50-100 lines of Korean text. All Korean content MUST be UTF-8.

- **Write Korean text naturally**: 한글 콘텐츠를 자연스럽게 작성하세요.
- **No encoding conversion**: Do NOT convert Korean to any other encoding.
- **No garbled characters**: Ensure no �, □, ?, \uFFFD in Korean text.
- **Verify after writing**: Check all Korean sentences are readable.

**Self-Check before completion**:
- [ ] No garbled Korean characters
- [ ] All headings (핵심 특징, 실무에서의 영향) are UTF-8
- [ ] Bullet points with Korean text are not garbled

If encoding errors detected:
1. Output: `ERROR: Encoding Error - Overview section has garbled Korean text`
2. Add HANDOFF LOG: `[FAILURE] overview-writer | UTF-8 encoding error | [timestamp]`
3. Set STATUS: FAILED
4. EXIT 1

### Content Quality

- Introduction: 3-5 sentences (not 1, not 10)
- Key features/problems: 4-5 bullets (not 2, not 10)
- Practical impact: 4-6 sentences (not 1, not 15)
- Total length: 50-100 lines (not 20, not 200)

### No Code Blocks

- Overview is **concept-only**, no code examples
- Use natural language to explain, not code syntax
- Save code for Practice section (practice-writer's job)
```

#### 8.2.6 오류 처리

```markdown
## Error Handling

### Precondition Failures (Fail-Fast)

**PC-1: CURRENT_AGENT mismatch**:
```
ERROR: Precondition failed - CURRENT_AGENT is '[actual]', expected 'overview-writer'
```
- Add HANDOFF LOG: `[FAILURE] overview-writer | Precondition failed: CURRENT_AGENT mismatch | [timestamp]`
- Set STATUS: FAILED
- EXIT 1

**PC-3: Missing frontmatter**:
```
ERROR: Precondition failed - frontmatter is missing
```
- Add HANDOFF LOG: `[FAILURE] overview-writer | Missing frontmatter | [timestamp]`
- Set STATUS: FAILED
- EXIT 1

**PC-4: No [START] entry in HANDOFF LOG**:
```
ERROR: Precondition failed - No [START] entry in HANDOFF LOG
```
- Add HANDOFF LOG: `[FAILURE] overview-writer | No [START] entry | [timestamp]`
- Set STATUS: FAILED
- EXIT 1

### Work Errors

**Content generation failure**:
```
ERROR: Content generation failed - Unable to write Overview section: [details]
```
- Rollback: Remove incomplete `# Overview` section
- Add HANDOFF LOG: `[FAILURE] overview-writer | Content generation failed | [timestamp]`
- Set STATUS: FAILED
- EXIT 1

**File write failure**:
```
ERROR: File write error - Unable to update file: [details]
```
- Add HANDOFF LOG: `[FAILURE] overview-writer | File write error | [timestamp]`
- Set STATUS: FAILED
- EXIT 1

### Postcondition Failures

**PO-1: Overview section missing after write**:
```
ERROR: Postcondition failed - # Overview section not found after write operation
```
- Rollback changes
- EXIT 1
```

#### 8.2.7 Handoff Protocol

```markdown
## Handoff Protocol

### From: content-initiator

**Expected state**:
- File exists with frontmatter and Work Status Markers
- `CURRENT_AGENT: overview-writer`
- `STATUS: PENDING`
- HANDOFF LOG has `[START]` entry

### To: concepts-writer

**State after completion**:
- File has frontmatter, markers, and `# Overview` section
- `CURRENT_AGENT: concepts-writer`
- `STATUS: IN_PROGRESS`
- HANDOFF LOG has `[DONE] overview-writer` entry

**Normal mode HANDOFF LOG entry**:
```
[DONE] overview-writer | Overview section completed | [timestamp]
```

**Improvement mode HANDOFF LOG entry** (if improving existing content):
```
[IMPROVE] overview-writer | Overview section improved | [timestamp]
```

### Improvement Mode

If `IMPROVEMENT_NEEDED` field exists with overview-writer entry:
1. Read existing `# Overview` section
2. Identify specific issues mentioned in IMPROVEMENT_NEEDED
3. Modify ONLY the parts that need improvement
4. Remove overview-writer entry from IMPROVEMENT_NEEDED after completion
5. Use `[IMPROVE]` event type in HANDOFF LOG
6. Update `CURRENT_AGENT` to next agent needing improvement (or concepts-writer if none)
```

#### 8.2.8 예시

**Example 1: Normal Flow**

**Input file**:
```markdown
---
id: var-problems
title: var 키워드의 문제점
difficulty: 2
---

<!--
CURRENT_AGENT: overview-writer
STATUS: PENDING
STARTED: 2025-10-17T14:00:00+09:00
UPDATED: 2025-10-17T14:00:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T14:00:00+09:00
-->

```

**Output file**:
```markdown
---
id: var-problems
title: var 키워드의 문제점
difficulty: 2
---

<!--
CURRENT_AGENT: concepts-writer
STATUS: IN_PROGRESS
STARTED: 2025-10-17T14:00:00+09:00
UPDATED: 2025-10-17T14:05:00+09:00
HANDOFF LOG:
[START] pipeline | Content generation started | 2025-10-17T14:00:00+09:00
[DONE] overview-writer | Overview section completed | 2025-10-17T14:05:00+09:00
-->

# Overview

var 키워드는 JavaScript에서 변수를 선언하는 초기 방법입니다. 그러나 호이스팅과 스코프 문제로 인해 현대 JavaScript 개발에서는 바람직하지 않은 결과를 초래하는 경우가 많습니다. 이러한 문제들을 이해하고 let과 const 같은 대안을 사용할 수 있어야 합니다.

## 핵심 문제점

- **호이스팅**: var 선언이 스코프 맨 위로 끌어올려짐
- **함수 스코프**: 블록 스코프를 무시하여 예상치 못한 동작 야기
- **중복 선언**: 같은 스코프에서 중복 선언 허용
- **루프 클로저**: 루프 내에서의 변수 사용 시 예상치 못한 값 참조

## 실무에서의 영향

var의 예측할 수 없는 동작은 실제 프로젝트에서 버그와 유지보수 문제를 야기합니다. 특히 비동기 코드나 이벤트 핸들러에서 예상치 못한 변수 값을 참조하거나, 의도하지 않은 전역 변수를 생성할 수 있습니다. ES6+에서 도입된 let과 const를 사용하면 이러한 문제들을 예방하고 더 예측 가능한 코드를 작성할 수 있습니다.

```

---

### 8.3 concepts-writer 프롬프트 설계

#### 8.3.1 에이전트 개요

**역할**: Core Concepts 섹션 작성 (3단계 난이도 설명)

**특성**:
- **핵심 기능**: Easy/Normal/Expert 3단계 난이도 설명 (프로젝트의 핵심)
- Overview 섹션 읽기 (의존성)
- Core Concepts 섹션 생성 (가장 긴 섹션, 200-400줄)
- 시각화 필요 여부 판단 (`needs_visualization` 플래그)

**Bounded Context**: Core Concepts Section Generation
- 소유 데이터: `# Core Concepts` 섹션 전체
- 접근 자원: Overview (읽기), frontmatter (읽기), Work Status Markers (읽기/쓰기)

**참조 계약**: `docs/aidlc-docs/specifications/contracts/concepts-writer-contract.md`

#### 8.3.2 프롬프트 구조 요약

```yaml
---
name: concepts-writer
version: 7.0.0
description: Generate Core Concepts with 3-level difficulty (Easy/Normal/Expert)
tools: [Read, Edit]
model: claude-sonnet-4
---
```

**섹션 구성** (총 400-500줄 예상):
1. Role and Responsibility
2. Input Contract
3. Output Contract (3단계 난이도 설명)
4. Execution Instructions
5. Difficulty Level Guidelines (핵심!)
6. Constraints (UTF-8 + 3단계 품질)
7. Error Handling
8. Handoff Protocol
9. Quality Standards
10. Examples (3단계 모두)

#### 8.3.3 핵심 지시사항

**Input Contract (요약)**:
```markdown
## Input Contract

**File State**:
- Target file with frontmatter, Work Status Markers, and `# Overview` section
- Overview section must exist (written by overview-writer)

**Work Status Markers**:
- `CURRENT_AGENT: concepts-writer` (MUST match)
- `STATUS: IN_PROGRESS`
- HANDOFF LOG contains `[DONE] overview-writer` entry

**Section Dependencies**:
- `# Overview`: MUST exist (read for context)

**Preconditions**:
- PC-1: `CURRENT_AGENT == "concepts-writer"`
- PC-2: `STATUS == IN_PROGRESS`
- PC-3: `# Overview` section exists
- PC-4: HANDOFF LOG contains `[DONE] overview-writer` OR `[IMPROVE] overview-writer`
```

**Output Contract (요약)**:
```markdown
## Output Contract

**File Modifications**:
- Add `# Core Concepts` section after `# Overview`
- Add `needs_visualization: true/false` to frontmatter
- Update Work Status Markers

**Section Structure**:
```markdown
# Core Concepts

## Easy (중학생도 이해 가능)

[3-5 paragraphs with daily life analogies, emojis, NO code]

## Normal (일반 개발자 수준)

[5-10 paragraphs with technical terms + simple code examples]

## Expert (20년+ 전문가 수준)

[5-10 paragraphs with ECMAScript specs, advanced terminology + explanations]
```

**Work Status Markers Updates**:
- `CURRENT_AGENT: visualization-writer` (next agent)
- `STATUS: IN_PROGRESS`
- `UPDATED: [current timestamp]`
- HANDOFF LOG: Add `[DONE] concepts-writer | Concepts completed | [timestamp]`

**Frontmatter Update**:
- Add `needs_visualization: true` if concept can be visualized
- Add `needs_visualization: false` if concept is purely abstract

**Content Guarantees**:
- Easy: 3-5 paragraphs, NO code, analogies, emojis optional
- Normal: 5-10 paragraphs, simple code examples, technical terms
- Expert: 5-10 paragraphs, ECMAScript specs, advanced concepts
- All Korean text: UTF-8 encoding
```

#### 8.3.4 Difficulty Level Guidelines (핵심!)

이 섹션이 concepts-writer의 핵심입니다.

```markdown
## Difficulty Level Guidelines

### Easy (중학생도 이해 가능)

**Target Audience**: 중학생, 프로그래밍 초심자

**Writing Style**:
- 일상 생활의 비유 사용 (예: "변수는 상자와 같다")
- 이모지 선택적 사용 (예: 📦 상자, 🔑 열쇠)
- 전문 용어 최소화, 사용 시 바로 설명
- **절대 코드 없음** (NO code blocks)

**Length**: 3-5 paragraphs (10-20 sentences)

**Example topics and analogies**:
- Variables → 상자에 물건 넣기
- Functions → 요리 레시피
- Loops → 반복 작업 (설거지, 청소)
- Arrays → 사물함, 책장
- Objects → 사람 정보 (이름, 나이, 주소)

**Tone**: 친근하고 대화체, "~합니다" 보다 "~해요" 형태 가능

**Example**:
```markdown
## Easy (중학생도 이해 가능)

var는 JavaScript에서 변수를 만드는 옛날 방법이에요. 변수는 값을 담는 상자라고 생각하면 됩니다 📦. var로 만든 변수는 특이한 점이 있는데, 선언하기 전에도 사용할 수 있다는 거예요. 마치 상자를 만들기 전에 이미 그 상자가 있는 것처럼 동작하죠.

이걸 "호이스팅"이라고 부르는데, 코드를 읽을 때 혼란스러울 수 있어요. 예를 들어, 아직 변수를 만들지 않았는데 그 변수를 사용하려고 하면 에러가 나지 않고 "undefined"라는 값이 나와요. 이건 마치 비어있는 상자를 먼저 준비해 둔 것 같은 상황이에요.

또 var는 블록 단위가 아니라 함수 단위로 동작해요. 중괄호 { } 안에서 var를 선언해도, 그 밖에서도 사용할 수 있다는 뜻이죠. 이것도 처음에는 이해하기 어려울 수 있어요. 그래서 요즘에는 var 대신 let과 const를 사용해요.
```

### Normal (일반 개발자 수준)

**Target Audience**: 1-3년차 개발자, 기본 프로그래밍 경험자

**Writing Style**:
- 기술 용어 사용 (변수, 스코프, 호이스팅 등)
- **간단한 코드 예시 포함** (5-10줄)
- 실무적 관점 (왜 문제가 되는지)
- 동작 원리 설명

**Length**: 5-10 paragraphs (20-40 sentences)

**Content Requirements**:
- 개념 정의 (기술적 용어로)
- 동작 방식 설명
- 간단한 코드 예시 (2-3개)
- 실무에서의 문제점

**Tone**: 전문적이지만 친근한, "~합니다" 형태

**Example**:
```markdown
## Normal (일반 개발자 수준)

var 키워드는 JavaScript에서 변수를 선언하는 초기 방법입니다. ES6(ES2015) 이전에는 var가 유일한 변수 선언 방법이었지만, 호이스팅과 스코프 문제로 인해 현재는 let과 const 사용이 권장됩니다.

**호이스팅 동작**:
var 선언은 호이스팅(hoisting)되어 스코프의 맨 위로 끌어올려집니다. 즉, 선언 전에 변수를 참조해도 에러가 발생하지 않고 undefined를 반환합니다:

\`\`\`javascript
console.log(name); // undefined (에러 아님)
var name = "Alice";
console.log(name); // "Alice"
\`\`\`

위 코드는 내부적으로 다음과 같이 해석됩니다:

\`\`\`javascript
var name; // 선언이 호이스팅됨
console.log(name); // undefined
name = "Alice";
console.log(name); // "Alice"
\`\`\`

**함수 스코프**:
var는 함수 스코프를 따릅니다. 블록 스코프(if, for, while 등의 중괄호)를 무시하고 가장 가까운 함수 스코프 또는 전역 스코프에 선언됩니다:

\`\`\`javascript
function test() {
  if (true) {
    var x = 10;
  }
  console.log(x); // 10 (블록 밖에서도 접근 가능)
}
\`\`\`

이러한 동작은 예상치 못한 버그를 유발할 수 있습니다. let과 const는 블록 스코프를 따르므로 이 문제를 해결합니다.
```

### Expert (20년+ 전문가 수준)

**Target Audience**: 시니어 개발자, 언어 명세에 관심 있는 전문가

**Writing Style**:
- ECMAScript 명세 참조
- 전문 용어 + 설명 (Lexical Environment, Variable Environment 등)
- 내부 동작 원리 (엔진 레벨)
- **고급 코드 예시** (엣지 케이스, 성능 이슈)

**Length**: 5-10 paragraphs (20-40 sentences)

**Content Requirements**:
- ECMAScript 명세 인용 (섹션 번호)
- 내부 동작 메커니즘 (Lexical Environment, Environment Record)
- 엣지 케이스 및 해결 방법
- 성능 고려사항 (V8, SpiderMonkey 등)

**Tone**: 매우 전문적, "~합니다" 형태, 정확한 용어 사용

**Example**:
```markdown
## Expert (20년+ 전문가 수준)

var 키워드의 동작은 ECMAScript 명세의 Variable Statement (섹션 13.3.2)에 정의되어 있습니다. var 선언은 Variable Environment의 Environment Record에 바인딩을 생성하며, 이는 함수 또는 전역 실행 컨텍스트의 생성 단계(Creation Phase)에서 발생합니다.

**Hoisting 메커니즘**:
호이스팅은 실제로 코드가 이동하는 것이 아니라, 실행 컨텍스트의 생성 단계에서 변수 선언이 먼저 처리되는 것입니다. 이 단계에서 var 선언된 변수는 Environment Record에 등록되고 undefined로 초기화됩니다 (ECMAScript 13.3.2.1 Runtime Semantics: Evaluation).

\`\`\`javascript
// 내부적으로 다음 단계로 처리됨:
// 1. Creation Phase: name 바인딩 생성, undefined로 초기화
// 2. Execution Phase: name에 "Alice" 할당
var name = "Alice";
\`\`\`

**Function Scope와 Lexical Environment**:
var는 함수 스코프를 따르므로, 블록 내부에서 선언되어도 Function Environment Record에 바인딩됩니다. let/const는 Block Environment Record를 사용하므로 블록 스코프를 구현합니다.

\`\`\`javascript
function outer() {
  // Function Environment Record 생성
  if (true) {
    // 블록이지만 var는 Function ER에 바인딩
    var x = 10;
  }
  console.log(x); // 10
}
\`\`\`

**Temporal Dead Zone (TDZ) 부재**:
var 선언은 TDZ가 없습니다. 즉, 선언 전에 접근해도 ReferenceError가 발생하지 않고 undefined를 반환합니다. 이는 let/const와의 주요 차이점입니다.

**성능 고려사항**:
현대 JavaScript 엔진(V8, SpiderMonkey)은 var의 호이스팅을 최적화하지만, 예측 불가능한 스코프 체인 탐색으로 인해 let/const보다 최적화가 어려울 수 있습니다. Hidden Class 생성 및 Inline Cache에도 영향을 줄 수 있습니다.
```

#### 8.3.5 DO / DO NOT

**DO**:
- ✅ **Write all 3 difficulty levels** (Easy, Normal, Expert)
- ✅ **Easy: NO code, use analogies and emojis**
- ✅ **Normal: Include simple code examples (5-10 lines)**
- ✅ **Expert: Reference ECMAScript specs, advanced concepts**
- ✅ **Use UTF-8 for all Korean content**
- ✅ **Add `needs_visualization` to frontmatter** (true/false)
- ✅ **Update CURRENT_AGENT to "visualization-writer"**
- ✅ **Add [DONE] entry to HANDOFF LOG**
- ✅ **Read Overview section for context**

**DO NOT**:
- ❌ **DO NOT include code in Easy level** (absolute rule)
- ❌ **DO NOT skip any difficulty level** (all 3 required)
- ❌ **DO NOT modify Overview section** (read-only)
- ❌ **DO NOT use headers deeper than `##`** (H1: Core Concepts, H2: Easy/Normal/Expert)
- ❌ **NEVER delete existing HANDOFF LOG entries**
- ❌ **DO NOT proceed if Overview section missing** (Fail-Fast)

#### 8.3.6 Constraints

```markdown
## Constraints

### UTF-8 Encoding (필수)

**CRITICAL**: Core Concepts is the LONGEST section (200-400 lines) with primarily Korean content.

- **All 3 difficulty levels in Korean**: UTF-8 encoding required
- **No garbled characters**: Verify �, □, ?, \uFFFD not present
- **Code comments can be Korean**: Ensure UTF-8 in code blocks too

**Self-Check**:
- [ ] Easy explanation: Korean text readable, no garbled chars
- [ ] Normal explanation: Korean text + code comments UTF-8
- [ ] Expert explanation: Korean text readable, no garbled chars

### 3-Level Quality Standards

**Easy**:
- Length: 3-5 paragraphs (minimum)
- NO code blocks (strict rule)
- At least 2 daily life analogies
- Emojis optional but encouraged

**Normal**:
- Length: 5-10 paragraphs (minimum)
- At least 2 code examples (5-10 lines each)
- Technical terms explained
- Practical perspective (why it matters)

**Expert**:
- Length: 5-10 paragraphs (minimum)
- ECMAScript spec references (section numbers)
- Internal mechanisms explained
- At least 1 advanced code example or edge case

### Visualization Flag

After writing concepts, decide:
- `needs_visualization: true` if concept can be visualized (e.g., scope chain, hoisting, prototype chain)
- `needs_visualization: false` if purely abstract (e.g., naming conventions, code style)
```

#### 8.3.7 예시

**Example: var 키워드의 문제점 (Normal level excerpt)**:

```markdown
## Normal (일반 개발자 수준)

var 키워드는 JavaScript에서 변수를 선언하는 초기 방법입니다. ES6(ES2015) 이전에는 var가 유일한 변수 선언 방법이었지만, 호이스팅과 스코프 문제로 인해 현재는 let과 const 사용이 권장됩니다.

**호이스팅 동작**:
var 선언은 호이스팅(hoisting)되어 스코프의 맨 위로 끌어올려집니다:

\`\`\`javascript
console.log(name); // undefined
var name = "Alice";
\`\`\`

**함수 스코프**:
var는 블록 스코프를 무시하고 함수 스코프를 따릅니다:

\`\`\`javascript
if (true) {
  var x = 10;
}
console.log(x); // 10 (블록 밖에서도 접근 가능)
\`\`\`
```

---

### 8.4 visualization-writer 프롬프트 설계

#### 8.4.1 에이전트 개요

**역할**: React 시각화 컴포넌트 생성

**특수성**:
- **조건부 실행**: `needs_visualization: false`이면 SKIP
- React 컴포넌트 파일 생성 (`.tsx`)
- `index.ts` 업데이트 (export 추가) - **CRITICAL**
- Concepts 섹션 텍스트 수정 금지

**Bounded Context**: Interactive Visualization Generation
- 소유 데이터: `src/components/visualization/[topic-id]/` 디렉터리
- 접근 자원: Core Concepts (읽기), frontmatter (읽기), index.ts (쓰기)

**참조 계약**: `docs/aidlc-docs/specifications/contracts/visualization-writer-contract.md`

#### 8.4.2 프롬프트 구조 요약

```yaml
---
name: visualization-writer
version: 2.0.0
description: Generate React visualization components for concepts
tools: [Read, Write, Edit]
model: claude-sonnet-4
---
```

**섹션 구성** (총 300-400줄 예상):
1. Role and Responsibility
2. Input Contract (needs_visualization 체크)
3. Output Contract (React 컴포넌트 + index.ts)
4. Execution Instructions (조건부 실행)
5. React Component Guidelines
6. Constraints
7. Error Handling
8. Handoff Protocol (SKIP 포함)
9. Examples

#### 8.4.3 핵심 지시사항

**Input Contract (요약)**:
```markdown
## Input Contract

**File State**:
- Target file with `# Core Concepts` section
- Frontmatter contains `needs_visualization: true/false`

**Work Status Markers**:
- `CURRENT_AGENT: visualization-writer` (MUST match)
- `STATUS: IN_PROGRESS`
- HANDOFF LOG contains `[DONE] concepts-writer`

**Preconditions**:
- PC-1: `CURRENT_AGENT == "visualization-writer"`
- PC-2: `# Core Concepts` section exists
- PC-3: `needs_visualization` field exists in frontmatter

**Conditional Execution**:
- If `needs_visualization: false` → SKIP (add [SKIP] to HANDOFF LOG)
- If `needs_visualization: true` → Generate visualization
```

**Output Contract (요약)**:
```markdown
## Output Contract

### Case 1: needs_visualization: false (SKIP)

**Actions**:
- Do NOT create any files
- Update Work Status Markers only
- Add `[SKIP] visualization-writer | Skipped - no visualization needed | [timestamp]`

### Case 2: needs_visualization: true (Generate)

**Files Created**:
1. `src/components/visualization/[topic-id]/[TopicId]Visualization.tsx`
   - React component with interactive visualization
   - TypeScript (.tsx)
   - Tailwind CSS for styling

2. Update `src/components/visualization/index.ts`
   - Add export: `export { default as [TopicId]Visualization } from './[topic-id]/[TopicId]Visualization'`
   - **CRITICAL**: Missing export causes "준비중" error in UI

**Work Status Markers Updates**:
- `CURRENT_AGENT: practice-writer`
- `STATUS: IN_PROGRESS`
- `UPDATED: [current timestamp]`
- HANDOFF LOG: `[DONE] visualization-writer | Visualization created | [timestamp]` OR `[SKIP]`

**Content Guarantees**:
- React component is valid TypeScript
- Component renders without errors
- Tailwind CSS classes used for styling
- index.ts export added (if generated)
```

**Execution Instructions (조건부)**:
```markdown
## Execution Instructions

### Step 1: Verify Preconditions

- [ ] PC-1: `CURRENT_AGENT == "visualization-writer"`
- [ ] PC-2: `# Core Concepts` section exists
- [ ] PC-3: `needs_visualization` field exists in frontmatter

### Step 2: Check needs_visualization

Read frontmatter and check `needs_visualization` value:

**If `false`**:
- Go to Step 7 (SKIP path)

**If `true`**:
- Proceed to Step 3 (Generate path)

### Step 3: Analyze Core Concepts (Generate path only)

Read `# Core Concepts` section to understand:
- What concept to visualize
- Key mechanisms to show (e.g., scope chain, hoisting, prototype lookup)
- Difficulty levels (Easy/Normal/Expert) for context

### Step 4: Design Visualization (Generate path only)

Decide on visualization type:
- **Interactive diagram**: Scope chain, call stack, prototype chain
- **Step-by-step animation**: Hoisting process, closure creation
- **State machine**: Event loop, promise resolution
- **Comparison view**: var vs let vs const

### Step 5: Generate React Component (Generate path only)

Create `.tsx` file at:
`src/components/visualization/[topic-id]/[TopicId]Visualization.tsx`

**Component structure**:
\`\`\`typescript
import React, { useState } from 'react';

export default function [TopicId]Visualization() {
  // State for interactivity
  const [currentStep, setCurrentStep] = useState(0);

  return (
    <div className="w-full p-4 bg-white rounded-lg shadow">
      {/* Visualization content */}
      <h3 className="text-lg font-bold mb-4">[시각화 제목]</h3>

      {/* Interactive elements */}
      <div className="space-y-4">
        {/* Diagram, animation, or interactive demo */}
      </div>

      {/* Controls */}
      <div className="mt-4 flex gap-2">
        <button className="px-4 py-2 bg-blue-500 text-white rounded">
          다음 단계
        </button>
      </div>
    </div>
  );
}
\`\`\`

**Requirements**:
- TypeScript (.tsx)
- React hooks (useState, useEffect)
- Tailwind CSS for styling
- Korean labels (한글, UTF-8)

### Step 6: Update index.ts (Generate path only) - CRITICAL

**CRITICAL**: This step is MANDATORY when generating visualization.

Edit `src/components/visualization/index.ts`:

**Add export**:
\`\`\`typescript
export { default as [TopicId]Visualization } from './[topic-id]/[TopicId]Visualization';
\`\`\`

**Example**:
If topic-id is `var-problems`, add:
\`\`\`typescript
export { default as VarProblemsVisualization } from './var-problems/VarProblemsVisualization';
\`\`\`

**Why CRITICAL**: Missing export causes UI to show "준비중" (Not Ready) instead of visualization.

### Step 7: Update Work Status Markers

**Generate path** (needs_visualization: true):
\`\`\`markdown
CURRENT_AGENT: practice-writer
STATUS: IN_PROGRESS
UPDATED: [timestamp]
HANDOFF LOG:
[existing entries...]
[DONE] visualization-writer | Visualization created for [topic-id] | [timestamp]
\`\`\`

**SKIP path** (needs_visualization: false):
\`\`\`markdown
CURRENT_AGENT: practice-writer
STATUS: IN_PROGRESS
UPDATED: [timestamp]
HANDOFF LOG:
[existing entries...]
[SKIP] visualization-writer | Skipped - no visualization needed | [timestamp]
\`\`\`

### Step 8: Verify Postconditions

**Generate path**:
- [ ] PO-1: `.tsx` file created in correct directory
- [ ] PO-2: Component is valid TypeScript
- [ ] PO-3: index.ts export added (CRITICAL)
- [ ] PO-4: `CURRENT_AGENT == "practice-writer"`
- [ ] PO-5: HANDOFF LOG has [DONE] entry

**SKIP path**:
- [ ] PO-1: No files created
- [ ] PO-2: `CURRENT_AGENT == "practice-writer"`
- [ ] PO-3: HANDOFF LOG has [SKIP] entry
```

#### 8.4.4 DO / DO NOT

**DO**:
- ✅ **Check `needs_visualization` field first** (conditional execution)
- ✅ **SKIP if `needs_visualization: false`** (add [SKIP] to log)
- ✅ **Generate React component if `true`**
- ✅ **Update index.ts with export** (CRITICAL)
- ✅ **Use Tailwind CSS for styling**
- ✅ **Use Korean labels in UI** (UTF-8)
- ✅ **Update CURRENT_AGENT to "practice-writer"**
- ✅ **Add [DONE] or [SKIP] to HANDOFF LOG**

**DO NOT**:
- ❌ **DO NOT modify Core Concepts section** (read-only, DO NOT add visualization marker)
- ❌ **DO NOT skip index.ts update** when generating (causes "준비중" error)
- ❌ **DO NOT generate visualization if `needs_visualization: false`**
- ❌ **DO NOT use inline styles** (use Tailwind classes)
- ❌ **DO NOT create .jsx files** (must be .tsx, TypeScript)
- ❌ **NEVER delete existing exports in index.ts** (only add new one)

#### 8.4.5 Constraints

```markdown
## Constraints

### Conditional Execution

**IMPORTANT**: This agent has TWO paths:
1. **SKIP path**: `needs_visualization: false` → No files, add [SKIP], move to next agent
2. **Generate path**: `needs_visualization: true` → Create component, update index.ts

### index.ts Export (CRITICAL)

**CRITICAL**: When generating visualization, MUST update index.ts.

- Missing export → UI shows "준비중" (Not Ready)
- Incorrect export → Runtime error

**Verification**:
After updating index.ts, verify:
- [ ] Export line added
- [ ] Export name matches component name (PascalCase)
- [ ] Path is correct (`./[topic-id]/[ComponentName]`)

### UTF-8 Encoding

- Component labels in Korean (버튼, 제목 등): UTF-8
- Korean text in JSX: UTF-8
- Comments can be Korean: UTF-8

### React Best Practices

- Use functional components
- Use TypeScript (.tsx)
- Use Tailwind CSS (no inline styles)
- Use React hooks (useState, useEffect)
```

#### 8.4.6 예시

**Example 1: SKIP path**

**Frontmatter**:
```yaml
needs_visualization: false
```

**Actions**:
- No files created
- HANDOFF LOG: `[SKIP] visualization-writer | Skipped - no visualization needed | [timestamp]`
- CURRENT_AGENT: practice-writer

**Example 2: Generate path**

**Frontmatter**:
```yaml
id: var-problems
needs_visualization: true
```

**File created**: `src/components/visualization/var-problems/VarProblemsVisualization.tsx`

**index.ts updated**:
```typescript
export { default as VarProblemsVisualization } from './var-problems/VarProblemsVisualization';
```

---

### 8.5 practice-writer 프롬프트 설계

#### 8.5.1 에이전트 개요

**역할**: Practice 섹션 작성 (Code Patterns + Experiments)

**특성**:
- 실습 콘텐츠 생성 (코드로 개념 확인)
- Code Patterns: 개념을 코드로 확인
- Experiments: 직접 실험하며 체득

**Bounded Context**: Practice Section Generation
- 소유 데이터: `# Practice` 섹션 전체
- 접근 자원: Core Concepts (읽기), Overview (읽기), frontmatter (읽기), Work Status Markers (읽기/쓰기)

**참조 계약**: `docs/aidlc-docs/specifications/contracts/practice-writer-contract.md`

#### 8.5.2 프롬프트 구조 요약 (간략히)

```yaml
---
name: practice-writer
version: 8.0.0
description: Generate Practice section with Code Patterns and Experiments
tools: [Read, Edit]
model: claude-sonnet-4
---
```

**섹션 구성**: Role, I/O Contract, Execution (Code Patterns 3-5개, Experiments 2-4개), Constraints (UTF-8), Error Handling, Handoff, Examples

#### 8.5.3 핵심 지시사항 (간략히)

**Output Contract**:
```markdown
# Practice

## Code Patterns

### 패턴 1: [패턴 이름]
[설명]
\`\`\`javascript
// 코드 예시
\`\`\`

### 패턴 2: [패턴 이름]
...

## Experiments

### 실험 1: [실험 제목]
[지시사항]
\`\`\`javascript
// 실험 코드
\`\`\`
**예상 결과**: ...
```

**DO / DO NOT**:
- ✅ Code Patterns: 3-5개 (최소 3개)
- ✅ Experiments: 2-4개 (최소 2개)
- ✅ 한글 설명 UTF-8
- ❌ DO NOT modify Core Concepts or Overview

---

### 8.6 quiz-writer 프롬프트 설계

#### 8.6.1 에이전트 개요

**역할**: Quiz 섹션 작성 (6가지 퀴즈 타입)

**특성**:
- 모든 학습 섹션 읽기 (Overview, Concepts, Practice)
- 6가지 퀴즈 타입 (multiple-choice, true-false, fill-in-blank, code-output, code-fix, concept-matching)
- 8-12개 문제 (난이도 분포: 1-2: 30%, 3: 40%, 4-5: 30%)

**Bounded Context**: Quiz Section Generation
- 소유 데이터: `# Quiz` 섹션 전체
- 접근 자원: 모든 학습 섹션 (읽기), Work Status Markers (읽기/쓰기)

**참조 계약**: `docs/aidlc-docs/specifications/contracts/quiz-writer-contract.md`

#### 8.6.2 프롬프트 구조 요약 (간략히)

```yaml
---
name: quiz-writer
version: 4.0.0
description: Generate Quiz section with 6 quiz types
tools: [Read, Edit]
model: claude-sonnet-4
---
```

**섹션 구성**: Role, I/O Contract, Execution (6가지 타입 설명), Difficulty Distribution, Constraints (UTF-8), Error Handling, Handoff, Examples

#### 8.6.3 핵심 지시사항 (간략히)

**6가지 퀴즈 타입**:
1. multiple-choice: 객관식 (4-5 선택지)
2. true-false: O/X 문제
3. fill-in-blank: 빈칸 채우기
4. code-output: 코드 실행 결과 예측
5. code-fix: 코드 오류 찾기 및 수정
6. concept-matching: 개념 매칭

**DO / DO NOT**:
- ✅ 8-12개 문제 (최소 8개)
- ✅ 난이도 분포 준수
- ✅ 6가지 타입 모두 사용
- ✅ 한글 UTF-8
- ❌ DO NOT modify other sections

---

### 8.7 content-validator 프롬프트 설계

#### 8.7.1 에이전트 개요

**역할**: 전체 콘텐츠 검증 및 개선 지시

**특성**:
- 파이프라인 마지막 에이전트
- 모든 섹션 품질 검증
- VALIDATION_SCORE (0-100) 계산
- 90점 미만: IMPROVEMENT_NEEDED 생성 → 개선 모드 진입
- 90점 이상: COMPLETE 처리

**Bounded Context**: Content Quality Validation
- 소유 데이터: VALIDATION_SCORE, IMPROVEMENT_NEEDED 필드
- 접근 자원: 모든 섹션 (읽기), Work Status Markers (읽기/쓰기)

**참조 계약**: `docs/aidlc-docs/specifications/contracts/content-validator-contract.md`

#### 8.7.2 프롬프트 구조 요약 (간략히)

```yaml
---
name: content-validator
version: 2.0.0
description: Validate content quality and guide improvements
tools: [Read, Edit]
model: claude-sonnet-4
---
```

**섹션 구성**: Role, I/O Contract, Execution (검증 단계), Scoring Rubric, Improvement Mode, Constraints, Error Handling, Handoff (COMPLETE), Examples

#### 8.7.3 핵심 지시사항 (간략히)

**검증 단계**:
1. Overview 검증 (20점)
2. Core Concepts 검증 (30점)
3. Practice 검증 (20점)
4. Quiz 검증 (20점)
5. UTF-8 인코딩 검증 (10점)

**Scoring Rubric**:
- 90-100점: 우수 → COMPLETE
- 80-89점: 양호 → IMPROVEMENT_NEEDED (선택)
- 70-79점: 보통 → IMPROVEMENT_NEEDED (필수)
- 70점 미만: 미흡 → IMPROVEMENT_NEEDED (필수)

**DO / DO NOT**:
- ✅ 모든 섹션 검증
- ✅ VALIDATION_SCORE 계산
- ✅ 90점 미만: IMPROVEMENT_NEEDED 생성
- ✅ 90점 이상: STATUS: COMPLETED, CURRENT_AGENT: ""
- ❌ DO NOT modify content sections (only markers)

---

## Section 8 완료

**작성 내용 요약**:
- 8.1 content-initiator: 파일 초기화, frontmatter + WSM 생성 (상세)
- 8.2 overview-writer: Overview 섹션 작성, 50-100줄 (상세)
- 8.3 concepts-writer: 3단계 난이도 설명 (Easy/Normal/Expert), 가이드라인 포함 (상세)
- 8.4 visualization-writer: React 컴포넌트 생성, index.ts 업데이트 (상세)
- 8.5 practice-writer: Code Patterns + Experiments (간략)
- 8.6 quiz-writer: 6가지 퀴즈 타입 (간략)
- 8.7 content-validator: 품질 검증 및 개선 지시 (간략)

**핵심 원칙**:
- 각 에이전트마다 Unit 2 계약 기반 프롬프트 설계
- Bounded Context 명확화 (DO/DO NOT)
- Fail-Fast 오류 처리 (Precondition/Postcondition)
- UTF-8 인코딩 보장 (모든 한글 콘텐츠)
- Handoff Protocol 표준화 (DONE/SKIP/IMPROVE/COMPLETE)
- 3단계 난이도 설명 가이드라인 (concepts-writer 핵심)
- 조건부 실행 (visualization-writer SKIP 경로)
- 품질 검증 및 개선 모드 (content-validator 90점 기준)

**다음 섹션**: Section 9 - 프롬프트 검증 전략

---

## 9. 프롬프트 검증 전략 (Prompt Validation Strategy)

### 목적

프롬프트 품질을 보장하기 위한 자동 검증 전략을 정의합니다. Question 3 답변(B - 중간 수준 자동화)에 따라 구조적 검증과 내용 검증을 자동화합니다.

**검증 목표**:
1. 프롬프트 구조적 완성도 검증 (필수 섹션, frontmatter 필드)
2. Unit 2 계약과의 일관성 검증
3. 용어 및 형식 표준 준수 검증
4. 프롬프트 길이 및 품질 기준 검증

**검증 수준** (Question 3: B - 중간):
- 정적 검증 (자동): frontmatter 필드, 필수 섹션 존재
- 내용 검증 (자동): 섹션 비어있지 않은지, 최소 길이
- 의미 검증 (수동): Unit 2 계약 일치 여부, 용어 일관성

---

### 9.1 정적 검증 (Static Validation)

#### 9.1.1 Frontmatter 검증

**검증 항목**:

| 필드 | 필수 | 타입 | 검증 규칙 |
|------|------|------|-----------|
| `name` | 필수 | string | 에이전트 이름 (kebab-case) |
| `version` | 필수 | string | SemVer 형식 (X.Y.Z) |
| `description` | 필수 | string | 1줄, 50자 이하 |
| `tools` | 필수 | array | 최소 1개, 유효한 도구명 |
| `model` | 필수 | string | "claude-sonnet-4" 또는 유효 모델명 |

**검증 스크립트 예시**:
```bash
# scripts/lib/validate-prompt-frontmatter.sh

validate_frontmatter() {
    local prompt_file="$1"
    local errors=0

    # frontmatter 존재 여부
    if ! grep -q "^---$" "$prompt_file"; then
        echo "❌ FAIL: No frontmatter found"
        ((errors++))
        return 1
    fi

    # name 필드 검증
    local name=$(awk '/^---$/,/^---$/ {if ($1 == "name:") print $2}' "$prompt_file")
    if [[ -z "$name" ]]; then
        echo "❌ FAIL: Missing 'name' field"
        ((errors++))
    elif ! echo "$name" | grep -qE '^[a-z]+(-[a-z]+)*$'; then
        echo "❌ FAIL: 'name' must be kebab-case: $name"
        ((errors++))
    else
        echo "✅ PASS: name = $name"
    fi

    # version 필드 검증 (SemVer)
    local version=$(awk '/^---$/,/^---$/ {if ($1 == "version:") print $2}' "$prompt_file")
    if [[ -z "$version" ]]; then
        echo "❌ FAIL: Missing 'version' field"
        ((errors++))
    elif ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "❌ FAIL: 'version' must be SemVer (X.Y.Z): $version"
        ((errors++))
    else
        echo "✅ PASS: version = $version"
    fi

    # description 필드 검증
    local description=$(awk '/^---$/,/^---$/ {if ($1 == "description:") {$1=""; print $0}}' "$prompt_file" | xargs)
    if [[ -z "$description" ]]; then
        echo "❌ FAIL: Missing 'description' field"
        ((errors++))
    elif [[ ${#description} -gt 100 ]]; then
        echo "⚠️  WARN: 'description' is too long (${#description} chars, max 100)"
    else
        echo "✅ PASS: description = $description"
    fi

    # tools 필드 검증
    if ! grep -qE "^tools:" "$prompt_file"; then
        echo "❌ FAIL: Missing 'tools' field"
        ((errors++))
    else
        echo "✅ PASS: tools field exists"
    fi

    # model 필드 검증
    local model=$(awk '/^---$/,/^---$/ {if ($1 == "model:") print $2}' "$prompt_file")
    if [[ -z "$model" ]]; then
        echo "❌ FAIL: Missing 'model' field"
        ((errors++))
    else
        echo "✅ PASS: model = $model"
    fi

    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "❌ Frontmatter validation FAILED: $errors error(s)"
        return 1
    else
        echo ""
        echo "✅ Frontmatter validation PASSED"
        return 0
    fi
}
```

#### 9.1.2 필수 섹션 검증

**모든 프롬프트 공통 필수 섹션**:

| 섹션 | 헤더 | 필수 여부 | 설명 |
|------|------|-----------|------|
| Role and Responsibility | `## Role and Responsibility` | 필수 | 에이전트 역할 정의 |
| Input Contract | `## Input Contract` | 필수 | 입력 명세 (요약) |
| Output Contract | `## Output Contract` | 필수 | 출력 명세 (요약) |
| Execution Instructions | `## Execution Instructions` | 필수 | 실행 단계 |
| Constraints | `## Constraints` | 필수 | 제약사항 (UTF-8 우선) |
| Error Handling | `## Error Handling` | 필수 | 오류 처리 |
| Handoff Protocol | `## Handoff Protocol` | 필수 | 핸드오프 규칙 |
| Examples | `## Examples` | 권장 | 실제 예시 |

**에이전트별 특수 섹션**:
- **concepts-writer**: `## Difficulty Level Guidelines` (필수)
- **visualization-writer**: `## React Component Guidelines` (필수)
- **content-validator**: `## Scoring Rubric` (필수)

**검증 스크립트 예시**:
```bash
# scripts/lib/validate-prompt-sections.sh

validate_sections() {
    local prompt_file="$1"
    local agent_name=$(basename "$prompt_file" .md)
    local errors=0

    echo "Validating sections for: $agent_name"

    # 공통 필수 섹션
    local required_sections=(
        "Role and Responsibility"
        "Input Contract"
        "Output Contract"
        "Execution Instructions"
        "Constraints"
        "Error Handling"
        "Handoff Protocol"
    )

    for section in "${required_sections[@]}"; do
        if grep -q "^## $section" "$prompt_file"; then
            echo "✅ PASS: $section"
        else
            echo "❌ FAIL: Missing required section: $section"
            ((errors++))
        fi
    done

    # 권장 섹션
    if grep -q "^## Examples" "$prompt_file"; then
        echo "✅ PASS: Examples (recommended)"
    else
        echo "⚠️  WARN: Missing recommended section: Examples"
    fi

    # 에이전트별 특수 섹션
    case "$agent_name" in
        concepts-writer)
            if grep -q "^## Difficulty Level Guidelines" "$prompt_file"; then
                echo "✅ PASS: Difficulty Level Guidelines (concepts-writer specific)"
            else
                echo "❌ FAIL: Missing concepts-writer specific section: Difficulty Level Guidelines"
                ((errors++))
            fi
            ;;
        visualization-writer)
            if grep -q "^## React Component Guidelines" "$prompt_file"; then
                echo "✅ PASS: React Component Guidelines (visualization-writer specific)"
            else
                echo "❌ FAIL: Missing visualization-writer specific section: React Component Guidelines"
                ((errors++))
            fi
            ;;
        content-validator)
            if grep -q "^## Scoring Rubric" "$prompt_file"; then
                echo "✅ PASS: Scoring Rubric (content-validator specific)"
            else
                echo "❌ FAIL: Missing content-validator specific section: Scoring Rubric"
                ((errors++))
            fi
            ;;
    esac

    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "❌ Section validation FAILED: $errors error(s)"
        return 1
    else
        echo ""
        echo "✅ Section validation PASSED"
        return 0
    fi
}
```

#### 9.1.3 프롬프트 길이 검증

**Question 2 답변: B (중간 - 200-400줄)**

**검증 규칙**:
- 최소 길이: 150줄 (너무 짧으면 정보 부족 경고)
- 권장 길이: 200-400줄 (적정 범위)
- 최대 길이: 500줄 (너무 길면 경고)

**검증 스크립트 예시**:
```bash
# scripts/lib/validate-prompt-length.sh

validate_length() {
    local prompt_file="$1"
    local line_count=$(wc -l < "$prompt_file")

    echo "Validating prompt length: $line_count lines"

    if [[ $line_count -lt 150 ]]; then
        echo "⚠️  WARN: Prompt is too short ($line_count lines, recommended 200-400)"
        return 1
    elif [[ $line_count -ge 150 && $line_count -lt 200 ]]; then
        echo "⚠️  INFO: Prompt is acceptable but could be more detailed ($line_count lines)"
        return 0
    elif [[ $line_count -ge 200 && $line_count -le 400 ]]; then
        echo "✅ PASS: Prompt length is optimal ($line_count lines)"
        return 0
    elif [[ $line_count -gt 400 && $line_count -le 500 ]]; then
        echo "⚠️  INFO: Prompt is long but acceptable ($line_count lines)"
        return 0
    else
        echo "⚠️  WARN: Prompt is too long ($line_count lines, recommended 200-400)"
        return 1
    fi
}
```

---

### 9.2 내용 검증 (Content Validation)

#### 9.2.1 섹션 비어있지 않은지 검증

**검증 규칙**:
- 각 필수 섹션이 헤더만 있고 내용이 없으면 실패
- 최소 3줄 이상의 내용이 있어야 함

**검증 스크립트 예시**:
```bash
# scripts/lib/validate-section-content.sh

validate_section_content() {
    local prompt_file="$1"
    local section_header="$2"
    local errors=0

    # 섹션 시작부터 다음 섹션 전까지 추출
    local section_content=$(awk "/^## $section_header$/,/^## / {print}" "$prompt_file" | sed '$d')
    local content_lines=$(echo "$section_content" | wc -l)

    # 헤더 제외한 실제 내용 줄 수
    local actual_content=$((content_lines - 1))

    if [[ $actual_content -lt 3 ]]; then
        echo "❌ FAIL: Section '$section_header' is empty or too short ($actual_content lines)"
        return 1
    else
        echo "✅ PASS: Section '$section_header' has content ($actual_content lines)"
        return 0
    fi
}

validate_all_section_content() {
    local prompt_file="$1"
    local errors=0

    local sections=(
        "Role and Responsibility"
        "Input Contract"
        "Output Contract"
        "Execution Instructions"
        "Constraints"
        "Error Handling"
        "Handoff Protocol"
    )

    for section in "${sections[@]}"; do
        if ! validate_section_content "$prompt_file" "$section"; then
            ((errors++))
        fi
    done

    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "❌ Content validation FAILED: $errors section(s) are empty"
        return 1
    else
        echo ""
        echo "✅ Content validation PASSED: All sections have content"
        return 0
    fi
}
```

#### 9.2.2 UTF-8 지시문 존재 검증

**검증 규칙**:
- `## Constraints` 섹션에 `### UTF-8 Encoding` 서브섹션 존재
- "CRITICAL" 키워드 존재 (강조 표시)
- "한글" 또는 "Korean" 키워드 존재

**검증 스크립트 예시**:
```bash
# scripts/lib/validate-utf8-constraint.sh

validate_utf8_constraint() {
    local prompt_file="$1"

    # Constraints 섹션에서 UTF-8 서브섹션 찾기
    if ! grep -q "^### UTF-8 Encoding" "$prompt_file"; then
        echo "❌ FAIL: Missing '### UTF-8 Encoding' subsection in Constraints"
        return 1
    fi

    # CRITICAL 키워드 확인
    if ! grep -A 5 "^### UTF-8 Encoding" "$prompt_file" | grep -q "CRITICAL"; then
        echo "⚠️  WARN: UTF-8 section missing 'CRITICAL' emphasis"
    fi

    # 한글/Korean 키워드 확인
    if ! grep -A 10 "^### UTF-8 Encoding" "$prompt_file" | grep -qE "(한글|Korean)"; then
        echo "⚠️  WARN: UTF-8 section missing '한글' or 'Korean' keyword"
    fi

    echo "✅ PASS: UTF-8 Encoding constraint exists"
    return 0
}
```

#### 9.2.3 DO/DO NOT 섹션 검증

**검증 규칙**:
- `## Execution Instructions` 또는 독립 섹션으로 DO/DO NOT 존재
- 최소 3개의 DO 항목
- 최소 3개의 DO NOT 항목

**검증 스크립트 예시**:
```bash
# scripts/lib/validate-do-donot.sh

validate_do_donot() {
    local prompt_file="$1"

    # DO 항목 개수
    local do_count=$(grep -c "^- ✅" "$prompt_file" || echo 0)

    # DO NOT 항목 개수
    local donot_count=$(grep -c "^- ❌" "$prompt_file" || echo 0)

    echo "DO items: $do_count"
    echo "DO NOT items: $donot_count"

    if [[ $do_count -lt 3 ]]; then
        echo "⚠️  WARN: Too few DO items ($do_count, recommended at least 3)"
    else
        echo "✅ PASS: Sufficient DO items ($do_count)"
    fi

    if [[ $donot_count -lt 3 ]]; then
        echo "⚠️  WARN: Too few DO NOT items ($donot_count, recommended at least 3)"
    else
        echo "✅ PASS: Sufficient DO NOT items ($donot_count)"
    fi

    if [[ $do_count -ge 3 && $donot_count -ge 3 ]]; then
        return 0
    else
        return 1
    fi
}
```

---

### 9.3 의미 검증 (Semantic Validation) - 수동

#### 9.3.1 Unit 2 계약 일치성 검증

**검증 항목** (수동 체크리스트):

- [ ] **Input Contract 일치**:
  - Unit 2 계약의 Input Contract와 프롬프트의 Input Contract 비교
  - Preconditions가 계약과 일치하는지 확인
  - File State, Work Status Markers 요구사항 일치

- [ ] **Output Contract 일치**:
  - Unit 2 계약의 Output Contract와 프롬프트의 Output Contract 비교
  - Postconditions가 계약과 일치하는지 확인
  - File Modifications, WSM Updates 일치

- [ ] **Error Handling 일치**:
  - Unit 2 계약의 Error Handling과 프롬프트의 Error Handling 일치
  - 오류 메시지 형식 일치 ("ERROR: [타입] - [상세]")

**검증 방법**:
1. Unit 2 계약 문서 열기 (`docs/aidlc-docs/specifications/contracts/[agent]-contract.md`)
2. 프롬프트 파일 열기 (`.claude/agents/[agent].md`)
3. 위 체크리스트 항목별로 수동 비교
4. 불일치 발견 시 프롬프트 수정

#### 9.3.2 용어 일관성 검증 (Ubiquitous Language)

**검증 항목**:

| 용어 | 표준 표현 | 금지 표현 |
|------|-----------|-----------|
| Work Status Markers | "Work Status Markers" | "WSM", "Markers", "Status Markers" |
| HANDOFF LOG | "HANDOFF LOG" | "Handoff Log", "handoff log" |
| CURRENT_AGENT | "CURRENT_AGENT" | "current_agent", "CurrentAgent" |
| Precondition | "Precondition" | "Pre-condition", "pre condition" |
| Postcondition | "Postcondition" | "Post-condition", "post condition" |
| Fail-Fast | "Fail-Fast" | "Fail Fast", "FailFast" |
| ISO 8601 | "ISO 8601" | "ISO8601" |
| UTF-8 | "UTF-8" | "utf-8", "UTF8" |

**검증 방법** (수동):
1. 프롬프트 파일에서 각 용어 검색
2. 금지 표현이 사용되었는지 확인
3. 발견 시 표준 표현으로 교체

**자동 검증 스크립트** (부분 자동화 가능):
```bash
# scripts/lib/validate-terminology.sh

validate_terminology() {
    local prompt_file="$1"
    local warnings=0

    # 금지 표현 검색
    if grep -qE '\bWSM\b' "$prompt_file"; then
        echo "⚠️  WARN: Found 'WSM', should use 'Work Status Markers'"
        ((warnings++))
    fi

    if grep -q "Handoff Log" "$prompt_file"; then
        echo "⚠️  WARN: Found 'Handoff Log', should use 'HANDOFF LOG'"
        ((warnings++))
    fi

    if grep -qE 'current_agent|CurrentAgent' "$prompt_file"; then
        echo "⚠️  WARN: Found incorrect casing, should use 'CURRENT_AGENT'"
        ((warnings++))
    fi

    if grep -qE 'Pre-condition|pre condition' "$prompt_file"; then
        echo "⚠️  WARN: Found incorrect spelling, should use 'Precondition'"
        ((warnings++))
    fi

    if [[ $warnings -gt 0 ]]; then
        echo ""
        echo "⚠️  Terminology validation: $warnings warning(s)"
        return 1
    else
        echo "✅ PASS: Terminology is consistent"
        return 0
    fi
}
```

#### 9.3.3 Handoff Protocol 일치성 검증

**검증 항목** (수동):

- [ ] **이전 에이전트 확인**:
  - 프롬프트에 명시된 이전 에이전트가 파이프라인 순서와 일치
  - 예: overview-writer의 이전 에이전트는 content-initiator

- [ ] **다음 에이전트 확인**:
  - 프롬프트에 명시된 다음 에이전트가 파이프라인 순서와 일치
  - 예: overview-writer의 다음 에이전트는 concepts-writer

- [ ] **HANDOFF LOG 형식**:
  - `[EVENT_TYPE] actor | message | timestamp` 형식 사용
  - EVENT_TYPE이 6가지 중 하나인지 확인 (START, DONE, IMPROVE, SKIP, FAILURE, COMPLETE)

**파이프라인 순서** (참조):
```
content-initiator → overview-writer → concepts-writer → visualization-writer
→ practice-writer → quiz-writer → content-validator
```

---

### 9.4 통합 검증 스크립트

#### 9.4.1 전체 검증 스크립트 명세

**스크립트 경로**: `scripts/lib/validate-prompts.sh`

**기능**:
1. 정적 검증 (자동)
2. 내용 검증 (자동)
3. 의미 검증 (부분 자동 + 수동 체크리스트 출력)

**사용법**:
```bash
# 단일 프롬프트 검증
./scripts/lib/validate-prompts.sh .claude/agents/overview-writer.md

# 전체 프롬프트 검증
./scripts/lib/validate-prompts.sh .claude/agents/*.md

# 검증 결과 저장
./scripts/lib/validate-prompts.sh .claude/agents/*.md > validation-report.txt
```

**통합 스크립트 예시**:
```bash
#!/bin/bash
# scripts/lib/validate-prompts.sh

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

validate_prompt() {
    local prompt_file="$1"
    local agent_name=$(basename "$prompt_file" .md)
    local total_errors=0
    local total_warnings=0

    echo "========================================"
    echo "Validating: $agent_name"
    echo "========================================"

    # 1. Frontmatter 검증
    echo ""
    echo "### 1. Frontmatter Validation ###"
    if ! validate_frontmatter "$prompt_file"; then
        ((total_errors++))
    fi

    # 2. 필수 섹션 검증
    echo ""
    echo "### 2. Section Validation ###"
    if ! validate_sections "$prompt_file"; then
        ((total_errors++))
    fi

    # 3. 프롬프트 길이 검증
    echo ""
    echo "### 3. Length Validation ###"
    if ! validate_length "$prompt_file"; then
        ((total_warnings++))
    fi

    # 4. 섹션 내용 검증
    echo ""
    echo "### 4. Content Validation ###"
    if ! validate_all_section_content "$prompt_file"; then
        ((total_errors++))
    fi

    # 5. UTF-8 제약사항 검증
    echo ""
    echo "### 5. UTF-8 Constraint Validation ###"
    if ! validate_utf8_constraint "$prompt_file"; then
        ((total_errors++))
    fi

    # 6. DO/DO NOT 검증
    echo ""
    echo "### 6. DO/DO NOT Validation ###"
    if ! validate_do_donot "$prompt_file"; then
        ((total_warnings++))
    fi

    # 7. 용어 일관성 검증
    echo ""
    echo "### 7. Terminology Validation ###"
    if ! validate_terminology "$prompt_file"; then
        ((total_warnings++))
    fi

    # 최종 결과
    echo ""
    echo "========================================"
    if [[ $total_errors -eq 0 && $total_warnings -eq 0 ]]; then
        echo -e "${GREEN}✅ VALIDATION PASSED${NC}: $agent_name"
    elif [[ $total_errors -eq 0 && $total_warnings -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  VALIDATION PASSED WITH WARNINGS${NC}: $agent_name ($total_warnings warning(s))"
    else
        echo -e "${RED}❌ VALIDATION FAILED${NC}: $agent_name ($total_errors error(s), $total_warnings warning(s))"
    fi
    echo "========================================"
    echo ""

    # 수동 검증 체크리스트 출력
    echo "### Manual Verification Checklist ###"
    echo "Please manually verify the following:"
    echo "  [ ] Input Contract matches Unit 2 contract"
    echo "  [ ] Output Contract matches Unit 2 contract"
    echo "  [ ] Error Handling matches Unit 2 contract"
    echo "  [ ] Handoff Protocol: Previous agent is correct"
    echo "  [ ] Handoff Protocol: Next agent is correct"
    echo ""

    if [[ $total_errors -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# 헬퍼 함수들 (위에서 정의한 함수들)
source "$(dirname "$0")/validate-prompt-frontmatter.sh"
source "$(dirname "$0")/validate-prompt-sections.sh"
source "$(dirname "$0")/validate-prompt-length.sh"
source "$(dirname "$0")/validate-section-content.sh"
source "$(dirname "$0")/validate-utf8-constraint.sh"
source "$(dirname "$0")/validate-do-donot.sh"
source "$(dirname "$0")/validate-terminology.sh"

# 메인 실행
main() {
    local prompt_files=("$@")
    local failed=0

    for prompt_file in "${prompt_files[@]}"; do
        if ! validate_prompt "$prompt_file"; then
            ((failed++))
        fi
    done

    echo "========================================"
    echo "Validation Summary"
    echo "========================================"
    echo "Total prompts: ${#prompt_files[@]}"
    echo "Failed: $failed"
    echo "Passed: $((${#prompt_files[@]} - failed))"
    echo "========================================"

    if [[ $failed -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
```

#### 9.4.2 CI/CD 통합

**GitHub Actions 워크플로우 예시**:
```yaml
# .github/workflows/validate-prompts.yml

name: Validate Agent Prompts

on:
  push:
    paths:
      - '.claude/agents/**'
  pull_request:
    paths:
      - '.claude/agents/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Validate all prompts
        run: |
          chmod +x scripts/lib/validate-prompts.sh
          ./scripts/lib/validate-prompts.sh .claude/agents/*.md

      - name: Upload validation report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: validation-report
          path: validation-report.txt
```

---

### 9.5 검증 오류 코드 및 메시지

#### 9.5.1 오류 코드 체계

| 오류 코드 | 타입 | 설명 | 심각도 |
|-----------|------|------|--------|
| E001 | Frontmatter | Missing frontmatter | 심각 |
| E002 | Frontmatter | Missing required field | 심각 |
| E003 | Frontmatter | Invalid field format | 심각 |
| E004 | Section | Missing required section | 심각 |
| E005 | Section | Empty section content | 심각 |
| W001 | Length | Prompt too short (<150 lines) | 경고 |
| W002 | Length | Prompt too long (>500 lines) | 경고 |
| W003 | Content | Missing UTF-8 constraint | 경고 |
| W004 | Content | Missing CRITICAL emphasis | 경고 |
| W005 | Content | Insufficient DO/DO NOT items | 경고 |
| W006 | Terminology | Inconsistent terminology | 경고 |

#### 9.5.2 표준 오류 메시지 형식

**형식**:
```
[오류코드] [파일:라인] [메시지]
```

**예시**:
```
E002 overview-writer.md:3 Missing required field 'version' in frontmatter
E004 concepts-writer.md:0 Missing required section 'Difficulty Level Guidelines'
W001 content-initiator.md:0 Prompt too short (145 lines, recommended 200-400)
W006 practice-writer.md:45 Found 'WSM', should use 'Work Status Markers'
```

---

## Section 9 완료

**작성 내용 요약**:
- 9.1 정적 검증 (Frontmatter 검증, 필수 섹션 검증, 프롬프트 길이 검증)
- 9.2 내용 검증 (섹션 내용 비어있지 않은지, UTF-8 지시문 존재, DO/DO NOT 섹션 검증)
- 9.3 의미 검증 (Unit 2 계약 일치성, 용어 일관성, Handoff Protocol 일치성) - 수동
- 9.4 통합 검증 스크립트 (전체 검증 스크립트 명세, CI/CD 통합)
- 9.5 검증 오류 코드 및 메시지 (오류 코드 체계, 표준 오류 메시지 형식)

**핵심 원칙**:
- Question 3 답변 적용 (B - 중간 수준 자동화)
- 정적 검증 + 내용 검증: 자동화
- 의미 검증: 수동 체크리스트 제공
- 검증 스크립트: `scripts/lib/validate-prompts.sh`
- CI/CD 통합: GitHub Actions 워크플로우
- 오류 코드 체계: E001-E005 (심각), W001-W006 (경고)
- 프롬프트 길이: 200-400줄 권장 (Question 2)

**다음 섹션**: Section 10 - 프롬프트 버전 관리

---

## 10. 프롬프트 버전 관리 (Prompt Versioning)

### 목적

프롬프트 버전 관리 전략을 정의합니다. Question 4 답변(루트의 backup 폴더)에 따라 백업 디렉터리 기반 버전 관리를 채택합니다.

**목표**:
1. 프롬프트 변경 이력 보존
2. 롤백 가능성 확보
3. 버전별 차이 추적 가능

---

### 10.1 버전 관리 전략

**채택 전략**: 백업 디렉터리 기반 (Question 4 답변)

**디렉터리 구조**:
```
backup/agents/
├── v1.0/                    # 버전 1.0 백업
│   ├── content-initiator.md
│   ├── overview-writer.md
│   ├── concepts-writer.md
│   ├── visualization-writer.md
│   ├── practice-writer.md
│   ├── quiz-writer.md
│   └── content-validator.md
├── v2.0/                    # 버전 2.0 백업 (미래)
│   └── ...
└── README.md                # 버전별 변경 사항 기록
```

**버전 번호**: Semantic Versioning (SemVer) - X.Y.Z
- MAJOR (X): 호환성 깨지는 변경 (Breaking Changes)
- MINOR (Y): 기능 추가 (호환성 유지)
- PATCH (Z): 버그 수정

---

### 10.2 백업 절차

**프롬프트 업데이트 시**:
```bash
# 1. 현재 프롬프트 백업 (버전 번호로)
mkdir -p backup/agents/v1.0
cp .claude/agents/*.md backup/agents/v1.0/

# 2. 백업 README 업데이트
cat >> backup/agents/v1.0/README.md <<EOF
# Agent Prompts v1.0

**Backup Date**: $(date +"%Y-%m-%d")
**Git Commit**: $(git rev-parse HEAD)

## Changes
- Initial version after Unit 3 DDD design
- All 7 agents: content-initiator, overview-writer, concepts-writer, visualization-writer, practice-writer, quiz-writer, content-validator

## Breaking Changes
- None (initial version)
EOF

# 3. Git 커밋
git add backup/agents/v1.0
git commit -m "backup: Add agent prompts v1.0"
```

---

### 10.3 롤백 전략

**롤백 시나리오**:
1. 새 프롬프트로 콘텐츠 생성 실패율 급증
2. 품질 저하 (VALIDATION_SCORE 하락)
3. 프롬프트 버그 발견

**롤백 절차**:
```bash
# 1. 백업에서 복원
cp backup/agents/v1.0/*.md .claude/agents/

# 2. Git 커밋
git add .claude/agents/
git commit -m "rollback: Revert to agent prompts v1.0"

# 3. 검증
./scripts/lib/validate-prompts.sh .claude/agents/*.md
```

---

### 10.4 Breaking Changes 판단 기준

**Breaking Change 예시**:
- Input Contract 변경 (Precondition 추가/제거)
- Output Contract 변경 (Postcondition 추가/제거)
- Work Status Markers 필드 변경 (새 필드 추가)
- HANDOFF LOG 형식 변경

**Non-Breaking Change 예시**:
- 설명 문구 개선
- 예시 추가
- 오타 수정
- DO/DO NOT 항목 추가 (기존 동작 유지)

---

## Section 10 완료

**다음 섹션**: Section 11 - 프롬프트 작성 가이드

---

## 11. 프롬프트 작성 가이드 (Prompt Writing Guide)

### 목적

새 에이전트 추가 또는 기존 프롬프트 수정 시 참고할 가이드를 제공합니다.

---

### 11.1 새 에이전트 추가 시

**Step 1: Unit 2에서 계약 먼저 작성**
- `docs/aidlc-docs/specifications/contracts/[new-agent]-contract.md` 작성
- Input Contract, Output Contract, Preconditions, Postconditions 정의

**Step 2: 프롬프트 템플릿 생성**
- Section 2 템플릿 사용
- `.claude/agents/[new-agent].md` 생성

**Step 3: Section 3-7 원칙 적용**
- I/O Contract 통합 (Section 3)
- Bounded Context 정의 (Section 4)
- Work Status Markers 조작 표준 (Section 5)
- Fail-Fast 오류 처리 (Section 6)
- UTF-8 인코딩 보장 (Section 7)

**Step 4: 검증**
- `./scripts/lib/validate-prompts.sh .claude/agents/[new-agent].md`

---

### 11.2 기존 프롬프트 수정 시

**체크사항**:
- [ ] Unit 2 계약과 불일치 발생 여부 확인
- [ ] 다른 에이전트에 미치는 영향 분석 (Handoff Protocol)
- [ ] Breaking Change 여부 판단
- [ ] 프롬프트 버전 업데이트 필요 여부 (frontmatter version 필드)

**수정 후**:
- [ ] 검증 스크립트 실행
- [ ] 테스트 콘텐츠 생성 (1-2개 토픽)
- [ ] 품질 확인 (VALIDATION_SCORE)
- [ ] 백업 (Breaking Change인 경우)

---

### 11.3 프롬프트 테스트 방법

**단일 에이전트 테스트**:
```bash
# 특정 에이전트만 실행
claude code -a overview-writer --file test-topic.md
```

**전체 파이프라인 테스트**:
```bash
# 전체 콘텐츠 생성 파이프라인
./scripts/content-generator-v6.sh --direct test-topic.md
```

**품질 검증**:
```bash
# 섹션별 파싱 테스트
npx tsx test/test-overview.mjs test-topic.md
npx tsx test/test-concepts.mjs test-topic.md
npx tsx test/test-quiz-raw.mjs test-topic.md
```

---

## Section 11 완료

**다음 섹션**: Section 12 - Summary and Next Steps

---

## 12. Summary and Next Steps

### 12.1 핵심 설계 결정 사항 요약

**Architectural Decisions (AD)**:

**AD-1: Prompt as Published Language**
- 결정: 프롬프트를 Filter의 Published Language로 정의
- 이유: Bounded Context 간 명확한 인터페이스 제공, DDD 원칙 적용
- 영향: 프롬프트 = 에이전트 실행 명세 + 계약 문서

**AD-2: Contract-to-Prompt Transformation (Summary + Reference)**
- 결정: Question 1 - B (요약 + 참조)
- 이유: 프롬프트 간결성 유지, 에이전트 즉시 이해 가능
- 영향: Input/Output Contract 30-40% 포함, Preconditions/Postconditions 100% 포함

**AD-3: Prompt Length Target (200-400 lines)**
- 결정: Question 2 - B (중간 길이)
- 이유: 참조 문서 없이도 대부분 작업 가능, AI 놓칠 위험 최소화
- 영향: 모든 프롬프트 200-400줄 목표

**AD-4: Validation Automation Level (Medium)**
- 결정: Question 3 - B (중간 수준 자동화)
- 이유: 구조/내용 검증 자동화, 의미 검증은 수동으로 품질 보장
- 영향: `scripts/lib/validate-prompts.sh` 자동 검증, 수동 체크리스트 제공

**AD-5: Backup-Based Versioning**
- 결정: Question 4 - 루트의 backup 폴더
- 이유: 명시적 버전 관리, 롤백 용이성
- 영향: `backup/agents/v1.0/` 구조, SemVer 버전 번호

**Design Decisions (DD)**:

**DD-1: 3-Level Difficulty Guidel ines (concepts-writer 핵심)**
- Easy: 일상 비유, 이모지, 절대 코드 없음
- Normal: 기술 용어, 간단한 코드 (5-10줄)
- Expert: ECMAScript 명세, 내부 메커니즘

**DD-2: Conditional Execution (visualization-writer)**
- needs_visualization 플래그 기반 SKIP/Generate 경로 분기

**DD-3: CRITICAL Tag for UTF-8**
- 모든 프롬프트 Constraints 섹션 최우선 배치

**DD-4: Fail-Fast Error Handling**
- 모든 에이전트 Precondition 실패 시 즉시 EXIT 1

**DD-5: 90-Point Quality Threshold (content-validator)**
- 90점 이상: COMPLETE
- 90점 미만: IMPROVEMENT_NEEDED → 개선 모드 진입

---

### 12.2 Phase 2.2 준비사항

**Phase 2.2: 논리적 설계 (Logical Design)**

**작업 내용**:
1. 프롬프트 템플릿 구체화
   - Section 2 템플릿을 실제 프롬프트로 구체화
   - 각 섹션별 상세 작성 예시

2. 자동 검증 스크립트 구현
   - `scripts/lib/validate-prompts.sh` 실제 구현
   - 모든 헬퍼 함수 구현 (validate-frontmatter.sh, validate-sections.sh, ...)

3. 7개 에이전트 프롬프트 초안 작성
   - Section 8 설계 기반으로 실제 프롬프트 작성
   - `.claude/agents/[agent].md` 파일 생성

4. 프롬프트 간 일관성 검증
   - 용어 일관성 (Ubiquitous Language)
   - Handoff Protocol 일치성
   - I/O Contract 연결성

**산출물**:
- `logical_design.md`: 논리적 설계 문서
- `scripts/lib/validate-*.sh`: 검증 스크립트 구현
- `.claude/agents/*.md`: 7개 프롬프트 초안

---

### 12.3 Open Questions

**질문 1: Prompt Context Length**
- 현재 설계: 200-400줄 (Question 2: B)
- 이슈: Claude의 context window 제한 고려 필요?
- 해결 방안: Phase 2.3에서 실제 테스트 후 재조정

**질문 2: Improvement Mode 최대 반복 횟수**
- 현재 설계: content-validator가 90점 미만 시 개선 지시
- 이슈: 몇 번 반복해도 90점 도달 못하면?
- 해결 방안: Phase 2.3에서 최대 반복 횟수 (예: 3회) 정의

**질문 3: Visualization Component 재사용**
- 현재 설계: 각 토픽마다 새 컴포넌트 생성
- 이슈: 유사한 개념의 시각화 재사용 가능?
- 해결 방안: Phase 3 (Implementation)에서 컴포넌트 라이브러리 고려

**질문 4: Prompt Backward Compatibility**
- 현재 설계: SemVer 버전 관리, Breaking Change 판단 기준 정의
- 이슈: 구버전 프롬프트로 생성된 콘텐츠와 신버전 호환성?
- 해결 방안: Phase 4 (Testing)에서 호환성 테스트 정의

---

## Phase 2.1 완료

**작성 완료**: `domain_design.md` - v1.0 (12개 섹션, ~6,800줄)

**핵심 성과**:
1. ✅ 프롬프트 도메인 모델 정의 (DDD 경량화)
2. ✅ 프롬프트 템플릿 구조 표준화 (10개 섹션)
3. ✅ I/O Contract 통합 패턴 정의 (요약 + 참조)
4. ✅ 에이전트 책임 경계 명확화 (Bounded Context, DO/DO NOT)
5. ✅ Work Status Markers 조작 표준화 (6가지 EVENT_TYPE)
6. ✅ Fail-Fast 오류 처리 표준화
7. ✅ UTF-8 인코딩 보장 전략 (CRITICAL 우선순위)
8. ✅ 7개 에이전트 프롬프트 설계 (상세 4개, 간략 3개)
9. ✅ 프롬프트 검증 전략 (자동 + 수동)
10. ✅ 프롬프트 버전 관리 (backup/agents/v1.0/)
11. ✅ 프롬프트 작성 가이드
12. ✅ Summary and Next Steps

**Question 1-4 답변 모두 반영**:
- Question 1: B (요약 + 참조) → Section 3
- Question 2: B (중간 200-400줄) → Section 2, 9
- Question 3: B (중간 수준 자동화) → Section 9
- Question 4: 루트의 backup 폴더 → Section 10

**다음 단계**:
- **Phase 2.2: 논리적 설계** - 프롬프트 템플릿 구체화, 검증 스크립트 구현
- **Phase 2.3: 물리적 설계** - 7개 프롬프트 실제 작성 및 검증
- **Phase 3: Implementation** - 프롬프트 배포 및 콘텐츠 생성 테스트
- **Phase 4: Testing** - 전체 파이프라인 품질 검증

---

**승인 요청**: Phase 2.1 domain_design.md 검토 및 승인 부탁드립니다. 승인 후 Phase 2.2로 진행하겠습니다.

---
