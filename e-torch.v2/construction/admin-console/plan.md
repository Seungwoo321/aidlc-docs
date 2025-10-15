# Admin Console Feature Module 설계 계획

## 목적

admin-console Feature Module의 설계를 수립합니다. US6.1~6.8 (8개 사용자 스토리)를 TypeScript Interface + Zod Schema + React Components + TanStack Query로 구현하기 위한 상세 설계를 작성합니다.

**중요**: DDD 패턴 (Aggregate Root, Repository, Domain Events) 사용 금지

## 설계 범위

**포함된 User Stories**:

- US6.1: 지표 등록
- US6.2: 지표 관리
- US6.3: 사용자 관리
- US6.4: 데이터 소스 관리
- US6.5: 플랜 제한 관리
- US6.6: 대시보드 템플릿 관리
- US6.7: 카테고리 관리
- US6.8: 수동 데이터 입력 및 관리

**주요 페이지**:

- `/indicators` - 지표 관리 (US6.1, US6.2)
- `/users` - 사용자 관리 (US6.3)
- `/data-sources` - 데이터 소스 관리 (US6.4)
- `/plan-limits` - 플랜 제한 관리 (US6.5)
- `/templates` - 템플릿 관리 (US6.6)
- `/categories` - 카테고리 관리 (US6.7)
- `/custom-data` - 수동 데이터 관리 (US6.8)

## 작업 단계

### Phase 1: 사전 조사 및 준비

- [x] 1.1: AdminConsoleContract 인터페이스 분석
  - integration_contract.md의 AdminConsoleContract 메서드 목록 확인
  - 각 메서드가 어떤 User Story에 매핑되는지 파악
  - 총 22개 메서드 확인 (지표 5개, 템플릿 4개, 사용자 5개, 데이터소스 6개, 플랜제한 5개, 카테고리 6개, 수동데이터 6개, 모니터링 2개)

- [x] 1.2: 공통 타입 조사
  - integration_contract.md의 공통 데이터 타입 확인
  - Admin Console에서 사용하는 타입 목록: ManagedIndicator, DataSource, PlanLimitConfig, Category, CustomDataPoint, CustomDataImportResult, CustomDataHistory, DashboardTemplate, AdminUserView, ActivityLog, SystemMetrics, DashboardStats, TestResult
  - DTO 타입 필요: CreateIndicatorDto, UpdateIndicatorDto, CreateDataSourceDto, UpdateDataSourceDto, CreateCategoryDto, UpdateCategoryDto, CreateTemplateDto, UpdateTemplateDto, CreateLimitDto, UpdateLimitDto, CustomDataPointDto, UserFilters

- [x] 1.3: 의존성 확인
  - Authentication Unit: getCurrentUser(), hasRole('admin')
  - DataIntegration Unit: searchIndicators() (지표 탐색 시 사용)
  - Supabase 테이블: indicators, users, data_sources, plan_limits, templates, categories, custom_data, activity_logs

### Phase 2: 타입 정의

- [x] 2.1: TypeScript Interface 정의
  - AdminConsoleContract 메서드 시그니처 (integration_contract.md 기반)
  - Request/Response DTO 인터페이스 정의
  - 공통 타입 재사용 (integration_contract.md에 정의된 타입)

- [x] 2.2: Zod Schema 정의
  - 각 DTO에 대한 Zod Schema 정의
  - 런타임 검증 규칙 명시
  - Form 유효성 검증용 Schema

### Phase 3: React Components Tree 설계

**[Question 1] Page Layout 구조**

Admin Console의 레이아웃 구조를 결정해야 합니다.

**Option A: Shadcn/UI App Layout 사용**

```
<AppLayout>
  <Sidebar />
  <Header />
  <Main>
    <PageContent />
  </Main>
</AppLayout>
```

**Option B: Next.js 15 Parallel Routes 사용**

```
app/(admin)/
  @sidebar/
  @header/
  @main/
  layout.tsx
```

**Option C: Simple Layout (packages/ui 재사용)**

```
<AdminLayout>
  <Sidebar />
  <Content />
</AdminLayout>
```

어떤 구조가 적절한가요?

**[Answer: Option C - Simple Layout (packages/ui 재사용)]**

**결정**: packages/ui에 범용 AppLayout 구현, apps/web과 apps/admin에서 공유

**이유**:

1. **Multi-Zone + Monorepo 구조에 적합**: 각 앱은 독립 배포되지만 동일한 소스코드(packages/ui) 공유
2. **범용 옵션 기반 설계**: "admin", "dashboard" 같은 도메인별 분리가 아닌, Props로 모든 변형 처리
3. **재사용성**: navigation, showUserMenu, headerActions 등의 옵션으로 다양한 레이아웃 구성
4. **YAGNI 원칙**: 현재 요구사항에 적합한 단순한 구조, 향후 필요 시 확장 가능

**구현 구조**:

```
packages/ui/
  src/layouts/
    AppLayout.tsx              # 범용 레이아웃 (Props로 커스터마이징)
    - Props: navigation, showUserMenu, sidebarCollapsible, headerActions, etc.

apps/admin/
  app/(system)/layout.tsx
  - import { AppLayout } from '@e-torch/ui'
  - navigation에 Admin 메뉴 주입

apps/web/
  app/layout.tsx
  - import { AppLayout } from '@e-torch/ui'
  - navigation에 User 메뉴 주입
```

---

- [x] 3.1: Layout Components 설계
  - AdminLayout, Sidebar, Header 컴포넌트 계층
  - Navigation 구조
  - 권한 기반 메뉴 표시

- [x] 3.2: Page Components 설계 (US6.1, US6.2 - 지표 관리)
  - IndicatorsPage (목록)
  - IndicatorCreatePage (등록)
  - IndicatorEditPage (수정)
  - IndicatorDetailPage (상세)
  - 하위 컴포넌트 (IndicatorList, IndicatorForm, IndicatorSourceSelector)

- [x] 3.3: Page Components 설계 (US6.3 - 사용자 관리)
  - UsersPage (목록)
  - UserDetailPage (상세)
  - 하위 컴포넌트 (UserList, UserFilters, UserSubscriptionForm, UserActivityLog)

- [x] 3.4: Page Components 설계 (US6.4 - 데이터 소스 관리)
  - DataSourcesPage (목록)
  - DataSourceCreatePage (추가)
  - DataSourceEditPage (수정)
  - 하위 컴포넌트 (DataSourceList, DataSourceForm, APIKeyInput, ConnectionTest)

- [x] 3.5: Page Components 설계 (US6.5 - 플랜 제한 관리)
  - PlanLimitsPage (목록)
  - PlanLimitEditPage (수정)
  - 하위 컴포넌트 (PlanLimitList, PlanLimitForm, LimitHistoryTable)

- [x] 3.6: Page Components 설계 (US6.6 - 템플릿 관리)
  - TemplatesPage (목록)
  - TemplateCreatePage (생성)
  - TemplateEditPage (수정)
  - 하위 컴포넌트 (TemplateList, TemplateForm, TemplatePreview)

- [x] 3.7: Page Components 설계 (US6.7 - 카테고리 관리)
  - CategoriesPage (목록)
  - 하위 컴포넌트 (CategoryList, CategoryForm, CategoryReorder)

- [x] 3.8: Page Components 설계 (US6.8 - 수동 데이터 관리)
  - CustomDataPage (목록)
  - CustomDataUploadPage (CSV 업로드)
  - 하위 컴포넌트 (CustomDataList, CSVUploader, DataPreview, DataPointForm)

- [x] 3.9: 공통 Components 설계
  - DataTable (공통 테이블)
  - FormDialog (공통 다이얼로그)
  - ConfirmDialog (확인 다이얼로그)
  - Toast (알림)
  - SearchInput (검색)
  - Pagination (페이지네이션)

### Phase 4: TanStack Query Hooks 설계

**[Question 2] Query Key 네이밍 전략**

TanStack Query의 Query Key 네이밍 규칙을 결정해야 합니다.

**Option A: Feature 기반**

```typescript
['admin-console', 'indicators', 'list']
['admin-console', 'indicators', 'detail', indicatorId]
['admin-console', 'users', 'list', filters]
```

**Option B: Resource 기반**

```typescript
['indicators', 'list']
['indicators', indicatorId]
['users', 'list', filters]
```

**Option C: Hierarchical**

```typescript
['admin', 'indicators', 'list']
['admin', 'indicators', indicatorId]
['admin', 'users', 'list', filters]
```

어떤 전략이 적절한가요?

**[Answer: Option B - Resource 기반]**

**결정**: Resource 중심의 Query Key 구조 사용 (예: ['indicators', 'list'])

**이유**:

1. **TanStack Query 공식 권장 패턴**: Resource → Operation → Parameters 계층 구조
2. **Multi-Zone 구조에 적합**: apps/admin과 apps/web은 독립 QueryClient를 가지므로 Resource 이름 충돌 없음
3. **단순성**: 2-3단계 구조로 짧고 직관적, Feature/App prefix 불필요
4. **리팩토링 친화적**: Feature Module 구조 변경에 영향 없음, Resource 이름만 일관성 유지
5. **명확한 무효화 전략**: queryKey로 특정 Resource 또는 Operation 단위 무효화 가능

**Query Key 구조**:

- 목록 조회: ['indicators', 'list']
- 상세 조회: ['indicators', indicatorId]
- 필터 적용: ['users', 'list', filters]
- 이력 조회: ['custom-data', indicatorId, 'history']

**Resource 이름 규칙**:

- admin-console: indicators, users, templates, categories, data-sources, plan-limits, custom-data
- admin-moderation: reports, violations, detection-rules
- 각 Resource는 Feature Module 내에서 명확히 구분됨

---

- [x] 4.1: Query Hooks 설계 (지표 관리)
  - useIndicators() - 지표 목록 조회
  - useIndicator(id) - 지표 상세 조회
  - useCreateIndicator() - 지표 생성 mutation
  - useUpdateIndicator() - 지표 수정 mutation
  - useDeleteIndicator() - 지표 삭제 mutation
  - useTestIndicatorConnection() - 연결 테스트 mutation

- [x] 4.2: Query Hooks 설계 (사용자 관리)
  - useUsers(filters) - 사용자 목록 조회
  - useUserActivityLog(userId) - 활동 로그 조회
  - useUpdateUserSubscription() - 구독 변경 mutation
  - useActivateUser() - 계정 활성화 mutation
  - useDeactivateUser() - 계정 비활성화 mutation

- [x] 4.3: Query Hooks 설계 (데이터 소스 관리)
  - useDataSources() - 데이터 소스 목록 조회
  - useCreateDataSource() - 데이터 소스 추가 mutation
  - useUpdateDataSource() - 데이터 소스 수정 mutation
  - useUpdateDataSourceAPIKey() - API Key 수정 mutation
  - useToggleDataSourceStatus() - 활성화/비활성화 mutation
  - useTestAPIConnection() - 연결 테스트 mutation

- [x] 4.4: Query Hooks 설계 (플랜 제한 관리)
  - usePlanLimits(planType) - 플랜 제한 목록 조회
  - useAddPlanLimit() - 제한 추가 mutation
  - useUpdatePlanLimit() - 제한 수정 mutation
  - useRemovePlanLimit() - 제한 삭제 mutation
  - useLimitHistory(limitKey) - 변경 이력 조회

- [x] 4.5: Query Hooks 설계 (템플릿 관리)
  - useTemplates() - 템플릿 목록 조회
  - useCreateTemplate() - 템플릿 생성 mutation
  - useUpdateTemplate() - 템플릿 수정 mutation
  - useDeleteTemplate() - 템플릿 삭제 mutation

- [x] 4.6: Query Hooks 설계 (카테고리 관리)
  - useCategories() - 카테고리 목록 조회
  - useCreateCategory() - 카테고리 생성 mutation
  - useUpdateCategory() - 카테고리 수정 mutation
  - useDeleteCategory() - 카테고리 삭제 mutation
  - useReorderCategories() - 순서 변경 mutation
  - useToggleCategoryStatus() - 활성화/비활성화 mutation

- [x] 4.7: Query Hooks 설계 (수동 데이터 관리)
  - useCustomData(indicatorId) - 데이터 목록 조회
  - useUploadCustomData() - CSV 업로드 mutation
  - useAddCustomDataPoint() - 데이터 포인트 추가 mutation
  - useUpdateCustomDataPoint() - 데이터 수정 mutation
  - useDeleteCustomDataPoint() - 데이터 삭제 mutation
  - useCustomDataHistory(indicatorId) - 변경 이력 조회

- [x] 4.8: Query Hooks 설계 (모니터링)
  - useSystemMetrics() - 시스템 메트릭 조회
  - useDashboardStats() - 대시보드 통계 조회

- [x] 4.9: 캐싱 전략 정의
  - Query Key 구조
  - staleTime, cacheTime 설정
  - Invalidation 전략 (mutation 후 어떤 query를 invalidate할지)
  - Optimistic Updates 적용 여부

### Phase 5: Business Logic (선택적)

**[Question 3] Business Logic 필요성**

Admin Console에서 복잡한 비즈니스 로직이 필요한 부분이 있는지 확인이 필요합니다.

**예상 복잡한 검증 로직**:

- 지표 소스별 API 파라미터 검증 (KOSIS, ECOS, OECD, CUSTOM)
- CSV 파일 업로드 전 데이터 검증 (형식, 필수 필드, 데이터 타입)
- 플랜 제한 변경 시 기존 사용자 영향 계산
- 카테고리 삭제 시 연결된 지표/템플릿 존재 여부 확인

이런 로직을 별도 Business Service로 분리해야 할까요?

**Option A: 분리 필요**

- packages/admin-console/src/services/ 에 별도 파일 생성
- IndicatorValidationService, CSVValidationService 등

**Option B: 컴포넌트/Hook 내부에 포함**

- 각 컴포넌트나 Hook에서 직접 처리
- Zod Schema로 기본 검증 충분

어떤 접근이 적절한가요?

**[Answer: Option A - 별도 Service 분리 (선택적)]**

**결정**: 복잡한 검증 로직만 별도 Service로 분리, 나머지는 Hook/컴포넌트에 포함

**분리할 Service** (복잡도 높음):

- CSV 파일 검증 (csvValidation.ts): 필수 컬럼, 날짜 형식, 숫자 타입, 중복 데이터, 최대 행 수
- 지표 소스별 API 파라미터 검증 (indicatorValidation.ts): KOSIS, ECOS, OECD 각 소스별 다른 검증 규칙

**Hook/컴포넌트에 포함** (복잡도 낮음):

- 플랜 제한 영향 계산: 간단한 쿼리로 처리
- 카테고리 참조 확인: 간단한 카운트 쿼리로 처리

**이유**:

1. **복잡도 기반 판단**: 중간 이상의 복잡도를 가진 로직만 분리 (Over-engineering 방지)
2. **재사용성**: CSV 검증과 지표 검증은 여러 컴포넌트에서 사용됨
3. **테스트 용이성**: 순수 함수로 작성하여 단위 테스트 쉬움
4. **유지보수**: 외부 API 스펙 변경 시 한 곳만 수정
5. **관심사 분리**: UI 로직과 비즈니스 검증 로직 명확히 분리

**Service 작성 원칙**:

- 순수 함수로 작성 (side effect 없음)
- 명확한 TypeScript 타입 정의
- 단일 책임 원칙 준수
- 에러는 throw 대신 Result 타입으로 반환

**파일 구조**:

- packages/admin-console/src/services/validation/csvValidation.ts
- packages/admin-console/src/services/validation/indicatorValidation.ts

---

- [x] 5.1: Business Logic 필요 여부 결정
- [x] 5.2: (Option A 선택 시) Service 클래스/함수 설계
- [x] 5.3: (Option A 선택 시) 각 Service의 메서드 시그니처 정의

### Phase 6: 파일 구조 정의

- [x] 6.1: packages/admin-console/ 디렉토리 구조 설계
  - src/components/ (React Components)
  - src/hooks/ (TanStack Query Hooks)
  - src/types/ (TypeScript Interfaces)
  - src/schemas/ (Zod Schemas)
  - src/services/ (Business Logic, 선택적)
  - src/lib/ (유틸리티)

- [x] 6.2: apps/admin/ 페이지 구조 설계
  - app/(system)/indicators/ (지표 관리 페이지)
  - app/(system)/users/ (사용자 관리 페이지)
  - app/(system)/data-sources/ (데이터 소스 관리 페이지)
  - app/(system)/plan-limits/ (플랜 제한 관리 페이지)
  - app/(system)/templates/ (템플릿 관리 페이지)
  - app/(system)/categories/ (카테고리 관리 페이지)
  - app/(system)/custom-data/ (수동 데이터 관리 페이지)

- [x] 6.3: 파일 네이밍 컨벤션 정의
  - 컴포넌트: PascalCase (IndicatorList.tsx)
  - Hooks: camelCase (useIndicators.ts)
  - Types: PascalCase (indicator.types.ts)
  - Schemas: camelCase (indicator.schema.ts)

### Phase 7: 의존성 정의

- [x] 7.1: 내부 의존성 (E-Torch 패키지)
  - @e-torch/ui (공통 UI 컴포넌트)
  - @e-torch/core (공통 타입, 유틸리티)
  - @e-torch/query (공통 데이터 레이어)
  - @e-torch/auth (Authentication Contract 사용)
  - @e-torch/data-sources (DataIntegration Contract 사용)

- [x] 7.2: 외부 의존성 (npm 패키지)
  - @tanstack/react-query
  - @tanstack/react-table (테이블)
  - zod
  - react-hook-form
  - @supabase/supabase-js
  - shadcn/ui 컴포넌트

- [x] 7.3: Supabase 의존성
  - 테이블 접근 (indicators, users, data_sources, plan_limits, templates, categories, custom_data)
  - RLS 정책 (admin 역할 필수)
  - Storage (템플릿 썸네일, CSV 파일, 선택적)

### Phase 8: 최종 검토 및 문서화

- [x] 8.1: 모든 User Story가 설계에 반영되었는지 확인
  - US6.1~6.8 각각에 대한 컴포넌트, Hook, 타입 매핑 확인

- [x] 8.2: AdminConsoleContract와의 일치성 확인
  - integration_contract.md의 모든 메서드가 Hook으로 구현되었는지 확인

- [x] 8.3: DDD 패턴 미사용 검증
  - Aggregate Root, Repository, Domain Events가 포함되지 않았는지 확인
  - TypeScript Interface + Zod Schema + React + TanStack Query만 사용하는지 확인

- [x] 8.4: feature_module_design.md 작성
  - 모든 설계 내용을 하나의 문서로 통합
  - 다이어그램 추가 (컴포넌트 트리, 의존성 그래프)

## 산출물

최종 산출물: `docs/aidlc-docs/construction/admin-console/feature_module_design.md`

**포함 내용**:

1. 개요 (Feature Module 책임, User Stories)
2. 타입 정의 (TypeScript Interface, Zod Schema)
3. React Components Tree (계층 구조, Props, State)
4. TanStack Query Hooks (Query/Mutation 목록, 캐싱 전략)
5. Business Logic (선택적)
6. 파일 구조 (디렉토리 트리)
7. 의존성 (내부/외부)
8. 보안 고려사항
9. 다음 단계 (BFF API 구현, Supabase 스키마)

## 다음 단계

이 계획을 승인하시면 Phase 1부터 순차적으로 실행하겠습니다. 각 Phase 완료 시 체크박스를 업데이트하고 다음 단계로 진행합니다.

**중요**: 코드 스니펫은 생성하지 않습니다. 설계 문서만 작성합니다.
