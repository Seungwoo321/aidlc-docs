# Authentication Feature Module - Construction Plan

## 목표
Authentication Feature Module을 BFF + Feature Module 아키텍처 기반으로 설계합니다.

## 설계 원칙
- DDD 패턴 사용 금지 (Aggregate Root, Repository, Domain Events 없음)
- TypeScript Interface + Zod Schema 기반 타입 안정성
- React Components + TanStack Query Hooks 사용
- Supabase Auth 직접 호출
- BFF (Backend-for-Frontend) 패턴

## 설계 단계

### Phase 1: 사전 분석 및 확인
- [ ] **1.1 Supabase 프로젝트 설정 확인**
  - Supabase 프로젝트가 이미 설정되어 있는지 확인
  - OAuth Providers (Google, Kakao) 설정 상태 확인
  - 필요한 환경 변수 확인

[Question] Supabase 프로젝트가 이미 설정되어 있나요?
[Answer] ✅ 예. Supabase 프로젝트 설정 완료 (https://beyjprayurmgqgcrxamt.supabase.co)

[Question] Google OAuth와 Kakao OAuth가 Supabase에 설정되어 있나요?
[Answer] ⚠️ OAuth 사용 기록 없음. 설정되어 있다고 가정하고 진행. 구현 단계에서 Supabase Dashboard를 통해 추가.

[Question] 다음 환경 변수가 설정되어 있나요?
- NEXT_PUBLIC_SUPABASE_URL
- NEXT_PUBLIC_SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY (서버 사이드용)
[Answer] ✅ 예. 모든 환경 변수 설정 완료.

- [ ] **1.2 데이터베이스 스키마 확인**
  - Supabase Auth의 기본 `auth.users` 테이블 확인
  - 추가로 필요한 `public.users` 프로필 테이블 확인
  - 계정 상태 관리를 위한 컬럼 (status) 확인

[Question] 사용자 프로필을 저장할 `public.users` 테이블이 있나요? 없다면 생성이 필요합니다.
필요한 컬럼:
- id (uuid, FK to auth.users.id)
- email (text)
- name (text)
- avatar (text, nullable)
- role (enum: 'user' | 'admin')
- status (enum: 'active' | 'inactive')
- created_at (timestamp)
- updated_at (timestamp)
[Answer] ❌ 없음. 신규 생성 필요. Integration Contract 기반 스키마 설계.
- linkedProviders는 auth.users.identities에서 동적 조회
- RLS 정책 + Trigger (auth.users → public.users 자동 생성)
- 데이터 마이그레이션 불필요 (기존 데이터 없음)

- [ ] **1.3 기존 패키지 구조 분석**
  - `packages/core/src/types/auth.ts` 파일 확인
  - 기존 타입 정의가 있는지 확인
  - 재사용 가능한 컴포넌트 확인 (`packages/ui`)

[Answer] ✅ 분석 완료
- 기존 타입: packages/core/src/types/auth.ts 존재하나 Integration Contract와 불일치
- 전략: Integration Contract 기반 새 타입 작성 (packages/authentication/src/types/)
- packages/ui: Button, Input, Card, Toast, Spinner 등 재사용 가능
- Authentication 전용 컴포넌트만 새로 작성

### Phase 2: 타입 시스템 설계
- [ ] **2.1 TypeScript Interface 정의**
  - User 인터페이스 정의
  - Session 인터페이스 정의
  - AuthContext 인터페이스 정의
  - Profile 관련 DTO 인터페이스 정의
  - SNS Provider 타입 정의

- [ ] **2.2 Zod Schema 정의**
  - User 스키마 (런타임 검증)
  - Profile 업데이트 스키마
  - OAuth 콜백 검증 스키마
  - API 요청/응답 스키마

[Answer] ✅ 전략 확정: Zod Schema → TypeScript 타입 추론 (Option B)
- 파일 구조: packages/authentication/src/schemas/
  - user.schema.ts (UserSchema + User 타입)
  - session.schema.ts (SessionSchema + Session 타입)
  - profile.schema.ts (UpdateProfileSchema + DTO)
  - provider.schema.ts (LinkProviderSchema + DTO)
- 장점: 단일 진실 공급원, 자동 동기화, BFF 패턴 적합, 런타임 안정성
- Integration Contract 준수: Schema에서 추론된 타입이 계약과 동일

### Phase 3: 패키지 구조 설계
- [ ] **3.1 packages/authentication 디렉터리 구조 설계**
  ```
  packages/authentication/
    ├── src/
    │   ├── types/           # TypeScript 인터페이스
    │   ├── schemas/         # Zod 스키마
    │   ├── contexts/        # React Context
    │   ├── hooks/           # TanStack Query Hooks
    │   ├── components/      # React 컴포넌트
    │   ├── lib/             # Supabase 클라이언트
    │   └── utils/           # 유틸리티 함수
    ├── package.json
    └── tsconfig.json
  ```

[Question] 이 디렉터리 구조가 프로젝트의 다른 Feature Module과 일관성이 있나요? 수정이 필요한 부분이 있나요?
[Answer] ✅ 확정: Context + TanStack Query 패턴 (Option B)

최종 구조:
```
packages/authentication/src/
├── schemas/        # Zod Schema + 타입 추론
├── contexts/       # AuthProvider (전역 인증 상태만)
├── hooks/          # TanStack Query Hooks (비즈니스 로직)
├── components/     # React 컴포넌트
├── lib/            # Supabase 클라이언트 래퍼
├── utils/          # 유틸리티 함수
└── index.ts        # Public exports
```

아키텍처적 장점:
- 관심사 분리 (Context는 상태, Hooks는 로직)
- 성능 최적화 (불필요한 리렌더링 방지)
- 테스트 가능성 (각 hook 독립 테스트)
- 확장성 (새 기능 = 새 hook 파일)
- TanStack Query 기능 활용 (캐싱, 재시도, 낙관적 업데이트)

### Phase 4: Supabase Auth 클라이언트 설계
- [ ] **4.1 Supabase 클라이언트 래퍼 설계**
  - Browser 클라이언트 (Client Component용)
  - Server 클라이언트 (Server Component/API Route용)
  - Middleware 클라이언트 (세션 검증용)

- [ ] **4.2 OAuth 플로우 설계**
  - Google OAuth 플로우
  - Kakao OAuth 플로우
  - 콜백 처리 로직
  - 계정 자동 통합 로직 (같은 이메일)

### Phase 5: React Context 및 Provider 설계
- [ ] **5.1 AuthContext 설계**
  - Context 상태 정의
    - user: User | null
    - session: Session | null
    - isLoading: boolean
    - isAuthenticated: boolean
  - Context 메서드 정의
    - signIn(provider)
    - signOut()
    - refreshSession()
    - updateProfile(data)
    - linkProvider(provider)
    - unlinkProvider(provider)

- [ ] **5.2 AuthProvider 구현 전략**
  - 초기 세션 로드 로직
  - 자동 토큰 갱신 로직
  - 세션 변경 리스너
  - 에러 처리 전략

[Question] AuthProvider는 어느 레벨에서 제공되어야 하나요?
- Option A: apps/web/app/layout.tsx (전체 앱)
- Option B: 특정 페이지/레이아웃에만 제공
[Answer] ✅ Option A 선택: apps/web/app/layout.tsx (전체 앱)

근거:
- Next.js 표준 패턴 (전역 Provider)
- 모든 페이지에서 인증 상태 접근 가능
- 공유 URL과 호환 (user = null 상태 지원)
- 로그인 여부에 따른 동적 UI 가능
- Middleware와 일관성
- 성능 오버헤드 미미

구현 위치: apps/web/app/layout.tsx
페이지별 인증 체크: app/(authenticated)/layout.tsx에서 처리

### Phase 6: TanStack Query Hooks 설계
- [ ] **6.1 인증 관련 Hooks**
  - useAuth() - Context 기반 훅
  - useSession() - 세션 정보 조회
  - useUser() - 사용자 정보 조회

- [ ] **6.2 Mutation Hooks**
  - useSignIn() - 로그인 Mutation
  - useSignOut() - 로그아웃 Mutation
  - useUpdateProfile() - 프로필 업데이트 Mutation
  - useLinkProvider() - SNS 계정 연결 Mutation
  - useUnlinkProvider() - SNS 계정 연결 해제 Mutation

- [ ] **6.3 Query Hooks**
  - useProfile() - 프로필 조회 Query
  - useLinkedProviders() - 연결된 SNS 계정 조회 Query

- [ ] **6.4 캐싱 전략 정의**
  - Query Key 구조
  - 캐시 무효화 전략
  - 낙관적 업데이트 전략

[Question] TanStack Query의 캐싱 전략에 대한 선호도가 있나요?
- staleTime: 기본값 사용 (0ms) vs 커스텀 (예: 5분)
- cacheTime: 기본값 사용 (5분) vs 커스텀
[Answer] ✅ 중도적 접근: 전역 기본값 + 쿼리별 커스텀

전역 기본값:
- staleTime: 1분 (합리적 기본값)
- gcTime: 5분 (TanStack Query 기본값)
- refetchOnWindowFocus: true (탭 전환 시 재검증)
- retry: 3

Authentication 특화 설정:
- useUser(): staleTime 5분 (프로필은 자주 안 변함)
- useLinkedProviders(): staleTime 5분
- Mutation 후: queryClient.invalidateQueries() 즉시 갱신

장점: 성능 최적화, Mutation 후 최신성 보장, 유연성

### Phase 7: React Components 설계
- [ ] **7.1 컴포넌트 계층 구조 정의**
  ```
  AuthProvider (Context)
    └── LoginPage
          ├── LoginForm
          │     ├── GoogleLoginButton
          │     └── KakaoLoginButton
          └── LoginCallback

  ProfilePage
    ├── ProfileHeader
    ├── ProfileForm
    │     ├── NameInput
    │     ├── EmailInput (readonly)
    │     └── AvatarUpload
    └── LinkedAccountsSection
          ├── LinkedAccountsList
          └── LinkAccountButton
  ```

- [ ] **7.2 컴포넌트별 Props 및 상태 정의**
  - GoogleLoginButton: onClick, isLoading, error
  - KakaoLoginButton: onClick, isLoading, error
  - ProfileForm: initialData, onSubmit, isLoading
  - LinkedAccountsList: providers, onUnlink

[Question] 로그인 UI는 어떤 스타일을 원하시나요?
- Option A: 전체 페이지 중앙 배치
- Option B: 모달 형태
- Option C: 사이드바 슬라이드
[Answer] ✅ Option A 선택: 전체 페이지 중앙 배치

근거:
- OAuth 플로우 적합 (리다이렉트 처리 자연스러움)
- 구현 단순 (복잡한 상태 관리 불필요)
- 접근성 우수 (페이지 단위 포커스 관리)
- SEO 친화적 (/login URL)
- 리다이렉트 URL 지원 (?redirect 파라미터)
- 업계 표준 패턴

구현: app/login/page.tsx (중앙 Card 레이아웃)

- [ ] **7.3 에러 처리 컴포넌트**
  - AuthErrorBoundary
  - AuthErrorDisplay
  - RetryButton

### Phase 8: BFF API Routes 설계
- [ ] **8.1 API 엔드포인트 구조**
  ```
  /api/auth/
    ├── signin/
    │   ├── google/route.ts
    │   └── kakao/route.ts
    ├── signout/route.ts
    ├── callback/route.ts
    ├── user/route.ts
    ├── profile/route.ts
    └── link/
        ├── [provider]/route.ts
        └── unlink/[provider]/route.ts
  ```

- [ ] **8.2 API Route 핸들러 설계**
  - 요청 검증 (Zod)
  - Supabase Auth 호출
  - 에러 처리 및 응답 형식
  - CORS 및 보안 헤더

[Question] API Routes의 에러 응답 형식을 표준화할 필요가 있나요?
예시:
```typescript
{
  success: boolean
  error?: {
    code: string
    message: string
    details?: any
  }
  data?: any
}
```
[Answer] ✅ 예, 표준화 필요 (Option A + HTTP Status 함께 사용)

응답 형식:
```typescript
type ApiResponse<T> =
  | { success: true, data: T }
  | { success: false, error: { code: string, message: string, details?: any } }
```

장점:
- 일관된 응답 구조 (클라이언트 처리 용이)
- 에러 코드 표준화 (세밀한 에러 처리 가능)
- HTTP Status Code도 함께 사용 (HTTP 표준 준수)
- 타입 안정성 (TypeScript)
- 다국어 지원 (code 기반 번역)

에러 코드 예시: AUTH_UNAUTHORIZED, AUTH_ACCOUNT_INACTIVE, AUTH_INVALID_CREDENTIALS

### Phase 9: Business Logic 설계 (선택적)
- [ ] **9.1 검증 로직**
  - 이메일 형식 검증
  - 이름 길이 검증
  - 프로필 사진 크기/형식 검증

- [ ] **9.2 보안 로직**
  - XSS 방지
  - CSRF 토큰 검증 (Supabase가 처리)
  - Rate Limiting 전략

[Question] Rate Limiting이 필요한가요? (예: 로그인 시도 제한)
[Answer] ⚠️ 초기에는 불필요, 향후 추가

근거:
- OAuth 로그인이 주요 방식 (Google, Kakao가 Rate Limiting 처리)
- Supabase도 기본 Rate Limiting 제공
- 복잡도 증가 방지
- email/password 로그인 추가 시 고려

- [ ] **9.3 계정 연결 로직**
  - 같은 이메일 자동 통합 규칙
  - 수동 연결 프로세스
  - 연결 해제 제약사항

### Phase 10: 의존성 분석
- [ ] **10.1 외부 의존성**
  - @supabase/supabase-js
  - @supabase/ssr
  - @tanstack/react-query
  - zod
  - react (Context, useState, useEffect)

- [ ] **10.2 내부 의존성**
  - @e-torch/core (공통 타입)
  - @e-torch/ui (공통 UI 컴포넌트)
  - @e-torch/utils (유틸리티 함수)

[Question] packages/authentication이 다른 Feature Module (subscription, admin-console)에 의존하지 않아야 하는데, 이 원칙에 동의하시나요?
[Answer] ✅ 절대 동의 (엄격한 원칙)

근거:
- authentication은 최하위 기반 모듈
- 순환 참조 방지
- 독립성 보장 (다른 모듈 변경에 영향 받지 않음)
- Integration Contract도 명시 (입력 의존성: 없음)

의존성 방향: authentication ← subscription/admin-console/dashboard

### Phase 11: 보안 요구사항 설계
- [ ] **11.1 세션 보안**
  - Access Token 저장 방식 (localStorage)
  - Refresh Token 저장 방식
  - 토큰 갱신 로직

- [ ] **11.2 XSS 방지**
  - Supabase의 기본 보호 활용
  - 사용자 입력 sanitization

- [ ] **11.3 CSRF 방지**
  - Supabase의 기본 PKCE 플로우 활용

- [ ] **11.4 계정 상태 관리**
  - 비활성 계정 로그인 차단 로직
  - 관리자 권한 검증 로직

### Phase 12: 문서 작성
- [ ] **12.1 feature_module_design.md 작성**
  - 개요 및 책임
  - 아키텍처 다이어그램
  - 타입 정의 (Interface + Zod Schema)
  - React Components Tree
  - TanStack Query Hooks
  - 파일 구조
  - 의존성 (내부/외부)
  - BFF API 엔드포인트
  - 보안 고려사항
  - 테스트 전략

[Question] feature_module_design.md에 포함하고 싶은 추가 섹션이 있나요?
[Answer] ✅ 기본 섹션 + 사용 예시 (코드 포함)

기본 섹션:
1. 개요 및 책임
2. 아키텍처 다이어그램
3. 타입 정의 (Zod Schema + 타입)
4. React Components Tree
5. TanStack Query Hooks
6. 파일 구조
7. 의존성 (내부/외부)
8. BFF API 엔드포인트
9. 보안 고려사항
10. 테스트 전략

추가 섹션:
11. **사용 예시 (코드 포함)** ⭐
    - 기본 사용법 (useAuth, useSignIn)
    - 다른 Feature Module에서 통합
    - 에러 처리 예시
12. 에러 코드 목록

코드 예시: 인터페이스 시그니처, 사용 패턴 (상세 구현 제외)

## 완료 조건
- [ ] 모든 Phase 완료
- [ ] 사용자 승인 획득
- [ ] feature_module_design.md 작성 완료

## 다음 단계
설계 완료 후:
1. 구현 단계로 진행 (코드 작성)
2. 테스트 작성
3. 문서 업데이트
