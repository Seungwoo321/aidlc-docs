# Unit 2: Filter Contracts 명시화

## 개요

**목적**: 각 에이전트(Filter)의 입출력 계약을 명시적으로 정의하여 에이전트 간 결합도를 낮추고, 독립적인 개발/테스트/개선을 가능하게 한다.

**현재 문제점**:
- 에이전트가 기대하는 입력과 생성하는 출력이 암묵적
- 에이전트 프롬프트에 산재된 정보로 인해 전체 파이프라인 이해 어려움
- 계약 변경 시 영향 범위 파악 불가
- 에이전트 간 의존성이 불명확

**개선 방향**:
- 각 에이전트의 입출력 명세를 명시적 계약으로 정의
- DDD의 Bounded Context 개념 적용하여 에이전트 경계 명확화
- Interface Definition Language (IDL) 스타일 명세 작성
- 계약 준수 여부를 자동 검증하는 메커니즘 구축

## 범위

### In Scope
1. **에이전트별 계약 명세 작성**
   - 7개 에이전트 (content-initiator, overview-writer, concepts-writer, visualization-writer, practice-writer, quiz-writer, content-validator) 각각의 계약 정의
   - Input Contract: 에이전트 시작 시 기대하는 상태
   - Output Contract: 에이전트 완료 시 보장하는 상태
   - Preconditions: 실행 전 만족해야 할 조건
   - Postconditions: 실행 후 보장되는 조건

2. **계약 검증 메커니즘 개발**
   - 에이전트 실행 전 Precondition 검증
   - 에이전트 실행 후 Postcondition 검증
   - 계약 위반 시 명확한 오류 메시지

3. **에이전트 책임 경계 정의**
   - 각 에이전트가 담당하는 섹션 명확화
   - 다른 에이전트 출력물에 대한 수정 금지 규칙
   - 공유 자원 (Work Status Markers) 접근 규칙

4. **계약 변경 관리 프로세스 정의**
   - 계약 버전 관리 방법
   - 하위 호환성 보장 전략
   - Breaking Change 처리 방법

### Out of Scope
- 에이전트 프롬프트 구체적 작성 방법 (Unit 3에서 처리)
- 오케스트레이션 로직 구현 (Unit 4에서 처리)
- 품질 점수 계산 로직 (Unit 5에서 처리)

## 아키텍처 컨텍스트

**Pipeline Architecture 관점**:
- **Filter 역할**: 각 에이전트는 입력을 받아 변환 후 출력하는 독립 Filter
- **데이터 변환**: 마크다운 파일을 점진적으로 완성
- **단방향 흐름**: 데이터는 content-initiator → content-validator 방향으로만 흐름

**DDD 경량화 관점**:
- **Bounded Context**: 각 에이전트가 하나의 Bounded Context
- **Context Mapping**: 에이전트 간 관계는 Shared Kernel (Work Status Markers) + Published Language (마크다운 섹션)
- **Anti-Corruption Layer**: 각 에이전트는 다른 에이전트 출력을 직접 수정하지 않음

## 작업 항목

### 1. 계약 명세 템플릿 정의
**예상 산출물**: `docs/aidlc-docs/specifications/agent-contract-template.md`

**템플릿 구조**:
```markdown
# Agent Contract: [Agent Name]

## Metadata
- Agent ID: [agent-name]
- Version: 1.0
- Bounded Context: [context-name]
- Position in Pipeline: [순서]

## Responsibility
[에이전트가 담당하는 작업의 본질적 목적]

## Input Contract

### File State
- Required Files: [필요한 파일 목록]
- File Encoding: UTF-8
- Frontmatter: Required/Optional
- Existing Sections: [이미 존재해야 하는 섹션]

### Work Status Markers
- CURRENT_AGENT: [기대값]
- STATUS: [기대값]
- Other Fields: [기대 조건]

### Section Dependencies
[이 에이전트가 의존하는 다른 에이전트의 섹션]

## Output Contract

### File State
- Modified Files: [수정하는 파일]
- New Sections: [추가하는 섹션 목록]
- Section Structure: [섹션 구조 명세]

### Work Status Markers
- CURRENT_AGENT: [설정값]
- STATUS: [설정값]
- HANDOFF LOG: `[EVENT_TYPE] agent-name | message | YYYY-MM-DDTHH:MM:SS+09:00` 형식 엔트리 추가

**Event Types**: START, DONE, IMPROVE, FAILURE, SKIP, COMPLETE

### Content Guarantees
[생성하는 콘텐츠의 보장 사항]

## Preconditions
[실행 전 검증 조건]

## Postconditions
[실행 후 검증 조건]

## Error Handling
[에러 발생 시 처리 방법]

## Examples
[입력/출력 예시]
```

### 2. 7개 에이전트 계약 작성
**예상 산출물**: `docs/aidlc-docs/specifications/contracts/[agent-name]-contract.md` (7개 파일)

**에이전트 목록**:
1. **content-initiator-contract.md**
   - Input: 파일 경로, 토픽 메타데이터 (category.yaml)
   - Output: Work Status Markers 초기화, 빈 마크다운 파일 또는 frontmatter

2. **overview-writer-contract.md**
   - Input: Work Status Markers (CURRENT_AGENT=overview-writer)
   - Output: `# Overview` 섹션 추가, CURRENT_AGENT=concepts-writer

3. **concepts-writer-contract.md**
   - Input: Overview 섹션 존재
   - Output: `# Core Concepts` 섹션 추가 (Easy/Normal/Expert 3단계)

4. **visualization-writer-contract.md**
   - Input: Core Concepts 섹션 존재
   - Output: Visualization 메타데이터 추가 (각 Concept에 임베딩)

5. **practice-writer-contract.md**
   - Input: Core Concepts 섹션 존재
   - Output: `# Code Patterns` + `# Experiments` 섹션 추가

6. **quiz-writer-contract.md**
   - Input: 모든 학습 섹션 존재
   - Output: `# Quiz` 섹션 추가

7. **content-validator-contract.md**
   - Input: 모든 섹션 존재
   - Output: VALIDATION_SCORE 설정, IMPROVEMENT_NEEDED 생성 (필요 시)

### 3. 계약 검증 스크립트 개발
**예상 산출물**: `scripts/lib/contract-validator.sh`

**함수 목록**:
```bash
# Precondition 검증
validate_preconditions() {
    local agent_name=$1
    local file_path=$2
    # 계약 명세에서 preconditions 읽고 검증
}

# Postcondition 검증
validate_postconditions() {
    local agent_name=$1
    local file_path=$2
    # 계약 명세에서 postconditions 읽고 검증
}

# 섹션 존재 여부 검증
validate_section_exists() {
    local file_path=$1
    local section_header=$2
}

# 섹션 구조 검증
validate_section_structure() {
    local file_path=$1
    local section_name=$2
    # 헤더 레벨, 필수 하위 섹션 등 검증
}
```

### 4. 에이전트 의존성 그래프 작성
**예상 산출물**: `docs/aidlc-docs/specifications/agent-dependency-graph.md`

**포함 내용**:
```
content-initiator
    ↓
overview-writer (depends on: content-initiator)
    ↓
concepts-writer (depends on: overview-writer)
    ↓
visualization-writer (depends on: concepts-writer)
    ↓
practice-writer (depends on: concepts-writer)
    ↓
quiz-writer (depends on: overview-writer, concepts-writer, practice-writer)
    ↓
content-validator (depends on: all previous agents)
```

**의존성 유형**:
- **Hard Dependency**: 반드시 필요 (예: overview-writer → concepts-writer, visualization-writer)
- **Data Dependency**: 특정 섹션 필요 (예: quiz-writer는 Core Concepts 필요)

**⚠️ 중요 변경 사항**:
- **visualization-writer는 필수 에이전트**로 결정됨 (Question 3 답변 참조)
- 모든 콘텐츠에 시각화 컴포넌트 필수 생성

### 5. Breaking Change 관리 가이드 작성
**예상 산출물**: `docs/aidlc-docs/guides/contract-versioning-guide.md`

**포함 내용**:
- 계약 버전 번호 부여 규칙 (Semantic Versioning)
- Breaking Change 정의
- 하위 호환성 유지 전략
- 계약 변경 시 영향 받는 에이전트 식별 방법

## 의존성

### 입력 의존성
- **Unit 1**: Work Status Markers 명세 (입출력 계약에서 참조)

### 출력 의존성
- **Unit 3**: Agent Prompts가 이 계약을 준수하도록 작성
- **Unit 4**: Orchestration이 계약 검증 로직 호출
- **Unit 5**: Quality Metrics가 계약 준수 여부를 품질 지표로 사용

## 성공 기준

1. **명세 완성도**: 7개 에이전트의 모든 입출력 조건이 명시적으로 정의됨
2. **검증 정확도**: 계약 위반 시 100% 감지
3. **독립성 확보**: 계약만 보고 에이전트를 독립적으로 개발 가능
4. **변경 영향 분석**: 계약 변경 시 영향 받는 에이전트 자동 식별

## 예상 산출물 리스트

1. `docs/aidlc-docs/specifications/agent-contract-template.md`
2. `docs/aidlc-docs/specifications/contracts/content-initiator-contract.md`
3. `docs/aidlc-docs/specifications/contracts/overview-writer-contract.md`
4. `docs/aidlc-docs/specifications/contracts/concepts-writer-contract.md`
5. `docs/aidlc-docs/specifications/contracts/visualization-writer-contract.md`
6. `docs/aidlc-docs/specifications/contracts/practice-writer-contract.md`
7. `docs/aidlc-docs/specifications/contracts/quiz-writer-contract.md`
8. `docs/aidlc-docs/specifications/contracts/content-validator-contract.md`
9. `scripts/lib/contract-validator.sh`
10. `docs/aidlc-docs/specifications/agent-dependency-graph.md`
11. `docs/aidlc-docs/guides/contract-versioning-guide.md`

## 예상 작업 기간

- 템플릿 정의: 1일
- 7개 에이전트 계약 작성: 3일 (각 0.5일 × 7개)
- 검증 스크립트 개발: 2일
- 의존성 그래프 및 가이드 작성: 1일
- **총 예상: 7일**

## 리스크 및 완화 방안

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| 계약이 너무 엄격하여 에이전트 유연성 저하 | 중간 | Preconditions는 엄격하게, Postconditions는 최소한으로 |
| 기존 에이전트 동작과 계약 불일치 | 높음 | 기존 에이전트 출력물 분석 후 계약 작성 |
| 계약 검증 오버헤드로 파이프라인 속도 저하 | 낮음 | 검증을 선택적으로 활성화 (--validate 플래그) |

## 질문 사항

### Question 1: 계약 명세 형식 ✅ 결정됨
**질문**: 계약 명세를 어떤 형식으로 작성할까요?

**최종 결정**: **C - YAML frontmatter + 마크다운**

**구현 상세**:
```markdown
---
agent_id: overview-writer
version: 1.0
dependencies: [content-initiator]
---

# Agent Contract: Overview Writer

## Input Contract
...
```

**장점**:
- frontmatter에서 메타데이터 기계 파싱
- 마크다운 본문에서 사람이 읽기 쉬운 설명

---

### Question 2: 계약 위반 처리 ✅ 결정됨
**질문**: Precondition 위반 시 어떻게 처리할까요?

**최종 결정**: **A - Fail-Fast (즉시 실패)**

**동작 방식**:
1. Precondition 검증 실패 시 즉시 중단
2. 명확한 오류 메시지 출력:
   ```
   ❌ Precondition Failed: overview-writer
   - Expected: CURRENT_AGENT=overview-writer
   - Actual: CURRENT_AGENT=concepts-writer
   - Fix: Check Work Status Markers
   ```
3. Exit code 1로 종료
4. HANDOFF LOG에 FAILURE 기록

**Unit 4 연계**: orchestration 스크립트에서 검증 호출 구현

---

### Question 3: visualization-writer 의존성 ✅ 결정됨 (권장과 다름)
**질문**: visualization-writer는 필수 에이전트인가요?

**최종 결정**: **A - 필수 에이전트 (항상 실행)**

**변경 근거** (사용자 답변):
- 모든 콘텐츠에 시각화 컴포넌트 필수
- --skip-visualization 옵션 제거 예정

**구현 영향**:
1. **에이전트 의존성 그래프**: Hard Dependency로 표기
2. **계약 명세**: visualization-writer를 필수 단계로 정의
3. **오케스트레이션**: skip 옵션 처리 코드 제거
4. **품질 메트릭**: 시각화 컴포넌트 존재 여부를 필수 검증 항목에 포함
