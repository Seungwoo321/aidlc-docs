# Admin Moderation BFF API 설계 계획

## 개요

**Feature Module**: Admin Moderation
**책임**: BFF API Layer for Admin Moderation (US6.9~6.11)
**아키텍처**: Next.js 15 App Router API Routes + Supabase Direct + RLS

## 목표

Admin Moderation BFF API 설계 문서를 작성하여 다음을 달성합니다:

1. **Thin API Layer**: 비즈니스 로직 최소화, Supabase 직접 호출
2. **RESTful API**: 10개 AdminModerationContract 메서드를 REST 엔드포인트로 매핑
3. **Type Safety**: TypeScript + Zod로 Request/Response 검증
4. **Security**: Supabase RLS + Middleware 기반 관리자 권한 검증 + 신고자 익명성 보호
5. **Performance**: Supabase Query 최적화, 자동 탐지 성능 최적화

## 포함된 사용자 스토리

### US6.9: 신고된 컨텐츠 관리
- 신고된 대시보드 목록 조회 (신고 사유, 접수일시, 신고자 수)
- 대시보드 상세 검토 (원본 내용, 작성자 이력)
- 조치 실행: 경고, 삭제, 계정 정지, 무혐의
- 조치 사유 기록 및 결과 통보

### US6.10: 컨텐츠 위반 사용자 관리
- 사용자별 위반 이력 조회 (경고 횟수, 삭제된 대시보드 수, 마지막 위반 날짜)
- 단계적 제재 시스템 (1회 경고 → 2회 48시간 제한 → 3회 영구 정지)
- 수동 제재 옵션
- 제재 내역 통보

### US6.11: 위험 컨텐츠 자동 탐지
- 위험 패턴 자동 스캔 (종목명 + 행동 유도, 수익 보장, 타이밍 단정, 외부 링크)
- 플래깅된 대시보드 목록 (키워드 하이라이트, 위험도 점수)
- 자동 조치 설정 (높음/중간/낮음)
- 오탐 처리 및 학습
- 탐지 룰 관리 (정규표현식 기반)

## 아키텍처 질문 (Admin Console과 공유)

Admin Console BFF API 설계에서 승인된 아키텍처 결정을 재사용합니다:

### [Question 1] API Route 경로 구조 전략

**승인된 결정**: Resource 기반 Flat 구조

```
apps/admin/app/api/moderation/
  reports/
    route.ts                    # GET /api/moderation/reports (list)
    [id]/route.ts               # GET /api/moderation/reports/[id]
    [id]/action/route.ts        # POST /api/moderation/reports/[id]/action
  violations/
    route.ts                    # GET /api/moderation/violations (list)
    user/[userId]/route.ts      # GET /api/moderation/violations/user/[userId]
    stats/route.ts              # GET /api/moderation/violations/stats
    [id]/sanction/route.ts      # POST /api/moderation/violations/[id]/sanction
  detection-rules/
    route.ts                    # GET /api/moderation/detection-rules (list), POST
    [id]/route.ts               # GET, PATCH, DELETE
    [id]/test/route.ts          # POST /api/moderation/detection-rules/[id]/test
  auto-detected/
    route.ts                    # GET /api/moderation/auto-detected (list)
    [id]/review/route.ts        # POST /api/moderation/auto-detected/[id]/review
```

### [Question 2] Supabase Client 전략

**승인된 결정**: Server Component Client (createServerClient)

### [Question 3] Middleware 권한 검증 전략

**승인된 결정**: Hybrid (Middleware + Supabase RLS)

### [Question 4] API Response 에러 처리 전략

**승인된 결정**: Zod + HTTP Status (Structured Error Response)

### [Question 5] Supabase Query 최적화 전략

**승인된 결정**: Explicit Field Selection

## Moderation 전용 아키텍처 질문

### [Question 6] 신고자 익명성 보호 전략

**선택지**:

**Option A: API에서 신고자 정보 제외**
```typescript
// reports/[id]/route.ts
const { data } = await supabase
  .from('dashboard_reports')
  .select('id, dashboard_id, reason, status, created_at')
  // reporter_id 제외

return Response.json({ data, error: null })
```

**장점**:
- API 레벨에서 익명성 보장

**단점**:
- 신고자 수 집계 불가

**Option B: 신고자 수만 집계하여 전달**
```typescript
// reports/[id]/route.ts
const { data: reports } = await supabase
  .from('dashboard_reports')
  .select('id, dashboard_id, reason, status, created_at, reporter_count')

return Response.json({ data: reports, error: null })
```

**장점**:
- 익명성 보호 + 신고자 수 표시

**단점**:
- reporter_count 컬럼 추가 필요

**Option C: Supabase RLS로 숨김**
```sql
-- dashboard_reports 테이블
CREATE POLICY hide_reporter ON dashboard_reports
  FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  )
  WITH CHECK (false);

-- View로 익명화
CREATE VIEW dashboard_reports_admin AS
SELECT
  id, dashboard_id, reason, status, created_at,
  COUNT(DISTINCT reporter_id) as reporter_count
FROM dashboard_reports
GROUP BY id, dashboard_id, reason, status, created_at;
```

**장점**:
- DB 레벨 보안
- 신고자 정보 완전 차단

**단점**:
- View 관리 필요

**권장**: Option B (신고자 수만 집계)

**이유**:
1. 익명성 보호 + 신고 심각도 판단 가능
2. API 코드 간결 (View 불필요)
3. reporter_count는 GROUP BY로 동적 계산 가능
4. 신고자 개인 정보 노출 방지

### [Question 7] 자동 탐지 스캔 실행 전략

**선택지**:

**Option A: API에서 동기 스캔**
```typescript
// POST /api/moderation/detection-rules/[id]/test
export async function POST(request: Request, { params }) {
  const { dashboardId } = await request.json()

  // 대시보드 조회
  const { data: dashboard } = await supabase
    .from('dashboards')
    .select('title, description')
    .eq('id', dashboardId)
    .single()

  // 탐지 룰 조회
  const { data: rule } = await supabase
    .from('detection_rules')
    .select('pattern, keywords')
    .eq('id', params.id)
    .single()

  // 동기 스캔 (Node.js regex)
  const matches = scanContent(dashboard, rule)

  return Response.json({ data: { matches }, error: null })
}
```

**장점**:
- 간단한 구현
- 즉시 결과 반환

**단점**:
- 대량 스캔 시 타임아웃 위험
- API 블로킹

**Option B: Supabase Edge Function (비동기)**
```typescript
// POST /api/moderation/detection-rules/[id]/test
export async function POST(request: Request, { params }) {
  // Edge Function 호출
  const { data } = await supabase.functions.invoke('detect-content', {
    body: { ruleId: params.id, dashboardId }
  })

  return Response.json({ data: { jobId: data.jobId }, error: null })
}

// GET /api/moderation/detection-rules/jobs/[jobId]
// 스캔 결과 조회 (폴링)
```

**장점**:
- 대량 스캔 가능
- API 응답 빠름

**단점**:
- Edge Function 배포 필요
- 폴링 복잡도

**Option C: 정기 Cron Job (Supabase pg_cron)**
```sql
-- 매 시간 자동 스캔
SELECT cron.schedule(
  'detect-risky-content',
  '0 * * * *',
  $$ SELECT detect_risky_content() $$
);
```

**장점**:
- 자동 스캔
- API 불필요

**단점**:
- 실시간 스캔 불가
- 관리자 수동 스캔 불가

**권장**: Option A (API에서 동기 스캔) + Option C (정기 Cron)

**이유**:
1. 수동 스캔: API에서 단일 대시보드 동기 스캔 (관리자 테스트용)
2. 자동 스캔: Cron Job으로 전체 대시보드 정기 스캔
3. Edge Function은 오버엔지니어링 (프로토타입 단계)
4. 타임아웃 위험은 단일 대시보드 스캔에서 낮음

### [Question 8] 조치 실행 후 알림 전략

**선택지**:

**Option A: API에서 즉시 알림**
```typescript
// POST /api/moderation/reports/[id]/action
export async function POST(request: Request, { params }) {
  // 조치 실행
  await supabase.from('dashboard_reports').update({ status: 'deleted' })

  // 알림 발송
  await sendNotification(userId, '대시보드가 삭제되었습니다')

  return Response.json({ data: { success: true }, error: null })
}
```

**장점**:
- 즉시 알림

**단점**:
- API 응답 지연
- 알림 실패 시 조치 롤백 문제

**Option B: Database Trigger + Queue**
```sql
-- Supabase Trigger
CREATE TRIGGER notify_after_action
AFTER UPDATE ON dashboard_reports
FOR EACH ROW
WHEN (NEW.status != OLD.status)
EXECUTE FUNCTION enqueue_notification();
```

**장점**:
- API 응답 빠름
- 조치와 알림 분리

**단점**:
- Trigger 관리 필요
- Queue 인프라 필요

**Option C: 알림 없음 (ActivityLog만 기록)**
```typescript
// POST /api/moderation/reports/[id]/action
export async function POST(request: Request, { params }) {
  // 조치 실행
  await supabase.from('dashboard_reports').update({ status: 'deleted' })

  // ActivityLog 자동 기록 (Trigger)
  // 사용자는 ActivityLog에서 확인

  return Response.json({ data: { success: true }, error: null })
}
```

**장점**:
- API 간결
- 알림 인프라 불필요

**단점**:
- 사용자 경험 저하 (즉시 인지 불가)

**권장**: Option C (알림 없음, ActivityLog만 기록)

**이유**:
1. MVP 단계에서 알림 인프라 오버헤드 높음
2. ActivityLog로 조치 이력 확인 가능
3. 사용자는 대시보드 목록에서 삭제 확인 가능
4. 향후 알림 기능은 별도 Feature Module로 추가 가능

## 설계 단계 (6 Phase)

### Phase 1: 사전 조사 및 준비

- [x] AdminModerationContract 10개 메서드 분석
- [x] 각 메서드의 HTTP Method 매핑 (GET, POST, PATCH, DELETE)
- [x] Supabase 테이블 스키마 확인 (feature_module_design.md 참조)
- [x] 필요한 RLS Policy 목록 작성

### Phase 2: API Endpoint 설계

- [x] 10개 메서드를 13개 RESTful 엔드포인트로 매핑
- [x] Route 파일 구조 정의 (Resource 기반 Flat 구조)
- [x] Request/Response 타입 정의 (TypeScript + Zod - Request만)
- [x] Query Parameter 설계 (필터링, 페이지네이션, 정렬)

### Phase 3: Supabase 통합 설계

- [x] Supabase Client 생성 전략 (createServerClient)
- [x] RLS Policy 설계 (admin_only, hide_reporter)
- [x] Query 최적화 전략 (Explicit Field Selection, 인덱스, 신고자 수 집계)
- [x] 트랜잭션 처리 전략 (조치 실행 + ActivityLog 기록)

### Phase 4: Middleware 및 보안 설계

- [x] Next.js Middleware 설계 (인증 확인, Admin Console과 공유)
- [x] Supabase RLS 정책 설계 (권한 확인 + 신고자 익명성 보호)
- [x] CORS 설정 (apps/admin 전용)
- [x] Rate Limiting 전략 (선택적)

### Phase 5: 자동 탐지 및 알림 설계

- [x] 자동 탐지 스캔 전략 (동기 API + 정기 Cron)
- [x] 탐지 룰 정규표현식 검증 로직 (detectionRuleValidation.ts)
- [x] 조치 실행 후 처리 전략 (ActivityLog 기록, 알림 없음)
- [x] 에러 처리 및 로깅

### Phase 6: File Structure 및 문서 작성

- [x] apps/admin/app/api/moderation/ 디렉토리 구조 정의 (13개 route.ts)
- [x] 공통 유틸리티 파일 배치 (lib/services/ - detectionRuleValidation, violationSeverityCalculator)
- [x] bff_api_design.md 작성 (866 lines)
- [x] API 엔드포인트 목록 및 명세 작성 (13개 엔드포인트)
- [x] 다음 단계 (Supabase Schema + Cron Job 구현) 가이드 작성

## 다음 단계 (Implementation Phase)

설계 완료 후:

1. **Supabase Schema 구현**: 테이블, RLS Policy, 인덱스, Trigger 생성
2. **API Routes 구현**: apps/admin/app/api/moderation/ 파일 생성
3. **Middleware 구현**: middleware.ts 작성 (Admin Console과 공유)
4. **Cron Job 구현**: Supabase pg_cron으로 자동 탐지 스케줄링
5. **통합 테스트**: Feature Module (TanStack Query)과 BFF API 통합 테스트
6. **배포**: Vercel 배포 및 환경 변수 설정

## 산출물

- `docs/aidlc-docs/construction/admin-moderation/bff_api_design.md`
  - 10개 API 엔드포인트 명세 (REST 매핑)
  - Request/Response 타입 정의 (TypeScript + Zod)
  - Supabase Query 최적화 전략
  - RLS Policy 설계 (신고자 익명성 보호)
  - Middleware 설계 (Admin Console과 공유)
  - 자동 탐지 스캔 전략 (동기 API + Cron Job)
  - 조치 실행 후 처리 전략 (ActivityLog)
  - 에러 처리 전략
  - File Structure
  - 다음 단계 가이드
  - **코드 스니펫 제외** (설계 명세만)
