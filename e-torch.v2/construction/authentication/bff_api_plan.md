# Authentication BFF API 설계 계획

## 목표
Authentication Feature Module의 BFF (Backend-for-Frontend) API를 설계합니다.

## BFF API 설계 원칙
- **Thin API Layer**: 비즈니스 로직 최소화, Supabase 호출 래핑만
- **Repository 패턴 미사용**: Supabase SDK 직접 호출
- **RESTful API 설계**: 표준 HTTP Method (GET, POST, PATCH, DELETE) 사용
- **Supabase RLS 활용**: 데이터베이스 레벨 권한 제어

## 설계 단계

### Phase 1: API 엔드포인트 설계

#### [ ] 1.1 인증 관련 엔드포인트

**로그인 (OAuth):**
- Endpoint: `POST /api/auth/signin/:provider`
- Provider: google | kakao
- Request: Query params `?redirectTo=/dashboards`
- Response: OAuth URL
- Supabase 호출: `supabase.auth.signInWithOAuth()`

[Question 1.1] OAuth 로그인 외에 추가로 지원해야 할 인증 방식이 있나요? (예: email/password, magic link)

[Answer]
**선택지:**

**Option A: OAuth만 (Google, Kakao)**
- 장점: 구현 단순, OAuth Provider가 보안 처리, 빠른 출시
- 단점: 사용자 선택권 제한, OAuth 의존성

**Option B: OAuth + Email/Password**
- 장점: 사용자 선택권 확대, OAuth 장애 시 대안
- 단점: 복잡도 증가, 비밀번호 관리 필요, Rate Limiting 필요

**Option C: OAuth + Magic Link**
- 장점: 비밀번호 불필요, 보안성 우수
- 단점: 이메일 전송 인프라 필요, 사용자 익숙하지 않을 수 있음

**Option D: 모두 지원**
- 장점: 최대 유연성
- 단점: 구현 복잡도 매우 높음, 유지보수 부담

**권장안: Option A (OAuth만)**
- Inception 문서에서 OAuth만 명시됨 (US1.1)
- 초기 MVP는 OAuth만으로 충분
- 향후 사용자 피드백 기반 추가 고려
- email/password는 Phase 2 확장 기능으로 설계 가능


**로그아웃:**
- Endpoint: `POST /api/auth/signout`
- Request: 없음 (세션 기반)
- Response: Success 여부
- Supabase 호출: `supabase.auth.signOut()`

**OAuth 콜백 처리:**
- Endpoint: `GET /api/auth/callback`
- Request: Query params (code, state from OAuth provider)
- Response: Redirect to app
- Supabase 호출: `supabase.auth.exchangeCodeForSession()`
- 추가 처리: public.users status 확인 → inactive면 로그아웃

[Question 1.2] OAuth 콜백 후 리다이렉트할 기본 경로는 어디인가요? (예: /dashboards, /profile)

[Answer]
**선택지:**

**Option A: /dashboards (대시보드 메인)**
- 장점: 핵심 기능으로 바로 진입, 사용자 목적 직접 달성
- 단점: 신규 사용자에게 overwhelming할 수 있음
- 적합: 대부분 사용자가 대시보드 조회 목적인 경우

**Option B: /profile (프로필 설정)**
- 장점: 프로필 완성 유도, 온보딩 기회
- 단점: 사용자가 원하는 기능으로 가기까지 추가 단계
- 적합: 프로필 정보가 필수인 경우

**Option C: / (홈/랜딩 페이지)**
- 장점: 서비스 소개 및 안내 가능
- 단점: 추가 클릭 필요
- 적합: 인증 후 추가 설명이 필요한 경우

**Option D: 동적 결정 (신규/기존 사용자 구분)**
- 장점: 최적화된 UX
- 단점: 구현 복잡도 증가
- 적합: 정교한 온보딩 플로우가 필요한 경우

**권장안: Option A (/dashboards)**
- E-Torch의 핵심 기능은 대시보드
- 로그인 목적 = 대시보드 사용
- 간단하고 명확한 UX
- redirectTo 파라미터로 유연성 확보 (예: /login?redirect=/profile)


**세션 갱신:**
- Endpoint: `POST /api/auth/refresh`
- Request: 없음 (Refresh Token은 Supabase가 자동 관리)
- Response: 새 Session
- Supabase 호출: `supabase.auth.refreshSession()`

[Question 1.3] 세션 갱신 엔드포인트를 명시적으로 제공해야 하나요, 아니면 Supabase의 자동 갱신에만 의존해도 되나요?

[Answer]
**선택지:**

**Option A: Supabase 자동 갱신만 사용**
- 장점: 구현 불필요, Supabase가 자동 처리, 클라이언트 측 투명
- 단점: 수동 갱신 불가 (특정 시나리오에서 필요할 수 있음)
- 동작: Supabase SDK가 만료 60초 전 자동 갱신

**Option B: 명시적 엔드포인트 제공**
- 장점: 수동 제어 가능, 디버깅 용이, 특정 상황 대응
- 단점: 추가 구현 필요, 대부분의 경우 사용되지 않음
- 사용 사례: 토큰 만료 직전 중요 작업, 테스트

**Option C: 혼합 (자동 + 수동 옵션)**
- 장점: 유연성 최대
- 단점: 복잡도 증가, 오용 가능성

**권장안: Option A (Supabase 자동 갱신만)**
- Supabase의 자동 갱신이 충분히 안정적
- 대부분의 사용 사례 커버
- 초기 구현 단순화
- 필요 시 향후 추가 가능 (YAGNI 원칙)


#### [ ] 1.2 사용자 정보 관련 엔드포인트

**현재 사용자 조회:**
- Endpoint: `GET /api/auth/user`
- Request: 없음 (세션 기반)
- Response: User 객체 (public.users)
- Supabase 호출:
  1. `supabase.auth.getUser()` → auth.users
  2. `supabase.from('users').select('*').eq('id', userId).single()` → public.users
- RLS 정책: 자신의 정보만 조회 가능

**프로필 수정:**
- Endpoint: `PATCH /api/auth/profile`
- Request Body: `{ name?: string, avatar?: string }`
- Response: 업데이트된 User 객체
- Supabase 호출: `supabase.from('users').update(data).eq('id', userId)`
- 검증: Zod Schema (UpdateProfileSchema)
- RLS 정책: 자신의 정보만 수정 가능

[Question 1.4] 프로필 수정 시 검증해야 할 추가 규칙이 있나요? (예: 이름 최소/최대 길이, avatar URL 형식)

[Answer]
**선택지:**

**Option A: 최소 검증 (타입만)**
- name: string (선택)
- avatar: string (선택)
- 장점: 유연성 높음, 구현 단순
- 단점: 잘못된 데이터 입력 가능

**Option B: 기본 검증 (타입 + 형식)**
- name: 1-100자, 트림, 빈 문자열 불가
- avatar: HTTPS URL, 최대 2048자
- 장점: 기본적인 데이터 품질 보장
- 단점: 제약이 너무 약할 수 있음

**Option C: 엄격한 검증 (타입 + 형식 + 비즈니스 규칙)**
- name: 1-100자, 한글/영문/숫자만, 특수문자 제한, 금지어 필터
- avatar: HTTPS URL, 화이트리스트 도메인만, 이미지 확장자 확인, 파일 크기 제한
- 장점: 데이터 품질 최상
- 단점: 구현 복잡, 사용자 불편, 유지보수 부담

**Option D: 점진적 검증 (기본 → 엄격)**
- Phase 1: 기본 검증 (Option B)
- Phase 2: 사용자 피드백 기반 추가 규칙
- 장점: 균형적 접근
- 단점: 초기 규칙이 변경될 수 있음

**권장안: Option B (기본 검증)**
- name: z.string().min(1).max(100).trim()
- avatar: z.string().url().startsWith('https://').max(2048)
- Integration Contract와 일치
- 충분한 데이터 품질 보장
- 구현 단순, 유지보수 용이
- XSS 방지 (HTTPS only)


#### [ ] 1.3 SNS 계정 연결 관리 엔드포인트

**SNS 계정 연결:**
- Endpoint: `POST /api/auth/link/:provider`
- Provider: google | kakao
- Request: 없음
- Response: OAuth URL (연결용)
- Supabase 호출: `supabase.auth.linkIdentity({ provider })`

[Question 1.5] 이미 다른 사용자가 사용 중인 SNS 계정을 연결하려고 할 때 어떻게 처리해야 하나요?

[Answer]
**선택지:**

**Option A: 에러 반환 (계정 연결 불가)**
- 동작: "이미 다른 계정에 연결된 SNS 계정입니다" 에러
- 장점: 간단하고 명확, 데이터 무결성 보장, 보안 위험 최소
- 단점: 사용자가 직접 기존 계정에서 연결 해제 필요
- 적합: 보안 우선, 계정 충돌 방지

**Option B: 기존 계정과 통합 (병합)**
- 동작: 두 계정의 데이터를 병합하여 하나로 통합
- 장점: 사용자 편의성 최고, 데이터 손실 없음
- 단점: 구현 매우 복잡, 데이터 충돌 처리 어려움, 보안 위험 (악의적 병합)
- 적합: 사용자 데이터가 매우 중요하고 복잡한 경우

**Option C: 현재 계정에서 기존 연결 해제 후 재연결**
- 동작: 자동으로 기존 계정 연결 해제 → 현재 계정 연결
- 장점: 자동화된 편의성
- 단점: 기존 계정 소유자가 의도하지 않은 연결 해제 당함 (보안 문제)
- 적합: 단일 사용자 환경 (권장하지 않음)

**Option D: 사용자에게 선택권 제공**
- 동작: 에러와 함께 "기존 계정으로 전환하시겠습니까?" 옵션
- 장점: 사용자 제어권 부여
- 단점: UX 복잡, 구현 복잡
- 적합: B2C 서비스

**권장안: Option A (에러 반환)**
- Supabase의 기본 동작과 일치
- 보안 우선 (다른 사용자의 SNS 계정 탈취 방지)
- 구현 단순 (Supabase가 자동 처리)
- 명확한 에러 메시지로 사용자 가이드
- Integration Contract에서 명시된 정책: "같은 이메일 자동 통합 (OAuth 시)" - 연결은 수동이므로 에러 처리가 적절


**SNS 계정 연결 해제:**
- Endpoint: `DELETE /api/auth/link/:provider`
- Provider: google | kakao
- Request: 없음
- Response: Success 여부
- Supabase 호출: `supabase.auth.unlinkIdentity({ identityId })`
- 제약사항: 마지막 연결 계정은 해제 불가

[Question 1.6] 마지막 연결 계정 해제 시도 시 어떤 에러 메시지를 제공해야 하나요?

[Answer]
**선택지:**

**Option A: 간단한 메시지**
- "마지막 연결 계정은 해제할 수 없습니다"
- 장점: 짧고 명확
- 단점: 이유 불명확, 해결 방법 없음

**Option B: 설명 포함**
- "계정 접근을 위해 최소 1개의 SNS 연결이 필요합니다. 다른 SNS를 먼저 연결한 후 해제해주세요"
- 장점: 이유 명확, 해결 방법 제시
- 단점: 다소 김

**Option C: 기술적 메시지**
- "AUTH_CANNOT_UNLINK_LAST_PROVIDER: Last identity cannot be unlinked"
- 장점: 에러 코드 명확
- 단점: 사용자 친화적이지 않음

**Option D: 단계별 가이드**
- "마지막 연결 계정입니다. 해제하려면: 1) 다른 SNS 계정 연결 → 2) 이 계정 해제"
- 장점: 구체적 가이드
- 단점: 너무 상세함

**권장안: Option B (설명 포함)**
- 에러 코드: `AUTH_CANNOT_UNLINK_LAST_PROVIDER`
- 사용자 메시지: "계정 접근을 위해 최소 1개의 SNS 연결이 필요합니다. 다른 SNS를 먼저 연결한 후 해제해주세요"
- 개발자용 details: `{ currentProviders: ['google'], minRequired: 1 }`
- 이유와 해결 방법 모두 제공


**연결된 SNS 계정 목록 조회:**
- Endpoint: `GET /api/auth/linked-providers`
- Request: 없음
- Response: `{ providers: ['google', 'kakao'] }`
- Supabase 호출: `supabase.auth.getUser()` → identities 파싱

#### [ ] 1.4 관리자 전용 엔드포인트

**계정 활성화 (Admin):**
- Endpoint: `POST /api/auth/activate/:userId`
- Request Body: `{ reason?: string }`
- Response: 업데이트된 User
- Supabase 호출: `supabase.from('users').update({ status: 'active' }).eq('id', userId)`
- 권한 검증: 현재 사용자가 admin인지 확인
- RLS 정책: Admin만 수정 가능

**계정 비활성화 (Admin):**
- Endpoint: `POST /api/auth/deactivate/:userId`
- Request Body: `{ reason: string }`
- Response: 업데이트된 User
- Supabase 호출: `supabase.from('users').update({ status: 'inactive' }).eq('id', userId)`
- 권한 검증: 현재 사용자가 admin인지 확인
- RLS 정책: Admin만 수정 가능

[Question 1.7] Admin 전용 엔드포인트에 추가로 필요한 기능이 있나요? (예: 사용자 목록 조회, 역할 변경, 로그 조회)

[Answer]
**선택지:**

**Option A: 현재 기능만 (활성화/비활성화)**
- 장점: 단순, 초기 필수 기능만
- 단점: Admin 기능 제한적

**Option B: 사용자 관리 기능 추가**
- 추가 엔드포인트:
  - `GET /api/auth/users` (목록 조회, 페이지네이션, 필터)
  - `GET /api/auth/users/:userId` (특정 사용자 조회)
  - `PATCH /api/auth/users/:userId/role` (역할 변경)
- 장점: 완전한 사용자 관리
- 단점: 구현 복잡도 증가

**Option C: 로그 및 모니터링 추가**
- 추가 엔드포인트:
  - `GET /api/auth/audit-logs` (로그인 이력, 변경 이력)
  - `GET /api/auth/stats` (통계)
- 장점: 감사 추적, 모니터링
- 단점: 추가 데이터베이스 테이블 필요

**Option D: Admin Console Feature Module로 분리**
- Admin 기능을 별도 Feature Module로 구현
- 장점: 관심사 분리, 확장성 좋음
- 단점: 초기 구조 복잡

**권장안: Option A (현재 기능만) + 향후 Option D**
- 초기: 활성화/비활성화만 (US6.3 - 사용자 상태 관리)
- Authentication은 기본 인증 기능에만 집중
- 향후: Admin Console Feature Module 설계 시 사용자 관리 기능 추가
- 이유: Feature Module 책임 분리 원칙, YAGNI


### Phase 2: API 응답 형식 표준화

#### [ ] 2.1 성공 응답 형식

```typescript
{
  success: true,
  data: T
}
```

HTTP Status: 200 OK (조회), 201 Created (생성)

#### [ ] 2.2 에러 응답 형식

```typescript
{
  success: false,
  error: {
    code: string,        // 예: "AUTH_UNAUTHORIZED"
    message: string,     // 사용자 친화적 메시지
    details?: any        // 개발자용 상세 정보 (선택)
  }
}
```

HTTP Status: 400 Bad Request, 401 Unauthorized, 403 Forbidden, 500 Internal Server Error

[Question 2.1] 에러 코드 네이밍 컨벤션은 어떻게 하시겠습니까?

[Answer]
**선택지:**

**Option A: 모듈 Prefix (AUTH_UNAUTHORIZED)**
- 형식: `{MODULE}_{ERROR_TYPE}`
- 예: `AUTH_UNAUTHORIZED`, `AUTH_INVALID_INPUT`, `DASHBOARD_NOT_FOUND`
- 장점: 에러 출처 명확, 모듈 간 충돌 방지, 검색 용이
- 단점: 코드 다소 김

**Option B: Prefix 없음 (UNAUTHORIZED)**
- 형식: `{ERROR_TYPE}`
- 예: `UNAUTHORIZED`, `INVALID_INPUT`, `NOT_FOUND`
- 장점: 짧고 간결
- 단점: 모듈 간 충돌 가능, 출처 불명확

**Option C: Colon 구분 (auth:unauthorized)**
- 형식: `{module}:{error_type}`
- 예: `auth:unauthorized`, `dashboard:not_found`
- 장점: 네임스페이스 명확, 사람이 읽기 편함
- 단점: JavaScript 상수 네이밍 컨벤션과 불일치, 소문자

**Option D: 혼합 (공통은 Prefix 없음, 모듈별은 Prefix)**
- 공통: `UNAUTHORIZED`, `INTERNAL_ERROR`
- 모듈별: `AUTH_ACCOUNT_INACTIVE`, `DASHBOARD_NOT_FOUND`
- 장점: 유연성
- 단점: 일관성 부족, 기준 모호

**권장안: Option A (모듈 Prefix)**
- `AUTH_UNAUTHORIZED`, `AUTH_VALIDATION_ERROR`, `DATABASE_ERROR`
- 마이크로서비스/Feature Module 아키텍처에 적합
- 에러 로깅/모니터링 시 필터링 용이
- TypeScript 상수 네이밍 컨벤션 (UPPER_SNAKE_CASE)과 일치
- 다른 Feature Module과 일관성 유지 가능


#### [ ] 2.3 에러 코드 정의

**인증 에러:**
- `AUTH_UNAUTHORIZED`: 인증이 필요합니다
- `AUTH_FORBIDDEN`: 권한이 없습니다
- `AUTH_SESSION_EXPIRED`: 세션이 만료되었습니다
- `AUTH_ACCOUNT_INACTIVE`: 비활성화된 계정입니다

**OAuth 에러:**
- `AUTH_OAUTH_ERROR`: OAuth 인증 실패
- `AUTH_INVALID_PROVIDER`: 지원하지 않는 Provider입니다
- `AUTH_OAUTH_CALLBACK_ERROR`: OAuth 콜백 처리 실패

**계정 연결 에러:**
- `AUTH_PROVIDER_ALREADY_LINKED`: 이미 연결된 계정입니다
- `AUTH_PROVIDER_NOT_LINKED`: 연결되지 않은 계정입니다
- `AUTH_CANNOT_UNLINK_LAST_PROVIDER`: 마지막 연결 계정은 해제할 수 없습니다

**검증 에러:**
- `AUTH_VALIDATION_ERROR`: 입력값이 올바르지 않습니다
- `AUTH_INVALID_INPUT`: 유효하지 않은 입력입니다

**서버 에러:**
- `DATABASE_ERROR`: 데이터베이스 오류
- `NETWORK_ERROR`: 네트워크 오류
- `INTERNAL_ERROR`: 서버 내부 오류

[Question 2.2] 추가로 정의해야 할 에러 코드가 있나요?

[Answer]
**검토 관점:**

**현재 정의된 에러 코드 (23개):**
- 인증: 4개
- OAuth: 3개
- 계정 연결: 3개
- 검증: 2개
- 서버: 3개

**추가 고려 에러 코드:**

**Option A: 현재 코드만으로 충분**
- 장점: 단순, 대부분 케이스 커버
- 단점: 특수 상황 처리 제한적

**Option B: 세분화된 에러 추가**
- `AUTH_USER_NOT_FOUND`: 사용자 없음
- `AUTH_EMAIL_NOT_VERIFIED`: 이메일 미인증 (향후)
- `AUTH_TOKEN_EXPIRED`: 토큰 만료 (SESSION_EXPIRED와 유사)
- `AUTH_INVALID_TOKEN`: 잘못된 토큰
- `AUTH_RATE_LIMIT_EXCEEDED`: Rate Limit 초과 (향후)
- 장점: 세밀한 에러 처리
- 단점: 관리 복잡도 증가

**Option C: OAuth 세분화**
- `AUTH_OAUTH_GOOGLE_ERROR`: Google 특정 에러
- `AUTH_OAUTH_KAKAO_ERROR`: Kakao 특정 에러
- 장점: Provider별 대응 가능
- 단점: Provider 추가 시 에러 코드 증가

**권장안: Option A (현재 코드 유지)**
- 현재 23개 코드로 초기 요구사항 충분히 커버
- 필요 시 점진적 추가 가능
- YAGNI 원칙
- 단, 향후 추가 고려:
  - `AUTH_USER_NOT_FOUND` (사용자 조회 실패 시)
  - `AUTH_RATE_LIMIT_EXCEEDED` (Rate Limiting 추가 시)


### Phase 3: Supabase 쿼리 최적화

#### [ ] 3.1 RLS (Row Level Security) 정책 설계

**public.users 테이블 RLS 정책:**

1. **사용자 자신의 프로필 조회:**
   ```sql
   CREATE POLICY "Users can view their own profile"
     ON public.users FOR SELECT
     USING (auth.uid() = id);
   ```

2. **사용자 자신의 프로필 수정:**
   ```sql
   CREATE POLICY "Users can update their own profile"
     ON public.users FOR UPDATE
     USING (auth.uid() = id);
   ```

3. **관리자는 모든 사용자 조회:**
   ```sql
   CREATE POLICY "Admins can view all users"
     ON public.users FOR SELECT
     USING (
       EXISTS (
         SELECT 1 FROM public.users
         WHERE id = auth.uid() AND role = 'admin'
       )
     );
   ```

4. **관리자는 모든 사용자 수정:**
   ```sql
   CREATE POLICY "Admins can update all users"
     ON public.users FOR UPDATE
     USING (
       EXISTS (
         SELECT 1 FROM public.users
         WHERE id = auth.uid() AND role = 'admin'
       )
     );
   ```

[Question 3.1] RLS 정책에 추가로 필요한 권한 규칙이 있나요? (예: 특정 필드만 수정 가능, 삭제 정책)

[Answer]
**선택지:**

**Option A: 현재 정책만 (SELECT, UPDATE)**
- 4개 정책: 본인 조회/수정, Admin 전체 조회/수정
- 장점: 단순, 필수 기능만
- 단점: 추가 시나리오 대응 제한적

**Option B: 필드별 제한 추가**
- role, status 필드는 Admin만 수정 가능
- 일반 사용자는 name, avatar만 수정
- 장점: 세밀한 권한 제어
- 단점: PostgreSQL RLS로 필드별 제한 구현 어려움

**Option C: 삭제 정책 추가**
- `DELETE` 정책: Admin만 사용자 삭제 가능
- 또는 Soft Delete (status = 'deleted')
- 장점: 완전한 CRUD
- 단점: 사용자 삭제가 필요한지 불명확

**Option D: INSERT 정책 추가**
- Trigger가 처리하므로 일반적으로 불필요
- 특수 케이스: 관리자가 사용자 수동 생성
- 장점: 관리자 기능 확장
- 단점: 복잡도 증가

**권장안: Option A (현재 정책 유지)**
- 현재 4개 정책으로 충분
- 필드별 제한은 Application Layer에서 처리 (Zod Schema)
  - UpdateProfileSchema는 name, avatar만 허용
  - role, status 수정은 별도 Admin API
- 삭제는 Soft Delete (status = 'inactive') 사용
- INSERT는 Trigger가 자동 처리
- RLS는 Row 레벨 접근 제어에만 집중


#### [ ] 3.2 데이터베이스 인덱스 설계

**public.users 테이블 인덱스:**
- `idx_users_email`: email 컬럼 (검색 최적화)
- `idx_users_role`: role 컬럼 (Admin 필터링)
- `idx_users_status`: status 컬럼 (Active/Inactive 필터링)

[Question 3.2] 사용자 목록을 자주 조회하나요? 조회 시 어떤 필터/정렬을 사용하나요?

[Answer]
**현재 설계 상황:**
- 사용자 목록 조회 API 없음 (Question 1.7에서 Admin Console로 분리 결정)
- 현재 Authentication API는 개별 사용자 조회만 (GET /api/auth/user)

**선택지:**

**Option A: 인덱스 최소화 (현재 설계 기준)**
- 필수 인덱스만: email, role, status
- 장점: 단순, 현재 요구사항 충족
- 적합: 사용자 목록 API가 없는 현재 설계

**Option B: 향후 확장 대비 인덱스**
- 추가: created_at, updated_at, (email, status) 복합 인덱스
- 장점: Admin Console 추가 시 준비 완료
- 단점: 사용하지 않는 인덱스 유지 비용

**권장안: Option A (현재 설계 기준)**
- 인덱스: email, role, status만 유지
- 이유: YAGNI, 인덱스는 필요 시 추가 가능
- Admin Console Feature Module 설계 시 재검토


#### [ ] 3.3 쿼리 최적화 전략

**N+1 문제 방지:**
- auth.users와 public.users를 별도로 조회하지 않고 한 번에 조회
- 예: `/api/auth/user`에서 auth.getUser() → public.users 조인 없이 별도 조회 (Supabase 제약)

**페이지네이션:**
- 관리자 사용자 목록 조회 시 페이지네이션 적용
- `limit`, `offset` 또는 `cursor-based pagination` 사용

[Question 3.3] 사용자 목록 페이지네이션 방식은?

[Answer]
**현재 상황:**
- 사용자 목록 API 없음 (Admin Console로 분리)
- 현재는 결정 불필요

**향후 Admin Console 설계 시 참고:**

**Option A: Offset-based (limit + offset)**
- 구현: `?page=2&limit=20` → `OFFSET 20 LIMIT 20`
- 장점: 구현 단순, 페이지 번호 표시 가능
- 단점: 대량 데이터 시 성능 저하, 데이터 변경 시 중복/누락 가능

**Option B: Cursor-based (created_at 기준)**
- 구현: `?cursor=2024-01-01T00:00:00Z&limit=20`
- 장점: 대량 데이터 성능 우수, 실시간 데이터 변경 대응
- 단점: 페이지 번호 없음, 구현 복잡

**Option C: 페이지네이션 없음**
- 모든 데이터 한 번에 반환
- 장점: 구현 단순
- 단점: 사용자 많아지면 성능 문제

**권장안: 현재는 N/A, 향후 Option B (Cursor-based)**
- 현재 설계에서는 결정 불필요
- Admin Console 설계 시 Cursor-based 권장
- 이유: 확장성, 성능, Supabase 권장 방식


**Select 최적화:**
- 필요한 필드만 조회
- 예: `select('id, email, name, role, status')` (avatar 제외 가능)

#### [ ] 3.4 Trigger 및 Function 설계

**auth.users → public.users 자동 생성 Trigger:**
```sql
CREATE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role, status)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    -- Master Admin 이메일이면 admin, 아니면 user
    CASE WHEN NEW.email = current_setting('app.settings.master_admin_email', true)
      THEN 'admin' ELSE 'user' END,
    'active'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

[Question 3.4] Master Admin 이메일을 설정할 환경 변수가 있나요? 아니면 첫 번째 사용자를 자동으로 Admin으로 설정하나요?

[Answer]
**선택지:**

**Option A: 환경 변수로 Master Admin 지정**
- 환경 변수: `MASTER_ADMIN_EMAIL=admin@example.com`
- Trigger에서 이메일 비교하여 role 설정
- 장점: 명확한 Admin 지정, 보안성 높음
- 단점: 환경 변수 관리 필요

**Option B: 첫 번째 사용자 자동 Admin**
- 첫 가입자를 자동으로 admin 설정
- 장점: 설정 불필요, 간편
- 단점: 보안 위험 (먼저 가입하는 사람이 Admin)

**Option C: Supabase Dashboard에서 수동 설정**
- 초기에는 모두 user로 생성
- Admin이 Dashboard에서 수동으로 role 변경
- 장점: 보안성 최고
- 단점: 수동 작업 필요

**Option D: 마이그레이션 스크립트로 Admin 생성**
- 초기 배포 시 마이그레이션 스크립트로 Admin 계정 생성
- 장점: 자동화, 재현 가능
- 단점: 초기 설정 필요

**권장안: Option A (환경 변수)**
- 환경 변수: `MASTER_ADMIN_EMAIL`
- Trigger에서 확인: `NEW.email = current_setting('app.settings.master_admin_email', true)`
- 장점:
  - 명확한 Admin 지정
  - 환경별 다른 Admin 설정 가능 (dev/staging/prod)
  - 보안성 우수
- 구현: Supabase Dashboard의 Custom Config 또는 환경 변수 사용


**updated_at 자동 업데이트 Trigger:**
```sql
CREATE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Phase 4: 미들웨어 설계

#### [ ] 4.1 인증 미들웨어 (Middleware)

**apps/web/middleware.ts:**

**역할:**
- 보호된 경로 접근 시 세션 검증
- 세션 없으면 /login으로 리다이렉트
- Admin 전용 경로 접근 시 role 검증

**보호 경로:**
- `/dashboards/*`: 인증 필요
- `/profile/*`: 인증 필요
- `/admin/*`: Admin 권한 필요

**공개 경로:**
- `/login`: 인증 불필요
- `/`: 인증 불필요
- `/shared/*`: 인증 불필요 (공유 대시보드)

[Question 4.1] 미들웨어에서 처리해야 할 추가 경로 규칙이 있나요?

[Answer]
**현재 정의된 경로:**
- 보호: /dashboards/*, /profile/*, /admin/*
- 공개: /login, /, /shared/*

**추가 고려 경로:**

**Option A: 현재 경로만**
- 장점: 단순, 명확
- 적합: 초기 MVP

**Option B: API 경로 추가**
- `/api/auth/*` 공개 (로그인 API는 인증 불필요)
- `/api/dashboards/*` 보호
- 장점: API도 미들웨어에서 보호
- 단점: API Route 자체에서 인증 체크하므로 중복

**Option C: 정적 파일 제외**
- `/_next/*`, `/static/*`, `/favicon.ico` 제외
- 장점: 불필요한 검사 제거
- 적합: Next.js 기본 패턴

**권장안: Option A + Option C (현재 경로 + 정적 파일 제외)**
- 보호: /dashboards/*, /profile/*, /admin/*
- 공개: /login, /, /shared/*, /api/auth/*, /_next/*, /favicon.ico
- API는 각 Route에서 자체 인증 (중복 방어)
- Next.js matcher config 사용


[Question 4.2] 인증 실패 시 리다이렉트할 경로는 어디인가요?

[Answer]
**선택지:**

**Option A: 단순 로그인 페이지 (/login)**
- 로그인 후 기본 경로(/dashboards)로 이동
- 장점: 간단한 구현
- 단점: 원래 가려던 페이지 잊음

**Option B: 원래 경로 포함 (/login?redirect={path})**
- 로그인 후 원래 가려던 페이지로 복귀
- 예: `/login?redirect=/dashboards/123`
- 장점: 사용자 경험 우수, 표준 패턴
- 단점: 구현 약간 복잡

**Option C: 동적 판단**
- Admin 경로 → /login?redirect={path}
- 일반 경로 → /login (기본으로 이동)
- 장점: 유연성
- 단점: 로직 복잡

**권장안: Option B (/login?redirect={원래경로})**
- Middleware: `return NextResponse.redirect(new URL(\`/login?redirect=\${request.nextUrl.pathname}\`, request.url))`
- LoginPage: `const redirect = searchParams.get('redirect') || '/dashboards'`
- 장점: UX 우수, 업계 표준, 구현 단순
- redirect URL validation 필요 (오픈 리다이렉트 방지)


#### [ ] 4.2 에러 핸들링 미들웨어

**역할:**
- API Route에서 발생한 에러를 표준 형식으로 변환
- Zod 검증 에러 → `AUTH_VALIDATION_ERROR`
- Supabase 에러 → 적절한 에러 코드로 매핑
- 예상치 못한 에러 → `INTERNAL_ERROR` + 로깅

**구현 위치:**
- 각 API Route에서 try-catch로 에러 처리
- 공통 에러 핸들러 함수 사용

[Question 4.3] 에러 로깅 방식은 어떻게 하시겠습니까?

[Answer]
**선택지:**

**Option A: console.error (개발 환경)**
- 장점: 구현 불필요, 개발 편의성
- 단점: 프로덕션 로그 관리 어려움, 검색/분석 불가

**Option B: Sentry 등 외부 서비스**
- 장점: 실시간 알림, 상세 분석, 스택 트레이스, 사용자 영향 추적
- 단점: 비용, 외부 의존성, 설정 필요

**Option C: 파일 로깅 (Winston, Pino)**
- 장점: 자체 호스팅, 비용 절감
- 단점: 로그 관리 부담, 분석 도구 별도 필요

**Option D: 로깅 없음**
- 장점: 단순
- 단점: 프로덕션 디버깅 불가

**권장안: Option A (현재) + Option B (향후)**
- **초기 (Phase 1)**: console.error + 표준 에러 응답
  - 개발 환경에서 충분
  - 구현 단순
- **향후 (프로덕션)**: Sentry 추가
  - 프로덕션 배포 시 추가
  - 중요 에러만 추적
  - 환경 변수로 활성화: `NEXT_PUBLIC_SENTRY_DSN`
- 이유: 점진적 접근, YAGNI


#### [ ] 4.3 요청 검증 미들웨어

**역할:**
- API Route 요청 body 검증 (Zod Schema)
- Provider 파라미터 검증 (google | kakao)
- UUID 형식 검증 (userId)

**구현:**
- Zod Schema의 `parse()` 또는 `safeParse()` 사용
- 검증 실패 시 400 Bad Request 반환

### Phase 5: 파일 구조 설계

#### [ ] 5.1 apps/web/app/api/ 디렉터리 구조

```
apps/web/app/api/auth/
├── signin/
│   └── [provider]/
│       └── route.ts          # POST /api/auth/signin/:provider
├── signout/
│   └── route.ts              # POST /api/auth/signout
├── callback/
│   └── route.ts              # GET /api/auth/callback
├── refresh/
│   └── route.ts              # POST /api/auth/refresh (선택)
├── user/
│   └── route.ts              # GET /api/auth/user
├── profile/
│   └── route.ts              # PATCH /api/auth/profile
├── link/
│   ├── [provider]/
│   │   └── route.ts          # POST /api/auth/link/:provider
│   └── unlink/
│       └── [provider]/
│           └── route.ts      # DELETE /api/auth/link/unlink/:provider
├── activate/
│   └── [userId]/
│       └── route.ts          # POST /api/auth/activate/:userId (Admin)
└── deactivate/
    └── [userId]/
        └── route.ts          # POST /api/auth/deactivate/:userId (Admin)
```

[Question 5.1] API 라우트 구조에 대한 선호도가 있나요? 위 구조가 적합한가요?

[Answer]
**현재 제안된 구조:**
```
/api/auth/
  signin/[provider]/route.ts
  signout/route.ts
  callback/route.ts
  user/route.ts
  profile/route.ts
  link/[provider]/route.ts
  link/unlink/[provider]/route.ts
  activate/[userId]/route.ts
  deactivate/[userId]/route.ts
```

**검토 관점:**

**Option A: 현재 구조 유지**
- 장점: RESTful, 명확한 경로, Next.js App Router 표준
- 단점: link/unlink 경로가 다소 깊음

**Option B: unlink 구조 평탄화**
- `/api/auth/link/[provider]` (POST = link)
- `/api/auth/unlink/[provider]` (DELETE)
- 장점: 경로 간결
- 단점: link/unlink가 분리됨

**Option C: HTTP Method로 구분**
- `/api/auth/link/[provider]` (POST = link, DELETE = unlink)
- 장점: RESTful 원칙, 경로 단순
- 단점: Next.js Route에서 구현 복잡 (같은 경로에 다른 Method)

**권장안: Option C (HTTP Method 구분)**
- `/api/auth/link/[provider]/route.ts`에서 POST와 DELETE 모두 처리
- RESTful 원칙에 부합
- 경로 간결
- Next.js에서 지원 (export async function POST, export async function DELETE)


#### [ ] 5.2 공통 유틸리티 파일 구조

```
apps/web/src/lib/api/
├── supabase/
│   ├── client.ts             # Browser client
│   ├── server.ts             # Server client (API Route용)
│   └── middleware.ts         # Middleware client
├── auth/
│   ├── errors.ts             # 에러 코드 상수
│   ├── validators.ts         # 공통 검증 함수
│   └── helpers.ts            # 헬퍼 함수
└── utils/
    ├── response.ts           # API 응답 포맷 함수
    └── error-handler.ts      # 에러 핸들러
```

[Question 5.2] 공통 유틸리티를 packages/authentication에 둘지, apps/web/src/lib에 둘지 선호도가 있나요?

[Answer]
**선택지:**

**Option A: packages/authentication/src/lib/ (재사용 가능)**
- Supabase 클라이언트, 에러 코드, API 응답 포맷 모두 packages에
- 장점: 다른 앱에서도 재사용 가능, 일관성
- 단점: API Route 관련 코드가 패키지에 포함됨

**Option B: apps/web/src/lib/ (앱 전용)**
- 모든 유틸리티를 apps에
- 장점: 앱 전용 코드 명확, 패키지 순수성 유지
- 단점: 재사용 어려움

**Option C: 혼합 (스키마는 packages, API 유틸은 apps)**
- packages/authentication: 스키마, 타입, 에러 코드
- apps/web/src/lib: Supabase 클라이언트, API 응답 유틸
- 장점: 책임 분리, 패키지 순수성 + 앱 특화
- 단점: 코드 위치 판단 필요

**권장안: Option C (혼합)**

**packages/authentication/src/**
- schemas/ (Zod Schema)
- utils/error-codes.ts (에러 코드 상수)
- utils/error-messages.ts (에러 메시지 매핑)

**apps/web/src/lib/**
- supabase/ (클라이언트 생성 함수)
- api/response.ts (API 응답 포맷 함수)
- api/error-handler.ts (에러 핸들러)

**이유:**
- 스키마/타입은 재사용 가능 (다른 앱, 테스트 등)
- Supabase 클라이언트는 앱별 설정 다를 수 있음
- API 응답 유틸은 Next.js 특화


### Phase 6: 보안 고려사항

#### [ ] 6.1 CORS 설정

**필요성:**
- Next.js API Routes는 기본적으로 same-origin만 허용
- 필요 시 특정 도메인만 허용

[Question 6.1] API를 외부 도메인에서 호출할 계획이 있나요?

[Answer]
**선택지:**

**Option A: same-origin만 (기본)**
- Next.js 앱과 API가 같은 도메인
- 장점: 보안성 최상, CORS 설정 불필요
- 적합: 단일 프론트엔드 앱

**Option B: 특정 도메인 허용**
- 예: 모바일 앱, 다른 서브도메인
- 장점: 유연성
- 단점: CORS 설정 필요, 보안 고려 필요

**권장안: Option A (same-origin만)**
- 현재 E-Torch는 Next.js 단일 앱
- 모바일 앱 계획 없음
- CORS 불필요
- 향후 필요 시 추가 가능


#### [ ] 6.2 Rate Limiting

**구현 여부:**
- 초기에는 생략 (OAuth가 Rate Limiting 처리)
- 향후 email/password 로그인 추가 시 고려

[Question 6.2] Rate Limiting을 초기부터 구현해야 하나요?

[Answer]
**선택지:**

**Option A: 초기부터 구현**
- 라이브러리: upstash/ratelimit, express-rate-limit
- 장점: DDoS 방지, API 남용 방지
- 단점: 복잡도 증가, Redis 등 추가 인프라 필요

**Option B: OAuth Provider에 의존**
- Google, Kakao가 자체 Rate Limiting 처리
- Supabase도 기본 Rate Limiting 제공
- 장점: 구현 불필요
- 단점: 세밀한 제어 불가

**Option C: 향후 추가 (email/password 로그인 시)**
- 장점: YAGNI, 초기 단순화
- 적합: OAuth만 사용하는 현재

**권장안: Option B (OAuth Provider 의존) + 향후 Option C**
- 현재는 Rate Limiting 구현 불필요
- OAuth Provider가 충분히 보호
- email/password 추가 시 재검토
- Vercel Edge Functions도 기본 Rate Limiting 제공


#### [ ] 6.3 입력 Sanitization

**XSS 방지:**
- React가 기본적으로 XSS 방지 (JSX 이스케이프)
- Zod Schema로 입력 검증
- Avatar URL은 HTTPS만 허용

**SQL Injection 방지:**
- Supabase SDK 사용 (Parameterized query)
- Raw SQL 사용 금지

#### [ ] 6.4 세션 보안

**Access Token:**
- Supabase가 localStorage에 자동 저장
- HttpOnly Cookie 사용 불가 (Supabase 제약)

**Refresh Token:**
- Supabase가 자동 갱신 관리
- 유효 기간: 7일 (Supabase 기본값)

[Question 6.3] Access Token의 localStorage 저장이 보안상 우려되나요?

[Answer]
**선택지:**

**Option A: localStorage (Supabase 기본)**
- Supabase SDK가 localStorage 사용
- 장점: 구현 단순, Supabase 표준, 클라이언트 측 편리
- 단점: XSS 공격 시 토큰 노출 가능

**Option B: HttpOnly Cookie**
- 서버에서 쿠키 설정, JavaScript 접근 불가
- 장점: XSS 방지, 보안성 최상
- 단점: Supabase 기본 방식 아님, 커스텀 구현 필요, CSRF 토큰 추가 필요

**Option C: Supabase SSR 패키지 사용**
- @supabase/ssr 사용하여 쿠키 기반 세션
- 장점: Supabase 공식 지원, Next.js 최적화
- 단점: 설정 복잡, 문서 제한적

**권장안: Option A (localStorage) + XSS 방지 조치**
- Supabase 기본 방식 사용
- XSS 방지 조치:
  - React의 자동 이스케이프 활용
  - dangerouslySetInnerHTML 금지
  - Zod Schema로 입력 검증
  - HTTPS only (avatar URL)
  - Content Security Policy (CSP) 헤더
- 이유:
  - Supabase 표준 방식
  - OAuth 토큰은 만료 시간 짧음 (1시간)
  - 실용적 보안 수준
  - HttpOnly Cookie 전환은 큰 변경


### Phase 7: 문서 작성

#### [ ] 7.1 bff_api_design.md 작성

**포함 내용:**
1. 개요 및 설계 원칙
2. API 엔드포인트 목록 (표 형식)
3. 각 엔드포인트 상세 스펙
   - HTTP Method, Path
   - Request (Body, Query, Params)
   - Response (Success, Error)
   - Supabase 호출 흐름
   - 권한 검증
4. API 응답 형식 표준
5. 에러 코드 목록
6. RLS 정책 설계
7. 인덱스 및 쿼리 최적화
8. Trigger 및 Function
9. 미들웨어 설계
10. 파일 구조
11. 보안 고려사항

[Question 7.1] bff_api_design.md에 추가로 포함하고 싶은 섹션이 있나요?

[Answer]
**현재 계획된 섹션 (11개):**
1. 개요 및 설계 원칙
2. API 엔드포인트 목록 (표 형식)
3. 각 엔드포인트 상세 스펙
4. API 응답 형식 표준
5. 에러 코드 목록
6. RLS 정책 설계
7. 인덱스 및 쿼리 최적화
8. Trigger 및 Function
9. 미들웨어 설계
10. 파일 구조
11. 보안 고려사항

**추가 고려 섹션:**

**Option A: 현재 섹션만**
- 장점: 핵심만 집중, 간결
- 적합: 초기 설계 문서

**Option B: 데이터베이스 스키마 섹션 추가**
- public.users 테이블 DDL 전체
- 장점: 완전성, 구현 참조 용이
- 적합: 구현 직전 단계

**Option C: 사용 예시 추가**
- API 호출 예시 (curl, fetch)
- 장점: 테스트/개발 편의성
- 단점: 설계 문서에 구현 예시 포함

**권장안: Option A (현재 섹션만)**
- 설계 문서는 "무엇을", "왜" 중심
- 11개 섹션으로 충분히 포괄적
- 데이터베이스 스키마는 Phase 3에 포함됨
- 사용 예시는 향후 API 문서에 추가


#### [ ] 7.2 API 문서 작성 (선택)

**Swagger/OpenAPI 문서 생성 여부:**
- 초기에는 Markdown 문서만
- 향후 필요 시 Swagger 생성

[Question 7.2] OpenAPI 스펙 문서를 생성해야 하나요?

[Answer]
**선택지:**

**Option A: Markdown 문서만**
- bff_api_design.md로 충분
- 장점: 간단, 빠른 작성
- 적합: 내부 팀 전용, 초기 단계

**Option B: OpenAPI 3.0 스펙 생성**
- YAML/JSON 형식
- Swagger UI로 인터랙티브 문서
- 장점: 표준 형식, 도구 지원 (코드 생성, 테스트), API 테스트 편리
- 단점: 작성 시간 증가, 유지보수 필요

**Option C: 코드 기반 자동 생성**
- ts-rest, tRPC, Hono 등 사용
- API Route 코드에서 자동 생성
- 장점: 코드와 문서 동기화
- 단점: 초기 설정 복잡, 아키텍처 변경

**권장안: Option A (Markdown만)**
- 초기에는 bff_api_design.md로 충분
- 내부 팀만 사용
- 구현 후 필요 시 OpenAPI 추가
- YAGNI 원칙
- 향후 외부 API 제공 시 재검토


## 완료 조건
- [ ] 모든 Phase 완료
- [ ] 모든 질문에 답변 완료
- [ ] 사용자 승인 획득
- [ ] bff_api_design.md 작성 완료

## 다음 단계
설계 완료 후:
1. bff_api_design.md 작성 (코드 없이 설계만)
2. 사용자 검토 및 피드백
3. 승인 후 구현 단계로 진행
