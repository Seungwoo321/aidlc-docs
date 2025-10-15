# Admin Moderation BFF API 설계 문서

## 개요

**Feature Module**: Admin Moderation
**책임**: 컨텐츠 안전 및 규제 관리 (US6.9~6.11)
**아키텍처**: Next.js 15 App Router API Routes + Supabase + RLS + Cron Job
**설계 원칙**: Thin API Layer, RESTful API, TypeScript + Zod, Explicit Field Selection

## 승인된 아키텍처 결정사항

### 공통 결정사항 (Admin Console과 공유)

1. **API Route 경로 구조**: Resource 기반 Flat 구조
2. **Supabase Client**: Server Component Client (createServerClient)
3. **Middleware 권한 검증**: Hybrid (Next.js Middleware + Supabase RLS)
4. **API Response 에러 처리**: TypeScript 타입 + Structured Response
5. **Supabase Query 최적화**: Explicit Field Selection

### Moderation 전용 결정사항

6. **신고자 익명성 보호**: 신고자 식별 + 관리자 익명 (신고자 수만 집계)
   - 시스템은 reporter_id 추적, 관리자는 reporter_count만 확인
   - 중복 신고 방지, 악용 패턴 감지 가능

7. **자동 탐지 스캔 실행**: 동기 API (수동) + 정기 Cron Job (자동)
   - 수동 테스트: API에서 단일 대시보드 동기 스캔
   - 자동 스캔: Supabase pg_cron으로 정기 전체 스캔

8. **조치 실행 후 알림**: 알림 없음 (ActivityLog만 기록)
   - MVP 단계에서 알림 인프라 구축 생략
   - ActivityLog로 조치 이력 확인 가능

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
- `REPORT_NOT_FOUND`: 신고를 찾을 수 없음
- `DASHBOARD_NOT_FOUND`: 대시보드를 찾을 수 없음
- `USER_NOT_FOUND`: 사용자를 찾을 수 없음
- `RULE_NOT_FOUND`: 탐지 룰을 찾을 수 없음
- `UNAUTHORIZED`: 인증되지 않은 요청
- `FORBIDDEN`: 권한 없음 (관리자 전용 API)
- `VALIDATION_ERROR`: 요청 데이터 검증 실패
- `DUPLICATE_RULE`: 중복된 탐지 룰
- `INVALID_PATTERN`: 정규표현식 패턴 오류
- `INTERNAL_ERROR`: 서버 내부 오류

## 1. 신고 관리 API (US6.9)

### 1.1 신고된 대시보드 목록 조회

**엔드포인트**: `GET /api/moderation/reports`

**Query Parameters**:
- `status` (string, optional): pending, under_review, actioned, dismissed
- `reason` (string, optional): investment_advice, scam, false_info, spam, other
- `dateFrom` (string, optional): 시작 날짜 (ISO 8601)
- `dateTo` (string, optional): 종료 날짜 (ISO 8601)
- `sortBy` (string, optional): created_at, reporter_count - 기본값: created_at
- `sortOrder` (string, optional): asc, desc - 기본값: desc
- `limit` (number, optional): 기본값: 50
- `offset` (number, optional): 페이지 오프셋

**Supabase Query**:
- 테이블: `dashboard_reports`
- 필드: `id, dashboard_id, reason, status, created_at, updated_at`
- **신고자 익명성**: `reporter_id`는 제외, `COUNT(DISTINCT reporter_id) as reporter_count` 집계
- 조인: `dashboards` (대시보드 이름, 작성자 정보)
- 필터: status, reason, dateFrom, dateTo
- 정렬: sortBy, sortOrder
- 페이지네이션: limit, offset

**비즈니스 로직**:
1. 동일한 dashboard_id에 대한 여러 신고를 GROUP BY로 집계
2. reporter_count = COUNT(DISTINCT reporter_id)
3. 가장 최근 신고 날짜를 created_at으로 사용

**Response**: `ApiResponse<DashboardReport[]>`

**DashboardReport 타입**:
```typescript
{
  id: string
  dashboardId: string
  dashboardName: string
  dashboardOwnerId: string
  dashboardOwnerName: string
  reason: 'investment_advice' | 'scam' | 'false_info' | 'spam' | 'other'
  status: 'pending' | 'under_review' | 'actioned' | 'dismissed'
  reporterCount: number  // 신고자 개인정보는 숨김
  createdAt: string
  updatedAt: string
}
```

**RLS Policy**: admin_only

---

### 1.2 신고 상세 조회

**엔드포인트**: `GET /api/moderation/reports/[id]`

**Path Parameters**:
- `id` (string): 신고 ID

**Supabase Query**:
- 테이블: `dashboard_reports`
- 필드: `id, dashboard_id, reason, status, review_note, created_at, reviewed_at`
- **신고자 익명성**: `reporter_id` 제외, `reporter_count` 집계
- 조인: `dashboards` (전체 필드 - 대시보드 내용 검토용)
- 조인: `profiles` (대시보드 작성자 이력)
- 필터: `id = :id` 또는 `dashboard_id = :dashboardId` (GROUP BY)

**Response**: `ApiResponse<DashboardReportDetail>`

**DashboardReportDetail 타입**:
```typescript
{
  id: string
  dashboardId: string
  dashboard: {
    name: string
    description: string
    isPublic: boolean
    createdAt: string
    // ... 대시보드 전체 정보
  }
  owner: {
    id: string
    name: string
    email: string
    violationCount: number  // 과거 위반 횟수
    lastViolationDate?: string
  }
  reason: string
  status: string
  reporterCount: number
  reviewNote?: string
  createdAt: string
  reviewedAt?: string
}
```

**RLS Policy**: admin_only

---

### 1.3 신고 검토 및 조치

**엔드포인트**: `POST /api/moderation/reports/[id]/action`

**Path Parameters**:
- `id` (string): 신고 ID (또는 dashboard_id로 모든 신고 처리)

**Request Body** (Zod 검증):
```typescript
ReviewReportSchema = z.object({
  action: z.enum(['warning', 'delete_dashboard', 'suspend_user', 'dismiss']),
  reason: z.string().min(1),
  suspendDuration: z.number().optional()  // suspend_user 선택 시 (시간 단위)
})
```

**비즈니스 로직**:
1. 동일한 dashboard_id의 모든 신고를 `actioned` 또는 `dismissed` 상태로 변경
2. action에 따라 추가 작업:
   - `warning`: violation_logs에 경고 기록
   - `delete_dashboard`: dashboards 테이블에서 삭제 (soft delete)
   - `suspend_user`: profiles 테이블에서 status = 'inactive', suspend_until = NOW() + suspendDuration
   - `dismiss`: 무혐의 처리
3. ActivityLog 기록

**Supabase Query**:
1. 테이블: `dashboard_reports` UPDATE (status = 'actioned' or 'dismissed', review_note = reason, reviewed_at = NOW(), reviewed_by = auth.uid())
2. 테이블: `violation_logs` INSERT (action에 따라)
3. 테이블: `dashboards` UPDATE or DELETE (delete_dashboard 선택 시)
4. 테이블: `profiles` UPDATE (suspend_user 선택 시)

**Response**: `ApiResponse<{ success: true, affectedReports: number }>`

**ActivityLog**: `action: 'review_report'`, `details: { dashboardId, action, reason }`

**RLS Policy**: admin_only

---

## 2. 위반 사용자 관리 API (US6.10)

### 2.1 사용자 위반 이력 조회

**엔드포인트**: `GET /api/moderation/violations/user/[userId]`

**Path Parameters**:
- `userId` (string): 사용자 ID

**Query Parameters**:
- `limit` (number, optional): 기본값: 100

**Supabase Query**:
- 테이블: `violation_logs`
- 필드: `id, user_id, dashboard_id, violation_type, severity, detected_by, status, action_taken, action_reason, created_at, reviewed_at`
- 조인: `dashboards` (대시보드 이름)
- 필터: `user_id = :userId`
- 정렬: `created_at DESC`
- 제한: limit

**Response**: `ApiResponse<ViolationLog[]>`

**RLS Policy**: admin_only

---

### 2.2 위반 통계 조회

**엔드포인트**: `GET /api/moderation/violations/stats`

**Query Parameters**:
- `from` (string, optional): 시작 날짜 (ISO 8601)
- `to` (string, optional): 종료 날짜 (ISO 8601)

**Supabase Query** (여러 집계 쿼리):
1. `dashboard_reports` 테이블: `COUNT(*)` (totalReports), `COUNT(*) WHERE status = 'pending'` (pendingReports)
2. `violation_logs` 테이블: `COUNT(*)` (totalViolations), `COUNT(*) GROUP BY violation_type` (violationsByType)
3. `violation_logs` 조인 `profiles`: `COUNT(*) GROUP BY user_id ORDER BY count DESC LIMIT 10` (topViolators)

**Response**: `ApiResponse<ViolationStats>`

**ViolationStats 타입**:
```typescript
{
  totalReports: number
  pendingReports: number
  totalViolations: number
  violationsByType: Record<string, number>  // { 'investment_advice': 10, 'scam': 5, ... }
  topViolators: Array<{
    userId: string
    userName: string
    violationCount: number
  }>
}
```

**RLS Policy**: admin_only

---

### 2.3 사용자 제재

**엔드포인트**: `POST /api/moderation/violations/[userId]/sanction`

**Path Parameters**:
- `userId` (string): 사용자 ID

**Request Body** (Zod 검증):
```typescript
SuspendUserSchema = z.object({
  reason: z.string().min(1),
  duration: z.number().optional()  // 시간 단위 (48시간 = 48, 영구 = null)
})
```

**비즈니스 로직** (violationSeverityCalculator.ts 서비스 사용):
1. 사용자의 누적 위반 횟수 조회
2. 단계적 제재 시스템:
   - 1회 위반: 경고
   - 2회 위반: 48시간 제한
   - 3회 이상: 영구 정지
3. 수동 제재 옵션 (duration 파라미터로 오버라이드)

**Supabase Query**:
1. 테이블: `profiles` UPDATE (status = 'inactive', suspend_until = NOW() + duration, suspend_reason = reason)
2. 테이블: `violation_logs` INSERT (action_taken = 'suspend_user')

**Response**: `ApiResponse<{ success: true, suspendUntil?: string }>`

**ActivityLog**: `action: 'suspend_user'`, `details: { userId, reason, duration }`

**RLS Policy**: admin_only

---

## 3. 자동 탐지 시스템 API (US6.11)

### 3.1 자동 탐지된 컨텐츠 목록 조회

**엔드포인트**: `GET /api/moderation/auto-detected`

**Query Parameters**:
- `severity` (string, optional): low, medium, high
- `status` (string, optional): pending, reviewed
- `dateFrom` (string, optional): 시작 날짜
- `limit` (number, optional): 기본값: 50
- `offset` (number, optional): 페이지 오프셋

**Supabase Query**:
- 테이블: `violation_logs`
- 필드: `id, user_id, dashboard_id, violation_type, severity, detected_pattern, status, created_at`
- 조인: `dashboards` (대시보드 내용, 키워드 하이라이트용)
- 조인: `profiles` (작성자 정보)
- 필터: `detected_by = 'auto_detection'`, severity, status, dateFrom
- 정렬: `severity DESC, created_at DESC` (높은 위험도 우선)
- 페이지네이션: limit, offset

**Response**: `ApiResponse<Array<{ dashboard: Dashboard, violation: ViolationLog }>>`

**주의**: 프론트엔드에서 detected_pattern을 사용하여 대시보드 내용에 키워드 하이라이트 표시

**RLS Policy**: admin_only

---

### 3.2 탐지 룰 목록 조회

**엔드포인트**: `GET /api/moderation/detection-rules`

**Query Parameters**:
- `isActive` (boolean, optional): 활성화 상태 필터링

**Supabase Query**:
- 테이블: `detection_rules`
- 필드: `id, name, pattern, severity, action, is_active, description, created_at, updated_at`
- 필터: isActive
- 정렬: `severity DESC, name ASC`

**Response**: `ApiResponse<DetectionRule[]>`

**RLS Policy**: admin_only

---

### 3.3 탐지 룰 생성

**엔드포인트**: `POST /api/moderation/detection-rules`

**Request Body** (Zod 검증):
```typescript
CreateDetectionRuleSchema = z.object({
  name: z.string().min(1).max(100),
  pattern: z.string().min(1),  // 정규표현식
  severity: z.enum(['low', 'medium', 'high']),
  action: z.enum(['flag', 'auto_hide', 'auto_delete']),
  description: z.string()
})
```

**비즈니스 로직** (detectionRuleValidation.ts 서비스 사용):
1. 정규표현식 패턴 검증 (구문 오류 체크)
2. 패턴이 너무 광범위한지 체크 (예: `.*` 금지)
3. 기존 룰과 충돌 체크

**Supabase Query**:
- 테이블: `detection_rules`
- 작업: INSERT
- 필드: 요청 데이터 + `is_active = true`, `created_by = auth.uid()`

**Response**: `ApiResponse<DetectionRule>`

**ActivityLog**: `action: 'create_detection_rule'`

**RLS Policy**: admin_only

---

### 3.4 탐지 룰 수정

**엔드포인트**: `PATCH /api/moderation/detection-rules/[id]`

**Path Parameters**:
- `id` (string): 탐지 룰 ID

**Request Body** (Zod 검증):
```typescript
UpdateDetectionRuleSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  pattern: z.string().min(1).optional(),
  severity: z.enum(['low', 'medium', 'high']).optional(),
  action: z.enum(['flag', 'auto_hide', 'auto_delete']).optional(),
  isActive: z.boolean().optional(),
  description: z.string().optional()
})
```

**비즈니스 로직**:
1. pattern 변경 시 정규표현식 검증
2. 기존 룰과 충돌 체크

**Supabase Query**:
- 테이블: `detection_rules`
- 작업: UPDATE
- 필드: 요청 데이터 + `updated_at = NOW()`, `updated_by = auth.uid()`
- 필터: `id = :id`

**Response**: `ApiResponse<DetectionRule>`

**ActivityLog**: `action: 'update_detection_rule'`

**RLS Policy**: admin_only

---

### 3.5 탐지 룰 삭제

**엔드포인트**: `DELETE /api/moderation/detection-rules/[id]`

**Path Parameters**:
- `id` (string): 탐지 룰 ID

**Supabase Query**:
- 테이블: `detection_rules`
- 작업: UPDATE (soft delete)
- 필드: `is_active = false`, `updated_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<{ success: true }>`

**ActivityLog**: `action: 'delete_detection_rule'`

**RLS Policy**: admin_only

---

### 3.6 탐지 룰 테스트 (수동 스캔)

**엔드포인트**: `POST /api/moderation/detection-rules/[id]/test`

**Path Parameters**:
- `id` (string): 탐지 룰 ID

**Request Body** (Zod 검증):
```typescript
TestDetectionRuleSchema = z.object({
  dashboardId: z.string().uuid()
})
```

**비즈니스 로직**:
1. 대시보드 조회 (title, description)
2. 탐지 룰 조회 (pattern)
3. Node.js regex로 동기 스캔 실행
4. 매칭된 키워드/구문 반환

**Supabase Query**:
- 테이블: `dashboards` SELECT
- 테이블: `detection_rules` SELECT

**Response**: `ApiResponse<{ matched: boolean, matches: string[] }>`

**주의**: 실제 violation_logs에 기록하지 않음 (테스트 용도)

**RLS Policy**: admin_only

---

### 3.7 위반 무혐의 처리

**엔드포인트**: `POST /api/moderation/violations/[id]/dismiss`

**Path Parameters**:
- `id` (string): 위반 로그 ID

**Request Body** (Zod 검증):
```typescript
DismissViolationSchema = z.object({
  reason: z.string().min(1)
})
```

**비즈니스 로직**:
1. 위반 로그 상태 변경 (status = 'dismissed')
2. 오탐으로 처리 (향후 학습 데이터로 활용 가능)

**Supabase Query**:
- 테이블: `violation_logs`
- 작업: UPDATE
- 필드: `status = 'dismissed'`, `action_reason = reason`, `reviewed_by = auth.uid()`, `reviewed_at = NOW()`
- 필터: `id = :id`

**Response**: `ApiResponse<{ success: true }>`

**ActivityLog**: `action: 'dismiss_violation'`, `details: { violationId, reason }`

**RLS Policy**: admin_only

---

## 4. Middleware 설계

### 4.1 인증 Middleware (Admin Console과 공유)

**파일**: `apps/admin/middleware.ts`

**책임**:
1. `/api/moderation/*` 경로 포함하여 모든 관리자 API에 적용
2. Supabase 세션 확인
3. 인증되지 않은 요청은 401 반환

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

### 4.2 RLS Policy (Supabase)

**Policy 예시**:
```sql
-- dashboard_reports 테이블 (신고자 익명성 보호)
CREATE POLICY admin_only_no_reporter ON dashboard_reports
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- reporter_id 필드는 SELECT에서 제외 (Application 레벨에서 처리)

-- 모든 moderation 테이블에 admin_only Policy 적용
-- violation_logs, detection_rules
```

---

## 5. Supabase Cron Job 설계

### 5.1 자동 탐지 스캔 Cron Job

**스케줄**: 매 시간 실행 (0 * * * *)

**Supabase Function**: `detect_risky_content()`

**로직**:
1. 최근 24시간 내 생성/수정된 대시보드 조회
2. 활성화된 탐지 룰 조회 (`detection_rules WHERE is_active = true`)
3. 각 대시보드에 대해:
   - title, description을 각 탐지 룰의 pattern으로 스캔
   - 매칭 시 `violation_logs` 테이블에 INSERT
   - `detected_by = 'auto_detection'`, `status = 'pending'`
4. action에 따라 자동 조치:
   - `flag`: 플래깅만
   - `auto_hide`: 대시보드 is_public = false
   - `auto_delete`: 대시보드 soft delete

**Supabase SQL**:
```sql
SELECT cron.schedule(
  'detect-risky-content',
  '0 * * * *',  -- 매 시간
  $$
  SELECT detect_risky_content();
  $$
);

CREATE OR REPLACE FUNCTION detect_risky_content()
RETURNS void AS $$
DECLARE
  dashboard_record RECORD;
  rule_record RECORD;
BEGIN
  -- 최근 24시간 대시보드 조회
  FOR dashboard_record IN
    SELECT id, title, description, user_id
    FROM dashboards
    WHERE updated_at > NOW() - INTERVAL '24 hours'
  LOOP
    -- 활성 탐지 룰 조회
    FOR rule_record IN
      SELECT id, pattern, severity, action
      FROM detection_rules
      WHERE is_active = true
    LOOP
      -- 정규표현식 매칭
      IF dashboard_record.title ~ rule_record.pattern OR
         dashboard_record.description ~ rule_record.pattern THEN

        -- violation_logs 삽입
        INSERT INTO violation_logs (
          user_id, dashboard_id, violation_type, severity,
          detected_by, detected_pattern, status
        ) VALUES (
          dashboard_record.user_id,
          dashboard_record.id,
          'auto_detected',
          rule_record.severity,
          'auto_detection',
          rule_record.pattern,
          'pending'
        );

        -- 자동 조치
        IF rule_record.action = 'auto_hide' THEN
          UPDATE dashboards SET is_public = false WHERE id = dashboard_record.id;
        ELSIF rule_record.action = 'auto_delete' THEN
          UPDATE dashboards SET deleted_at = NOW() WHERE id = dashboard_record.id;
        END IF;
      END IF;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

---

## 6. Supabase 테이블 설계 (개요)

### 6.1 필요한 테이블 목록

1. **dashboard_reports**: 신고 정보
   - 필드: `id, dashboard_id, reporter_id, reason, description, status, review_note, reviewed_by, created_at, reviewed_at`
   - 인덱스: `(dashboard_id, status)`, `(created_at)`
   - **신고자 익명성**: API에서 reporter_id 제외, COUNT(DISTINCT reporter_id) 집계

2. **violation_logs**: 위반 로그
   - 필드: `id, user_id, dashboard_id, violation_type, severity, detected_by, detected_pattern, status, action_taken, action_reason, reviewed_by, created_at, reviewed_at`
   - 인덱스: `(user_id, created_at)`, `(dashboard_id)`, `(detected_by, status)`

3. **detection_rules**: 탐지 룰
   - 필드: `id, name, pattern, severity, action, is_active, description, created_by, created_at, updated_at`
   - 인덱스: `(is_active, severity)`

4. **profiles** (확장): 사용자 프로필
   - 추가 필드: `suspend_until (timestamp)`, `suspend_reason (text)`

### 6.2 Trigger 설계

**ActivityLog 자동 기록 Trigger**:
- dashboard_reports UPDATE (조치 실행 시)
- violation_logs INSERT (위반 기록 시)
- detection_rules INSERT/UPDATE/DELETE

---

## 7. File Structure

```
apps/admin/
  app/
    api/
      moderation/
        reports/
          route.ts                      # GET
          [id]/
            route.ts                    # GET
            action/
              route.ts                  # POST
        violations/
          stats/
            route.ts                    # GET
          user/
            [userId]/
              route.ts                  # GET
          [userId]/
            sanction/
              route.ts                  # POST
          [id]/
            dismiss/
              route.ts                  # POST
        auto-detected/
          route.ts                      # GET
        detection-rules/
          route.ts                      # GET, POST
          [id]/
            route.ts                    # PATCH, DELETE
            test/
              route.ts                  # POST
    middleware.ts                       # Admin Console과 공유
  lib/
    supabase/
      server.ts                         # createServerClient
      types.ts                          # Supabase 타입 정의
    api/
      responses.ts                      # ApiResponse 헬퍼 (공유)
      errors.ts                         # 에러 처리 유틸리티 (공유)
    services/
      detectionRuleValidation.ts        # 탐지 룰 정규표현식 검증
      violationSeverityCalculator.ts    # 위반 심각도 계산
      activityLogger.ts                 # ActivityLog 기록 (공유)

packages/admin-moderation/
  (Feature Module - React Components, TanStack Query Hooks)
```

---

## 8. 다음 단계 (Implementation)

### 8.1 Supabase Schema 구현

1. 테이블 생성 (migration SQL)
   - dashboard_reports (신고자 익명성 고려)
   - violation_logs
   - detection_rules
   - profiles 확장 (suspend_until, suspend_reason)

2. RLS Policy 적용
   - admin_only Policy (모든 moderation 테이블)

3. 인덱스 생성
   - 성능 최적화 인덱스

4. Trigger 생성
   - ActivityLog 자동 기록

5. Cron Job 설정
   - pg_cron으로 자동 탐지 스케줄링

### 8.2 API Routes 구현

1. middleware.ts (Admin Console과 공유)
2. lib/services/ 구현 (detectionRuleValidation, violationSeverityCalculator)
3. 각 route.ts 파일 구현
4. Zod Schema 정의
5. 통합 테스트

### 8.3 Feature Module 통합

1. packages/admin-moderation의 TanStack Query Hooks가 BFF API 호출
2. Query Key 구조 일치 확인
3. 에러 처리 통합
4. Loading/Success/Error 상태 관리

### 8.4 배포

1. Vercel Multi-Zone 설정 (Admin Console과 공유)
2. Supabase Cron Job 활성화
3. 성능 모니터링
4. 탐지 룰 초기 데이터 입력

---

## 9. 보안 고려사항

### 9.1 신고자 익명성 보호

- **시스템 레벨**: `reporter_id` 저장 (중복 신고 방지, 악용 패턴 감지)
- **관리자 레벨**: `reporter_id` 노출 금지, `reporter_count`만 제공
- **API 응답**: reporter_id 필드 제외
- **Supabase Query**: `COUNT(DISTINCT reporter_id) as reporter_count`

### 9.2 RLS 정책

- 모든 moderation 테이블에 `admin_only` Policy 적용
- `profiles.role = 'admin'` 체크
- Service Role Key 사용 금지

### 9.3 정규표현식 보안

- 탐지 룰 pattern 검증 (detectionRuleValidation.ts)
- ReDoS (Regular Expression Denial of Service) 방지
- 너무 광범위한 패턴 금지 (예: `.*`)

### 9.4 ActivityLog

- 모든 조치 실행은 ActivityLog 기록
- 누가, 언제, 어떤 조치를, 왜(reason) 기록
- 신고 검토, 위반 처리, 탐지 룰 변경 모두 기록

### 9.5 조치 로그 영구 보존

- violation_logs는 soft delete 금지 (영구 보존)
- 법적 증거로 활용 가능

---

## 10. 성능 최적화

### 10.1 Query 최적화

- Explicit Field Selection
- 적절한 인덱스 사용
- N+1 문제 방지 (JOIN 사용)

### 10.2 자동 탐지 성능

- Cron Job은 최근 24시간 대시보드만 스캔
- 비활성화된 탐지 룰은 제외 (`is_active = true`)
- 정규표현식 성능 최적화 (간단한 패턴 우선)

### 10.3 캐싱 전략

- 탐지 룰 목록: 긴 staleTime (자주 변경되지 않음)
- 신고 목록, 위반 로그: 짧은 staleTime (실시간 업데이트)

---

## 11. 에러 처리 전략

### 11.1 에러 타입별 처리

1. **Validation Error (400)**: Zod 검증 실패
2. **Unauthorized (401)**: 인증 실패
3. **Forbidden (403)**: 권한 없음
4. **Not Found (404)**: 리소스 없음
5. **Conflict (409)**: 중복된 탐지 룰
6. **Internal Server Error (500)**: 서버 오류

### 11.2 정규표현식 에러

- 탐지 룰 생성/수정 시 pattern 검증
- 구문 오류 시 `INVALID_PATTERN` 에러 반환
- 에러 메시지에 구문 오류 위치 포함

---

## 12. 테스트 전략

### 12.1 단위 테스트

- detectionRuleValidation.ts 테스트 (정규표현식 검증)
- violationSeverityCalculator.ts 테스트 (단계적 제재)
- Zod Schema 검증 테스트

### 12.2 통합 테스트

- API Route 테스트
- Mock Supabase Client 사용
- 신고 → 조치 → ActivityLog 플로우 테스트

### 12.3 Cron Job 테스트

- detect_risky_content() 함수 테스트
- 다양한 탐지 패턴 시나리오 테스트
- 자동 조치 테스트 (flag, auto_hide, auto_delete)

### 12.4 E2E 테스트

- Feature Module + BFF API 통합 테스트
- Playwright 사용
- 주요 플로우 테스트:
  - 신고 접수 → 검토 → 조치
  - 탐지 룰 생성 → 테스트 → 자동 탐지

---

## 부록: AdminModerationContract 메서드 매핑표

| Contract 메서드 | HTTP Method | 엔드포인트 | 설명 |
|----------------|-------------|-----------|------|
| getReportedDashboards | GET | /api/moderation/reports | 신고된 대시보드 목록 조회 |
| (상세 조회) | GET | /api/moderation/reports/[id] | 신고 상세 조회 |
| reviewReport | POST | /api/moderation/reports/[id]/action | 신고 검토 및 조치 |
| getUserViolations | GET | /api/moderation/violations/user/[userId] | 사용자 위반 이력 조회 |
| getViolationStats | GET | /api/moderation/violations/stats | 위반 통계 조회 |
| suspendUser | POST | /api/moderation/violations/[userId]/sanction | 사용자 제재 |
| getAutoDetectedContent | GET | /api/moderation/auto-detected | 자동 탐지된 컨텐츠 목록 |
| getDetectionRules | GET | /api/moderation/detection-rules | 탐지 룰 목록 조회 |
| createDetectionRule | POST | /api/moderation/detection-rules | 탐지 룰 생성 |
| updateDetectionRule | PATCH | /api/moderation/detection-rules/[id] | 탐지 룰 수정 |
| (탐지 룰 삭제) | DELETE | /api/moderation/detection-rules/[id] | 탐지 룰 삭제 |
| (탐지 룰 테스트) | POST | /api/moderation/detection-rules/[id]/test | 탐지 룰 수동 테스트 |
| dismissViolation | POST | /api/moderation/violations/[id]/dismiss | 위반 무혐의 처리 |

**총 10개 메서드 → 13개 REST 엔드포인트** (일부 메서드는 여러 엔드포인트로 분리)

---

## 부록: 자동 탐지 패턴 예시

### 위험 키워드 패턴

```regex
# 종목명 + 행동 유도
(?i)(삼성전자|현대차|SK하이닉스).{0,50}(지금 사세요|빨리 매수|놓치지 마세요)

# 수익 보장
(?i)(100% 수익|무조건 상승|손실 없음|원금 보장)

# 타이밍 단정
(?i)(내일 급등|다음주 폭등|곧 상한가)

# 외부 링크 (텔레그램, 카카오톡)
(?i)(텔레그램|telegram|카톡|오픈채팅).{0,20}(링크|주소|참여)
```

### 탐지 룰 우선순위

1. **높음 (high)**: 수익 보장, 불법 투자 권유
2. **중간 (medium)**: 타이밍 단정, 종목 추천 + 행동 유도
3. **낮음 (low)**: 외부 링크, 스팸성 키워드

### 오탐 방지

- 컨텍스트 고려 (예: "삼성전자 주가 분석" vs "삼성전자 지금 사세요")
- 면책 조항 포함 시 severity 낮춤
- 관리자 무혐의 처리 이력 학습 (향후 개선)
