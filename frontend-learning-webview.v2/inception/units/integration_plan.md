# Integration Plan: 유닛 간 통합 계약 및 실행 순서

## 개요

본 문서는 5개 개선 유닛 간의 의존성, 통합 계약, 실행 순서를 정의합니다. 각 유닛은 독립적으로 구축 가능하지만, 최종 통합 시 명확한 인터페이스와 순서를 따라야 합니다.

## 유닛 개요

| 유닛 ID | 유닛명 | 주요 산출물 | 예상 기간 |
|---------|--------|-------------|-----------|
| Unit 1 | Pipe Mechanism 표준화 | Work Status Markers 명세, 파싱/생성 유틸리티 | 5일 |
| Unit 2 | Filter Contracts 명시화 | 에이전트별 입출력 계약, 검증 스크립트 | 7일 |
| Unit 3 | Agent Prompts 개선 | 업데이트된 에이전트 프롬프트 (7개) | 7일 |
| Unit 4 | Orchestration 개선 | content-generator-v7.sh, 모듈화된 라이브러리 | 8-10일 |
| Unit 5 | Quality Metrics 구축 | 품질 측정 스크립트, 리포트 생성기, 대시보드 | 9일 |

**총 예상 기간**: 36-38일 (순차 실행 시) 또는 10-12일 (병렬 실행 시)

## 의존성 그래프

```
Unit 1: Pipe Mechanism
    ↓
    ├─→ Unit 2: Filter Contracts
    │       ↓
    │       └─→ Unit 3: Agent Prompts
    │               ↓
    │               └─→ Unit 4: Orchestration
    │                       ↓
    │                       └─→ Unit 5: Quality Metrics
    └─────────────────────────────────────────→ Unit 5 (직접 의존)
```

### 의존성 상세

#### Unit 1 → Unit 2
- **제공**: Work Status Markers 명세
- **사용**: Filter Contracts가 입출력 조건으로 마커 필드 참조
- **인터페이스**: `docs/aidlc-docs/specifications/work-status-markers-spec.md`

#### Unit 2 → Unit 3
- **제공**: 에이전트별 입출력 계약
- **사용**: Agent Prompts가 계약을 프롬프트에 통합
- **인터페이스**: `docs/aidlc-docs/specifications/contracts/[agent-name]-contract.md`

#### Unit 3 → Unit 4
- **제공**: 개선된 에이전트 프롬프트
- **사용**: Orchestration이 업데이트된 프롬프트 실행
- **인터페이스**: `.claude/agents/[agent-name].md`

#### Unit 4 → Unit 5
- **제공**: 실행 로그, execution-summary.json
- **사용**: Quality Metrics가 로그 분석하여 품질 트렌드 생성
- **인터페이스**: `logs/sessions/[session-id]/execution-summary.json`

#### Unit 1 → Unit 4
- **제공**: 마커 파싱/생성 유틸리티
- **사용**: Orchestration이 유틸리티 함수 호출
- **인터페이스**: `scripts/lib/work-status-markers.sh`

#### Unit 2 → Unit 4
- **제공**: 계약 검증 스크립트
- **사용**: Orchestration이 에이전트 실행 전후 검증
- **인터페이스**: `scripts/lib/contract-validator.sh`

#### Unit 1 → Unit 5
- **제공**: VALIDATION_SCORE 필드 정의
- **사용**: Quality Metrics가 점수를 마커에 기록
- **인터페이스**: Work Status Markers 명세

## 통합 계약 (Integration Contracts)

### Contract 1: Unit 1 → Unit 2
**명칭**: Marker Specification Contract

**Unit 1 제공**:
```yaml
work-status-markers-spec:
  location: docs/aidlc-docs/specifications/work-status-markers-spec.md
  version: 1.0
  provides:
    - field_definitions:
        required: [CURRENT_AGENT, PROGRESS, STARTED, UPDATED, HANDOFF_LOG]
        optional: [VALIDATION_SCORE, IMPROVEMENT_NEEDED]
    - format_specification:
        timestamp: ISO 8601
        handoff_log_entry: "[STATUS] agent-name: message - timestamp"
```

**Unit 2 사용**:
- 에이전트 입출력 계약에서 Work Status Markers 필드를 전제 조건(Precondition)으로 사용
- 예: `overview-writer`의 Precondition: `CURRENT_AGENT: overview-writer`

**검증 방법**:
```bash
# Unit 2는 Unit 1의 명세 파일 존재 확인
test -f docs/aidlc-docs/specifications/work-status-markers-spec.md
```

---

### Contract 2: Unit 1 → Unit 4
**명칭**: Marker Utilities Contract

**Unit 1 제공**:
```bash
# scripts/lib/work-status-markers.sh
parse_work_status_markers() { ... }
write_work_status_markers() { ... }
validate_work_status_markers() { ... }
append_handoff_log() { ... }
update_current_agent() { ... }
```

**Unit 4 사용**:
```bash
# content-generator-v7.sh
source scripts/lib/work-status-markers.sh

# 마커 읽기
markers=$(parse_work_status_markers "$file_path")
current_agent=$(echo "$markers" | grep "^CURRENT_AGENT=" | cut -d= -f2)

# 마커 업데이트
update_current_agent "$file_path" "concepts-writer"
append_handoff_log "$file_path" "DONE" "overview-writer" "완료"
```

**검증 방법**:
```bash
# Unit 4는 Unit 1의 유틸리티 함수 실행 가능 확인
source scripts/lib/work-status-markers.sh
type parse_work_status_markers | grep -q "function"
```

---

### Contract 3: Unit 2 → Unit 3
**명칭**: Agent Contract Integration

**Unit 2 제공**:
```yaml
agent-contract:
  location: docs/aidlc-docs/specifications/contracts/[agent-name]-contract.md
  version: 1.0
  provides:
    - input_contract: {preconditions, expected_file_state, expected_markers}
    - output_contract: {postconditions, file_modifications, marker_updates}
```

**Unit 3 사용**:
- 에이전트 프롬프트의 "Input Contract" 섹션에 Unit 2 계약 요약 포함
- 에이전트 프롬프트의 "Output Contract" 섹션에 Unit 2 계약 요약 포함

**검증 방법**:
```bash
# Unit 3의 프롬프트가 Unit 2 계약 참조하는지 확인
for agent in content-initiator overview-writer concepts-writer visualization-writer practice-writer quiz-writer content-validator; do
    grep -q "Input Contract" .claude/agents/$agent.md || echo "Missing Input Contract in $agent"
    grep -q "Output Contract" .claude/agents/$agent.md || echo "Missing Output Contract in $agent"
done
```

---

### Contract 4: Unit 2 → Unit 4
**명칭**: Contract Validation Contract

**Unit 2 제공**:
```bash
# scripts/lib/contract-validator.sh
validate_preconditions() {
    local agent_name=$1
    local file_path=$2
    # 계약 파일에서 preconditions 읽고 검증
}

validate_postconditions() {
    local agent_name=$1
    local file_path=$2
    # 계약 파일에서 postconditions 읽고 검증
}
```

**Unit 4 사용**:
```bash
# content-generator-v7.sh
source scripts/lib/contract-validator.sh

execute_agent_with_validation() {
    local agent_name=$1
    local file_path=$2

    # Precondition 검증
    validate_preconditions "$agent_name" "$file_path" || return 1

    # 에이전트 실행
    execute_claude_agent "$agent_name" "$file_path"

    # Postcondition 검증
    validate_postconditions "$agent_name" "$file_path" || return 1
}
```

**검증 방법**:
```bash
# Unit 4가 Unit 2의 검증 함수 호출 가능 확인
source scripts/lib/contract-validator.sh
type validate_preconditions | grep -q "function"
```

---

### Contract 5: Unit 3 → Unit 4
**명칭**: Prompt Execution Contract

**Unit 3 제공**:
```yaml
agent-prompt:
  location: .claude/agents/[agent-name].md
  version: 6.0 (업데이트)
  provides:
    - frontmatter: {name, version, description, tools, model}
    - sections: [Role, Input Contract, Output Contract, Instructions, Constraints, Error Handling]
```

**Unit 4 사용**:
```bash
# content-generator-v7.sh
execute_claude_agent() {
    local agent_name=$1
    local file_path=$2

    # Unit 3의 업데이트된 프롬프트 실행
    claude -p "$agent_name agent 실행" --session-id "$session_id"
}
```

**검증 방법**:
```bash
# Unit 4는 Unit 3의 프롬프트 파일 존재 확인
for agent in content-initiator overview-writer concepts-writer visualization-writer practice-writer quiz-writer content-validator; do
    test -f .claude/agents/$agent.md || echo "Missing prompt: $agent.md"
done
```

---

### Contract 6: Unit 4 → Unit 5
**명칭**: Execution Log Contract

**Unit 4 제공**:
```json
{
  "session_id": "uuid",
  "start_time": "ISO 8601",
  "end_time": "ISO 8601",
  "target_file": "path",
  "status": "success|failed|partial",
  "agents_executed": [
    {
      "agent": "agent-name",
      "duration_seconds": 123,
      "status": "success|failed",
      "precondition_check": "passed|failed",
      "postcondition_check": "passed|failed"
    }
  ]
}
```

**Unit 5 사용**:
```bash
# scripts/generate-quality-dashboard.sh
for session_dir in logs/sessions/*; do
    summary_file="$session_dir/execution-summary.json"
    # JSON 파싱하여 트렌드 데이터 수집
done
```

**검증 방법**:
```bash
# Unit 5는 Unit 4의 로그 형식 파싱 가능 확인
test -f logs/sessions/*/execution-summary.json
jq . logs/sessions/*/execution-summary.json
```

---

### Contract 7: Unit 1 → Unit 5
**명칭**: Quality Score Storage Contract

**Unit 1 제공**:
```markdown
<!-- VALIDATION_SCORE: 87/100 -->
```

**Unit 5 사용**:
```bash
# scripts/measure-quality.sh
calculate_total_score() {
    local file=$1
    local score=$(calculate_score "$file")

    # Unit 1의 마커에 점수 기록
    sed -i "s/<!-- VALIDATION_SCORE: .* -->/<!-- VALIDATION_SCORE: $score\/100 -->/" "$file"
}
```

**검증 방법**:
```bash
# Unit 5가 마커에 점수 기록 가능 확인
grep -q "<!-- VALIDATION_SCORE: [0-9]\+/100 -->" public/content/ko/**/**.md
```

## 실행 순서 (Execution Order)

### 시나리오 1: 순차 실행 (Sequential Execution)
**적용 상황**: 단일 팀, 리스크 최소화, 각 유닛 완료 후 검증

**실행 순서**:
```
Week 1-2: Unit 1 (5일)
    ↓ 검증 및 승인
Week 3-4: Unit 2 (7일)
    ↓ 검증 및 승인
Week 5-6: Unit 3 (7일)
    ↓ 검증 및 승인
Week 7-8: Unit 4 (10일)
    ↓ 검증 및 승인
Week 9-10: Unit 5 (9일)
    ↓ 최종 통합 테스트
```

**총 기간**: 약 10주 (38일 + 검증 시간)

---

### 시나리오 2: 병렬 실행 (Parallel Execution)
**적용 상황**: 다수 팀, 빠른 완료, 높은 조율 필요

**Phase 1 (Week 1-2)**: Unit 1
- Unit 1 완료 (5일)
- Unit 1 검증 및 승인 (2일)

**Phase 2 (Week 3-4)**: Unit 2 + Unit 5 (일부)
- Unit 2 완료 (7일) [메인 경로]
- Unit 5 메트릭 명세 작성 (2일, Unit 1 의존성만) [병렬]

**Phase 3 (Week 5-6)**: Unit 3 + Unit 5 (계속)
- Unit 3 완료 (7일) [메인 경로]
- Unit 5 측정 스크립트 개발 (5일, Unit 1 의존성만) [병렬]

**Phase 4 (Week 7-8)**: Unit 4
- Unit 4 완료 (10일)

**Phase 5 (Week 9)**: Unit 5 통합 + 최종 테스트
- Unit 5 content-validator 통합 (2일)
- 전체 통합 테스트 (3일)

**총 기간**: 약 9주

---

### 시나리오 3: 점진적 롤아웃 (Incremental Rollout)
**적용 상황**: 운영 중인 시스템, 리스크 분산, 단계별 배포

**Milestone 1: Pipe 표준화 (Week 1-2)**
- Unit 1 완료
- 기존 시스템에 Unit 1 유틸리티 통합
- 기존 에이전트가 새 유틸리티 사용하도록 수정
- 프로덕션 배포 및 모니터링

**Milestone 2: Contract 명시화 (Week 3-5)**
- Unit 2 완료
- 계약 검증을 --validate 플래그로 선택적 실행
- 프로덕션 배포 (검증 비활성화)
- 검증 로그 수집 및 분석

**Milestone 3: Prompt 개선 (Week 6-8)**
- Unit 3 완료
- 1개 에이전트씩 업데이트 (7일)
- 각 업데이트 후 출력물 비교 테스트
- 프로덕션 배포

**Milestone 4: Orchestration 개선 (Week 9-11)**
- Unit 4 완료
- v6와 v7 동시 유지 (v6를 fallback)
- v7로 점진적 마이그레이션
- 프로덕션 배포

**Milestone 5: Quality 구축 (Week 12-14)**
- Unit 5 완료
- 품질 리포트 생성 (수동)
- 대시보드 배포
- content-validator 품질 측정 통합

**총 기간**: 약 14주 (안정성 최우선)

## 통합 테스트 계획

### Integration Test 1: Marker Utilities + Orchestration
**목적**: Unit 1과 Unit 4 통합 검증

**테스트 케이스**:
1. content-generator-v7.sh가 work-status-markers.sh 함수 호출 성공
2. 마커 파싱 결과가 정확함
3. 마커 업데이트가 올바르게 파일에 반영됨

**실행 방법**:
```bash
./test/test-integration-unit1-unit4.sh
```

---

### Integration Test 2: Contract Validation + Orchestration
**목적**: Unit 2와 Unit 4 통합 검증

**테스트 케이스**:
1. content-generator-v7.sh가 contract-validator.sh 호출 성공
2. Precondition 위반 시 에이전트 실행 중단
3. Postcondition 위반 시 명확한 오류 메시지

**실행 방법**:
```bash
./test/test-integration-unit2-unit4.sh
```

---

### Integration Test 3: Updated Prompts + Orchestration
**목적**: Unit 3과 Unit 4 통합 검증

**테스트 케이스**:
1. 업데이트된 프롬프트로 에이전트 실행 성공
2. 에이전트 출력물이 계약 준수
3. Work Status Markers 올바르게 업데이트

**실행 방법**:
```bash
./test/test-integration-unit3-unit4.sh
```

---

### Integration Test 4: Orchestration + Quality Metrics
**목적**: Unit 4와 Unit 5 통합 검증

**테스트 케이스**:
1. execution-summary.json 생성
2. 품질 측정 스크립트가 summary 파싱 성공
3. 품질 대시보드에 데이터 반영

**실행 방법**:
```bash
./test/test-integration-unit4-unit5.sh
```

---

### End-to-End Test: Full Pipeline
**목적**: 전체 유닛 통합 검증

**테스트 시나리오**:
1. 새 토픽 파일 생성 (content-initiator)
2. 7개 에이전트 순차 실행
3. 품질 측정 및 리포트 생성
4. 품질 점수 90점 이상 확인

**실행 방법**:
```bash
./test/test-e2e-full-pipeline.sh
```

## 롤백 계획 (Rollback Plan)

### 각 유닛별 롤백 전략

**Unit 1 롤백**:
- `scripts/lib/work-status-markers.sh` 삭제
- content-generator-v6.sh의 내장 파싱 로직으로 복원

**Unit 2 롤백**:
- `scripts/lib/contract-validator.sh` 삭제
- 계약 검증 호출 코드 제거

**Unit 3 롤백**:
- `.claude/agents/*.md` 파일을 Git에서 이전 버전으로 복원
- `git checkout HEAD~1 .claude/agents/`

**Unit 4 롤백**:
- `content-generator-v7.sh` 비활성화
- `content-generator-v6.sh` 재활성화
- 심볼릭 링크 변경: `ln -sf content-generator-v6.sh content-generator.sh`

**Unit 5 롤백**:
- 품질 측정 스크립트는 독립적이므로 영향 없음
- content-validator의 품질 측정 통합만 제거

## 리스크 및 완화 방안

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| Unit 간 인터페이스 불일치 | 높음 | 통합 계약 문서 엄격히 준수, 계약 검증 스크립트 작성 |
| 순차 실행으로 기간 장기화 | 중간 | 병렬 실행 가능 유닛 식별 (Unit 5 일부) |
| Unit 4 완료 지연 시 전체 지연 | 높음 | Unit 4를 작은 Milestone로 분할 |
| 통합 테스트 실패 | 높음 | 각 유닛별 단위 테스트 충분히 수행 |

## 마일스톤 및 체크포인트

### Milestone 1: Foundation (Unit 1 완료)
**날짜**: Week 2 종료
**체크포인트**:
- [ ] Work Status Markers 명세 작성 완료
- [ ] 마커 파싱/생성 유틸리티 개발 완료
- [ ] 유틸리티 단위 테스트 통과
- [ ] 기존 콘텐츠 파일의 마커 검증 통과

---

### Milestone 2: Contracts (Unit 2 완료)
**날짜**: Week 4 종료
**체크포인트**:
- [ ] 7개 에이전트 계약 작성 완료
- [ ] 계약 검증 스크립트 개발 완료
- [ ] 계약 위반 감지 테스트 통과
- [ ] 의존성 그래프 문서화 완료

---

### Milestone 3: Prompts (Unit 3 완료)
**날짜**: Week 6 종료
**체크포인트**:
- [ ] 프롬프트 템플릿 작성 완료
- [ ] 7개 에이전트 프롬프트 업데이트 완료
- [ ] 업데이트 전후 출력물 비교 테스트 통과
- [ ] 프롬프트 검증 체크리스트 통과

---

### Milestone 4: Orchestration (Unit 4 완료)
**날짜**: Week 8 종료
**체크포인트**:
- [ ] content-generator-v7.sh 개발 완료
- [ ] 모듈화된 라이브러리 분리 완료
- [ ] 재시작 메커니즘 테스트 통과
- [ ] 계약 검증 통합 테스트 통과
- [ ] v6 대비 기능 동등성 확인

---

### Milestone 5: Quality (Unit 5 완료)
**날짜**: Week 10 종료
**체크포인트**:
- [ ] 품질 메트릭 명세 작성 완료
- [ ] 품질 측정 스크립트 개발 완료
- [ ] 품질 리포트 생성 테스트 통과
- [ ] 대시보드 배포 완료
- [ ] content-validator 통합 완료

---

### Milestone 6: Integration (전체 통합)
**날짜**: Week 11 종료
**체크포인트**:
- [ ] 모든 통합 테스트 통과
- [ ] End-to-End 테스트 통과
- [ ] 성능 벤치마크 (50-80분 목표 유지)
- [ ] 문서화 완료
- [ ] 프로덕션 배포 준비 완료

## 의사소통 계획

### 정기 회의
- **주간 리뷰**: 매주 금요일, 진행 상황 및 차주 계획
- **유닛 완료 리뷰**: 각 유닛 완료 시, 산출물 검토 및 승인

### 문서 공유
- 모든 명세 및 계약 문서는 `docs/aidlc-docs/` 디렉터리에 중앙 집중
- Git으로 버전 관리
- Markdown 형식으로 작성하여 diff 추적 용이

### 이슈 추적
- 통합 이슈는 `docs/aidlc-docs/inception/integration-issues.md`에 기록
- 각 이슈에 담당자, 기한, 해결 방안 명시

## 성공 기준

1. **기능 완전성**: 기존 v6의 모든 기능이 v7에서 작동
2. **성능 유지**: 콘텐츠 생성 시간 50-80분 유지 또는 단축
3. **품질 향상**: 평균 품질 점수 75점 이상
4. **재시작 성공률**: 중간 실패 후 재시작 성공률 95% 이상
5. **계약 준수율**: 에이전트 출력물의 계약 준수율 100%

## 다음 단계

1. **승인 요청**: 본 통합 계획에 대한 이해관계자 승인
2. **팀 구성**: 각 유닛 담당 팀/인원 배정
3. **킥오프 미팅**: Unit 1 작업 시작 전 킥오프
4. **첫 마일스톤 착수**: Unit 1 - Pipe Mechanism 표준화 시작
