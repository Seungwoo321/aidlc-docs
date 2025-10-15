# AI DLC 프롬프트 - E-Torch

## 7. 구축 단계(Construction) - 실제 구현 (선택적)

```bash
단계 2.4: 실제 구현 (선택적)

⚠️ 중요: 이 단계는 사용자가 명시적으로 요청할 때만 진행하세요.
         설계 문서 검증이 완료된 후에만 실행합니다.

당신의 역할: 전문 풀스택 엔지니어로서, Feature Module 설계와 BFF API 설계를 기반으로 실제 코드를 구현하는 업무를 담당합니다.

앞으로의 작업을 계획하고 docs/aidlc-docs/construction/{module-name}/implementation_progress.md 파일에 진행 상황을 기록하세요. 각 단계를 완료할 때마다 체크박스를 완료로 표시하세요.

당신의 과제:
- 구현 계획: docs/aidlc-docs/construction/{module-name}/implementation_plan.md
- Feature Module 설계: docs/aidlc-docs/construction/{module-name}/feature_module_design.md
- BFF API 설계: docs/aidlc-docs/construction/{module-name}/bff_api_design.md

[중요] 구체적인 Feature Module과 Phase 지정:
예: "Widget Library Feature Module의 Phase 1 (타입 정의)을 구현하세요."
예: "Widget Library Feature Module의 Phase 2 (React Components)를 구현하세요."

## 구현 가이드라인

### 기술 스택
- TypeScript Strict mode, React 19, Next.js 15
- TanStack Query (서버 상태)
- Supabase 직접 호출 (Repository 패턴 미사용)
- Zod Schema (런타임 검증)

### DDD 패턴 미사용
- Aggregate Root, Repository, Domain Events 사용 금지
- TypeScript Interface + Zod Schema 사용
- React Components + TanStack Query Hooks 사용

## 구현 순서

**Phase 1: 타입 정의 + Zod Schema (1일)**
- packages/{module-name}/src/types/*.ts 생성
- packages/{module-name}/src/utils/validators.ts 생성 (Zod)

**Phase 2: React Components - UI만 (2-3일)**
- packages/{module-name}/src/components/*.tsx 생성
- 하드코딩 데이터로 UI 렌더링

**Phase 3: BFF API Routes + Supabase (2일)**
- apps/web/app/api/{resource}/route.ts 생성
- Supabase RLS 정책 설정

**Phase 4: TanStack Query Hooks (2일)**
- packages/{module-name}/src/hooks/*.ts 생성
- React Components와 BFF API 연결

**Phase 5: Business Service - 선택적 (1일)**
- packages/query/src/services/*BusinessService.ts 생성

**Phase 6: 테스트 작성 (2-3일)**
- Component 테스트 (Vitest + Testing Library)
- Hook 테스트 (Vitest)
- API 테스트 (Vitest + MSW)
- E2E 테스트 (Playwright, 핵심 시나리오만)

## 산출물

실제 프로젝트 경로에 구현 파일을 생성하세요:
- packages/{module-name}/src/**/*.ts(x)
- apps/web/app/api/{module-name}/**/*.ts

진행 상황을 기록하세요:
- docs/aidlc-docs/construction/{module-name}/implementation_progress.md

## 이 단계에서는 코드를 생성합니다

Phase별로 실제 구현 코드를 생성하세요. 단, 사용자가 명시적으로 요청할 때만 진행합니다.
```
