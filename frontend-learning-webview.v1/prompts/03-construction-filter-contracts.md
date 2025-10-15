# 프롬프트 3: Construction - Filter 계약 명시화

```bash
2단계: 시스템 개선 구축 (Construction)
단계 2.1: Filter 계약 명시화 (도메인 설계)

당신의 역할: 당신은 전문 소프트웨어 아키텍트로서, 현재 작동 중인 7개 서브에이전트의 암묵적 계약을 분석하여 Pipeline Architecture의 명시적 Filter 계약으로 문서화하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(aidlc-docs/construction/plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요. 어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제: 기존 에이전트 프롬프트를 분석하여 명시적 Filter 계약을 추출하세요. 다음 파일들을 참조하세요:
- `.claude/agents/*.md` (7개 에이전트 프롬프트 파일)
- `test/test-*.mjs` (각 에이전트의 품질 기준)
- `public/content/ko/{category}/{subcategory}/*.md` (실제 산출물 샘플)

aidlc-docs/ 디렉터리에 /construction/ 폴더를 생성하고, aidlc-docs/construction/filters/ 폴더에 각 Filter에 대한 계약 문서를 작성하세요. 각 Filter 계약 문서에는 다음을 포함하세요:

**각 Filter 계약 문서 구조:**
1. 입력 계약: 파일 경로, 필수 섹션, Work Status Markers, 선행 조건
2. 출력 계약: 생성 섹션, 구조, 최소 길이, Work Status Markers 업데이트
3. 품질 기준: 파서 테스트 항목, 검증 체크리스트
4. 오류 처리: 오류 유형, 재시도 전략
5. 성능 기준: 평균 처리 시간, 출력 크기

**통합 문서:**
aidlc-docs/construction/filter-contracts-summary.md 파일에 7개 Filter의 계약을 표 형식으로 요약하세요.

**중요**: 새로운 계약을 만들지 마세요. 기존 에이전트 프롬프트와 파서 테스트에서 역공학으로 추출하세요.

코드 스니펫을 생성하지 마세요. 계약 명세 문서화에만 집중하세요.
```
