# Unit 1: Pipe Mechanism 표준화

## 개요

**목적**: Work Status Markers를 명시적이고 표준화된 Pipe 메커니즘으로 개선하여 에이전트 간 데이터 전달의 신뢰성과 추적 가능성을 향상시킨다.

**현재 문제점**:
- Work Status Markers 형식이 암묵적이고 문서화되지 않음
- 파싱 로직이 Bash 스크립트에 분산되어 있음 (content-generator-v6.sh의 parse_work_status_markers 함수)
- 에이전트가 마커를 읽고 쓰는 방법이 표준화되지 않음
- 오류 발생 시 디버깅이 어려움

**개선 방향**:
- Work Status Markers의 명세 문서화
- 마커 파싱/생성 로직의 중앙 집중화
- 검증 메커니즘 구축
- 에이전트가 준수해야 할 명확한 규칙 정의

## 범위

### In Scope
1. **Work Status Markers 명세 정의**
   - 필수 필드 및 선택 필드 정의
   - 각 필드의 데이터 타입 및 형식 정의
   - HANDOFF LOG 형식 표준화
   - 타임스탬프 형식 통일

2. **마커 파싱/생성 유틸리티 개발**
   - Bash 함수 또는 별도 스크립트로 중앙 집중화
   - 마커 읽기 함수
   - 마커 쓰기 함수
   - 마커 검증 함수

3. **에이전트 핸드오프 프로토콜 명세**
   - 에이전트가 작업을 시작할 때 해야 할 일
   - 에이전트가 작업을 완료할 때 해야 할 일
   - 다음 에이전트로 핸드오프하는 방법
   - 개선 요청 시 마커 업데이트 방법

4. **에러 처리 및 재시작 메커니즘**
   - 실패 기록 형식 정의
   - 재시작 지점 식별 로직
   - 불완전한 마커 복구 방법

### Out of Scope
- 에이전트 프롬프트 내용 수정 (Unit 3에서 처리)
- 오케스트레이션 스크립트 전체 리팩토링 (Unit 4에서 처리)
- 품질 측정 로직 (Unit 5에서 처리)

## 아키텍처 컨텍스트

**Pipeline Architecture 관점**:
- **Pipe 역할**: Work Status Markers는 Filter(에이전트) 간 데이터 전달 채널
- **데이터 흐름**: HTML 주석으로 마크다운 파일 상단에 메타데이터 임베딩
- **상태 추적**: CURRENT_AGENT, STATUS, HANDOFF LOG로 파이프라인 진행 상황 추적

**DDD 경량화 관점**:
- **Bounded Context 경계**: 각 에이전트는 마커를 통해서만 다른 에이전트와 통신
- **Ubiquitous Language**: 마커 필드명과 상태값이 팀의 공통 언어
- **Domain Events**: HANDOFF LOG 엔트리가 도메인 이벤트 역할

## 작업 항목

### 1. Work Status Markers 명세 문서 작성
**예상 산출물**: `docs/aidlc-docs/specifications/work-status-markers-spec.md`

**포함 내용**:
```markdown
# Work Status Markers Specification v1.0

## 구조

### 필수 필드
- CURRENT_AGENT: string (에이전트명 또는 빈 문자열)
- STATUS: enum (PENDING, IN_PROGRESS, COMPLETED, FAILED)
- STARTED: datetime (ISO 8601 형식: YYYY-MM-DDTHH:MM:SS+09:00)
- UPDATED: datetime (ISO 8601 형식: YYYY-MM-DDTHH:MM:SS+09:00)
- HANDOFF LOG: array of log entries

### 선택 필드
- VALIDATION_SCORE: integer (0-100)
- IMPROVEMENT_NEEDED: array of improvement items

## HANDOFF LOG 형식
[EVENT_TYPE] agent-name | message | YYYY-MM-DDTHH:MM:SS+09:00

**형식 규칙**:
- 파이프 구분자(`|`)로 필드 분리
- 에이전트당 단일 엔트리 (중복 제거)
- 시간 순서 정렬 (ISO 8601 타임스탬프)

### EVENT_TYPE 값
- START: 파이프라인 시작
- DONE: 작업 완료
- FAILURE: 작업 실패
- SKIP: 건너뛰기
- COMPLETE: 최종 완료

**참고**: WAITING 상태는 중복성으로 인해 제거됨 (DONE 이후 다음 에이전트의 CURRENT_AGENT 설정으로 대체)

## 예시
(전체 예시 코드)

## 파싱 규칙
(정규식 또는 파싱 알고리즘)
```

### 2. 마커 접근 방법 명확화

**핵심 원칙**: 에이전트가 Section 4의 Handoff Protocol을 따라 **마커를 직접 읽고 쓴다**.

**에이전트 책임**:
- **읽기**: Precondition 확인 (CURRENT_AGENT, STATUS, 필수 입력 섹션)
- **쓰기**: Postcondition 보장 (HANDOFF LOG 추가, CURRENT_AGENT 업데이트, STATUS 업데이트, UPDATED 타임스탬프 갱신)
- **검증**: 출력 섹션 존재 여부 확인

**오케스트레이션 스크립트 역할** (Unit 4):
- 에이전트 실행 환경 설정 (UTF-8 인코딩, 환경 변수)
- 에이전트 실행 전후 검증 (사전/사후 검증)
- 실패 시 재시도 또는 복구 처리
- Lock 파일 메커니즘으로 동시성 제어

**참조**:
- `domain_design.md` Section 4: Handoff Protocol Specification (에이전트 규칙)
- `domain_design.md` Section 5: Domain Invariants (검증 규칙)

### 3. 마커 검증 테스트 스크립트 작성
**예상 산출물**: `test/test-work-status-markers.sh`

**테스트 케이스**:
- 모든 필수 필드 존재 확인
- 날짜 형식 검증 (ISO 8601 형식)
- STATUS 값 검증 (PENDING, IN_PROGRESS, COMPLETED, FAILED 중 하나)
- HANDOFF LOG 형식 검증 (파이프 구분자, ISO 8601 타임스탬프)
- 불완전한 마커 감지
- 에이전트당 단일 엔트리 검증

### 4. 에이전트 핸드오프 가이드 작성
**예상 산출물**: `docs/aidlc-docs/guides/agent-handoff-guide.md`

**포함 내용**:
- 에이전트 시작 시 체크리스트
- 에이전트 완료 시 체크리스트
- 핸드오프 시 마커 업데이트 방법
- 개선 요청 기록 방법
- 예외 상황 처리 방법

## 의존성

### 입력 의존성
- 현재 Work Status Markers 사용 현황 (scripts/content-generator-v6.sh)
- 에이전트 프롬프트에서 마커 사용 패턴 (.claude/agents/*.md)

### 출력 의존성
- **Unit 2**: Filter Contracts가 이 명세를 참조하여 입출력 정의
- **Unit 3**: Agent Prompts가 이 가이드를 따라 마커 조작
- **Unit 4**: Orchestration이 이 유틸리티 함수 사용

## 성공 기준

1. **명세 완성도**: 모든 마커 필드와 형식이 문서화됨
2. **유틸리티 작동**: 파싱/생성 함수가 현재 시스템의 모든 마커 처리 가능
3. **검증 통과**: 기존 콘텐츠 파일의 마커가 모두 검증 통과
4. **가이드 명확성**: 개발자가 가이드만 보고 마커 조작 가능

## 예상 산출물 리스트

### Phase 2.1: Domain Design (현재 단계)
1. `docs/aidlc-docs/construction/unit-01-pipe-mechanism/domain_design.md` ✅
   - Section 1: Bounded Context
   - Section 2: Ubiquitous Language
   - Section 3: Domain Events
   - Section 4: Handoff Protocol Specification
   - Section 5: Domain Invariants
   - Section 6: Context Integration
   - Section 7: Validation (진행 중)
   - Section 8: Finalization (대기 중)

### Phase 2.2: Implementation (다음 단계)
1. `docs/aidlc-docs/specifications/work-status-markers-spec.md` (domain_design.md 기반)
2. `test/test-work-status-markers.sh` (검증 스크립트)
3. `docs/aidlc-docs/guides/agent-handoff-guide.md` (에이전트 가이드)

## 예상 작업 기간

- 명세 작성: 1일
- 유틸리티 개발: 2일
- 테스트 작성: 1일
- 가이드 작성: 1일
- **총 예상: 5일**

## 리스크 및 완화 방안

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| 기존 마커 형식과 신규 명세 불일치 | 높음 | 기존 콘텐츠 파일 분석 후 명세 작성 |
| Bash 스크립트 파싱 한계 | 중간 | 복잡한 경우 Node.js 스크립트 사용 검토 |
| 에이전트가 명세를 따르지 않음 | 높음 | 검증 스크립트를 파이프라인에 통합 |

## 질문 사항

### Question 1: 마커 저장 위치 ✅ 결정됨
**질문**: Work Status Markers를 마크다운 파일 내부가 아닌 별도 메타데이터 파일(예: .meta.json)로 분리할까요?

**최종 결정**: **A - 현재 구조 유지 (마크다운 내부 HTML 주석)**

**근거**:
- 단일 파일로 원자성 보장
- 기존 시스템 호환성 유지
- 파일 동기화 문제 방지

**구현 시 주의사항**:
- HTML 주석 형식 엄격히 준수
- UTF-8 인코딩 필수 (한글 정상 표시)

---

### Question 2: 타임스탬프 형식 ✅ 결정됨
**질문**: 타임스탬프를 ISO 8601 형식(YYYY-MM-DDTHH:MM:SSZ)으로 변경할까요?

**최종 결정**: **ISO 8601 형식 채택**

**형식**: `2025-10-14T18:15:00+09:00`
- T로 날짜와 시간 구분
- 타임존 명시 (+09:00)
- 초 단위까지 표기

**구현 영향**:
- `scripts/lib/work-status-markers.sh`의 타임스탬프 생성 함수 업데이트 필요
- 기존 마커 마이그레이션 또는 두 형식 모두 파싱 지원

---

### Question 3: 검증 수준 ✅ 결정됨
**질문**: 마커 검증을 언제 수행할까요?

**최종 결정**: **C - 사전+사후 검증 모두**

**구현 상세**:
1. **사전 검증 (Precondition)**:
   - 파이프라인 시작 전: 파일 존재, 기본 마커 구조 확인
   - 에이전트 실행 전: CURRENT_AGENT 일치 여부 확인

2. **사후 검증 (Postcondition)**:
   - 에이전트 실행 후: 마커 업데이트 정상 여부 확인
   - HANDOFF LOG 엔트리 추가 확인

**검증 실패 시 동작**:
- Fail-Fast: 즉시 중단, 명확한 오류 메시지 출력
- 재시작 지점 마커에 기록
