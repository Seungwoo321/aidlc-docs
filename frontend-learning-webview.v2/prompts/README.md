# AI-DLC 프롬프트 목록

## 개요

학습 콘텐츠 자동화 시스템을 **Modular Monolithic Pipeline Architecture**로 개선하기 위한 AI-DLC 프롬프트 세트입니다.

---

## 프롬프트 구조

### 1. Inception 단계 (2개)

| 프롬프트 | 파일명 | 설명 |
|---------|--------|------|
| 01 | 01-system-architect-role.md | 시스템 아키텍트 역할 부여 + 프로젝트 배경 |
| 02 | 02-inception-unit-decomposition.md | 개선 영역을 5개 유닛으로 분해 |

**산출물**:
- `aidlc-docs/inception/plan.md`
- `aidlc-docs/inception/units/unit-{1-5}.md`
- `aidlc-docs/inception/units/integration_plan.md`

---

### 2. Construction 단계 (15개: 5개 유닛 × 3단계)

각 유닛별로 **도메인 설계 → 논리 설계 → 구현** 3단계 프롬프트

#### Unit 1: Filter 계약 명시화

| 프롬프트 | 파일명 | 설명 |
|---------|--------|------|
| 03 | 03-construction-unit1-domain.md | Filter 계약 도메인 모델 설계 |
| 04 | 04-construction-unit1-logical.md | Filter 계약 논리 설계 |
| 05 | 05-construction-unit1-implementation.md | 7개 Filter 계약 문서 생성 |

**산출물**:
- `aidlc-docs/construction/unit-1-filter-contracts/domain_design.md`
- `aidlc-docs/construction/unit-1-filter-contracts/logical_design.md`
- `aidlc-docs/construction/unit-1-filter-contracts/filters/{filter-name}-contract.md`

#### Unit 2: Pipe 메커니즘 설계

| 프롬프트 | 파일명 | 설명 |
|---------|--------|------|
| 06 | 06-construction-unit2-domain.md | Pipe 메커니즘 도메인 모델 설계 |
| 07 | 07-construction-unit2-logical.md | Pipe 메커니즘 논리 설계 |
| 08 | 08-construction-unit2-implementation.md | Work Status Markers 표준 문서 생성 |

**산출물**:
- `aidlc-docs/construction/unit-2-pipe-mechanism/domain_design.md`
- `aidlc-docs/construction/unit-2-pipe-mechanism/logical_design.md`
- `aidlc-docs/construction/unit-2-pipe-mechanism/specifications/`

#### Unit 3: 에이전트 프롬프트 개선

| 프롬프트 | 파일명 | 설명 |
|---------|--------|------|
| 09 | 09-construction-unit3-domain.md | 에이전트 프롬프트 도메인 모델 설계 |
| 10 | 010-construction-unit3-logical.md | 에이전트 프롬프트 논리 설계 |
| 11 | 011-construction-unit3-implementation.md | 7개 에이전트 프롬프트에 계약 통합 |

**산출물**:
- `aidlc-docs/construction/unit-3-agent-prompts/domain_design.md`
- `aidlc-docs/construction/unit-3-agent-prompts/logical_design.md`
- `aidlc-docs/construction/unit-3-agent-prompts/src/` (개선된 프롬프트)

#### Unit 4: 오케스트레이션 개선

| 프롬프트 | 파일명 | 설명 |
|---------|--------|------|
| 12 | 012-construction-unit4-domain.md | 오케스트레이션 도메인 모델 설계 |
| 13 | 013-construction-unit4-logical.md | 오케스트레이션 논리 설계 |
| 14 | 014-construction-unit4-implementation.md | 스크립트 개선 구현 |

**산출물**:
- `aidlc-docs/construction/unit-4-orchestration/domain_design.md`
- `aidlc-docs/construction/unit-4-orchestration/logical_design.md`
- `aidlc-docs/construction/unit-4-orchestration/src/` (개선된 스크립트)

#### Unit 5: 품질 측정 방법 구축

| 프롬프트 | 파일명 | 설명 |
|---------|--------|------|
| 15 | 015-construction-unit5-domain.md | 품질 측정 도메인 모델 설계 |
| 16 | 016-construction-unit5-logical.md | 품질 측정 논리 설계 |
| 17 | 017-construction-unit5-implementation.md | 품질 측정 시스템 구현 |

**산출물**:
- `aidlc-docs/construction/unit-5-quality-metrics/domain_design.md`
- `aidlc-docs/construction/unit-5-quality-metrics/logical_design.md`
- `aidlc-docs/construction/unit-5-quality-metrics/src/` (품질 측정 스크립트)

---

### 3. Operations 단계 (1개)

| 프롬프트 | 파일명 | 설명 |
|---------|--------|------|
| 18 | 18-operations-quality-monitoring.md | 품질 데이터 수집 및 분석 |

**산출물**:
- `aidlc-docs/operations/quality_reports/`
- `aidlc-docs/operations/performance_logs/`
- `aidlc-docs/operations/improvement_plan.md`

---

## 실행 순서

### Phase 1: Inception (1-2주)
1. **프롬프트 01**: 시스템 아키텍트 역할 이해
2. **프롬프트 02**: 5개 유닛 정의 및 통합 계획 수립

### Phase 2: Construction - Unit 1, 2 (병렬 가능, 1주)
3. **프롬프트 03-05**: Unit 1 (Filter 계약)
4. **프롬프트 06-08**: Unit 2 (Pipe 메커니즘)

### Phase 3: Construction - Unit 3, 4 (순차 실행, 1-2주)
5. **프롬프트 09-11**: Unit 3 (에이전트 프롬프트) - Unit 1, 2 산출물 통합
6. **프롬프트 12-14**: Unit 4 (오케스트레이션) - Unit 1, 2 산출물 통합

### Phase 4: Construction - Unit 5 (1주)
7. **프롬프트 15-17**: Unit 5 (품질 측정) - 모든 Unit 완료 후

### Phase 5: Operations (지속적)
8. **프롬프트 18**: 품질 모니터링 및 개선 루프

---

## 참고 문서

- `docs/aidlc-docs/methodology-comparison-report.md`: 아키텍처 선정 보고서
- `docs/aidlc-docs/ai-dlc-whitepaper-ko.md`: AI-DLC 방법론 정의
- `.claude/agents/*.md`: 현재 에이전트 프롬프트
- `scripts/content-generator-v6.sh`: 현재 오케스트레이션 스크립트
- `test/test-*.mjs`: 파서 테스트 (품질 기준)

---

**작성일**: 2025-10-16
**총 프롬프트 수**: 18개
**예상 총 기간**: 4-6주
