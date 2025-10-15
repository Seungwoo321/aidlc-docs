# E-Torch Integration Contract

## 개요

이 문서는 E-Torch 프로젝트의 6개 독립 단위(Unit) 간 통합 계약을 정의합니다.
각 단위는 독립적으로 개발 가능하며, 명확한 인터페이스를 통해 통신합니다.

## 단위 간 의존성 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│                        Admin Console                         │
│                     (독립 MFA 애플리케이션)                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      User Application                        │
│                                                              │
│  ┌──────────────────────────────────┐                       │
│  │           Dashboard              │                       │
│  └──────────────┬───────────────────┘                       │
│                 │                                            │
│                 ▼                                            │
│  ┌──────────────────────────────────┐                       │
│  │         Widget Library            │                       │
│  └──────────────┬───────────────────┘                       │
│                 │                                            │
│                 ▼                                            │
│  ┌──────────────────────────────────┐                       │
│  │       Data Integration            │                       │
│  └──────────────────────────────────┘                       │
│                                                              │
│  ┌──────────────┐     ┌──────────────┐                     │
│  │Authentication│────▶│ Subscription │                     │
│  └──────────────┘     └──────────────┘                     │
│         ▲                     ▲                              │
│         └─────────┬───────────┘                              │
│              All Units                                       │
└─────────────────────────────────────────────────────────────┘
```

## 1. Dashboard Unit

### 제공하는 인터페이스

```typescript
interface DashboardContract {
  // 대시보드 조회 및 렌더링
  renderDashboard(dashboardId: string): Promise<void>
  refreshDashboard(dashboardId: string): Promise<void>
  getDashboardList(options?: ListOptions): Promise<Dashboard[]>
  getPublicDashboards(options?: ListOptions): Promise<Dashboard[]>
  getDashboards(userId: string): Promise<Dashboard[]>
  getDefaultDashboard(userId: string): Promise<Dashboard | null>
  setDefaultDashboard(dashboardId: string): Promise<void>

  // 대시보드 CRUD
  createDashboard(data: CreateDashboardDto): Promise<Dashboard>
  createFromTemplate(templateId: string, data: CreateFromTemplateDto): Promise<Dashboard>
  duplicateDashboard(dashboardId: string, data: DuplicateDto): Promise<Dashboard>
  updateDashboard(id: string, data: UpdateDashboardDto): Promise<Dashboard>
  deleteDashboard(id: string): Promise<void>

  // 템플릿 활용
  getAvailableTemplates(): Promise<DashboardTemplate[]>

  // 레이아웃 및 위젯 배치
  updateLayout(dashboardId: string, layout: WidgetLayout[]): Promise<void>
  autoSaveLayout(dashboardId: string, layout: WidgetLayout[]): Promise<void>
  addWidgetToDashboard(dashboardId: string, widgetId: string): Promise<void>
  copyWidgetToDashboard(sourceWidgetId: string, targetDashboardId: string): Promise<void>
  removeWidgetFromDashboard(dashboardId: string, widgetId: string): Promise<void>
  lazyLoadWidgets(dashboardId: string, viewportWidgetIds: string[]): Promise<void>

  // 버전 관리
  getVersionHistory(dashboardId: string): Promise<DashboardVersion[]>
  restoreVersion(dashboardId: string, versionId: string): Promise<void>

  // 즐겨찾기
  bookmarkDashboard(dashboardId: string): Promise<void>
  unbookmarkDashboard(dashboardId: string): Promise<void>
  getBookmarkedDashboards(): Promise<Dashboard[]>

  // 공유
  shareDashboard(id: string): Promise<ShareLink>
  regenerateShareLink(dashboardId: string): Promise<ShareLink>

  // 법적 보호 및 신고
  reportDashboard(dashboardId: string, reason: 'investment_advice' | 'scam' | 'false_info' | 'spam' | 'other', description?: string): Promise<void>
  logConsent(userId: string, consentType: 'dashboard_create' | 'disclaimer_view', metadata: {dashboardId?: string, consentText: string, consentVersion: string, ipAddress: string, userAgent: string}): Promise<void>
  hasSeenDisclaimer(userId: string): Promise<boolean>

  // 위젯 상호작용 이벤트
  events: {
    onWidgetClick: EventEmitter<{widgetId: string}>
    onLayoutChange: EventEmitter<{layout: WidgetLayout[]}>
    onWidgetVisible: EventEmitter<{widgetId: string}>
  }
}
```

### 필요한 인터페이스

- `WidgetLibrary.renderWidget()`
- `WidgetLibrary.getWidget()`
- `WidgetLibrary.exportWidgetData()` - 위젯 데이터 내보내기 (US3.8)
- `DataIntegration.fetchData()`
- `Authentication.getCurrentUser()`
- `Subscription.getPlanLimits()`
- `Subscription.canCreateDashboard()`
- `Subscription.canAddWidget()`
- `Subscription.canExportData()` - 데이터 내보내기 권한 체크 (US3.8)
- `AdminConsole.getTemplates()`

## 2. Widget Library Unit

### 제공하는 인터페이스

```typescript
interface WidgetLibraryContract {
  // 위젯 CRUD
  createWidget(data: CreateWidgetDto): Promise<Widget>
  updateWidget(id: string, data: UpdateWidgetDto): Promise<Widget>
  deleteWidget(id: string): Promise<void>
  getWidget(id: string): Promise<Widget>
  getMyWidgets(userId: string, options?: WidgetListOptions): Promise<Widget[]>
  getPublicWidgets(options?: WidgetListOptions): Promise<Widget[]>
  toggleWidgetVisibility(widgetId: string, isPublic: boolean): Promise<Widget>

  // 위젯 렌더링
  renderWidget(widget: Widget, container: HTMLElement, data: any): void

  // 위젯 복사 (참조 개념 제거)
  copyWidget(widgetId: string, userId: string): Promise<Widget>

  // 위젯 사용 정보
  getWidgetUsage(widgetId: string): Promise<{dashboardCount: number}>

  // 위젯 팩토리
  getWidgetTypes(): WidgetType[]
  createWidgetComponent(type: WidgetType): React.ComponentType

  // 데이터 내보내기 (Pro)
  exportWidgetData(widgetId: string, format: 'csv' | 'excel', options?: ExportOptions): Promise<Blob>
}
```

### 필요한 인터페이스

- `Authentication.getCurrentUser()` - 위젯 소유자 확인
- `Authentication.isAuthenticated()` - 인증 상태 확인
- `Subscription.canAddWidget()` - 위젯 개수 제한 체크
- `Subscription.canExportData()` - 데이터 내보내기 권한 체크 (Pro)
- `Subscription.getPlanLimits()` - Free/Pro 플랜별 제한
- `DataIntegration.fetchData()` - 지표 데이터 페칭
- `DataIntegration.searchIndicators()` - 지표 검색

## 3. Data Integration Unit

### 제공하는 인터페이스

```typescript
interface DataIntegrationContract {
  // 지표 검색
  searchIndicators(query: string, filters?: Filters): Promise<Indicator[]>
  getIndicator(id: string): Promise<Indicator>

  // 데이터 조회
  fetchData(indicatorId: string, params: DataParams): Promise<StandardizedData>
  batchFetchData(requests: DataRequest[]): Promise<StandardizedData[]>

  // 캐시 관리
  invalidateCache(indicatorId: string): Promise<void>

  // 데이터 스트림
  subscribeToData(indicatorId: string, callback: (data: any) => void): Unsubscribe
}
```

### 필요한 인터페이스

- `Authentication.getSession()` (API 인증용)
- `Subscription.getDataRetentionLimit()` (기간 제한)

## 4. Authentication Unit

### 제공하는 인터페이스

```typescript
interface AuthenticationContract {
  // 인증
  signIn(provider: 'google' | 'kakao'): Promise<Session>
  signOut(): Promise<void>
  refreshSession(): Promise<Session>

  // 사용자 정보
  getCurrentUser(): User | null
  getSession(): Session | null
  updateProfile(data: UpdateProfileDto): Promise<User>

  // SNS 계정 연결 (US1.2)
  linkProvider(provider: 'google' | 'kakao'): Promise<void>
  unlinkProvider(provider: 'google' | 'kakao'): Promise<void>

  // 계정 상태 관리 (Admin only - US6.3)
  activateUser(userId: string, reason: string): Promise<User>
  deactivateUser(userId: string, reason: string): Promise<User>

  // 권한 확인
  isAuthenticated(): boolean
  hasRole(role: 'user' | 'admin'): boolean

  // Context Provider
  AuthProvider: React.FC<{children: React.ReactNode}>
  useAuth: () => AuthContext
}
```

### 필요한 인터페이스

없음 (독립적)

## 5. Subscription Unit

### 제공하는 인터페이스

```typescript
interface SubscriptionContract {
  // 구독 정보
  getSubscription(userId: string): Promise<Subscription>
  getCurrentPlan(userId: string): Promise<'free' | 'pro'>

  // 플랜 제한 (동적)
  getPlanLimits(plan: 'free' | 'pro'): Promise<DynamicPlanLimits>
  canCreateDashboard(userId: string): Promise<boolean>
  canAddWidget(userId: string, dashboardId: string): Promise<boolean>
  canRestoreVersion(userId: string): Promise<boolean>  // Pro 전용
  canAddBookmark(userId: string): Promise<boolean>
  canExportData(userId: string): Promise<boolean>  // Pro 전용
  getDataRetentionLimit(userId: string): Promise<number> // years

  // 사용량
  getUsageStats(userId: string): Promise<UsageStats>

  // 플랜 변경
  upgradeToPro(userId: string): Promise<Subscription>
  cancelSubscription(userId: string): Promise<Subscription>

  // Hooks
  useSubscription: () => Subscription
  usePlanLimits: () => DynamicPlanLimits
  useInvalidateLimits: () => void
}
```

### 필요한 인터페이스

- `Authentication.getCurrentUser()` (사용자 ID)
- `AdminConsole.getPlanLimitConfigs()` (동적 제한값 조회)

## 6. Admin Console Unit

### 제공하는 인터페이스

```typescript
interface AdminConsoleContract {
  // 지표 관리
  createIndicator(data: CreateIndicatorDto): Promise<ManagedIndicator>
  updateIndicator(id: string, data: UpdateIndicatorDto): Promise<ManagedIndicator>
  deleteIndicator(id: string): Promise<void>
  getIndicators(): Promise<ManagedIndicator[]>
  testIndicatorConnection(indicatorId: string): Promise<TestResult>

  // 템플릿 관리
  createTemplate(data: CreateTemplateDto): Promise<DashboardTemplate>
  updateTemplate(id: string, data: UpdateTemplateDto): Promise<DashboardTemplate>
  deleteTemplate(id: string): Promise<void>
  getTemplates(): Promise<DashboardTemplate[]>

  // 사용자 관리
  getUsers(filters?: UserFilters): Promise<AdminUserView[]>
  updateUserSubscription(userId: string, plan: 'free' | 'pro', expiryDate?: Date, reason: string): Promise<void>
  activateUser(userId: string, reason: string): Promise<User>
  deactivateUser(userId: string, reason: string): Promise<User>
  getUserActivityLog(userId: string): Promise<ActivityLog[]>

  // 데이터 소스 관리
  getDataSources(): Promise<DataSource[]>
  createDataSource(data: CreateDataSourceDto): Promise<DataSource>
  updateDataSource(id: string, data: UpdateDataSourceDto): Promise<DataSource>
  updateDataSourceAPIKey(id: string, apiKey: string): Promise<void>
  toggleDataSourceStatus(id: string, active: boolean): Promise<void>
  testAPIConnection(sourceId: string): Promise<TestResult>

  // 플랜 제한 관리
  getPlanLimitConfigs(planType?: 'free' | 'pro'): Promise<PlanLimitConfig[]>
  updatePlanLimit(id: string, data: UpdateLimitDto): Promise<PlanLimitConfig>
  addPlanLimit(data: CreateLimitDto): Promise<PlanLimitConfig>
  removePlanLimit(id: string): Promise<void>
  getLimitHistory(limitKey: string): Promise<PlanLimitHistory[]>

  // 카테고리 관리
  getCategories(): Promise<Category[]>
  createCategory(data: CreateCategoryDto): Promise<Category>
  updateCategory(id: string, data: UpdateCategoryDto): Promise<Category>
  deleteCategory(id: string): Promise<void>
  reorderCategories(categoryIds: string[]): Promise<void>
  toggleCategoryStatus(id: string, active: boolean): Promise<void>

  // 수동 데이터 입력 및 관리
  uploadCustomData(indicatorId: string, file: File): Promise<CustomDataImportResult>
  addCustomDataPoint(indicatorId: string, data: CustomDataPointDto): Promise<CustomDataPoint>
  getCustomData(indicatorId: string): Promise<CustomDataPoint[]>
  updateCustomDataPoint(id: string, data: CustomDataPointDto): Promise<CustomDataPoint>
  deleteCustomDataPoint(id: string): Promise<void>
  getCustomDataHistory(indicatorId: string): Promise<CustomDataHistory[]>

  // 컨텐츠 관리 및 신고 처리
  getReportedDashboards(filters?: {status?: 'pending' | 'under_review' | 'actioned' | 'dismissed', reason?: string, dateFrom?: Date, dateTo?: Date}): Promise<DashboardReport[]>
  reviewReport(reportId: string, action: 'warning' | 'delete_dashboard' | 'suspend_user' | 'dismiss', reason: string): Promise<void>
  getUserViolations(userId: string): Promise<ViolationLog[]>
  getViolationStats(period?: {from: Date, to: Date}): Promise<ViolationStats>
  suspendUser(userId: string, reason: string, duration?: number): Promise<void>

  // 자동 탐지 시스템
  getAutoDetectedContent(filters?: {severity?: 'low' | 'medium' | 'high', status?: 'pending' | 'reviewed', dateFrom?: Date}): Promise<Array<{dashboard: Dashboard, violation: ViolationLog}>>
  getDetectionRules(): Promise<DetectionRule[]>
  updateDetectionRule(ruleId: string, updates: Partial<DetectionRule>): Promise<DetectionRule>
  createDetectionRule(rule: Omit<DetectionRule, 'id' | 'createdAt'>): Promise<DetectionRule>
  dismissViolation(violationId: string, reason: string): Promise<void>

  // 모니터링
  getSystemMetrics(): Promise<SystemMetrics>
  getDashboardStats(): Promise<DashboardStats>
}
```

### 필요한 인터페이스

- `Authentication.getCurrentUser()` (관리자 인증)
- `Authentication.hasRole('admin')` (권한 확인)
- `DataIntegration.searchIndicators()` (지표 검색)

## 공통 데이터 타입

### 기본 타입

```typescript
// 사용자
interface User {
  id: string
  email: string
  name: string
  avatar?: string
  role: 'user' | 'admin'
  status: 'active' | 'inactive'  // 계정 활성화 상태 (관리자가 제어)
  linkedProviders?: Array<'google' | 'kakao'>  // 연결된 SNS 계정 목록 (US1.2)
}

// 대시보드
interface Dashboard {
  id: string
  userId: string
  name: string
  description?: string
  categoryCode?: string  // Category.code 참조
  layout: WidgetLayout[]
  isPublic: boolean
  isDefault?: boolean
  shareLinks?: ShareLink[]  // Pro
  createdAt: Date
  updatedAt: Date
  lastAutoSaveAt?: Date
  lastViewedAt?: Date
}

// 위젯
interface Widget {
  id: string
  userId: string
  type: WidgetType
  name: string
  parameters: WidgetParameters
  isPublic: boolean
  createdAt: Date
  updatedAt: Date
}

// 위젯 레이아웃
interface WidgetLayout {
  id: string
  dashboardId: string
  widgetId: string  // 모든 위젯이 owned
  x: number
  y: number
  width: number
  height: number
  order: number
}

// 대시보드 버전 (Pro)
interface DashboardVersion {
  id: string
  dashboardId: string
  userId: string
  version: number
  layouts: WidgetLayout[]
  savedAt: Date
}

// 대시보드 즐겨찾기
interface DashboardBookmark {
  id: string
  userId: string
  dashboardId: string
  createdAt: Date
}

// 데이터 소스
interface DataSource {
  id: string
  name: string  // 'KOSIS', 'ECOS', 'OECD', 'World Bank', etc.
  description: string
  isActive: boolean
  apiKey?: string  // 암호화 저장
  createdAt: Date
  updatedAt: Date
  updatedBy: string
}

// 플랜 제한 설정
interface PlanLimitConfig {
  id: string
  planType: 'free' | 'pro'
  limitKey: string
  limitValue: number | boolean | string
  description: string
  unit?: string
  isActive: boolean
  effectiveDate?: Date
  expiryDate?: Date
  updatedAt: Date
  updatedBy: string
}

// 동적 플랜 제한
interface DynamicPlanLimits {
  planType: 'free' | 'pro'
  limits: Map<string, any>
  effectiveDate?: Date
  expiryDate?: Date
}

// 대시보드 템플릿
interface DashboardTemplate {
  id: string
  name: string
  description: string
  categoryCode?: string  // Category.code 참조
  thumbnail?: string
  isActive: boolean
  isPro: boolean
  widgets: TemplateWidget[]
  createdAt: Date
  updatedAt: Date
}

// 템플릿 위젯
interface TemplateWidget {
  widgetType: WidgetType
  name: string
  parameters: WidgetParameters
  layout: {
    x: number
    y: number
    width: number
    height: number
    order: number
  }
}

// 표준 데이터
interface StandardizedData {
  indicatorId: string
  period: string
  data: DataPoint[]
  lastUpdated: Date
}

interface DataPoint {
  date: Date
  value: number
  metadata?: Record<string, any>
}

// 카테고리
interface Category {
  id: string
  code: string
  name: string
  description?: string
  order: number
  isActive: boolean
  usageCount: number
  createdAt: Date
  updatedAt: Date
}

// 사용자 활동 로그
interface ActivityLog {
  id: string
  userId: string
  action: string
  resourceType: string
  resourceId?: string
  details?: Record<string, any>
  ipAddress?: string
  userAgent?: string
  createdAt: Date
}

// 수동 데이터 포인트
interface CustomDataPoint {
  id: string
  indicatorId: string
  date: Date
  value: number
  metadata?: Record<string, any>
  createdBy: string
  createdAt: Date
  updatedAt: Date
}

// 수동 데이터 임포트 결과
interface CustomDataImportResult {
  success: boolean
  totalRows: number
  importedRows: number
  errors?: Array<{row: number, message: string}>
  preview: CustomDataPoint[]
}

// 수동 데이터 변경 이력
interface CustomDataHistory {
  id: string
  indicatorId: string
  dataPointId: string
  action: 'create' | 'update' | 'delete'
  oldValue?: any
  newValue?: any
  changedBy: string
  changedAt: Date
}

// 위젯 목록 옵션
interface WidgetListOptions {
  category?: string
  widgetType?: WidgetType
  indicatorId?: string
  sortBy?: 'popular' | 'latest' | 'name'
  limit?: number
  search?: string
}

// 데이터 내보내기 옵션
interface ExportOptions {
  fileName?: string  // 기본값: 위젯명-날짜
  startDate?: Date
  endDate?: Date
  includeMetadata?: boolean
}

// 공유 링크
interface ShareLink {
  id: string
  dashboardId: string
  token: string
  isActive: boolean
  expiresAt?: Date
  createdAt: Date
  createdBy: string
}

// 위젯 파라미터
interface WidgetParameters {
  indicatorId: string
  period?: DataPeriod
  startDate?: Date
  endDate?: Date
  chartOptions?: Record<string, any>
  customOptions?: Record<string, any>
}

// 지표
interface Indicator {
  id: string
  name: string
  description: string
  source: 'KOSIS' | 'ECOS' | 'OECD' | 'CUSTOM'
  categoryCode?: string
  unit?: string
  frequency?: DataPeriod
  apiParams?: Record<string, any>
  createdAt: Date
  updatedAt: Date
}

// 관리자용 지표
interface ManagedIndicator extends Indicator {
  isActive: boolean
  usageCount: number
  lastSyncAt?: Date
  createdBy: string
  updatedBy: string
}

// 세션
interface Session {
  access_token: string
  refresh_token: string
  expires_in: number
  expires_at: number
  user: User
}

// 구독 정보
interface Subscription {
  id: string
  userId: string
  planType: 'free' | 'pro'
  status: 'active' | 'cancelled' | 'expired'
  startDate: Date
  expiryDate?: Date
  cancelledAt?: Date
  createdAt: Date
  updatedAt: Date
}

// 사용량 통계
interface UsageStats {
  userId: string
  dashboardCount: number
  dashboardLimit: number
  widgetCount: number
  widgetLimit: number
  bookmarkCount: number
  bookmarkLimit: number
  dataRetentionYears: number
}

// 테스트 결과
interface TestResult {
  success: boolean
  responseTime?: number
  statusCode?: number
  message?: string
  error?: string
  testedAt: Date
}

// 목록 조회 옵션
interface ListOptions {
  sortBy?: 'name' | 'createdAt' | 'updatedAt' | 'lastViewedAt'
  sortOrder?: 'asc' | 'desc'
  category?: string
  isPublic?: boolean
  limit?: number
  offset?: number
  search?: string
}

// 이벤트 이미터
interface EventEmitter<T> {
  on(handler: (data: T) => void): void
  off(handler: (data: T) => void): void
  emit(data: T): void
}

// 검색 필터
interface Filters {
  category?: string
  source?: string
  frequency?: DataPeriod
  search?: string
}

// 데이터 조회 파라미터
interface DataParams {
  startDate?: Date
  endDate?: Date
  period?: DataPeriod
  limit?: number
}

// 배치 데이터 요청
interface DataRequest {
  indicatorId: string
  params: DataParams
}

// 구독 취소 함수
type Unsubscribe = () => void

// 인증 컨텍스트
interface AuthContext {
  user: User | null
  session: Session | null
  isAuthenticated: boolean
  signIn: (provider: 'google' | 'kakao') => Promise<void>
  signOut: () => Promise<void>
  refreshSession: () => Promise<void>
}

// 사용자 필터
interface UserFilters {
  planType?: 'free' | 'pro'
  status?: 'active' | 'inactive'
  search?: string
  sortBy?: 'createdAt' | 'lastLoginAt' | 'email'
  sortOrder?: 'asc' | 'desc'
}

// 관리자용 사용자 뷰
interface AdminUserView {
  id: string
  email: string
  name: string
  planType: 'free' | 'pro'
  status: 'active' | 'inactive'
  dashboardCount: number
  lastLoginAt?: Date
  createdAt: Date
}

// 플랜 제한 변경 이력
interface PlanLimitHistory {
  id: string
  limitKey: string
  planType: 'free' | 'pro'
  oldValue: any
  newValue: any
  changedBy: string
  changedAt: Date
  reason?: string
}

// 시스템 메트릭
interface SystemMetrics {
  totalUsers: number
  activeUsers: number
  totalDashboards: number
  totalWidgets: number
  apiCallsToday: number
  avgResponseTime: number
  errorRate: number
  timestamp: Date
}

// 대시보드 통계
interface DashboardStats {
  totalPublic: number
  totalPrivate: number
  avgWidgetsPerDashboard: number
  mostUsedCategories: Array<{categoryCode: string, count: number}>
  mostUsedIndicators: Array<{indicatorId: string, name: string, count: number}>
}

// ============================================
// 법적 보호 및 컨텐츠 관리 타입
// ============================================

// 동의 로그
interface ConsentLog {
  id: string
  userId: string
  dashboardId?: string
  consentType: 'dashboard_create' | 'disclaimer_view'
  consentText: string
  consentVersion: string
  ipAddress: string
  userAgent: string
  timestamp: Date
}

// 위반 로그
interface ViolationLog {
  id: string
  userId: string
  dashboardId: string
  violationType: 'investment_advice' | 'false_claim' | 'spam' | 'other'
  severity: 'low' | 'medium' | 'high'
  detectedBy: 'user_report' | 'auto_detection' | 'admin_review'
  detectedPattern?: string
  status: 'pending' | 'confirmed' | 'dismissed'
  actionTaken?: 'warning' | 'delete_dashboard' | 'suspend_user' | 'none'
  actionReason?: string
  reviewedBy?: string
  createdAt: Date
  reviewedAt?: Date
}

// 대시보드 신고
interface DashboardReport {
  id: string
  dashboardId: string
  reporterId: string
  reason: 'investment_advice' | 'scam' | 'false_info' | 'spam' | 'other'
  description?: string
  status: 'pending' | 'under_review' | 'actioned' | 'dismissed'
  reviewNote?: string
  createdAt: Date
  reviewedAt?: Date
}

// 위반 통계
interface ViolationStats {
  totalReports: number
  pendingReports: number
  totalViolations: number
  violationsByType: Record<string, number>
  topViolators: Array<{
    userId: string
    userName: string
    violationCount: number
  }>
}

// 자동 탐지 룰
interface DetectionRule {
  id: string
  name: string
  pattern: string
  severity: 'low' | 'medium' | 'high'
  action: 'flag' | 'auto_hide' | 'auto_delete'
  isActive: boolean
  description: string
  createdAt: Date
}
```

### 열거형 타입

```typescript
type WidgetType = 'time-series' | 'bar-chart' | 'pie-chart' | 'treemap' | 'scatter-chart' | 'radar-chart' | 'radial-bar-chart' | 'text-custom' | 'text-data'
type DataPeriod = 'daily' | 'monthly' | 'quarterly' | 'yearly'
type PlanType = 'free' | 'pro'
type UserRole = 'user' | 'admin'
```

## 통신 패턴

### 1. 이벤트 기반 통신

```typescript
// 이벤트 버스
class EventBus {
  emit(event: string, data: any): void
  on(event: string, handler: (data: any) => void): void
  off(event: string, handler: Function): void
}

// 글로벌 이벤트
const globalEvents = {
  'auth:signIn': User
  'auth:signOut': void
  'subscription:upgraded': Subscription
  'widget:created': Widget
  'dashboard:updated': Dashboard
}
```

### 2. 직접 호출

- 각 단위는 필요한 단위의 인터페이스를 직접 import
- TypeScript로 타입 안정성 보장
- 순환 의존성 방지

### 3. 상태 동기화

- Zustand stores 간 subscribe 패턴
- 필요시 상태 변경 감지 및 업데이트

## 에러 처리 계약

### 공통 에러 타입

```typescript
interface IntegrationError {
  code: string
  message: string
  source: string // Unit name
  details?: any
}

enum ErrorCode {
  // Authentication
  AUTH_REQUIRED = 'AUTH_REQUIRED',
  SESSION_EXPIRED = 'SESSION_EXPIRED',

  // Subscription
  PLAN_LIMIT_EXCEEDED = 'PLAN_LIMIT_EXCEEDED',

  // Data
  DATA_NOT_FOUND = 'DATA_NOT_FOUND',
  API_ERROR = 'API_ERROR',

  // General
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  NETWORK_ERROR = 'NETWORK_ERROR'
}
```

## 버전 관리

각 단위는 독립적으로 버전 관리되며, 인터페이스 변경 시:

1. 하위 호환성 유지
2. Deprecation warning 제공
3. Migration guide 작성

## 테스트 계약

### 계약 테스트

```typescript
// Pact를 사용한 계약 테스트
describe('Dashboard <-> Widget Library Contract', () => {
  it('should render widget with correct data format', async () => {
    // 계약 검증 코드
  })
})
```

### Mock 제공

각 단위는 개발/테스트용 Mock 구현체 제공:

```typescript
// Mock 구현 예시
class MockAuthenticationUnit implements AuthenticationContract {
  getCurrentUser() {
    return { id: 'test-user', email: 'test@example.com', role: 'user' }
  }
  // ... 다른 메서드 구현
}
```

## 배포 계약

- 각 단위는 독립적으로 배포 가능
- 인터페이스 변경 시 다른 단위에 통지
- Feature flag로 점진적 롤아웃
