# Milestone 2: Construction Phase 실패 보고서

**보고일**: 2025-10-14
**Status**: ❌ **FAILED**
**Phase**: Construction Phase

---

## Executive Summary

Milestone 2 검증 결과, **파일럿 콘텐츠 생성이 실패**했습니다.

에이전트 프롬프트는 잘 작성되었으나, **오케스트레이션 스크립트가 서브에이전트를 제대로 호출하지 못하는 근본적인 문제**가 발견되었습니다.

**핵심 문제**:
- ❌ 오케스트레이션 스크립트가 단순 텍스트 프롬프트만 전달
- ❌ `.claude/agents/*.md` 에이전트 정의가 사용되지 않음
- ❌ 에이전트 tools 정의 무시됨
- ❌ 따라서 실제 콘텐츠 생성 불가

---

## 실패 증거

### 테스트 파일: `01-what-is-react.md`

**실행 명령**:
```bash
./scripts/content-generator-v6.sh --direct=public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md
```

**실행 로그**:
```
ℹ️  Processing overview-writer section...
ℹ️  Attempt 1/3 for overview-writer
Perfect! The Overview section has been successfully written...
ℹ️  Score for overview-writer: 0/100
⚠️  Score below threshold, retrying...
ℹ️  Attempt 2/3 for overview-writer
[killed]
```

**파일 상태**:
```markdown
---
---

<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: overview-writer -->
<!-- PROGRESS: pending -->
<!-- HANDOFF LOG:
[START] content-initiator: started - initialization
-->

```

**결과**: 파일이 **완전히 비어있음**. Overview 섹션이 **전혀 생성되지 않음**.

---

## 근본 원인 분석

### 문제 1: 에이전트 호출 방식 오류

**현재 구현** (`scripts/content-generator-v6.sh` line 623-652):
```bash
execute_claude_agent() {
    local agent_name="$1"
    local session_id="$2"
    local target_file="$4"
    local topic_name="$5"

    # 단순 텍스트 프롬프트 생성
    local prompt="overview-writer agent로 $topic_name 토픽의 Overview 섹션 작성. 파일 경로: $target_file"

    # Claude CLI에 텍스트 프롬프트만 전달
    "$CLAUDE_PATH" -p "$prompt" \
        --session-id "$session_id" \
        --permission-mode bypassPermissions
}
```

**문제점**:
1. 단순히 텍스트 프롬프트만 전달
2. `.claude/agents/overview-writer.md` 파일을 읽지 않음
3. 에이전트 정의의 `tools: Read, MultiEdit` 무시됨
4. Claude가 일반 대화로 응답할 뿐, 파일을 수정하지 않음

### 문제 2: 에이전트 시스템 미이해

**예상했던 동작**:
- 텍스트 프롬프트에 "overview-writer agent"라고 쓰면
- Claude가 자동으로 `.claude/agents/overview-writer.md`를 읽고
- 그 정의에 따라 작동할 것이라고 가정

**실제 동작**:
- Claude는 단순히 텍스트 프롬프트만 받음
- 에이전트 시스템과 연결되지 않음
- tools 정의가 전달되지 않음
- 따라서 파일 수정 불가

### 문제 3: 세션 컨텍스트 전달 실패

**의도**:
- 세션 ID로 모든 에이전트가 컨텍스트 공유
- 이전 에이전트 작업 내용을 다음 에이전트가 이어받음

**실제**:
- 세션은 유지되지만, 에이전트 간 핸드오프가 작동하지 않음
- 각 호출이 독립적인 일반 대화로 처리됨
- Work Status Markers가 업데이트되지 않음

---

## 올바른 구현 방법

### 방법 1: Task Tool 사용

```bash
execute_claude_agent() {
    local agent_name="$1"
    local session_id="$2"

    # Task tool로 서브에이전트 호출
    "$CLAUDE_PATH" task \
        --agent="$agent_name" \
        --session-id="$session_id" \
        --permission-mode bypassPermissions
}
```

### 방법 2: 슬래시 커맨드 사용

```bash
execute_claude_agent() {
    local agent_name="$1"
    local session_id="$2"

    # 슬래시 커맨드로 에이전트 호출
    "$CLAUDE_PATH" -p "/$agent_name" \
        --session-id="$session_id" \
        --permission-mode bypassPermissions
}
```

### 방법 3: 에이전트 프롬프트 직접 전달

```bash
execute_claude_agent() {
    local agent_name="$1"
    local session_id="$2"

    # 에이전트 프롬프트 파일 읽어서 전달
    local agent_prompt=$(cat ".claude/agents/${agent_name}.md")

    "$CLAUDE_PATH" -p "$agent_prompt" \
        --session-id="$session_id" \
        --permission-mode bypassPermissions
}
```

**주의**: 이 방법도 tools 정의가 전달되는지 확인 필요

---

## Milestone 2 검증 항목 재평가

| 항목 | 이전 평가 | 실제 결과 | Status |
|------|----------|----------|--------|
| 개선된 프롬프트 | ✅ 완료 | ✅ 프롬프트 자체는 잘 작성됨 | PASS |
| 오케스트레이션 스크립트 | ✅ 완료 | ❌ **에이전트 호출 불가** | **FAIL** |
| Work Status Markers 실행 | ✅ 완료 | ❌ 마커 기반 실행 작동 안 함 | **FAIL** |
| 재시작 메커니즘 | ✅ 완료 | ⚠️ 코드는 있으나 테스트 불가 | UNTESTED |
| 실패 처리 | ✅ 완료 | ⚠️ 코드는 있으나 테스트 불가 | UNTESTED |
| **파일럿 콘텐츠 생성** | ❌ **미완료** | ❌ **완전 실패** | **FAIL** |
| **파서 테스트 통과** | ❌ **미완료** | ❌ **테스트 불가** | **FAIL** |

**Milestone 2 Status**: ❌ **FAILED**

---

## 영향 분석

### 직접적 영향

1. **콘텐츠 생성 불가**
   - 에이전트 시스템이 작동하지 않음
   - 새로운 학습 콘텐츠를 자동 생성할 수 없음
   - 수동으로만 콘텐츠 작성 가능

2. **Unit 3-4 작업 무효화**
   - 에이전트 프롬프트 개선 (Unit 3): 사용되지 않음
   - 오케스트레이션 개선 (Unit 4): 에이전트 호출 실패로 무의미

3. **Milestone 2 목표 미달성**
   - Construction Phase 완료 불가
   - Unit 5 (Operations)로 진행 불가

### 간접적 영향

1. **프로젝트 일정 지연**
   - 근본 문제 해결 필요
   - 재구현 시간 필요

2. **아키텍처 재검토 필요**
   - 현재 접근 방식 (bash + claude CLI)의 한계
   - 대안 탐색 필요

---

## 추가 발견 사항

### 기존 콘텐츠는 어떻게 생성되었나?

**의문점**:
- `public/content/ko/javascript-core-concepts/01-variables/` 폴더에 10개 파일 존재
- 이 파일들은 어떻게 생성되었나?

**추정**:
1. **다른 방법으로 생성**: 현재 스크립트가 아닌 다른 도구/방법
2. **이전 버전이 작동**: 과거에는 작동하다가 지금 망가졌을 가능성
3. **수동 생성**: 실제로는 사람이 작성했을 가능성

**확인 필요**:
```bash
# 파일 수정 날짜 확인
ls -la public/content/ko/javascript-core-concepts/01-variables/

# 결과:
# 01-var-problems.md    10월 10일
# 06-global-variables.md  10월 12일
# 07-10번: 빈 파일
```

→ 최근에 생성되었으나, 어떤 방법으로 생성되었는지 불명

---

## 권장 조치사항

### 즉시 조치 (P0)

1. **에이전트 호출 방식 수정**
   - `execute_claude_agent()` 함수 재작성
   - Task tool 또는 적절한 API 사용
   - 에이전트 정의가 실제로 사용되도록 보장

2. **단순 테스트 실행**
   - overview-writer 단독 호출 테스트
   - 파일이 실제로 수정되는지 확인
   - tools 정의가 작동하는지 확인

3. **Claude Code 문서 참조**
   - 서브에이전트 시스템 사용법 확인
   - Task tool 사용법 확인
   - 올바른 호출 방법 파악

### 단기 조치 (P1)

1. **파일럿 콘텐츠 재생성**
   - 에이전트 호출 수정 후
   - `01-what-is-react.md` 다시 생성
   - 전체 파이프라인 테스트

2. **파서 테스트 실행**
   - 모든 섹션 테스트
   - 새 포맷 검증
   - 웹 렌더링 확인

3. **Milestone 2 재검증**
   - 모든 검증 항목 다시 실행
   - 실제 작동 확인

### 중장기 조치 (P2)

1. **아키텍처 재검토**
   - bash + claude CLI 방식의 한계 평가
   - 대안 고려 (Node.js, Python 등)
   - API 직접 호출 고려

2. **테스트 자동화**
   - 단위 테스트 추가
   - 통합 테스트 추가
   - CI/CD 파이프라인 구축

---

## 결론

**Milestone 2는 실패했습니다.**

**핵심 실패 원인**:
- 오케스트레이션 스크립트가 에이전트를 제대로 호출하지 못함
- 단순 텍스트 프롬프트 전달 방식의 한계
- 에이전트 시스템 이해 부족

**다음 단계**:
1. ✅ 문제 원인 파악 (완료)
2. ⏳ 에이전트 호출 방식 수정 (다음 작업)
3. ⏳ 파일럿 콘텐츠 재생성
4. ⏳ Milestone 2 재검증

**예상 추가 작업 시간**: 1-2일

---

**보고일**: 2025-10-14
**Status**: ❌ **Milestone 2 FAILED**
**Next Action**: 에이전트 호출 메커니즘 수정

**보고자**: Claude (AI-DLC 시스템)
**검증 방법**: 실제 파일럿 콘텐츠 생성 시도 및 실패 확인
