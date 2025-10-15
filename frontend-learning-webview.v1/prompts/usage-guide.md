# Pipeline Architecture 개선 프롬프트 사용 가이드

## 개요

이 가이드는 **현재 작동 중인** 학습 콘텐츠 자동화 시스템을 Pipeline Architecture 기반으로 **개선**하기 위한 9개 AI-DLC 프롬프트의 사용 방법을 설명합니다.

**중요한 이해**:
- ❌ 새로운 시스템을 만드는 것이 **아닙니다**
- ✅ **현재 7개 에이전트 시스템을 개선**하는 것입니다
- ✅ 입력은 **category.yaml** (토픽은 이미 정의됨)
- ✅ **역공학 접근**: 기존 프롬프트/테스트에서 계약 추출

**대상 독자**:
- 현재 시스템을 개선하려는 개발자
- AI-DLC 방법론을 기존 시스템에 적용하려는 팀
- Pipeline Architecture로 명시적 설계를 원하는 아키텍트

**소요 시간**:
- 전체 프로세스: 2-3주
- Inception: 1-3일 (개선 영역 정의)
- Construction: 1-2주 (개선 구현)
- Operations: 3-5일 (Quality Gates, 손실 함수)
- 회고: 1일

---

## 사전 이해: 3가지 레이어

**반드시 이해해야 할 레이어 구조**:

```
[레이어 1] AI-DLC 방법론 (시스템 개발 방법) ← 고정
           ↓ 적용 대상
[레이어 2] 콘텐츠 생성 시스템 (프로덕트) ← 이 프롬프트들의 개선 대상
           ↓ 생성하는 것
[레이어 3] 학습 콘텐츠 (시스템의 산출물)
```

**이 프롬프트들의 초점**:
- ✅ **레이어 2**: 7개 에이전트 시스템 **개선**
- ❌ **레이어 3**: 학습 토픽 분석 (이미 category.yaml에 정의됨)

---

## 사전 준비

### 1. 현재 시스템 확인

다음 파일들이 존재하고 작동하는지 확인하세요:

```bash
# 7개 에이전트 프롬프트 (이미 작동 중)
ls .claude/agents/*.md
# 예상: content-initiator.md, overview-writer.md, concepts-writer.md,
#      visualization-writer.md, practice-writer.md, quiz-writer.md,
#      content-validator.md

# 오케스트레이션 스크립트 (이미 작동 중)
ls scripts/content-generator-v6.sh

# 파서 테스트 (이미 존재)
ls test/test-*.mjs

# 생성된 콘텐츠 샘플
ls public/content/ko/javascript-core-concepts/01-variables/*.md
```

### 2. 작업 디렉터리 생성

```bash
mkdir -p docs/aidlc-docs/inception/units
mkdir -p docs/aidlc-docs/construction/filters
mkdir -p docs/aidlc-docs/operations
mkdir -p docs/aidlc-docs/retrospective
mkdir -p logs
```

### 3. Claude 세션 준비

- Claude Code 또는 Claude.ai 새 세션 시작
- 프로젝트 컨텍스트 파일 준비 (CLAUDE.md, handoff-guide.md)

---

## 실행 가이드

### Phase 1: Inception - 개선 영역 정의 (1-3일)

#### 프롬프트 1: 시스템 아키텍트 역할 부여

**목적**: Claude에게 "기존 시스템 개선" 컨텍스트 제공

**실행 방법**:
1. `docs/aidlc-docs/prompts/01-architect-role.md` 파일 열기
2. 프롬프트 전체를 Claude에게 복사/붙여넣기
3. Claude가 컨텍스트를 이해했는지 확인

**확인 사항**:
- Claude가 "7개 에이전트 **개선**"을 이해했는가?
- "기존 시스템" vs "새 시스템" 구분을 명확히 하는가?

**소요 시간**: 5분

---

#### 프롬프트 2: 개선 영역 정의

**목적**: 프로젝트 배경에서 제시된 개선 필요 영역 → 5개 개선 유닛으로 분해

**실행 방법**:
1. `docs/aidlc-docs/prompts/02-inception-improvement-areas.md` 프롬프트 제공
2. Claude가 프롬프트 1에서 제시된 개선 필요 영역을 참조하여 5개 유닛 정의
3. 각 유닛의 목표, 범위, 의존성 검토

**5개 개선 유닛**:
- **Unit 1**: Filter 계약 명시화 (P2, 2-3일)
- **Unit 2**: Quality Gates 추가 (P0, 1-2일)
- **Unit 3**: 손실 함수 강화 (P0, 2-3일)
- **Unit 4**: 조건부 Filter 실행 (P1, 2-3일)
- **Unit 5**: 성능 모니터링 (P2, 1-2일)

**체크리스트**:
- [ ] 각 유닛이 독립적으로 구현 가능한가?
- [ ] 우선순위가 명확한가? (P0 > P1 > P2)
- [ ] 유닛 간 의존성이 명시되어 있는가?
- [ ] 실행 순서가 논리적인가?

**기대 산출물**:
- `aidlc-docs/inception/units/unit-1-filter-contracts.md`
- `aidlc-docs/inception/units/unit-2-quality-gates.md`
- `aidlc-docs/inception/units/unit-3-loss-function.md`
- `aidlc-docs/inception/units/unit-4-conditional-execution.md`
- `aidlc-docs/inception/units/unit-5-monitoring.md`
- `aidlc-docs/inception/units/integration_plan.md`

**소요 시간**: 1-3일

---

### Phase 2: Construction - 개선 구현 (1-2주)

#### 프롬프트 3: Filter 계약 명시화

**목적**: **기존 7개 에이전트를 역공학 분석**하여 계약 추출

**실행 방법**:
1. `docs/aidlc-docs/prompts/03-construction-filter-contracts.md` 프롬프트 제공
2. Claude가 **역공학 분석**:
   - `.claude/agents/*.md` 읽기 (입력/출력 파악)
   - `test/test-*.mjs` 읽기 (품질 기준 파악)
   - `public/content/ko/**/*.md` 읽기 (실제 산출물 확인)
3. 각 Filter에 대해 계약 문서 작성

**중요: 역공학 접근**:
```
❌ 잘못된 접근: "이상적인 계약을 설계하자"
✅ 올바른 접근: "기존 프롬프트에서 계약을 추출하자"

예시:
1. .claude/agents/overview-writer.md 읽기
2. "## 개요 섹션을 작성하세요" → 출력 계약: "## 개요"
3. test-overview.mjs에서 "4개 하위 섹션 확인" → 품질 기준
4. 실제 생성된 파일에서 평균 길이 측정 → 성능 기준
```

**검토 체크리스트** (각 Filter마다):
- [ ] 입력 계약이 기존 프롬프트와 일치하는가?
- [ ] 출력 계약이 실제 산출물과 일치하는가?
- [ ] 품질 기준이 파서 테스트와 일치하는가?
- [ ] **역공학** 근거가 명시되어 있는가? (파일명:줄번호)

**기대 산출물**:
- `aidlc-docs/construction/filters/content-initiator-contract.md` (총 7개)
- `aidlc-docs/construction/filter-contracts-summary.md` (요약 표)

**소요 시간**: 2-3일

---

#### 프롬프트 4: Pipe 메커니즘 개선

**목적**: 현재 Work Status Markers 분석 + 3가지 개선 옵션 제시

**실행 방법**:
1. `docs/aidlc-docs/prompts/04-construction-pipe-mechanism.md` 프롬프트 제공
2. Claude가 현재 Work Status Markers 분석
3. 3가지 옵션 비교 (A: 강화, B: JSON, C: 중간 파일)
4. 로드맵 검토

**의사결정 포인트**:
- **단기(1-2개월)**: 옵션 A (Work Status Markers 강화) 권장
- **중기(3-6개월)**: 옵션 B (JSON 메타데이터) POC
- **장기(6개월+)**: 옵션 C (중간 파일) 평가

**기대 산출물**:
- `aidlc-docs/construction/pipe-mechanism.md`

**소요 시간**: 1-2일

---

#### 프롬프트 5: 에이전트 프롬프트 개선

**목적**: **기존 에이전트 프롬프트를 개선** (Filter 계약 통합)

**실행 방법**:
1. `docs/aidlc-docs/prompts/05-construction-agent-improvement.md` 프롬프트 제공
2. Claude가 각 에이전트 프롬프트 읽기
3. 기존 강점 파악 (예시, 톤, 가이드라인)
4. Filter 계약 통합 (입력/출력/품질)
5. 개선된 프롬프트를 **같은 파일에 덮어쓰기**

**개선 전략**:
```
1. 기존 강점 유지:
   - 효과적인 예시 보존
   - 에이전트의 "목소리" 유지
   - 핵심 가이드라인 보존

2. 명시성 추가:
   - 입력 계약 섹션 추가
   - 출력 계약 섹션 추가
   - 품질 기준 체크리스트 추가
   - Work Status Markers 업데이트 로직 추가

3. 모호함 제거:
   - "개요를 작성하세요" → "4개 하위 섹션으로 구성된 ## 개요 섹션"
   - "적절한 길이" → "Introduction 50자 이상"
```

**검토 체크리스트** (각 에이전트마다):
- [ ] 기존의 효과적인 부분이 보존되었는가?
- [ ] Filter 계약이 통합되었는가?
- [ ] 입력 검증 로직이 추가되었는가?
- [ ] 출력 자체 점검 체크리스트가 있는가?
- [ ] Work Status Markers 업데이트 로직이 명확한가?

**백업 권장**:
```bash
cp .claude/agents/overview-writer.md .claude/agents/overview-writer.md.backup
```

**기대 산출물**:
- `.claude/agents/*.md` (7개, 개선됨)

**소요 시간**: 3-5일

---

#### 프롬프트 6: 오케스트레이션 스크립트 개선

**목적**: content-generator-v6.sh 개선 설계

**실행 방법**:
1. `docs/aidlc-docs/prompts/06-construction-orchestration.md` 프롬프트 제공
2. Claude가 개선 아키텍처 설계
3. 조건부 실행, 부분 재실행, Quality Gates 알고리즘 검토

**기대 산출물**:
- `aidlc-docs/construction/orchestration-design.md`
  * 조건부 실행 알고리즘
  * 부분 재실행 알고리즘
  * Quality Gates 통합
  * 성능 모니터링

**소요 시간**: 2-3일

---

### Phase 3: Operations - 배포 및 모니터링 (3-5일)

#### 프롬프트 7: Quality Gates 구현

**목적**: 3개 인간 검증 포인트 실제 구현

**실행 방법**:
1. `docs/aidlc-docs/prompts/07-operations-quality-gates.md` 프롬프트 제공
2. Claude가 Bash 함수 구현 (`after_filter_*`)
3. 대화형 모드 및 자동 모드 로직 검토

**테스트**:
```bash
# 대화형 모드 테스트
./content-generator-v6.sh -a --category=test --interactive

# 자동 모드 테스트
./content-generator-v6.sh -a --category=test
```

**기대 산출물**:
- `aidlc-docs/operations/quality-gates.md`
- `aidlc-docs/operations/quality-gates-implementation.sh`

**소요 시간**: 1-2일

---

#### 프롬프트 8: 손실 함수 및 모니터링

**목적**: 파서 테스트 → 손실 함수로 강화, 성능 모니터링

**실행 방법**:
1. `docs/aidlc-docs/prompts/08-operations-loss-function.md` 프롬프트 제공
2. Claude가 `validate-*.mjs` 파일 생성 (감점 규칙 명시)
3. 성능 로깅 및 분석 스크립트 구현

**테스트**:
```bash
# 손실 함수 테스트
npx tsx test/validate-overview.mjs public/content/ko/**/*.md

# 기대 출력:
# {
#   score: 92,
#   errors: [...],
#   improvements: [...]
# }
```

**기대 산출물**:
- `test/validate-overview.mjs`
- `test/validate-concepts.mjs`
- `test/validate-practice.mjs`
- `test/validate-quiz.mjs`
- `test/generate-improvement-markers.mjs`
- `scripts/analyze-performance.sh`

**소요 시간**: 2-3일

---

#### 프롬프트 9: 회고 및 다음 Bolt

**목적**: Bolt 완료 후 회고 및 개선 계획

**실행 시점**:
- 최소 10-20개 콘텐츠 생성 후
- 성능 데이터 충분히 축적 후 (logs/performance.log)

**실행 방법**:
1. 1-2주간 성능 데이터 수집
2. `docs/aidlc-docs/prompts/09-retrospective.md` 프롬프트 제공
3. Claude가 정량적/정성적 분석 수행
4. 반복 오류 패턴 식별
5. 다음 Bolt 개선 계획 수립

**기대 산출물**:
- `aidlc-docs/retrospective/bolt-1-retrospective.md`
- `aidlc-docs/retrospective/bolt-2-plan.md`

**소요 시간**: 1일

---

## 사용 시나리오

### 시나리오 1: 전체 개선 (Full AI-DLC)

**상황**: 현재 시스템을 체계적으로 개선하고 싶음

**단계**:
1. 프롬프트 1 → 시스템 컨텍스트 설정
2. 프롬프트 2 → Inception (개선 영역 정의)
3. 프롬프트 3-6 → Construction (Filter 계약, Pipe, 프롬프트 개선, 오케스트레이션)
4. 프롬프트 7-8 → Operations (Quality Gates, 손실 함수)
5. 1-2주 운영 → 성능 데이터 수집
6. 프롬프트 9 → 회고 및 다음 Bolt

**소요 시간**: 2-3주

---

### 시나리오 2: 빠른 명시화 (Quick Win)

**상황**: 빠르게 시작하고 싶음, Filter 계약만 명시화

**단계**:
1. 프롬프트 1 → 시스템 컨텍스트
2. 프롬프트 2 → 개선 영역 정의 (간략히)
3. 프롬프트 3 → Filter 계약 명시화 (역공학)
4. 완료

**소요 시간**: 3-5일

---

### 시나리오 3: 품질 개선 우선 (Quality First)

**상황**: 품질 보증이 급선무

**단계**:
1. 프롬프트 1 → 시스템 컨텍스트
2. 프롬프트 2 → 개선 영역 정의 (Unit 2, 3 집중)
3. 프롬프트 8 → 손실 함수 강화 (P0)
4. 프롬프트 7 → Quality Gates 추가 (P0)
5. 완료

**소요 시간**: 1주

---

## 문제 해결

### 문제 1: Claude가 "새 시스템"을 만들려고 함

**증상**: 프롬프트 실행 시 "학습 토픽 분석"을 하려고 함

**해결**:
```
잠깐! 이 프로젝트는 새 시스템을 만드는 것이 아닙니다.

**현재 상황**:
- 7개 에이전트가 이미 작동 중
- category.yaml에 토픽이 이미 정의됨
- 입력은 category.yaml, 출력은 학습 콘텐츠

**당신의 임무**:
- 프롬프트 1에서 제시된 개선 필요 영역을 참조하세요
- 현재 시스템의 **개선**에 집중하세요 (.claude/agents/*.md 읽기)
- 개선할 영역을 **유닛으로 분해**하세요

"학습 토픽 분석"은 하지 마세요. 그것은 시스템이 하는 일입니다.
```

### 문제 2: Filter 계약을 "이상적으로" 설계함

**증상**: 프롬프트 3에서 기존 프롬프트를 무시하고 새 계약 작성

**해결**:
```
잠깐! Filter 계약은 **역공학으로 추출**해야 합니다.

**올바른 접근**:
1. .claude/agents/overview-writer.md 파일을 읽으세요
2. 현재 프롬프트에서 입력/출력이 무엇인지 파악하세요
3. test/test-overview.mjs에서 품질 기준을 파악하세요
4. 실제 생성된 파일을 확인하여 검증하세요
5. 파악한 내용을 **있는 그대로** 문서화하세요

새로운 계약을 설계하지 마세요. 기존 계약을 **추출**하세요.
```

### 문제 3: 에이전트 프롬프트를 완전히 새로 작성함

**증상**: 프롬프트 5에서 기존 프롬프트를 무시하고 새로 작성

**해결**:
```
잠깐! 에이전트 프롬프트는 **개선**하는 것입니다.

**올바른 접근**:
1. 기존 .claude/agents/overview-writer.md를 읽으세요
2. 효과적인 부분을 식별하세요 (예시, 톤, 가이드라인)
3. 이 부분들을 **보존**하세요
4. Filter 계약에 맞춰 **명시성만 추가**하세요:
   - 입력 계약 섹션
   - 출력 계약 섹션
   - 품질 기준 체크리스트
   - Work Status Markers 업데이트 로직

기존 프롬프트를 완전히 새로 작성하지 마세요.
```

---

## 다음 단계

### 즉시 시작 (오늘)
1. 이 가이드 정독 (30분)
2. 3가지 레이어 이해 확인
3. 프롬프트 1 실행 (시스템 컨텍스트)

### 1주차
1. 프롬프트 2 (Inception)
2. 개선 영역 정의

### 2-3주차
1. 프롬프트 3-6 (Construction)
2. Filter 계약 명시화, 에이전트 개선

### 4주차+
1. 프롬프트 7-8 (Operations)
2. Quality Gates, 손실 함수 구현
3. 1-2주 운영 후 회고 (프롬프트 9)

---

## 추가 자료

### 관련 문서
- `docs/aidlc-docs/ai-dlc-whitepaper-ko.md`: AI-DLC 방법론
- `docs/aidlc-docs/methodology-comparison-report.md`: 아키텍처 선정 근거
- `.claude/handoff-guide.md`: 에이전트 협업 가이드

### 핵심 구분
```
❌ 잘못된 이해: "학습 토픽 분석 → 에이전트 설계 → 구현"
✅ 올바른 이해: "개선 필요 영역 파악 → 유닛 분해 → 개선 구현"

❌ 잘못된 접근: "이상적인 Filter 계약 설계"
✅ 올바른 접근: "기존 프롬프트에서 계약 역공학 추출"

❌ 잘못된 목표: "새로운 에이전트 프롬프트 작성"
✅ 올바른 목표: "기존 프롬프트 개선 (강점 유지 + 명시성 추가)"
```

---

**작성 일시**: 2025-10-12 (전면 수정)
**버전**: 2.0
**아키텍처**: Pipeline Architecture (기존 시스템 개선)
**방법론**: AI-DLC

이 가이드를 따라 **현재 작동 중인** 학습 콘텐츠 자동화 시스템을 Pipeline Architecture로 **명시적 설계**하고, AI-DLC 원칙을 충실히 적용하여 인간-AI 협업 품질을 극대화하세요.
