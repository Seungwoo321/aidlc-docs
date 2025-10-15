# AI-DLC 개발 프롬프트 생성기

## 개요

이 프롬프트는 아키텍처 선정 보고서를 기반으로, 해당 프로젝트의 개발에 사용할 AI-DLC 방법론 적용 프롬프트를 자동 생성합니다.

---

## 프롬프트

```
당신의 역할: 당신은 AI-DLC 방법론 전문가입니다.

## 임무

다음 문서들을 읽고 분석하여, 프로젝트 개발을 위한 AI-DLC 단계별 프롬프트를 생성하세요:

**입력 문서:**
1. `docs/aidlc-docs/ai-dlc-whitepaper-ko.md` - AI-DLC 방법론 이해
2. `docs/aidlc-docs/methodology-comparison-report.md` - 프로젝트 및 선정된 아키텍처
3. `docs/aidlc-docs/prompts.example.md` - 프롬프트 형식 참조

**작업 순서:**

### 1단계: 컨텍스트 파악

다음을 읽고 이해하세요:
- AI-DLC의 3단계: Inception (의도→유닛), Construction (도메인→논리→코드), Operations (배포→모니터링)
- 보고서의 선정된 아키텍처와 그 이유
- 프로젝트의 시스템명, 배경, 목표, 기술 스택, 비기능 요구사항
- prompts.example.md의 프롬프트 작성 패턴 (역할 정의, 계획 수립, [Question]/[Answer], 승인 후 실행)

### 2단계: 프롬프트 생성

다음 프롬프트들을 **prompts.example.md 형식을 따라** 생성하세요:

**필수 프롬프트:**
1. **시스템 아키텍트 역할 부여** - 프로젝트 컨텍스트 설정
2. **Inception: 사용자 스토리 작성** - 비즈니스 의도를 스토리로
3. **Inception: 유닛 분해** - 선정된 아키텍처 원칙에 따라 유닛으로 그룹화
4. **Construction: 도메인 설계** - 아키텍처별 도메인 모델링
5. **Construction: 논리적 설계** - NFR과 패턴 적용
6. **Construction: 시스템 구현** - 실제 코드 생성
7. **Operations: 배포 자동화** - 인프라 및 CI/CD
8. **Operations: 모니터링** - 관찰 가능성 확보
9. **회고 및 다음 Bolt** - 반복 개선

**각 프롬프트 작성 시 반드시 포함:**
- `당신의 역할: ...` (prompts.example.md 패턴)
- `앞으로의 작업을 계획하고 md 파일에...` (prompts.example.md 패턴)
- `[Question]/[Answer]` 태그 사용 안내 (prompts.example.md 패턴)
- `계획 완료 후 사용자 승인 요청` (prompts.example.md 패턴)
- `당신의 과제:` 섹션에 **보고서의 구체적 내용 반영**
- **선정된 아키텍처**의 용어와 패턴 (예: Pipeline→Filter/Pipe, DDD→Bounded Context/Aggregate)
- **코드 생성 제어**:
  * Inception 단계: "코드 스니펫을 생성하지 마세요"
  * Construction 도메인/논리: "의사코드만 가능, 실제 코드 X"
  * Construction 구현 이후: "실제 코드 생성"

### 3단계: 출력

생성한 프롬프트를 다음과 같이 저장하세요:

1. 개별 파일로 저장:
   - `aidlc-docs/prompts/01-architect-role.md`
   - `aidlc-docs/prompts/02-inception-user-stories.md`
   - `aidlc-docs/prompts/03-inception-units.md`
   - `aidlc-docs/prompts/04-construction-domain.md`
   - `aidlc-docs/prompts/05-construction-logical.md`
   - `aidlc-docs/prompts/06-construction-implementation.md`
   - `aidlc-docs/prompts/07-operations-deployment.md`
   - `aidlc-docs/prompts/08-operations-monitoring.md`
   - `aidlc-docs/prompts/09-retrospective.md`

2. 통합 파일로 저장:
   - `aidlc-docs/prompts/[선정된_아키텍처]-prompts.md`
   - 예: `pipeline-architecture-prompts.md`, `ddd-prompts.md`

3. 사용 가이드 생성:
   - `aidlc-docs/prompts/usage-guide.md`
   - 프롬프트 실행 순서, 소요 시간, 팁 포함

**완료 후 사용자에게 보고:**
**단, 3단계의 프롬프트 구조 및 내용은 선택된 아키텍처에 맞게 판단해서 변형 가능합니다.**
```
생성 완료:
- 프롬프트 9개 생성
- 아키텍처: [선정된 아키텍처]
- 통합 파일: [파일명]

각 프롬프트는 보고서의 [시스템명], [기술 스택], [NFR]을 반영했습니다.
검토 후 피드백 주시면 수정하겠습니다.
```

지금 시작하세요.
```

---

## 사용 방법

1. 아키텍처 선정 보고서 작성 완료 (`final-report.md`)
2. 이 프롬프트를 AI에게 제공
3. AI가 보고서 분석 → 프롬프트 9개 생성
4. 생성된 프롬프트로 실제 개발 진행

---

## 예시

### 입력 (보고서에서)
```
선정된 아키텍처: Pipeline Architecture
시스템명: 학습 콘텐츠 자동화 시스템
기술 스택: TypeScript, Node.js
```

### 출력 (AI가 생성한 프롬프트 3)
```markdown
# 프롬프트 3: Inception - 유닛 분해

당신의 역할: 전문 소프트웨어 아키텍트로서, 사용자 스토리를 Pipeline Architecture의 원칙에 따라 독립적으로 구축 가능한 유닛으로 그룹화합니다.

앞으로의 작업을 계획하고 aidlc-docs/inception/units_plan.md 파일에...

당신의 과제:
- 시스템: 학습 콘텐츠 자동화 시스템
- 아키텍처: Pipeline Architecture
- 유닛 분해 원칙:
  * Filter 단위로 분해 (각 Filter는 독립적 데이터 변환 단계)
  * 명확한 입력/출력 계약 정의
  * Pipeline 순서에 따른 의존성 명시

입력 문서: aidlc-docs/inception/user_stories.md

출력: aidlc-docs/inception/units/*.md

코드 스니펫을 생성하지 마세요.
```
→ 보고서의 내용이 자동으로 반영됨!
