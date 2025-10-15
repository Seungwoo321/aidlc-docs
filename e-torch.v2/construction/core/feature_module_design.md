# Core Unit Feature Module 설계 문서

## 개요

**Feature Module**: Core Unit
**책임**: 공유 TypeScript 타입, 비즈니스 로직, 유틸리티 함수 제공
**아키텍처**: Pure TypeScript Package, TypeScript + Zod, Tree-shakable Named Exports

## 승인된 아키텍처 결정사항

### 1. Zod Schema 위치 전략
- **전략**: 타입과 Schema 별도 파일
- **근거**: 트리 쉐이킹 최적화, TypeScript 우선 설계, 역할 분리

### 2. Business Logic 함수 순수성
- **전략**: 완전 순수 함수
- **근거**: 테스트 용이성, 예측 가능성, 외부 의존성 없음

### 3. 상수 관리 전략
- **전략**: 카테고리별 분리 (api, routes, storage, limits, regex)
- **근거**: 트리 쉐이킹 최적화, 역할 분리, 파일 크기 관리

### 4. Error Type 제공 전략
- **전략**: Error Factory Function
- **근거**: API 응답 호환, 직렬화 쉬움, 번들 크기 최소화

### 5. Utility 함수 네이밍
- **전략**: 동사 시작 (formatDate, formatNumber, slugify)
- **근거**: JavaScript 커뮤니티 표준, 가독성, 자동완성 지원

## Core Unit 특징

- **React Components 없음**: 순수 TypeScript 라이브러리
- **BFF API 없음**: 데이터 페칭 없음
- **TanStack Query Hooks 없음**: 상태 관리 없음
- **최하위 레이어**: 다른 패키지에 의존하지 않음 (Zod만 의존)
- **모든 Feature Module의 기반**: 타입, 로직, 유틸리티 제공

## 1. Domain Types 정의

### 1.1 User & Authentication Types

#### User
- **필드**: id, email, name, avatar, role, status, linkedProviders
- **목적**: 사용자 프로필 정보
- **Zod Schema**: UserSchema
- **관계**: Session, ActivityLog

#### Session
- **필드**: access_token, refresh_token, expires_in, expires_at, user
- **목적**: 인증 세션 정보
- **Zod Schema**: SessionSchema
- **관계**: User

#### AuthContext
- **필드**: user, session, isAuthenticated, signIn, signOut, refreshSession
- **목적**: React Context 타입
- **Zod Schema**: 없음 (React Context 타입)
- **관계**: User, Session

---

### 1.2 Dashboard Types

#### Dashboard
- **필드**: id, userId, name, description, categoryCode, layout, isPublic, isDefault, shareLinks, createdAt, updatedAt, lastAutoSaveAt, lastViewedAt
- **목적**: 대시보드 기본 정보
- **Zod Schema**: DashboardSchema
- **관계**: User, WidgetLayout, Category, ShareLink

#### WidgetLayout
- **필드**: id, dashboardId, widgetId, x, y, width, height, order
- **목적**: 위젯 배치 정보
- **Zod Schema**: WidgetLayoutSchema
- **관계**: Dashboard, Widget

#### DashboardVersion (Pro)
- **필드**: id, dashboardId, userId, version, layouts, savedAt
- **목적**: 대시보드 버전 관리
- **Zod Schema**: DashboardVersionSchema
- **관계**: Dashboard, WidgetLayout

#### DashboardBookmark
- **필드**: id, userId, dashboardId, createdAt
- **목적**: 즐겨찾기 정보
- **Zod Schema**: DashboardBookmarkSchema
- **관계**: User, Dashboard

#### ShareLink
- **필드**: id, dashboardId, token, isActive, expiresAt, createdAt, createdBy
- **목적**: 공유 링크 정보
- **Zod Schema**: ShareLinkSchema
- **관계**: Dashboard

---

### 1.3 Widget Types

#### Widget
- **필드**: id, userId, type, name, parameters, isPublic, createdAt, updatedAt
- **목적**: 위젯 기본 정보
- **Zod Schema**: WidgetSchema
- **관계**: User, WidgetParameters, WidgetType

#### WidgetType
- **열거형**: 'time-series', 'bar-chart', 'pie-chart', 'treemap', 'scatter-chart', 'radar-chart', 'radial-bar-chart', 'text-custom', 'text-data'
- **목적**: 위젯 타입 정의
- **Zod Schema**: WidgetTypeSchema

#### WidgetParameters
- **필드**: indicatorId, period, startDate, endDate, chartOptions, customOptions
- **목적**: 위젯 설정 파라미터
- **Zod Schema**: WidgetParametersSchema
- **관계**: Indicator, DataPeriod

---

### 1.4 Data Integration Types

#### Indicator
- **필드**: id, name, description, source, categoryCode, unit, frequency, apiParams, createdAt, updatedAt
- **목적**: 지표 기본 정보
- **Zod Schema**: IndicatorSchema
- **관계**: DataSource, Category

#### ManagedIndicator (Admin용)
- **extends**: Indicator
- **추가 필드**: isActive, usageCount, lastSyncAt, createdBy, updatedBy
- **목적**: 관리자가 관리하는 지표 정보
- **Zod Schema**: ManagedIndicatorSchema

#### DataSource
- **필드**: id, name, description, isActive, apiKey, createdAt, updatedAt, updatedBy
- **목적**: 데이터 소스 정보
- **Zod Schema**: DataSourceSchema

#### DataPeriod
- **열거형**: 'daily', 'monthly', 'quarterly', 'yearly'
- **목적**: 데이터 주기
- **Zod Schema**: DataPeriodSchema

#### StandardizedData
- **필드**: indicatorId, period, data, lastUpdated
- **목적**: 표준화된 데이터 포맷
- **Zod Schema**: StandardizedDataSchema
- **관계**: Indicator, DataPoint

#### DataPoint
- **필드**: date, value, metadata
- **목적**: 개별 데이터 포인트
- **Zod Schema**: DataPointSchema

---

### 1.5 Subscription Types

#### Subscription
- **필드**: id, userId, planType, status, startDate, expiryDate, cancelledAt, createdAt, updatedAt
- **목적**: 구독 정보
- **Zod Schema**: SubscriptionSchema
- **관계**: User, PlanType

#### PlanType
- **열거형**: 'free', 'pro'
- **목적**: 플랜 타입
- **Zod Schema**: PlanTypeSchema

#### SubscriptionStatus
- **열거형**: 'active', 'cancelled', 'expired'
- **목적**: 구독 상태
- **Zod Schema**: SubscriptionStatusSchema

#### UsageStats
- **필드**: userId, dashboardCount, dashboardLimit, widgetCount, widgetLimit, bookmarkCount, bookmarkLimit, dataRetentionYears
- **목적**: 사용량 통계
- **Zod Schema**: UsageStatsSchema
- **관계**: User, Subscription

#### PlanLimitConfig
- **필드**: id, planType, limitKey, limitValue, description, unit, isActive, effectiveDate, expiryDate, updatedAt, updatedBy
- **목적**: 플랜 제한 설정 (동적)
- **Zod Schema**: PlanLimitConfigSchema
- **관계**: PlanType

#### DynamicPlanLimits
- **필드**: planType, limits (Map<string, any>), effectiveDate, expiryDate
- **목적**: 런타임에 로드된 플랜 제한값
- **Zod Schema**: DynamicPlanLimitsSchema
- **관계**: PlanType, PlanLimitConfig

---

### 1.6 Admin Types

#### DashboardTemplate
- **필드**: id, name, description, categoryCode, thumbnail, isActive, isPro, widgets, createdAt, updatedAt
- **목적**: 대시보드 템플릿
- **Zod Schema**: DashboardTemplateSchema
- **관계**: Category, TemplateWidget

#### TemplateWidget
- **필드**: widgetType, name, parameters, layout (x, y, width, height, order)
- **목적**: 템플릿에 포함된 위젯 정보
- **Zod Schema**: TemplateWidgetSchema
- **관계**: WidgetType, WidgetParameters

#### Category
- **필드**: id, code, name, description, order, isActive, usageCount, createdAt, updatedAt
- **목적**: 카테고리 정보
- **Zod Schema**: CategorySchema

#### ActivityLog
- **필드**: id, userId, action, resourceType, resourceId, details, ipAddress, userAgent, createdAt
- **목적**: 활동 로그
- **Zod Schema**: ActivityLogSchema
- **관계**: User

#### CustomDataPoint
- **필드**: id, indicatorId, date, value, metadata, createdBy, createdAt, updatedAt
- **목적**: 수동 입력 데이터
- **Zod Schema**: CustomDataPointSchema
- **관계**: Indicator

#### CustomDataImportResult
- **필드**: success, totalRows, importedRows, errors, preview
- **목적**: CSV 임포트 결과
- **Zod Schema**: CustomDataImportResultSchema
- **관계**: CustomDataPoint

#### CustomDataHistory
- **필드**: id, indicatorId, dataPointId, action, oldValue, newValue, changedBy, changedAt
- **목적**: 데이터 변경 이력
- **Zod Schema**: CustomDataHistorySchema
- **관계**: CustomDataPoint

#### PlanLimitHistory
- **필드**: id, limitKey, planType, oldValue, newValue, changedBy, changedAt, reason
- **목적**: 플랜 제한 변경 이력
- **Zod Schema**: PlanLimitHistorySchema
- **관계**: PlanLimitConfig

#### SystemMetrics
- **필드**: totalUsers, activeUsers, totalDashboards, totalWidgets, apiCallsToday, avgResponseTime, errorRate, timestamp
- **목적**: 시스템 메트릭
- **Zod Schema**: SystemMetricsSchema

#### DashboardStats
- **필드**: totalPublic, totalPrivate, avgWidgetsPerDashboard, mostUsedCategories, mostUsedIndicators
- **목적**: 대시보드 통계
- **Zod Schema**: DashboardStatsSchema

#### AdminUserView
- **필드**: id, email, name, planType, status, dashboardCount, lastLoginAt, createdAt
- **목적**: 관리자가 보는 사용자 정보
- **Zod Schema**: AdminUserViewSchema
- **관계**: User, Subscription

#### TestResult
- **필드**: success, responseTime, statusCode, message, error, testedAt
- **목적**: API/연결 테스트 결과
- **Zod Schema**: TestResultSchema

---

### 1.7 Content Moderation Types

#### ConsentLog
- **필드**: id, userId, dashboardId, consentType, consentText, consentVersion, ipAddress, userAgent, timestamp
- **목적**: 법적 동의 로그 (US2.12, US2.13)
- **Zod Schema**: ConsentLogSchema
- **관계**: User, Dashboard

#### ViolationLog
- **필드**: id, userId, dashboardId, violationType, severity, detectedBy, detectedPattern, status, actionTaken, actionReason, reviewedBy, createdAt, reviewedAt
- **목적**: 위반 로그
- **Zod Schema**: ViolationLogSchema
- **관계**: User, Dashboard

#### DashboardReport
- **필드**: id, dashboardId, reporterId, reason, description, status, reviewNote, createdAt, reviewedAt
- **목적**: 대시보드 신고
- **Zod Schema**: DashboardReportSchema
- **관계**: Dashboard, User

#### ViolationStats
- **필드**: totalReports, pendingReports, totalViolations, violationsByType, topViolators
- **목적**: 위반 통계
- **Zod Schema**: ViolationStatsSchema

#### DetectionRule
- **필드**: id, name, pattern, severity, action, isActive, description, createdAt
- **목적**: 자동 탐지 룰
- **Zod Schema**: DetectionRuleSchema

---

### 1.8 Utility Types

#### ListOptions
- **필드**: sortBy, sortOrder, category, isPublic, limit, offset, search
- **목적**: 목록 조회 옵션
- **Zod Schema**: ListOptionsSchema

#### WidgetListOptions
- **필드**: category, widgetType, indicatorId, sortBy, limit, search
- **목적**: 위젯 목록 조회 옵션
- **Zod Schema**: WidgetListOptionsSchema

#### ExportOptions
- **필드**: fileName, startDate, endDate, includeMetadata
- **목적**: 데이터 내보내기 옵션
- **Zod Schema**: ExportOptionsSchema

#### Filters
- **필드**: category, source, frequency, search
- **목적**: 지표 검색 필터
- **Zod Schema**: FiltersSchema

#### DataParams
- **필드**: startDate, endDate, period, limit
- **목적**: 데이터 조회 파라미터
- **Zod Schema**: DataParamsSchema

#### DataRequest
- **필드**: indicatorId, params
- **목적**: 배치 데이터 요청
- **Zod Schema**: DataRequestSchema

#### UserFilters
- **필드**: planType, status, search, sortBy, sortOrder
- **목적**: 사용자 필터
- **Zod Schema**: UserFiltersSchema

---

## 2. DTO Types 정의

### 2.1 Dashboard DTOs

#### CreateDashboardDto
- **필드**: name, description, categoryCode, isPublic, templateId (optional), sourceDashboardId (optional)
- **목적**: 대시보드 생성 요청
- **Zod Schema**: CreateDashboardDtoSchema
- **사용처**: POST /api/dashboards

#### UpdateDashboardDto
- **필드**: name (optional), description (optional), categoryCode (optional), isPublic (optional)
- **목적**: 대시보드 수정 요청
- **Zod Schema**: UpdateDashboardDtoSchema
- **사용처**: PATCH /api/dashboards/[id]

#### CreateFromTemplateDto
- **필드**: name, description (optional)
- **목적**: 템플릿에서 대시보드 생성
- **Zod Schema**: CreateFromTemplateDtoSchema
- **사용처**: POST /api/dashboards (with templateId)

#### DuplicateDto
- **필드**: name, description (optional)
- **목적**: 대시보드 복제
- **Zod Schema**: DuplicateDtoSchema
- **사용처**: POST /api/dashboards (with sourceDashboardId)

---

### 2.2 Widget DTOs

#### CreateWidgetDto
- **필드**: type, name, parameters, isPublic
- **목적**: 위젯 생성 요청
- **Zod Schema**: CreateWidgetDtoSchema
- **사용처**: POST /api/widgets

#### UpdateWidgetDto
- **필드**: name (optional), parameters (optional), isPublic (optional)
- **목적**: 위젯 수정 요청
- **Zod Schema**: UpdateWidgetDtoSchema
- **사용처**: PATCH /api/widgets/[id]

---

### 2.3 User DTOs

#### UpdateProfileDto
- **필드**: name (optional), avatar (optional)
- **목적**: 프로필 수정 요청
- **Zod Schema**: UpdateProfileDtoSchema
- **사용처**: PATCH /api/auth/profile

---

### 2.4 Legal & Moderation DTOs

#### ReportDashboardDto (US2.14)
- **필드**: reason ('investment_advice' | 'scam' | 'false_info' | 'spam' | 'other'), description (optional)
- **목적**: 대시보드 신고 요청
- **Zod Schema**: ReportDashboardDtoSchema
- **사용처**: POST /api/dashboards/[id]/report

#### LogConsentDto (US2.12, US2.13)
- **필드**: userId, consentType ('dashboard_create' | 'disclaimer_view'), metadata (dashboardId, consentText, consentVersion, ipAddress, userAgent)
- **목적**: 법적 동의 로그 기록
- **Zod Schema**: LogConsentDtoSchema
- **사용처**: POST /api/consent

---

### 2.5 Admin DTOs

#### CreateIndicatorDto
- **필드**: name, description, source, categoryId, unit, frequency, apiParams
- **목적**: 지표 생성 요청
- **Zod Schema**: CreateIndicatorDtoSchema
- **사용처**: POST /api/admin/indicators

#### UpdateIndicatorDto
- **필드**: name (optional), description (optional), categoryId (optional), unit (optional), frequency (optional), apiParams (optional), isActive (optional)
- **목적**: 지표 수정 요청
- **Zod Schema**: UpdateIndicatorDtoSchema
- **사용처**: PATCH /api/admin/indicators/[id]

#### CreateTemplateDto
- **필드**: name, description, categoryCode, thumbnail, isPro, widgets
- **목적**: 템플릿 생성 요청
- **Zod Schema**: CreateTemplateDtoSchema
- **사용처**: POST /api/admin/templates

#### UpdateTemplateDto
- **필드**: name (optional), description (optional), categoryCode (optional), thumbnail (optional), isPro (optional), isActive (optional), widgets (optional)
- **목적**: 템플릿 수정 요청
- **Zod Schema**: UpdateTemplateDtoSchema
- **사용처**: PATCH /api/admin/templates/[id]

#### CreateCategoryDto
- **필드**: code, name, description
- **목적**: 카테고리 생성 요청
- **Zod Schema**: CreateCategoryDtoSchema
- **사용처**: POST /api/admin/categories

#### UpdateCategoryDto
- **필드**: name (optional), description (optional)
- **목적**: 카테고리 수정 요청
- **Zod Schema**: UpdateCategoryDtoSchema
- **사용처**: PATCH /api/admin/categories/[id]

#### CreateDataSourceDto
- **필드**: name, description, apiKey (optional)
- **목적**: 데이터 소스 생성 요청
- **Zod Schema**: CreateDataSourceDtoSchema
- **사용처**: POST /api/admin/datasources

#### UpdateDataSourceDto
- **필드**: name (optional), description (optional)
- **목적**: 데이터 소스 수정 요청
- **Zod Schema**: UpdateDataSourceDtoSchema
- **사용처**: PATCH /api/admin/datasources/[id]

#### CreatePlanLimitDto
- **필드**: planType, limitKey, limitValue, description, unit
- **목적**: 플랜 제한 생성 요청
- **Zod Schema**: CreatePlanLimitDtoSchema
- **사용처**: POST /api/admin/plan-limits

#### UpdatePlanLimitDto
- **필드**: limitValue, description (optional), effectiveDate (optional), expiryDate (optional), reason
- **목적**: 플랜 제한 수정 요청
- **Zod Schema**: UpdatePlanLimitDtoSchema
- **사용처**: PATCH /api/admin/plan-limits/[id]

#### CustomDataPointDto
- **필드**: date, value, metadata (optional)
- **목적**: 커스텀 데이터 포인트 추가/수정
- **Zod Schema**: CustomDataPointDtoSchema
- **사용처**: POST /api/admin/custom-data/[indicatorId]

---

## 3. Error Types 정의

### 3.1 ErrorCode

**열거형**:
- `AUTH_REQUIRED`: 인증 필요
- `SESSION_EXPIRED`: 세션 만료
- `UNAUTHORIZED`: 권한 없음
- `FORBIDDEN`: 접근 금지
- `PLAN_LIMIT_EXCEEDED`: 플랜 제한 초과
- `DATA_NOT_FOUND`: 데이터 없음
- `API_ERROR`: 외부 API 오류
- `VALIDATION_ERROR`: 검증 오류
- `NETWORK_ERROR`: 네트워크 오류
- `SERVER_ERROR`: 서버 오류
- `INDICATOR_NOT_FOUND`: 지표 없음
- `DASHBOARD_NOT_FOUND`: 대시보드 없음
- `WIDGET_NOT_FOUND`: 위젯 없음
- `USER_NOT_FOUND`: 사용자 없음
- `DUPLICATE_ENTRY`: 중복 항목
- `CONSTRAINT_VIOLATION`: 제약 조건 위반

**Zod Schema**: ErrorCodeSchema (enum)

---

### 3.2 AppError

**필드**:
- `code`: ErrorCode
- `message`: string
- `details`: unknown (optional)

**목적**: 애플리케이션 에러 객체

**Zod Schema**: AppErrorSchema

---

### 3.3 Error Factory Function

**함수명**: `createError`

**시그니처**: `(code: ErrorCode, message: string, details?: unknown) => AppError`

**목적**: 에러 객체 생성

**특징**:
- 순수 함수 (side effect 없음)
- 직렬화 가능한 객체 반환
- API 응답과 호환

---

## 4. Business Logic 함수 명세

### 4.1 Subscription Logic

#### canCreateDashboard
- **시그니처**: `(currentCount: number, limit: number) => boolean`
- **목적**: 대시보드 생성 가능 여부 확인
- **로직**: currentCount < limit
- **사용처**: Dashboard 생성 시

#### canAddWidget
- **시그니처**: `(currentCount: number, limit: number) => boolean`
- **목적**: 위젯 추가 가능 여부 확인
- **로직**: currentCount < limit
- **사용처**: Widget 추가 시

#### canRestoreVersion
- **시그니처**: `(planType: PlanType) => boolean`
- **목적**: 버전 복원 가능 여부 확인 (Pro 전용)
- **로직**: planType === 'pro'
- **사용처**: Dashboard 버전 복원 시

#### canAddBookmark
- **시그니처**: `(currentCount: number, limit: number) => boolean`
- **목적**: 즐겨찾기 추가 가능 여부 확인
- **로직**: currentCount < limit
- **사용처**: Dashboard 즐겨찾기 시

#### canExportData
- **시그니처**: `(planType: PlanType) => boolean`
- **목적**: 데이터 내보내기 가능 여부 확인 (Pro 전용)
- **로직**: planType === 'pro'
- **사용처**: Widget 데이터 내보내기 시

#### getDataRetentionLimit
- **시그니처**: `(planType: PlanType) => number`
- **목적**: 데이터 조회 기간 제한 조회 (년 단위)
- **로직**: Free = 3년, Pro = 무제한(100년)
- **사용처**: Data Integration에서 startDate 계산 시

#### getPlanLimitValue
- **시그니처**: `(limits: DynamicPlanLimits, key: string) => any`
- **목적**: 동적 플랜 제한값 조회
- **로직**: limits.limits.get(key)
- **사용처**: 모든 제한 체크 시

---

### 4.2 Widget Logic

#### isChartWidget
- **시그니처**: `(type: WidgetType) => boolean`
- **목적**: 차트 위젯 여부 확인
- **로직**: type이 'time-series', 'bar-chart', 'pie-chart', 'treemap', 'scatter-chart', 'radar-chart', 'radial-bar-chart' 중 하나
- **사용처**: Widget 렌더링 분기 시

#### isTextWidget
- **시그니처**: `(type: WidgetType) => boolean`
- **목적**: 텍스트 위젯 여부 확인
- **로직**: type이 'text-custom', 'text-data' 중 하나
- **사용처**: Widget 렌더링 분기 시

#### validateWidgetType
- **시그니처**: `(type: string) => type is WidgetType`
- **목적**: WidgetType 타입 가드
- **로직**: WidgetTypeSchema.safeParse(type).success
- **사용처**: Widget 생성/수정 시

---

### 4.3 Data Integration Logic

#### standardizeData
- **시그니처**: `(source: 'KOSIS' | 'ECOS' | 'OECD' | 'CUSTOM', rawData: unknown) => StandardizedData`
- **목적**: 데이터 소스별 데이터를 표준 포맷으로 변환
- **로직**:
  - KOSIS: KOSIS API 응답 → StandardizedData
  - ECOS: ECOS API 응답 → StandardizedData
  - OECD: OECD API 응답 → StandardizedData
  - CUSTOM: Supabase CustomDataPoint[] → StandardizedData
- **사용처**: Data Integration Feature Module

#### parseDataPeriod
- **시그니처**: `(date: Date, period: DataPeriod) => string`
- **목적**: 날짜를 period에 맞게 포맷
- **로직**:
  - daily: YYYY-MM-DD
  - monthly: YYYY-MM
  - quarterly: YYYY-Q1/Q2/Q3/Q4
  - yearly: YYYY
- **사용처**: Data Integration, Chart 렌더링

---

### 4.4 Content Moderation Logic (US6.11)

#### detectRiskyPatterns
- **시그니처**: `(text: string, rules: DetectionRule[]) => { matched: boolean; matches: Array<{ ruleId: string; pattern: string; severity: string }> }`
- **목적**: 위험 패턴 자동 탐지
- **로직**:
  - 각 rule의 pattern(정규표현식)으로 text 스캔
  - 매칭된 pattern과 severity 반환
- **사용처**: Auto-detection Cron Job, 탐지 룰 테스트 API

#### calculateRiskScore
- **시그니처**: `(matches: Array<{ severity: string }>) => { score: number; level: 'low' | 'medium' | 'high' }`
- **목적**: 위험도 점수 계산
- **로직**:
  - High severity: +10점
  - Medium severity: +5점
  - Low severity: +2점
  - 20점 이상: high
  - 10-19점: medium
  - 9점 이하: low
- **사용처**: Auto-detection Cron Job

---

### 4.5 User Violation Logic (US6.10)

#### calculateSanction
- **시그니처**: `(violationCount: number, lastViolationDate: Date | null) => { action: 'warning' | 'restrict_48h' | 'permanent_ban'; duration: number | null }`
- **목적**: 누적 위반 횟수에 따른 제재 판단
- **로직**:
  - 1회: warning (duration: null)
  - 2회: restrict_48h (duration: 48시간)
  - 3회 이상: permanent_ban (duration: null)
- **사용처**: 신고 검토 조치, 자동 탐지 조치

#### isRecentViolation
- **시그니처**: `(lastViolationDate: Date, thresholdDays: number) => boolean`
- **목적**: 최근 위반 여부 확인
- **로직**: (현재 날짜 - lastViolationDate) <= thresholdDays
- **사용처**: 제재 강도 판단 시

---

## 5. Utility 함수 명세

### 5.1 Date Utilities

#### formatDate
- **시그니처**: `(date: Date | string, format?: 'short' | 'long' | 'iso') => string`
- **목적**: 날짜 포맷팅
- **로직**:
  - short: YYYY-MM-DD
  - long: YYYY년 MM월 DD일
  - iso: ISO 8601 (기본값)
- **사용처**: 모든 날짜 표시

#### formatDateRelative
- **시그니처**: `(date: Date | string) => string`
- **목적**: 상대 시간 표시 (몇 분 전, 몇 시간 전)
- **로직**:
  - 1분 미만: 방금 전
  - 1시간 미만: N분 전
  - 1일 미만: N시간 전
  - 1주일 미만: N일 전
  - 그 이상: YYYY-MM-DD
- **사용처**: ActivityLog, 댓글, 알림

#### parseDate
- **시그니처**: `(dateString: string) => Date`
- **목적**: 문자열을 Date 객체로 변환
- **로직**: new Date(dateString) with validation
- **사용처**: API 응답 파싱

---

### 5.2 Number Utilities

#### formatNumber
- **시그니처**: `(value: number, decimals?: number, locale?: string) => string`
- **목적**: 숫자 포맷팅 (천 단위 콤마)
- **로직**: Intl.NumberFormat 사용
- **사용처**: 모든 숫자 표시

#### formatCurrency
- **시그니처**: `(value: number, currency?: string, locale?: string) => string`
- **목적**: 통화 포맷팅
- **로직**: Intl.NumberFormat with currency style
- **사용처**: 가격, 금액 표시

#### formatPercent
- **시그니처**: `(value: number, decimals?: number) => string`
- **목적**: 백분율 포맷팅
- **로직**: (value * 100).toFixed(decimals) + '%'
- **사용처**: 증감률, 비율 표시

#### formatCompact
- **시그니처**: `(value: number) => string`
- **목적**: 큰 숫자 간략 표시 (1.2K, 3.4M, 5.6B)
- **로직**: Intl.NumberFormat with compact notation
- **사용처**: 대시보드 통계, 차트 레이블

---

### 5.3 String Utilities

#### slugify
- **시그니처**: `(text: string) => string`
- **목적**: URL 안전한 슬러그 생성
- **로직**: 소문자 변환, 공백을 하이픈으로, 특수문자 제거
- **사용처**: URL 생성, 파일명 생성

#### formatFileSize
- **시그니처**: `(bytes: number, decimals?: number) => string`
- **목적**: 파일 크기 포맷팅 (KB, MB, GB)
- **로직**: bytes를 적절한 단위로 변환
- **사용처**: 파일 업로드, 스토리지 사용량

#### truncate
- **시그니처**: `(text: string, maxLength: number, suffix?: string) => string`
- **목적**: 문자열 자르기
- **로직**: text.length > maxLength ? text.substring(0, maxLength) + suffix : text
- **사용처**: 긴 텍스트 미리보기

#### capitalize
- **시그니처**: `(text: string) => string`
- **목적**: 첫 글자 대문자 변환
- **로직**: text.charAt(0).toUpperCase() + text.slice(1).toLowerCase()
- **사용처**: 레이블, 타이틀

---

### 5.4 Array Utilities

#### chunk
- **시그니처**: `<T>(array: T[], size: number) => T[][]`
- **목적**: 배열을 지정된 크기로 분할
- **로직**: array를 size 단위로 분할하여 2차원 배열 반환
- **사용처**: 페이지네이션, 그리드 레이아웃

#### groupBy
- **시그니처**: `<T>(array: T[], key: keyof T) => Record<string, T[]>`
- **목적**: 배열을 키로 그룹화
- **로직**: array.reduce로 key별 그룹핑
- **사용처**: 데이터 그룹핑, 차트 데이터 변환

#### unique
- **시그니처**: `<T>(array: T[]) => T[]`
- **목적**: 배열 중복 제거
- **로직**: [...new Set(array)]
- **사용처**: 태그, 카테고리 필터

#### sortBy
- **시그니처**: `<T>(array: T[], key: keyof T, order?: 'asc' | 'desc') => T[]`
- **목적**: 배열 정렬
- **로직**: array.sort with key comparison
- **사용처**: 목록 정렬

---

### 5.5 Function Utilities

#### debounce
- **시그니처**: `<T extends (...args: any[]) => any>(fn: T, delay: number) => (...args: Parameters<T>) => void`
- **목적**: 함수 디바운싱 (마지막 호출만 실행)
- **로직**: setTimeout으로 delay 후 실행, 중간 호출은 취소
- **사용처**: 검색 입력, 자동 저장

#### throttle
- **시그니처**: `<T extends (...args: any[]) => any>(fn: T, delay: number) => (...args: Parameters<T>) => void`
- **목적**: 함수 스로틀링 (delay 간격으로 실행)
- **로직**: delay 간격으로만 함수 실행
- **사용처**: 스크롤 이벤트, 리사이즈 이벤트

#### memoize
- **시그니처**: `<T extends (...args: any[]) => any>(fn: T) => T`
- **목적**: 함수 결과 메모이제이션
- **로직**: 입력값을 키로 결과 캐싱
- **사용처**: 비용 높은 계산 함수

---

## 6. Constants 명세

### 6.1 API Endpoints (constants/api.ts)

#### API_ENDPOINTS
```
{
  // Dashboard
  DASHBOARD: '/api/dashboards',
  DASHBOARD_BY_ID: (id: string) => `/api/dashboards/${id}`,
  DASHBOARD_BOOKMARKED: '/api/dashboards/bookmarked',
  DASHBOARD_PUBLIC: '/api/dashboards/public',

  // Widget
  WIDGET: '/api/widgets',
  WIDGET_BY_ID: (id: string) => `/api/widgets/${id}`,
  WIDGET_PUBLIC: '/api/widgets/public',

  // Data
  INDICATOR: '/api/indicators',
  INDICATOR_BY_ID: (id: string) => `/api/indicators/${id}`,
  DATA_FETCH: '/api/data/fetch',
  DATA_BATCH: '/api/data/batch',

  // Auth
  AUTH_SIGNIN: (provider: string) => `/api/auth/signin/${provider}`,
  AUTH_SIGNOUT: '/api/auth/signout',
  AUTH_USER: '/api/auth/user',

  // Subscription
  SUBSCRIPTION: '/api/subscription',
  SUBSCRIPTION_LIMITS: '/api/subscription/limits',
  SUBSCRIPTION_USAGE: '/api/subscription/usage',

  // Admin
  ADMIN_INDICATORS: '/api/admin/indicators',
  ADMIN_USERS: '/api/admin/users',
  ADMIN_TEMPLATES: '/api/admin/templates',
  ADMIN_CATEGORIES: '/api/admin/categories',
  ADMIN_DATASOURCES: '/api/admin/datasources',
  ADMIN_PLAN_LIMITS: '/api/admin/plan-limits',

  // Moderation
  MODERATION_REPORTS: '/api/moderation/reports',
  MODERATION_VIOLATIONS: '/api/moderation/violations',
  MODERATION_DETECTION_RULES: '/api/moderation/detection-rules',
}
```

---

### 6.2 Routes (constants/routes.ts)

#### ROUTES
```
{
  // Public
  HOME: '/',
  ABOUT: '/about',

  // Auth
  SIGNIN: '/signin',
  SIGNUP: '/signup',

  // User Dashboard
  DASHBOARD: '/dashboard',
  DASHBOARD_VIEW: (id: string) => `/dashboard/${id}`,
  DASHBOARD_CREATE: '/dashboard/create',
  DASHBOARD_EDIT: (id: string) => `/dashboard/${id}/edit`,

  // User Widget
  WIDGET: '/widget',
  WIDGET_CREATE: '/widget/create',
  WIDGET_EDIT: (id: string) => `/widget/${id}/edit`,

  // User Profile
  PROFILE: '/profile',
  SUBSCRIPTION: '/subscription',

  // Admin
  ADMIN_DASHBOARD: '/admin',
  ADMIN_INDICATORS: '/admin/indicators',
  ADMIN_USERS: '/admin/users',
  ADMIN_TEMPLATES: '/admin/templates',
  ADMIN_CATEGORIES: '/admin/categories',
  ADMIN_DATASOURCES: '/admin/datasources',
  ADMIN_PLAN_LIMITS: '/admin/plan-limits',
  ADMIN_REPORTS: '/admin/moderation/reports',
  ADMIN_VIOLATIONS: '/admin/moderation/violations',
  ADMIN_DETECTION: '/admin/moderation/detection',
}
```

---

### 6.3 Storage Keys (constants/storage.ts)

#### STORAGE_KEYS
```
{
  // Auth
  ACCESS_TOKEN: 'e-torch:auth:access_token',
  REFRESH_TOKEN: 'e-torch:auth:refresh_token',
  USER: 'e-torch:auth:user',

  // Preferences
  THEME: 'e-torch:pref:theme',
  LANGUAGE: 'e-torch:pref:language',

  // Dashboard
  DASHBOARD_LAYOUT: (id: string) => `e-torch:dashboard:${id}:layout`,
  DASHBOARD_AUTOSAVE: (id: string) => `e-torch:dashboard:${id}:autosave`,

  // Widget
  WIDGET_CONFIG: (id: string) => `e-torch:widget:${id}:config`,
}
```

---

### 6.4 Limits (constants/limits.ts)

#### LIMITS
```
{
  // Text
  DASHBOARD_NAME_MAX_LENGTH: 100,
  DASHBOARD_DESCRIPTION_MAX_LENGTH: 500,
  WIDGET_NAME_MAX_LENGTH: 100,
  CATEGORY_NAME_MAX_LENGTH: 100,
  INDICATOR_NAME_MAX_LENGTH: 200,

  // Files
  CSV_FILE_MAX_SIZE: 10 * 1024 * 1024, // 10MB
  IMAGE_FILE_MAX_SIZE: 5 * 1024 * 1024, // 5MB

  // Pagination
  DEFAULT_PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 100,

  // API
  API_TIMEOUT: 30000, // 30초
  MAX_RETRY_COUNT: 3,

  // Data
  MAX_DATA_POINTS: 10000,
  MAX_INDICATORS_PER_WIDGET: 5,
}
```

---

### 6.5 Regex (constants/regex.ts)

#### REGEX
```
{
  EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  URL: /^https?:\/\/.+/,
  SLUG: /^[a-z0-9]+(?:-[a-z0-9]+)*$/,

  // Validation
  CATEGORY_CODE: /^[A-Z_]+$/,
  DATE_ISO: /^\d{4}-\d{2}-\d{2}$/,
  DATE_YEAR_MONTH: /^\d{4}-\d{2}$/,
  DATE_YEAR: /^\d{4}$/,

  // Content Moderation (US6.11)
  STOCK_NAME_KR: /삼성전자|현대차|SK하이닉스|카카오|네이버/,
  ACTION_INDUCEMENT: /지금 사세요|빨리 매수|놓치지 마세요|추천합니다/,
  FALSE_CLAIM: /100% 수익|무조건 상승|손실 없음|원금 보장/,
  TIMING_ASSERTION: /내일 급등|다음주 폭등|곧 상한가/,
  EXTERNAL_SERVICE: /텔레그램|telegram|카톡|오픈채팅/,
}
```

---

### 6.6 Error Messages (constants/errors.ts)

#### ERROR_MESSAGES
```
{
  // Auth
  AUTH_REQUIRED: '로그인이 필요합니다',
  SESSION_EXPIRED: '세션이 만료되었습니다',
  UNAUTHORIZED: '권한이 없습니다',

  // Subscription
  PLAN_LIMIT_EXCEEDED: '플랜 제한을 초과했습니다',
  DASHBOARD_LIMIT_EXCEEDED: '대시보드 생성 제한을 초과했습니다',
  WIDGET_LIMIT_EXCEEDED: '위젯 추가 제한을 초과했습니다',

  // Data
  DATA_NOT_FOUND: '데이터를 찾을 수 없습니다',
  INDICATOR_NOT_FOUND: '지표를 찾을 수 없습니다',
  DASHBOARD_NOT_FOUND: '대시보드를 찾을 수 없습니다',
  WIDGET_NOT_FOUND: '위젯을 찾을 수 없습니다',

  // Validation
  VALIDATION_ERROR: '입력값이 올바르지 않습니다',
  REQUIRED_FIELD: '필수 항목입니다',
  INVALID_EMAIL: '이메일 형식이 올바르지 않습니다',
  INVALID_URL: 'URL 형식이 올바르지 않습니다',

  // Network
  NETWORK_ERROR: '네트워크 오류가 발생했습니다',
  API_ERROR: 'API 요청 중 오류가 발생했습니다',
  TIMEOUT: '요청 시간이 초과되었습니다',

  // Server
  SERVER_ERROR: '서버 오류가 발생했습니다',
  INTERNAL_ERROR: '내부 오류가 발생했습니다',
}
```

---

## 7. File Structure

```
packages/core/
├── src/
│   ├── types/
│   │   ├── domain/
│   │   │   ├── user.ts           # User, Session, AuthContext
│   │   │   ├── dashboard.ts      # Dashboard, WidgetLayout, DashboardVersion
│   │   │   ├── widget.ts         # Widget, WidgetType, WidgetParameters
│   │   │   ├── data.ts           # Indicator, DataSource, StandardizedData
│   │   │   ├── subscription.ts   # Subscription, PlanType, UsageStats
│   │   │   ├── admin.ts          # DashboardTemplate, Category, ActivityLog
│   │   │   ├── moderation.ts     # ConsentLog, ViolationLog, DashboardReport
│   │   │   └── index.ts          # Re-export all domain types
│   │   ├── dto/
│   │   │   ├── dashboard.ts      # CreateDashboardDto, UpdateDashboardDto
│   │   │   ├── widget.ts         # CreateWidgetDto, UpdateWidgetDto
│   │   │   ├── user.ts           # UpdateProfileDto
│   │   │   ├── legal.ts          # ReportDashboardDto, LogConsentDto
│   │   │   ├── admin.ts          # Admin DTOs
│   │   │   └── index.ts          # Re-export all DTOs
│   │   ├── errors/
│   │   │   ├── codes.ts          # ErrorCode enum
│   │   │   ├── app-error.ts      # AppError type
│   │   │   └── index.ts          # Re-export
│   │   └── index.ts              # Re-export all types
│   ├── schemas/
│   │   ├── domain/
│   │   │   ├── user.ts           # UserSchema, SessionSchema
│   │   │   ├── dashboard.ts      # DashboardSchema, WidgetLayoutSchema
│   │   │   ├── widget.ts         # WidgetSchema, WidgetTypeSchema
│   │   │   ├── data.ts           # IndicatorSchema, DataSourceSchema
│   │   │   ├── subscription.ts   # SubscriptionSchema, PlanTypeSchema
│   │   │   ├── admin.ts          # DashboardTemplateSchema, CategorySchema
│   │   │   ├── moderation.ts     # ConsentLogSchema, ViolationLogSchema
│   │   │   └── index.ts          # Re-export
│   │   ├── dto/
│   │   │   ├── dashboard.ts      # CreateDashboardDtoSchema
│   │   │   ├── widget.ts         # CreateWidgetDtoSchema
│   │   │   ├── user.ts           # UpdateProfileDtoSchema
│   │   │   ├── legal.ts          # ReportDashboardDtoSchema
│   │   │   ├── admin.ts          # Admin DTO Schemas
│   │   │   └── index.ts          # Re-export
│   │   ├── errors/
│   │   │   ├── codes.ts          # ErrorCodeSchema
│   │   │   ├── app-error.ts      # AppErrorSchema
│   │   │   └── index.ts          # Re-export
│   │   └── index.ts              # Re-export all schemas
│   ├── business/
│   │   ├── subscription.ts       # Subscription logic functions
│   │   ├── widget.ts             # Widget logic functions
│   │   ├── data.ts               # Data Integration logic
│   │   ├── moderation.ts         # Content Moderation logic
│   │   ├── violation.ts          # User Violation logic
│   │   └── index.ts              # Re-export
│   ├── utils/
│   │   ├── date.ts               # formatDate, formatDateRelative
│   │   ├── number.ts             # formatNumber, formatCurrency
│   │   ├── string.ts             # slugify, formatFileSize
│   │   ├── array.ts              # chunk, groupBy
│   │   ├── function.ts           # debounce, throttle
│   │   └── index.ts              # Re-export
│   ├── constants/
│   │   ├── api.ts                # API_ENDPOINTS
│   │   ├── routes.ts             # ROUTES
│   │   ├── storage.ts            # STORAGE_KEYS
│   │   ├── limits.ts             # LIMITS
│   │   ├── regex.ts              # REGEX
│   │   ├── errors.ts             # ERROR_MESSAGES
│   │   └── index.ts              # Re-export
│   ├── errors/
│   │   ├── factory.ts            # createError function
│   │   └── index.ts              # Re-export
│   └── index.ts                  # Main entry point
├── package.json
├── tsconfig.json
└── README.md
```

**특징**:
- **types/와 schemas/ 분리**: 트리 쉐이킹 최적화
- **domain/dto/errors 분류**: 역할별 명확한 구분
- **Named exports**: 필요한 것만 import
- **index.ts re-export**: 편리한 import 경로

---

## 8. Export 전략

### 8.1 Main Entry Point (src/index.ts)

```typescript
// Domain Types
export * from './types/domain'
export * from './types/dto'
export * from './types/errors'

// Schemas (별도 export path)
// import { UserSchema } from '@e-torch/core/schemas'

// Business Logic
export * from './business'

// Utilities
export * from './utils'

// Constants
export * from './constants'

// Errors
export * from './errors'
```

### 8.2 Subpath Exports (package.json)

```json
{
  "exports": {
    ".": "./dist/index.js",
    "./types": "./dist/types/index.js",
    "./schemas": "./dist/schemas/index.js",
    "./business": "./dist/business/index.js",
    "./utils": "./dist/utils/index.js",
    "./constants": "./dist/constants/index.js"
  }
}
```

**사용 예시**:
```typescript
// 타입만 필요한 경우
import { Dashboard, Widget } from '@e-torch/core/types'

// Schema가 필요한 경우
import { DashboardSchema } from '@e-torch/core/schemas'

// 비즈니스 로직
import { canCreateDashboard } from '@e-torch/core/business'

// 유틸리티
import { formatDate, formatNumber } from '@e-torch/core/utils'

// 상수
import { API_ENDPOINTS, ROUTES } from '@e-torch/core/constants'
```

---

## 9. 의존성

### 9.1 외부 의존성

- **zod**: 런타임 데이터 검증

### 9.2 내부 의존성

- **없음** (최하위 레이어)

### 9.3 제공 대상

- **모든 Feature Module**: Dashboard, Widget Library, Data Integration, Authentication, Subscription, Admin Console, Admin Moderation
- **@e-torch/query**: API 요청/응답 타입
- **@e-torch/ui**: 공통 타입
- **apps/web**: 사용자 앱
- **apps/admin**: 관리자 앱

---

## 10. 타입 안정성 전략

### 10.1 TypeScript Interface (컴파일 타임)

- **목적**: 컴파일 타임 타입 체크
- **위치**: `packages/core/src/types/`
- **사용처**: 모든 TypeScript 코드
- **장점**: IDE 자동완성, 타입 오류 조기 발견

### 10.2 Zod Schema (런타임)

- **목적**: 런타임 데이터 검증
- **위치**: `packages/core/src/schemas/`
- **사용처**: API 요청/응답, 외부 데이터
- **장점**: 런타임 오류 방지, 타입 추론 지원

### 10.3 단일 진실 공급원 (Single Source of Truth)

- **진실 공급원**: `integration_contract.md`
- **구현 순서**:
  1. integration_contract.md에 타입 정의
  2. packages/core/src/types/에 TypeScript Interface 작성
  3. packages/core/src/schemas/에 Zod Schema 작성
  4. 타입 일치 확인

---

## 11. 버전 관리

### 11.1 Semantic Versioning

- **MAJOR**: 하위 호환성 깨지는 타입 인터페이스 변경
- **MINOR**: 하위 호환되는 기능 추가 (새 타입, 새 함수)
- **PATCH**: 버그 수정, 문서 업데이트

### 11.2 Breaking Changes 가이드

**MAJOR 버전 변경이 필요한 경우**:
- 타입 필드 삭제
- 타입 필드 이름 변경
- 함수 시그니처 변경
- ErrorCode enum 값 삭제

**MINOR 버전으로 가능한 경우**:
- 새 타입 추가
- 기존 타입에 optional 필드 추가
- 새 함수 추가
- 새 ErrorCode enum 값 추가

---

## 12. 테스트 전략

### 12.1 단위 테스트 (Vitest)

**테스트 대상**:
- 모든 Business Logic 함수
- 모든 Utility 함수
- Error Factory Function
- Zod Schema 검증

**테스트 파일 구조**:
```
packages/core/src/
  business/
    subscription.test.ts
    widget.test.ts
    data.test.ts
    moderation.test.ts
    violation.test.ts
  utils/
    date.test.ts
    number.test.ts
    string.test.ts
    array.test.ts
    function.test.ts
  schemas/
    domain/
      user.test.ts
      dashboard.test.ts
      widget.test.ts
      ...
```

### 12.2 스키마 검증 테스트

**목적**: Zod Schema가 TypeScript Interface와 일치하는지 확인

**테스트 예시**:
- UserSchema로 User 타입 객체 파싱 성공
- 잘못된 필드가 있으면 파싱 실패
- Optional 필드 누락 시 파싱 성공

### 12.3 순수 함수 테스트

**목적**: Business Logic과 Utility 함수의 순수성 확인

**테스트 예시**:
- 같은 입력 → 같은 출력
- Side Effect 없음
- 외부 의존성 없음

---

## 13. 다음 단계 (Implementation)

### 13.1 Package 초기화

1. **패키지 생성**: `packages/core/` 디렉토리 생성
2. **package.json 설정**: name, version, exports, dependencies
3. **tsconfig.json 설정**: strict mode, paths
4. **README.md 작성**: 사용법, API 문서

### 13.2 Types 구현

1. **Domain Types 작성**: 43개 TypeScript Interface 정의
2. **DTO Types 작성**: Create/Update/Report DTO 정의
3. **Error Types 작성**: ErrorCode enum, AppError interface

### 13.3 Schemas 구현

1. **Domain Schemas 작성**: 43개 Zod Schema 정의
2. **DTO Schemas 작성**: Create/Update/Report DTO Schema
3. **Error Schemas 작성**: ErrorCode Schema, AppError Schema
4. **타입 일치 확인**: Schema와 Interface 일치 테스트

### 13.4 Business Logic 구현

1. **Subscription Logic**: 5개 함수 구현
2. **Widget Logic**: 3개 함수 구현
3. **Data Integration Logic**: 2개 함수 구현
4. **Content Moderation Logic**: 2개 함수 구현
5. **User Violation Logic**: 2개 함수 구현

### 13.5 Utilities 구현

1. **Date Utilities**: 3개 함수 구현
2. **Number Utilities**: 4개 함수 구현
3. **String Utilities**: 4개 함수 구현
4. **Array Utilities**: 4개 함수 구현
5. **Function Utilities**: 3개 함수 구현

### 13.6 Constants 구현

1. **API Endpoints**: 모든 엔드포인트 정의
2. **Routes**: 모든 페이지 경로 정의
3. **Storage Keys**: 로컬 스토리지 키 정의
4. **Limits**: 제한값 정의
5. **Regex**: 정규식 정의
6. **Error Messages**: 에러 메시지 정의

### 13.7 Error Factory 구현

1. **createError 함수**: Error Factory 구현
2. **테스트**: 모든 ErrorCode에 대한 에러 생성 테스트

### 13.8 단위 테스트

1. **Business Logic 테스트**: 14개 함수 테스트
2. **Utilities 테스트**: 18개 함수 테스트
3. **Schema 테스트**: 43개 Schema 검증 테스트
4. **테스트 커버리지**: 90% 이상 목표

### 13.9 빌드 및 배포

1. **빌드 스크립트**: TypeScript 컴파일
2. **타입 선언 파일**: .d.ts 생성
3. **Turborepo 통합**: 다른 패키지와 연동
4. **npm publish**: (선택적) npm 레지스트리에 배포

---

## 14. 사용 예시

### 14.1 타입 사용

```typescript
// Feature Module에서
import { Dashboard, Widget, User } from '@e-torch/core/types'

function createDashboard(data: Dashboard): void {
  // 타입 안전한 코드
}
```

### 14.2 Schema 사용

```typescript
// API Route에서
import { CreateDashboardDtoSchema } from '@e-torch/core/schemas'

export async function POST(request: Request) {
  const body = await request.json()
  const data = CreateDashboardDtoSchema.parse(body) // 런타임 검증
  // ...
}
```

### 14.3 Business Logic 사용

```typescript
// Feature Module에서
import { canCreateDashboard } from '@e-torch/core/business'

const canCreate = canCreateDashboard(currentCount, limit)
if (!canCreate) {
  throw new Error('Cannot create dashboard')
}
```

### 14.4 Utility 사용

```typescript
// Component에서
import { formatDate, formatNumber } from '@e-torch/core/utils'

const formattedDate = formatDate(new Date(), 'short')
const formattedNumber = formatNumber(1234567.89, 2)
```

### 14.5 Constants 사용

```typescript
// API Client에서
import { API_ENDPOINTS } from '@e-torch/core/constants'

const url = API_ENDPOINTS.DASHBOARD_BY_ID('123')
```

### 14.6 Error 사용

```typescript
// Error Handling에서
import { createError } from '@e-torch/core/errors'
import { ERROR_MESSAGES } from '@e-torch/core/constants'

throw createError('AUTH_REQUIRED', ERROR_MESSAGES.AUTH_REQUIRED)
```

---

## 부록: 타입 카운트 확인

- **Domain Types**: 43개 (User, Dashboard, Widget, Indicator, Subscription, Admin, Moderation 등)
- **DTO Types**: 15개 (Create/Update/Report DTO)
- **Error Types**: 3개 (ErrorCode, AppError, createError)
- **Business Logic 함수**: 14개 (Subscription 5, Widget 3, Data 2, Moderation 2, Violation 2)
- **Utility 함수**: 18개 (Date 3, Number 4, String 4, Array 4, Function 3)
- **Constants**: 6개 카테고리 (API, Routes, Storage, Limits, Regex, ErrorMessages)

**총 93개 항목** (타입 61개 + 함수 32개)
