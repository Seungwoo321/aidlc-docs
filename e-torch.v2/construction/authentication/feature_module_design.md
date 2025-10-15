# Authentication Feature Module - 설계 문서

## 문서 정보

- **Feature Module**: Authentication
- **작성일**: 2025-10-13
- **아키텍처**: BFF (Backend-for-Frontend) + Feature Module
- **관련 문서**:
  - [Inception - Authentication Unit](../../inception/units/authentication.md)
  - [Integration Contract](../../inception/units/integration_contract.md)
  - [Construction Plan](./plan.md)

---

## 1. 개요 및 책임

### 1.1 Feature Module 개요

Authentication Feature Module은 E-Torch 경제지표 대시보드의 사용자 인증 및 권한 관리를 담당합니다.

**핵심 책임:**
- SNS 로그인 (Google, Kakao OAuth)
- 세션 관리 (Access Token, Refresh Token)
- 사용자 프로필 관리
- SNS 계정 연결/해제
- 계정 상태 관리 (active/inactive)
- 권한 확인 (user/admin)

**설계 원칙:**
- ✅ DDD 패턴 사용 금지 (Aggregate Root, Repository, Domain Events 없음)
- ✅ TypeScript Interface + Zod Schema 기반 타입 안정성
- ✅ React Components + TanStack Query Hooks
- ✅ Supabase Auth 직접 호출
- ✅ BFF (Backend-for-Frontend) 패턴

### 1.2 사용자 스토리

**US1.1: SNS 로그인**
- 방문자가 Google 또는 Kakao 계정으로 간편하게 로그인
- OAuth 인증을 통한 자동 회원가입
- 같은 이메일의 기존 계정 자동 통합

**US1.2: 프로필 관리**
- 사용자가 프로필 정보(이름, 아바타) 수정
- 연결된 SNS 계정 확인
- 추가 SNS 계정 연결/해제

### 1.3 Integration Contract 준수

다른 Feature Module에 제공하는 인터페이스:

```typescript
interface AuthenticationContract {
  // 인증
  signIn(provider: 'google' | 'kakao'): Promise<Session>
  signOut(): Promise<void>

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

---

## 2. 아키텍처 다이어그램

### 2.1 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    apps/web (Next.js 15)                     │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  app/layout.tsx                                        │ │
│  │  └─ AuthProvider (전역)                                │ │
│  │     └─ QueryClientProvider                             │ │
│  │        └─ {children}                                    │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  BFF API Routes (Backend-for-Frontend)                 │ │
│  │  /api/auth/*                                            │ │
│  │  ├─ /signin/:provider  → Supabase Auth                 │ │
│  │  ├─ /signout           → Supabase Auth                 │ │
│  │  ├─ /callback          → Supabase Auth                 │ │
│  │  ├─ /user              → public.users                  │ │
│  │  ├─ /profile           → public.users                  │ │
│  │  └─ /link/:provider    → Supabase Auth                 │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│         packages/authentication (Feature Module)             │
│                                                              │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐         │
│  │  contexts  │  │    hooks    │  │  components  │         │
│  │            │  │             │  │              │         │
│  │ AuthContext│◄─│ useAuth()   │◄─│ LoginForm    │         │
│  │            │  │ useSignIn() │  │ ProfileForm  │         │
│  │ AuthProvider│ │ useSignOut()│  │              │         │
│  └────────────┘  └─────────────┘  └──────────────┘         │
│                                                              │
│  ┌────────────┐  ┌─────────────┐                           │
│  │  schemas   │  │     lib     │                           │
│  │            │  │             │                           │
│  │ UserSchema │  │ Supabase    │                           │
│  │ SessionSchema│ │ Clients     │                           │
│  └────────────┘  └─────────────┘                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  Supabase (Database + Auth)                  │
│                                                              │
│  ┌──────────────┐          ┌──────────────┐                │
│  │ auth.users   │          │ public.users │                │
│  │ (Supabase)   │──────────│ (App)        │                │
│  │              │ Trigger  │              │                │
│  │ - id         │          │ - id (FK)    │                │
│  │ - email      │          │ - email      │                │
│  │ - identities │          │ - name       │                │
│  │   (OAuth)    │          │ - avatar     │                │
│  │              │          │ - role       │                │
│  │              │          │ - status     │                │
│  └──────────────┘          └──────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Context + TanStack Query 패턴

```typescript
┌──────────────────────────────────────┐
│      AuthProvider (Context)          │
│                                      │
│  State:                              │
│  - user: User | null                 │
│  - session: Session | null           │
│  - isLoading: boolean                │
│                                      │
│  Methods:                            │
│  - setUser(user)                     │
│  - setSession(session)               │
└──────────────────────────────────────┘
              │
              │ provides
              ▼
┌──────────────────────────────────────┐
│     TanStack Query Hooks             │
│                                      │
│  useSignIn()                         │
│  ├─ mutationFn: Supabase signIn      │
│  └─ onSuccess: setUser, setSession   │
│                                      │
│  useSignOut()                        │
│  ├─ mutationFn: Supabase signOut     │
│  └─ onSuccess: setUser(null)         │
│                                      │
│  useUpdateProfile()                  │
│  ├─ mutationFn: Update public.users  │
│  └─ onSuccess: setUser, invalidate   │
│                                      │
│  useLinkProvider()                   │
│  useUnlinkProvider()                 │
└──────────────────────────────────────┘
              │
              │ calls
              ▼
┌──────────────────────────────────────┐
│       Supabase Clients               │
│                                      │
│  createBrowserClient()               │
│  createServerClient()                │
│  createServiceClient()               │
└──────────────────────────────────────┘
```

---

## 3. 타입 정의 (Zod Schema + TypeScript)

### 3.1 타입 설계 전략

**Zod Schema → TypeScript 타입 추론 패턴 사용**

근거:
- 단일 진실 공급원 (Single Source of Truth)
- 자동 동기화 (Schema 변경 시 타입 자동 업데이트)
- 런타임 안정성 (Zod가 컴파일 타임 + 런타임 보장)
- BFF 패턴 적합 (API Route에서 입력 검증 필수)

### 3.2 User Schema

**파일**: `packages/authentication/src/schemas/user.schema.ts`

```typescript
import { z } from 'zod'

// Integration Contract 준수
export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string(),
  avatar: z.string().url().optional(),
  role: z.enum(['user', 'admin']),
  status: z.enum(['active', 'inactive']),
  linkedProviders: z.array(z.enum(['google', 'kakao'])).optional(),
})

// 타입 추론
export type User = z.infer<typeof UserSchema>

// 예시:
// {
//   id: '123e4567-e89b-12d3-a456-426614174000',
//   email: 'user@example.com',
//   name: '홍길동',
//   avatar: 'https://example.com/avatar.jpg',
//   role: 'user',
//   status: 'active',
//   linkedProviders: ['google', 'kakao']
// }
```

### 3.3 Session Schema

**파일**: `packages/authentication/src/schemas/session.schema.ts`

```typescript
import { z } from 'zod'
import { UserSchema } from './user.schema'

export const SessionSchema = z.object({
  access_token: z.string(),
  refresh_token: z.string(),
  expires_in: z.number(),
  expires_at: z.number(),
  user: UserSchema,
})

export type Session = z.infer<typeof SessionSchema>
```

### 3.4 Profile DTO Schemas

**파일**: `packages/authentication/src/schemas/profile.schema.ts`

```typescript
import { z } from 'zod'

// 프로필 업데이트 DTO
export const UpdateProfileSchema = z.object({
  name: z.string().min(1, '이름은 필수입니다').max(100, '이름은 100자 이하여야 합니다').optional(),
  avatar: z.string().url('유효한 URL이어야 합니다').optional(),
})

export type UpdateProfileDto = z.infer<typeof UpdateProfileSchema>

// 예시:
// { name: '김철수', avatar: 'https://...' }
```

### 3.5 Provider Schema

**파일**: `packages/authentication/src/schemas/provider.schema.ts`

```typescript
import { z } from 'zod'

export const ProviderSchema = z.enum(['google', 'kakao'])
export type Provider = z.infer<typeof ProviderSchema>

// SNS 계정 연결
export const LinkProviderSchema = z.object({
  provider: ProviderSchema,
})

export type LinkProviderDto = z.infer<typeof LinkProviderSchema>

// SNS 계정 해제
export const UnlinkProviderSchema = z.object({
  provider: ProviderSchema,
})

export type UnlinkProviderDto = z.infer<typeof UnlinkProviderSchema>
```

### 3.6 AuthContext Types

**파일**: `packages/authentication/src/schemas/auth-context.schema.ts`

```typescript
import { z } from 'zod'
import { UserSchema } from './user.schema'
import { SessionSchema } from './session.schema'

// AuthContext 상태
export const AuthContextSchema = z.object({
  user: UserSchema.nullable(),
  session: SessionSchema.nullable(),
  isLoading: z.boolean(),
  isAuthenticated: z.boolean(),
})

export type AuthContext = z.infer<typeof AuthContextSchema>

// 예시:
// {
//   user: { id: '...', email: '...', ... },
//   session: { access_token: '...', ... },
//   isLoading: false,
//   isAuthenticated: true
// }
```

### 3.7 API Response Schema

**파일**: `packages/authentication/src/schemas/api-response.schema.ts`

```typescript
import { z } from 'zod'

// 성공 응답
export const SuccessResponseSchema = <T extends z.ZodTypeAny>(dataSchema: T) =>
  z.object({
    success: z.literal(true),
    data: dataSchema,
  })

// 에러 응답
export const ErrorResponseSchema = z.object({
  success: z.literal(false),
  error: z.object({
    code: z.string(),
    message: z.string(),
    details: z.any().optional(),
  }),
})

// API Response 유니온
export const ApiResponseSchema = <T extends z.ZodTypeAny>(dataSchema: T) =>
  z.union([SuccessResponseSchema(dataSchema), ErrorResponseSchema])

// 타입 유틸리티
export type ApiResponse<T> =
  | { success: true; data: T }
  | { success: false; error: { code: string; message: string; details?: any } }

// 사용 예시:
// const SignInResponseSchema = ApiResponseSchema(SessionSchema)
// type SignInResponse = ApiResponse<Session>
```

---

## 4. React Components Tree

### 4.1 컴포넌트 계층 구조

```
apps/web/app/
├── layout.tsx
│   └── <AuthProvider>  ⭐ 전역 Provider
│       └── <QueryClientProvider>
│           └── {children}
│
├── login/
│   └── page.tsx
│       └── <LoginPage>
│           ├── <Card>
│           ├── <GoogleLoginButton>
│           └── <KakaoLoginButton>
│
├── auth/
│   └── callback/
│       └── page.tsx
│           └── <AuthCallback>  (OAuth 콜백 처리)
│
└── (authenticated)/
    ├── layout.tsx  (인증 체크)
    └── profile/
        └── page.tsx
            └── <ProfilePage>
                ├── <ProfileHeader>
                ├── <ProfileForm>
                │   ├── <Input name="name" />
                │   ├── <Input name="email" readonly />
                │   └── <AvatarUpload />
                └── <LinkedAccountsSection>
                    ├── <LinkedAccountsList>
                    │   ├── <LinkedAccountCard provider="google" />
                    │   └── <LinkedAccountCard provider="kakao" />
                    └── <LinkAccountButton>
```

### 4.2 주요 컴포넌트 Props

#### AuthProvider

```typescript
// packages/authentication/src/contexts/AuthProvider.tsx
interface AuthProviderProps {
  children: React.ReactNode
}

// 제공하는 Context 값
interface AuthContextValue {
  user: User | null
  session: Session | null
  isLoading: boolean
  isAuthenticated: boolean
  setUser: (user: User | null) => void
  setSession: (session: Session | null) => void
}
```

#### GoogleLoginButton / KakaoLoginButton

```typescript
// packages/authentication/src/components/GoogleLoginButton.tsx
interface GoogleLoginButtonProps {
  onSuccess?: (session: Session) => void
  onError?: (error: Error) => void
  disabled?: boolean
  redirectTo?: string
}

// 내부에서 useSignIn() hook 사용
function GoogleLoginButton({ onSuccess, onError, disabled, redirectTo }: GoogleLoginButtonProps) {
  const { mutate: signIn, isPending } = useSignIn()

  return (
    <Button
      onClick={() => signIn('google', { redirectTo })}
      disabled={disabled || isPending}
    >
      <GoogleIcon /> Google로 로그인
    </Button>
  )
}
```

#### ProfileForm

```typescript
// packages/authentication/src/components/ProfileForm.tsx
interface ProfileFormProps {
  user: User
  onSuccess?: () => void
  onError?: (error: Error) => void
}

function ProfileForm({ user, onSuccess, onError }: ProfileFormProps) {
  const { mutate: updateProfile, isPending } = useUpdateProfile()

  const handleSubmit = (data: UpdateProfileDto) => {
    updateProfile(data, {
      onSuccess: () => {
        toast.success('프로필이 업데이트되었습니다')
        onSuccess?.()
      },
      onError: (error) => {
        toast.error('업데이트 실패')
        onError?.(error)
      }
    })
  }

  return <form onSubmit={handleSubmit}>...</form>
}
```

#### LinkedAccountsList

```typescript
// packages/authentication/src/components/LinkedAccountsList.tsx
interface LinkedAccountsListProps {
  providers: Provider[]
  onUnlink?: (provider: Provider) => void
}

function LinkedAccountsList({ providers, onUnlink }: LinkedAccountsListProps) {
  const { mutate: unlinkProvider } = useUnlinkProvider()

  return (
    <div>
      {providers.map(provider => (
        <LinkedAccountCard
          key={provider}
          provider={provider}
          onUnlink={() => unlinkProvider(provider)}
        />
      ))}
    </div>
  )
}
```

---

## 5. TanStack Query Hooks

### 5.1 Hooks 목록 및 책임

| Hook | 타입 | 책임 |
|------|------|------|
| `useAuth()` | Context | 전역 인증 상태 접근 |
| `useSignIn()` | Mutation | OAuth 로그인 |
| `useSignOut()` | Mutation | 로그아웃 |
| `useUpdateProfile()` | Mutation | 프로필 수정 |
| `useLinkProvider()` | Mutation | SNS 계정 연결 |
| `useUnlinkProvider()` | Mutation | SNS 계정 해제 |
| `useUser()` | Query | 사용자 정보 조회 (캐싱) |
| `useLinkedProviders()` | Query | 연결된 SNS 목록 조회 |

### 5.2 useAuth (Context Hook)

**파일**: `packages/authentication/src/hooks/useAuth.ts`

```typescript
import { useContext } from 'react'
import { AuthContext } from '../contexts/AuthContext'

export function useAuth() {
  const context = useContext(AuthContext)

  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }

  return context
}

// 사용 예시:
// const { user, isAuthenticated, isLoading } = useAuth()
```

### 5.3 useSignIn (Mutation Hook)

**파일**: `packages/authentication/src/hooks/useSignIn.ts`

**시그니처:**
```typescript
interface SignInOptions {
  redirectTo?: string
}

export function useSignIn(): UseMutationResult<
  Session,
  Error,
  { provider: Provider, options?: SignInOptions }
>
```

**사용 예시:**
```typescript
const { mutate: signIn, isPending } = useSignIn()
signIn({ provider: 'google', options: { redirectTo: '/dashboards' } })
```

### 5.4 useUpdateProfile (Mutation Hook)

**파일**: `packages/authentication/src/hooks/useUpdateProfile.ts`

**시그니처:**
```typescript
export function useUpdateProfile(): UseMutationResult<User, Error, UpdateProfileDto>
```

**기능:**
- 사용자 프로필 수정
- AuthContext 자동 업데이트
- Query 캐시 무효화
- 낙관적 업데이트 지원

**사용 예시:**
```typescript
const { mutate: updateProfile, isPending } = useUpdateProfile()
updateProfile({ name: '새 이름', avatar: 'https://...' })
```

### 5.5 캐싱 전략

**전역 기본값 (QueryClient 설정):**

```typescript
// apps/web/app/providers.tsx
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,           // 1분 (합리적 기본값)
      gcTime: 5 * 60 * 1000,          // 5분 (TanStack Query 기본값)
      refetchOnWindowFocus: true,     // 탭 전환 시 재검증
      refetchOnReconnect: true,       // 재연결 시 재검증
      retry: 3,                       // 실패 시 3번 재시도
    },
  },
})
```

**Authentication 특화 설정:**

```typescript
// useUser (Query)
export function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
    staleTime: 5 * 60 * 1000,        // 5분 (user는 자주 변경 안 됨)
    gcTime: 10 * 60 * 1000,          // 10분
  })
}

// useLinkedProviders (Query)
export function useLinkedProviders() {
  const { user } = useAuth()

  return useQuery({
    queryKey: ['linkedProviders', user?.id],
    queryFn: () => fetchLinkedProviders(user!.id),
    enabled: !!user,                  // user가 있을 때만 실행
    staleTime: 5 * 60 * 1000,        // 5분
  })
}
```

---

## 6. 파일 구조

### 6.1 packages/authentication 구조

```
packages/authentication/
├── src/
│   ├── schemas/                    # Zod Schema + 타입
│   │   ├── user.schema.ts
│   │   ├── session.schema.ts
│   │   ├── profile.schema.ts
│   │   ├── provider.schema.ts
│   │   ├── auth-context.schema.ts
│   │   ├── api-response.schema.ts
│   │   └── index.ts               # Re-export
│   │
│   ├── contexts/                   # React Context
│   │   ├── AuthContext.tsx        # Context 정의
│   │   ├── AuthProvider.tsx       # Provider 구현
│   │   └── index.ts
│   │
│   ├── hooks/                      # TanStack Query Hooks
│   │   ├── useAuth.ts             # Context hook
│   │   ├── useSignIn.ts           # Mutation
│   │   ├── useSignOut.ts          # Mutation
│   │   ├── useUpdateProfile.ts    # Mutation
│   │   ├── useLinkProvider.ts     # Mutation
│   │   ├── useUnlinkProvider.ts   # Mutation
│   │   ├── useUser.ts             # Query
│   │   ├── useLinkedProviders.ts  # Query
│   │   └── index.ts
│   │
│   ├── components/                 # React 컴포넌트
│   │   ├── GoogleLoginButton.tsx
│   │   ├── KakaoLoginButton.tsx
│   │   ├── ProfileForm.tsx
│   │   ├── ProfileHeader.tsx
│   │   ├── LinkedAccountsList.tsx
│   │   ├── LinkedAccountCard.tsx
│   │   ├── LinkAccountButton.tsx
│   │   ├── AuthErrorDisplay.tsx
│   │   └── index.ts
│   │
│   ├── lib/                        # Supabase 클라이언트
│   │   ├── supabase-browser.ts    # Browser client
│   │   ├── supabase-server.ts     # Server client
│   │   ├── supabase-service.ts    # Service role client
│   │   ├── api.ts                 # API 함수들
│   │   └── index.ts
│   │
│   ├── utils/                      # 유틸리티
│   │   ├── error-codes.ts         # 에러 코드 상수
│   │   ├── validators.ts          # 검증 함수
│   │   └── index.ts
│   │
│   └── index.ts                    # Public API (메인 export)
│
├── package.json
├── tsconfig.json
├── README.md
└── CHANGELOG.md
```

### 6.2 Public API (index.ts)

```typescript
// packages/authentication/src/index.ts

// Schemas & Types
export * from './schemas'

// Context & Provider
export { AuthProvider, useAuth } from './contexts'

// Hooks
export {
  useSignIn,
  useSignOut,
  useUpdateProfile,
  useLinkProvider,
  useUnlinkProvider,
  useUser,
  useLinkedProviders,
} from './hooks'

// Components
export {
  GoogleLoginButton,
  KakaoLoginButton,
  ProfileForm,
  ProfileHeader,
  LinkedAccountsList,
  LinkedAccountCard,
  LinkAccountButton,
  AuthErrorDisplay,
} from './components'

// Utils
export { AuthErrorCode } from './utils'
```

### 6.3 apps/web 통합 구조

```
apps/web/
├── app/
│   ├── layout.tsx                  # AuthProvider 설정
│   ├── login/
│   │   └── page.tsx               # 로그인 페이지
│   ├── auth/
│   │   └── callback/
│   │       └── route.ts           # OAuth 콜백
│   ├── (authenticated)/
│   │   ├── layout.tsx             # 인증 체크
│   │   └── profile/
│   │       └── page.tsx           # 프로필 페이지
│   │
│   └── api/
│       └── auth/                   # BFF API Routes
│           ├── signin/
│           │   └── [provider]/
│           │       └── route.ts
│           ├── signout/
│           │   └── route.ts
│           ├── callback/
│           │   └── route.ts
│           ├── user/
│           │   └── route.ts
│           ├── profile/
│           │   └── route.ts
│           └── link/
│               ├── [provider]/
│               │   └── route.ts
│               └── unlink/
│                   └── [provider]/
│                       └── route.ts
│
└── src/
    └── lib/
        └── supabase/
            ├── client.ts           # Browser client
            ├── server.ts           # Server client
            └── middleware.ts       # Middleware client
```

---

## 7. 의존성

### 7.1 외부 의존성

```json
{
  "dependencies": {
    "@supabase/supabase-js": "^2.39.0",
    "@supabase/ssr": "^0.1.0",
    "@tanstack/react-query": "^5.17.0",
    "zod": "^3.22.4",
    "react": "^19.0.0",
    "next": "^15.0.0"
  }
}
```

**패키지 역할:**
- `@supabase/supabase-js`: Supabase 클라이언트 (인증, 데이터베이스)
- `@supabase/ssr`: Next.js SSR 지원
- `@tanstack/react-query`: 서버 상태 관리, 캐싱
- `zod`: 스키마 검증 및 타입 추론

### 7.2 내부 의존성

```
packages/authentication/
├─ depends on ─► @e-torch/core         (공통 타입, 상수)
├─ depends on ─► @e-torch/ui           (UI 컴포넌트)
└─ depends on ─► @e-torch/utils        (유틸리티 함수)

packages/dashboard/
├─ depends on ─► @e-torch/authentication  ✅
└─ ...

packages/subscription/
├─ depends on ─► @e-torch/authentication  ✅
└─ ...

packages/admin-console/
├─ depends on ─► @e-torch/authentication  ✅
└─ ...
```

**의존성 방향 (엄격한 원칙):**
```
authentication (기반 모듈)
    ↑
    │ depends on
    │
dashboard, subscription, admin-console (상위 모듈)
```

**❌ 금지:**
- authentication이 다른 Feature Module에 의존
- 순환 참조

### 7.3 Supabase 의존성

```
Supabase
├─ auth.users (Supabase 관리)
│   ├─ id
│   ├─ email
│   ├─ identities (OAuth providers)
│   └─ ...
│
└─ public.users (애플리케이션 관리)
    ├─ id (FK to auth.users.id)
    ├─ email
    ├─ name
    ├─ avatar
    ├─ role
    ├─ status
    └─ ...
```

**Trigger 자동 동기화:**
```sql
-- auth.users INSERT 시 public.users 자동 생성
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
```

---

## 8. BFF API 엔드포인트

### 8.1 API Routes 목록

| Method | Endpoint | 설명 | 인증 |
|--------|----------|------|------|
| POST | `/api/auth/signin/:provider` | OAuth 로그인 시작 | ❌ |
| POST | `/api/auth/signout` | 로그아웃 | ✅ |
| POST | `/api/auth/refresh` | 세션 갱신 | ✅ |
| GET | `/api/auth/callback` | OAuth 콜백 처리 | ❌ |
| GET | `/api/auth/user` | 현재 사용자 정보 | ✅ |
| PATCH | `/api/auth/profile` | 프로필 수정 | ✅ |
| POST | `/api/auth/link/:provider` | SNS 계정 연결 | ✅ |
| DELETE | `/api/auth/link/:provider` | SNS 계정 해제 | ✅ |
| POST | `/api/auth/activate/:userId` | 계정 활성화 (Admin) | ✅ Admin |
| POST | `/api/auth/deactivate/:userId` | 계정 비활성화 (Admin) | ✅ Admin |

### 8.2 API Route 상세

#### POST /api/auth/signin/:provider

**파일**: `apps/web/app/api/auth/signin/[provider]/route.ts`

**요청:**
```
URL: /api/auth/signin/:provider
Params: provider (google | kakao)
Query: redirectTo (optional, default: '/')
```

**성공 응답: 200 OK**
```typescript
{
  success: true,
  data: {
    url: string  // OAuth 인증 URL
  }
}
```

**에러 응답: 400 Bad Request**
```typescript
{
  success: false,
  error: {
    code: "AUTH_INVALID_PROVIDER",
    message: string,
    details?: any
  }
}
```

**처리 흐름:**
1. Provider 파라미터 검증 (Zod Schema)
2. Supabase OAuth URL 생성
3. OAuth URL 반환

#### PATCH /api/auth/profile

**파일**: `apps/web/app/api/auth/profile/route.ts`

**요청:**
```typescript
{
  name?: string,
  avatar?: string
}
```

**성공 응답: 200 OK**
```typescript
{
  success: true,
  data: User  // 업데이트된 사용자 정보
}
```

**에러 응답:**
```typescript
// 401 Unauthorized
{
  success: false,
  error: {
    code: "AUTH_UNAUTHORIZED",
    message: "인증이 필요합니다"
  }
}

// 400 Bad Request
{
  success: false,
  error: {
    code: "VALIDATION_ERROR",
    message: "입력값이 올바르지 않습니다",
    details: ZodError
  }
}
```

**처리 흐름:**
1. 세션 인증 확인
2. 요청 body 검증 (UpdateProfileSchema)
3. public.users 업데이트
4. 업데이트된 User 반환

---

## 9. 보안 고려사항

### 9.1 세션 보안

**Access Token 저장:**
- Supabase가 자동으로 `localStorage`에 저장
- HttpOnly 쿠키 사용 불가 (Supabase 제약)
- XSS 방지 필수

**Refresh Token:**
- Supabase가 자동 갱신 관리
- 유효 기간: 7일 (Supabase 기본값)

**세션 검증:**
```typescript
// Middleware에서 세션 검증
// apps/web/middleware.ts
import { NextResponse } from 'next/server'
import { createMiddlewareClient } from '@/lib/supabase/middleware'

export async function middleware(request: NextRequest) {
  const supabase = createMiddlewareClient(request)

  const { data: { session } } = await supabase.auth.getSession()

  // 인증 필요 페이지
  if (request.nextUrl.pathname.startsWith('/dashboards')) {
    if (!session) {
      return NextResponse.redirect(new URL('/login', request.url))
    }
  }

  // Admin 페이지
  if (request.nextUrl.pathname.startsWith('/admin')) {
    if (!session) {
      return NextResponse.redirect(new URL('/login', request.url))
    }

    // Admin 권한 체크 (public.users 조회 필요)
    const { data: user } = await supabase
      .from('users')
      .select('role')
      .eq('id', session.user.id)
      .single()

    if (user?.role !== 'admin') {
      return NextResponse.redirect(new URL('/403', request.url))
    }
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboards/:path*', '/admin/:path*', '/profile/:path*']
}
```

### 9.2 XSS 방지

**React의 기본 보호:**
- JSX는 자동으로 이스케이프
- `dangerouslySetInnerHTML` 사용 금지

**Avatar URL 검증:**
- Zod Schema로 HTTPS URL만 허용
- `avatar: z.string().url().startsWith('https://')`

### 9.3 CSRF 방지

**Supabase PKCE 플로우:**
- OAuth 2.0 PKCE (Proof Key for Code Exchange) 자동 사용
- CSRF 토큰 별도 불필요
- Supabase 클라이언트 기본 설정: `flowType: 'pkce'`

### 9.4 계정 상태 관리

**비활성 계정 로그인 차단:**

**처리 흐름** (`/api/auth/callback`):
1. OAuth 콜백 세션 확인
2. public.users에서 status 조회
3. status === 'inactive'인 경우:
   - 자동 로그아웃
   - /login?error=account_inactive로 리다이렉트
4. status === 'active'인 경우:
   - 정상 로그인 처리

### 9.5 보안 체크리스트

- [x] Access Token은 localStorage (Supabase 기본)
- [x] Refresh Token 자동 갱신
- [x] XSS 방지 (React 자동 이스케이프)
- [x] CSRF 방지 (Supabase PKCE)
- [x] 비활성 계정 로그인 차단
- [x] Admin 권한 검증 (Middleware)
- [x] API Route 인증 체크
- [x] Zod로 입력 검증
- [x] HTTPS only (Avatar URL)
- [ ] Rate Limiting (향후 추가)

---

## 10. 테스트 전략

### 10.1 테스트 레벨

#### Unit Tests (단위 테스트)

**대상:**
- Zod Schemas
- Utility 함수
- 순수 함수 로직

**도구:**
- Vitest (Jest 호환)
- @testing-library/react

**예시:**
```typescript
// packages/authentication/__tests__/schemas/user.schema.test.ts
import { describe, it, expect } from 'vitest'
import { UserSchema } from '../../src/schemas'

describe('UserSchema', () => {
  it('should validate correct user data', () => {
    const validUser = {
      id: '123e4567-e89b-12d3-a456-426614174000',
      email: 'user@example.com',
      name: '홍길동',
      role: 'user',
      status: 'active',
    }

    const result = UserSchema.safeParse(validUser)
    expect(result.success).toBe(true)
  })

  it('should reject invalid email', () => {
    const invalidUser = {
      id: '123',
      email: 'not-an-email',
      name: '홍길동',
      role: 'user',
      status: 'active',
    }

    const result = UserSchema.safeParse(invalidUser)
    expect(result.success).toBe(false)
  })
})
```

#### Integration Tests (통합 테스트)

**대상:**
- React Hooks (TanStack Query)
- Context Provider
- Component 상호작용

**도구:**
- @testing-library/react-hooks
- @tanstack/react-query (테스트 utils)

**예시:**
```typescript
// packages/authentication/__tests__/hooks/useSignIn.test.ts
import { renderHook, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useSignIn } from '../../src/hooks'
import { AuthProvider } from '../../src/contexts'

describe('useSignIn', () => {
  it('should sign in successfully', async () => {
    const queryClient = new QueryClient()
    const wrapper = ({ children }) => (
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          {children}
        </AuthProvider>
      </QueryClientProvider>
    )

    const { result } = renderHook(() => useSignIn(), { wrapper })

    result.current.mutate('google')

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })
  })
})
```

#### E2E Tests (End-to-End)

**대상:**
- 전체 로그인 플로우
- OAuth 콜백
- 프로필 수정 플로우

**도구:**
- Playwright

**예시:**
```typescript
// apps/web/e2e/auth/login.spec.ts
import { test, expect } from '@playwright/test'

test('should login with Google', async ({ page }) => {
  await page.goto('/login')

  await page.click('text=Google로 로그인')

  // Google OAuth 페이지 (Mock)
  await page.fill('input[type="email"]', 'test@example.com')
  await page.click('button[type="submit"]')

  // 콜백 후 리다이렉트
  await expect(page).toHaveURL('/dashboards')

  // 사용자 이름 확인
  await expect(page.locator('text=test@example.com')).toBeVisible()
})
```

### 10.2 테스트 커버리지 목표

| 레벨 | 목표 커버리지 |
|------|--------------|
| Schemas | 100% |
| Utils | 90% |
| Hooks | 80% |
| Components | 70% |
| API Routes | 80% |

### 10.3 Mock 전략

**Supabase Mock:**
- Vitest의 `vi.fn()` 사용
- Mock 대상: `supabase.auth.*`, `supabase.from()`
- 테스트마다 독립적인 Mock 인스턴스 생성

---

## 11. 사용 예시 (코드 포함)

### 11.1 기본 사용법

#### AuthProvider 설정

**파일**: `apps/web/app/layout.tsx`

```typescript
<QueryClientProvider client={queryClient}>
  <AuthProvider>
    {children}
  </AuthProvider>
</QueryClientProvider>
```

#### 인증 상태 확인

**파일**: `apps/web/app/components/Header.tsx`

```typescript
const { user, isLoading, isAuthenticated } = useAuth()

// isAuthenticated === true인 경우: user.name 접근 가능
// isAuthenticated === false인 경우: 로그인 버튼 표시
```

#### 로그인 페이지

**파일**: `apps/web/app/login/page.tsx`

```typescript
<GoogleLoginButton
  redirectTo="/dashboards"
  onSuccess={() => router.push('/dashboards')}
  onError={(error) => toast.error(error.message)}
/>

<KakaoLoginButton
  redirectTo="/dashboards"
  onSuccess={() => router.push('/dashboards')}
  onError={(error) => toast.error(error.message)}
/>
```

### 11.2 다른 Feature Module에서 사용

#### Dashboard Feature Module

```typescript
// packages/dashboard/src/components/DashboardPage.tsx
const { user, isAuthenticated } = useAuth()

if (!isAuthenticated) {
  return <LoginPrompt />
}

return <h1>{user.name}님의 대시보드</h1>
```

#### Subscription Feature Module

```typescript
// packages/subscription/src/hooks/useSubscription.ts
const { user } = useAuth()

return useQuery({
  queryKey: ['subscription', user?.id],
  queryFn: () => fetchSubscription(user!.id),
  enabled: !!user,  // user 존재 시에만 실행
})
```

#### Admin Console Feature Module

```typescript
// packages/admin-console/src/components/AdminDashboard.tsx
const { user } = useAuth()

if (user?.role !== 'admin') {
  return <Navigate to="/403" />
}
```

### 11.3 에러 처리 예시

```typescript
const { mutate: signIn, isPending } = useSignIn()

signIn({ provider: 'google' }, {
  onError: (error) => {
    // 에러 코드 기반 처리
    if (error.code === 'AUTH_ACCOUNT_INACTIVE') {
      toast.error('비활성화된 계정입니다')
    } else if (error.code === 'AUTH_OAUTH_ERROR') {
      toast.error('로그인 실패')
    }
  }
})
```

### 11.4 프로필 수정 예시

```typescript
const { user } = useAuth()
const { mutate: updateProfile, isPending } = useUpdateProfile()

updateProfile(
  { name: '새 이름', avatar: 'https://...' },
  {
    onSuccess: () => toast.success('업데이트 완료'),
    onError: (error) => toast.error(error.message)
  }
)
```

---

## 12. 에러 코드 목록

### 12.1 에러 코드 상수

**파일**: `packages/authentication/src/utils/error-codes.ts`

```typescript
export const AuthErrorCode = {
  // 인증 실패
  INVALID_CREDENTIALS: 'AUTH_INVALID_CREDENTIALS',
  ACCOUNT_INACTIVE: 'AUTH_ACCOUNT_INACTIVE',
  SESSION_EXPIRED: 'AUTH_SESSION_EXPIRED',
  UNAUTHORIZED: 'AUTH_UNAUTHORIZED',
  FORBIDDEN: 'AUTH_FORBIDDEN',

  // OAuth 관련
  OAUTH_PROVIDER_ERROR: 'AUTH_OAUTH_PROVIDER_ERROR',
  OAUTH_CALLBACK_ERROR: 'AUTH_OAUTH_CALLBACK_ERROR',
  INVALID_PROVIDER: 'AUTH_INVALID_PROVIDER',

  // 계정 연결
  PROVIDER_ALREADY_LINKED: 'AUTH_PROVIDER_ALREADY_LINKED',
  PROVIDER_NOT_LINKED: 'AUTH_PROVIDER_NOT_LINKED',
  CANNOT_UNLINK_LAST_PROVIDER: 'AUTH_CANNOT_UNLINK_LAST_PROVIDER',

  // 검증
  VALIDATION_ERROR: 'AUTH_VALIDATION_ERROR',
  INVALID_INPUT: 'AUTH_INVALID_INPUT',

  // 서버 에러
  DATABASE_ERROR: 'DATABASE_ERROR',
  NETWORK_ERROR: 'NETWORK_ERROR',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const

export type AuthErrorCodeType = typeof AuthErrorCode[keyof typeof AuthErrorCode]
```

### 12.2 에러 메시지 매핑

```typescript
// packages/authentication/src/utils/error-messages.ts
export const AuthErrorMessages: Record<AuthErrorCodeType, string> = {
  // 인증 실패
  AUTH_INVALID_CREDENTIALS: '이메일 또는 비밀번호가 올바르지 않습니다.',
  AUTH_ACCOUNT_INACTIVE: '비활성화된 계정입니다. 관리자에게 문의하세요.',
  AUTH_SESSION_EXPIRED: '세션이 만료되었습니다. 다시 로그인해주세요.',
  AUTH_UNAUTHORIZED: '인증이 필요합니다.',
  AUTH_FORBIDDEN: '권한이 없습니다.',

  // OAuth
  AUTH_OAUTH_PROVIDER_ERROR: 'OAuth 인증 중 오류가 발생했습니다.',
  AUTH_OAUTH_CALLBACK_ERROR: 'OAuth 콜백 처리 중 오류가 발생했습니다.',
  AUTH_INVALID_PROVIDER: '지원하지 않는 Provider입니다.',

  // 계정 연결
  AUTH_PROVIDER_ALREADY_LINKED: '이미 연결된 계정입니다.',
  AUTH_PROVIDER_NOT_LINKED: '연결되지 않은 계정입니다.',
  AUTH_CANNOT_UNLINK_LAST_PROVIDER: '마지막 연결 계정은 해제할 수 없습니다.',

  // 검증
  AUTH_VALIDATION_ERROR: '입력값이 올바르지 않습니다.',
  AUTH_INVALID_INPUT: '유효하지 않은 입력입니다.',

  // 서버
  DATABASE_ERROR: '데이터베이스 오류가 발생했습니다.',
  NETWORK_ERROR: '네트워크 오류가 발생했습니다.',
  INTERNAL_ERROR: '서버 오류가 발생했습니다.',
}
```

### 12.3 에러 처리 유틸리티

**파일**: `packages/authentication/src/utils/error-handler.ts`

**시그니처:**
```typescript
export function getErrorMessage(code: string): string

export function isAuthError(error: any): error is AuthError
```

**사용 예시:**
```typescript
if (isAuthError(error)) {
  toast.error(getErrorMessage(error.code))
}
```

---

## 13. 데이터베이스 스키마

### 13.1 public.users 테이블

```sql
-- 사용자 프로필 테이블
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  avatar TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_status ON public.users(status);

-- RLS 활성화
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- RLS 정책: 사용자는 자신의 프로필만 조회
CREATE POLICY "Users can view their own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

-- RLS 정책: 사용자는 자신의 프로필만 수정
CREATE POLICY "Users can update their own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- RLS 정책: 관리자는 모든 사용자 조회 가능
CREATE POLICY "Admins can view all users"
  ON public.users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RLS 정책: 관리자는 모든 사용자 수정 가능
CREATE POLICY "Admins can update all users"
  ON public.users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 13.2 Trigger: auth.users → public.users 자동 생성

```sql
-- auth.users INSERT 시 public.users 자동 생성
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role, status)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    CASE
      -- MASTER_ADMIN_EMAIL 환경 변수와 비교
      WHEN NEW.email = current_setting('app.settings.master_admin_email', true)
      THEN 'admin'
      ELSE 'user'
    END,
    'active'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger 생성
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### 13.3 updated_at 자동 업데이트 Trigger

```sql
-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger 생성
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
```

---

## 14. 향후 확장

### 14.1 Email/Password 로그인 추가

현재는 OAuth만 지원하지만, 향후 email/password 로그인 추가 가능:

**추가 필요 사항:**
- `SignUpSchema`: email, password, name 검증
- `useSignUp()`: 회원가입 Mutation Hook
- `useSignIn()` 확장: email/password 지원

### 14.2 2FA (Two-Factor Authentication)

**추가 필요 사항:**
- Supabase TOTP 기반 2FA 지원
- `useEnableTwoFactor()`: 2FA 활성화 Hook
- `useVerifyTwoFactor()`: 2FA 검증 Hook

### 14.3 Passkey (WebAuthn)

Supabase WebAuthn (Passkey) 지원 예정.

---

## 15. 참고 자료

### 15.1 공식 문서

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [TanStack Query Documentation](https://tanstack.com/query/latest)
- [Zod Documentation](https://zod.dev)
- [Next.js App Router](https://nextjs.org/docs/app)

### 15.2 관련 문서

- [Integration Contract](../../inception/units/integration_contract.md)
- [Authentication Unit](../../inception/units/authentication.md)
- [Construction Plan](./plan.md)

### 15.3 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2025-10-13 | 1.0.0 | 초기 설계 문서 작성 |

---

**문서 끝**
