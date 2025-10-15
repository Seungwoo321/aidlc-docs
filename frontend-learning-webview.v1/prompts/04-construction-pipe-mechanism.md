# 프롬프트 4: Construction - Pipe 메커니즘 설계

```bash
단계 2.2: Pipe 메커니즘 설계 (논리적 설계)

당신의 역할: 당신은 전문 소프트웨어 아키텍트로서, Pipeline Architecture의 Filter 간 데이터 전달 메커니즘(Pipe)을 설계하고, 현재 방식(Work Status Markers)의 개선안을 제시하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(aidlc-docs/construction/plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요. 어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제: Filter 간 데이터 전달 방식을 설계하세요. 다음 파일들을 참조하세요:
- aidlc-docs/construction/filters/*-contract.md (Filter 계약 문서)
- 현재 Work Status Markers 방식

aidlc-docs/construction/pipe-mechanism.md 파일에 다음을 작성하세요:

**Pipe 메커니즘 설계 내용:**
1. 현재 방식 분석: Work Status Markers 장점/단점
2. 대안 옵션:
   - 옵션 A: Work Status Markers 강화 (구조, 장단점, 구현 복잡도)
   - 옵션 B: JSON 메타데이터 분리 (구조, 장단점, 구현 복잡도)
   - 옵션 C: 중간 파일 생성 (구조, 장단점, 구현 복잡도)
3. 권장 로드맵: Phase 1 (즉시), Phase 2 (3개월), Phase 3 (6개월)
4. Pipe 동작 방식: Filter 실행 전/중/후

의사코드만 작성하세요. 실제 코드는 생성하지 마세요.
```
