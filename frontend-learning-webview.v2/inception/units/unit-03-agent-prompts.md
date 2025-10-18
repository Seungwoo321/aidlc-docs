# Unit 3: Agent Prompts 개선

## 개요

**목적**: 에이전트 프롬프트를 Unit 1(Pipe 명세)과 Unit 2(Filter 계약)를 반영하여 개선하고, 명확한 I/O 명세와 책임 경계를 프롬프트에 명시한다.

**현재 문제점**:
- 프롬프트에 입출력 명세가 산재되어 있거나 누락
- Work Status Markers 조작 방법이 일관되지 않음
- 에이전트 책임 경계가 모호 (예: visualization-writer가 concepts 수정 가능?)
- 오류 처리 지침 부재

**개선 방향**:
- Unit 2의 계약을 프롬프트에 통합
- Unit 1의 Pipe 메커니즘을 에이전트에게 명확히 지시
- 에이전트의 "DO"와 "DO NOT" 명확화
- 오류 상황 처리 방법 추가

## 범위

### In Scope
1. **프롬프트 템플릿 개선**
   - I/O Contract 섹션 추가
   - Work Status Markers 조작 가이드 추가
   - 오류 처리 섹션 추가
   - 검증 체크리스트 추가

2. **7개 에이전트 프롬프트 업데이트**
   - 각 에이전트 프롬프트를 템플릿에 맞춰 재작성
   - Unit 2의 계약 반영
   - UTF-8 인코딩 명시적 지시

3. **프롬프트 검증 체크리스트 작성**
   - 모든 프롬프트가 갖춰야 할 필수 요소 체크리스트
   - 프롬프트 품질 기준

4. **프롬프트 개선 가이드 작성**
   - 새 에이전트 추가 시 프롬프트 작성 방법
   - 기존 프롬프트 수정 시 주의사항

### Out of Scope
- 에이전트 실행 방법 변경 (Unit 4에서 처리)
- 품질 측정 기준 (Unit 5에서 처리)
- 에이전트 코드 구현 (프롬프트만 개선)

## 아키텍처 컨텍스트

**Pipeline Architecture 관점**:
- **Filter 구현체**: 프롬프트는 Filter의 실행 로직 정의
- **자기 문서화**: 프롬프트 자체가 에이전트의 명세 역할
- **표준화**: 모든 Filter가 동일한 구조의 프롬프트 사용

**DDD 경량화 관점**:
- **Ubiquitous Language**: 프롬프트에서 사용하는 용어가 도메인 언어
- **명시적 경계**: 프롬프트에 Bounded Context 경계 명시
- **책임 명확화**: "이것은 내 책임, 저것은 다른 에이전트 책임" 명확히

## 작업 항목

### 1. 개선된 프롬프트 템플릿 작성
**예상 산출물**: `docs/aidlc-docs/templates/agent-prompt-template.md`

**템플릿 구조**:
```markdown
---
name: [agent-name]
version: [semantic-version]
description: [한 문장 설명]
tools: [사용 도구 목록]
model: [AI 모델]
---

# [Agent Name]

## Role & Responsibility
[에이전트의 역할과 책임 명확히 정의]

## Input Contract (from Unit 2)
[Unit 2에서 정의한 Input Contract 요약]

### Expected File State
- [필수 파일 및 섹션]

### Expected Work Status Markers
- CURRENT_AGENT: [기대값]
- STATUS: [기대값]

### Dependencies
- [이전 에이전트 목록]

## Output Contract (from Unit 2)
[Unit 2에서 정의한 Output Contract 요약]

### File Modifications
- [추가/수정할 섹션]

### Work Status Markers Updates
- CURRENT_AGENT: [설정할 값]
- STATUS: [설정할 값]
- HANDOFF LOG: `[EVENT_TYPE] agent-name | message | YYYY-MM-DDTHH:MM:SS+09:00` 형식으로 엔트리 추가

### Content Guarantees
- [생성 콘텐츠 보장 사항]

## Execution Instructions

### Step 1: Validate Preconditions
- [ ] Check CURRENT_AGENT matches
- [ ] Verify required sections exist
- [ ] Validate file encoding (UTF-8)

### Step 2: Perform Work
[구체적 작업 단계]

### Step 3: Update Work Status Markers
- [ ] Add HANDOFF LOG entry (`[EVENT_TYPE] agent-name | message | ISO8601_timestamp`)
- [ ] Update CURRENT_AGENT to next agent
- [ ] Update STATUS (if needed)
- [ ] Update UPDATED timestamp (ISO 8601 format)

### Step 4: Validate Postconditions
- [ ] Verify output section exists
- [ ] Run parser test (if applicable)
- [ ] Confirm UTF-8 encoding

## Critical Constraints

### DO
- [반드시 해야 할 것들]

### DO NOT
- [절대 하지 말아야 할 것들]

## Error Handling

### Error Scenarios
1. [오류 시나리오 1]
   - Detection: [감지 방법]
   - Handling: [처리 방법]

### Recovery Instructions
[에러 복구 방법]

## Handoff Protocol (from Unit 1)

### Event Types
에이전트는 작업 완료 시 적절한 이벤트 타입을 사용하여 HANDOFF LOG에 기록해야 합니다:

- **START**: 파이프라인 시작 (content-initiator만 사용)
- **DONE**: 첫 번째 작업 완료 (일반 실행)
- **IMPROVE**: 개선 작업 완료 (IMPROVEMENT_NEEDED 응답 시)
- **FAILURE**: 실행 실패 (Precondition 실패, 실행 오류 등)
- **SKIP**: 건너뛰기 (--skip 옵션 사용 시)
- **COMPLETE**: 최종 완료 (content-validator만 사용, VALIDATION_SCORE ≥ 90)

### HANDOFF LOG Format
```
[EVENT_TYPE] agent-name | message | YYYY-MM-DDTHH:MM:SS+09:00
```

**예시**:
```
[DONE] overview-writer | Overview 섹션 작성 완료 (150줄) | 2025-10-16T10:05:30+09:00
[IMPROVE] concepts-writer | Expert 난이도 확장 완료 | 2025-10-16T10:42:00+09:00
```

### Work Status Markers 조작 규칙
1. **Precondition 확인**: `CURRENT_AGENT` 필드가 자신의 이름과 일치하는지 확인
2. **작업 수행**: 계약에 정의된 출력물 생성
3. **Postcondition 보장**: 출력 섹션 존재, 파싱 테스트 통과
4. **마커 업데이트**:
   - `HANDOFF LOG`에 엔트리 추가 (적절한 EVENT_TYPE 사용)
   - `CURRENT_AGENT`를 다음 에이전트로 업데이트
   - `STATUS` 업데이트 (필요 시)
   - `UPDATED` 타임스탬프 갱신 (ISO 8601 형식)

## Quality Standards
[출력물 품질 기준]

## Examples
[입력/출력 예시]

## References
- Contract Specification: [경로]
- Work Status Markers Spec: [경로]
- Handoff Guide: [경로]
```

### 2. 7개 에이전트 프롬프트 업데이트
**예상 산출물**: `.claude/agents/[agent-name].md` 업데이트 (7개 파일)

**각 에이전트별 작업**:

1. **content-initiator.md**
   - Input Contract 명확화: 파일 경로, category.yaml
   - Output Contract: Work Status Markers 초기화 보장
   - 오류 처리: 파일 이미 존재 시, 권한 없을 시

2. **overview-writer.md**
   - Input: CURRENT_AGENT=overview-writer 검증
   - Output: Overview 섹션 구조 명세 (현재 50-100줄 가이드라인 명확히)
   - DO NOT: 다른 섹션 수정 금지

3. **concepts-writer.md**
   - Input: Overview 섹션 존재 검증
   - Output: Easy/Normal/Expert 3단계 보장
   - 품질 기준: 각 난이도별 최소 길이, 필수 요소

4. **visualization-writer.md**
   - Input: Core Concepts 섹션 존재
   - Output: Visualization 메타데이터 삽입 위치 명확화
   - DO NOT: Concepts 텍스트 수정 금지 (메타데이터만 추가)

5. **practice-writer.md**
   - Input: Core Concepts 섹션 존재
   - Output: Code Patterns + Experiments 모두 생성 보장
   - 품질 기준: 최소 패턴 수, 실험 수

6. **quiz-writer.md**
   - Input: 모든 학습 섹션 존재
   - Output: 다양한 퀴즈 타입 (multiple-choice, true-false, fill-in-the-blank 등)
   - 품질 기준: 최소 퀴즈 수, 난이도 분포

7. **content-validator.md**
   - Input: 모든 섹션 존재
   - Output: VALIDATION_SCORE, IMPROVEMENT_NEEDED
   - 개선 지시 형식 표준화

### 3. 프롬프트 검증 체크리스트 작성
**예상 산출물**: `docs/aidlc-docs/checklists/prompt-quality-checklist.md`

**체크리스트 항목**:
- [ ] Role & Responsibility 명확히 정의됨
- [ ] Input Contract 명시됨
- [ ] Output Contract 명시됨
- [ ] Preconditions 검증 단계 포함
- [ ] Postconditions 검증 단계 포함
- [ ] Work Status Markers 조작 지침 포함
- [ ] DO / DO NOT 명확함
- [ ] 오류 처리 지침 포함
- [ ] UTF-8 인코딩 명시적 지시
- [ ] 예시 포함
- [ ] Contract Specification 참조 포함

### 4. 프롬프트 작성 가이드 작성
**예상 산출물**: `docs/aidlc-docs/guides/agent-prompt-writing-guide.md`

**포함 내용**:
- 새 에이전트 추가 시 프롬프트 작성 단계
- 기존 프롬프트 수정 시 체크 사항
- 프롬프트 테스트 방법
- 프롬프트 버전 관리 방법

### 5. 프롬프트 자동 검증 스크립트
**예상 산출물**: `scripts/lib/validate-prompts.sh`

**검증 항목**:
- frontmatter 필수 필드 존재 확인
- Input/Output Contract 섹션 존재 확인
- DO/DO NOT 섹션 존재 확인
- 프롬프트 길이 체크 (너무 짧거나 길지 않은지)

## 의존성

### 입력 의존성
- **Unit 1**: Work Status Markers 명세 (프롬프트에서 참조)
- **Unit 2**: Filter Contracts (프롬프트에 통합)

### 출력 의존성
- **Unit 4**: Orchestration이 업데이트된 프롬프트 기반으로 에이전트 실행
- **Unit 5**: Quality Metrics가 프롬프트 품질 기준 사용

## 성공 기준

1. **완전성**: 모든 에이전트 프롬프트가 템플릿의 모든 섹션 포함
2. **명확성**: 프롬프트만 보고 에이전트가 무엇을 해야 하는지 100% 이해 가능
3. **일관성**: 7개 프롬프트가 동일한 구조와 용어 사용
4. **검증 가능성**: 자동 스크립트로 프롬프트 품질 검증 가능

## 예상 산출물 리스트

1. `docs/aidlc-docs/templates/agent-prompt-template.md`
2. `.claude/agents/content-initiator.md` (업데이트)
3. `.claude/agents/overview-writer.md` (업데이트)
4. `.claude/agents/concepts-writer.md` (업데이트)
5. `.claude/agents/visualization-writer.md` (업데이트)
6. `.claude/agents/practice-writer.md` (업데이트)
7. `.claude/agents/quiz-writer.md` (업데이트)
8. `.claude/agents/content-validator.md` (업데이트)
9. `docs/aidlc-docs/checklists/prompt-quality-checklist.md`
10. `docs/aidlc-docs/guides/agent-prompt-writing-guide.md`
11. `scripts/lib/validate-prompts.sh`

## 예상 작업 기간

- 템플릿 작성: 1일
- 7개 프롬프트 업데이트: 4일 (각 0.5~0.6일 × 7개)
- 체크리스트 및 가이드 작성: 1일
- 검증 스크립트 개발: 1일
- **총 예상: 7일**

## 리스크 및 완화 방안

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| 프롬프트가 너무 길어져 AI가 이해 못함 | 높음 | 핵심만 명시, 상세 내용은 참조 문서로 분리 |
| 기존 에이전트 동작 변경으로 콘텐츠 품질 저하 | 높음 | 업데이트 전후 출력물 비교 테스트 |
| 프롬프트 변경 시 모든 에이전트 재테스트 필요 | 중간 | 단계적 롤아웃, 1개씩 업데이트 후 검증 |

## 질문 사항

### Question 1: 프롬프트 상세도 ✅ 결정됨
**질문**: Input/Output Contract를 프롬프트에 얼마나 상세히 포함할까요?

**최종 결정**: **B - 요약만 포함 + 계약 문서 참조**

**구현 상세**:
- 프롬프트에는 Input/Output Contract의 핵심 내용만 요약
- 상세 내용은 Unit 2의 계약 문서 참조
- 프롬프트 간결성 유지하면서 명확성 확보

**중요 참고사항**:
- Claude Code 공식 문서 [Quick Start 가이드](https://docs.claude.com/en/docs/claude-code/sub-agents#quick-start) 참조
- 서브에이전트 작성 시 공식 문서의 best practices 준수

---

### Question 2: 오류 처리 자율성 ✅ 결정됨
**질문**: 에이전트가 오류를 자율적으로 처리하게 할까요?

**최종 결정**: **A - 오류 발생 시 즉시 종료 (Fail-Fast)**

**동작 방식**:
1. 에이전트가 Precondition 실패 또는 실행 오류 감지 시 즉시 중단
2. 명확한 오류 메시지 출력
3. Exit code 1로 종료
4. HANDOFF LOG에 FAILURE 기록
5. 오케스트레이션 스크립트에서 재시도 또는 복구 처리

**Unit 4 연계**: orchestration 스크립트에서 오류 처리 로직 구현

---

### Question 3: UTF-8 인코딩 검증 ✅ 결정됨 (중요 주의사항)
**질문**: 에이전트가 직접 UTF-8 인코딩을 검증할까요?

**최종 결정**: **A + C - 명시적 지시 + 사후 검증**

**⚠️ 중요 변경 사항 (사용자 피드백)**:
> UTF-8 관련해서 지금 수준의 쉘 스크립트 설정이 없으면 한글이 깨지는 문제가 발생합니다. 이 점을 주의하세요. 문서는 한글이 정상 작성 되어야 합니다.

**구현 영향**:
1. **에이전트 프롬프트**:
   - 모든 프롬프트에 "UTF-8 인코딩으로 작성" 명시적 지시
   - 한글 콘텐츠 정상 작성 필수 강조

2. **오케스트레이션 스크립트** (Unit 4):
   - 쉘 스크립트 환경 변수 설정 필수:
     ```bash
     export LANG=ko_KR.UTF-8
     export LC_ALL=ko_KR.UTF-8
     ```
   - 에이전트 실행 후 파일 인코딩 검증:
     ```bash
     file -b --mime-encoding "$filepath" | grep -q "utf-8"
     ```

3. **검증 스크립트**:
   - 한글 문자 깨짐 감지 로직 추가
   - 인코딩 오류 시 명확한 오류 메시지

---

### Question 4: 기존 프롬프트 백업 ✅ 결정됨 (재검토 필요)
**질문**: 기존 프롬프트를 백업할까요?

**사용자 질문**:
> docs/aidlc-docs/ai-dlc-whitepaper-ko.md 에 따르면 프롬프트를 보존하도록 되어 있지 않나요?

**임시 결정**: **프롬프트 보존 정책 재검토 필요**

**검토 사항**:
1. AI-DLC 화이트페이퍼 프롬프트 보존 지침 확인
2. 프롬프트 버전 관리 전략 수립:
   - 옵션 A: Git 버전 관리
   - 옵션 B: `.claude/agents/backup/` 디렉터리
   - 옵션 C: 별도 브랜치

**Unit 3 작업 시 재결정**: 화이트페이퍼 검토 후 최종 결정
