# content-generator-v7 사용 가이드

## 목차

1. [개요](#1-개요)
2. [설치 및 요구사항](#2-설치-및-요구사항)
3. [기본 사용법](#3-기본-사용법)
4. [실행 모드](#4-실행-모드)
5. [고급 옵션](#5-고급-옵션)
6. [사용 예시](#6-사용-예시)
7. [오류 처리](#7-오류-처리)
8. [FAQ](#8-faq)

---

## 1. 개요

**content-generator-v7**는 AI 기반 학습 콘텐츠 자동 생성 오케스트레이션 스크립트입니다.

**주요 기능**:
- ✅ 7개 에이전트 자동 실행 (content-initiator → content-validator)
- ✅ Work Status Markers 기반 재시작 메커니즘
- ✅ Precondition/Postcondition 자동 검증
- ✅ 4가지 실행 모드 (Direct, Auto, Interactive, Validate-Only)
- ✅ execution-summary.json 자동 생성 (Unit 5 품질 분석용)

**v6 대비 개선사항**:
- 5단계 재시작 메커니즘 (v6는 3단계)
- 에이전트별 계약 검증 통합
- 구조화된 오류 처리 (6가지 오류 타입)
- execution-summary.json 자동 생성

---

## 2. 설치 및 요구사항

### 2.1 필수 요구사항

**Shell 환경**:
- bash 4.0 이상
- macOS 또는 Linux

**Claude CLI**:
```bash
# Claude CLI 설치 확인
which claude

# 없으면 설치 필요
# (설치 방법은 Claude 공식 문서 참조)
```

**환경 변수**:
```bash
# PROJECT_ROOT 설정 (자동으로 5단계 위로 설정됨)
# 수동 설정 시:
export PROJECT_ROOT="/path/to/frontend-learning-webview"
```

### 2.2 선택적 요구사항

**Python** (선택적 - duration 계산용):
```bash
python3 --version
# 없어도 동작하지만 total_duration=0으로 설정됨
```

---

## 3. 기본 사용법

### 3.1 도움말 보기

```bash
./src/content-generator-v7.sh --help
```

### 3.2 가장 간단한 실행

```bash
# 특정 파일 직접 지정
./src/content-generator-v7.sh --direct=public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md
```

### 3.3 주요 옵션

| 옵션 | 설명 | 예시 |
|------|------|------|
| `--direct=FILE` | 특정 파일 지정 | `--direct=path/to/file.md` |
| `-a, --auto` | 자동 모드 (category.yaml 기반) | `-a --category=react --subcategory=basics` |
| `-i, --interactive` | 대화형 모드 (3단계 선택) | `-i` |
| `--validate-only` | 검증만 수행 (실행 X) | `--validate-only --direct=file.md` |

---

## 4. 실행 모드

### 4.1 Direct Mode (직접 지정)

**용도**: 특정 파일을 직접 지정하여 실행

**사용법**:
```bash
./src/content-generator-v7.sh --direct=public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md
```

**동작**:
1. 파일 경로 검증
2. Work Status Markers 파싱
3. 재시작 지점 자동 식별 (Priority 1-5)
4. 파이프라인 실행

---

### 4.2 Auto Mode (자동 선택)

**용도**: category.yaml 기반으로 불완전 파일 자동 선택

**사용법**:
```bash
./src/content-generator-v7.sh -a --category=react-core-concepts --subcategory=01-react-basics
```

**동작**:
1. category.yaml에서 토픽 목록 추출
2. 각 토픽 파일 상태 확인:
   - 파일 미존재
   - `CURRENT_AGENT:` 필드 존재
   - `[COMPLETE]` 마커 누락
3. 첫 불완전 파일 자동 선택
4. 파이프라인 실행

**종료 조건**:
- 모든 파일 `[COMPLETE]` 상태 시 종료

---

### 4.3 Interactive Mode (대화형 선택)

**용도**: 사용자가 3단계로 카테고리/서브카테고리/토픽 선택

**사용법**:
```bash
./src/content-generator-v7.sh -i
```

**동작**:
1. **Step 1**: 카테고리 목록 표시 + 선택
2. **Step 2**: 서브카테고리 목록 표시 + 선택
3. **Step 3**: 토픽 목록 + 상태 표시 (✅/⏸️/⏳/❌) + 선택
4. 파이프라인 실행

**상태 아이콘**:
- ✅ `[COMPLETE]`: 완료
- ⏸️ `CURRENT_AGENT:` 존재: 진행 중
- ⏳ `[COMPLETE]` 누락: 미완성
- ❌ 파일 미존재: 생성 필요

---

### 4.4 Validate-Only Mode (검증 전용)

**용도**: Work Status Markers 및 계약 검증만 수행 (에이전트 실행 X)

**사용법**:
```bash
./src/content-generator-v7.sh --validate-only --direct=public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md
```

**동작**:
1. Work Status Markers 파싱
2. 재시작 지점 식별
3. Precondition/Postcondition 검증
4. 검증 결과 출력 (에이전트 실행 안 함)

---

## 5. 고급 옵션

### 5.1 재시작 옵션

#### --resume (자동 재시작)

**용도**: 중단된 작업을 자동으로 재시작

**사용법**:
```bash
./src/content-generator-v7.sh --direct=file.md --resume
```

**동작**:
- Priority 1-5 알고리즘으로 재시작 지점 자동 식별
- 식별된 에이전트부터 실행

#### --from=AGENT (특정 에이전트부터)

**용도**: 특정 에이전트부터 강제 실행

**사용법**:
```bash
./src/content-generator-v7.sh --direct=file.md --from=concepts-writer
```

**에이전트 이름**:
- `content-initiator`
- `overview-writer`
- `concepts-writer`
- `visualization-writer`
- `practice-writer`
- `quiz-writer`
- `content-validator`

**주의**: --resume과 --from은 동시 사용 불가

---

### 5.2 검증 옵션

#### --skip-validation (검증 건너뛰기)

**용도**: 빠른 실행 (Precondition/Postcondition 검증 안 함)

**사용법**:
```bash
./src/content-generator-v7.sh --direct=file.md --skip-validation
```

**위험성**: 계약 위반 가능 (프로덕션 사용 비권장)

---

### 5.3 디버깅 옵션

#### --debug (디버그 모드)

**용도**: 상세 디버그 로그 출력

**사용법**:
```bash
./src/content-generator-v7.sh --direct=file.md --debug
```

**출력**: `log_debug()` 메시지 모두 표시

#### --verbose (상세 모드)

**용도**: 설정 정보 상세 표시

**사용법**:
```bash
./src/content-generator-v7.sh --direct=file.md --verbose
```

---

### 5.4 강제 실행 옵션

#### --force (강제 모드)

**용도**: Lock 무시 + COMPLETE 상태 무시

**사용법**:
```bash
./src/content-generator-v7.sh --direct=file.md --force
```

**동작**:
1. 기존 Lock 파일 강제 제거
2. `[COMPLETE]` 마커 무시하고 재실행

**위험성**: 동시 실행 시 파일 손상 가능 (신중히 사용)

---

### 5.5 테스트 옵션

#### --test (테스트 모드)

**용도**: Claude CLI 실제 실행 없이 흐름만 테스트

**사용법**:
```bash
./src/content-generator-v7.sh --direct=file.md --test
```

**동작**:
- Lock 획득/해제 스킵
- 에이전트 실제 실행 스킵
- Postcondition 검증 실패 (의도됨)

---

## 6. 사용 예시

### 예시 1: 새 토픽 생성

```bash
# Interactive Mode로 토픽 선택
./src/content-generator-v7.sh -i

# 출력:
# Available categories:
# ==================
#   1) react-core-concepts
#   2) javascript-fundamentals
# Select category (1-2 or 'q' to quit): 1
#
# Available subcategories:
# ====================
#   1) 01-react-basics
#   2) 02-hooks
# Select subcategory (1-2 or 'q' to quit): 1
#
# Available topics (with status):
# ========================
#   1) 01-what-is-react.md ✅ [COMPLETE]
#   2) 02-virtual-dom.md ❌ (not found)
# Select topic (1-2 or 'q' to quit): 2
#
# ℹ️  Starting content generation session: a1b2c3d4-...
# ✅ Lock acquired for 02-virtual-dom.md
# ℹ️  Executing agent: content-initiator
# ...
```

---

### 예시 2: 중단된 작업 재시작

```bash
# 자동 재시작 지점 식별
./src/content-generator-v7.sh --direct=public/content/ko/react-core-concepts/01-react-basics/02-virtual-dom.md --resume

# 출력:
# ℹ️  Restart point detected: RESUME from concepts-writer
# ℹ️  Executing agent: concepts-writer
# ...
```

---

### 예시 3: 특정 에이전트부터 강제 실행

```bash
# visualization-writer부터 재실행
./src/content-generator-v7.sh --direct=public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md --from=visualization-writer

# 출력:
# ℹ️  Starting from agent: visualization-writer
# ℹ️  Executing agent: visualization-writer
# ...
```

---

### 예시 4: Auto Mode로 불완전 파일 자동 처리

```bash
# category.yaml 기반 자동 선택
./src/content-generator-v7.sh -a --category=react-core-concepts --subcategory=01-react-basics

# 출력:
# ℹ️  Auto mode: searching for incomplete files...
# ℹ️  Found incomplete file: 03-jsx-basics.md (CURRENT_AGENT: concepts-writer)
# ℹ️  Restart point detected: RESUME from concepts-writer
# ...
```

---

### 예시 5: 검증만 수행 (실행 안 함)

```bash
# Work Status Markers 및 계약 검증
./src/content-generator-v7.sh --validate-only --direct=public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md

# 출력:
# ℹ️  Validation-only mode
# ℹ️  Parsing Work Status Markers...
# ✅ PC-1: CURRENT_AGENT matches expected
# ✅ PC-2: Required fields present
# ✅ PO-1: Output sections present
# ℹ️  Validation complete
```

---

## 7. 오류 처리

### 7.1 오류 타입

| 오류 타입 | 설명 | 복구 방법 |
|-----------|------|----------|
| `PRECONDITION_FAILED` | Precondition 검증 실패 | Work Status Markers 확인, --from 옵션 사용 |
| `POSTCONDITION_FAILED` | Postcondition 검증 실패 | 프롬프트 수정, --from 옵션으로 재실행 |
| `EXECUTION_FAILED` | 에이전트 실행 실패 | --resume 또는 --debug로 원인 파악 |
| `PARSING_ERROR` | Work Status Markers 파싱 오류 | 파일 인코딩 확인 (UTF-8), 백업 복원 |
| `LOCK_CONFLICT` | Lock 충돌 | 대기 또는 --force 사용 (위험) |
| `TIMEOUT` | 타임아웃 | 프롬프트 수정, 타임아웃 증가 |

---

### 7.2 오류 발생 시 출력 예시

```bash
❌ Precondition validation failed for concepts-writer
   PC-1: CURRENT_AGENT is 'overview-writer', expected 'concepts-writer'

💡 Suggestion: Precondition validation failed
   Diagnosis:
     - Work Status Markers may be out of sync
     - Previous agent may not have completed successfully

   Recovery options:
     1. Check Work Status Markers:
        grep -A 20 'WORK STATUS MARKERS' file.md
     2. Resume from correct agent:
        ./content-generator-v7.sh --direct=file.md --from=concepts-writer
     3. Skip validation (not recommended):
        ./content-generator-v7.sh --direct=file.md --skip-validation
```

---

### 7.3 execution-summary.json 확인

```bash
# 세션별 실행 결과 확인
cat logs/sessions/{session-id}/execution-summary.json

# Pretty print
python3 -m json.tool logs/sessions/{session-id}/execution-summary.json
```

**출력 예시**:
```json
{
  "session_id": "a1b2c3d4-...",
  "started_at": "2025-10-18 10:00:00",
  "completed_at": "2025-10-18 10:15:00",
  "total_duration": 900,
  "file_path": "public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md",
  "agents": [
    {
      "name": "content-initiator",
      "completed_at": "2025-10-18 10:02:00",
      "status": "SUCCESS",
      "exit_code": 0,
      "duration": 120
    }
  ],
  "errors": [],
  "final_validation_score": 95
}
```

---

## 8. FAQ

### Q1: v6와 v7 중 어떤 것을 사용해야 하나요?

**A**: v7을 권장합니다.
- v7은 5단계 재시작 메커니즘, 계약 검증, 구조화된 오류 처리 제공
- v6는 호환성 유지를 위해 보존됨 (백업용)
- Breaking Changes 없음 (v6 → v7 안전하게 전환 가능)

---

### Q2: Lock 파일이 남아있어 실행이 안 됩니다

**A**: Stale lock 제거 방법
```bash
# 자동 제거 (PID 확인 후)
./src/content-generator-v7.sh --direct=file.md

# 수동 제거
rm -f .locks/file-name.lock

# 강제 실행 (위험 - 동시 실행 시 파일 손상 가능)
./src/content-generator-v7.sh --direct=file.md --force
```

---

### Q3: [COMPLETE] 상태인데 다시 실행하고 싶습니다

**A**: --force 옵션 사용
```bash
./src/content-generator-v7.sh --direct=file.md --force
```

**주의**: 기존 콘텐츠가 덮어씌워질 수 있음 (백업 권장)

---

### Q4: execution-summary.json의 total_duration이 0입니다

**A**: Python 미설치 또는 날짜 형식 오류
```bash
# Python 설치 확인
python3 --version

# 없으면 설치 (macOS)
brew install python3
```

**대안**: duration 필드는 선택적이므로 무시해도 됨

---

### Q5: 특정 에이전트만 건너뛰고 싶습니다

**A**: 현재 지원 안 함
- v6의 `--skip-*` 옵션은 v7에서 제거됨
- 대안: --from 옵션으로 건너뛴 에이전트 다음부터 실행

---

### Q6: 여러 토픽을 동시에 실행할 수 있나요?

**A**: 가능 (토픽별 독립 Lock 파일)
```bash
# Terminal 1
./src/content-generator-v7.sh --direct=public/content/ko/topic1.md &

# Terminal 2
./src/content-generator-v7.sh --direct=public/content/ko/topic2.md &
```

**주의**: 동일 파일은 Lock으로 보호됨 (충돌 방지)

---

### Q7: 디버그 로그가 너무 많습니다

**A**: --debug 없이 실행
```bash
# 기본 로그만 표시
./src/content-generator-v7.sh --direct=file.md
```

**로그 파일 위치**:
- 전체 로그: `logs/content-generator-v7.log`
- 에이전트별 로그: `logs/sessions/{session-id}/{agent-name}.log`

---

### Q8: macOS에서만 작동하나요?

**A**: macOS와 Linux 모두 지원
- `get_timestamp()`, `ps -p $PID`, sed/awk/grep 모두 호환
- 일부 명령 (예: `date`) macOS 구문 우선, Linux fallback

---

## 9. 로그 및 산출물

### 9.1 로그 디렉터리 구조

```
logs/
├── content-generator-v7.log          # 전체 실행 로그
└── sessions/
    └── {session-id}/
        ├── content-initiator.log     # 에이전트별 로그
        ├── overview-writer.log
        ├── concepts-writer.log
        ├── visualization-writer.log
        ├── practice-writer.log
        ├── quiz-writer.log
        ├── content-validator.log
        └── execution-summary.json    # 실행 요약 (Unit 5용)
```

---

### 9.2 Lock 파일

**위치**: `.locks/{file-name}.lock`

**형식**: `PID:timestamp:username:agent_name`

**예시**: `12345:2025-10-18 10:00:00:user:concepts-writer`

---

## 10. 추가 리소스

**AI-DLC 방법론 문서**:
- `domain_design.md` - 도메인 모델 설계
- `logical_design.md` - 논리적 설계
- `implementation.md` - 구현 결정사항

**Unit 의존성**:
- Unit 1: Work Status Markers 명세
- Unit 2: 에이전트 계약 명세
- Unit 3: 개선된 프롬프트

**문의**:
- GitHub Issues: (프로젝트 저장소)
- 문서 위치: `docs/aidlc-docs/construction/unit-04-orchestration/`

---

**버전**: v7.0
**마지막 업데이트**: 2025-10-18
