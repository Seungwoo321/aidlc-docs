# Admin Console Feature Module 설계

## 1. 개요

### 1.1 Feature Module 책임

Admin Console Feature Module은 E-Torch 시스템의 관리자 전용 기능을 제공합니다. 시스템 운영 및 설정 관리에 집중하며, 컨텐츠 관리 기능(US6.9~6.11)은 별도의 Admin Moderation Feature Module로 분리되었습니다.

**주요 책임**:

- 경제 지표 등록 및 관리 (KOSIS, ECOS, OECD, CUSTOM 지원)
- 카테고리 관리
- 수동 데이터 입력 및 관리
- 대시보드 템플릿 생성 및 관리
- 사용자 및 구독 관리
- 데이터 소스 관리 (동적 추가 및 설정)
- 플랜 제한 관리

### 1.2 포함된 User Stories

- **US6.1**: 지표 등록 - 관리자가 새로운 경제 지표를 등록
- **US6.2**: 지표 관리 - 등록된 지표를 수정/삭제하고 연결 테스트
- **US6.3**: 사용자 관리 - 사용자 정보와 구독 관리
- **US6.4**: 데이터 소스 관리 - 데이터 소스를 동적으로 추가 및 관리
- **US6.5**: 플랜 제한 관리 - 플랜별 제한사항을 동적으로 관리
- **US6.6**: 대시보드 템플릿 관리 - 템플릿 생성 및 관리
- **US6.7**: 카테고리 관리 - 지표 및 대시보드 카테고리 관리
- **US6.8**: 수동 데이터 입력 및 관리 - API 없는 지표의 데이터를 수동 입력

### 1.3 아키텍처 컨텍스트

**Multi-Zone 구조**:

- apps/admin: Admin Console 전용 Next.js 앱 (독립 배포)
- apps/web: User Dashboard 앱 (독립 배포)
- packages/admin-console: Admin Console Feature Module 패키지
- packages/ui: 공통 UI 컴포넌트 (AppLayout 등)

**설계 원칙**:

- DDD 패턴 사용 금지 (Aggregate Root, Repository, Domain Events)
- TypeScript Interface + Zod Schema 사용
- React Components + TanStack Query Hooks
- Supabase 클라이언트 직접 호출

### 1.4 페이지 구조

apps/admin의 (system) 라우트 그룹 내 7개 주요 페이지:

- `/indicators` - 지표 관리 (US6.1, US6.2)
- `/users` - 사용자 관리 (US6.3)
- `/data-sources` - 데이터 소스 관리 (US6.4)
- `/plan-limits` - 플랜 제한 관리 (US6.5)
- `/templates` - 템플릿 관리 (US6.6)
- `/categories` - 카테고리 관리 (US6.7)
- `/custom-data` - 수동 데이터 관리 (US6.8)

---

## 2. 타입 정의

### 2.1 TypeScript Interface

#### 2.1.1 AdminConsoleContract (integration_contract.md 기반)

Admin Console이 제공하는 22개 메서드:

**지표 관리 (US6.1, US6.2)** - 5개 메서드:

- createIndicator(data: CreateIndicatorDto): Promise<ManagedIndicator>
- updateIndicator(id: string, data: UpdateIndicatorDto): Promise<ManagedIndicator>
- deleteIndicator(id: string): Promise<void>
- getIndicators(): Promise<ManagedIndicator[]>
- testIndicatorConnection(indicatorId: string): Promise<TestResult>

**템플릿 관리 (US6.6)** - 4개 메서드:

- createTemplate(data: CreateTemplateDto): Promise<DashboardTemplate>
- updateTemplate(id: string, data: UpdateTemplateDto): Promise<DashboardTemplate>
- deleteTemplate(id: string): Promise<void>
- getTemplates(): Promise<DashboardTemplate[]>

**사용자 관리 (US6.3)** - 5개 메서드:

- getUsers(filters?: UserFilters): Promise<AdminUserView[]>
- updateUserSubscription(userId: string, plan: 'free' | 'pro', expiryDate?: Date, reason: string): Promise<void>
- activateUser(userId: string, reason: string): Promise<User>
- deactivateUser(userId: string, reason: string): Promise<User>
- getUserActivityLog(userId: string): Promise<ActivityLog[]>

**데이터 소스 관리 (US6.4)** - 6개 메서드:

- getDataSources(): Promise<DataSource[]>
- createDataSource(data: CreateDataSourceDto): Promise<DataSource>
- updateDataSource(id: string, data: UpdateDataSourceDto): Promise<DataSource>
- updateDataSourceAPIKey(id: string, apiKey: string): Promise<void>
- toggleDataSourceStatus(id: string, active: boolean): Promise<void>
- testAPIConnection(sourceId: string): Promise<TestResult>

**플랜 제한 관리 (US6.5)** - 5개 메서드:

- getPlanLimitConfigs(planType?: 'free' | 'pro'): Promise<PlanLimitConfig[]>
- updatePlanLimit(id: string, data: UpdateLimitDto): Promise<PlanLimitConfig>
- addPlanLimit(data: CreateLimitDto): Promise<PlanLimitConfig>
- removePlanLimit(id: string): Promise<void>
- getLimitHistory(limitKey: string): Promise<PlanLimitHistory[]>

**카테고리 관리 (US6.7)** - 6개 메서드:

- getCategories(): Promise<Category[]>
- createCategory(data: CreateCategoryDto): Promise<Category>
- updateCategory(id: string, data: UpdateCategoryDto): Promise<Category>
- deleteCategory(id: string): Promise<void>
- reorderCategories(categoryIds: string[]): Promise<void>
- toggleCategoryStatus(id: string, active: boolean): Promise<void>

**수동 데이터 입력 및 관리 (US6.8)** - 6개 메서드:

- uploadCustomData(indicatorId: string, file: File): Promise<CustomDataImportResult>
- addCustomDataPoint(indicatorId: string, data: CustomDataPointDto): Promise<CustomDataPoint>
- getCustomData(indicatorId: string): Promise<CustomDataPoint[]>
- updateCustomDataPoint(id: string, data: CustomDataPointDto): Promise<CustomDataPoint>
- deleteCustomDataPoint(id: string): Promise<void>
- getCustomDataHistory(indicatorId: string): Promise<CustomDataHistory[]>

**모니터링** - 2개 메서드:

- getSystemMetrics(): Promise<SystemMetrics>
- getDashboardStats(): Promise<DashboardStats>

#### 2.1.2 공통 데이터 타입 (integration_contract.md에서 재사용)

Admin Console에서 사용하는 주요 타입:

**지표 관련**:

- ManagedIndicator: Indicator를 확장하여 관리용 필드 추가 (isActive, usageCount, lastSyncAt, createdBy, updatedBy)
- Indicator: 기본 지표 타입 (id, name, description, source, categoryCode, unit, frequency, apiParams)

**데이터 소스**:

- DataSource: id, name, description, isActive, apiKey, createdAt, updatedAt, updatedBy

**플랜 제한**:

- PlanLimitConfig: id, planType, limitKey, limitValue, description, unit, isActive, effectiveDate, expiryDate, updatedAt, updatedBy
- PlanLimitHistory: id, limitKey, planType, oldValue, newValue, changedBy, changedAt, reason

**템플릿**:

- DashboardTemplate: id, name, description, categoryCode, thumbnail, isActive, isPro, widgets, createdAt, updatedAt
- TemplateWidget: widgetType, name, parameters, layout

**카테고리**:

- Category: id, code, name, description, order, isActive, usageCount, createdAt, updatedAt

**사용자 관리**:

- AdminUserView: id, email, name, planType, status, dashboardCount, lastLoginAt, createdAt
- ActivityLog: id, userId, action, resourceType, resourceId, details, ipAddress, userAgent, createdAt
- User: id, email, name, avatar, role, status, linkedProviders

**수동 데이터**:

- CustomDataPoint: id, indicatorId, date, value, metadata, createdBy, createdAt, updatedAt
- CustomDataImportResult: success, totalRows, importedRows, errors, preview
- CustomDataHistory: id, indicatorId, dataPointId, action, oldValue, newValue, changedBy, changedAt

**모니터링**:

- SystemMetrics: totalUsers, activeUsers, totalDashboards, totalWidgets, apiCallsToday, avgResponseTime, errorRate, timestamp
- DashboardStats: totalPublic, totalPrivate, avgWidgetsPerDashboard, mostUsedCategories, mostUsedIndicators

**기타**:

- TestResult: success, responseTime, statusCode, message, error, testedAt

#### 2.1.3 Request/Response DTO

Admin Console에서 새로 정의해야 하는 DTO:

**지표 관리**:

- CreateIndicatorDto: name, description, source, categoryCode, unit, frequency, apiParams
- UpdateIndicatorDto: Partial<CreateIndicatorDto>

**템플릿 관리**:

- CreateTemplateDto: name, description, categoryCode, thumbnail, isPro, widgets
- UpdateTemplateDto: Partial<CreateTemplateDto>

**데이터 소스 관리**:

- CreateDataSourceDto: name, description, apiKey
- UpdateDataSourceDto: Partial<Omit<CreateDataSourceDto, 'apiKey'>>

**플랜 제한 관리**:

- CreateLimitDto: planType, limitKey, limitValue, description, unit, effectiveDate, expiryDate
- UpdateLimitDto: Partial<Omit<CreateLimitDto, 'planType' | 'limitKey'>>

**카테고리 관리**:

- CreateCategoryDto: code, name, description
- UpdateCategoryDto: Partial<CreateCategoryDto>

**사용자 관리**:

- UserFilters: planType?, status?, search?, sortBy?, sortOrder?

**수동 데이터 관리**:

- CustomDataPointDto: date, value, metadata

### 2.2 Zod Schema

각 DTO에 대한 Zod Schema를 정의하여 런타임 검증 및 Form 유효성 검증에 사용합니다.

**Schema 작성 원칙**:

- 모든 필수 필드는 required()로 명시
- 선택 필드는 optional()로 명시
- 타입별 검증 규칙 적용 (string, number, date, email, url 등)
- 비즈니스 규칙 검증 (최소/최대값, 길이, 정규표현식 등)
- 에러 메시지는 한국어로 제공

**주요 Schema**:

**지표 관리 Schema**:

- CreateIndicatorSchema: name (min 2자), description (optional), source (enum), categoryCode (optional), unit (optional), frequency (enum), apiParams (object)
- UpdateIndicatorSchema: CreateIndicatorSchema.partial()

**템플릿 관리 Schema**:

- CreateTemplateSchema: name (min 2자), description (min 10자), categoryCode (optional), thumbnail (url, optional), isPro (boolean), widgets (array)
- UpdateTemplateSchema: CreateTemplateSchema.partial()

**데이터 소스 관리 Schema**:

- CreateDataSourceSchema: name (min 2자), description (min 5자), apiKey (min 10자, optional)
- UpdateDataSourceSchema: CreateDataSourceSchema.omit({ apiKey: true }).partial()

**플랜 제한 관리 Schema**:

- CreateLimitSchema: planType (enum), limitKey (min 2자), limitValue (string | number | boolean), description (min 5자), unit (optional), effectiveDate (date, optional), expiryDate (date, optional)
- UpdateLimitSchema: CreateLimitSchema.omit({ planType: true, limitKey: true }).partial()

**카테고리 관리 Schema**:

- CreateCategorySchema: code (alphanumeric, min 2자, max 20자), name (min 2자), description (optional)
- UpdateCategorySchema: CreateCategorySchema.partial()

**사용자 관리 Schema**:

- UserFiltersSchema: planType (enum, optional), status (enum, optional), search (optional), sortBy (enum, optional), sortOrder (enum, optional)

**수동 데이터 관리 Schema**:

- CustomDataPointSchema: date (YYYY-MM-DD 형식), value (number), metadata (object, optional)
- CSVFileSchema: File 타입 검증 (csv, max 10MB)

**검증 규칙 예시**:

- 날짜: YYYY-MM-DD 형식 (ISO 8601)
- 이메일: email validation
- URL: url validation
- 코드: 영문자와 숫자만 허용, 특수문자 제외
- API 파라미터: JSON 형식 검증

---

## 3. React Components Tree

### 3.1 Layout Components

**AppLayout (packages/ui/src/layouts/AppLayout.tsx)**:

- 범용 레이아웃 컴포넌트
- Props로 모든 변형 처리:
  - navigation: 메뉴 아이템 배열
  - showUserMenu: 사용자 프로필 메뉴 표시 여부
  - sidebarCollapsible: 사이드바 접기/펴기 기능
  - headerActions: 헤더 우측 커스텀 영역
  - sidebarWidth: 사이드바 너비 커스터마이징
- apps/web과 apps/admin에서 공유

**apps/admin에서 사용**:

- (system)/layout.tsx에서 AppLayout import
- navigation에 Admin 메뉴 주입:
  - 지표 관리 (/indicators)
  - 사용자 관리 (/users)
  - 데이터 소스 (/data-sources)
  - 플랜 제한 (/plan-limits)
  - 템플릿 (/templates)
  - 카테고리 (/categories)
  - 수동 데이터 (/custom-data)

### 3.2 지표 관리 Components (US6.1, US6.2)

**Page Components**:

- IndicatorsPage: 지표 목록 페이지
  - Props: -
  - State: 검색어, 필터 (소스, 카테고리, 활성 상태)
  - Children: IndicatorList, SearchInput, FilterPanel

- IndicatorCreatePage: 지표 등록 페이지
  - Props: -
  - State: Form 데이터
  - Children: IndicatorForm

- IndicatorEditPage: 지표 수정 페이지
  - Props: indicatorId (URL params)
  - State: Form 데이터
  - Children: IndicatorForm, ConnectionTestButton

- IndicatorDetailPage: 지표 상세 페이지
  - Props: indicatorId (URL params)
  - State: -
  - Children: IndicatorDetail, UsageStats, ConnectionTestResult

**Sub Components**:

- IndicatorList: 지표 목록 테이블
  - Props: indicators, onEdit, onDelete, onTest
  - DataTable 컴포넌트 활용
  - 컬럼: 이름, 소스, 카테고리, 사용 횟수, 마지막 동기화, 활성 상태

- IndicatorForm: 지표 생성/수정 폼
  - Props: initialData, onSubmit, isEdit
  - react-hook-form + Zod 사용
  - 필드: 이름, 설명, 소스 선택, 카테고리 선택, 단위, 주기, API 파라미터
  - Children: IndicatorSourceSelector

- IndicatorSourceSelector: 소스별 지표 탐색
  - Props: source, value, onChange
  - 소스별 다른 UI:
    - KOSIS: 키워드 검색 + 계층 탐색
    - ECOS: 통계표 목록 → 세부 항목 선택
    - OECD: 데이터셋 목록
    - CUSTOM: 등록된 지표 목록
  - DataIntegration.searchIndicators() 사용

- ConnectionTestButton: 연결 테스트 버튼
  - Props: indicatorId
  - State: 테스트 진행 중, 결과
  - useTestIndicatorConnection() hook 사용

### 3.3 사용자 관리 Components (US6.3)

**Page Components**:

- UsersPage: 사용자 목록 페이지
  - Props: -
  - State: 필터 (플랜, 상태, 검색어, 정렬)
  - Children: UserList, UserFilters

- UserDetailPage: 사용자 상세 페이지
  - Props: userId (URL params)
  - State: -
  - Children: UserDetail, UserSubscriptionForm, UserActivityLog

**Sub Components**:

- UserList: 사용자 목록 테이블
  - Props: users, onViewDetail, onChangeSubscription
  - DataTable 컴포넌트 활용
  - 컬럼: 이메일, 이름, 플랜, 상태, 대시보드 수, 마지막 로그인, 가입일

- UserFilters: 필터 패널
  - Props: filters, onFilterChange
  - 필드: 플랜 타입, 상태, 검색어, 정렬 기준, 정렬 순서

- UserSubscriptionForm: 구독 변경 폼
  - Props: userId, currentPlan, onSubmit
  - 필드: 플랜 선택 (Free/Pro), 만료일 (optional), 변경 사유
  - 사유는 드롭다운(기존 사유 목록) + 직접 입력

- UserActivityLog: 활동 로그 테이블
  - Props: userId
  - useUserActivityLog() hook 사용
  - 컬럼: 날짜/시간, 액션, 리소스 타입, 리소스 ID, 상세

### 3.4 데이터 소스 관리 Components (US6.4)

**Page Components**:

- DataSourcesPage: 데이터 소스 목록 페이지
  - Props: -
  - State: -
  - Children: DataSourceList

- DataSourceCreatePage: 데이터 소스 추가 페이지
  - Props: -
  - State: Form 데이터
  - Children: DataSourceForm

- DataSourceEditPage: 데이터 소스 수정 페이지
  - Props: sourceId (URL params)
  - State: Form 데이터
  - Children: DataSourceForm, APIKeyUpdateForm, ConnectionTestButton

**Sub Components**:

- DataSourceList: 데이터 소스 목록 테이블
  - Props: dataSources, onEdit, onToggleStatus, onTest
  - 컬럼: 이름, 설명, 활성 상태, 생성일, 마지막 수정일, 수정자

- DataSourceForm: 데이터 소스 생성/수정 폼
  - Props: initialData, onSubmit, isEdit
  - 필드: 이름, 설명
  - API Key는 별도 폼에서 관리

- APIKeyInput: API Key 입력/표시
  - Props: value, onChange, showKey
  - 토글 버튼으로 표시/숨김 전환
  - 마스킹 처리 (****)

- ConnectionTestButton: 연결 테스트 버튼
  - Props: sourceId
  - State: 테스트 진행 중, 결과
  - useTestAPIConnection() hook 사용

### 3.5 플랜 제한 관리 Components (US6.5)

**Page Components**:

- PlanLimitsPage: 플랜 제한 목록 페이지
  - Props: -
  - State: 선택된 플랜 타입 (Free/Pro/All)
  - Children: PlanLimitList, PlanTypeSelector

- PlanLimitEditPage: 플랜 제한 수정 페이지
  - Props: limitId (URL params)
  - State: Form 데이터
  - Children: PlanLimitForm, LimitHistoryTable

**Sub Components**:

- PlanLimitList: 플랜 제한 목록 테이블
  - Props: limits, planType, onEdit, onAdd, onDelete
  - 컬럼: 플랜, 제한 키, 제한 값, 단위, 설명, 적용 기간, 활성 상태
  - 플랜별 그룹핑 표시

- PlanLimitForm: 플랜 제한 생성/수정 폼
  - Props: initialData, onSubmit, isEdit
  - 필드: 플랜 타입 (create 시만), 제한 키 (create 시만), 제한 값, 설명, 단위, 적용 기간, 만료일
  - 제한 값은 타입에 따라 다른 input (number, boolean, string)

- LimitHistoryTable: 변경 이력 테이블
  - Props: limitKey
  - useLimitHistory() hook 사용
  - 컬럼: 날짜/시간, 이전 값, 새로운 값, 변경자, 사유

### 3.6 템플릿 관리 Components (US6.6)

**Page Components**:

- TemplatesPage: 템플릿 목록 페이지
  - Props: -
  - State: 필터 (활성 상태, Pro 여부)
  - Children: TemplateList

- TemplateCreatePage: 템플릿 생성 페이지
  - Props: -
  - State: Form 데이터
  - Children: TemplateForm

- TemplateEditPage: 템플릿 수정 페이지
  - Props: templateId (URL params)
  - State: Form 데이터
  - Children: TemplateForm

**Sub Components**:

- TemplateList: 템플릿 목록 그리드
  - Props: templates, onEdit, onDelete, onToggleStatus
  - 카드 형식 레이아웃 (썸네일, 이름, 설명, 사용 횟수)

- TemplateForm: 템플릿 생성/수정 폼
  - Props: initialData, onSubmit, isEdit
  - 필드: 이름, 설명, 카테고리, 썸네일 (업로드), Pro 전용 여부, 위젯 구성
  - Children: TemplatePreview

- TemplatePreview: 템플릿 미리보기
  - Props: widgets, layout
  - 위젯 배치 시각화

### 3.7 카테고리 관리 Components (US6.7)

**Page Components**:

- CategoriesPage: 카테고리 목록 페이지
  - Props: -
  - State: 편집 모드 (정렬 모드 vs 일반 모드)
  - Children: CategoryList, CategoryReorder

**Sub Components**:

- CategoryList: 카테고리 목록 테이블
  - Props: categories, onEdit, onDelete, onToggleStatus, onReorder
  - 컬럼: 순서, 코드, 이름, 설명, 사용 개수, 활성 상태
  - Drag & Drop으로 순서 변경

- CategoryForm: 카테고리 생성/수정 폼
  - Props: initialData, onSubmit, isEdit
  - FormDialog 컴포넌트 사용
  - 필드: 코드, 이름, 설명

- CategoryReorder: 카테고리 순서 변경
  - Props: categories, onReorder
  - Drag & Drop 리스트
  - useReorderCategories() hook 사용

### 3.8 수동 데이터 관리 Components (US6.8)

**Page Components**:

- CustomDataPage: 수동 데이터 목록 페이지
  - Props: -
  - State: 선택된 지표 ID
  - Children: IndicatorSelector, CustomDataList

- CustomDataUploadPage: CSV 업로드 페이지
  - Props: indicatorId (URL params)
  - State: 업로드 파일, 미리보기 데이터
  - Children: CSVUploader, DataPreview

**Sub Components**:

- CustomDataList: 데이터 포인트 목록 테이블
  - Props: indicatorId, dataPoints, onEdit, onDelete, onAdd
  - 컬럼: 날짜, 값, 메타데이터, 생성자, 생성일, 수정일
  - 건당 데이터 추가 버튼

- CSVUploader: CSV 파일 업로드
  - Props: indicatorId, onUploadSuccess
  - CSV 양식 다운로드 버튼
  - 파일 선택 input (drag & drop 지원)
  - 업로드 전 검증 (csvValidation service 사용)
  - 검증 결과 표시

- DataPreview: 데이터 미리보기 테이블
  - Props: preview (CustomDataPoint[])
  - 업로드 전 데이터 확인
  - 총 행 수, 임포트될 행 수, 에러 행 수 표시

- DataPointForm: 데이터 포인트 생성/수정 폼
  - Props: indicatorId, initialData, onSubmit, isEdit
  - FormDialog 컴포넌트 사용
  - 필드: 날짜, 값, 메타데이터 (JSON)

- CustomDataHistoryTable: 변경 이력 테이블
  - Props: indicatorId
  - useCustomDataHistory() hook 사용
  - 컬럼: 날짜/시간, 데이터 포인트, 액션, 이전 값, 새로운 값, 변경자

### 3.9 공통 Components (packages/ui/src/components/)

**DataTable**: 공통 테이블 컴포넌트

- Props: columns, data, onRowClick, pagination, sorting, filtering
- @tanstack/react-table 사용
- Shadcn/UI Table 컴포넌트 래핑

**FormDialog**: 공통 다이얼로그 폼

- Props: open, onClose, title, children, onSubmit
- Shadcn/UI Dialog 컴포넌트 사용
- 생성/수정 폼에 재사용

**ConfirmDialog**: 확인 다이얼로그

- Props: open, onClose, title, message, onConfirm
- 삭제, 활성화/비활성화 등 확인용

**Toast**: 알림 컴포넌트

- Shadcn/UI Toast 사용
- 성공/에러/경고 메시지 표시

**SearchInput**: 검색 입력

- Props: value, onChange, placeholder
- debounce 적용

**Pagination**: 페이지네이션

- Props: currentPage, totalPages, onPageChange
- Shadcn/UI Pagination 컴포넌트 사용

---

## 4. TanStack Query Hooks

### 4.1 Query Key 전략

**결정**: Resource 기반 Query Key 사용

**Query Key 구조**:

- 목록 조회: ['indicators', 'list']
- 상세 조회: ['indicators', indicatorId]
- 필터 적용: ['users', 'list', filters]
- 이력 조회: ['custom-data', indicatorId, 'history']

**Resource 이름**:

- indicators, users, data-sources, plan-limits, templates, categories, custom-data

### 4.2 지표 관리 Hooks (US6.1, US6.2)

**useIndicators()**:

- Query Key: ['indicators', 'list']
- Query Function: Supabase에서 indicators 테이블 조회
- staleTime: 5분
- 반환: { data: ManagedIndicator[], isLoading, error }

**useIndicator(id: string)**:

- Query Key: ['indicators', id]
- Query Function: Supabase에서 특정 indicator 조회
- Enabled: id가 존재할 때만
- 반환: { data: ManagedIndicator, isLoading, error }

**useCreateIndicator()**:

- Mutation Function: Supabase에 indicator 생성
- onSuccess: ['indicators', 'list'] 무효화
- Optimistic Update 없음
- indicatorValidation service로 사전 검증
- 반환: { mutate, mutateAsync, isLoading, error }

**useUpdateIndicator()**:

- Mutation Function: Supabase에서 indicator 수정
- onSuccess: ['indicators', id], ['indicators', 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useDeleteIndicator()**:

- Mutation Function: Supabase에서 indicator 삭제
- onSuccess: ['indicators', 'list'] 무효화
- ConfirmDialog로 확인 필요
- 반환: { mutate, mutateAsync, isLoading, error }

**useTestIndicatorConnection()**:

- Mutation Function: 외부 API (KOSIS, ECOS, OECD) 연결 테스트
- 캐시 없음 (매번 테스트)
- 반환: { mutate, mutateAsync, isLoading, data: TestResult, error }

### 4.3 사용자 관리 Hooks (US6.3)

**useUsers(filters: UserFilters)**:

- Query Key: ['users', 'list', filters]
- Query Function: Supabase users 테이블 조회 + 필터 적용
- staleTime: 3분
- 반환: { data: AdminUserView[], isLoading, error }

**useUserActivityLog(userId: string)**:

- Query Key: ['users', userId, 'activity-log']
- Query Function: Supabase activity_logs 테이블 조회
- Enabled: userId가 존재할 때만
- 반환: { data: ActivityLog[], isLoading, error }

**useUpdateUserSubscription()**:

- Mutation Function: Supabase users 테이블 subscription 수정
- onSuccess: ['users', 'list', filters], ['users', userId] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useActivateUser()**:

- Mutation Function: Supabase users 테이블 status를 'active'로 변경
- onSuccess: ['users', 'list', filters], ['users', userId] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useDeactivateUser()**:

- Mutation Function: Supabase users 테이블 status를 'inactive'로 변경
- onSuccess: ['users', 'list', filters], ['users', userId] 무효화
- ConfirmDialog로 확인 필요
- 반환: { mutate, mutateAsync, isLoading, error }

### 4.4 데이터 소스 관리 Hooks (US6.4)

**useDataSources()**:

- Query Key: ['data-sources', 'list']
- Query Function: Supabase data_sources 테이블 조회
- staleTime: 10분 (자주 변경되지 않음)
- 반환: { data: DataSource[], isLoading, error }

**useCreateDataSource()**:

- Mutation Function: Supabase data_sources 테이블 생성
- API Key는 암호화하여 저장
- onSuccess: ['data-sources', 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useUpdateDataSource()**:

- Mutation Function: Supabase data_sources 테이블 수정
- API Key 제외 (별도 hook 사용)
- onSuccess: ['data-sources', 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useUpdateDataSourceAPIKey()**:

- Mutation Function: Supabase data_sources 테이블 apiKey만 수정
- 암호화하여 저장
- onSuccess: ['data-sources', 'list'] 무효화
- 민감한 작업이므로 재인증 필요 (UI에서 처리)
- 반환: { mutate, mutateAsync, isLoading, error }

**useToggleDataSourceStatus()**:

- Mutation Function: Supabase data_sources 테이블 isActive 토글
- Optimistic Update 적용
- onSuccess: ['data-sources', 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useTestAPIConnection()**:

- Mutation Function: 특정 데이터 소스 연결 테스트
- 캐시 없음
- 반환: { mutate, mutateAsync, isLoading, data: TestResult, error }

### 4.5 플랜 제한 관리 Hooks (US6.5)

**usePlanLimits(planType?: 'free' | 'pro')**:

- Query Key: ['plan-limits', 'list', planType]
- Query Function: Supabase plan_limits 테이블 조회 + 필터
- staleTime: 10분
- 반환: { data: PlanLimitConfig[], isLoading, error }

**useAddPlanLimit()**:

- Mutation Function: Supabase plan_limits 테이블 생성
- onSuccess: ['plan-limits', 'list', planType] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useUpdatePlanLimit()**:

- Mutation Function: Supabase plan_limits 테이블 수정
- onSuccess: ['plan-limits', 'list', planType], ['plan-limits', id] 무효화
- Subscription 패키지에서 getPlanLimits() 캐시도 무효화 필요
- 반환: { mutate, mutateAsync, isLoading, error }

**useRemovePlanLimit()**:

- Mutation Function: Supabase plan_limits 테이블 삭제 (soft delete: isActive=false)
- onSuccess: ['plan-limits', 'list', planType] 무효화
- ConfirmDialog로 확인 필요
- 반환: { mutate, mutateAsync, isLoading, error }

**useLimitHistory(limitKey: string)**:

- Query Key: ['plan-limits', limitKey, 'history']
- Query Function: Supabase plan_limit_history 테이블 조회
- Enabled: limitKey가 존재할 때만
- 반환: { data: PlanLimitHistory[], isLoading, error }

### 4.6 템플릿 관리 Hooks (US6.6)

**useTemplates()**:

- Query Key: ['templates', 'list']
- Query Function: Supabase templates 테이블 조회
- staleTime: 5분
- 반환: { data: DashboardTemplate[], isLoading, error }

**useCreateTemplate()**:

- Mutation Function: Supabase templates 테이블 생성
- 썸네일 업로드는 Supabase Storage 사용 (선택적)
- onSuccess: ['templates', 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useUpdateTemplate()**:

- Mutation Function: Supabase templates 테이블 수정
- onSuccess: ['templates', 'list'], ['templates', id] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useDeleteTemplate()**:

- Mutation Function: Supabase templates 테이블 삭제
- onSuccess: ['templates', 'list'] 무효화
- ConfirmDialog로 확인 필요
- 반환: { mutate, mutateAsync, isLoading, error }

### 4.7 카테고리 관리 Hooks (US6.7)

**useCategories()**:

- Query Key: ['categories', 'list']
- Query Function: Supabase categories 테이블 조회 (order 순 정렬)
- staleTime: 10분
- 반환: { data: Category[], isLoading, error }

**useCreateCategory()**:

- Mutation Function: Supabase categories 테이블 생성
- onSuccess: ['categories', 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useUpdateCategory()**:

- Mutation Function: Supabase categories 테이블 수정
- onSuccess: ['categories', 'list'], ['categories', id] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useDeleteCategory()**:

- Mutation Function: Supabase categories 테이블 삭제
- 삭제 전 usageCount 확인 (0이 아니면 경고)
- onSuccess: ['categories', 'list'] 무효화
- ConfirmDialog로 확인 필요
- 반환: { mutate, mutateAsync, isLoading, error }

**useReorderCategories()**:

- Mutation Function: Supabase categories 테이블 order 일괄 수정
- Optimistic Update 적용
- onSuccess: ['categories', 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useToggleCategoryStatus()**:

- Mutation Function: Supabase categories 테이블 isActive 토글
- Optimistic Update 적용
- onSuccess: ['categories', 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

### 4.8 수동 데이터 관리 Hooks (US6.8)

**useCustomData(indicatorId: string)**:

- Query Key: ['custom-data', indicatorId, 'list']
- Query Function: Supabase custom_data 테이블 조회 (특정 지표의 데이터)
- Enabled: indicatorId가 존재할 때만
- staleTime: 5분
- 반환: { data: CustomDataPoint[], isLoading, error }

**useUploadCustomData()**:

- Mutation Function: CSV 파일 파싱 → csvValidation service로 검증 → Supabase custom_data 테이블 일괄 생성
- onSuccess: ['custom-data', indicatorId, 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, data: CustomDataImportResult, error }

**useAddCustomDataPoint()**:

- Mutation Function: Supabase custom_data 테이블 생성
- onSuccess: ['custom-data', indicatorId, 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useUpdateCustomDataPoint()**:

- Mutation Function: Supabase custom_data 테이블 수정
- onSuccess: ['custom-data', indicatorId, 'list'] 무효화
- 반환: { mutate, mutateAsync, isLoading, error }

**useDeleteCustomDataPoint()**:

- Mutation Function: Supabase custom_data 테이블 삭제
- onSuccess: ['custom-data', indicatorId, 'list'] 무효화
- ConfirmDialog로 확인 필요
- 반환: { mutate, mutateAsync, isLoading, error }

**useCustomDataHistory(indicatorId: string)**:

- Query Key: ['custom-data', indicatorId, 'history']
- Query Function: Supabase custom_data_history 테이블 조회
- Enabled: indicatorId가 존재할 때만
- 반환: { data: CustomDataHistory[], isLoading, error }

### 4.9 모니터링 Hooks

**useSystemMetrics()**:

- Query Key: ['system', 'metrics']
- Query Function: Supabase에서 집계 쿼리 실행 (users, dashboards, widgets 개수 등)
- refetchInterval: 30초 (자동 갱신)
- staleTime: 30초
- 반환: { data: SystemMetrics, isLoading, error }

**useDashboardStats()**:

- Query Key: ['system', 'dashboard-stats']
- Query Function: Supabase에서 집계 쿼리 실행 (대시보드 통계)
- staleTime: 5분
- 반환: { data: DashboardStats, isLoading, error }

### 4.10 캐싱 전략

**staleTime 설정**:

- 자주 변경되지 않는 데이터: 10분 (data-sources, plan-limits, categories)
- 보통 데이터: 5분 (indicators, templates, custom-data)
- 자주 변경되는 데이터: 3분 (users)
- 실시간 데이터: 30초 (system-metrics)
- 테스트/일회성: 0 (connection test)

**cacheTime 설정**:

- 기본값 사용 (5분)

**Invalidation 전략**:

- Mutation 성공 시 관련 Query 무효화
- 목록 조회 Query는 항상 무효화
- 상세 조회 Query는 해당 항목만 무효화
- 연관된 다른 Resource의 Query도 무효화 필요 시 처리

**Optimistic Updates 적용**:

- 토글 작업 (활성화/비활성화): Optimistic Update 적용
- 순서 변경 (카테고리 재정렬): Optimistic Update 적용
- 기타 CRUD: Optimistic Update 없음 (일관성 우선)

---

## 5. Business Logic (선택적)

### 5.1 분리할 Service

복잡한 검증 로직만 별도 Service로 분리:

**csvValidation.ts** (packages/admin-console/src/services/validation/):

- 역할: CSV 파일 업로드 전 데이터 검증
- 함수:
  - validateCSVFile(file: File): Result<boolean, ValidationError[]> - 파일 형식 검증 (확장자, 크기)
  - parseCSV(file: File): Promise<Result<ParsedCSV, ParseError>> - CSV 파싱
  - validateCSVData(data: ParsedCSV): Result<ValidatedData, ValidationError[]> - 데이터 검증
- 검증 규칙:
  - 필수 컬럼: date, value
  - 날짜 형식: YYYY-MM-DD (ISO 8601)
  - 숫자 타입: value는 number로 파싱 가능
  - 중복 데이터: 동일 날짜의 중복 체크
  - 최대 행 수: 10,000행 제한
- 에러 형식: { row: number, column: string, message: string }

**indicatorValidation.ts** (packages/admin-console/src/services/validation/):

- 역할: 지표 소스별 API 파라미터 검증
- 함수:
  - validateKOSISParams(params: any): Result<boolean, ValidationError> - KOSIS 파라미터 검증
  - validateECOSParams(params: any): Result<boolean, ValidationError> - ECOS 파라미터 검증
  - validateOECDParams(params: any): Result<boolean, ValidationError> - OECD 파라미터 검증
- 검증 규칙:
  - KOSIS: 통계표 코드, 항목 코드, 기간 형식
  - ECOS: 통계코드, 주기, 시작일/종료일 형식
  - OECD: 데이터셋 ID, 국가 코드, 시계열 필터
  - CUSTOM: 검증 없음

### 5.2 Hook/컴포넌트에 포함

복잡도가 낮은 로직은 Hook/컴포넌트에서 직접 처리:

**플랜 제한 영향 계산** (PlanLimitEditPage):

- 제한값 감소 시 영향받는 사용자 수 쿼리
- Supabase 쿼리 하나로 처리 가능

**카테고리 참조 확인** (useDeleteCategory):

- 카테고리를 사용하는 지표/템플릿 개수 쿼리
- Supabase 쿼리로 처리

### 5.3 Service 작성 원칙

- 순수 함수로 작성 (side effect 없음)
- 명확한 TypeScript 타입 정의
- 단일 책임 원칙 준수
- 에러는 throw 대신 Result 타입으로 반환
- Result 타입: { success: boolean, data?: T, error?: E }

---

## 6. 파일 구조

### 6.1 packages/admin-console/ 구조

```
packages/admin-console/
├── src/
│   ├── components/           # React Components
│   │   ├── indicators/       # 지표 관리 컴포넌트
│   │   │   ├── IndicatorList.tsx
│   │   │   ├── IndicatorForm.tsx
│   │   │   ├── IndicatorSourceSelector.tsx
│   │   │   └── ConnectionTestButton.tsx
│   │   ├── users/            # 사용자 관리 컴포넌트
│   │   │   ├── UserList.tsx
│   │   │   ├── UserFilters.tsx
│   │   │   ├── UserSubscriptionForm.tsx
│   │   │   └── UserActivityLog.tsx
│   │   ├── data-sources/     # 데이터 소스 관리 컴포넌트
│   │   │   ├── DataSourceList.tsx
│   │   │   ├── DataSourceForm.tsx
│   │   │   └── APIKeyInput.tsx
│   │   ├── plan-limits/      # 플랜 제한 관리 컴포넌트
│   │   │   ├── PlanLimitList.tsx
│   │   │   ├── PlanLimitForm.tsx
│   │   │   └── LimitHistoryTable.tsx
│   │   ├── templates/        # 템플릿 관리 컴포넌트
│   │   │   ├── TemplateList.tsx
│   │   │   ├── TemplateForm.tsx
│   │   │   └── TemplatePreview.tsx
│   │   ├── categories/       # 카테고리 관리 컴포넌트
│   │   │   ├── CategoryList.tsx
│   │   │   ├── CategoryForm.tsx
│   │   │   └── CategoryReorder.tsx
│   │   └── custom-data/      # 수동 데이터 관리 컴포넌트
│   │       ├── CustomDataList.tsx
│   │       ├── CSVUploader.tsx
│   │       ├── DataPreview.tsx
│   │       ├── DataPointForm.tsx
│   │       └── CustomDataHistoryTable.tsx
│   ├── hooks/                # TanStack Query Hooks
│   │   ├── indicators/
│   │   │   ├── useIndicators.ts
│   │   │   ├── useIndicator.ts
│   │   │   ├── useCreateIndicator.ts
│   │   │   ├── useUpdateIndicator.ts
│   │   │   ├── useDeleteIndicator.ts
│   │   │   └── useTestIndicatorConnection.ts
│   │   ├── users/
│   │   │   ├── useUsers.ts
│   │   │   ├── useUserActivityLog.ts
│   │   │   ├── useUpdateUserSubscription.ts
│   │   │   ├── useActivateUser.ts
│   │   │   └── useDeactivateUser.ts
│   │   ├── data-sources/
│   │   │   ├── useDataSources.ts
│   │   │   ├── useCreateDataSource.ts
│   │   │   ├── useUpdateDataSource.ts
│   │   │   ├── useUpdateDataSourceAPIKey.ts
│   │   │   ├── useToggleDataSourceStatus.ts
│   │   │   └── useTestAPIConnection.ts
│   │   ├── plan-limits/
│   │   │   ├── usePlanLimits.ts
│   │   │   ├── useAddPlanLimit.ts
│   │   │   ├── useUpdatePlanLimit.ts
│   │   │   ├── useRemovePlanLimit.ts
│   │   │   └── useLimitHistory.ts
│   │   ├── templates/
│   │   │   ├── useTemplates.ts
│   │   │   ├── useCreateTemplate.ts
│   │   │   ├── useUpdateTemplate.ts
│   │   │   └── useDeleteTemplate.ts
│   │   ├── categories/
│   │   │   ├── useCategories.ts
│   │   │   ├── useCreateCategory.ts
│   │   │   ├── useUpdateCategory.ts
│   │   │   ├── useDeleteCategory.ts
│   │   │   ├── useReorderCategories.ts
│   │   │   └── useToggleCategoryStatus.ts
│   │   ├── custom-data/
│   │   │   ├── useCustomData.ts
│   │   │   ├── useUploadCustomData.ts
│   │   │   ├── useAddCustomDataPoint.ts
│   │   │   ├── useUpdateCustomDataPoint.ts
│   │   │   ├── useDeleteCustomDataPoint.ts
│   │   │   └── useCustomDataHistory.ts
│   │   └── monitoring/
│   │       ├── useSystemMetrics.ts
│   │       └── useDashboardStats.ts
│   ├── types/                # TypeScript Interfaces
│   │   ├── indicator.types.ts
│   │   ├── user.types.ts
│   │   ├── dataSource.types.ts
│   │   ├── planLimit.types.ts
│   │   ├── template.types.ts
│   │   ├── category.types.ts
│   │   ├── customData.types.ts
│   │   └── index.ts
│   ├── schemas/              # Zod Schemas
│   │   ├── indicator.schema.ts
│   │   ├── user.schema.ts
│   │   ├── dataSource.schema.ts
│   │   ├── planLimit.schema.ts
│   │   ├── template.schema.ts
│   │   ├── category.schema.ts
│   │   ├── customData.schema.ts
│   │   └── index.ts
│   ├── services/             # Business Logic (선택적)
│   │   └── validation/
│   │       ├── csvValidation.ts
│   │       └── indicatorValidation.ts
│   ├── lib/                  # 유틸리티
│   │   ├── supabase.ts       # Supabase 클라이언트
│   │   └── utils.ts          # 공통 유틸리티
│   └── index.ts              # Public API
├── package.json
└── tsconfig.json
```

### 6.2 apps/admin/ 페이지 구조

```
apps/admin/
├── app/
│   ├── (system)/             # Admin Console 라우트 그룹
│   │   ├── layout.tsx        # AppLayout 사용
│   │   ├── page.tsx          # 대시보드 홈 (SystemMetrics, DashboardStats)
│   │   ├── indicators/
│   │   │   ├── page.tsx      # IndicatorsPage
│   │   │   ├── create/
│   │   │   │   └── page.tsx  # IndicatorCreatePage
│   │   │   ├── [id]/
│   │   │   │   ├── page.tsx  # IndicatorDetailPage
│   │   │   │   └── edit/
│   │   │   │       └── page.tsx # IndicatorEditPage
│   │   ├── users/
│   │   │   ├── page.tsx      # UsersPage
│   │   │   └── [id]/
│   │   │       └── page.tsx  # UserDetailPage
│   │   ├── data-sources/
│   │   │   ├── page.tsx      # DataSourcesPage
│   │   │   ├── create/
│   │   │   │   └── page.tsx  # DataSourceCreatePage
│   │   │   └── [id]/
│   │   │       └── edit/
│   │   │           └── page.tsx # DataSourceEditPage
│   │   ├── plan-limits/
│   │   │   ├── page.tsx      # PlanLimitsPage
│   │   │   └── [id]/
│   │   │       └── edit/
│   │   │           └── page.tsx # PlanLimitEditPage
│   │   ├── templates/
│   │   │   ├── page.tsx      # TemplatesPage
│   │   │   ├── create/
│   │   │   │   └── page.tsx  # TemplateCreatePage
│   │   │   └── [id]/
│   │   │       └── edit/
│   │   │           └── page.tsx # TemplateEditPage
│   │   ├── categories/
│   │   │   └── page.tsx      # CategoriesPage (단일 페이지, FormDialog 사용)
│   │   └── custom-data/
│   │       ├── page.tsx      # CustomDataPage
│   │       └── upload/
│   │           └── page.tsx  # CustomDataUploadPage
│   ├── layout.tsx            # Root Layout
│   └── providers.tsx         # TanStack Query Provider
├── public/
└── package.json
```

### 6.3 파일 네이밍 컨벤션

- **컴포넌트**: PascalCase (IndicatorList.tsx)
- **Hooks**: camelCase (useIndicators.ts)
- **Types**: camelCase (indicator.types.ts)
- **Schemas**: camelCase (indicator.schema.ts)
- **Services**: camelCase (csvValidation.ts)
- **페이지**: page.tsx (Next.js 규칙)
- **레이아웃**: layout.tsx (Next.js 규칙)

---

## 7. 의존성

### 7.1 내부 의존성 (E-Torch 패키지)

**packages/ui**:

- AppLayout: 범용 레이아웃 컴포넌트
- DataTable, FormDialog, ConfirmDialog, Toast, SearchInput, Pagination: 공통 UI 컴포넌트
- Shadcn/UI 컴포넌트 래퍼

**packages/core**:

- 공통 타입 (User, Session, Indicator 등)
- 공통 유틸리티 함수
- 상수 정의

**packages/query**:

- TanStack Query 관련 공통 설정
- Query Client 설정
- 공통 Query Hooks (선택적)

**packages/auth** (Authentication Contract):

- getCurrentUser(): User | null
- hasRole(role: 'admin'): boolean
- 관리자 권한 확인

**packages/data-sources** (DataIntegration Contract):

- searchIndicators(query, filters): Promise<Indicator[]>
- 지표 탐색 시 사용 (IndicatorSourceSelector)

### 7.2 외부 의존성 (npm 패키지)

**React 생태계**:

- react: ^19.0.0
- react-dom: ^19.0.0
- next: ^15.0.0

**TanStack Query**:

- @tanstack/react-query: ^5.0.0
- @tanstack/react-table: ^8.0.0 (DataTable 사용)

**폼 관리**:

- react-hook-form: ^7.0.0
- zod: ^3.0.0
- @hookform/resolvers: ^3.0.0

**Supabase**:

- @supabase/supabase-js: ^2.0.0

**UI 컴포넌트**:

- shadcn/ui 컴포넌트 (packages/ui에서 재사용)
- lucide-react: ^0.x (아이콘)

**유틸리티**:

- date-fns: ^3.0.0 (날짜 처리)
- papaparse: ^5.0.0 (CSV 파싱)

### 7.3 Supabase 의존성

**테이블**:

- indicators: 지표 메타데이터
- users: 사용자 정보 (RLS: admin 역할 필요)
- data_sources: 데이터 소스 정보
- plan_limits: 플랜 제한 설정
- plan_limit_history: 플랜 제한 변경 이력
- templates: 대시보드 템플릿
- categories: 카테고리 마스터
- custom_data: 수동 입력 데이터
- custom_data_history: 수동 데이터 변경 이력
- activity_logs: 관리자 활동 로그

**RLS 정책**:

- 모든 테이블에 admin 역할 필수 체크
- SELECT, INSERT, UPDATE, DELETE 모두 admin 역할 필요
- activity_logs는 INSERT만 허용, UPDATE/DELETE 금지

**Storage (선택적)**:

- templates/thumbnails: 템플릿 썸네일 이미지
- custom-data/csv: CSV 파일 임시 저장 (선택적)

---

## 8. 보안 고려사항

### 8.1 인증 및 권한

**관리자 인증**:

- 모든 Admin Console 페이지는 admin 역할 필수
- apps/admin의 (system)/layout.tsx에서 권한 확인
- Authentication.hasRole('admin') 호출
- 권한 없으면 403 에러 페이지로 리다이렉트

**재인증**:

- API Key 변경 등 민감한 작업 수행 시 재인증 요구
- 모달로 비밀번호 재입력 요청

### 8.2 데이터 보호

**API Key 암호화**:

- 데이터 소스 API Key는 암호화하여 Supabase에 저장
- 표시 시 마스킹 처리 (****)
- 토글 버튼으로 전체 표시/숨김

**민감 정보 로깅**:

- Activity Log에 API Key, 비밀번호 등 민감 정보 제외
- 변경 사유, 변경자, 변경 시간만 기록

### 8.3 감사 로그

**모든 관리 작업 기록**:

- 지표 생성/수정/삭제
- 사용자 구독 변경, 계정 활성화/비활성화
- 데이터 소스 생성/수정/삭제, API Key 변경
- 플랜 제한 변경
- 템플릿 생성/수정/삭제
- 카테고리 생성/수정/삭제
- 수동 데이터 입력/수정/삭제

**Activity Log 필드**:

- userId: 관리자 ID
- action: 액션 타입 (create, update, delete, activate, deactivate 등)
- resourceType: 리소스 타입 (indicator, user, data_source 등)
- resourceId: 리소스 ID
- details: JSON 형식의 상세 정보
- ipAddress: IP 주소
- userAgent: User Agent
- createdAt: 로그 생성 시간

### 8.4 입력 검증

**클라이언트 검증**:

- Zod Schema로 Form 유효성 검증
- 타입, 형식, 길이, 정규표현식 검증

**서버 검증**:

- Supabase RLS로 권한 체크
- Database 제약 조건 (NOT NULL, UNIQUE, FOREIGN KEY)

**CSV 파일 검증**:

- 파일 크기 제한 (10MB)
- 확장자 체크 (.csv)
- 최대 행 수 제한 (10,000행)
- csvValidation service로 데이터 검증

---

## 9. 다음 단계

### 9.1 BFF API 구현

Admin Console의 22개 메서드를 BFF API Routes로 구현:

**apps/admin/app/api/ 구조**:

```
app/api/admin/
├── indicators/
│   ├── route.ts              # GET /api/admin/indicators, POST
│   ├── [id]/
│   │   ├── route.ts          # GET, PATCH, DELETE
│   │   └── test/
│   │       └── route.ts      # POST /api/admin/indicators/:id/test
├── users/
│   ├── route.ts              # GET /api/admin/users
│   └── [id]/
│       ├── subscription/
│       │   └── route.ts      # PATCH
│       ├── activate/
│       │   └── route.ts      # POST
│       ├── deactivate/
│       │   └── route.ts      # POST
│       └── activity/
│           └── route.ts      # GET
├── datasources/
│   ├── route.ts              # GET, POST
│   └── [id]/
│       ├── route.ts          # PATCH, DELETE
│       ├── apikey/
│       │   └── route.ts      # PATCH
│       ├── status/
│       │   └── route.ts      # PATCH
│       └── test/
│           └── route.ts      # POST
├── plan-limits/
│   ├── route.ts              # GET, POST
│   └── [id]/
│       ├── route.ts          # PATCH, DELETE
│       └── history/
│           └── route.ts      # GET
├── templates/
│   ├── route.ts              # GET, POST
│   └── [id]/
│       └── route.ts          # GET, PATCH, DELETE
├── categories/
│   ├── route.ts              # GET, POST
│   ├── reorder/
│   │   └── route.ts          # PATCH
│   └── [id]/
│       ├── route.ts          # PATCH, DELETE
│       └── status/
│           └── route.ts      # PATCH
├── custom-data/
│   └── [indicatorId]/
│       ├── route.ts          # GET, POST
│       ├── upload/
│       │   └── route.ts      # POST
│       ├── history/
│       │   └── route.ts      # GET
│       └── [id]/
│           └── route.ts      # PATCH, DELETE
└── metrics/
    ├── route.ts              # GET /api/admin/metrics
    └── dashboard-stats/
        └── route.ts          # GET
```

**BFF API 구현 원칙**:

- Next.js 15 API Routes 사용
- Supabase 클라이언트로 직접 DB 접근
- Request Body는 Zod Schema로 검증
- 에러 핸들링 (try-catch, HTTP 상태 코드)
- 권한 체크 (admin 역할 확인)
- Activity Log 기록

### 9.2 Supabase 스키마 정의

Admin Console에서 사용하는 테이블 스키마를 Supabase에 정의:

**테이블 목록**:

- indicators
- users (기존 auth.users 확장)
- data_sources
- plan_limits
- plan_limit_history
- templates
- categories
- custom_data
- custom_data_history
- activity_logs

**RLS 정책 설정**:

- admin 역할 체크
- SELECT, INSERT, UPDATE, DELETE 권한 제어

**인덱스 최적화**:

- 자주 조회되는 컬럼에 인덱스 추가
- Foreign Key 인덱스

### 9.3 테스트 계획 수립

**단위 테스트**:

- Validation Service 테스트 (csvValidation, indicatorValidation)
- Zod Schema 테스트
- 유틸리티 함수 테스트

**통합 테스트**:

- TanStack Query Hooks 테스트 (MSW로 API 모킹)
- 컴포넌트 테스트 (React Testing Library)

**E2E 테스트**:

- 주요 User Flow 테스트 (Playwright)
- 지표 등록 → 수정 → 삭제
- 사용자 구독 변경
- CSV 업로드

### 9.4 배포 준비

**Vercel 배포 설정**:

- apps/admin을 별도 Vercel 프로젝트로 배포
- 환경 변수 설정 (SUPABASE_URL, SUPABASE_ANON_KEY 등)
- 도메인 설정 (admin.e-torch.com)

**CI/CD 파이프라인**:

- GitHub Actions 설정
- apps/admin 변경 시 자동 배포
- 빌드 에러 체크

---

## 10. 요약

이 문서는 Admin Console Feature Module의 전체 설계를 정의합니다:

1. **8개 User Stories** (US6.1~6.8)를 7개 주요 페이지로 구현
2. **22개 메서드**를 TanStack Query Hooks로 제공
3. **DDD 패턴 사용 금지**, TypeScript Interface + Zod Schema + React + TanStack Query 사용
4. **Multi-Zone 구조**에서 packages/ui를 공유하여 일관된 UX 제공
5. **Resource 기반 Query Key** 전략으로 단순하고 명확한 캐싱
6. **선택적 Business Logic** 분리 (csvValidation, indicatorValidation)
7. **보안 고려**: 관리자 권한 체크, API Key 암호화, 감사 로그

다음 단계는 BFF API 구현, Supabase 스키마 정의, 테스트 계획 수립입니다.
