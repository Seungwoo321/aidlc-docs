# content-initiator Contract

**Version**: 1.0.0
**Created**: 2025-10-13
**Status**: Draft

---

## 1. 개요

### Filter 이름
`content-initiator`

### 역할 및 책임
파이프라인의 첫 번째 Filter로서, 콘텐츠 생성 프로세스를 시작하는 역할을 합니다. 빈 마크다운 파일에 Work Status Markers를 초기화하고, 다음 Filter (overview-writer)에게 작업을 핸드오프합니다.

**핵심 책임**:
- Work Status Markers 초기화
- overview-writer로의 핸드오프
- **콘텐츠 작성 금지** (마커만 추가)

### Pipeline에서의 위치
```
category.yaml → [content-initiator] → overview-writer → ...
```

- **선행 Filter**: 없음 (첫 번째)
- **후행 Filter**: overview-writer

---

## 2. 입력 계약 (Input Contract)

### 필수 입력 데이터

#### 2.1 파일 경로
- **형식**: `public/content/ko/{category}/{subcategory}/{topic-id}-{topic-name}.md`
- **예시**: `public/content/ko/javascript-core-concepts/01-variables/01-var-problems.md`
- **조건**: 파일이 이미 존재해야 함 (오케스트레이션 스크립트가 사전 생성)

#### 2.2 파일 내용
**최소 구조**:
```markdown
---
---

```

- **Frontmatter**: 빈 frontmatter (`---\n---\n`) 필수
- **본문**: 비어 있음
- **Work Status Markers**: 없음 (이 Filter가 추가)

### 선행 조건 (Preconditions)
1. 파일이 존재함
2. Frontmatter만 있고 Work Status Markers 없음
3. 락 파일 관리는 오케스트레이션 스크립트가 담당

---

## 3. 출력 계약 (Output Contract)

### 생성할 산출물

#### 3.1 Work Status Markers 추가

**위치**: Frontmatter 바로 다음 (line 3~)

**필수 마커**:
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: overview-writer -->
<!-- PROGRESS: pending -->
<!-- STARTED: YYYY-MM-DD HH:MM -->
<!-- UPDATED: YYYY-MM-DD HH:MM -->
<!-- HANDOFF LOG:
[DONE] content-initiator: 완료 - initialization
-->
```

#### 3.2 출력 파일 구조
```markdown
---
---

<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: overview-writer -->
<!-- PROGRESS: pending -->
<!-- STARTED: 2025-10-13 14:30 -->
<!-- UPDATED: 2025-10-13 14:30 -->
<!-- HANDOFF LOG:
[DONE] content-initiator: 완료 - initialization
-->

```

- **Frontmatter**: 변경 없음
- **Work Status Markers**: 추가됨
- **본문**: 여전히 비어 있음 (콘텐츠 작성 금지)

### 출력 형식

#### 마커 형식 규칙
1. **CURRENT_AGENT**: `overview-writer` (다음 Filter)
2. **PROGRESS**: `pending` (대기 상태)
3. **STARTED**: ISO 8601 형식 (YYYY-MM-DD HH:MM)
4. **UPDATED**: STARTED와 동일한 타임스탬프
5. **HANDOFF LOG**: `[DONE] content-initiator: 완료 - initialization` 정확히 이 형식

### 후행 조건 (Postconditions)
1. Work Status Markers가 파일 상단에 존재
2. `CURRENT_AGENT`가 `overview-writer`로 설정
3. 본문은 여전히 비어 있음
4. 다음 Filter가 즉시 실행 가능한 상태

---

## 4. 품질 기준 (Quality Criteria)

### 구조적 요구사항

#### 4.1 마커 위치
- ✅ Frontmatter 바로 다음 (line 3)
- ✅ 빈 줄 없이 연속으로 작성
- ❌ 파일 중간이나 끝에 위치

#### 4.2 마커 완전성
- ✅ 5개 필수 마커 모두 존재 (CURRENT_AGENT, PROGRESS, STARTED, UPDATED, HANDOFF LOG)
- ✅ HANDOFF LOG에 START 항목 존재
- ❌ 마커 누락

#### 4.3 마커 형식
- ✅ HTML 주석 형식 (`<!-- ... -->`)
- ✅ 대문자 키워드 사용
- ✅ 콜론 후 공백 (예: `CURRENT_AGENT: `)

### 내용적 요구사항

#### 4.4 핸드오프 정확성
- ✅ `CURRENT_AGENT`가 정확히 `overview-writer` (오타 없음)
- ✅ `PROGRESS`가 `pending`
- ❌ 다른 agent 이름
- ❌ 다른 progress 상태

#### 4.5 타임스탬프 유효성
- ✅ STARTED와 UPDATED가 유효한 날짜/시간 형식
- ✅ 두 타임스탬프가 동일 (첫 초기화)
- ❌ 미래 날짜
- ❌ 형식 오류

### 금지 사항

#### 4.6 콘텐츠 작성 금지
- ❌ Overview 작성
- ❌ Core Concepts 작성
- ❌ Code Patterns 작성
- ❌ Experiments 작성
- ❌ Quiz 작성
- ❌ Frontmatter 수정
- ❌ 기타 모든 콘텐츠

### 검증 체크리스트
- [ ] Work Status Markers가 line 3에서 시작
- [ ] 5개 필수 마커 모두 존재
- [ ] CURRENT_AGENT가 `overview-writer`
- [ ] PROGRESS가 `pending`
- [ ] 타임스탬프가 유효한 형식
- [ ] HANDOFF LOG에 START 항목 존재
- [ ] 본문이 비어 있음 (콘텐츠 작성 안 함)

---

## 5. 오류 처리 (Error Handling)

### 오류 유형

#### 5.1 입력 오류
**오류**: 파일이 존재하지 않음
- **대응**: 오류 메시지 출력, 종료
- **메시지 형식**: `Error: File not found: {file_path}`

**오류**: Frontmatter 없음
- **대응**: 오류 메시지 출력, 종료
- **메시지 형식**: `Error: Invalid file format - frontmatter missing`

**오류**: Work Status Markers가 이미 존재
- **대응**:
  - `CURRENT_AGENT`가 `content-initiator`이면 `overview-writer`로 변경
  - 그 외에는 아무 작업 안 함 (이미 처리됨)

#### 5.2 생성 오류
**오류**: 마커 작성 실패
- **대응**: 오류 메시지 출력, 재시도 (최대 1회)
- **재시도 조건**: 일시적 파일 I/O 오류

#### 5.3 검증 오류
**오류**: 생성한 마커가 형식에 맞지 않음
- **대응**: 경고 메시지 출력, 수정 후 재작성
- **검증 항목**: 5개 필수 마커 존재 여부

### 재시도 전략
- **재시도 횟수**: 최대 1회
- **재시도 조건**: 파일 I/O 오류만
- **재시도 간격**: 즉시

### 실패 시 처리
- 오류 로그 출력
- 오케스트레이션 스크립트에 종료 코드 반환
- 락 파일 제거 (스크립트 담당)

---

## 6. 성능 기준 (Performance Criteria)

### 평균 처리 시간
- **추정 범위**: 1-3초
- **측정 항목**:
  - 파일 읽기
  - 마커 생성
  - 파일 쓰기

### 출력 크기 범위
- **Work Status Markers**: 약 200-300 bytes
- **전체 파일**: Frontmatter + 마커 = 약 400-500 bytes

### 리소스 사용량
- **토큰 소비**: 0 (콘텐츠 생성 없음)
- **API 호출**: 1회 (파일 읽기 + 쓰기)
- **메모리**: 최소 (마커만 생성)

---

## 7. 분석 근거 (Analysis Evidence)

### 프롬프트 파일 분석

**참고 파일**: `.claude/agents/content-initiator.md`

#### 핵심 지침 (line 8-21)
```markdown
## YOUR ONLY JOB
Add Work Status Markers at the top of the file. Nothing else.

**DO NOT**:
- Write Overview, Concepts, Code Patterns, Experiments, Quiz, or any learning content
- Create or modify frontmatter
- Add any content besides Work Status Markers
```

→ **추출**: 역할이 명확함 (마커만 추가), 콘텐츠 작성 금지

#### 워크플로 (line 23-49)
```markdown
Step 1: Read the file
Step 2: Check if Work Status Markers exist
Step 3: Add markers after frontmatter
Step 4: If markers exist with CURRENT_AGENT: content-initiator, change to overview-writer
```

→ **추출**: 입력 확인 절차, 출력 형식, 핸드오프 조건

#### 마커 형식 (line 31-42)
```markdown
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: overview-writer -->
<!-- PROGRESS: pending -->
<!-- STARTED: YYYY-MM-DD HH:MM -->
<!-- UPDATED: YYYY-MM-DD HH:MM -->
<!-- HANDOFF LOG:
[DONE] content-initiator: 완료 - initialization
-->
```

→ **추출**: 정확한 출력 형식

### 파서 테스트 분석
**해당 없음**: content-initiator의 출력(Work Status Markers)은 파서 대상이 아님

### 산출물 샘플 분석
**참고 파일**: `public/content/ko/javascript-core-concepts/01-variables/04-naming-convention.md:1-15`

```markdown
---
---

<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: visualization-writer -->
<!-- PROGRESS: 대기중 -->
...
```

→ **확인**: 실제 산출물에서 마커 위치와 형식 확인

**참고 파일**: `.claude/handoff-guide.md`
→ **확인**: Work Status Markers 전체 명세

### 제대로 된 계약 정의

#### 개선 사항
1. **명확성**:
   - "Work Status Markers 추가"를 구체적인 5개 마커로 명시
   - CURRENT_AGENT 값을 정확히 `overview-writer`로 명시

2. **완전성**:
   - 금지 사항 명확화 (콘텐츠 작성 전면 금지)
   - 오류 처리 시나리오 추가 (이미 마커 존재하는 경우)

3. **검증 가능성**:
   - 7개 체크리스트 항목으로 검증 가능
   - 각 마커의 정확한 형식 명시

---

## 8. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2025-10-13 | 초기 계약 정의 |

---

## 9. 참고 문서

- `.claude/agents/content-initiator.md` (프롬프트 파일)
- `.claude/handoff-guide.md` (Work Status Markers 명세)
- `docs/aidlc-docs/inception/units/unit-2-pipe-mechanism.md` (Pipe 메커니즘)
