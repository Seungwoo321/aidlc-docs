# Feature Module 그룹화 계획

## 목적

E-Torch 프로젝트의 38개 사용자 스토리를 독립적으로 구축 가능한 Feature Module로 그룹화하고, 각 Module의 책임과 통합 계약을 명확히 정의합니다.

## 현황 분석

**기존 units 문서:**

- ✅ authentication.md
- ✅ dashboard.md
- ✅ widget-library.md
- ✅ data-integration.md
- ✅ subscription.md
- ✅ admin-console.md
- ✅ integration_contract.md

**user_stories.md 스토리 현황:**

- Epic 1: 사용자 인증 (2개)
- Epic 2: 대시보드 관리 (14개)
- Epic 3: 위젯 관리 (8개)
- Epic 4: 데이터 통합 (3개)
- Epic 5: 구독 관리 (5개)
- Epic 6: 관리자 기능 (11개)
- **총 43개 스토리**

## 작업 단계

### Phase 1: 기존 Feature Module 검증

- [x] 1.1: 각 units/*.md 문서 읽기 및 현재 상태 확인
- [x] 1.2: user_stories.md의 43개 스토리와 기존 units 매핑 확인
- [x] 1.3: 누락된 스토리 식별
  - ✅ 모든 43개 스토리가 units 문서에 포함됨
  - ✅ US2.12~2.14는 dashboard.md에 포함
  - ✅ US6.9~6.11은 admin-console.md에 포함
  - ✅ 누락된 스토리 없음
- [x] 1.4: Feature Module 그룹화 기준 검증

| Feature Module | 스토리 수 | 높은 응집도 | 느슨한 결합 | 독립 배포 | 팀 할당 | 판정 |
|---------------|---------|-----------|-----------|---------|--------|-----|
| **Authentication** | 2 | ✅ 인증/프로필 관리 | ✅ 독립적 (0개 의존) | ✅ `@e-torch/auth` | ✅ 1명 | ✅ 적합 |
| **Dashboard** | 14 | ✅ 대시보드 CRUD + 법적 동의 | ⚠️ 5개 의존 (Widget, Subscription, Auth, Data, Admin) | ✅ `@e-torch/dashboard` | ✅ 3-4명 | ✅ 적합 |
| **Widget Library** | 8 | ✅ 위젯 CRUD + 시각화 | ⚠️ 3개 의존 (Auth, Subscription, Data) | ✅ `@e-torch/widgets` | ✅ 2-3명 | ✅ 적합 |
| **Data Integration** | 3 | ✅ 데이터 소스 통합 | ✅ 2개 의존 (Auth, Subscription) | ✅ `@e-torch/data-sources` | ✅ 1-2명 | ✅ 적합 |
| **Subscription** | 5 | ✅ 구독/플랜 관리 | ✅ 2개 의존 (Auth, Admin) | ✅ `@e-torch/payments` | ✅ 1-2명 | ✅ 적합 |
| **Admin Console** | 11 | ✅ 시스템 운영 + Moderation | ✅ 2개 의존 (Auth, Data) | ✅ `@e-torch/admin-console` + `@e-torch/admin-moderation` | ✅ 2명 | ✅ 적합 |

**검증 결과**:

- ✅ 모든 Feature Module이 그룹화 기준을 충족함
- ✅ Dashboard의 5개 의존성은 허용 범위 (BFF 계층에서 조율)
- ✅ 각 Module이 명확한 책임과 경계를 가짐
- ✅ Multi-Zone 아키텍처 적용 결정:
  - `apps/web`: Authentication + Dashboard + Widget Library + Data Integration + Subscription
  - `apps/admin`: Admin Console + Content Moderation

### Phase 2: Feature Module 스토리 매핑

- [x] 2.1: authentication.md 검증
  - Epic 1 스토리 (US1.1~1.2) 포함 확인
  - 누락된 스토리 없는지 확인

- [x] 2.2: dashboard.md 검증
  - Epic 2 스토리 (US2.1~2.14) 포함 확인
  - US2.12~2.14 일관성 검증 (user_stories.md 156-177 vs dashboard.md 199-278)
    - 제목 일치 여부
    - Acceptance Criteria 일치 여부
    - 불일치 발견 시 기록

- [x] 2.3: widget-library.md 검증
  - Epic 3 스토리 (US3.1~3.8) 포함 확인
  - 9가지 위젯 타입 명시 확인

- [x] 2.4: data-integration.md 검증
  - Epic 4 스토리 (US4.1~4.3) 포함 확인
  - KOSIS/ECOS/OECD/CUSTOM 소스 명시 확인

- [x] 2.5: subscription.md 검증
  - Epic 5 스토리 (US5.1~5.5) 포함 확인
  - TossPay 연동 상태 확인

- [x] 2.6: admin-console.md + admin-moderation.md 분리 완료
  - admin-console.md: US6.1~6.8 (시스템 운영)
  - admin-moderation.md: US6.9~6.11 (컨텐츠 안전)
  - 분리 사유: Question 4 결정사항 반영

### Phase 3: 공통 Module 문서 확인

- [x] 3.1: query.md (Business Service Layer) 작성 완료
  - WidgetBusinessService
  - DashboardBusinessService
  - SubscriptionBusinessService
  - Error Handling

- [x] 3.2: ui.md (공통 UI 컴포넌트) 작성 완료
  - Shadcn/UI 래핑
  - 공통 컴포넌트 목록

- [x] 3.3: core.md (공통 타입/상수) 작성 완료
  - TypeScript 인터페이스
  - 상수 정의 (플랜, 제한 등)

### Phase 4: integration_contract.md 검증

- [x] 4.1: BFF API 엔드포인트 추가 완료
  - Widget Library API (9개)
  - Dashboard API (21개)
  - Data Sources API (5개)
  - Subscription API (5개)
  - Admin Console API (45개)
  - Admin Moderation API (10개) - 신규 추가

- [x] 4.2: Feature Module 간 의존성 다이어그램 업데이트
  - Admin 영역에 Admin Console + Admin Moderation 분리 표시
  - 총 7개 Feature Module로 변경

- [x] 4.3: 이벤트 정의 확인 (선택적)
  - 글로벌 이벤트 목록 정의됨

### Phase 5: 문서 업데이트

- [x] 5.1: authentication.md - 업데이트 불필요 (이미 완성)
- [x] 5.2: dashboard.md - US2.12~2.14 이미 포함됨
- [x] 5.3: widget-library.md - 9가지 위젯 타입 명시됨
- [x] 5.4: data-integration.md - 4가지 소스 명시됨
- [x] 5.5: subscription.md - 업데이트 불필요 (이미 완성)
- [x] 5.6: admin-console.md - US6.1~6.8만 포함하도록 수정 완료
- [x] 5.7: admin-moderation.md - US6.9~6.11 신규 생성 완료
- [x] 5.8: integration_contract.md - AdminModerationContract 추가 완료
- [x] 5.9: 공통 Module 문서 (query.md, ui.md, core.md) 작성 완료

### Phase 6: 최종 검증

- [x] 6.1: 43개 스토리가 모두 Feature Module에 할당됨
- [x] 6.2: Feature Module 그룹화 기준 준수 확인 완료
- [x] 6.3: 통합 계약 완전성 확인 - 7개 Feature Module 모두 정의됨
- [x] 6.4: 문서 일관성 확인 완료

---

## 질문 사항

### [Question 1] 공통 Module 문서 작성 필요성

현재 units/ 폴더에는 Feature Module 문서만 있고, 공통 Module 문서가 없습니다.

다음 공통 Module 문서를 작성해야 할까요?

**Option A: 작성 필요**

- query.md (Business Service Layer)
- ui.md (Shadcn/UI 공통 컴포넌트)
- core.md (공통 타입/상수)

**Option B: 불필요**

- 이유: 공통 Module은 Feature Module에 종속되므로 별도 문서 불필요
- 대안: integration_contract.md에 간략히 언급만

**Option C: 일부만 작성**

- 어떤 Module 문서가 필요한가?

**[Answer: Option A - 작성 필요]**

**결정**: query.md, ui.md, core.md 모두 작성 필요

**이유**:

- AI-DLC 방법론: 문서는 아키텍처 계약을 정의하며, 현재 구현을 설명하는 것이 아님
- 현재 구현이 100% 동작하지 않을 수 있고, 결정된 아키텍처에 맞지 않을 수 있음
- 문서를 기반으로 모든 구현 내용을 변경할 수 있어야 함
- 공통 Module은 여러 Feature Module에서 사용되므로 명확한 계약 정의가 필수

**작성할 문서**:

1. `docs/aidlc-docs/inception/units/query.md`: Business Service Layer 계약
2. `docs/aidlc-docs/inception/units/ui.md`: 공통 UI 컴포넌트 계약
3. `docs/aidlc-docs/inception/units/core.md`: 공통 타입/상수 계약

---

### [Question 2] 신규 스토리 (US2.12~2.14, US6.9~6.11) 추가 위치

user_stories.md에 추가된 6개 신규 스토리를 units 문서에 반영해야 합니다.

**dashboard.md에 추가할 스토리:**

- US2.12: 대시보드 생성 시 법적 동의
- US2.13: 대시보드 조회 시 면책 조항
- US2.14: 대시보드 신고

**admin-console.md에 추가할 스토리:**

- US6.9: 신고된 컨텐츠 관리
- US6.10: 컨텐츠 위반 사용자 관리
- US6.11: 위험 컨텐츠 자동 탐지

이 6개 스토리를 해당 units 문서에 추가해야 할까요, 아니면 이미 포함되어 있나요?

**[Answer: Option B - 일관성 검증 필요]**

**현황 확인 결과**:

- ✅ dashboard.md: US2.12~2.14 이미 포함 (lines 199-278)
- ✅ admin-console.md: US6.9~6.11 이미 포함 (lines 159, 194, 226)

**결정**: 일관성 검증 필요 (Verification Required)

**이유**:

1. AI-DLC 방법론: 문서 간 일관성이 Inception Phase의 핵심
2. 리스크 관리: 존재하는 것과 정확히 일치하는 것은 다름
3. user_stories.md와 units/*.md가 다른 시점에 작성되었을 가능성
4. Phase 2 "Feature Module 스토리 매핑"의 목적과 정확히 일치

**검증 범위**:

- US2.12~2.14: user_stories.md와 dashboard.md 간 제목/AC 일치 여부
- US6.9~6.11: user_stories.md와 admin-console.md 간 제목/AC 일치 여부
- 불일치 발견 시 Phase 5에서 수정

**실행 계획**: Phase 2.2와 Phase 2.6에서 상세 검증 실행

---

### [Question 3] Feature Module 분리 기준 재검토

현재 Feature Module 구조:

1. authentication (Epic 1: 2개)
2. dashboard (Epic 2: 14개)
3. widget-library (Epic 3: 8개)
4. data-integration (Epic 4: 3개)
5. subscription (Epic 5: 5개)
6. admin-console (Epic 6: 11개)

**dashboard (14개 스토리)가 너무 크지 않나요?**

분리 옵션:

- **Option A: 현재 구조 유지** - Dashboard는 응집도가 높아 분리 불필요
- **Option B: Dashboard를 2개로 분리**
  - dashboard-core (생성/편집/삭제)
  - dashboard-community (공유/즐겨찾기/템플릿)
- **Option C: Legal Compliance를 별도 Module로 분리**
  - legal-compliance (US2.12~2.14, US6.9~6.11)

어떤 구조가 적절한가요?

**[Answer: Option A - 현재 구조 유지]**

**결정**: Dashboard는 14개 스토리 그대로 단일 Feature Module 유지

**이유**:

1. **Feature Module 원칙 준수**:
   - 높은 응집도: Dashboard 도메인의 모든 기능이 자연스럽게 묶임
   - 느슨한 결합: 5개 의존성은 관리 가능한 수준
   - 독립 배포 가능: `@e-torch/dashboard` 단일 패키지
   - 팀 할당 가능: 3-4명 팀이 14개 스토리 개발 적정

2. **DDD 관점**: Dashboard는 단일 Bounded Context
   - CRUD + 공유 + 법적 동의가 단일 생명주기

3. **실용적 이유**:
   - Option B/C는 조기 추상화 위험
   - Legal Compliance(US2.12~2.14)는 Dashboard 생명주기에 강하게 결합됨
   - Community 기능(US2.9~2.11)도 CRUD와 분리 불가

4. **아키텍처 방향**:
   - Minimal Multi-Zone 적용: `apps/web` + `apps/admin` 분리
   - Dashboard/Widget Library/Data Integration은 `apps/web`에 통합 유지
   - Admin Console은 `apps/admin`으로 완전 분리

**Multi-Zone 아키텍처 상세**:

```
Production:
  - https://e-torch.com           → apps/web (Dashboard + Widgets + Data Integration)
  - https://admin.e-torch.com     → apps/admin (Admin Console)

Development:
  - http://localhost:3000         → apps/web
  - http://localhost:3001         → apps/admin

Authentication:
  - Cookie domain: .e-torch.com (서브도메인 공유)
  - apps/web: User 권한 체크
  - apps/admin: Admin 권한 체크

Deployment:
  - Independent CI/CD (Vercel Project 2개)
  - apps/web 변경 → apps/web만 배포
  - apps/admin 변경 → apps/admin만 배포
```

**재검토 조건**:

- [ ] Dashboard Core 스토리가 20개 이상으로 증가
- [ ] Legal Compliance가 다른 Module에도 필요 (10개 이상 스토리)
- [ ] 2개 팀으로 분리 운영 필요

---

### [Question 4] Admin Console의 Feature Module 분리

admin-console은 11개 스토리를 포함하며, 다양한 책임을 가지고 있습니다:

- 지표 관리 (US6.1~6.2)
- 사용자 관리 (US6.3)
- 데이터 소스 관리 (US6.4)
- 플랜 관리 (US6.5)
- 템플릿 관리 (US6.6)
- 카테고리 관리 (US6.7)
- 수동 데이터 관리 (US6.8)
- 컨텐츠 관리 (US6.9~6.11)

**Admin Console을 여러 Module로 분리해야 할까요?**

- **Option A: 현재 구조 유지** - 단일 관리자 앱으로 충분
- **Option B: 도메인별 분리**
  - admin-indicators (US6.1~6.2, 6.8)
  - admin-users (US6.3)
  - admin-system (US6.4~6.7)
  - admin-content-moderation (US6.9~6.11)
- **Option C: Content Moderation만 분리**
  - admin-console (US6.1~6.8)
  - content-moderation (US6.9~6.11)

어떤 구조가 적절한가요?

**[Answer: Option C - Content Moderation만 분리]**

**결정**: Admin Console을 2개 Feature Module로 분리

```
packages/
├── @e-torch/admin-console/         # US6.1~6.8 (8개)
│   ├── indicators/                 # 지표 등록/관리
│   ├── data-sources/               # 데이터 소스 관리
│   ├── users/                      # 사용자 관리
│   ├── plan-limits/                # 플랜 제한 관리
│   ├── templates/                  # 템플릿 관리
│   ├── categories/                 # 카테고리 관리
│   └── custom-data/                # 수동 데이터 입력
│
└── @e-torch/admin-moderation/      # US6.9~6.11 (3개)
    ├── reports/                    # 신고 관리
    ├── violations/                 # 위반 사용자 관리
    └── detection/                  # 자동 탐지

apps/admin/ (Next.js)
└── app/
    ├── (system)/                   # admin-console 사용
    └── (moderation)/               # admin-moderation 사용
```

**이유**:

1. **Content Moderation의 특수성**:
   - 법적 리스크 관리는 별도 관심사
   - Dashboard US2.14 (신고)와 연결되는 독립 workflow
   - 컴플라이언스/법무 전문가 전담 가능

2. **응집도 최적화**:
   - admin-console: 시스템 운영/설정 기능 (8개 스토리)
   - admin-moderation: 컨텐츠 안전/규제 기능 (3개 스토리)
   - 각각 명확한 책임과 목적

3. **느슨한 결합**:
   - Moderation은 Dashboard 데이터만 읽음 (약한 의존)
   - admin-console ↔ admin-moderation 상호 의존 없음

4. **팀 구성 현실성**:
   - 2명 팀 가능 (System 1명, Moderation 1명)
   - 또는 1명 개발 후 Compliance 전담자 인계

5. **미래 확장성**:
   - Moderation 기능 확장 시 (AI 탐지, 이미지 검토 등)
   - 독립 Module로 영향 범위 명확

**재검토 조건**:

- [ ] Admin 개발자가 1명뿐이고 Moderation 3개로 고정
- [ ] Admin 팀이 4명 이상, 각 도메인 10개 이상 스토리 증가

---

### [Question 5] integration_contract.md 업데이트 범위

integration_contract.md에 다음 내용이 포함되어야 하는지 확인이 필요합니다:

**1. BFF API 엔드포인트:**

- Widget Library API (GET/POST/PATCH/DELETE)
- Dashboard API (GET/POST/PATCH/DELETE)
- Data Sources API (KOSIS/ECOS/OECD Proxy)
- Subscription API (Plans/Checkout/Status)
- Admin API (Indicators/Users/Templates)
- **신규**: Legal Compliance API (Consent/Report)
- **신규**: Content Moderation API (Reports/Violations/Detection)

**2. Feature Module 간 의존성:**

- Dashboard → Widget Library (위젯 렌더링)
- Dashboard → Subscription (플랜 제한 검증)
- Widget Library → Data Sources (데이터 조회)
- Admin Console → 모든 Module (관리 기능)

**3. 이벤트 정의:**

- Dashboard Created/Updated/Deleted
- Widget Shared
- Subscription Changed
- **신규**: Report Created
- **신규**: User Sanctioned

어떤 내용까지 포함해야 할까요?

- **Option A: BFF API만** - Feature Module 간 통신은 각 units 문서에서 정의
- **Option B: BFF API + 의존성** - 통합 계약의 핵심만 정의
- **Option C: 모두 포함** - BFF API + 의존성 + 이벤트 전체 정의

**[Answer: Option B - BFF API + 의존성 (BFF API는 간소화)]**

**결정**: integration_contract.md에 BFF API 개요 + Feature Module 간 의존성 추가

**포함 내용**:

1. **BFF API 엔드포인트 개요 (간소화)**:

   ```markdown
   ## BFF API 엔드포인트 개요

   ### 엔드포인트 매핑 원칙
   - TypeScript Interface 메서드 → HTTP 엔드포인트 1:1 매핑
   - RESTful 규칙 준수
   - 인증: Authorization Bearer Token
   - Admin API: 별도 도메인 (admin.e-torch.com)

   ### 주요 API 그룹
   1. **Dashboard API**: `/api/dashboards/*`
      - TypeScript: `DashboardContract.*`

   2. **Widget API**: `/api/widgets/*`
      - TypeScript: `WidgetLibraryContract.*`

   3. **Data Integration API**: `/api/data/*`
      - TypeScript: `DataIntegrationContract.*`

   4. **Subscription API**: `/api/subscription/*`
      - TypeScript: `SubscriptionContract.*`

   5. **Admin API**: `https://admin.e-torch.com/api/admin/*`
      - TypeScript: `AdminConsoleContract.*`
      - TypeScript: `AdminModerationContract.*`

   ### 상세 명세
   - Request/Response 포맷, Validation 규칙 등은 Construction Phase에서 OpenAPI Spec으로 정의
   - 현재는 TypeScript Interface가 계약의 기준
   ```

2. **Feature Module 간 의존성 상세**:
   - 각 Feature Module의 의존 대상
   - 의존 방식 (TypeScript import, HTTP 호출 등)
   - 주요 의존 시나리오

3. **이벤트 정의 (선택적)**:
   - 글로벌 이벤트 목록 간략히 언급
   - 구현 여부는 Construction에서 결정
   - Supabase Realtime 대안 명시

**이유**:

1. **Inception 목적 충족**:
   - BFF API가 존재한다는 계약 명시
   - 매핑 원칙으로 충분한 가이드 제공
   - 구체적 스펙은 Construction의 OpenAPI Spec에서

2. **의존성은 필수**:
   - Multi-Zone 아키텍처에서 apps/web ↔ apps/admin 경계 명확화
   - 순환 의존성 방지
   - 팀 간 통합 계약 명확

3. **중복 방지**:
   - TypeScript Interface가 이미 완벽하게 정의됨
   - HTTP 엔드포인트 상세는 1:1 매핑 원칙으로 충분
   - OpenAPI Spec과 중복 방지

4. **유연성 유지**:
   - Construction Phase에서 구현 자유도 제공
   - BFF 경로 변경 시 영향 최소화

---

## 다음 단계

위 질문에 대한 답변을 받은 후, Phase 1부터 순차적으로 실행하겠습니다.
각 Phase 완료 시 체크박스를 업데이트하고 다음 단계로 진행합니다.
