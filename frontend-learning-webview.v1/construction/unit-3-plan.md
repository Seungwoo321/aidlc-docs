# Unit 3: 에이전트 프롬프트 개선 - 작업 계획서

**목표**: Unit 1 Filter 계약 및 Unit 2 Pipe 메커니즘을 기존 에이전트 프롬프트에 통합

**작성일**: 2025-10-13
**단계**: Construction Phase - Unit 3 (에이전트 프롬프트 개선)

---

## 작업 개요

### 핵심 목표
**기존 강점 유지 + 명시성 추가**

- ✅ 유지: 효과적인 예시, 에이전트 톤, 핵심 가이드라인
- ➕ 추가: 입력/출력 계약, 품질 기준, Work Status Markers 처리, 자체 점검

### 작업 범위
- **7개 에이전트 프롬프트 개선**
  1. content-initiator.md
  2. overview-writer.md
  3. concepts-writer.md
  4. visualization-writer.md
  5. practice-writer.md
  6. quiz-writer.md
  7. content-validator.md

### 각 프롬프트에 추가할 섹션
1. 입력 계약 (Input Contract)
2. 출력 계약 (Output Contract)
3. 품질 기준 (Quality Criteria)
4. 자체 점검 체크리스트 (Self-Check Checklist)
5. Work Status Markers 처리 로직

---

## 작업 단계

### 1단계: 개선 방법론 정의

**진행 상태**: 진행 예정

- [ ] 표준 프롬프트 구조 템플릿 확정
- [ ] 개선 전후 비교 기준 정의
- [ ] 강점 식별 방법 정의
- [ ] 백업 및 롤백 절차 확립

**예상 소요 시간**: 1시간

**참고 문서**:
- `docs/aidlc-docs/inception/units/unit-3-agent-prompts.md` (개선 템플릿)
- `docs/aidlc-docs/construction/filters/*.md` (7개 Filter 계약)
- `docs/aidlc-docs/construction/pipe-mechanism.md` (Pipe 메커니즘)

---

### 2단계: 에이전트별 개선 (7개)

#### 개선 프로세스 (각 에이전트 공통)

**Step 1**: 현재 상태 분석
- [ ] 기존 프롬프트 읽기
- [ ] 효과적인 부분 식별 (예시, 톤, 가이드라인)
- [ ] 모호한 부분 식별

**Step 2**: 계약 통합
- [ ] Unit 1의 해당 Filter 계약 읽기
- [ ] 입력 계약 섹션 추가
- [ ] 출력 계약 섹션 추가

**Step 3**: 품질 기준 추가
- [ ] 파서 테스트 참조 (`test/test-*.mjs`)
- [ ] 구조적 요구사항 명시
- [ ] 내용적 요구사항 명시

**Step 4**: Work Status Markers 처리 추가
- [ ] Unit 2의 Pipe 메커니즘 참조
- [ ] 시작 시 확인할 마커 명시
- [ ] 완료 시 업데이트할 마커 명시
- [ ] 실패 시 처리 방법 명시

**Step 5**: 자체 점검 체크리스트 추가
- [ ] 에이전트가 출력 전 확인할 항목 나열

**Step 6**: 검증
- [ ] 개선 전후 비교
- [ ] 기존 강점 유지 확인

#### 2.1 content-initiator.md 개선

**진행 상태**: 대기중

- [ ] Step 1: 현재 상태 분석
- [ ] Step 2: 계약 통합 (content-initiator-contract.md 참조)
- [ ] Step 3: 품질 기준 추가 (초기 파일 생성 검증)
- [ ] Step 4: Work Status Markers 초기화 로직 추가
- [ ] Step 5: 자체 점검 체크리스트 추가
- [ ] Step 6: 검증

**참고**: content-initiator는 파서 테스트 없음 (초기 파일만 생성)

**예상 소요 시간**: 1-2시간

---

#### 2.2 overview-writer.md 개선

**진행 상태**: 대기중

- [ ] Step 1: 현재 상태 분석
- [ ] Step 2: 계약 통합 (overview-writer-contract.md 참조)
- [ ] Step 3: 품질 기준 추가 (test-overview.mjs 참조)
- [ ] Step 4: Work Status Markers 처리 추가
- [ ] Step 5: 자체 점검 체크리스트 추가
- [ ] Step 6: 검증

**예상 소요 시간**: 2-3시간

---

#### 2.3 concepts-writer.md 개선

**진행 상태**: 대기중

- [ ] Step 1: 현재 상태 분석
- [ ] Step 2: 계약 통합 (concepts-writer-contract.md 참조)
- [ ] Step 3: 품질 기준 추가 (test-concepts.mjs 참조)
- [ ] Step 4: Work Status Markers 처리 추가
- [ ] Step 5: 자체 점검 체크리스트 추가
- [ ] Step 6: 검증

**특이사항**: 3단계 난이도 시스템 (Easy/Normal/Expert) 명확히 명시

**예상 소요 시간**: 2-3시간

---

#### 2.4 visualization-writer.md 개선

**진행 상태**: 대기중

- [ ] Step 1: 현재 상태 분석
- [ ] Step 2: 계약 통합 (visualization-writer-contract.md 참조)
- [ ] Step 3: 품질 기준 추가 (TypeScript 컴파일, index.ts export)
- [ ] Step 4: Work Status Markers 처리 추가 ([SKIP] 처리 포함)
- [ ] Step 5: 자체 점검 체크리스트 추가
- [ ] Step 6: 검증

**특이사항**:
- 파서 테스트 없음 (React 컴포넌트 생성)
- index.ts export 누락 방지 강조 (Critical!)
- 건너뛰기 처리 로직 ([SKIP]) 명시

**예상 소요 시간**: 2-3시간

---

#### 2.5 practice-writer.md 개선

**진행 상태**: 대기중

- [ ] Step 1: 현재 상태 분석
- [ ] Step 2: 계약 통합 (practice-writer-contract.md 참조)
- [ ] Step 3: 품질 기준 추가 (test-patterns.mjs, test-experiments.mjs 참조)
- [ ] Step 4: Work Status Markers 처리 추가
- [ ] Step 5: 자체 점검 체크리스트 추가
- [ ] Step 6: 검증

**특이사항**: Code Patterns + Experiments 두 섹션 생성

**예상 소요 시간**: 2-3시간

---

#### 2.6 quiz-writer.md 개선

**진행 상태**: 대기중

- [ ] Step 1: 현재 상태 분석
- [ ] Step 2: 계약 통합 (quiz-writer-contract.md 참조)
- [ ] Step 3: 품질 기준 추가 (test-quiz-raw.mjs 참조)
- [ ] Step 4: Work Status Markers 처리 추가
- [ ] Step 5: 자체 점검 체크리스트 추가
- [ ] Step 6: 검증

**특이사항**:
- 6가지 퀴즈 유형 명시
- 난이도 분포 (1-2: 30%, 3: 40%, 4-5: 30%) 명시

**예상 소요 시간**: 2-3시간

---

#### 2.7 content-validator.md 개선

**진행 상태**: 대기중

- [ ] Step 1: 현재 상태 분석
- [ ] Step 2: 계약 통합 (content-validator-contract.md 참조)
- [ ] Step 3: 품질 기준 추가 (100점 만점 검증)
- [ ] Step 4: Work Status Markers 처리 추가 (IMPROVEMENT_NEEDED 처리)
- [ ] Step 5: 자체 점검 체크리스트 추가
- [ ] Step 6: 검증

**특이사항**:
- 마지막 Filter (다음 에이전트 없음)
- 100점: COMPLETE, <100점: IMPROVEMENT_NEEDED + 핸드오프
- Visualization 3단계 검증 (메타데이터 + 파일 + index.ts)

**예상 소요 시간**: 2-3시간

---

### 3단계: 통합 가이드 문서 작성

**진행 상태**: 대기중

- [ ] `agent-prompt-improvements.md` 작성
  - 개선 전후 비교
  - 개선 원칙 정리
  - 강점 유지 항목 정리
  - 향후 새 에이전트 작성 가이드

**예상 소요 시간**: 2시간

---

### 4단계: 검증 및 테스트

**진행 상태**: 대기중

- [ ] 7개 개선된 프롬프트 일관성 확인
- [ ] Unit 1 Filter 계약과 일치 확인
- [ ] Unit 2 Pipe 메커니즘과 일치 확인
- [ ] 기존 강점 유지 확인
- [ ] 파일럿 콘텐츠 생성 테스트 (선택)

**예상 소요 시간**: 2-3시간

---

### 5단계: 문서 최종 검토 및 승인 요청

**진행 상태**: 대기중

- [ ] 7개 프롬프트 품질 확인
  - 명확성: 입력/출력 명확히 정의
  - 완전성: 필수 섹션 모두 포함
  - 일관성: Filter 계약과 일치
- [ ] 가이드 문서 완성도 확인
- [ ] 백업 파일 확인
- [ ] 사용자 최종 검토 요청

**예상 소요 시간**: 1시간

---

## 예상 소요 시간 총계

- 1단계: 1시간
- 2단계: 14-17시간 (7개 × 2-3시간)
- 3단계: 2시간
- 4단계: 2-3시간
- 5단계: 1시간

**총**: 20-24시간 (약 3-4일)

---

## 중요 원칙

### 🎯 Unit 3의 핵심 목표

**기존 강점 유지 + 명시성 추가**
- 이 작업은 **개선(improvement)**이지 **재작성(rewrite)**이 아님
- 효과적인 부분은 **그대로 유지**
- 명시적 계약만 **추가**

### ✅ 해야 할 것

- **기존 강점 식별 및 보존**
  - 효과적인 예시 유지
  - 에이전트의 톤 및 스타일 유지
  - 핵심 가이드라인 유지
- **명시성 추가**
  - 입력/출력 계약 명시
  - 품질 기준 명시
  - Work Status Markers 처리 명시
  - 자체 점검 체크리스트 추가
- **Unit 1, 2와 일관성 유지**
  - Filter 계약과 일치
  - Pipe 메커니즘과 일치

### ❌ 하지 말아야 할 것

- 에이전트의 기본 기능 변경
- 효과적인 예시/가이드라인 삭제
- 과도한 명시성으로 창의성 저하
- 프롬프트를 완전히 새로 작성

### 📋 작업 흐름

```
기존 프롬프트 분석 (강점 식별)
    ↓
Filter 계약 통합 (I/O 명시)
    ↓
품질 기준 추가 (파서 테스트 기반)
    ↓
Work Status Markers 처리 추가 (Pipe 메커니즘 기반)
    ↓
자체 점검 체크리스트 추가
    ↓
검증 (강점 유지 + 명시성 확보)
```

---

## 백업 및 롤백

### 백업 절차
```bash
# 개선 전 전체 백업
for file in .claude/agents/*.md; do
  cp "$file" "$file.backup"
done
```

### 롤백 절차
```bash
# 문제 발생 시 특정 파일 롤백
cp .claude/agents/overview-writer.md.backup .claude/agents/overview-writer.md
```

---

## 산출물 목록

### 주요 산출물 (8개)

1. `.claude/agents/content-initiator.md` (개선됨)
2. `.claude/agents/overview-writer.md` (개선됨)
3. `.claude/agents/concepts-writer.md` (개선됨)
4. `.claude/agents/visualization-writer.md` (개선됨)
5. `.claude/agents/practice-writer.md` (개선됨)
6. `.claude/agents/quiz-writer.md` (개선됨)
7. `.claude/agents/content-validator.md` (개선됨)
8. `docs/aidlc-docs/construction/agent-prompt-improvements.md` (가이드)

---

## 검증 체크리스트

### 문서 완성도
- [ ] 7개 에이전트 프롬프트 모두 개선 완료
- [ ] 각 프롬프트에 입력/출력/품질/자체점검 섹션 추가
- [ ] 개선 가이드 문서 작성 완료

### 계약 일치성
- [ ] Unit 1의 Filter 계약과 일치
- [ ] Unit 2의 Pipe 메커니즘과 일치
- [ ] 파서 테스트와 품질 기준 일치

### 강점 보존
- [ ] 기존 효과적인 예시 유지
- [ ] 에이전트의 톤 및 스타일 유지
- [ ] 핵심 가이드라인 유지

### 명확성
- [ ] 입력이 명확히 정의됨
- [ ] 출력 형식이 구체적으로 명시됨
- [ ] 품질 기준이 측정 가능
- [ ] Work Status Markers 처리 로직이 명확

---

## 참고 문서

- `docs/aidlc-docs/inception/units/unit-3-agent-prompts.md` (Unit 3 정의)
- `docs/aidlc-docs/construction/filters/*.md` (7개 Filter 계약)
- `docs/aidlc-docs/construction/pipe-mechanism.md` (Pipe 메커니즘)
- `docs/aidlc-docs/construction/filter-contracts-summary.md` (계약 요약)
- `.claude/handoff-guide.md` (에이전트 협업 가이드)

---

**작성 완료**: 2025-10-13
**상태**: 작업 시작 준비 완료
