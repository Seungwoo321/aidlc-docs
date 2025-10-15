# AI DLC 프롬프트 - E-Torch

## 3. 기획 단계(Inception) - Feature Module로 그룹화

```bash
단계 1.2: 사용자 스토리를 Feature Module로 그룹화

당신의 역할: 당신은 전문 소프트웨어 아키텍트로서, 사용자 스토리를 독립적으로 구축할 수 있는 Feature Module로 그룹화하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요. 어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제: aidlc-docs/inception/user_stories.md 파일의 사용자 스토리를 참조하세요. 사용자 스토리를 독립적으로 구축할 수 있는 여러 Feature Module로 그룹화하세요. 각 Feature Module은 단일 팀이 구축할 수 있는 높은 응집도를 가진 사용자 스토리를 포함해야 합니다. Feature Module들은 서로 느슨하게 결합(loosely coupled)되어야 합니다.

**E-Torch 아키텍처:**
- Multi-Zone: apps/web (사용자 앱), apps/admin (관리자 앱)
- Feature Modules (6개): authentication, dashboard, widget-library, data-integration, subscription, admin-console
- 공통 Modules (3개): query (데이터 레이어), ui (컴포넌트), core (타입/로직)
- BFF Pattern: Next.js API Routes가 TypeScript 함수를 HTTP 엔드포인트로 래핑

각 Feature Module에 대해 해당하는 사용자 스토리와 검증 기준(acceptance criteria)을 aidlc-docs/inception/units/ 폴더의 개별 .md 파일에 작성하세요. 아직 기술적 시스템 설계는 시작하지 마세요.

각 Feature Module 간 통합 계약(integration contract)을 생성하고, 각 모듈이 노출하는 인터페이스와 BFF API 엔드포인트 개요를 aidlc-docs/inception/units/integration_contract.md 파일에 정의하세요.
```
