# E-Torch AI-DLC Quick Start

**5분 안에 시작하기**

---

## 1. 첫 번째 프롬프트 실행

AI 세션을 시작하고 **01-architect-role.md** 파일의 내용을 복사하여 붙여넣습니다.

```bash
# 파일 내용 복사/붙여넣기
[01-architect-role.md의 프롬프트 섹션]
```

AI가 E-Torch 프로젝트 컨텍스트를 이해했는지 확인합니다.

---

## 2. 순차 진행

프롬프트를 순서대로 진행합니다:

```
01 역할 부여
  ↓
02 사용자 스토리
  ↓
03 Feature Module 그룹화
  ↓
04 Feature Module 설계 ← Feature Module 지정 필요
  ↓
05 BFF API 설계 ← Feature Module 지정 필요
  ↓
06 구현 계획
  ↓
07 실제 구현 (선택)
  ↓
08 테스트 계획 ← Feature Module 지정 필요
  ↓
09 배포 계획
```

---

## 3. Feature Module 지정 예시

프롬프트 04-08을 실행할 때:

```
[프롬프트 04 내용 붙여넣기]

+ 추가로 입력:
"Widget Library Feature Module에만 집중하세요."
```

---

## 4. 계획-승인-실행 패턴

모든 프롬프트는 다음 패턴을 따릅니다:

1. AI가 **plan.md** 파일에 계획 작성
2. 계획 검토
3. "승인합니다" 입력
4. AI가 단계별 실행
5. 각 단계 완료 시 체크박스 표시

---

## 5. 주의사항

### ❌ 하지 말 것
- 설계 단계(01-06, 08-09)에서 코드 생성 요청
- DDD 패턴(Aggregate, Repository) 사용 요청
- 여러 Feature Module 동시 진행

### ✅ 할 것
- 한 번에 하나의 Feature Module에 집중
- 계획 검토 후 승인
- 07번은 사용자가 명시적으로 요청할 때만

---

## 6. 예상 소요 시간

| 단계 | 소요 시간 |
|------|----------|
| 01-03 (Inception) | 2-4시간 |
| 04-06 (설계) | 5-7시간 |
| 07 (구현) | 10-12일 |
| 08-09 (Operations) | 4-6시간 |

**Widget Library 1개 Feature Module 전체**: 약 18일

---

## 트러블슈팅

### AI가 코드를 생성하려고 할 때
```
"코드 스니펫을 생성하지 마세요. 설계 문서만 작성하세요."
```

### AI가 DDD 패턴을 사용하려고 할 때
```
"DDD 패턴을 사용하지 마세요.
TypeScript Interface + Zod Schema + TanStack Query를 사용하세요."
```

### AI가 계획 없이 바로 실행하려고 할 때
```
"먼저 plan.md 파일에 계획을 작성하고 제 승인을 받으세요."
```

---

상세한 정보는 개별 프롬프트 파일(01-09)을 참조하세요.
