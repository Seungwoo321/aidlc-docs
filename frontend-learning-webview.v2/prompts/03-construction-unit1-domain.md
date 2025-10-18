# 프롬프트 03: Construction - Unit 1 도메인 설계

```bash
2단계: Unit 1 구축 (Construction)
단계 2.1: DDD를 사용한 도메인 모델 설계

당신의 역할: 당신은 전문 소프트웨어 아키텍트로서, Unit 1에 대해 DDD 경량화 방식을 사용하여
도메인 모델을 설계하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요.
어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수
있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와
승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를
완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

Unit 1에만 집중하세요.

당신의 과제: aidlc-docs/inception/units/ 폴더를 참조하세요. Unit 1 md 파일에는 개선 목표와 범위가
정의되어 있습니다.

DDD 경량화 방식으로 Pipe 메커니즘 도메인 모델을 설계하세요:
- Bounded Context: Work Status Markers의 책임 경계
- Ubiquitous Language: Work Status Markers, HANDOFF LOG, STATUS, CURRENT_AGENT
- Domain Events: PipelineStartedEvent, AgentCompletedEvent, AgentImprovedEvent 등
- Handoff Protocol: 에이전트 간 핸드오프 규칙
- Aggregate, Entity, Repository 같은 전술적 패턴은 사용하지 마세요

aidlc-docs/ 디렉터리에 새로운 /construction/ 폴더를 생성하고,
aidlc-docs/construction/unit-01-pipe-mechanism/domain_design.md 파일에 설계 세부사항을 작성하세요.

코드 스니펫을 생성하지 마세요.
```
