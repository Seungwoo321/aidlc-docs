# Admin Console BFF API 설계 문서

## 개요

**Feature Module**: Admin Console
**책임**: 시스템 운영 및 관리 (US6.1~6.8)
**아키텍처**: Next.js 15 App Router API Routes + Supabase + RLS
**설계 원칙**: Thin API Layer, RESTful API, TypeScript + Zod, Explicit Field Selection

## 승인된 아키텍처 결정사항

### 1. API Route 경로 구조
- **전략**: Resource 기반 Flat 구조
- **근거**: Next.js 15 App Router 공식 패턴, RESTful 의미론 일치, 서브 리소스 처리 간단

### 2. Supabase Client
- **전략**: Server Component Client (createServerClient)
- **근거**: RLS 활용, 쿠키 기반 세션 자동 처리, Next.js App Router 공식 패턴

### 3. Middleware 권한 검증
- **전략**: Hybrid (Next.js Middleware + Supabase RLS)
- **근거**: Defense in Depth, Middleware에서 인증 확인, RLS에서 관리자 권한 확인

### 4. API Response 에러 처리
- **전략**: TypeScript 타입 + Structured Response (Zod는 Request만 사용)
- **근거**: 업계 표준, 성능 우수, Request 검증만 Zod로 엄격히 처리

### 5. Supabase Query 최적화
- **전략**: Explicit Field Selection
- **근거**: 명시적 필드 선택, 네트워크 최적화, API별 필요 필드 다름

## API Response 표준 형식

### 성공 응답
```typescript
type ApiResponse<T> = {
  data: T | null
  error: {
    code: string
    message: string
    details?: Record<string, unknown>
  } | null
}
```

### 에러 코드 체계
- `INDICATOR_NOT_FOUND`: 지표를 찾을 수 없음
- `UNAUTHORIZED`: 인증되지 않은 요청
- `FORBIDDEN`: 권한 없음 (관리자 전용 API)
- `VALIDATION_ERROR`: 요청 데이터 검증 실패
- `DUPLICATE_ENTRY`: 중복된 데이터 (예: 이미 존재하는 카테고리 코드)
- `CONSTRAINT_VIOLATION`: 제약 조건 위반 (예: 사용 중인 카테고리 삭제 시도)
- `EXTERNAL_API_ERROR`: 외부 API 연결 실패 (데이터 소스 테스트)
- `FILE_UPLOAD_ERROR`: 파일 업로드 실패 (CSV)
- `INTERNAL_ERROR`: 서버 내부 오류

## 1. 지표 관리 API (US6.1, US6.2)

### 1.1 지표 목록 조회

**엔드포인트**: `GET /api/indicators`

**Query Parameters**:
- `categoryId` (string, optional): 카테고리 필터링
- `source` (string, optional): 데이터 소스 필터링 (KOSIS, ECOS, OECD, CUSTOM)
- `isActive` (boolean, optional): 활성화 상태 필터링
- `search` (string, optional): 검색어 (이름, 설명)
- `sortBy` (string, optional): 정렬 기준 (name, createdAt, usageCount) - 기본값: name
- `sortOrder` (string, optional): 정렬 순서 (asc, desc) - 기본값: asc
- `limit` (number, optional): 페이지 크기 - 기본값: 50
- `offset` (number, optional): 페이지 오프셋

**Supabase Query**:
- 테이블: `indicators`
- 필드: `id, name, description, source, category_id, unit, frequency, is_active, usage_count, created_at, updated_at`
- 필터: categoryId, source, isActive, search (name ILIKE, description ILIKE)
- 정렬: sortBy, sortOrder
- 페이지네이션: limit, offset

**Response**: `ApiResponse<ManagedIndicator[]>`

**RLS Policy**: admin_only (관리자만 조회 가능)

---

### 1.2 지표 상세 조회

**엔드포인트**: `GET /api/indicators/[id]`

**Path Parameters**:
- `id` (string): 지표 ID

**Supabase Query**:
- 테이블: `indicators`
- 필드: 모든 필드 (`*`)
- 필터: `id = :id`

**Response**: `ApiResponse<ManagedIndicator>`

**RLS Policy**: admin_only

---

### 1.3 지표 생성

**엔드포인트**: `POST /api/indicators`

**Request Body** (Zod 검증):
```typescript
CreateIndicatorSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().optional(),
  source: z.enum(['KOSIS', 'ECOS', 'OECD', 'CUSTOM']),
  categoryId: z.string().uuid().optional(),
  unit: z.string().optional(),
  frequency: z.enum(['daily', 'monthly', 'quarterly', 'yearly']).optional(),
  apiParams: z.record(z.unknown()).optional()
})
```

**Supabase Query**:
- 테이블: `indicators`
- 작업: INSERT
- 필드: 요청 데이터 + `created_by = auth.uid()`, `is_active = true`, `usage_count = 0`

**Response**: `ApiResponse<ManagedIndicator>`

**ActivityLog**: `action: 'create_indicator'`, `resourceType: 'indicator'`

**RLS Policy**: admin_only

---

### 1.4 지표 수정

**엔드포인트**: `PATCH /api/indicators/[id]`

**Path Parameters**:
- `id` (string): 지표 ID

**Request Body** (Zod 검증):
```typescript
UpdateIndicatorSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  description: z.string().optional(),
  categoryId: z.string().uuid().optional(),
  unit: z.string().optional(),
  frequency: z.enum(['daily', 'monthly', 'quarterly', 'yearly']).optional(),
  apiParams: z.record(z.unknown()).optional(),
  isActive: z.boolean().optional()
})
```

**Supabase Query**:
- 테이블: `indicators`
- 작업: UPDATE
- 필드: 요청 데이터 + `updated_by = auth.uid()`, `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<ManagedIndicator>`

**ActivityLog**: `action: 'update_indicator'`

**RLS Policy**: admin_only

---

### 1.5 지표 삭제

**엔드포인트**: `DELETE /api/indicators/[id]`

**Path Parameters**:
- `id` (string): 지표 ID

**비즈니스 로직**:
1. 위젯에서 사용 중인지 확인 (`widgets` 테이블에서 `parameters->indicatorId` 체크)
2. 사용 중이면 `CONSTRAINT_VIOLATION` 에러 반환
3. 사용 중이지 않으면 삭제

**Supabase Query**:
- 테이블: `indicators`
- 작업: DELETE
- 필터: `id = :id`

**Response**: `ApiResponse<{ success: true }>`

**ActivityLog**: `action: 'delete_indicator'`

**RLS Policy**: admin_only

---

### 1.6 지표 연결 테스트

**엔드포인트**: `POST /api/indicators/[id]/test`

**Path Parameters**:
- `id` (string): 지표 ID

**비즈니스 로직**:
1. 지표 조회 (source, apiParams)
2. source에 따라 외부 API 호출:
   - KOSIS: KOSIS API 호출
   - ECOS: ECOS API 호출
   - OECD: OECD API 호출
   - CUSTOM: Supabase `custom_data_points` 테이블 조회
3. 응답 시간, 상태 코드, 성공 여부 기록

**Supabase Query**:
- 테이블: `indicators`
- 작업: UPDATE
- 필드: `last_sync_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<TestResult>`

**RLS Policy**: admin_only

---

## 2. 사용자 관리 API (US6.2)

### 2.1 사용자 목록 조회

**엔드포인트**: `GET /api/users`

**Query Parameters**:
- `planType` (string, optional): free, pro
- `status` (string, optional): active, inactive
- `search` (string, optional): 검색어 (이메일, 이름)
- `sortBy` (string, optional): createdAt, lastLoginAt, email - 기본값: createdAt
- `sortOrder` (string, optional): asc, desc - 기본값: desc
- `limit` (number, optional): 기본값: 50
- `offset` (number, optional): 페이지 오프셋

**Supabase Query**:
- 테이블: `profiles` (Supabase Auth users와 조인)
- 필드: `id, email, name, plan_type, status, last_login_at, created_at`
- 서브쿼리: `dashboard_count` (dashboards 테이블에서 COUNT)
- 필터: planType, status, search
- 정렬: sortBy, sortOrder
- 페이지네이션: limit, offset

**Response**: `ApiResponse<AdminUserView[]>`

**RLS Policy**: admin_only

---

### 2.2 사용자 상세 조회

**엔드포인트**: `GET /api/users/[id]`

**Path Parameters**:
- `id` (string): 사용자 ID

**Supabase Query**:
- 테이블: `profiles`
- 필드: 모든 필드 + `dashboard_count`, `widget_count`
- 필터: `id = :id`

**Response**: `ApiResponse<AdminUserView>`

**RLS Policy**: admin_only

---

### 2.3 사용자 플랜 변경

**엔드포인트**: `PATCH /api/users/[id]/plan`

**Path Parameters**:
- `id` (string): 사용자 ID

**Request Body** (Zod 검증):
```typescript
UpdateUserSubscriptionSchema = z.object({
  planType: z.enum(['free', 'pro']),
  expiryDate: z.string().datetime().optional(),
  reason: z.string().min(1)
})
```

**Supabase Query**:
- 테이블: `subscriptions`
- 작업: UPDATE 또는 INSERT
- 필드: `user_id, plan_type, expiry_date, updated_at`

**Response**: `ApiResponse<Subscription>`

**ActivityLog**: `action: 'admin_update_subscription'`, `details: { userId, planType, reason }`

**RLS Policy**: admin_only

---

### 2.4 사용자 계정 정지

**엔드포인트**: `POST /api/users/[id]/suspend`

**Path Parameters**:
- `id` (string): 사용자 ID

**Request Body** (Zod 검증):
```typescript
SuspendUserSchema = z.object({
  reason: z.string().min(1)
})
```

**Supabase Query**:
- 테이블: `profiles`
- 작업: UPDATE
- 필드: `status = 'inactive'`, `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<User>`

**ActivityLog**: `action: 'suspend_user'`, `details: { reason }`

**RLS Policy**: admin_only

---

### 2.5 사용자 계정 활성화

**엔드포인트**: `POST /api/users/[id]/activate`

**Path Parameters**:
- `id` (string): 사용자 ID

**Request Body** (Zod 검증):
```typescript
ActivateUserSchema = z.object({
  reason: z.string().min(1)
})
```

**Supabase Query**:
- 테이블: `profiles`
- 작업: UPDATE
- 필드: `status = 'active'`, `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<User>`

**ActivityLog**: `action: 'activate_user'`, `details: { reason }`

**RLS Policy**: admin_only

---

### 2.6 사용자 활동 로그 조회

**엔드포인트**: `GET /api/users/[id]/activity`

**Path Parameters**:
- `id` (string): 사용자 ID

**Query Parameters**:
- `action` (string, optional): 활동 유형 필터링
- `dateFrom` (string, optional): 시작 날짜
- `dateTo` (string, optional): 종료 날짜
- `limit` (number, optional): 기본값: 100

**Supabase Query**:
- 테이블: `activity_logs`
- 필드: `id, user_id, action, resource_type, resource_id, details, created_at`
- 필터: `user_id = :id`, action, dateFrom, dateTo
- 정렬: `created_at DESC`
- 제한: limit

**Response**: `ApiResponse<ActivityLog[]>`

**RLS Policy**: admin_only

---

## 3. 데이터 소스 관리 API (US6.3)

### 3.1 데이터 소스 목록 조회

**엔드포인트**: `GET /api/data-sources`

**Query Parameters**:
- `isActive` (boolean, optional): 활성화 상태 필터링

**Supabase Query**:
- 테이블: `data_sources`
- 필드: `id, name, description, is_active, created_at, updated_at`
- 필터: isActive
- 정렬: `name ASC`

**Response**: `ApiResponse<DataSource[]>`

**RLS Policy**: admin_only

---

### 3.2 데이터 소스 상세 조회

**엔드포인트**: `GET /api/data-sources/[id]`

**Path Parameters**:
- `id` (string): 데이터 소스 ID

**Supabase Query**:
- 테이블: `data_sources`
- 필드: 모든 필드 (단, `api_key`는 마스킹 처리)
- 필터: `id = :id`

**Response**: `ApiResponse<DataSource>` (api_key는 `***` 형태로 마스킹)

**RLS Policy**: admin_only

---

### 3.3 데이터 소스 생성

**엔드포인트**: `POST /api/data-sources`

**Request Body** (Zod 검증):
```typescript
CreateDataSourceSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string(),
  apiKey: z.string().optional()
})
```

**Supabase Query**:
- 테이블: `data_sources`
- 작업: INSERT
- 필드: 요청 데이터 + `is_active = true`, `created_by = auth.uid()`
- **보안**: `api_key`는 Supabase `vault` 테이블에 암호화 저장

**Response**: `ApiResponse<DataSource>`

**ActivityLog**: `action: 'create_data_source'`

**RLS Policy**: admin_only

---

### 3.4 데이터 소스 수정

**엔드포인트**: `PATCH /api/data-sources/[id]`

**Path Parameters**:
- `id` (string): 데이터 소스 ID

**Request Body** (Zod 검증):
```typescript
UpdateDataSourceSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  description: z.string().optional()
})
```

**Supabase Query**:
- 테이블: `data_sources`
- 작업: UPDATE
- 필드: 요청 데이터 + `updated_by = auth.uid()`, `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<DataSource>`

**ActivityLog**: `action: 'update_data_source'`

**RLS Policy**: admin_only

---

### 3.5 데이터 소스 API Key 수정

**엔드포인트**: `PATCH /api/data-sources/[id]/api-key`

**Path Parameters**:
- `id` (string): 데이터 소스 ID

**Request Body** (Zod 검증):
```typescript
UpdateAPIKeySchema = z.object({
  apiKey: z.string().min(1)
})
```

**Supabase Query**:
- 테이블: `data_sources`
- 작업: UPDATE
- **보안**: `api_key`를 Supabase `vault`에 암호화 저장
- 필터: `id = :id`

**Response**: `ApiResponse<{ success: true }>`

**ActivityLog**: `action: 'update_api_key'`, `details: { maskedKey: '***' }`

**RLS Policy**: admin_only

---

### 3.6 데이터 소스 상태 변경

**엔드포인트**: `PATCH /api/data-sources/[id]/status`

**Path Parameters**:
- `id` (string): 데이터 소스 ID

**Request Body** (Zod 검증):
```typescript
ToggleStatusSchema = z.object({
  isActive: z.boolean()
})
```

**Supabase Query**:
- 테이블: `data_sources`
- 작업: UPDATE
- 필드: `is_active = :isActive`, `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<DataSource>`

**ActivityLog**: `action: 'toggle_data_source_status'`

**RLS Policy**: admin_only

---

### 3.7 데이터 소스 연결 테스트

**엔드포인트**: `POST /api/data-sources/[id]/test`

**Path Parameters**:
- `id` (string): 데이터 소스 ID

**비즈니스 로직**:
1. 데이터 소스 조회 (name, api_key)
2. 외부 API 테스트 호출
3. 응답 시간, 상태 코드, 성공 여부 반환

**Response**: `ApiResponse<TestResult>`

**RLS Policy**: admin_only

---

### 3.8 데이터 소스 삭제

**엔드포인트**: `DELETE /api/data-sources/[id]`

**Path Parameters**:
- `id` (string): 데이터 소스 ID

**비즈니스 로직**:
1. 지표에서 사용 중인지 확인 (`indicators` 테이블에서 `source` 체크)
2. 사용 중이면 `CONSTRAINT_VIOLATION` 에러 반환
3. 사용 중이지 않으면 삭제

**Supabase Query**:
- 테이블: `data_sources`
- 작업: DELETE
- 필터: `id = :id`

**Response**: `ApiResponse<{ success: true }>`

**ActivityLog**: `action: 'delete_data_source'`

**RLS Policy**: admin_only

---

## 4. 플랜 제한 관리 API (US6.4)

### 4.1 플랜 제한 목록 조회

**엔드포인트**: `GET /api/plan-limits`

**Query Parameters**:
- `planType` (string, optional): free, pro

**Supabase Query**:
- 테이블: `plan_limit_configs`
- 필드: `id, plan_type, limit_key, limit_value, description, unit, is_active, effective_date, expiry_date, updated_at`
- 필터: planType, `is_active = true`
- 정렬: `plan_type ASC, limit_key ASC`

**Response**: `ApiResponse<PlanLimitConfig[]>`

**RLS Policy**: admin_only

---

### 4.2 플랜 제한 상세 조회

**엔드포인트**: `GET /api/plan-limits/[id]`

**Path Parameters**:
- `id` (string): 플랜 제한 ID

**Supabase Query**:
- 테이블: `plan_limit_configs`
- 필드: 모든 필드
- 필터: `id = :id`

**Response**: `ApiResponse<PlanLimitConfig>`

**RLS Policy**: admin_only

---

### 4.3 플랜 제한 수정

**엔드포인트**: `PATCH /api/plan-limits/[id]`

**Path Parameters**:
- `id` (string): 플랜 제한 ID

**Request Body** (Zod 검증):
```typescript
UpdatePlanLimitSchema = z.object({
  limitValue: z.union([z.number(), z.boolean(), z.string()]),
  description: z.string().optional(),
  effectiveDate: z.string().datetime().optional(),
  expiryDate: z.string().datetime().optional(),
  reason: z.string().min(1)
})
```

**비즈니스 로직**:
1. 기존 값 조회
2. 변경 이력 기록 (`plan_limit_history` 테이블)
3. 새 값으로 업데이트

**Supabase Query**:
- 테이블: `plan_limit_configs`
- 작업: UPDATE
- 필드: 요청 데이터 + `updated_by = auth.uid()`, `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<PlanLimitConfig>`

**ActivityLog**: `action: 'update_plan_limit'`, `details: { limitKey, oldValue, newValue, reason }`

**RLS Policy**: admin_only

---

### 4.4 플랜 제한 추가

**엔드포인트**: `POST /api/plan-limits`

**Request Body** (Zod 검증):
```typescript
CreatePlanLimitSchema = z.object({
  planType: z.enum(['free', 'pro']),
  limitKey: z.string().min(1),
  limitValue: z.union([z.number(), z.boolean(), z.string()]),
  description: z.string(),
  unit: z.string().optional()
})
```

**Supabase Query**:
- 테이블: `plan_limit_configs`
- 작업: INSERT
- 필드: 요청 데이터 + `is_active = true`, `updated_by = auth.uid()`

**Response**: `ApiResponse<PlanLimitConfig>`

**ActivityLog**: `action: 'create_plan_limit'`

**RLS Policy**: admin_only

---

### 4.5 플랜 제한 삭제

**엔드포인트**: `DELETE /api/plan-limits/[id]`

**Path Parameters**:
- `id` (string): 플랜 제한 ID

**Supabase Query**:
- 테이블: `plan_limit_configs`
- 작업: UPDATE (soft delete)
- 필드: `is_active = false`, `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<{ success: true }>`

**ActivityLog**: `action: 'delete_plan_limit'`

**RLS Policy**: admin_only

---

### 4.6 플랜 제한 변경 이력 조회

**엔드포인트**: `GET /api/plan-limits/history`

**Query Parameters**:
- `limitKey` (string): 제한 키
- `planType` (string, optional): free, pro
- `limit` (number, optional): 기본값: 50

**Supabase Query**:
- 테이블: `plan_limit_history`
- 필드: `id, limit_key, plan_type, old_value, new_value, changed_by, changed_at, reason`
- 필터: limitKey, planType
- 정렬: `changed_at DESC`
- 제한: limit

**Response**: `ApiResponse<PlanLimitHistory[]>`

**RLS Policy**: admin_only

---

## 5. 템플릿 관리 API (US6.5)

### 5.1 템플릿 목록 조회

**엔드포인트**: `GET /api/templates`

**Query Parameters**:
- `categoryCode` (string, optional): 카테고리 필터링
- `isPro` (boolean, optional): Pro 전용 템플릿 필터링
- `isActive` (boolean, optional): 활성화 상태 필터링

**Supabase Query**:
- 테이블: `dashboard_templates`
- 필드: `id, name, description, category_code, thumbnail, is_active, is_pro, created_at, updated_at`
- 서브쿼리: `widget_count` (template_widgets 테이블에서 COUNT)
- 필터: categoryCode, isPro, isActive
- 정렬: `created_at DESC`

**Response**: `ApiResponse<DashboardTemplate[]>`

**RLS Policy**: admin_only

---

### 5.2 템플릿 상세 조회

**엔드포인트**: `GET /api/templates/[id]`

**Path Parameters**:
- `id` (string): 템플릿 ID

**Supabase Query**:
- 테이블: `dashboard_templates`
- 필드: 모든 필드
- 조인: `template_widgets` (템플릿에 포함된 위젯 정보)
- 필터: `id = :id`

**Response**: `ApiResponse<DashboardTemplate>`

**RLS Policy**: admin_only

---

### 5.3 템플릿 생성

**엔드포인트**: `POST /api/templates`

**Request Body** (Zod 검증):
```typescript
CreateTemplateSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string(),
  categoryCode: z.string().optional(),
  thumbnail: z.string().url().optional(),
  isPro: z.boolean().default(false),
  widgets: z.array(z.object({
    widgetType: z.enum(['time-series', 'bar-chart', 'pie-chart', /* ... */]),
    name: z.string(),
    parameters: z.record(z.unknown()),
    layout: z.object({
      x: z.number(),
      y: z.number(),
      width: z.number(),
      height: z.number(),
      order: z.number()
    })
  }))
})
```

**Supabase Query**:
1. 테이블: `dashboard_templates` INSERT
2. 테이블: `template_widgets` BATCH INSERT (각 위젯)

**Response**: `ApiResponse<DashboardTemplate>`

**ActivityLog**: `action: 'create_template'`

**RLS Policy**: admin_only

---

### 5.4 템플릿 수정

**엔드포인트**: `PATCH /api/templates/[id]`

**Path Parameters**:
- `id` (string): 템플릿 ID

**Request Body** (Zod 검증):
```typescript
UpdateTemplateSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  description: z.string().optional(),
  categoryCode: z.string().optional(),
  thumbnail: z.string().url().optional(),
  isPro: z.boolean().optional(),
  isActive: z.boolean().optional(),
  widgets: z.array(/* TemplateWidget */).optional()
})
```

**비즈니스 로직**:
1. 템플릿 기본 정보 업데이트
2. widgets가 제공되면 기존 위젯 삭제 후 새 위젯 삽입

**Supabase Query**:
1. 테이블: `dashboard_templates` UPDATE
2. (widgets 제공 시) 테이블: `template_widgets` DELETE + INSERT

**Response**: `ApiResponse<DashboardTemplate>`

**ActivityLog**: `action: 'update_template'`

**RLS Policy**: admin_only

---

### 5.5 템플릿 삭제

**엔드포인트**: `DELETE /api/templates/[id]`

**Path Parameters**:
- `id` (string): 템플릿 ID

**Supabase Query**:
- 테이블: `dashboard_templates`
- 작업: UPDATE (soft delete)
- 필드: `is_active = false`, `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<{ success: true }>`

**ActivityLog**: `action: 'delete_template'`

**RLS Policy**: admin_only

---

### 5.6 템플릿 복제

**엔드포인트**: `POST /api/templates/[id]/clone`

**Path Parameters**:
- `id` (string): 원본 템플릿 ID

**Request Body** (Zod 검증):
```typescript
CloneTemplateSchema = z.object({
  name: z.string().min(1).max(100)
})
```

**비즈니스 로직**:
1. 원본 템플릿 조회 (위젯 포함)
2. 새 템플릿 생성 (이름만 변경)
3. 위젯도 복제

**Supabase Query**:
1. 테이블: `dashboard_templates` INSERT (원본 데이터 복사)
2. 테이블: `template_widgets` BATCH INSERT (원본 위젯 복사)

**Response**: `ApiResponse<DashboardTemplate>`

**ActivityLog**: `action: 'clone_template'`, `details: { sourceTemplateId }`

**RLS Policy**: admin_only

---

## 6. 카테고리 관리 API (US6.6)

### 6.1 카테고리 목록 조회

**엔드포인트**: `GET /api/categories`

**Query Parameters**:
- `isActive` (boolean, optional): 활성화 상태 필터링

**Supabase Query**:
- 테이블: `categories`
- 필드: `id, code, name, description, order, is_active, usage_count, created_at, updated_at`
- 필터: isActive
- 정렬: `order ASC`

**Response**: `ApiResponse<Category[]>`

**RLS Policy**: admin_only

---

### 6.2 카테고리 생성

**엔드포인트**: `POST /api/categories`

**Request Body** (Zod 검증):
```typescript
CreateCategorySchema = z.object({
  code: z.string().min(1).max(50).regex(/^[A-Z_]+$/),
  name: z.string().min(1).max(100),
  description: z.string().optional()
})
```

**비즈니스 로직**:
1. code 중복 체크
2. 중복 시 `DUPLICATE_ENTRY` 에러 반환
3. order는 현재 최대값 + 1로 자동 설정

**Supabase Query**:
- 테이블: `categories`
- 작업: INSERT
- 필드: 요청 데이터 + `is_active = true`, `usage_count = 0`, `order = (MAX(order) + 1)`

**Response**: `ApiResponse<Category>`

**ActivityLog**: `action: 'create_category'`

**RLS Policy**: admin_only

---

### 6.3 카테고리 수정

**엔드포인트**: `PATCH /api/categories/[id]`

**Path Parameters**:
- `id` (string): 카테고리 ID

**Request Body** (Zod 검증):
```typescript
UpdateCategorySchema = z.object({
  name: z.string().min(1).max(100).optional(),
  description: z.string().optional()
})
```

**Supabase Query**:
- 테이블: `categories`
- 작업: UPDATE
- 필드: 요청 데이터 + `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<Category>`

**ActivityLog**: `action: 'update_category'`

**RLS Policy**: admin_only

---

### 6.4 카테고리 삭제

**엔드포인트**: `DELETE /api/categories/[id]`

**Path Parameters**:
- `id` (string): 카테고리 ID

**비즈니스 로직**:
1. 사용 중인 지표/템플릿이 있는지 확인 (`usage_count > 0`)
2. 사용 중이면 `CONSTRAINT_VIOLATION` 에러 반환
3. 사용 중이지 않으면 삭제

**Supabase Query**:
- 테이블: `categories`
- 작업: DELETE
- 필터: `id = :id`

**Response**: `ApiResponse<{ success: true }>`

**ActivityLog**: `action: 'delete_category'`

**RLS Policy**: admin_only

---

### 6.5 카테고리 순서 변경

**엔드포인트**: `POST /api/categories/reorder`

**Request Body** (Zod 검증):
```typescript
ReorderCategoriesSchema = z.object({
  categoryIds: z.array(z.string().uuid())
})
```

**비즈니스 로직**:
1. categoryIds 배열 순서대로 order 값 재설정 (0, 1, 2, ...)

**Supabase Query**:
- 테이블: `categories`
- 작업: BATCH UPDATE
- 필드: `order = :newOrder`, `updated_at = NOW()`
- 각 카테고리에 대해 순차적으로 실행

**Response**: `ApiResponse<{ success: true }>`

**ActivityLog**: `action: 'reorder_categories'`

**RLS Policy**: admin_only

---

### 6.6 카테고리 상태 변경

**엔드포인트**: `PATCH /api/categories/[id]/status`

**Path Parameters**:
- `id` (string): 카테고리 ID

**Request Body** (Zod 검증):
```typescript
ToggleCategoryStatusSchema = z.object({
  isActive: z.boolean()
})
```

**Supabase Query**:
- 테이블: `categories`
- 작업: UPDATE
- 필드: `is_active = :isActive`, `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<Category>`

**ActivityLog**: `action: 'toggle_category_status'`

**RLS Policy**: admin_only

---

## 7. 커스텀 데이터 관리 API (US6.7)

### 7.1 커스텀 데이터 업로드 (CSV)

**엔드포인트**: `POST /api/custom-data/validate`

**Request Body** (multipart/form-data):
- `file` (File): CSV 파일
- `indicatorId` (string): 지표 ID

**비즈니스 로직** (csvValidation.ts 서비스 사용):
1. CSV 파일 파싱 (date, value 컬럼 필수)
2. 날짜 형식 검증 (YYYY-MM-DD)
3. 값 검증 (숫자)
4. 중복 날짜 체크
5. 미리보기 데이터 반환 (최대 10행)

**Response**: `ApiResponse<CustomDataImportResult>`
- `success`: 검증 성공 여부
- `totalRows`: 전체 행 수
- `importedRows`: 유효한 행 수
- `errors`: 에러 목록 (행 번호, 메시지)
- `preview`: 미리보기 데이터 (최대 10행)

**주의**: 이 API는 검증만 수행하고 실제 저장은 하지 않음. 프론트엔드에서 확인 후 7.2 API로 저장.

**RLS Policy**: admin_only

---

### 7.2 커스텀 데이터 저장

**엔드포인트**: `POST /api/custom-data/[indicatorId]`

**Path Parameters**:
- `indicatorId` (string): 지표 ID

**Request Body** (Zod 검증):
```typescript
SaveCustomDataSchema = z.object({
  dataPoints: z.array(z.object({
    date: z.string().datetime(),
    value: z.number(),
    metadata: z.record(z.unknown()).optional()
  }))
})
```

**Supabase Query**:
- 테이블: `custom_data_points`
- 작업: BATCH INSERT (ON CONFLICT UPDATE)
- 필드: `indicator_id, date, value, metadata, created_by = auth.uid()`

**Response**: `ApiResponse<{ success: true, count: number }>`

**ActivityLog**: `action: 'upload_custom_data'`, `details: { indicatorId, count }`

**RLS Policy**: admin_only

---

### 7.3 커스텀 데이터 목록 조회

**엔드포인트**: `GET /api/custom-data/[indicatorId]`

**Path Parameters**:
- `indicatorId` (string): 지표 ID

**Query Parameters**:
- `startDate` (string, optional): 시작 날짜
- `endDate` (string, optional): 종료 날짜
- `limit` (number, optional): 기본값: 1000

**Supabase Query**:
- 테이블: `custom_data_points`
- 필드: `id, indicator_id, date, value, metadata, created_by, created_at, updated_at`
- 필터: `indicator_id = :indicatorId`, startDate, endDate
- 정렬: `date DESC`
- 제한: limit

**Response**: `ApiResponse<CustomDataPoint[]>`

**RLS Policy**: admin_only

---

### 7.4 커스텀 데이터 수정

**엔드포인트**: `PATCH /api/custom-data/[id]`

**Path Parameters**:
- `id` (string): 데이터 포인트 ID

**Request Body** (Zod 검증):
```typescript
UpdateCustomDataPointSchema = z.object({
  value: z.number(),
  metadata: z.record(z.unknown()).optional()
})
```

**비즈니스 로직**:
1. 기존 값 조회
2. 변경 이력 기록 (`custom_data_history` 테이블)
3. 새 값으로 업데이트

**Supabase Query**:
- 테이블: `custom_data_points`
- 작업: UPDATE
- 필드: 요청 데이터 + `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<CustomDataPoint>`

**ActivityLog**: `action: 'update_custom_data'`, `details: { dataPointId, oldValue, newValue }`

**RLS Policy**: admin_only

---

### 7.5 커스텀 데이터 삭제

**엔드포인트**: `DELETE /api/custom-data/[id]`

**Path Parameters**:
- `id` (string): 데이터 포인트 ID

**비즈니스 로직**:
1. 삭제 전 데이터 조회
2. 변경 이력 기록 (`custom_data_history` 테이블)
3. 삭제

**Supabase Query**:
- 테이블: `custom_data_points`
- 작업: DELETE
- 필터: `id = :id`

**Response**: `ApiResponse<{ success: true }>`

**ActivityLog**: `action: 'delete_custom_data'`, `details: { dataPointId }`

**RLS Policy**: admin_only

---

### 7.6 커스텀 데이터 변경 이력 조회

**엔드포인트**: `GET /api/custom-data/[indicatorId]/history`

**Path Parameters**:
- `indicatorId` (string): 지표 ID

**Query Parameters**:
- `limit` (number, optional): 기본값: 100

**Supabase Query**:
- 테이블: `custom_data_history`
- 필드: `id, indicator_id, data_point_id, action, old_value, new_value, changed_by, changed_at`
- 필터: `indicator_id = :indicatorId`
- 정렬: `changed_at DESC`
- 제한: limit

**Response**: `ApiResponse<CustomDataHistory[]>`

**RLS Policy**: admin_only

---

## 8. 활동 로그 조회 API (US6.8)

### 8.1 활동 로그 목록 조회

**엔드포인트**: `GET /api/activity-logs`

**Query Parameters**:
- `userId` (string, optional): 사용자 필터링
- `action` (string, optional): 활동 유형 필터링
- `resourceType` (string, optional): 리소스 유형 필터링
- `dateFrom` (string, optional): 시작 날짜
- `dateTo` (string, optional): 종료 날짜
- `limit` (number, optional): 기본값: 100
- `offset` (number, optional): 페이지 오프셋

**Supabase Query**:
- 테이블: `activity_logs`
- 필드: `id, user_id, action, resource_type, resource_id, details, ip_address, created_at`
- 조인: `profiles` (사용자 이름, 이메일)
- 필터: userId, action, resourceType, dateFrom, dateTo
- 정렬: `created_at DESC`
- 페이지네이션: limit, offset

**Response**: `ApiResponse<ActivityLog[]>`

**RLS Policy**: admin_only

---

## 9. 모니터링 API

### 9.1 시스템 메트릭 조회

**엔드포인트**: `GET /api/metrics`

**Supabase Query** (여러 집계 쿼리):
1. `profiles` 테이블: `COUNT(*)` (totalUsers), `COUNT(*) WHERE last_login_at > NOW() - INTERVAL '30 days'` (activeUsers)
2. `dashboards` 테이블: `COUNT(*)` (totalDashboards)
3. `widgets` 테이블: `COUNT(*)` (totalWidgets)
4. `activity_logs` 테이블: `COUNT(*) WHERE created_at > NOW() - INTERVAL '1 day'` (apiCallsToday)

**Response**: `ApiResponse<SystemMetrics>`

**RLS Policy**: admin_only

---

### 9.2 대시보드 통계 조회

**엔드포인트**: `GET /api/dashboard-stats`

**Supabase Query** (여러 집계 쿼리):
1. `dashboards` 테이블: `COUNT(*) WHERE is_public = true` (totalPublic), `COUNT(*) WHERE is_public = false` (totalPrivate)
2. `widget_layouts` 테이블: `AVG(widget_count) GROUP BY dashboard_id` (avgWidgetsPerDashboard)
3. `dashboards` 테이블: `COUNT(*) GROUP BY category_code` (mostUsedCategories)
4. `indicators` 테이블: `COUNT(*) FROM widgets GROUP BY indicator_id` (mostUsedIndicators)

**Response**: `ApiResponse<DashboardStats>`

**RLS Policy**: admin_only

---

## 10. Middleware 설계

### 10.1 인증 Middleware

**파일**: `apps/admin/middleware.ts`

**책임**:
1. `/api/*` 경로의 모든 요청에 대해 인증 확인
2. Supabase 세션 확인 (쿠키 기반)
3. 인증되지 않은 요청은 401 Unauthorized 반환

**로직**:
```
1. request.nextUrl.pathname이 /api/로 시작하는지 확인
2. Supabase createServerClient 생성
3. supabase.auth.getSession() 호출
4. session이 없으면 401 반환
5. session이 있으면 NextResponse.next()
```

**Edge Runtime**: 지원

---

### 10.2 RLS Policy (Supabase)

**책임**:
1. DB 레벨에서 관리자 권한 확인
2. `profiles.role = 'admin'` 체크

**Policy 예시**:
```sql
-- indicators 테이블
CREATE POLICY admin_only ON indicators
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 모든 관리자 테이블에 동일한 Policy 적용
-- users, data_sources, plan_limit_configs, categories, templates, custom_data_points, activity_logs
```

---

## 11. Supabase 테이블 설계 (개요)

### 11.1 필요한 테이블 목록

1. **indicators**: 지표 정보
2. **data_sources**: 데이터 소스 정보
3. **plan_limit_configs**: 플랜 제한 설정
4. **plan_limit_history**: 플랜 제한 변경 이력
5. **dashboard_templates**: 대시보드 템플릿
6. **template_widgets**: 템플릿 위젯
7. **categories**: 카테고리
8. **custom_data_points**: 커스텀 데이터 포인트
9. **custom_data_history**: 커스텀 데이터 변경 이력
10. **activity_logs**: 활동 로그
11. **profiles**: 사용자 프로필 (Supabase Auth와 연동)
12. **subscriptions**: 구독 정보

### 11.2 인덱스 전략

**성능 최적화를 위한 인덱스**:
1. `indicators`: `(source, is_active)`, `(category_id)`, `(name)` (FULLTEXT)
2. `plan_limit_configs`: `(plan_type, is_active)`
3. `categories`: `(order)`, `(is_active)`
4. `custom_data_points`: `(indicator_id, date)`
5. `activity_logs`: `(user_id, created_at)`, `(action)`, `(resource_type)`
6. `profiles`: `(role)`, `(status)`

---

## 12. File Structure

```
apps/admin/
  app/
    api/
      indicators/
        route.ts                    # GET, POST
        [id]/
          route.ts                  # GET, PATCH, DELETE
          test/
            route.ts                # POST
      users/
        route.ts                    # GET
        [id]/
          route.ts                  # GET
          plan/
            route.ts                # PATCH
          suspend/
            route.ts                # POST
          activate/
            route.ts                # POST
          activity/
            route.ts                # GET
      data-sources/
        route.ts                    # GET, POST
        [id]/
          route.ts                  # GET, PATCH, DELETE
          api-key/
            route.ts                # PATCH
          status/
            route.ts                # PATCH
          test/
            route.ts                # POST
      plan-limits/
        route.ts                    # GET, POST
        [id]/
          route.ts                  # GET, PATCH, DELETE
        history/
          route.ts                  # GET
      templates/
        route.ts                    # GET, POST
        [id]/
          route.ts                  # GET, PATCH, DELETE
          clone/
            route.ts                # POST
      categories/
        route.ts                    # GET, POST
        [id]/
          route.ts                  # GET, PATCH, DELETE
          status/
            route.ts                # PATCH
        reorder/
          route.ts                  # POST
      custom-data/
        validate/
          route.ts                  # POST
        [indicatorId]/
          route.ts                  # GET, POST
          history/
            route.ts                # GET
        [id]/
          route.ts                  # PATCH, DELETE
      activity-logs/
        route.ts                    # GET
      metrics/
        route.ts                    # GET
      dashboard-stats/
        route.ts                    # GET
    middleware.ts                   # 인증 Middleware
  lib/
    supabase/
      server.ts                     # createServerClient
      types.ts                      # Supabase 타입 정의
    api/
      responses.ts                  # ApiResponse 헬퍼
      errors.ts                     # 에러 처리 유틸리티
    services/
      csvValidation.ts              # CSV 검증 로직
      indicatorValidation.ts        # 지표 파라미터 검증 로직
      activityLogger.ts             # ActivityLog 기록 유틸리티

packages/admin-console/
  (Feature Module - React Components, TanStack Query Hooks)
```

---

## 13. 다음 단계 (Implementation)

### 13.1 Supabase Schema 구현

1. 테이블 생성 (migration SQL)
2. RLS Policy 적용
3. 인덱스 생성
4. Trigger 생성 (ActivityLog 자동 기록)
5. Vault 설정 (API Key 암호화)

### 13.2 API Routes 구현

1. middleware.ts 구현
2. lib/supabase/server.ts 구현
3. lib/api/responses.ts, errors.ts 유틸리티 구현
4. 각 route.ts 파일 구현
5. Zod Schema 정의
6. 통합 테스트

### 13.3 Feature Module 통합

1. packages/admin-console의 TanStack Query Hooks가 BFF API 호출
2. Query Key 구조 일치 확인
3. 에러 처리 통합
4. Loading/Success/Error 상태 관리

### 13.4 배포

1. Vercel Multi-Zone 설정
2. 환경 변수 설정 (Supabase URL, Keys)
3. Middleware Edge Runtime 확인
4. 성능 모니터링 설정

---

## 14. 보안 고려사항

### 14.1 API Key 보안

- 데이터 소스 API Key는 Supabase Vault에 암호화 저장
- API 응답에서 API Key는 마스킹 처리 (`***`)
- ActivityLog에도 API Key 원문 저장 금지

### 14.2 RLS 정책

- 모든 관리자 테이블에 `admin_only` Policy 적용
- `profiles.role = 'admin'` 체크
- Service Role Key 사용 금지 (RLS 우회 방지)

### 14.3 입력 검증

- Request Body는 Zod로 엄격히 검증
- SQL Injection 방지 (Supabase Query Builder 사용)
- XSS 방지 (사용자 입력 이스케이프)

### 14.4 ActivityLog

- 모든 CUD(Create, Update, Delete) 작업은 ActivityLog 기록
- 누가, 언제, 무엇을, 왜(reason) 기록
- IP 주소, User Agent 기록

### 14.5 Rate Limiting

- (선택적) Vercel Edge Config로 Rate Limiting 구현
- 관리자 API는 일반 사용자 API보다 높은 제한

---

## 15. 성능 최적화

### 15.1 Query 최적화

- Explicit Field Selection (불필요한 필드 제외)
- 적절한 인덱스 사용
- N+1 문제 방지 (JOIN 사용)

### 15.2 캐싱 전략

- TanStack Query의 staleTime, cacheTime 활용
- 정적 데이터(카테고리, 플랜 제한)는 긴 staleTime
- 동적 데이터(사용자 목록, 활동 로그)는 짧은 staleTime

### 15.3 페이지네이션

- 목록 조회 API는 모두 limit, offset 지원
- 기본 limit: 50~100
- 무한 스크롤 또는 페이지 네비게이션 지원

---

## 16. 에러 처리 전략

### 16.1 에러 타입별 처리

1. **Validation Error (400)**: Zod 검증 실패
   - 에러 코드: `VALIDATION_ERROR`
   - details에 필드별 에러 메시지 포함

2. **Unauthorized (401)**: 인증 실패
   - Middleware에서 처리
   - 프론트엔드에서 로그인 페이지로 리다이렉트

3. **Forbidden (403)**: 권한 없음
   - RLS Policy에서 처리
   - 에러 코드: `FORBIDDEN`

4. **Not Found (404)**: 리소스 없음
   - 에러 코드: `INDICATOR_NOT_FOUND`, `USER_NOT_FOUND`, 등

5. **Conflict (409)**: 제약 조건 위반
   - 에러 코드: `DUPLICATE_ENTRY`, `CONSTRAINT_VIOLATION`

6. **Internal Server Error (500)**: 서버 오류
   - 에러 코드: `INTERNAL_ERROR`
   - 상세 정보는 로그에만 기록, 클라이언트에는 일반 메시지

### 16.2 에러 로깅

- Supabase Edge Functions Log 또는 외부 서비스 (Sentry)
- 에러 발생 시 스택 트레이스, 요청 정보 기록

---

## 17. 테스트 전략

### 17.1 단위 테스트

- lib/services/ 함수 테스트 (csvValidation, indicatorValidation)
- Zod Schema 검증 테스트

### 17.2 통합 테스트

- API Route 테스트 (Vitest + Supertest)
- Mock Supabase Client 사용
- 인증, 권한, 에러 처리 시나리오 테스트

### 17.3 E2E 테스트

- Feature Module + BFF API 통합 테스트
- Playwright 사용
- 주요 플로우 테스트 (지표 생성, 사용자 관리, 템플릿 생성)

---

## 부록: AdminConsoleContract 메서드 매핑표

| Contract 메서드 | HTTP Method | 엔드포인트 | 설명 |
|----------------|-------------|-----------|------|
| createIndicator | POST | /api/indicators | 지표 생성 |
| updateIndicator | PATCH | /api/indicators/[id] | 지표 수정 |
| deleteIndicator | DELETE | /api/indicators/[id] | 지표 삭제 |
| getIndicators | GET | /api/indicators | 지표 목록 조회 |
| testIndicatorConnection | POST | /api/indicators/[id]/test | 지표 연결 테스트 |
| createTemplate | POST | /api/templates | 템플릿 생성 |
| updateTemplate | PATCH | /api/templates/[id] | 템플릿 수정 |
| deleteTemplate | DELETE | /api/templates/[id] | 템플릿 삭제 |
| getTemplates | GET | /api/templates | 템플릿 목록 조회 |
| getUsers | GET | /api/users | 사용자 목록 조회 |
| updateUserSubscription | PATCH | /api/users/[id]/plan | 사용자 플랜 변경 |
| activateUser | POST | /api/users/[id]/activate | 계정 활성화 |
| deactivateUser | POST | /api/users/[id]/suspend | 계정 정지 |
| getUserActivityLog | GET | /api/users/[id]/activity | 활동 로그 조회 |
| getDataSources | GET | /api/data-sources | 데이터 소스 목록 조회 |
| createDataSource | POST | /api/data-sources | 데이터 소스 생성 |
| updateDataSource | PATCH | /api/data-sources/[id] | 데이터 소스 수정 |
| updateDataSourceAPIKey | PATCH | /api/data-sources/[id]/api-key | API Key 수정 |
| toggleDataSourceStatus | PATCH | /api/data-sources/[id]/status | 상태 변경 |
| testAPIConnection | POST | /api/data-sources/[id]/test | 연결 테스트 |
| getPlanLimitConfigs | GET | /api/plan-limits | 플랜 제한 목록 조회 |
| updatePlanLimit | PATCH | /api/plan-limits/[id] | 플랜 제한 수정 |
| addPlanLimit | POST | /api/plan-limits | 플랜 제한 추가 |
| removePlanLimit | DELETE | /api/plan-limits/[id] | 플랜 제한 삭제 |
| getLimitHistory | GET | /api/plan-limits/history | 변경 이력 조회 |
| getCategories | GET | /api/categories | 카테고리 목록 조회 |
| createCategory | POST | /api/categories | 카테고리 생성 |
| updateCategory | PATCH | /api/categories/[id] | 카테고리 수정 |
| deleteCategory | DELETE | /api/categories/[id] | 카테고리 삭제 |
| reorderCategories | POST | /api/categories/reorder | 순서 변경 |
| toggleCategoryStatus | PATCH | /api/categories/[id]/status | 상태 변경 |
| uploadCustomData | POST | /api/custom-data/validate | CSV 검증 |
| addCustomDataPoint | POST | /api/custom-data/[indicatorId] | 데이터 저장 |
| getCustomData | GET | /api/custom-data/[indicatorId] | 데이터 목록 조회 |
| updateCustomDataPoint | PATCH | /api/custom-data/[id] | 데이터 수정 |
| deleteCustomDataPoint | DELETE | /api/custom-data/[id] | 데이터 삭제 |
| getCustomDataHistory | GET | /api/custom-data/[indicatorId]/history | 변경 이력 조회 |
| getSystemMetrics | GET | /api/metrics | 시스템 메트릭 조회 |
| getDashboardStats | GET | /api/dashboard-stats | 대시보드 통계 조회 |

**총 39개 메서드 → 42개 REST 엔드포인트** (일부 메서드는 여러 엔드포인트로 분리)
