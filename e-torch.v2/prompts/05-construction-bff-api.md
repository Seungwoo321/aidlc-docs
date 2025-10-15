# AI DLC 프롬프트 - E-Torch

## 5. 구축 단계(Construction) - BFF API 설계

```bash
단계 2.2: BFF API 설계

당신의 역할: 당신은 전문 백엔드 아키텍트로서, Next.js API Routes를 사용하여 BFF (Backend-for-Frontend) API를 설계하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요. 어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제:
- Feature Module 설계: aidlc-docs/construction/{module-name}/feature_module_design.md
- 통합 계약: aidlc-docs/inception/units/integration_contract.md

[중요] authentication BFF API에만 집중하세요

**BFF API 설계 원칙:**
- Thin API Layer (비즈니스 로직 최소화)
- Repository 패턴 미사용 (Supabase 직접 호출)
- RESTful API 설계 (GET, POST, PATCH, DELETE)
- Supabase RLS (Row Level Security) 활용

**설계 내용:**
- API 엔드포인트 정의 (HTTP Method, Path, Request/Response)
- Supabase 쿼리 최적화 (RLS 정책, 인덱스, 페이지네이션)
- 미들웨어 설계 (인증, 에러 핸들링)
- 파일 구조 (apps/web/app/api/)

aidlc-docs/construction/{module-name}/bff_api_design.md 파일에 설계를 작성하세요.

코드 스니펫을 생성하지 마세요.
```
