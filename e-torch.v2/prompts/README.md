# E-Torch AI-DLC 프롬프트

**프로젝트**: E-Torch 경제지표 대시보드
**아키텍처**: BFF (Backend-for-Frontend) + Feature Module Architecture
**방법론**: AI-DLC (AI-Driven Development Lifecycle)

---

## 프롬프트 목록

### 1단계: 기획 (Inception)

- **01-architect-role.md** - 시스템 아키텍트 역할 부여
- **02-inception-user-stories.md** - 사용자 스토리 작성
- **03-inception-units.md** - Feature Module로 그룹화

### 2단계: 구축 (Construction)

- **04-construction-feature-module.md** - Feature Module 설계
- **05-construction-bff-api.md** - BFF API 설계
- **06-construction-implementation-plan.md** - 구현 계획 수립
- **07-construction-implementation.md** - 실제 구현 (선택적)

### 3단계: 품질 보증 (Operations)

- **08-operations-test-plan.md** - 테스트 계획 수립
- **09-operations-deployment.md** - 배포 및 모니터링 계획

---

## 사용 방법

1. **순차 진행**: 01번부터 09번까지 순서대로 진행
2. **Feature Module 지정**: 04-08번은 구체적인 Feature Module 지정 필요
3. **계획-승인-실행**: 모든 프롬프트는 계획 → 검토 → 승인 → 실행 패턴

---

## 핵심 원칙

### DDD 패턴 미사용
- ❌ Aggregate Root, Repository, Domain Events
- ✅ TypeScript Interface + Zod Schema + TanStack Query + React Components

### 코드 생성 제어
- Inception (01-03): 코드 생성 금지
- Construction 설계 (04-06): 코드 생성 금지
- Construction 구현 (07): 사용자 요청 시만 코드 생성
- Operations (08-09): 코드 생성 금지

---

## 산출물 구조

```
docs/aidlc-docs/
├── inception/
│   ├── user_stories.md
│   └── units/
│       ├── {module-name}.md
│       └── integration_contract.md
├── construction/
│   └── {module-name}/
│       ├── feature_module_design.md
│       ├── bff_api_design.md
│       ├── implementation_plan.md
│       └── implementation_progress.md (구현 시)
└── operations/
    ├── {module-name}/
    │   └── test_plan.md
    ├── deployment_plan.md
    └── monitoring_plan.md
```

---

## 추가 자료

- **prompts.example.md** - 프롬프트 작성 예시 형식
