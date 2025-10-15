# Admin Console BFF API 설계 계획

## 개요

**Feature Module**: Admin Console
**책임**: BFF API Layer for Admin Console (US6.1~6.8)
**아키텍처**: Next.js 15 App Router API Routes + Supabase Direct + RLS

## 목표

Admin Console BFF API 설계 문서를 작성하여 다음을 달성합니다:

1. **Thin API Layer**: 비즈니스 로직 최소화, Supabase 직접 호출
2. **RESTful API**: 22개 AdminConsoleContract 메서드를 REST 엔드포인트로 매핑
3. **Type Safety**: TypeScript + Zod로 Request/Response 검증
4. **Security**: Supabase RLS + Middleware 기반 관리자 권한 검증
5. **Performance**: Supabase Query 최적화, 적절한 인덱싱 전략

## 포함된 사용자 스토리

### US6.1: 지표 관리

- 지표 목록 조회, 상세 조회, 생성, 수정, 삭제
- 카테고리별 필터링, 검색

### US6.2: 사용자 관리

- 사용자 목록 조회, 통계 조회
- 플랜 변경, 계정 정지/해제

### US6.3: 데이터 소스 관리

- 데이터 소스 목록 조회, 생성, 수정, 삭제
- 소스별 지표 개수 통계

### US6.4: 플랜 제한 관리

- 플랜 제한 목록 조회, 수정

### US6.5: 템플릿 관리

- 템플릿 목록 조회, 생성, 수정, 삭제, 복제

### US6.6: 카테고리 관리

- 카테고리 목록 조회, 생성, 수정, 삭제, 순서 변경

### US6.7: 커스텀 데이터 검증

- 업로드된 CSV 검증, 미리보기

### US6.8: 활동 로그 조회

- 관리자 활동 로그 조회, 필터링

## 아키텍처 질문 (사용자 승인 필요)

### [Question 1] API Route 경로 구조 전략

**선택지**:

**Option A: Resource 기반 Flat 구조**

```
apps/admin/app/api/
  indicators/
    route.ts              # GET /api/indicators (list), POST /api/indicators (create)
    [id]/route.ts         # GET /api/indicators/[id], PATCH, DELETE
  users/
    route.ts              # GET /api/users (list)
    [id]/route.ts         # GET /api/users/[id]
    [id]/plan/route.ts    # PATCH /api/users/[id]/plan
    [id]/suspend/route.ts # POST /api/users/[id]/suspend
  data-sources/
    route.ts              # GET /api/data-sources (list), POST
    [id]/route.ts         # GET, PATCH, DELETE
  plan-limits/
    route.ts              # GET /api/plan-limits (list)
    [id]/route.ts         # PATCH /api/plan-limits/[id]
  templates/
    route.ts              # GET, POST
    [id]/route.ts         # GET, PATCH, DELETE
    [id]/clone/route.ts   # POST /api/templates/[id]/clone
  categories/
    route.ts              # GET, POST
    [id]/route.ts         # GET, PATCH, DELETE
    reorder/route.ts      # POST /api/categories/reorder
  custom-data/
    validate/route.ts     # POST /api/custom-data/validate
  activity-logs/
    route.ts              # GET /api/activity-logs
```

**장점**:

- Next.js App Router 컨벤션과 일치
- RESTful 리소스 명확
- Auto-completion 지원 (파일 기반)

**단점**:

- 파일 개수 많음 (약 25개 route.ts)

**Option B: Feature 기반 Nested 구조**

```
apps/admin/app/api/admin/
  console/
    indicators/route.ts        # 모든 indicator API
    users/route.ts             # 모든 user API
    data-sources/route.ts      # 모든 data-source API
    plan-limits/route.ts
    templates/route.ts
    categories/route.ts
    custom-data/route.ts
    activity-logs/route.ts
```

**장점**:

- 파일 개수 적음 (8개 route.ts)
- Feature Module 구조와 일치

**단점**:

- 단일 route.ts에서 메서드 분기 필요
- RESTful 서브 리소스 처리 복잡 (예: `/users/[id]/plan`)

**권장**: Option A (Resource 기반 Flat 구조)

**이유**:

1. Next.js 15 App Router 공식 권장 패턴
2. RESTful API 의미론과 일치
3. 서브 리소스 처리 간단 (`[id]/plan/route.ts`)
4. 파일 개수는 많지만 각 파일 복잡도 낮음

### [Question 2] Supabase Client 전략

**선택지**:

**Option A: Server Component Client (createServerClient)**

```typescript
// 각 route.ts에서
import { createServerClient } from '@/lib/supabase/server'

export async function GET() {
  const supabase = createServerClient()
  const { data } = await supabase.from('indicators').select('*')
  return Response.json(data)
}
```

**장점**:

- Next.js App Router 서버 컴포넌트 패턴
- 쿠키 기반 세션 자동 처리

**단점**:

- 각 route.ts에서 반복 생성

**Option B: Singleton Service Client**

```typescript
// lib/supabase/service.ts
export const supabaseServiceClient = createClient(url, serviceKey)

// route.ts에서
import { supabaseServiceClient } from '@/lib/supabase/service'
```

**장점**:

- 단일 클라이언트 재사용

**단점**:

- RLS 우회 (service role key)
- 보안 위험

**권장**: Option A (Server Component Client)

**이유**:

1. Supabase RLS 활용 (사용자별 권한 검증)
2. 쿠키 기반 세션 자동 처리
3. Next.js App Router 공식 패턴
4. Service Role Key는 Admin 작업에도 RLS 우회 방지

### [Question 3] Middleware 권한 검증 전략

**선택지**:

**Option A: Route-level Middleware**

```typescript
// app/api/indicators/route.ts
export async function GET(request: Request) {
  const user = await verifyAdmin(request) // 각 route에서 호출
  if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 })

  const supabase = createServerClient()
  // ...
}
```

**장점**:

- 명시적 권한 검증
- Route별 커스텀 가능

**단점**:

- 모든 route.ts에서 반복 코드

**Option B: Next.js Middleware (middleware.ts)**

```typescript
// middleware.ts
export async function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith('/api/')) {
    const user = await verifyAdmin(request)
    if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }
  return NextResponse.next()
}

export const config = {
  matcher: '/api/:path*'
}
```

**장점**:

- 중앙 집중식 권한 검증
- Route 코드 간결

**단점**:

- Edge Runtime 제약 (일부 Node.js API 미지원)

**Option C: Hybrid (Middleware + Supabase RLS)**

```typescript
// middleware.ts - 기본 인증 확인
export async function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith('/api/')) {
    const session = await getSession(request)
    if (!session) return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }
  return NextResponse.next()
}

// Supabase RLS - 관리자 권한 확인
CREATE POLICY admin_only ON indicators
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
```

**장점**:

- Middleware: 인증 확인 (빠른 실패)
- Supabase RLS: 권한 확인 (DB 레벨 보안)
- Route 코드 최소화

**단점**:

- 두 레벨 검증 (약간의 오버헤드)

**권장**: Option C (Hybrid)

**이유**:

1. Defense in Depth (다층 보안)
2. Middleware: 인증되지 않은 요청 빠르게 차단
3. RLS: DB 레벨에서 관리자 권한 확인
4. Route 코드 간결 (인증/권한 로직 제거)

### [Question 4] API Response 에러 처리 전략

**선택지**:

**Option A: HTTP Status Code Only**

```typescript
// 성공
return Response.json(data, { status: 200 })

// 에러
return Response.json({ error: 'Not found' }, { status: 404 })
```

**장점**:

- 간단한 구조

**단점**:

- 에러 상세 정보 부족
- 프론트엔드 에러 핸들링 어려움

**Option B: Structured Error Response**

```typescript
// 성공
return Response.json({ data, error: null }, { status: 200 })

// 에러
return Response.json({
  data: null,
  error: {
    code: 'INDICATOR_NOT_FOUND',
    message: 'Indicator not found',
    details: { indicatorId: '123' }
  }
}, { status: 404 })
```

**장점**:

- 에러 코드로 프론트엔드 처리 가능
- 상세 정보 제공

**단점**:

- 응답 구조 복잡

**Option C: Zod + HTTP Status**

```typescript
// Response Schema
const ApiResponseSchema = z.object({
  data: z.unknown().nullable(),
  error: z.object({
    code: z.string(),
    message: z.string(),
    details: z.record(z.unknown()).optional()
  }).nullable()
})

// 사용
return Response.json(
  ApiResponseSchema.parse({ data: indicator, error: null }),
  { status: 200 }
)
```

**장점**:

- 타입 안전성 + 런타임 검증
- 일관된 응답 구조

**단점**:

- Zod 검증 오버헤드

**권장**: Option C (Zod + HTTP Status)

**이유**:

1. 타입 안전성 (프론트엔드 TanStack Query와 통합)
2. 런타임 검증 (잘못된 응답 방지)
3. 에러 코드 기반 처리 가능
4. 일관된 API 인터페이스

### [Question 5] Supabase Query 최적화 전략

**선택지**:

**Option A: Select All Fields**

```typescript
const { data } = await supabase.from('indicators').select('*')
```

**장점**:

- 간단한 쿼리

**단점**:

- 불필요한 데이터 전송
- 네트워크 오버헤드

**Option B: Explicit Field Selection**

```typescript
const { data } = await supabase
  .from('indicators')
  .select('id, name, category_id, created_at')
```

**장점**:

- 필요한 필드만 조회
- 네트워크 최적화

**단점**:

- 쿼리 코드 길어짐

**Option C: View + Select All**

```sql
-- Supabase View
CREATE VIEW indicators_list AS
SELECT id, name, category_id, created_at, updated_at
FROM indicators;
```

```typescript
const { data } = await supabase.from('indicators_list').select('*')
```

**장점**:

- DB 레벨 필드 제한
- 코드 간결

**단점**:

- View 관리 필요

**권장**: Option B (Explicit Field Selection)

**이유**:

1. 명시적 필드 선택 (코드 가독성)
2. 네트워크 최적화 (모바일 환경 고려)
3. View는 복잡한 조인에만 사용
4. API별로 필요한 필드 다를 수 있음

## 설계 단계 (6 Phase)

### Phase 1: 사전 조사 및 준비

- [x] AdminConsoleContract 39개 메서드 분석
- [x] 각 메서드의 HTTP Method 매핑 (GET, POST, PATCH, DELETE)
- [x] Supabase 테이블 스키마 확인 (feature_module_design.md 참조)
- [x] 필요한 RLS Policy 목록 작성

### Phase 2: API Endpoint 설계

- [x] 39개 메서드를 42개 RESTful 엔드포인트로 매핑
- [x] Route 파일 구조 정의 (Resource 기반 Flat 구조)
- [x] Request/Response 타입 정의 (TypeScript + Zod - Request만)
- [x] Query Parameter 설계 (필터링, 페이지네이션, 정렬)

### Phase 3: Supabase 통합 설계

- [x] Supabase Client 생성 전략 (createServerClient)
- [x] RLS Policy 설계 (admin_only)
- [x] Query 최적화 전략 (Explicit Field Selection, 인덱스)
- [x] 트랜잭션 처리 전략 (multi-step operations)

### Phase 4: Middleware 및 보안 설계

- [x] Next.js Middleware 설계 (인증 확인)
- [x] Supabase RLS 정책 설계 (권한 확인)
- [x] CORS 설정 (apps/admin 전용)
- [x] Rate Limiting 전략 (선택적)

### Phase 5: 에러 처리 및 로깅 설계

- [x] Structured Error Response 스키마 (TypeScript 타입)
- [x] 에러 코드 정의 (INDICATOR_NOT_FOUND, UNAUTHORIZED 등)
- [x] ActivityLog 자동 기록 전략
- [x] 에러 로깅 전략 (Supabase Edge Functions Log 또는 외부 서비스)

### Phase 6: File Structure 및 문서 작성

- [x] apps/admin/app/api/ 디렉토리 구조 정의 (42개 route.ts)
- [x] 공통 유틸리티 파일 배치 (lib/api/, lib/supabase/, lib/services/)
- [x] bff_api_design.md 작성 (1,592 lines)
- [x] API 엔드포인트 목록 및 명세 작성 (42개 엔드포인트)
- [x] 다음 단계 (Supabase Schema 구현) 가이드 작성

## 다음 단계 (Implementation Phase)

설계 완료 후:

1. **Supabase Schema 구현**: 테이블, RLS Policy, 인덱스 생성
2. **API Routes 구현**: apps/admin/app/api/ 파일 생성
3. **Middleware 구현**: middleware.ts 작성
4. **통합 테스트**: Feature Module (TanStack Query)과 BFF API 통합 테스트
5. **배포**: Vercel 배포 및 환경 변수 설정

## 산출물

- `docs/aidlc-docs/construction/admin-console/bff_api_design.md`
  - 22개 API 엔드포인트 명세 (REST 매핑)
  - Request/Response 타입 정의 (TypeScript + Zod)
  - Supabase Query 최적화 전략
  - RLS Policy 설계
  - Middleware 설계
  - 에러 처리 전략
  - File Structure
  - 다음 단계 가이드
  - **코드 스니펫 제외** (설계 명세만)
