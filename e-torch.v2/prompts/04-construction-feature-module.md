# AI DLC 프롬프트 - E-Torch

## 4. 구축 단계(Construction) - Feature Module 설계

```bash
2단계: 하나의 Feature Module 구축 (Construction)
단계 2.1: Feature Module 설계

당신의 역할: 당신은 전문 소프트웨어 아키텍트로서, BFF + Feature Module 아키텍처를 사용하여 Feature Module을 설계하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요. 어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제: aidlc-docs/inception/units/{module-name}.md 파일의 사용자 스토리를 참조하세요.

[중요] Dashboard Feature Module에만 집중하세요.

**DDD 패턴을 사용하지 마세요:**
- Aggregate Root, Repository, Domain Events 사용 금지
- TypeScript Interface + Zod Schema 사용
- React Components + TanStack Query Hooks 사용
- Supabase 클라이언트 직접 호출

**설계 내용:**
- 타입 정의 (TypeScript Interface, Zod Schema)
- React Components Tree (컴포넌트 계층 구조, Props, 상태 관리)
- TanStack Query Hooks (Data Fetching, Mutation, 캐싱 전략)
- Business Logic (복잡한 검증만, 선택적)
- 파일 구조 (packages/{module-name}/ 디렉토리)
- 의존성 (내부/외부)

aidlc-docs/ 디렉터리에 새로운 /construction/{module-name}/ 폴더를 생성하고, aidlc-docs/construction/{module-name}/feature_module_design.md 파일에 설계 세부사항을 작성하세요.

코드 스니펫을 생성하지 마세요.
```
