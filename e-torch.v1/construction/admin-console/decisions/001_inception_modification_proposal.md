# Inception 단계 문서 수정 제안서

## 배경

DDD 도메인 모델 설계 과정에서 Admin Console Unit의 Aggregate 구조를 분석한 결과, 다음과 같은 결정이 내려졌습니다:

1. **User Aggregate 제거**: Admin Console에서 User Aggregate를 제거하고, 사용자 관리 기능을 Authentication Unit과 Subscription Unit에 위임
2. **ActivityLog Aggregate 추가**: 모든 관리자 작업에 대한 감사 로그를 독립 Aggregate로 분리
3. **AuthenticationContract 확장**: 계정 활성화/비활성화 기능 추가

이러한 변경사항을 반영하기 위해 Inception 단계 문서들을 수정해야 합니다.

## 영향 받는 문서

1. `docs/aidlc/inception/units/integration_contract.md`
2. `docs/aidlc/inception/units/authentication.md`
3. `docs/aidlc/inception/units/admin-console.md`

---

## 1. integration_contract.md 수정사항

### 수정 1-1: User 타입에 status 필드 추가

**위치**: Lines 326-333

**현재 코드**:
```typescript
interface User {
  id: string
  email: string
  name: string
  avatar?: string
  role: 'user' | 'admin'
  linkedProviders?: Array<'google' | 'kakao'>  // 연결된 SNS 계정 목록 (US1.2)
}
```

**수정 후**:
```typescript
interface User {
  id: string
  email: string
  name: string
  avatar?: string
  role: 'user' | 'admin'
  status: 'active' | 'inactive'  // 계정 활성화 상태 (관리자가 제어)
  linkedProviders?: Array<'google' | 'kakao'>  // 연결된 SNS 계정 목록 (US1.2)
}
```

**변경 근거**:
- AdminUserView (Line 704)에는 이미 status 필드가 정의되어 있음
- User 기본 타입과 AdminUserView 간의 일관성 확보
- 계정 활성화/비활성화 기능 구현을 위해 필수

**User.email 필드 참고**:
- E-Torch는 자체 이메일/비밀번호 회원가입이 없음 (US1.1 참조)
- User.email은 SNS 계정(Google/Kakao)에서 제공받은 이메일 주소
- 첫 SNS 로그인 시 자동으로 계정 생성되며, 이때 email 저장
- 같은 이메일로 다른 provider 로그인 시 자동 계정 통합 (Supabase Account Linking)

**영향도**:
- **낮음**: 새 필드 추가는 기존 코드에 영향을 주지 않음
- 기본값: 'active' (신규 사용자는 모두 활성 상태로 시작)
- SNS 로그인 시 계정 생성과 동시에 status='active' 설정

---

### 수정 1-2: AuthenticationContract에 계정 상태 관리 메서드 추가

**위치**: Lines 185-207

**현재 코드**:
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

  // 권한 확인
  isAuthenticated(): boolean
  hasRole(role: 'user' | 'admin'): boolean

  // Context Provider
  AuthProvider: React.FC<{children: React.ReactNode}>
  useAuth: () => AuthContext
}
```

**수정 후**:
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

**변경 근거**:
- US6.3에서 "계정 활성화/비활성화" 기능 요구
- 사용자 인증 및 계정 관리는 Authentication Unit의 핵심 책임
- Admin Console은 이 메서드를 호출하여 계정 상태를 변경하고, ActivityLog에 기록

**메서드 상세**:
- **메서드 이름**: `activateUser()` / `deactivateUser()`
  - 명시적인 두 개의 메서드로 분리 (DDD Ubiquitous Language)
  - boolean 파라미터보다 의도가 명확함
- **파라미터**:
  - `userId: string` - 대상 사용자 ID
  - `reason: string` - 변경 사유 (필수, 빈 문자열 시 에러)
- **반환값**: `Promise<User>` - 업데이트된 사용자 정보 (status 필드 포함)
- **권한 검증**:
  - 내부에서 `getCurrentUser()`로 호출자 확인
  - `currentUser.role !== 'admin'` 시 UnauthorizedError
  - Admin Console은 별도 권한 검증 불필요

**메서드 부작용**:

**deactivateUser():**
- `User.status`를 `'inactive'`로 변경
- 이후 모든 API 요청이 **인증 미들웨어**에서 차단됨
- 미들웨어는 매 요청마다 `User.status`를 확인하여 비활성 계정 차단
- Supabase 세션은 자연 만료됨 (명시적 revoke 없음)
- 비활성 계정의 SNS 로그인 시도 시 명확한 오류 메시지 반환

**activateUser():**
- `User.status`를 `'active'`로 변경
- 기존 Supabase 세션이 있다면 즉시 사용 가능
- 이후 API 요청이 정상 처리됨

**보안 보장 방식**:
- 세션 무효화는 메서드 책임이 아님
- 인증 미들웨어가 매 요청마다 `User.status` 확인 (캐싱 가능)
- 업계 표준 패턴: User와 Session 분리, 미들웨어 검증

**중요**: E-Torch는 SNS 로그인만 지원하며, 이메일/비밀번호 로그인은 존재하지 않습니다 (US1.1 참조)

**영향도**:
- **중간**: Authentication Unit에 새로운 메서드 구현 필요
- Admin Console Unit은 이 메서드를 사용하도록 수정 필요

---

### 수정 1-3: AdminConsoleContract의 계정 상태 관리 메서드 수정

**위치**: Line 271-276

**현재 코드**:
```typescript
// 사용자 관리
getUsers(filters?: UserFilters): Promise<AdminUserView[]>
updateUserSubscription(userId: string, plan: 'free' | 'pro', expiryDate?: Date, reason: string): Promise<void>
toggleUserStatus(userId: string, active: boolean, reason: string): Promise<void>
getUserActivityLog(userId: string): Promise<ActivityLog[]>
```

**수정 후**:
```typescript
// 사용자 관리 (Authentication Unit과 Subscription Unit에 위임)
getUsers(filters?: UserFilters): Promise<AdminUserView[]>
updateUserSubscription(userId: string, plan: 'free' | 'pro', expiryDate?: Date, reason: string): Promise<void>
// Authentication Unit에 위임 + ActivityLog 기록
activateUser(userId: string, reason: string): Promise<User>
deactivateUser(userId: string, reason: string): Promise<User>
getUserActivityLog(userId: string): Promise<ActivityLog[]>
```

**변경 근거**:
- AuthenticationContract와 일관성 유지 (activateUser/deactivateUser)
- Admin Console은 Application Service 레벨의 오케스트레이션 담당
- 실제 계정 상태 변경은 Authentication Unit에 위임
- 변경 사유(reason)는 Admin Console이 ActivityLog Aggregate에 기록

**메서드 변경사항**:
- **메서드 분리**: toggleUserStatus → activateUser + deactivateUser
- **반환 타입 변경**: Promise<void> → Promise<User>
  - 업데이트된 User 정보를 반환하여 UI 즉시 갱신 가능
  - ActivityLog 기록 시 변경 후 상태 확인 가능

**구현 패턴**:
```typescript
// Admin Console Application Service 수도코드
class UserManagementApplicationService {
  async activateUser(userId: string, reason: string): Promise<User> {
    // 1. Authentication Unit에 위임하여 실제 상태 변경
    const updatedUser = await authenticationContract.activateUser(userId, reason);

    // 2. ActivityLog Aggregate에 감사 로그 기록
    await activityLogRepository.save({
      userId,
      action: 'USER_ACTIVATED',
      resourceType: 'USER',
      resourceId: userId,
      details: {
        reason,
        changedBy: this.authContext.getCurrentUser().id,
        previousStatus: 'inactive',
        newStatus: 'active'
      },
      createdAt: new Date()
    });

    return updatedUser;
  }

  async deactivateUser(userId: string, reason: string): Promise<User> {
    // 1. Authentication Unit에 위임하여 실제 상태 변경
    const updatedUser = await authenticationContract.deactivateUser(userId, reason);

    // 2. ActivityLog Aggregate에 감사 로그 기록
    await activityLogRepository.save({
      userId,
      action: 'USER_DEACTIVATED',
      resourceType: 'USER',
      resourceId: userId,
      details: {
        reason,
        changedBy: this.authContext.getCurrentUser().id,
        previousStatus: 'active',
        newStatus: 'inactive'
      },
      createdAt: new Date()
    });

    return updatedUser;
  }
}
```

**영향도**:
- **중간**: AdminConsoleContract 인터페이스 변경
- integration_contract.md Line 271-276 수정 완료됨
- Admin Console Application Service 구현 필요

---

### 수정 1-4: AuthContext 타입에 status 필드 반영 여부

**위치**: Lines 680-687

**현재 코드**:
```typescript
interface AuthContext {
  user: User | null
  session: Session | null
  isAuthenticated: boolean
  signIn: (provider: 'google' | 'kakao') => Promise<void>
  signOut: () => Promise<void>
  refreshSession: () => Promise<void>
}
```

**검토 사항**:
- User 타입에 status 필드가 추가되므로 자동으로 AuthContext.user에도 반영됨
- 추가 수정 불필요

**영향도**:
- **없음**: 타입 의존성으로 자동 반영

---

## 2. authentication.md 수정사항

### 수정 2-1: "출력 제공" 섹션에 계정 상태 관리 추가

**위치**: Lines 66-87

**현재 코드**:
```markdown
### 출력 제공

다른 Unit에서 사용 가능한 기능 (상세 인터페이스는 integration_contract.md 참조):

- **모든 Unit에 제공**:
  - 인증 상태 확인
    - 현재 로그인 사용자 정보 조회
    - 세션 유효성 검증
  - 권한 확인
    - 사용자 역할 확인 (user/admin)
    - 보호된 리소스 접근 권한 검증
  - 세션 관리
    - 토큰 갱신
    - 로그아웃 처리
  - SNS 계정 연결 관리 (US1.2)
    - 추가 SNS 계정 연결
    - 연결된 SNS 계정 해제
    - 연결된 계정 목록 조회

- **Admin Console Unit에 제공**:
  - 관리자 권한 검증
  - 역할 기반 접근 제어
```

**수정 후**:
```markdown
### 출력 제공

다른 Unit에서 사용 가능한 기능 (상세 인터페이스는 integration_contract.md 참조):

- **모든 Unit에 제공**:
  - 인증 상태 확인
    - 현재 로그인 사용자 정보 조회
    - 세션 유효성 검증
  - 권한 확인
    - 사용자 역할 확인 (user/admin)
    - 보호된 리소스 접근 권한 검증
  - 세션 관리
    - 토큰 갱신
    - 로그아웃 처리
  - SNS 계정 연결 관리 (US1.2)
    - 추가 SNS 계정 연결
    - 연결된 SNS 계정 해제
    - 연결된 계정 목록 조회

- **Admin Console Unit에 제공**:
  - 관리자 권한 검증
  - 역할 기반 접근 제어
  - 계정 상태 관리
    - 사용자 계정 활성화/비활성화
    - 비활성 계정 로그인 차단
```

**변경 근거**:
- US6.3 "계정 활성화/비활성화" 기능이 Authentication Unit의 책임임을 명확히 함
- Admin Console Unit과의 인터페이스 계약을 문서화

**영향도**:
- **낮음**: 문서 보완 수준

---

### 수정 2-2: 보안 요구사항에 계정 상태 검증 추가

**위치**: Lines 110-118

**현재 코드**:
```markdown
## 보안 요구사항

- 사용자 인증 토큰이 안전하게 저장되어야 한다
- 전송 중 인증 데이터가 보호되어야 한다
- XSS 공격으로부터 보호되어야 한다
- 세션 고정 공격이 방지되어야 한다
- CSRF 공격으로부터 보호되어야 한다
- 인가되지 않은 OAuth 리다이렉트가 차단되어야 한다
```

**수정 후**:
```markdown
## 보안 요구사항

- 사용자 인증 토큰이 안전하게 저장되어야 한다
- 전송 중 인증 데이터가 보호되어야 한다
- XSS 공격으로부터 보호되어야 한다
- 세션 고정 공격이 방지되어야 한다
- CSRF 공격으로부터 보호되어야 한다
- 인가되지 않은 OAuth 리다이렉트가 차단되어야 한다
- 비활성화된 계정(status: 'inactive')의 로그인이 차단되어야 한다
- 계정 상태 변경은 관리자 권한을 가진 사용자만 수행할 수 있어야 한다
```

**변경 근거**:
- 계정 비활성화 기능의 보안 요구사항 명시
- SNS 로그인(Google, Kakao) 시 status 검증 필수
- E-Torch는 SNS 로그인만 지원하므로 OAuth 콜백 처리 시 검증

**영향도**:
- **중간**: Authentication Unit의 SNS 로그인 로직에 status 검증 추가 필요
- Supabase Auth의 signIn() 호출 직후 User.status 확인

---

## 3. admin-console.md 수정사항

### 수정 3-1: US6.3 설명 보완

**위치**: Lines 55-71

**현재 코드**: (변경 없음)

**제안**: 현재 설명이 충분히 명확하므로 수정 불필요

**검토 사항**:
- US6.3의 검증 기준이 이미 명확하게 기술되어 있음
- "사용자 목록 조회", "플랜 수동 변경", "계정 활성화/비활성화" 모두 명시됨
- Admin Console이 다른 Unit에 위임한다는 점은 Construction 단계에서 다룰 내용

**영향도**:
- **없음**: 수정 불필요

---

## 요약

### 필수 수정사항

| 문서 | 섹션 | 변경 내용 | 우선순위 |
|------|------|----------|---------|
| integration_contract.md | User 타입 | status 필드 추가 | 높음 |
| integration_contract.md | AuthenticationContract | activateUser/deactivateUser 메서드 추가 | 높음 |
| integration_contract.md | AdminConsoleContract | activateUser/deactivateUser로 메서드 변경 | 높음 |
| authentication.md | 출력 제공 | 계정 상태 관리 기능 추가 | 중간 |
| authentication.md | 보안 요구사항 | 계정 상태 검증 요구사항 추가 | 중간 |

### 영향도 평가

**1. User 타입 수정**
- ✅ 하위 호환성: 유지됨 (새 필드 추가만)
- ✅ 기존 코드: 영향 없음
- ⚠️ 데이터베이스: 마이그레이션 필요 (기본값: 'active')

**2. AuthenticationContract 확장**
- ✅ 하위 호환성: 유지됨 (메서드 추가만)
- ⚠️ Authentication Unit: 새 메서드 구현 필요
- ⚠️ Admin Console: 기존 toggleUserStatus 로직 수정 필요

**3. 문서 보완**
- ✅ 문서만 수정, 코드 영향 없음

### 미래 문제 예방

**1. 데이터 일관성**
- User.status와 인증 상태 간 일관성 보장
- 비활성 사용자의 API 접근 차단: **인증 미들웨어**가 매 요청마다 User.status 확인
- 세션 무효화는 명시적으로 수행하지 않음 (Supabase 세션 자연 만료)
- SNS 로그인 플로우:
  - OAuth 콜백 → Supabase 세션 생성 → User.status 확인 → 'inactive'이면 로그인 차단
- API 요청 플로우:
  - 요청 수신 → 미들웨어가 Supabase 세션 검증 → User.status 확인 → 'inactive'이면 401 Unauthorized

**2. 감사 로그**
- ActivityLog Aggregate를 통해 모든 상태 변경 기록
- 변경 사유(reason) 필수 입력
- 변경 주체(changedBy) 추적

**3. 사용자 경험**
- 비활성 계정 로그인 시도 시 명확한 안내 메시지
- 관리자에게 비활성화 사유 전달 방법 제공

**4. 테스트 요구사항**
- 비활성 계정 SNS 로그인 차단 테스트 (Google, Kakao 각각)
- 활성 세션 중 계정 비활성화 테스트 (다음 API 요청부터 401 확인)
- 인증 미들웨어의 User.status 검증 테스트
- 권한 검증 테스트 (getCurrentUser()로 admin 확인)
- linkedProviders가 여러 개인 사용자의 비활성화 테스트 (모든 provider 차단 확인)
- activateUser/deactivateUser 메서드의 reason 필수 검증 테스트

---

## 승인 후 작업 순서

1. **integration_contract.md 수정**
   - User 타입에 status 필드 추가
   - AuthenticationContract에 activateUser/deactivateUser 메서드 추가
   - AdminConsoleContract에 activateUser/deactivateUser 메서드 변경

2. **authentication.md 수정**
   - 출력 제공 섹션에 계정 상태 관리 추가
   - 보안 요구사항에 계정 상태 검증 추가

3. **plan_construction_admin-console.md 업데이트**
   - 6개 Aggregate → 5개 Aggregate + ActivityLog로 수정
   - User Aggregate 제거 근거 문서화
   - ActivityLog Aggregate 추가 근거 문서화

4. **Construction 단계 진행**
   - 미답변 질문들 계속 답변
   - domain_model.md 작성

---

---

## 4. 법적 보호 및 컨텐츠 관리 기능 추가

### 배경

E-Torch의 법적 리스크 분석 결과, 다음과 같은 보호 장치가 필요함:

**핵심 리스크:**
- 대시보드가 투자 권유로 오해받을 위험
- 전문가 콘텐츠가 "투자 조언"으로 해석될 가능성
- 한국 자본시장법상 무등록 투자자문업 제재 위험

**해결 방안:**
1. **사전 예방**: 대시보드 생성 시 법적 동의 필수
2. **명확한 면책**: 사용자 조회 시 투자 권고 아님 고지
3. **사후 관리**: 신고 시스템 + 자동 모니터링
4. **법적 증거**: 모든 동의 내역 로그 저장

이는 비즈니스 성장과 법적 안정성의 균형을 위한 필수 기능입니다.

---

### 수정 4-1: dashboard.md에 법적 보호 사용자 스토리 추가

**파일**: `docs/aidlc/inception/units/dashboard.md`

#### US2.12: 대시보드 생성 시 법적 동의

**추가 위치**: US2.11 이후

```markdown
### US2.12: 대시보드 생성 시 법적 동의

**As a** 대시보드 작성자
**I want to** 대시보드 생성 시 법적 동의 사항을 확인하고
**So that** 투자 권고가 아님을 명확히 인지하고 법적 책임을 이해할 수 있다

**검증 기준**:

- Given: 로그인한 사용자가 대시보드 생성 시도
- When: 대시보드 생성 폼 제출
- Then: 필수 동의 체크박스 표시
- And: 다음 항목을 체크해야만 게시 가능:
  - "본인이 작성하는 대시보드는 개인 의견이며 투자 권고가 아닙니다"
  - "특정 종목의 직접적 매수/매도를 권유하지 않겠습니다"
  - "투자 손실에 대한 법적 책임이 없음을 이해합니다"
- And: 금지 사항 예시 명확히 표시:
  - ❌ "삼성전자 지금 사세요"
  - ❌ "100% 수익 보장"
  - ❌ "내일 급등 3종목"
- And: 위반 시 계정 제재 가능성 경고
- And: 동의 내역 로그로 저장 (userId, dashboardId, IP, User-Agent, timestamp)
- And: 동의 문구 버전 관리 (약관 변경 추적)

**기술 요구사항**:

- ConsentLog 저장 (법적 증거 확보)
- 3년 이상 로그 보관
- 동의 시점의 IP 주소 및 User-Agent 기록
```

#### US2.13: 대시보드 조회 시 면책 조항

**추가 위치**: US2.12 이후

```markdown
### US2.13: 대시보드 조회 시 면책 조항

**As a** 대시보드 조회자
**I want to** 최초 조회 시 면책 조항을 확인하고
**So that** E-Torch가 정보 제공 플랫폼임을 명확히 인지할 수 있다

**검증 기준**:

- Given: 사용자의 최초 대시보드 조회
- When: 대시보드 페이지 진입
- Then: 면책 모달 표시 (1회만)
- And: 면책 내용 명확히 고지:
  - "E-Torch의 모든 대시보드는 작성자 개인의 분석 의견입니다"
  - "투자 권고가 아니며, E-Torch는 내용의 정확성을 보증하지 않습니다"
  - "투자 결정의 책임은 전적으로 이용자 본인에게 있습니다"
  - "투자에는 원금 손실 위험이 있습니다"
- And: "이해했으며, 다시 보지 않기" 체크박스 제공
- And: 동의 여부 로그 저장 (consentType: 'disclaimer_view')
- And: 모든 대시보드 하단에 간단한 면책 배너 고정 표시:
  - "ℹ️ 이 대시보드는 투자 권고가 아닙니다"

**UI/UX 요구사항**:

- 모달은 대시보드 내용을 가리지 않되, 반드시 확인해야 조회 가능
- 면책 배너는 눈에 띄되 사용자 경험 해치지 않도록
```

#### US2.14: 대시보드 신고

**추가 위치**: US2.13 이후

```markdown
### US2.14: 대시보드 신고

**As a** 사용자
**I want to** 부적절한 투자 권유나 사기성 대시보드를 신고하고
**So that** 플랫폼 품질을 유지하고 다른 사용자를 보호할 수 있다

**검증 기준**:

- Given: 대시보드를 조회하는 사용자
- When: 신고 버튼 클릭
- Then: 신고 사유 선택 옵션 표시:
  - 투자 권유 (특정 종목 매수/매도 직접 추천)
  - 사기성 내용 (허위 정보, 수익 보장 주장)
  - 스팸/광고 (유료 시그널 서비스 홍보 등)
  - 기타 (상세 설명 입력)
- And: 신고 내역은 Admin Console로 전달
- And: 신고자 익명성 보장 (작성자에게 신고자 정보 비공개)
- And: 중복 신고 방지 (동일 사용자가 같은 대시보드 재신고 불가)
- And: 신고 완료 시 확인 메시지:
  - "신고가 접수되었습니다. 48시간 내 검토 예정입니다"

**비기능 요구사항**:

- 신고 내역 최소 1년 보관
- 악의적 신고 남용 방지 (과도한 신고 시 신고자 제재)
```

**변경 근거:**
- 법적 리스크 최소화 (투자자문업 무등록 영업 제재 예방)
- 플랫폼 책임 명확화 (정보 제공 플랫폼 지위 확보)
- 사용자 보호 (사기성 콘텐츠 차단)
- 법적 증거 확보 (동의 로그를 통한 선의의 노력 입증)

**영향도:**
- **높음**: 출시 전 필수 구현 (법적 보호 핵심)
- Dashboard Unit의 핵심 플로우 변경 (생성/조회 시 추가 단계)
- 새로운 Aggregate 필요 가능성 (ConsentLog, DashboardReport)

---

### 수정 4-2: admin-console.md에 컨텐츠 관리 사용자 스토리 추가

**파일**: `docs/aidlc/inception/units/admin-console.md`

#### US6.9: 신고된 컨텐츠 관리

**추가 위치**: US6.8 이후

```markdown
### US6.9: 신고된 컨텐츠 관리

**As a** 관리자
**I want to** 신고된 대시보드를 검토하고 적절한 조치를 취하여
**So that** 불법 투자 권유를 차단하고 플랫폼 품질을 유지할 수 있다

**검증 기준**:

- Given: 관리자 권한 및 신고 접수된 대시보드
- When: 컨텐츠 관리 페이지 접속
- Then: 신고된 대시보드 목록 조회
  - 신고 사유 (투자 권유, 사기, 스팸 등)
  - 신고 접수 일시 (최신순 정렬)
  - 신고자 수 (중복 신고 집계)
  - 대시보드 제목, 작성자, 내용 미리보기
  - 상태 (대기, 검토 중, 조치 완료)
- And: 대시보드 상세 검토
  - 원본 내용 전체 확인
  - 작성자 이력 조회 (이전 위반 내역)
  - 위반 여부 판단 근거 메모
- And: 조치 실행 옵션:
  - **경고**: 작성자에게 경고 메시지 발송 (1회 기록)
  - **삭제**: 대시보드 즉시 삭제 (복구 불가)
  - **계정 정지**: 작성자 게시 제한 (48시간)
  - **무혐의**: 신고 각하 (사유 기록)
- And: 조치 사유 필수 기록
  - 어떤 부분이 문제인지 구체적 명시
  - 작성자와 신고자에게 결과 통보
- And: 조치 내역 ActivityLog에 자동 기록

**비기능 요구사항**:

- 신고 접수 후 48시간 내 1차 검토
- 조치 내역 영구 보관 (법적 분쟁 대비)
```

#### US6.10: 컨텐츠 위반 사용자 관리

**추가 위치**: US6.9 이후

```markdown
### US6.10: 컨텐츠 위반 사용자 관리

**As a** 관리자
**I want to** 위반 이력이 누적된 사용자를 관리하여
**So that** 반복 위반자를 효과적으로 제재할 수 있다

**검증 기준**:

- Given: 관리자 권한
- When: 사용자 위반 관리 페이지 접속
- Then: 사용자별 위반 이력 조회
  - 경고 횟수 (누적)
  - 삭제된 대시보드 수
  - 마지막 위반 날짜
  - 누적 신고 수 (정당한 신고만 집계)
  - 위반 유형별 분류 (투자 권유, 사기, 스팸)
- And: 단계적 제재 시스템 자동 적용:
  - **1회 경고**: 이메일 + 앱 내 알림
  - **2회 경고**: 48시간 게시 제한
  - **3회 위반**: 계정 영구 정지
- And: 수동 제재 옵션
  - 관리자 판단으로 즉시 정지
  - 제재 사유 상세 기록
- And: 제재 내역 사용자에게 통보
  - 위반 사유, 제재 기간, 이의 제기 방법
- And: 제재 내역 ActivityLog 기록

**비기능 요구사항**:

- 제재 이력 영구 보관
- 이의 제기 시 재검토 프로세스
```

#### US6.11: 위험 컨텐츠 자동 탐지

**추가 위치**: US6.10 이후

```markdown
### US6.11: 위험 컨텐츠 자동 탐지

**As a** 관리자
**I want to** 위험 키워드가 포함된 대시보드를 자동으로 플래깅하여
**So that** 문제 콘텐츠를 빠르게 발견하고 대응할 수 있다

**검증 기준**:

- Given: 관리자 권한 및 자동 탐지 시스템 운영
- When: 자동 탐지 결과 페이지 접속
- Then: 매일 자동 스캔 실행 (신규/수정 대시보드 대상)
- And: 위험 패턴 탐지:
  - 특정 종목명 + 행동 유도 ("삼성전자 사세요")
  - 수익 보장 표현 ("100% 수익", "반드시 오른다")
  - 타이밍 단정 ("내일 급등", "곧 폭등")
  - 외부 유료 서비스 링크 ("텔레그램", "카톡방")
- And: 플래깅된 대시보드 목록
  - 탐지된 키워드 하이라이트 표시
  - 위험도 점수 (높음/중간/낮음)
  - 작성자 정보 및 이전 위반 이력
- And: 자동 조치 설정 (선택 사항):
  - **높음**: 즉시 비공개 + 작성자 알림
  - **중간**: 검토 대기열 추가
  - **낮음**: 로그만 기록, 공개 유지
- And: 오탐 처리
  - 관리자가 "문제 없음" 판정 가능
  - 오탐으로 판정된 패턴 학습 (재탐지 방지)

**기술 요구사항**:

- 키워드 룰 엔진 (정규표현식 기반)
- 탐지 룰 버전 관리 (언제든 수정 가능)
- 일일 배치 스케줄러
```

**변경 근거:**
- 플랫폼 책임 (콘텐츠 방치 시 공동 책임 가능성)
- 선제적 대응 (문제 발생 전 차단)
- 운영 효율성 (수동 검토만으로는 불가능)
- 법적 방어 (선의의 관리 노력 입증)

**영향도:**
- **높음**: Admin Console의 새로운 핵심 기능
- 새로운 도메인 개념 추가 (ViolationLog, DetectionRule)
- 배치 작업 인프라 필요

---

### 수정 4-3: integration_contract.md에 법적 보호 타입 및 메서드 추가

**파일**: `docs/aidlc/inception/units/integration_contract.md`

#### 새로운 공통 타입 추가

**추가 위치**: 공통 타입 섹션 (Line 320 이후)

```typescript
// ============================================
// 법적 보호 및 컨텐츠 관리 타입
// ============================================

// 동의 로그 (법적 증거)
interface ConsentLog {
  id: string
  userId: string
  dashboardId?: string  // 대시보드 생성 시에만
  consentType: 'dashboard_create' | 'disclaimer_view'
  consentText: string  // 실제 동의한 문구 전문
  consentVersion: string  // 약관 버전 (예: "v1.0")
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
  detectedPattern?: string  // 자동 탐지 시 매칭된 패턴
  status: 'pending' | 'confirmed' | 'dismissed'
  actionTaken?: 'warning' | 'delete_dashboard' | 'suspend_user' | 'none'
  actionReason?: string
  reviewedBy?: string  // 관리자 ID
  createdAt: Date
  reviewedAt?: Date
}

// 대시보드 신고
interface DashboardReport {
  id: string
  dashboardId: string
  reporterId: string  // 신고자 (익명 처리됨)
  reason: 'investment_advice' | 'scam' | 'false_info' | 'spam' | 'other'
  description?: string  // 상세 설명
  status: 'pending' | 'under_review' | 'actioned' | 'dismissed'
  reviewNote?: string  // 관리자 검토 의견
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

// 탐지 룰
interface DetectionRule {
  id: string
  name: string
  pattern: string  // 정규표현식
  severity: 'low' | 'medium' | 'high'
  action: 'flag' | 'auto_hide' | 'auto_delete'
  isActive: boolean
  description: string
  createdAt: Date
}
```

#### DashboardContract 메서드 추가

**추가 위치**: DashboardContract 인터페이스 내

```typescript
interface DashboardContract {
  // ... 기존 메서드 ...

  // 신고 (US4.11)
  reportDashboard(
    dashboardId: string,
    reason: 'investment_advice' | 'scam' | 'false_info' | 'spam' | 'other',
    description?: string
  ): Promise<void>

  // 동의 로그 기록 (내부용)
  logConsent(
    userId: string,
    consentType: 'dashboard_create' | 'disclaimer_view',
    metadata: {
      dashboardId?: string
      consentText: string
      consentVersion: string
      ipAddress: string
      userAgent: string
    }
  ): Promise<void>

  // 사용자의 면책 조항 확인 여부 조회
  hasSeenDisclaimer(userId: string): Promise<boolean>
}
```

#### AdminConsoleContract 메서드 추가

**추가 위치**: AdminConsoleContract 인터페이스 내

```typescript
interface AdminConsoleContract {
  // ... 기존 메서드 ...

  // 신고 관리 (US6.9)
  getReportedDashboards(filters?: {
    status?: 'pending' | 'under_review' | 'actioned' | 'dismissed'
    reason?: string
    dateFrom?: Date
    dateTo?: Date
  }): Promise<DashboardReport[]>

  reviewReport(
    reportId: string,
    action: 'warning' | 'delete_dashboard' | 'suspend_user' | 'dismiss',
    reason: string
  ): Promise<void>

  // 위반 관리 (US6.10)
  getUserViolations(userId: string): Promise<ViolationLog[]>

  getViolationStats(period?: {
    from: Date
    to: Date
  }): Promise<ViolationStats>

  // 수동 제재
  suspendUser(
    userId: string,
    reason: string,
    duration?: number  // 시간 (48시간 기본)
  ): Promise<void>

  // 자동 탐지 (US6.11)
  getAutoDetectedContent(filters?: {
    severity?: 'low' | 'medium' | 'high'
    status?: 'pending' | 'reviewed'
    dateFrom?: Date
  }): Promise<Array<{
    dashboard: Dashboard
    violation: ViolationLog
  }>>

  // 탐지 룰 관리
  getDetectionRules(): Promise<DetectionRule[]>

  updateDetectionRule(
    ruleId: string,
    updates: Partial<DetectionRule>
  ): Promise<DetectionRule>

  createDetectionRule(rule: Omit<DetectionRule, 'id' | 'createdAt'>): Promise<DetectionRule>

  // 오탐 처리
  dismissViolation(violationId: string, reason: string): Promise<void>
}
```

**변경 근거:**
- 법적 보호 기능의 단위 간 계약 명확화
- ConsentLog는 모든 법적 분쟁의 1차 증거
- ViolationLog는 플랫폼의 선의의 노력 입증
- Dashboard와 Admin Console 간 신고 플로우 정의

**영향도:**
- **중간**: 타입 추가는 기존 코드 영향 없음
- DashboardContract: 2개 메서드 추가
- AdminConsoleContract: 9개 메서드 추가 (컨텐츠 관리 핵심)

---

## 요약 (업데이트)

### 필수 수정사항 (업데이트)

| 문서 | 섹션 | 변경 내용 | 우선순위 |
|------|------|----------|---------|
| integration_contract.md | User 타입 | status 필드 추가 | 높음 |
| integration_contract.md | AuthenticationContract | activateUser/deactivateUser 메서드 추가 | 높음 |
| integration_contract.md | AdminConsoleContract | activateUser/deactivateUser로 메서드 변경 | 높음 |
| **integration_contract.md** | **공통 타입** | **ConsentLog, ViolationLog, DashboardReport 추가** | **높음** |
| **integration_contract.md** | **DashboardContract** | **reportDashboard, logConsent 메서드 추가** | **높음** |
| **integration_contract.md** | **AdminConsoleContract** | **컨텐츠 관리 메서드 9개 추가** | **높음** |
| authentication.md | 출력 제공 | 계정 상태 관리 기능 추가 | 중간 |
| authentication.md | 보안 요구사항 | 계정 상태 검증 요구사항 추가 | 중간 |
| **dashboard.md** | **사용자 스토리** | **US2.12-2.14 추가 (법적 동의, 면책, 신고)** | **높음** |
| **admin-console.md** | **사용자 스토리** | **US6.9-6.11 추가 (컨텐츠 관리)** | **높음** |

### 미래 문제 예방 (추가)

**5. 법적 보호 시스템**
- ConsentLog를 통한 법적 증거 확보 (3년 이상 보관)
- 4단계 방어 체계: 사전 예방 → 자동 감지 → 신고 → 제재
- 면책 조항의 명확한 표시 및 사용자 동의 확보
- 악의적 콘텐츠 신속 대응 (48시간 내 1차 검토)

**6. 컨텐츠 품질 관리**
- 위험 패턴 자동 탐지 시스템
- 단계적 제재 (1회 경고 → 2회 제한 → 3회 정지)
- 커뮤니티 신고 시스템
- 반복 위반자 추적 및 관리

### 승인 후 작업 순서 (업데이트)

1. **integration_contract.md 수정**
   - User 타입에 status 필드 추가
   - AuthenticationContract에 activateUser/deactivateUser 메서드 추가
   - AdminConsoleContract에 activateUser/deactivateUser 메서드 변경
   - **ConsentLog, ViolationLog, DashboardReport 타입 추가**
   - **DashboardContract, AdminConsoleContract 메서드 추가**

2. **authentication.md 수정**
   - 출력 제공 섹션에 계정 상태 관리 추가
   - 보안 요구사항에 계정 상태 검증 추가

3. **dashboard.md 수정**
   - **US2.12: 대시보드 생성 시 법적 동의**
   - **US2.13: 대시보드 조회 시 면책 조항**
   - **US2.14: 대시보드 신고**

4. **admin-console.md 수정**
   - **US6.9: 신고된 컨텐츠 관리**
   - **US6.10: 컨텐츠 위반 사용자 관리**
   - **US6.11: 위험 컨텐츠 자동 탐지**

5. **plan_construction_admin-console.md 업데이트**
   - 6개 Aggregate → 5개 Aggregate + ActivityLog로 수정
   - User Aggregate 제거 근거 문서화
   - ActivityLog Aggregate 추가 근거 문서화
   - **ConsentLog, ViolationLog Aggregate 검토 필요**

6. **Construction 단계 재개**
   - 새로 추가된 도메인 개념 반영
   - domain_model.md 작성

---

## 검토 요청 사항

이 제안서를 검토해 주시고, 다음 사항들에 대한 피드백을 부탁드립니다:

1. 각 수정사항의 타당성
2. 누락된 영향 범위가 있는지
3. 추가로 고려해야 할 보안/정책 사항
4. 수정 우선순위의 적절성
5. **법적 보호 기능의 충분성 (변호사 자문 권장)**

승인 후 문서 수정을 진행하겠습니다.
