# 프롬프트 5: Construction - 에이전트 프롬프트 개선

```bash
단계 2.3: 에이전트 프롬프트 개선

당신의 역할: 당신은 전문 소프트웨어 엔지니어로서, Filter 계약 명세에 따라 기존 에이전트 프롬프트를 개선하여 명시적 I/O 계약, 품질 기준, Work Request Marker 처리를 추가하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(aidlc-docs/construction/plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요. 어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제: 기존 에이전트 프롬프트를 개선하세요. 다음 파일들을 참조하세요:
- `.claude/agents/{filter-name}.md` (기존 프롬프트)
- `aidlc-docs/construction/filters/{filter-name}-contract.md` (Filter 계약)
- `.claude/handoff-guide.md` (개선 가이드)

각 에이전트에 대해 기존 .claude/agents/{filter-name}.md 파일을 읽고, 다음 섹션을 추가/개선하세요:

**개선 체크리스트:**
1. 기존 강점 유지: 효과적인 부분, 예시, 가이드라인 보존
2. Filter 계약 통합:
   - 입력 계약 섹션 추가
   - 출력 계약 섹션 추가
   - Work Status Markers 업데이트 로직 추가
3. 품질 기준 강화:
   - 품질 보증 섹션 추가
   - 파서 테스트 참조
   - 자체 점검 체크리스트
4. 주의사항 명확화:
   - 절대 금지 항목
   - 반드시 준수 항목

**검증:**
```bash
# 변경 사항 확인
git diff .claude/agents/{filter-name}.md

# 테스트 실행
npx tsx test/test-{filter}.mjs public/content/ko/**/*.md
```

**중요**: 기존 프롬프트를 완전히 새로 작성하지 마세요. Filter 계약에 맞춰 명시성만 추가하세요.
```
