# v6 → v7 마이그레이션 가이드

## 목차

1. [마이그레이션 개요](#1-마이그레이션-개요)
2. [Breaking Changes](#2-breaking-changes)
3. [주요 변경사항](#3-주요-변경사항)
4. [옵션 매핑](#4-옵션-매핑)
5. [마이그레이션 절차](#5-마이그레이션-절차)
6. [롤백 계획](#6-롤백-계획)

---

## 1. 마이그레이션 개요

### 1.1 마이그레이션 필요성

**v7의 주요 개선사항**:
- ✅ 5단계 재시작 메커니즘 (v6는 3단계)
- ✅ 에이전트별 계약 검증 통합 (Precondition/Postcondition)
- ✅ 구조화된 오류 처리 (6가지 오류 타입 + 복구 제안)
- ✅ execution-summary.json 자동 생성 (Unit 5 품질 분석용)
- ✅ 모듈화된 구조 (common-utils.sh 분리)

### 1.2 마이그레이션 안전성

**Breaking Changes**: ⭐ **없음**

- v6 파일 그대로 보존 (`content-generator-v6.sh`)
- v7 신규 생성 (`content-generator-v7.sh`)
- `claude -p` 실행 방식 100% 보존
- 최종 출력 형식 동일 (Work Status Markers + 5 Sections)

**마이그레이션 위험도**: ⭐⭐☆☆☆ (5단계 중 2 - 낮음)

---

## 2. Breaking Changes

### 2.1 명령줄 옵션 변경

**⭐ Breaking Changes 없음**

모든 v6 옵션이 v7에서 그대로 작동합니다.

---

### 2.2 환경 변수 변경

**⭐ Breaking Changes 없음**

모든 v6 환경 변수가 v7에서 그대로 작동합니다.

---

### 2.3 출력 형식 변경

**⭐ Breaking Changes 없음**

- Work Status Markers 형식 동일
- 5개 섹션 (Overview, Core Concepts, Code Patterns, Experiments, Quiz) 동일
- HANDOFF LOG 이벤트 타입 동일 (START, DONE, IMPROVE, FAILURE, SKIP, COMPLETE)

---

## 3. 주요 변경사항

### 3.1 재시작 메커니즘 (3단계 → 5단계)

**v6 (3단계)**:
1. HANDOFF LOG 마지막 [FAILURE] 확인
2. 마지막 [DONE] 또는 [IMPROVE] 다음 에이전트
3. [COMPLETE] 확인

**v7 (5단계)**:
1. **Priority 1**: `IMPROVEMENT_NEEDED:` 필드 확인 → IMPROVEMENT 모드
2. **Priority 2**: `CURRENT_AGENT:` 필드 확인 → RESUME 모드
3. **Priority 3**: HANDOFF LOG 마지막 `[FAILURE]` → RETRY 모드
4. **Priority 4**: `[COMPLETE]` 마커 확인 → COMPLETE 상태
5. **Priority 5**: 마지막 `[DONE]`/`[IMPROVE]` → RESUME 모드

**마이그레이션 영향**: ⭐ 없음 (자동으로 더 정확한 재시작 지점 식별)

---

### 3.2 계약 검증 추가

**v6**: 검증 없음 (에이전트가 자율적으로 Work Status Markers 조작)

**v7**: Precondition/Postcondition 자동 검증
- Precondition 실패 시 에이전트 실행 중단
- Postcondition 실패 시 에이전트 출력 롤백

**마이그레이션 옵션**:
- 기본: 검증 활성화 (권장)
- 빠른 실행: `--skip-validation` 사용 (비권장)

---

### 3.3 오류 처리 개선

**v6**: HANDOFF LOG에 `[FAILURE]` 기록만

**v7**: 구조화된 오류 처리
- 6가지 오류 타입 분류
- 복구 제안 자동 생성 (Diagnosis + Recovery Options)
- execution-summary.json에 오류 정보 기록

**마이그레이션 영향**: ⭐ 긍정적 (더 명확한 오류 메시지)

---

### 3.4 로깅 개선

**v6**:
- 전체 로그: `logs/content-generator-v6.log`
- 에이전트별 로그 없음

**v7**:
- 전체 로그: `logs/content-generator-v7.log`
- 세션별 디렉터리: `logs/sessions/{session-id}/`
  - 에이전트별 로그: `{agent-name}.log`
  - 실행 요약: `execution-summary.json`

**마이그레이션 영향**: ⭐ 긍정적 (더 상세한 로깅, Unit 5 품질 분석 가능)

---

## 4. 옵션 매핑

### 4.1 실행 모드 옵션

| v6 옵션 | v7 옵션 | 변경 사항 |
|---------|---------|----------|
| `-a, --auto` | `-a, --auto` | ⭐ 동일 |
| `-i, --interactive` | `-i, --interactive` | ⭐ 동일 |
| `--direct=FILE` | `--direct=FILE` | ⭐ 동일 |
| ❌ 없음 | `--validate-only` | ✨ 신규 (검증만 수행) |

---

### 4.2 재시작 옵션

| v6 옵션 | v7 옵션 | 변경 사항 |
|---------|---------|----------|
| `--restart` | `--resume` | 📝 이름 변경 (기능 개선) |
| ❌ 없음 | `--from=AGENT` | ✨ 신규 (특정 에이전트부터) |

**마이그레이션**:
```bash
# v6
./content-generator-v6.sh --direct=file.md --restart

# v7 (권장)
./content-generator-v7.sh --direct=file.md --resume
```

---

### 4.3 검증 옵션

| v6 옵션 | v7 옵션 | 변경 사항 |
|---------|---------|----------|
| `--validation=MODE` | `--skip-validation` | 📝 간소화 |

**v6 검증 모드**:
- `--validation=immediate` (섹션별 검증)
- `--validation=comprehensive` (마커 기반)
- `--validation=hybrid` (둘 다)

**v7 검증**:
- 기본: 검증 활성화 (Precondition + Postcondition)
- `--skip-validation`: 검증 건너뛰기

**마이그레이션**:
```bash
# v6 (검증 없이 실행)
./content-generator-v6.sh --direct=file.md --validation=immediate

# v7 (권장: 기본 검증)
./content-generator-v7.sh --direct=file.md

# v7 (빠른 실행)
./content-generator-v7.sh --direct=file.md --skip-validation
```

---

### 4.4 에이전트 Skip 옵션

| v6 옵션 | v7 옵션 | 변경 사항 |
|---------|---------|----------|
| `--skip-overview` | ❌ 제거됨 | 🚫 v7에서 미지원 |
| `--skip-concepts` | ❌ 제거됨 | 🚫 v7에서 미지원 |
| ... | ... | ... |

**이유**: 계약 검증으로 인해 섹션별 Skip 불가

**대안**:
```bash
# v6
./content-generator-v6.sh --direct=file.md --skip-overview

# v7 (대안: --from 사용)
./content-generator-v7.sh --direct=file.md --from=concepts-writer
```

---

### 4.5 디버깅 옵션

| v6 옵션 | v7 옵션 | 변경 사항 |
|---------|---------|----------|
| `--debug` | `--debug` | ⭐ 동일 |
| ❌ 없음 | `--verbose` | ✨ 신규 (상세 정보 표시) |
| `--test` | `--test` | ⭐ 동일 |

---

### 4.6 강제 실행 옵션

| v6 옵션 | v7 옵션 | 변경 사항 |
|---------|---------|----------|
| `--force` | `--force` | ⭐ 동일 (Lock 무시) |
| ❌ 없음 | `--force` | ✨ 확장 (COMPLETE 상태도 무시) |

**v7 --force 동작**:
1. 기존 Lock 파일 강제 제거
2. `[COMPLETE]` 마커 무시하고 재실행

---

### 4.7 카테고리 옵션

| v6 옵션 | v7 옵션 | 변경 사항 |
|---------|---------|----------|
| `--category=NAME` | `--category=NAME` | ⭐ 동일 |
| `--subcategory=NAME` | `--subcategory=NAME` | ⭐ 동일 |

---

## 5. 마이그레이션 절차

### 5.1 사전 준비

#### Step 1: v6 백업 확인

```bash
# v6 파일 존재 확인
ls -la scripts/content-generator-v6.sh

# 출력:
# -rwxr-xr-x  1 user  staff  66789 Oct 14 10:00 content-generator-v6.sh
```

#### Step 2: v7 파일 복사

```bash
# src/ → scripts/ 복사
cp src/content-generator-v7.sh scripts/
cp src/lib/common-utils.sh scripts/lib/

# 실행 권한 설정
chmod +x scripts/content-generator-v7.sh
chmod +x scripts/lib/common-utils.sh
```

#### Step 3: 환경 변수 확인

```bash
# PROJECT_ROOT 확인
echo $PROJECT_ROOT

# 없으면 설정
export PROJECT_ROOT="/path/to/frontend-learning-webview"
```

---

### 5.2 점진적 마이그레이션 (권장)

#### Phase 1: 병행 실행 (1주일)

```bash
# v6 계속 사용 (프로덕션)
./scripts/content-generator-v6.sh --direct=file.md

# v7 테스트 실행 (스테이징)
./scripts/content-generator-v7.sh --direct=file.md --test
```

#### Phase 2: 제한적 v7 사용 (2주일)

```bash
# 새 토픽만 v7 사용
./scripts/content-generator-v7.sh --direct=new-topic.md

# 기존 토픽은 v6 사용
./scripts/content-generator-v6.sh --direct=existing-topic.md
```

#### Phase 3: 전체 v7 전환 (1개월 후)

```bash
# 모든 토픽에 v7 사용
./scripts/content-generator-v7.sh --direct=file.md
```

---

### 5.3 일괄 마이그레이션 (빠른 전환)

#### Step 1: v7 검증

```bash
# 샘플 파일로 v7 테스트
./scripts/content-generator-v7.sh --direct=public/content/ko/react-core-concepts/01-react-basics/01-what-is-react.md --validate-only

# 출력 확인:
# ℹ️  Validation-only mode
# ✅ PC-1: ...
# ✅ PO-1: ...
```

#### Step 2: v6 → v7 전환

```bash
# 모든 스크립트에서 v6 → v7 변경
sed -i '' 's/content-generator-v6/content-generator-v7/g' scripts/*.sh
```

#### Step 3: 전체 테스트

```bash
# Auto Mode로 전체 카테고리 테스트
./scripts/content-generator-v7.sh -a --category=react-core-concepts --subcategory=01-react-basics
```

---

## 6. 롤백 계획

### 6.1 v7 문제 발생 시 롤백 절차

#### Step 1: v6로 즉시 롤백

```bash
# v7 실행 중단
pkill -f content-generator-v7

# Lock 파일 제거
rm -f .locks/*.lock

# v6 재실행
./scripts/content-generator-v6.sh --direct=file.md --restart
```

#### Step 2: v7 파일 격리

```bash
# v7 파일 이동 (삭제 X)
mv scripts/content-generator-v7.sh scripts/content-generator-v7.sh.backup
mv scripts/lib/common-utils.sh scripts/lib/common-utils.sh.backup
```

#### Step 3: 로그 분석

```bash
# v7 오류 로그 확인
tail -100 logs/content-generator-v7.log

# execution-summary.json 확인
ls -la logs/sessions/*/execution-summary.json
```

---

### 6.2 롤백 시나리오별 대응

#### 시나리오 1: PARSING_ERROR 빈발

**원인**: Work Status Markers 파싱 오류

**롤백 조치**:
```bash
# v6로 즉시 롤백
./scripts/content-generator-v6.sh --direct=file.md --restart

# v7 버그 리포트
# (파일 인코딩, Work Status Markers 형식 확인)
```

---

#### 시나리오 2: Precondition 검증 실패

**원인**: 계약 검증이 너무 엄격

**롤백 조치**:
```bash
# 임시: --skip-validation 사용
./scripts/content-generator-v7.sh --direct=file.md --skip-validation

# 또는 v6 롤백
./scripts/content-generator-v6.sh --direct=file.md
```

---

#### 시나리오 3: Lock 충돌

**원인**: Lock 메커니즘 버그

**롤백 조치**:
```bash
# Stale lock 제거
rm -f .locks/*.lock

# v6 재실행
./scripts/content-generator-v6.sh --direct=file.md
```

---

## 7. 회귀 테스트

### 7.1 동일 입력/출력 검증

```bash
# v6 실행
./scripts/content-generator-v6.sh --direct=test-file.md
cp test-file.md test-file-v6.md

# v7 실행 (같은 파일)
./scripts/content-generator-v7.sh --direct=test-file.md --force
cp test-file.md test-file-v7.md

# 차이점 확인
diff test-file-v6.md test-file-v7.md

# 출력:
# (Work Status Markers 외에는 동일해야 함)
```

---

### 7.2 성능 비교

```bash
# v6 실행 시간 측정
time ./scripts/content-generator-v6.sh --direct=file.md

# v7 실행 시간 측정
time ./scripts/content-generator-v7.sh --direct=file.md

# execution-summary.json에서 확인
jq '.total_duration' logs/sessions/*/execution-summary.json
```

---

## 8. FAQ

### Q1: v6를 삭제해도 되나요?

**A**: 아니요, v6 보존 권장
- v7에 문제 발생 시 롤백용
- 기존 스크립트와의 호환성 유지
- 디스크 공간 66KB (무시 가능)

---

### Q2: v6와 v7을 동시에 사용할 수 있나요?

**A**: 가능 (토픽별 다른 버전 사용 가능)
```bash
# 토픽 1: v6 사용
./scripts/content-generator-v6.sh --direct=topic1.md &

# 토픽 2: v7 사용
./scripts/content-generator-v7.sh --direct=topic2.md &
```

**주의**: 동일 파일은 Lock으로 보호됨 (충돌 방지)

---

### Q3: 마이그레이션 시 다운타임이 있나요?

**A**: 없음
- v6 파일 보존 (백업)
- v7 신규 파일 추가
- 점진적 전환 가능

---

### Q4: v7 사용 시 성능 차이가 있나요?

**A**: 약간 느림 (검증 오버헤드)
- Precondition 검증: ~1초
- Postcondition 검증: ~2초
- execution-summary.json 생성: ~0.5초
- **총 오버헤드**: ~3.5초 (전체 실행 시간 대비 무시 가능)

**대안**: `--skip-validation` 사용 (비권장)

---

### Q5: execution-summary.json이 필요 없으면 어떻게 하나요?

**A**: 그대로 생성됨 (Unit 5 품질 분석용)
- 삭제해도 됨 (선택적)
- 디스크 공간 ~1KB (무시 가능)

---

## 9. 추가 리소스

**문서**:
- `USAGE.md` - v7 사용 가이드
- `implementation.md` - 구현 결정사항
- `logical_design.md` - 논리적 설계

**테스트**:
- `test-common-utils.sh` - 단위 테스트
- `test-final-all.sh` - execution-summary.json 테스트

**문의**:
- GitHub Issues: (프로젝트 저장소)
- 문서 위치: `docs/aidlc-docs/construction/unit-04-orchestration/`

---

**버전**: v6 → v7 마이그레이션 가이드 v1.0
**마지막 업데이트**: 2025-10-18
