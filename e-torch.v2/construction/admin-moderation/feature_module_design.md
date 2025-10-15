# Admin Moderation Feature Module 설계

## 1. 개요

### 1.1 Feature Module 정보

**명칭**: Admin Moderation
**책임**: 컨텐츠 안전 및 규제 관리
**범위**: US6.9 ~ US6.11 (신고 관리, 위반 사용자 관리, 자동 탐지)
**아키텍처**: Multi-Zone (apps/admin), BFF + Feature Module

### 1.2 주요 책임

Admin Moderation Feature Module은 E-Torch 플랫폼의 컨텐츠 안전성과 법적 규제 준수를 담당합니다:

1. **신고 관리 (US6.9)**
   - 사용자 신고 대시보드 검토 및 조치
   - 신고 사유별 분류 및 우선순위 관리
   - 조치 내역 기록 및 통보

2. **위반 사용자 관리 (US6.10)**
   - 사용자별 위반 이력 추적
   - 단계적 제재 시스템 운영
   - 제재 내역 통보 및 이의제기 처리

3. **자동 탐지 시스템 (US6.11)**
   - 위험 키워드 및 패턴 자동 스캔
   - 탐지 룰 관리 (정규표현식 기반)
   - 오탐 학습 및 개선

### 1.3 아키텍처 컨텍스트

Admin Moderation은 Admin Console과 같은 apps/admin 앱 내에서 별도 패키지로 제공됩니다:

```
apps/
  admin/            ← Admin 전용 Next.js 앱 (Multi-Zone)
    app/
      (system)/     ← admin-console 사용
      (moderation)/ ← admin-moderation 사용 (별도 레이아웃)
        reports/
        violations/
        detection/
packages/
  @e-torch/admin-console/      # 시스템 운영
  @e-torch/admin-moderation/   # 컨텐츠 관리 ← 본 Feature Module
  ui/               ← 공유 UI 컴포넌트
  core/             ← 공유 타입, 유틸리티
  query/            ← 공유 데이터 레이어
```

**아키텍처 특성**:

- Next.js 15 + React 19 기반
- Admin Console과 독립 패키지, 같은 앱에서 실행
- Supabase Auth 기반 공통 인증
- Role 기반 접근 제어 (admin 역할 필수)
- packages/ui를 통한 컴포넌트 공유

### 1.4 기술 스택

- **Language**: TypeScript 5.x
- **Runtime Validation**: Zod
- **UI Framework**: React 19
- **Data Fetching**: TanStack Query v5
- **Routing**: Next.js 15 App Router
- **Database**: Supabase (PostgreSQL + RLS)
- **Auth**: Supabase Auth
- **Architecture**: BFF + Feature Module (No DDD)

## 2. Type 정의

### 2.1 AdminModerationContract 개요

AdminModerationContract는 10개의 메서드로 구성되며, 신고 관리, 위반 사용자 관리, 자동 탐지 기능을 제공합니다.

### 2.2 메서드별 TypeScript Interface

#### 2.2.1 신고 관리 (US6.9)

**Method 1: getReportedDashboards**

신고된 대시보드 목록을 조회합니다.

Request Type:

- filters (optional): status, reason, dateFrom, dateTo

Response Type:

- DashboardReport[]

**Method 2: reviewReport**

신고를 검토하고 조치를 실행합니다.

Request Type:

- reportId: string
- action: 'warning' | 'delete_dashboard' | 'suspend_user' | 'dismiss'
- reason: string

Response Type:

- void

#### 2.2.2 위반 사용자 관리 (US6.10)

**Method 3: getUserViolations**

특정 사용자의 위반 이력을 조회합니다.

Request Type:

- userId: string

Response Type:

- ViolationLog[]

**Method 4: getViolationStats**

위반 통계를 조회합니다.

Request Type:

- period (optional): from, to

Response Type:

- ViolationStats

**Method 5: suspendUser**

사용자를 제재합니다.

Request Type:

- userId: string
- reason: string
- duration (optional): number (hours)

Response Type:

- void

#### 2.2.3 자동 탐지 시스템 (US6.11)

**Method 6: getAutoDetectedContent**

자동 탐지된 컨텐츠 목록을 조회합니다.

Request Type:

- filters (optional): severity, status, dateFrom

Response Type:

- Array<{dashboard: Dashboard, violation: ViolationLog}>

**Method 7: getDetectionRules**

탐지 룰 목록을 조회합니다.

Request Type:

- (none)

Response Type:

- DetectionRule[]

**Method 8: updateDetectionRule**

탐지 룰을 수정합니다.

Request Type:

- ruleId: string
- updates: Partial<DetectionRule>

Response Type:

- DetectionRule

**Method 9: createDetectionRule**

새로운 탐지 룰을 생성합니다.

Request Type:

- rule: Omit<DetectionRule, 'id' | 'createdAt'>

Response Type:

- DetectionRule

**Method 10: dismissViolation**

위반을 무혐의 처리합니다.

Request Type:

- violationId: string
- reason: string

Response Type:

- void

### 2.3 공통 타입

**DashboardReport**

- id: string
- dashboardId: string
- reporterId: string
- reason: 'investment_advice' | 'scam' | 'false_info' | 'spam' | 'other'
- description: string (optional)
- status: 'pending' | 'under_review' | 'actioned' | 'dismissed'
- reviewNote: string (optional)
- createdAt: Date
- reviewedAt: Date (optional)

**ViolationLog**

- id: string
- userId: string
- dashboardId: string
- violationType: 'investment_advice' | 'false_claim' | 'spam' | 'other'
- severity: 'low' | 'medium' | 'high'
- detectedBy: 'user_report' | 'auto_detection' | 'admin_review'
- detectedPattern: string (optional)
- status: 'pending' | 'confirmed' | 'dismissed'
- actionTaken: 'warning' | 'delete_dashboard' | 'suspend_user' | 'none' (optional)
- actionReason: string (optional)
- reviewedBy: string (optional)
- createdAt: Date
- reviewedAt: Date (optional)

**ViolationStats**

- totalReports: number
- pendingReports: number
- totalViolations: number
- violationsByType: Record<string, number>
- topViolators: Array<{userId: string, userName: string, violationCount: number}>

**DetectionRule**

- id: string
- name: string
- pattern: string (정규표현식)
- severity: 'low' | 'medium' | 'high'
- action: 'flag' | 'auto_hide' | 'auto_delete'
- isActive: boolean
- description: string
- createdAt: Date

### 2.4 Zod Schema 정의 원칙

각 Request/Response 타입에 대해 Zod Schema를 정의하여 런타임 검증을 수행합니다.

**Schema 명명 규칙**:

- Request DTO: {MethodName}RequestSchema
- Response DTO: {MethodName}ResponseSchema
- 공통 타입: {TypeName}Schema

**검증 규칙**:

- 필수 필드 검증
- 타입 검증 (string, number, boolean, Date)
- Enum 값 검증
- 문자열 길이 제한 (reason: 최소 10자, 최대 1000자)
- 정규표현식 유효성 검증 (DetectionRule.pattern)
- 날짜 범위 검증 (dateFrom <= dateTo)

## 3. React Components Tree

### 3.1 전체 컴포넌트 계층 개요

Admin Moderation은 3개의 주요 페이지로 구성됩니다:

1. **Reports Page** (`/moderation/reports`) - 신고 관리 (US6.9)
2. **Violations Page** (`/moderation/violations`) - 위반 사용자 관리 (US6.10)
3. **Detection Page** (`/moderation/detection`) - 자동 탐지 관리 (US6.11)

### 3.2 Layout Components

**AppLayout** (packages/ui)

- Props:
  - navigation: NavigationItem[]
  - showUserMenu: boolean
  - headerActions: React.ReactNode (optional)
  - breadcrumbs: BreadcrumbItem[] (optional)

**ModerationLayout** (packages/admin-moderation)

- AppLayout를 래핑하며 Moderation 전용 navigation 제공
- Children:
  - Header: 페이지 제목, 필터 컨트롤
  - Sidebar: 통계 요약 (대기 중 신고 수, 위반 사용자 수)
  - Content: 페이지별 컨텐츠

### 3.3 Reports Page (US6.9)

**ReportsPage**
└── ReportsPageHeader
    ├── PageTitle
    ├── FilterControls
    │   ├── StatusFilter (dropdown)
    │   ├── ReasonFilter (dropdown)
    │   └── DateRangeFilter
    └── RefreshButton
└── ReportsContent
    ├── ReportsStatsBar
    │   ├── StatCard (총 신고 수)
    │   ├── StatCard (대기 중)
    │   └── StatCard (처리 완료)
    └── ReportsTable
        ├── DataTable (packages/ui)
        │   ├── TableHeader
        │   │   ├── Column: 신고 사유
        │   │   ├── Column: 대시보드 제목
        │   │   ├── Column: 신고자 수
        │   │   ├── Column: 접수일시
        │   │   ├── Column: 상태
        │   │   └── Column: 액션
        │   └── TableRow[]
        │       ├── ReportReasonBadge
        │       ├── DashboardTitleLink
        │       ├── ReporterCountBadge
        │       ├── DateTimeDisplay
        │       ├── StatusBadge
        │       └── ActionButtons
        │           ├── ViewDetailButton
        │           └── QuickActionDropdown
        └── Pagination (packages/ui)
    └── ReportDetailDialog (Modal)
        ├── DialogHeader
        │   ├── ReportId
        │   └── StatusBadge
        ├── DialogContent
        │   ├── ReportInfoSection
        │   │   ├── ReportReason
        │   │   ├── ReportDescription
        │   │   ├── ReporterCount
        │   │   └── ReportDate
        │   ├── DashboardPreviewSection
        │   │   ├── DashboardTitle
        │   │   ├── DashboardContent (full text)
        │   │   └── KeywordHighlighter (위험 키워드 강조)
        │   ├── AuthorHistorySection
        │   │   ├── AuthorInfo
        │   │   ├── PreviousViolationsCount
        │   │   └── ViolationTimeline
        │   └── ReviewNoteInput
        │       └── Textarea
        └── DialogFooter
            ├── ActionButtons
            │   ├── WarningButton
            │   ├── DeleteDashboardButton
            │   ├── SuspendUserButton
            │   └── DismissButton
            └── CancelButton

### 3.4 Violations Page (US6.10)

**ViolationsPage**
└── ViolationsPageHeader
    ├── PageTitle
    ├── FilterControls
    │   ├── SortByDropdown (위반 횟수, 마지막 위반일)
    │   └── SearchInput (사용자명, 이메일)
    └── ExportButton
└── ViolationsContent
    ├── ViolationsStatsBar
    │   ├── StatCard (총 위반 사용자)
    │   ├── StatCard (활성 제재 중)
    │   └── StatCard (영구 정지)
    └── ViolationsTable
        ├── DataTable (packages/ui)
        │   ├── TableHeader
        │   │   ├── Column: 사용자
        │   │   ├── Column: 경고 횟수
        │   │   ├── Column: 삭제된 대시보드
        │   │   ├── Column: 마지막 위반일
        │   │   ├── Column: 상태
        │   │   └── Column: 액션
        │   └── TableRow[]
        │       ├── UserInfoCell
        │       │   ├── Avatar
        │       │   ├── Name
        │       │   └── Email
        │       ├── WarningCountBadge
        │       ├── DeletedCountBadge
        │       ├── LastViolationDate
        │       ├── UserStatusBadge
        │       └── ActionButtons
        │           ├── ViewHistoryButton
        │           └── SuspendButton
        └── Pagination (packages/ui)
    └── ViolationHistoryDialog (Modal)
        ├── DialogHeader
        │   ├── UserInfo
        │   └── TotalViolationsCount
        ├── DialogContent
        │   ├── ViolationSummary
        │   │   ├── ByTypeChart (pie chart)
        │   │   └── SeverityDistribution
        │   └── ViolationTimeline
        │       └── TimelineItem[]
        │           ├── ViolationDate
        │           ├── ViolationType
        │           ├── Severity
        │           ├── DashboardLink
        │           ├── ActionTaken
        │           └── ReviewNote
        └── DialogFooter
            ├── SuspendUserButton
            └── CloseButton

**SuspendUserDialog** (Modal)
├── DialogHeader
│   ├── Title: "사용자 제재"
│   └── UserInfo
├── DialogContent
│   ├── SuspensionReasonInput
│   │   └── Textarea
│   ├── SuspensionDurationSelect
│   │   ├── Option: 48시간
│   │   ├── Option: 7일
│   │   ├── Option: 30일
│   │   └── Option: 영구 정지
│   └── WarningMessage
└── DialogFooter
    ├── ConfirmButton
    └── CancelButton

### 3.5 Detection Page (US6.11)

**DetectionPage**
└── DetectionPageHeader
    ├── PageTitle
    └── TabControls
        ├── Tab: 자동 탐지 결과
        └── Tab: 탐지 룰 관리
└── DetectionContent
    ├── AutoDetectedTab (when selected)
    │   ├── FilterControls
    │   │   ├── SeverityFilter
    │   │   ├── StatusFilter
    │   │   └── DateRangeFilter
    │   ├── AutoDetectedStatsBar
    │   │   ├── StatCard (총 탐지)
    │   │   ├── StatCard (높음)
    │   │   ├── StatCard (중간)
    │   │   └── StatCard (낮음)
    │   └── AutoDetectedTable
    │       ├── DataTable (packages/ui)
    │       │   ├── TableHeader
    │       │   │   ├── Column: 대시보드
    │       │   │   ├── Column: 탐지 패턴
    │       │   │   ├── Column: 위험도
    │       │   │   ├── Column: 탐지일시
    │       │   │   ├── Column: 상태
    │       │   │   └── Column: 액션
    │       │   └── TableRow[]
    │       │       ├── DashboardInfoCell
    │       │       ├── DetectedPatternBadge
    │       │       ├── SeverityBadge
    │       │       ├── DetectionDate
    │       │       ├── StatusBadge
    │       │       └── ActionButtons
    │       │           ├── ReviewButton
    │       │           └── DismissButton
    │       └── Pagination (packages/ui)
    │   └── DetectionDetailDialog (Modal)
    │       ├── DialogHeader
    │       │   ├── DashboardTitle
    │       │   └── SeverityBadge
    │       ├── DialogContent
    │       │   ├── DetectionInfoSection
    │       │   │   ├── DetectedPattern
    │       │   │   ├── DetectionRule
    │       │   │   └── DetectionDate
    │       │   ├── DashboardContentSection
    │       │   │   └── KeywordHighlighter (탐지된 키워드 강조)
    │       │   ├── AuthorHistorySection
    │       │   │   ├── PreviousViolations
    │       │   │   └── ViolationTimeline
    │       │   └── ReviewNoteInput
    │       └── DialogFooter
    │           ├── ConfirmViolationButton
    │           ├── DismissButton
    │           └── CancelButton
    └── DetectionRulesTab (when selected)
        ├── RulesHeader
        │   ├── SearchInput
        │   └── AddRuleButton
        ├── RulesStatsBar
        │   ├── StatCard (총 룰)
        │   ├── StatCard (활성)
        │   └── StatCard (비활성)
        └── DetectionRulesTable
            ├── DataTable (packages/ui)
            │   ├── TableHeader
            │   │   ├── Column: 룰 이름
            │   │   ├── Column: 패턴
            │   │   ├── Column: 위험도
            │   │   ├── Column: 액션
            │   │   ├── Column: 상태
            │   │   └── Column: 관리
            │   └── TableRow[]
            │       ├── RuleNameCell
            │       ├── PatternPreview
            │       ├── SeverityBadge
            │       ├── AutoActionBadge
            │       ├── StatusToggle
            │       └── ActionButtons
            │           ├── EditButton
            │           └── DeleteButton
            └── Pagination (packages/ui)
        └── DetectionRuleDialog (Modal)
            ├── DialogHeader
            │   └── Title (생성/수정)
            ├── DialogContent
            │   ├── RuleForm
            │   │   ├── RuleNameInput
            │   │   ├── PatternInput (정규표현식)
            │   │   │   └── PatternValidator
            │   │   ├── SeveritySelect
            │   │   │   ├── Option: Low
            │   │   │   ├── Option: Medium
            │   │   │   └── Option: High
            │   │   ├── AutoActionSelect
            │   │   │   ├── Option: Flag (플래그만)
            │   │   │   ├── Option: Auto Hide (자동 비공개)
            │   │   │   └── Option: Auto Delete (자동 삭제)
            │   │   ├── DescriptionTextarea
            │   │   └── IsActiveToggle
            │   └── PatternTester
            │       ├── TestInput
            │       └── TestResult (matches highlight)
            └── DialogFooter
                ├── SaveButton
                └── CancelButton

### 3.6 공통 컴포넌트 (packages/ui 재사용)

**DataTable**

- 정렬, 필터링, 페이지네이션 기능
- Row selection 지원
- Column visibility toggle

**FormDialog**

- Modal 기반 폼 컴포넌트
- 폼 검증 통합
- Loading/Error 상태 관리

**ConfirmDialog**

- 위험한 액션 확인용
- 커스텀 메시지 지원
- 비동기 액션 지원

**Toast**

- 성공/에러 메시지 표시
- Auto-dismiss
- Action button 지원

**SearchInput**

- Debounced 검색
- Clear button
- Loading indicator

**Pagination**

- 페이지 번호 표시
- 이전/다음 버튼
- 페이지 크기 선택

**StatusBadge**

- 상태별 색상 자동 적용
- 크기 옵션 (sm, md, lg)

**DateTimeDisplay**

- 상대 시간 표시 (1시간 전, 2일 전)
- 절대 시간 툴팁

### 3.7 Admin Moderation 전용 컴포넌트

**KeywordHighlighter**

- 위험 키워드를 텍스트에서 강조 표시
- 탐지 패턴별 색상 구분
- 툴팁으로 패턴 이름 표시

**ViolationTimeline**

- 시간순 위반 이력 표시
- 타임라인 UI
- 액션별 아이콘

**PatternValidator**

- 정규표현식 유효성 실시간 검증
- 에러 메시지 표시
- 예시 제공

**SeverityBadge**

- 위험도별 색상 (Low: green, Medium: yellow, High: red)
- 아이콘 포함

**ViolationTypeIcon**

- 위반 유형별 아이콘
- 툴팁으로 설명 제공

## 4. TanStack Query Hooks 설계

### 4.1 Query Key 구조

Admin Moderation은 Resource 기반 Query Key를 사용합니다:

**Resource 목록**:

- `reports`: 신고 관리
- `violations`: 위반 로그
- `detection-rules`: 탐지 룰
- `auto-detected`: 자동 탐지 결과
- `violation-stats`: 위반 통계

**Query Key 패턴**:

- List: `[resource, 'list', filters?]`
- Detail: `[resource, id]`
- Stats: `[resource, 'stats', period?]`
- Nested: `[resource, parentId, childResource]`

**예시**:

- `['reports', 'list', {status: 'pending'}]`
- `['reports', reportId]`
- `['violations', 'user', userId]`
- `['violations', 'stats', {from: '2024-01-01', to: '2024-12-31'}]`
- `['detection-rules', 'list']`
- `['detection-rules', ruleId]`
- `['auto-detected', 'list', {severity: 'high'}]`

### 4.2 Query Hooks (Read Operations)

#### 4.2.1 신고 관리 (US6.9)

**useReportedDashboards**

Query Key: `['reports', 'list', filters]`

Parameters:

- filters (optional): status, reason, dateFrom, dateTo

Return Type:

- data: DashboardReport[]
- isLoading: boolean
- error: Error | null

Caching Strategy:

- staleTime: 30초 (실시간 신고 반영)
- cacheTime: 5분
- refetchOnWindowFocus: true

**useReportDetail**

Query Key: `['reports', reportId]`

Parameters:

- reportId: string

Return Type:

- data: DashboardReport & {dashboard: Dashboard, reporter: User, author: User}
- isLoading: boolean
- error: Error | null

Caching Strategy:

- staleTime: 1분
- cacheTime: 5분
- enabled: !!reportId

#### 4.2.2 위반 사용자 관리 (US6.10)

**useUserViolations**

Query Key: `['violations', 'user', userId]`

Parameters:

- userId: string

Return Type:

- data: ViolationLog[]
- isLoading: boolean
- error: Error | null

Caching Strategy:

- staleTime: 3분
- cacheTime: 10분
- enabled: !!userId

**useViolationStats**

Query Key: `['violations', 'stats', period]`

Parameters:

- period (optional): from, to

Return Type:

- data: ViolationStats
- isLoading: boolean
- error: Error | null

Caching Strategy:

- staleTime: 5분 (통계는 덜 자주 변경)
- cacheTime: 15분
- refetchInterval: 5분 (자동 갱신)

#### 4.2.3 자동 탐지 시스템 (US6.11)

**useAutoDetectedContent**

Query Key: `['auto-detected', 'list', filters]`

Parameters:

- filters (optional): severity, status, dateFrom

Return Type:

- data: Array<{dashboard: Dashboard, violation: ViolationLog}>
- isLoading: boolean
- error: Error | null

Caching Strategy:

- staleTime: 1분
- cacheTime: 5분
- refetchOnWindowFocus: true

**useDetectionRules**

Query Key: `['detection-rules', 'list']`

Parameters:

- (none)

Return Type:

- data: DetectionRule[]
- isLoading: boolean
- error: Error | null

Caching Strategy:

- staleTime: 10분 (룰은 자주 변경되지 않음)
- cacheTime: 30분
- refetchOnWindowFocus: false

**useDetectionRule**

Query Key: `['detection-rules', ruleId]`

Parameters:

- ruleId: string

Return Type:

- data: DetectionRule
- isLoading: boolean
- error: Error | null

Caching Strategy:

- staleTime: 10분
- cacheTime: 30분
- enabled: !!ruleId

### 4.3 Mutation Hooks (Write Operations)

#### 4.3.1 신고 관리 (US6.9)

**useReviewReport**

Mutation Function: `reviewReport(reportId, action, reason)`

Parameters:

- reportId: string
- action: 'warning' | 'delete_dashboard' | 'suspend_user' | 'dismiss'
- reason: string

Invalidation:

- `['reports', 'list']` (모든 필터)
- `['reports', reportId]`
- `['violations', 'stats']`
- action이 'delete_dashboard'이면 `['dashboards', 'list']` 추가 무효화
- action이 'suspend_user'이면 `['violations', 'user', userId]` 추가 무효화

Optimistic Update:

- reports 목록에서 해당 report의 status를 'actioned'로 즉시 변경
- 실패 시 rollback

#### 4.3.2 위반 사용자 관리 (US6.10)

**useSuspendUser**

Mutation Function: `suspendUser(userId, reason, duration)`

Parameters:

- userId: string
- reason: string
- duration (optional): number (hours)

Invalidation:

- `['violations', 'user', userId]`
- `['violations', 'stats']`
- `['users', userId]` (Admin Console에서 사용)

#### 4.3.3 자동 탐지 시스템 (US6.11)

**useCreateDetectionRule**

Mutation Function: `createDetectionRule(rule)`

Parameters:

- rule: Omit<DetectionRule, 'id' | 'createdAt'>

Invalidation:

- `['detection-rules', 'list']`

**useUpdateDetectionRule**

Mutation Function: `updateDetectionRule(ruleId, updates)`

Parameters:

- ruleId: string
- updates: Partial<DetectionRule>

Invalidation:

- `['detection-rules', 'list']`
- `['detection-rules', ruleId]`

Optimistic Update:

- rules 목록에서 해당 rule 즉시 업데이트
- 실패 시 rollback

**useDeleteDetectionRule**

Mutation Function: `deleteDetectionRule(ruleId)`

Parameters:

- ruleId: string

Invalidation:

- `['detection-rules', 'list']`

**useDismissViolation**

Mutation Function: `dismissViolation(violationId, reason)`

Parameters:

- violationId: string
- reason: string

Invalidation:

- `['auto-detected', 'list']` (모든 필터)
- `['violations', 'stats']`

Optimistic Update:

- auto-detected 목록에서 해당 violation의 status를 'dismissed'로 즉시 변경

### 4.4 Custom Hooks

**useReportFilters**

신고 필터 상태 관리 및 URL 동기화

Return:

- filters: {status, reason, dateFrom, dateTo}
- setFilter: (key, value) => void
- resetFilters: () => void

**useViolationFilters**

위반 사용자 필터 상태 관리

Return:

- filters: {sortBy, search}
- setFilter: (key, value) => void
- resetFilters: () => void

**useDetectionFilters**

자동 탐지 필터 상태 관리

Return:

- filters: {severity, status, dateFrom}
- setFilter: (key, value) => void
- resetFilters: () => void

**useReportActions**

신고 조치 관련 액션 통합

Return:

- reviewReport: (reportId, action, reason) => Promise<void>
- isReviewing: boolean
- error: Error | null

**useDetectionRuleActions**

탐지 룰 CRUD 액션 통합

Return:

- createRule: (rule) => Promise<DetectionRule>
- updateRule: (ruleId, updates) => Promise<DetectionRule>
- deleteRule: (ruleId) => Promise<void>
- isLoading: boolean
- error: Error | null

### 4.5 Hooks 명명 규칙

- Query Hook: `use{Resource}{Operation}` (예: useReportedDashboards, useViolationStats)
- Mutation Hook: `use{Action}{Resource}` (예: useReviewReport, useSuspendUser)
- Custom Hook: `use{Purpose}` (예: useReportFilters, useReportActions)

### 4.6 Error Handling

모든 Hooks는 통일된 에러 처리를 제공합니다:

- Network Error: Toast로 "네트워크 오류가 발생했습니다" 표시
- Authorization Error: 관리자 권한 확인 후 로그인 페이지로 리다이렉트
- Validation Error: 폼 필드별 에러 메시지 표시
- Server Error: Toast로 에러 메시지 표시 + Sentry로 로깅

### 4.7 Loading States

- Initial Loading: Skeleton UI 표시
- Refetching: 기존 데이터 유지하며 상단에 작은 로딩 인디케이터
- Mutation Loading: 버튼에 Spinner 표시 + 버튼 비활성화

## 5. Business Logic 분리

### 5.1 분리 원칙

Admin Moderation Feature Module은 복잡한 검증 및 계산 로직만 별도 Service로 분리합니다. 단순한 UI 로직은 컴포넌트나 Hook에 포함합니다.

### 5.2 분리할 Services

#### 5.2.1 detectionRuleValidation.ts

**책임**: 탐지 룰의 정규표현식 검증 및 위험 키워드 매칭

**주요 함수**:

validatePattern(pattern: string): ValidationResult

- 정규표현식 유효성 검증
- 위험한 패턴 감지 (ReDoS 방지)
- 에러 메시지 반환

testPattern(pattern: string, text: string): MatchResult[]

- 패턴을 테스트 텍스트에 적용
- 매칭된 위치와 내용 반환
- 하이라이팅용 정보 제공

detectKeywords(text: string, rules: DetectionRule[]): DetectionMatch[]

- 여러 룰을 텍스트에 적용
- 매칭된 룰과 키워드 반환
- 위험도별 정렬

checkRuleConflict(newRule: DetectionRule, existingRules: DetectionRule[]): ConflictResult

- 새 룰이 기존 룰과 중복되는지 확인
- 중복 패턴 감지
- 충돌 해결 제안

**의존성**: 없음 (순수 함수)

#### 5.2.2 violationSeverityCalculator.ts

**책임**: 위반 심각도 계산 및 자동 제재 판단

**주요 함수**:

calculateSeverity(violations: ViolationLog[]): SeverityScore

- 위반 이력을 기반으로 심각도 점수 계산
- 위반 유형별 가중치 적용 (investment_advice: 3점, spam: 1점)
- 최근 위반 간격 고려 (짧을수록 높은 점수)
- 총점 반환 (0-100)

shouldAutoSuspend(user: User, violations: ViolationLog[]): SuspensionRecommendation

- 자동 제재 필요 여부 판단
- 단계적 제재 규칙 적용:
  - 1회 경고: 이메일 알림만
  - 2회 경고: 48시간 게시 제한
  - 3회 위반: 영구 정지
- 제재 이유와 기간 반환

getNextSuspensionDuration(previousViolations: ViolationLog[]): number

- 다음 제재 기간 계산
- 위반 횟수에 따라 증가 (48시간 → 7일 → 30일 → 영구)

categorizeViolationPattern(violations: ViolationLog[]): ViolationPattern

- 위반 패턴 분류
- "occasional" (가끔), "frequent" (자주), "serial" (연속)
- 패턴별 대응 전략 제안

**의존성**: 없음 (순수 함수)

### 5.3 Hook/컴포넌트에 포함할 로직

**신고 필터링**

- 간단한 쿼리 파라미터 처리
- URL 동기화
- useReportFilters Hook에서 처리

**제재 기간 포맷팅**

- 시간 단위 변환 (hours → "48시간", "7일")
- 컴포넌트 내에서 직접 처리

**조치 결과 포맷팅**

- action 값을 UI 텍스트로 변환
- 'warning' → "경고 발송"
- 컴포넌트 또는 유틸리티 함수

**상태 배지 색상 결정**

- status 값에 따른 색상 매핑
- StatusBadge 컴포넌트 내에서 처리

**페이지네이션 계산**

- offset, limit 계산
- usePagination Hook에서 처리

## 6. File Structure

### 6.1 packages/admin-moderation/ 구조

```
packages/
  @e-torch/admin-moderation/
    src/
      components/
        reports/
          ReportsPage.tsx
          ReportsPageHeader.tsx
          ReportsTable.tsx
          ReportDetailDialog.tsx
          ReportActionButtons.tsx
        violations/
          ViolationsPage.tsx
          ViolationsTable.tsx
          ViolationHistoryDialog.tsx
          SuspendUserDialog.tsx
          ViolationTimeline.tsx
        detection/
          DetectionPage.tsx
          AutoDetectedTab.tsx
          DetectionRulesTab.tsx
          DetectionRuleDialog.tsx
          PatternValidator.tsx
        common/
          KeywordHighlighter.tsx
          SeverityBadge.tsx
          ViolationTypeIcon.tsx
          ModerationLayout.tsx
      hooks/
        queries/
          useReportedDashboards.ts
          useReportDetail.ts
          useUserViolations.ts
          useViolationStats.ts
          useAutoDetectedContent.ts
          useDetectionRules.ts
          useDetectionRule.ts
        mutations/
          useReviewReport.ts
          useSuspendUser.ts
          useCreateDetectionRule.ts
          useUpdateDetectionRule.ts
          useDeleteDetectionRule.ts
          useDismissViolation.ts
        custom/
          useReportFilters.ts
          useViolationFilters.ts
          useDetectionFilters.ts
          useReportActions.ts
          useDetectionRuleActions.ts
      types/
        contracts.ts      # AdminModerationContract
        reports.ts        # DashboardReport 관련 타입
        violations.ts     # ViolationLog, ViolationStats 관련 타입
        detection.ts      # DetectionRule 관련 타입
        filters.ts        # 필터 관련 타입
        common.ts         # 공통 타입
      schemas/
        reports.ts        # Report 관련 Zod Schema
        violations.ts     # Violation 관련 Zod Schema
        detection.ts      # DetectionRule 관련 Zod Schema
      services/
        detectionRuleValidation.ts
        violationSeverityCalculator.ts
      utils/
        formatters.ts     # 날짜, 시간, 상태 포맷팅
        constants.ts      # 제재 기간, 위반 유형 등 상수
      index.ts            # Public API
    package.json
    tsconfig.json
```

### 6.2 apps/admin/app/(moderation)/ 구조

```
apps/
  admin/
    app/
      (moderation)/
        layout.tsx        # ModerationLayout 적용
        reports/
          page.tsx        # ReportsPage
        violations/
          page.tsx        # ViolationsPage
        detection/
          page.tsx        # DetectionPage
      api/
        moderation/
          reports/
            route.ts      # GET /api/moderation/reports
            [id]/
              review/
                route.ts  # POST /api/moderation/reports/:id/review
          violations/
            users/
              [id]/
                route.ts  # GET /api/moderation/violations/users/:id
            stats/
              route.ts    # GET /api/moderation/violations/stats
          users/
            [userId]/
              suspend/
                route.ts  # POST /api/moderation/users/:userId/suspend
          auto-detect/
            route.ts      # GET /api/moderation/auto-detect
          detection-rules/
            route.ts      # GET, POST /api/moderation/detection-rules
            [id]/
              route.ts    # PATCH /api/moderation/detection-rules/:id
          violations/
            [id]/
              dismiss/
                route.ts  # POST /api/moderation/violations/:id/dismiss
```

### 6.3 Public API (packages/admin-moderation/src/index.ts)

```typescript
// Components
export { ReportsPage } from './components/reports/ReportsPage'
export { ViolationsPage } from './components/violations/ViolationsPage'
export { DetectionPage } from './components/detection/DetectionPage'
export { ModerationLayout } from './components/common/ModerationLayout'

// Hooks (Queries)
export { useReportedDashboards } from './hooks/queries/useReportedDashboards'
export { useUserViolations } from './hooks/queries/useUserViolations'
export { useViolationStats } from './hooks/queries/useViolationStats'
export { useAutoDetectedContent } from './hooks/queries/useAutoDetectedContent'
export { useDetectionRules } from './hooks/queries/useDetectionRules'

// Hooks (Mutations)
export { useReviewReport } from './hooks/mutations/useReviewReport'
export { useSuspendUser } from './hooks/mutations/useSuspendUser'
export { useCreateDetectionRule } from './hooks/mutations/useCreateDetectionRule'
export { useUpdateDetectionRule } from './hooks/mutations/useUpdateDetectionRule'
export { useDismissViolation } from './hooks/mutations/useDismissViolation'

// Hooks (Custom)
export { useReportFilters } from './hooks/custom/useReportFilters'
export { useReportActions } from './hooks/custom/useReportActions'

// Types
export * from './types/contracts'
export * from './types/reports'
export * from './types/violations'
export * from './types/detection'

// Schemas
export * from './schemas/reports'
export * from './schemas/violations'
export * from './schemas/detection'

// Services
export * from './services/detectionRuleValidation'
export * from './services/violationSeverityCalculator'
```

### 6.4 파일 명명 규칙

- 컴포넌트: PascalCase (ReportsPage.tsx)
- Hook: camelCase with 'use' prefix (useReportedDashboards.ts)
- Type 파일: camelCase (reports.ts, violations.ts)
- Service 파일: camelCase (detectionRuleValidation.ts)
- 유틸리티 파일: camelCase (formatters.ts)

## 7. 의존성

### 7.1 내부 의존성 (Monorepo Packages)

**@e-torch/ui**

- AppLayout, DataTable, FormDialog, ConfirmDialog, Toast, SearchInput, Pagination, StatusBadge, DateTimeDisplay

**@e-torch/core**

- 공통 타입 (User, Dashboard)
- 유틸리티 함수 (날짜 포맷팅, 문자열 처리)

**@e-torch/query**

- QueryClient 설정
- React Query DevTools

**@e-torch/auth** (Authentication Feature Module)

- getCurrentUser()
- hasRole('admin')
- useAuth Hook

**@e-torch/dashboard** (Dashboard Feature Module, 읽기 전용)

- Dashboard 타입 참조
- getDashboards() (신고된 대시보드 조회)

### 7.2 외부 의존성 (npm packages)

**필수**:

- <react@19.x>
- <react-dom@19.x>
- @tanstack/react-query@5.x
- <zod@3.x>
- <typescript@5.x>

**UI**:

- @radix-ui/react-dialog (Modal)
- @radix-ui/react-dropdown-menu
- @radix-ui/react-tabs
- @radix-ui/react-select
- @radix-ui/react-toggle
- lucide-react (아이콘)
- <tailwindcss@3.x>

**데이터 페칭**:

- @supabase/supabase-js@2.x

**유틸리티**:

- date-fns (날짜 처리)
- clsx (className 조합)

**개발**:

- @types/react
- @types/node
- eslint
- prettier

### 7.3 Supabase Schema 의존성

Admin Moderation은 다음 Supabase 테이블을 사용합니다:

**dashboard_reports** (신고 테이블)

- id: uuid (PK)
- dashboard_id: uuid (FK → dashboards.id)
- reporter_id: uuid (FK → users.id)
- reason: text
- description: text
- status: text
- review_note: text
- created_at: timestamp
- reviewed_at: timestamp

**violation_logs** (위반 로그 테이블)

- id: uuid (PK)
- user_id: uuid (FK → users.id)
- dashboard_id: uuid (FK → dashboards.id)
- violation_type: text
- severity: text
- detected_by: text
- detected_pattern: text
- status: text
- action_taken: text
- action_reason: text
- reviewed_by: uuid (FK → users.id)
- created_at: timestamp
- reviewed_at: timestamp

**detection_rules** (탐지 룰 테이블)

- id: uuid (PK)
- name: text
- pattern: text
- severity: text
- action: text
- is_active: boolean
- description: text
- created_at: timestamp

**RLS (Row Level Security) 정책**:

- SELECT: role = 'admin' 인 사용자만 접근 가능
- INSERT/UPDATE/DELETE: role = 'admin' 인 사용자만 접근 가능

## 8. 보안 고려사항

### 8.1 인증 및 권한

**관리자 권한 검증**:

- 모든 API 엔드포인트에서 `hasRole('admin')` 검증
- Supabase RLS로 이중 보호
- 세션 만료 시 자동 로그아웃

**권한 부족 시 처리**:

- 403 Forbidden 응답
- 에러 페이지로 리다이렉트
- Toast로 "관리자 권한이 필요합니다" 표시

### 8.2 데이터 보호

**신고자 익명성 보장**:

- 신고자 ID는 관리자에게만 표시
- 일반 사용자는 신고 여부만 확인 가능
- 신고자 정보는 암호화하여 저장 (선택 사항)

**민감 정보 처리**:

- 위반 로그의 dashboard_id는 논리 삭제 후에도 유지 (감사 목적)
- 조치 사유는 영구 보존
- 개인정보는 익명화 처리 (GDPR 준수)

### 8.3 입력 검증

**정규표현식 검증**:

- ReDoS 공격 방지 (detectionRuleValidation 서비스)
- 패턴 복잡도 제한
- 테스트 실행 시간 제한 (1초)

**문자열 길이 제한**:

- reason: 최소 10자, 최대 1000자
- description: 최대 5000자
- pattern: 최대 500자

**SQL Injection 방지**:

- Supabase client의 파라미터화된 쿼리 사용
- 사용자 입력 직접 SQL에 삽입 금지

### 8.4 로깅 및 감사

**조치 로그 영구 보존**:

- 모든 조치 (경고, 삭제, 제재)를 violation_logs에 기록
- 삭제 불가능 (soft delete 사용)
- 법적 분쟁 대비

**ActivityLog 자동 기록**:

- 관리자 액션 자동 로깅
- IP 주소, User Agent 기록
- 타임스탬프 UTC 저장

### 8.5 Rate Limiting

**조치 실행 제한**:

- 동일 관리자가 1분에 최대 10건 조치 가능
- 초과 시 429 Too Many Requests
- Vercel Edge Config로 구현

**API 호출 제한**:

- 관리자 API는 1분에 100 요청으로 제한
- Vercel Middleware에서 구현

### 8.6 위험 액션 확인

**돌이킬 수 없는 액션**:

- 대시보드 삭제: ConfirmDialog로 재확인
- 영구 정지: 재확인 + 사유 필수 입력
- 탐지 룰 삭제: 활성 룰인 경우 경고 메시지

**Optimistic Update 롤백**:

- 조치 실행 실패 시 UI 자동 롤백
- 에러 메시지 Toast 표시

## 9. 다음 단계

Admin Moderation Feature Module 설계 완료 후 다음 단계는 BFF API 및 Feature Module 구현입니다.

### 9.1 BFF API 구현

Admin Moderation의 10개 메서드를 BFF API Routes로 구현:

**apps/admin/app/api/moderation/ 구조**:

```
app/api/moderation/
├── reports/
│   ├── route.ts                      # GET /api/moderation/reports
│   └── [id]/
│       └── review/
│           └── route.ts              # POST /api/moderation/reports/:id/review
├── violations/
│   ├── users/
│   │   └── [id]/
│   │       └── route.ts              # GET /api/moderation/violations/users/:id
│   └── stats/
│       └── route.ts                  # GET /api/moderation/violations/stats
├── users/
│   └── [userId]/
│       └── suspend/
│           └── route.ts              # POST /api/moderation/users/:userId/suspend
├── auto-detect/
│   └── route.ts                      # GET /api/moderation/auto-detect
├── detection-rules/
│   ├── route.ts                      # GET, POST /api/moderation/detection-rules
│   └── [id]/
│       └── route.ts                  # PATCH /api/moderation/detection-rules/:id
└── violations/
    └── [id]/
        └── dismiss/
            └── route.ts              # POST /api/moderation/violations/:id/dismiss
```

**각 API Route 구현 시**:

- Zod Schema로 요청 검증
- `hasRole('admin')` 권한 확인
- Supabase client로 데이터베이스 조회/수정
- 에러 처리 및 로깅
- Activity Log 자동 기록

### 9.2 Supabase Schema 구현

**테이블 생성 (SQL Migration)**:

```sql
-- dashboard_reports 테이블
CREATE TABLE dashboard_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  dashboard_id uuid REFERENCES dashboards(id) ON DELETE CASCADE,
  reporter_id uuid REFERENCES users(id) ON DELETE SET NULL,
  reason text NOT NULL CHECK (reason IN ('investment_advice', 'scam', 'false_info', 'spam', 'other')),
  description text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'actioned', 'dismissed')),
  review_note text,
  created_at timestamptz DEFAULT now(),
  reviewed_at timestamptz
);

-- violation_logs 테이블
CREATE TABLE violation_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  dashboard_id uuid REFERENCES dashboards(id) ON DELETE SET NULL,
  violation_type text NOT NULL CHECK (violation_type IN ('investment_advice', 'false_claim', 'spam', 'other')),
  severity text NOT NULL CHECK (severity IN ('low', 'medium', 'high')),
  detected_by text NOT NULL CHECK (detected_by IN ('user_report', 'auto_detection', 'admin_review')),
  detected_pattern text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'dismissed')),
  action_taken text CHECK (action_taken IN ('warning', 'delete_dashboard', 'suspend_user', 'none')),
  action_reason text,
  reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  reviewed_at timestamptz
);

-- detection_rules 테이블
CREATE TABLE detection_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  pattern text NOT NULL,
  severity text NOT NULL CHECK (severity IN ('low', 'medium', 'high')),
  action text NOT NULL CHECK (action IN ('flag', 'auto_hide', 'auto_delete')),
  is_active boolean DEFAULT true,
  description text,
  created_at timestamptz DEFAULT now()
);
```

**RLS 정책 생성**:

```sql
-- dashboard_reports RLS
ALTER TABLE dashboard_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all reports"
  ON dashboard_reports FOR SELECT
  TO authenticated
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admins can update reports"
  ON dashboard_reports FOR UPDATE
  TO authenticated
  USING (auth.jwt() ->> 'role' = 'admin');

-- violation_logs RLS
ALTER TABLE violation_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all violations"
  ON violation_logs FOR SELECT
  TO authenticated
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admins can insert violations"
  ON violation_logs FOR INSERT
  TO authenticated
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- detection_rules RLS
ALTER TABLE detection_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage detection rules"
  ON detection_rules FOR ALL
  TO authenticated
  USING (auth.jwt() ->> 'role' = 'admin');
```

**인덱스 생성 (성능 최적화)**:

```sql
CREATE INDEX idx_reports_status ON dashboard_reports(status);
CREATE INDEX idx_reports_dashboard_id ON dashboard_reports(dashboard_id);
CREATE INDEX idx_reports_created_at ON dashboard_reports(created_at DESC);

CREATE INDEX idx_violations_user_id ON violation_logs(user_id);
CREATE INDEX idx_violations_status ON violation_logs(status);
CREATE INDEX idx_violations_severity ON violation_logs(severity);
CREATE INDEX idx_violations_created_at ON violation_logs(created_at DESC);

CREATE INDEX idx_detection_rules_active ON detection_rules(is_active);
```

### 9.3 Feature Module 구현

**packages/admin-moderation/ 구현 순서**:

1. **타입 및 스키마** (types/, schemas/)
   - AdminModerationContract 인터페이스 정의
   - 공통 타입 정의 (DashboardReport, ViolationLog, etc.)
   - Zod Schema 정의

2. **Services** (services/)
   - detectionRuleValidation.ts 구현
   - violationSeverityCalculator.ts 구현
   - 단위 테스트 작성

3. **Query Hooks** (hooks/queries/)
   - useReportedDashboards, useUserViolations 등 구현
   - Query Key 설정
   - Caching 전략 적용

4. **Mutation Hooks** (hooks/mutations/)
   - useReviewReport, useSuspendUser 등 구현
   - Invalidation 패턴 적용
   - Optimistic Update 구현

5. **Custom Hooks** (hooks/custom/)
   - useReportFilters, useReportActions 등 구현

6. **공통 컴포넌트** (components/common/)
   - ModerationLayout, KeywordHighlighter 등 구현

7. **페이지 컴포넌트** (components/reports/, violations/, detection/)
   - ReportsPage, ViolationsPage, DetectionPage 구현
   - 하위 컴포넌트 구현

8. **통합 테스트**
   - 각 페이지별 E2E 테스트
   - Hook 통합 테스트

### 9.4 통합 및 배포

**apps/admin 통합**:

- (moderation)/ 라우트에 페이지 추가
- ModerationLayout 적용
- 네비게이션 메뉴 추가

**Vercel 배포**:

- apps/admin을 Multi-Zone으로 배포
- 환경 변수 설정 (SUPABASE_URL, SUPABASE_ANON_KEY)
- Edge Config 설정 (Rate Limiting)

### 9.5 테스트 전략

**단위 테스트** (Jest + Testing Library):

- Services (detectionRuleValidation, violationSeverityCalculator)
- Hooks (모든 Query/Mutation Hooks)
- 유틸리티 함수

**통합 테스트** (Playwright):

- 신고 관리 플로우 (조회 → 검토 → 조치)
- 위반 사용자 관리 플로우 (조회 → 제재)
- 탐지 룰 관리 플로우 (생성 → 수정 → 삭제)

**E2E 테스트**:

- 관리자 로그인 → 신고 페이지 접근 → 조치 실행
- 자동 탐지 결과 확인 → 오탐 처리

### 9.6 문서화

**개발 문서**:

- API 문서 (각 BFF API Route의 요청/응답 명세)
- Hook 사용 가이드
- 컴포넌트 Storybook

**운영 문서**:

- 관리자 매뉴얼 (각 기능 사용법)
- 탐지 룰 작성 가이드
- 제재 절차 가이드

## 10. 요약

Admin Moderation Feature Module은 E-Torch 플랫폼의 컨텐츠 안전성과 법적 규제 준수를 담당하는 핵심 모듈입니다.

**주요 특징**:

- AdminModerationContract 10개 메서드 완전 매핑
- TypeScript + Zod로 타입 안정성 및 런타임 검증
- React 19 + TanStack Query v5 기반 UI
- Resource 기반 Query Key 전략
- 복잡한 검증 로직만 Service로 분리
- Admin Console과 동일한 앱에서 독립 패키지로 실행

**User Story 커버리지**:

- US6.9: 신고된 컨텐츠 관리 ✓
- US6.10: 컨텐츠 위반 사용자 관리 ✓
- US6.11: 위험 컨텐츠 자동 탐지 ✓

**다음 단계**: BFF API 구현, Supabase Schema 생성, Feature Module 구현, 통합 테스트, 배포
