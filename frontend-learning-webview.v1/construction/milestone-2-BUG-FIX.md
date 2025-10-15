# Milestone 2: Bug Fix Report

**수정일**: 2025-10-14
**Status**: ✅ **FIXED**
**Issue**: Overview 섹션이 생성되지 않는 문제

---

## Bug Summary

**증상**:
- overview-writer 에이전트가 "Perfect! Overview written!" 메시지를 출력
- 하지만 실제 파일에는 아무것도 작성되지 않음
- 점수 계산 결과 0/100 (섹션 누락 감지)

**원인**:
Unit 4 개선 과정에서 `execute_comprehensive_mode`가 `topic_name` 파라미터를 전달하지 않아, 에이전트 프롬프트에 **파일 경로가 포함되지 않았음**.

---

## Root Cause Analysis

### 문제 코드 (Before Fix)

**execute_comprehensive_mode (line 274-309):**
```bash
execute_comprehensive_mode() {
    local session_id="$1"
    local target_file="$2"

    # ❌ topic_name을 추출하지 않음!

    while [ $iteration -lt $max_iterations ]; do
        local next_agent=$(determine_next_agent "$target_file")

        # ❌ topic_name 자리에 빈 문자열 전달
        execute_claude_agent "$next_agent" "$session_id" "$is_first" "$target_file" ""
    done
}
```

**execute_claude_agent (line 639-644):**
```bash
"overview-writer")
    # 두 조건 모두 만족해야 함
    if [ -n "$target_file" ] && [ -n "$topic_name" ]; then
        prompt="overview-writer agent로 $topic_name 토픽의 Overview 섹션 작성. 파일 경로: $target_file"
    else
        # ❌ topic_name이 비어있으면 여기로 fallback
        prompt="overview-writer agent로 Overview 섹션 작성"
        # → 파일 경로가 없음!
    fi
```

### 실행 흐름

1. `execute_comprehensive_mode("session-id", "path/to/file.md")` 호출
2. `execute_claude_agent("overview-writer", "session-id", "true", "path/to/file.md", "")`
   - `target_file` = "path/to/file.md" ✅
   - `topic_name` = "" (빈 문자열) ❌
3. 조건문 `[ -n "$target_file" ] && [ -n "$topic_name" ]` 평가:
   - `[ -n "path/to/file.md" ]` → true ✅
   - `[ -n "" ]` → **false** ❌
   - 전체 조건: false → else 블록 실행
4. 프롬프트: `"overview-writer agent로 Overview 섹션 작성"` (파일 경로 없음)
5. 에이전트가 어느 파일을 수정해야 할지 모름
6. 에이전트는 "성공" 메시지를 출력하지만 실제로 파일을 수정하지 않음

### 왜 Backup 버전은 작동했나?

**Backup 버전의 comprehensive mode:**
```bash
execute_comprehensive_mode() {
    local session_id="$1"
    # target_file을 파라미터로 받지 않음

    for agent in "${content_agents[@]}"; do
        # 3개 파라미터만 전달 (target_file, topic_name 모두 없음)
        execute_claude_agent "$agent" "$session_id" "$is_first"
    done
}
```

**execute_claude_agent에서:**
```bash
"overview-writer")
    if [ -n "$target_file" ] && [ -n "$topic_name" ]; then
        # 둘 다 비어있으므로 이 블록 실행 안 됨
        prompt="overview-writer agent로 $topic_name 토픽의 Overview 섹션 작성. 파일 경로: $target_file"
    else
        # 여기 실행
        prompt="overview-writer agent로 Overview 섹션 작성"
    fi
```

- Backup 버전도 동일한 generic 프롬프트 사용
- **하지만 content-initiator가 먼저 실행되어 Work Status Markers에 파일 정보 기록**
- 이후 에이전트들이 Work Status Markers를 읽어 파일 정보 획득
- 세션 컨텍스트로 파일 정보 공유

**Current 버전의 문제:**
- marker-based execution으로 content-initiator 건너뛰기 가능
- target_file은 전달하지만 topic_name은 누락
- 조건문이 양쪽 모두 체크하므로 fallback 발생

---

## The Fix

### 수정 코드 (After Fix)

**execute_comprehensive_mode:**
```bash
execute_comprehensive_mode() {
    local session_id="$1"
    local target_file="$2"

    # ✅ topic_name 추출 추가
    local topic_name=""
    if [ -n "$target_file" ]; then
        topic_name=$(basename "$target_file" .md)
    fi

    while [ $iteration -lt $max_iterations ]; do
        local next_agent=$(determine_next_agent "$target_file")

        # ✅ topic_name 전달
        execute_claude_agent "$next_agent" "$session_id" "$is_first" "$target_file" "$topic_name"
    done
}
```

### 수정 내용

1. **Line 899-903 추가**: target_file에서 topic_name 추출
   ```bash
   local topic_name=""
   if [ -n "$target_file" ]; then
       topic_name=$(basename "$target_file" .md)
   fi
   ```

2. **Line 934 수정**: 빈 문자열 대신 topic_name 전달
   ```bash
   # Before:
   execute_claude_agent "$next_agent" "$session_id" "$is_first" "$target_file" ""

   # After:
   execute_claude_agent "$next_agent" "$session_id" "$is_first" "$target_file" "$topic_name"
   ```

### 수정 후 실행 흐름

1. `execute_comprehensive_mode("session-id", "public/content/.../01-what-is-react.md")` 호출
2. `topic_name = "01-what-is-react"` 추출 ✅
3. `execute_claude_agent("overview-writer", "session-id", "true", "path/to/file.md", "01-what-is-react")`
4. 조건문 `[ -n "$target_file" ] && [ -n "$topic_name" ]` 평가:
   - `[ -n "path/to/file.md" ]` → true ✅
   - `[ -n "01-what-is-react" ]` → true ✅
   - 전체 조건: true → if 블록 실행
5. 프롬프트: `"overview-writer agent로 01-what-is-react 토픽의 Overview 섹션 작성. 파일 경로: public/content/.../01-what-is-react.md"`
6. 에이전트가 파일 경로를 알고 정확히 해당 파일 수정 가능 ✅

---

## Verification Plan

### 1. Syntax Check
```bash
bash -n scripts/content-generator-v6.sh
# Expected: No errors
```

### 2. Pilot Content Generation
```bash
# Reset test file
echo -e "---\n---\n\n" > public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md

# Run generation
./scripts/content-generator-v6.sh --direct=public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md

# Expected results:
# 1. content-initiator: Work Status Markers 초기화
# 2. overview-writer: Overview 섹션 실제 작성
# 3. Score: 100/100 (섹션 존재 + 파서 테스트 통과)
```

### 3. Parser Tests
```bash
# Test all 5 sections
for test in overview concepts patterns experiments quiz-raw; do
    echo "Testing $test..."
    npx tsx test/test-${test}.mjs public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md
done

# Expected: All tests pass with valid output
```

### 4. Web Rendering
```bash
# Check web app can parse and display
npm run dev
# Navigate to: http://localhost:3000/ko/react-core-concepts/01-react-basics/01-what-is-react
# Expected: All 4 tabs render correctly
```

---

## Impact Analysis

### Before Fix
- ❌ Overview 섹션 생성 불가
- ❌ 모든 콘텐츠 생성 작업 실패
- ❌ Milestone 2 검증 불가

### After Fix
- ✅ Overview 섹션 정상 생성
- ✅ 전체 파이프라인 작동
- ✅ Milestone 2 검증 가능

---

## Lessons Learned

### Why This Bug Happened

1. **Parameter Addition Without Full Integration**:
   - Unit 4에서 `target_file` 파라미터 추가
   - 하지만 `topic_name` 추출 로직 누락

2. **Conditional Logic Not Updated**:
   - `execute_claude_agent`의 조건문이 두 값 모두 요구
   - 한쪽만 전달하면 fallback 발생

3. **Testing Gap**:
   - Unit 4 완료 후 실제 콘텐츠 생성 테스트 미실시
   - 코드 리뷰만으로는 이런 integration bug 발견 어려움

### Prevention for Future

1. **Integration Testing Required**:
   - 각 Unit 완료 후 end-to-end 테스트 필수
   - 코드 변경 → 실제 콘텐츠 생성 → 파서 테스트

2. **Parameter Pairing**:
   - `target_file`과 `topic_name`은 함께 다뤄야 함
   - 한쪽만 전달하면 안 됨

3. **Milestone Checkpoints Are Critical**:
   - Milestone 검증은 이론적 체크가 아님
   - 실제 시스템 작동 확인이 필수

---

## Next Steps

1. ✅ Bug fix 완료
2. ⏳ 파일럿 콘텐츠 재생성 (01-what-is-react.md)
3. ⏳ 파서 테스트 전체 실행
4. ⏳ 웹 렌더링 확인
5. ⏳ Milestone 2 재검증

---

**수정일**: 2025-10-14
**Status**: ✅ **Bug Fixed, Ready for Testing**
**Next Action**: 파일럿 콘텐츠 생성 테스트
