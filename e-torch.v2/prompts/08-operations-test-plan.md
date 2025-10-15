# AI DLC 프롬프트 - E-Torch

## 8. 품질 보증 단계(Operations) - 테스트 계획 수립

```bash
3단계: 품질 보증 (Operations)
단계 3.1: 테스트 계획 수립

당신의 역할: 전문 품질 보증 엔지니어로서, Feature Module과 BFF API의 테스트 계획을 생성하는 업무를 담당합니다.

앞으로의 작업을 계획하고 docs/aidlc-docs/operations/{module-name}/plan_test.md 파일에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요.

어떤 단계든 제가 확인이 필요한 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요.

계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제:
- 사용자 스토리: docs/aidlc-docs/inception/units/{module-name}.md
- Feature Module 설계: docs/aidlc-docs/construction/{module-name}/feature_module_design.md
- BFF API 설계: docs/aidlc-docs/construction/{module-name}/bff_api_design.md
- 구현 계획: docs/aidlc-docs/construction/{module-name}/implementation_plan.md

[중요] 구체적인 Feature Module 지정:
예: "Widget Library 테스트 계획을 수립하세요."

## 프론트엔드 중심 테스트 전략

**1. Component 테스트 (Vitest + Testing Library)**
- React 컴포넌트 렌더링 및 사용자 인터랙션 검증
- 커버리지 목표: 80% Statement

**2. TanStack Query Hook 테스트 (Vitest)**
- 데이터 페칭, 캐싱, Mutation 로직 검증
- MSW (Mock Service Worker)로 API 모킹
- 커버리지 목표: 90% Function

**3. BFF API 테스트 (Vitest + MSW)**
- API 엔드포인트 Request/Response 검증
- 인증, Validation, 권한, 에러 처리 검증
- 커버리지 목표: 85% Function

**4. E2E 테스트 (Playwright)**
- 핵심 사용자 시나리오 검증 (10-15개)
- Cross-browser 테스트 (Chrome, Firefox, Safari)

**5. 성능 테스트**
- 차트 렌더링: < 2초 (40,000+ 데이터포인트)
- 초기 로드 (LCP): < 2.5초
- API 응답: < 500ms (p95)

## 산출물

docs/aidlc-docs/operations/{module-name}/test_plan.md 파일에 다음을 포함하세요:

1. 테스트 전략 개요 (테스트 레벨, 도구, 커버리지 목표)
2. Component 테스트 계획 (테스트 대상, 케이스 작성 기준)
3. TanStack Query Hook 테스트 계획 (테스트 대상, MSW 모킹 전략)
4. BFF API 테스트 계획 (엔드포인트, 테스트 케이스, Supabase 모킹)
5. E2E 테스트 계획 (핵심 시나리오, Cross-browser 전략)
6. 성능 테스트 계획 (성능 목표, 측정 방법)
7. 테스트 자동화 (CI/CD 통합)
8. 테스트 커버리지 (목표 및 보고서)

코드 스니펫을 생성하지 마세요. 계획 문서만 작성하세요.
```
