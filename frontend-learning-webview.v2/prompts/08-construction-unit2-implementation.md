# 프롬프트 08: Construction - Unit 2 구현

```bash
단계 2.3: 논리적 설계 기반 구현

당신의 역할: 당신은 전문 소프트웨어 엔지니어로서, 논리적 설계에 따라 Filter 계약 문서를 생성하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요.
어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수
있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와
승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를
완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

Unit 2에만 집중하세요.

당신의 과제: 논리적 설계 세부사항은 aidlc-docs/construction/unit-02-filter-contracts/logical_design.md 파일을 참조하세요.

7개 Filter 각각에 대해 계약 문서를 생성하세요:
- content-initiator
- overview-writer
- concepts-writer
- visualization-writer
- practice-writer
- quiz-writer
- content-validator

참고 문서:
- .claude/agents/*.md (현재 에이전트 프롬프트)
- test/test-*.mjs (파서 테스트 - 품질 기준)
- public/content/ko/*/01-*.md (샘플 콘텐츠)
- docs/aidlc-docs/specifications/work-status-markers-spec.md (Unit 1 산출물)

각 Filter 계약 문서를 다음 위치에 생성하세요:
- docs/aidlc-docs/specifications/contracts/{filter-name}-contract.md
```
