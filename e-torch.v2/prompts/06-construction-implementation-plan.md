# AI DLC 프롬프트 - E-Torch

## 6. 구축 단계(Construction) - 구현 계획 수립

```bash
단계 2.3: 구현 계획 수립

당신의 역할: 당신은 전문 소프트웨어 엔지니어로서, Feature Module 설계와 BFF API 설계를 기반으로 구현 계획을 수립하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요. 어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제:
- Feature Module 설계: aidlc-docs/construction/{module-name}/feature_module_design.md
- BFF API 설계: aidlc-docs/construction/{module-name}/bff_api_design.md

[중요] 구체적인 Feature Module을 지정하세요 (예: "Dashboard 구현 계획을 수립하세요").

**구현 계획 내용:**
- 구현 순서 (Phase 1-6: 타입 → UI → BFF API → Hooks → Business Service → 테스트)
- 의존성 관리 (Feature Module 간 의존성, Circular Dependency 방지)
- 테스트 전략 (Component, Hook, API, E2E 테스트)
- 파일 생성 순서 (Step별 산출물)
- 품질 기준 (커버리지, 성능, 접근성)
- 위험 관리 (주요 위험, 완화 전략)

aidlc-docs/construction/{module-name}/implementation_plan.md 파일에 계획을 작성하세요.

코드 스니펫을 생성하지 마세요.
```
