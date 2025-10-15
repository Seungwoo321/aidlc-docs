# Authentication Unit - DDD 도메인 모델 설계 계획

## 목표

Authentication Unit에 대해 도메인 주도 설계(DDD)를 사용하여 도메인 모델을 설계합니다.

## 작업 범위

- **대상 단위**: Authentication Unit (authentication.md)
- **포함된 사용자 스토리**: US1.1 ~ US1.2 (2개)
- **산출물**: `docs/aidlc/construction/authentication/domain_model.md`

## 작업 단계

### 단계 1: 도메인 분석 및 바운디드 컨텍스트 식별

- [ ] Authentication Unit의 2개 사용자 스토리 재검토
- [ ] 주요 도메인 개념 추출 및 정리
- [ ] 바운디드 컨텍스트 경계 식별
- [ ] 유비쿼터스 언어(Ubiquitous Language) 정의

**[Question]** Authentication Unit은 단일 바운디드 컨텍스트인가요? Supabase Auth와의 관계는 어떻게 모델링해야 할까요?

**[Answer]** Authentication Unit은 **단일 바운디드 컨텍스트**로 정의합니다. Supabase Auth와의 관계는 **하이브리드 접근(선택적 추상화)** 방식을 사용합니다.

- **추상화 대상**: 계정 자동 통합, 비활성 계정 차단, Provider 연결 정책 등 비즈니스 규칙
- **직접 사용 대상**: OAuth 플로우, 세션 관리, 토큰 갱신 등 Supabase 표준 기능
- **레이어 분담**:
  - Domain Layer: 정책 인터페이스 정의 (`IAccountMergePolicy`, `IAccountStatusPolicy`)
  - Infrastructure Layer: Supabase Client 직접 사용 + 정책 구현체

이 방식은 실용성과 유연성의 균형을 맞추며, 향후 필요 시 추상화 레이어를 확장할 수 있는 여지를 남깁니다.

**[Question]** User는 Authentication Unit의 Aggregate Root인가요, 아니면 여러 Unit이 공유하는 "공유 커널(Shared Kernel)"인가요?

**[Answer]** User는 **Authentication Unit의 Aggregate Root**입니다. Customer-Supplier 패턴을 적용하며, Authentication Unit이 User의 소유자(Supplier)가 됩니다.

- **Authentication Unit**: User Aggregate 정의 및 관리 (Supabase auth.users + public.user_profiles)
- **다른 Unit**: User ID로만 참조, 필요시 `getCurrentUser()` 등 인터페이스 호출
- **Admin Console**: 계정 상태 변경 시 Authentication Unit의 `activateUser()`, `deactivateUser()` 사용
- **이벤트**: User 관련 도메인 이벤트는 Authentication Unit에서 발행 (UserCreated, UserDeactivated, UserProfileUpdated 등)

이 구조는 DDD의 Bounded Context 경계를 유지하면서도 실용적인 통합을 가능하게 하며, integration_contract.md에 정의된 인터페이스와 일치합니다.

**[Question]** 계정 상태(active/inactive)는 Authentication Unit의 책임인가요, 아니면 Admin Console Unit의 책임인가요?

**[Answer]** 계정 상태(active/inactive)는 **Authentication Unit의 책임**입니다. User Aggregate의 핵심 속성으로 정의됩니다.

- **상태 저장 및 관리**: Authentication Unit의 User Aggregate
- **상태 변경 메서드**: `User.activate(reason)`, `User.deactivate(reason)`
- **불변 조건**: "비활성 계정은 로그인할 수 없다" - User Aggregate가 강제
- **Admin Console의 역할**: Authentication Unit의 인터페이스를 호출하여 상태 변경 요청
  ```
  Admin Console → Authentication.deactivateUser(userId, reason)
  ```
- **감사 로그**: Admin Console Use Case에서 기록
- **이벤트**: UserActivated, UserDeactivated 이벤트를 Authentication Unit에서 발행

이 구조는 DDD의 Aggregate 경계를 존중하면서도 Admin Console의 관리 기능을 제공합니다.

### 단계 2: 애그리게이트 식별 및 경계 정의

- [ ] 트랜잭션 일관성이 필요한 경계 식별
- [ ] 각 애그리게이트의 루트 엔티티 결정
- [ ] 애그리게이트 간 참조 방식 정의 (ID 참조 vs 객체 참조)
- [ ] 애그리게이트별 불변 조건(Invariant) 정의

**[Question]** User Aggregate는 어떤 불변 조건을 가져야 할까요? (예: 이메일 고유성, 최소 1개 Provider 연결 등)

**[Answer]** User Aggregate는 다음 **5가지 불변 조건**을 가집니다:

1. **비활성 계정 로그인 차단** ⭐ 핵심
   - `status === 'inactive'`인 사용자는 로그인할 수 없다
   - 검증: `User.canLogin()` 메서드

2. **최소 1개 Provider 유지** ⭐ 핵심
   - `linkedProviders.length >= 1` (최소 한 가지 로그인 방법 필요)
   - 검증: `User.unlinkProvider()` 메서드에서 마지막 Provider 제거 차단

3. **유효한 사용자 ID**
   - `id`는 유효한 UUID (Supabase auth.users.id와 일치)
   - 검증: User 생성자

4. **유효한 이메일**
   - Email Value Object로 형식 검증 위임
   - User는 이미 검증된 Email을 받음

5. **유효한 역할**
   - `role`은 'user' | 'admin' (TypeScript 타입으로 보장)

**불변 조건이 아닌 것:**
- 이메일 고유성: Supabase Auth + DB Unique Constraint로 보장 (Application Service에서 사전 검증)
- 이름 필수: Optional 허용 (OAuth 제공자에 따라 다름)

**[Question]** SNS 계정 연결(linkedProviders)은 User Aggregate의 내부 엔티티인가요, 아니면 값 객체인가요?

**[Answer]** linkedProviders는 **단순 배열** (`Array<'google' | 'kakao'>`)로 모델링합니다. 엔티티도 값 객체도 아닌 User Aggregate의 primitive 속성입니다.

**구조:**
- `linkedProviders: ProviderType[]` (ProviderType = 'google' | 'kakao')
- User Aggregate가 직접 배열 조작 메서드 제공 (`linkProvider()`, `unlinkProvider()`)

**근거:**
- 현재 요구사항(US1.1, US1.2)은 Provider 목록만 필요
- integration_contract.md의 인터페이스와 일치
- YAGNI 원칙: 불필요한 복잡도 제거
- Supabase `auth.identities`의 상세 정보는 Infrastructure Layer에서 관리
- 불변 조건 "최소 1개 Provider 유지"는 배열 길이 검증으로 충분

**Supabase 통합:**
- `auth.identities` 테이블에서 provider 목록을 조회하여 배열로 변환
- 실제 Identity 메타데이터는 Supabase가 관리

**향후 확장:**
- Provider별 메타데이터 필요 시 ProviderLink Entity로 리팩토링 가능

**[Question]** Session은 별도 Aggregate인가요, 아니면 User Aggregate의 일부인가요? Supabase가 세션을 관리하는데 도메인 모델에 포함해야 할까요?

**[Answer]** Session은 **도메인 모델에 포함하지 않습니다**. Supabase Auth가 완전히 관리하며, Application Layer에서 DTO로만 노출합니다.

**구조:**
- **Domain Layer**: Session 개념 없음
- **Application Layer**: `SessionDTO` (데이터 전송 객체)
- **Infrastructure Layer**: Supabase Auth에 완전히 위임

**근거:**
- Session은 기술적 관심사 (JWT, OAuth)이지 비즈니스 도메인 개념이 아님
- Session에 대한 비즈니스 규칙 없음 (만료 정책도 Supabase 설정)
- Supabase Auth가 토큰 관리, 갱신, 저장을 전문적으로 처리
- integration_contract.md에서 Session은 단순 응답 타입으로만 사용
- 다른 Unit은 Session을 직접 사용하지 않음 (`getCurrentUser()`만 호출)

**세션 관리:**
- 토큰 저장: localStorage (Supabase 자동)
- 토큰 갱신: Supabase SDK 자동 처리
- 만료 정책: Supabase 설정 (Access: 1시간, Refresh: 7일)

**향후 확장:**
"동시 세션 제한", "디바이스별 로그인 관리" 등의 비즈니스 규칙이 추가될 경우 Session Aggregate 도입 고려

### 단계 3: 엔티티와 값 객체 설계

- [ ] 각 애그리게이트 내 엔티티 식별
- [ ] 식별자가 필요한 개념(엔티티) vs 속성으로 정의 가능한 개념(값 객체) 구분
- [ ] 값 객체의 불변성 및 동등성 정의
- [ ] 엔티티의 생명주기 정의

**[Question]** Email은 값 객체로 모델링해야 할까요? (검증 로직 포함)

**[Answer]** Email은 **값 객체(Value Object)로 모델링**하되, SNS OAuth 특성을 고려하여 **최소 검증만 수행**합니다.

**구조:**
- 불변 클래스 `Email`
- 생성 시 null/undefined 체크 및 정규화만 수행 (toLowerCase, trim)
- 이메일 형식 검증은 제외 (SNS Provider + Supabase Auth 신뢰)
- `getValue()`, `equals()` 메서드 제공

**검증 로직:**
- 필수 값 확인만 (null/undefined/빈 문자열 체크)
- ❌ 형식 검증 제외: Google/Kakao OAuth가 이미 검증된 이메일 제공
- 정규화: toLowerCase(), trim() 적용

**근거:**
- 도메인 개념 명시적 표현 (타입 안정성)
- 불변성 보장 및 정규화 일관성
- SNS OAuth 신뢰: 중복 검증 제거로 성능 향상
- 방어적 프로그래밍: null/undefined만 체크

**Repository 통합:**
- Infrastructure Layer에서 문자열 ↔ Email 변환
- Supabase auth.users의 email 필드 사용

**[Question]** UserRole은 값 객체인가요, 아니면 Enum인가요?

**[Answer]** UserRole은 **TypeScript Enum**으로 모델링합니다.

**구조:**
- Enum 타입 정의: USER = 'user', ADMIN = 'admin'
- User Aggregate의 role 속성으로 사용
- isAdmin() 메서드로 역할 확인

**근거:**
- 단순한 개념 (2개 값)에 적합한 복잡도
- 컴파일 타임 타입 안정성
- IDE 자동완성 및 리팩토링 지원
- DB 직렬화 용이 (자동 문자열 변환)
- TypeScript Best Practice

**integration_contract.md 호환:**
- 인터페이스: 'user' | 'admin' Union Type으로 정의
- 구현: UserRole Enum 사용
- TypeScript에서 자동 호환

**향후 확장:**
역할 추가 시 Enum에 항목만 추가. 복잡한 RBAC 필요 시 Role Aggregate로 리팩토링.

**[Question]** AccountStatus('active', 'inactive')는 어떻게 모델링해야 할까요?

**[Answer]** AccountStatus는 **TypeScript Enum**으로 모델링합니다. UserRole과 동일한 패턴을 적용하여 일관성을 유지합니다.

**구조:**
- Enum 타입 정의: ACTIVE = 'active', INACTIVE = 'inactive'
- User Aggregate의 status 속성으로 사용
- canLogin() 메서드로 상태 확인
- activate(reason), deactivate(reason) 메서드로 상태 전이

**근거:**
- UserRole과 일관성 (2개 값, 단순 상태)
- 불변 조건 "비활성 계정 로그인 차단" 구현
- 타입 안정성 및 IDE 지원
- DB 직렬화 용이
- 적절한 복잡도 (YAGNI 원칙)

**상태 전이 검증:**
- 중복 전이 방지 (이미 inactive인데 deactivate 호출 시 에러)
- 도메인 이벤트 발행 (UserActivated, UserDeactivated)

**향후 확장:**
상태 추가 시 (suspended, banned 등) Enum 확장. 상태 전이 로직이 복잡해지면 상태 패턴으로 리팩토링.

### 단계 4: 도메인 이벤트 정의

- [ ] 비즈니스적으로 중요한 상태 변경 식별
- [ ] 각 도메인 이벤트의 이름과 속성 정의
- [ ] 이벤트 발행 시점 정의
- [ ] 이벤트 간 인과 관계 정의

**[Question]** 어떤 작업들이 도메인 이벤트로 발행되어야 할까요? (예: UserSignedIn, UserSignedOut, ProviderLinked, UserDeactivated 등)

**[Answer]** Authentication Unit은 **6개의 도메인 이벤트**를 발행합니다:

**필수 이벤트 (3개):**
1. **UserCreated**: 계정 생성 시 - Subscription Unit의 플랜 초기화, 환영 이메일
2. **UserActivated**: 계정 활성화 시 - 기능 차단 해제, 감사 로그
3. **UserDeactivated**: 계정 비활성화 시 - 기능 차단, 사용자 알림, 감사 로그

**Provider 관리 이벤트 (2개):**
4. **ProviderLinked**: SNS 계정 연결 시 - 보안 알림, 감사 로그
5. **ProviderUnlinked**: SNS 계정 해제 시 - 보안 경고, 감사 로그

**선택적 이벤트 (1개):**
6. **UserProfileUpdated**: 프로필 수정 시 - 캐시 무효화 (필요 시만)

**제외하는 이벤트:**
- UserSignedIn/Out: Application Event로 처리 (높은 빈도, 도메인 상태 변경 없음)
- UserPasswordChanged: SNS OAuth 전용으로 비밀번호 없음

**발행 원칙:**
- 비즈니스적으로 중요한 상태 변경만 발행
- 다른 Unit이 구독 필요한 이벤트 우선
- 높은 빈도 이벤트는 제외 (성능)

**[Question]** US1.1 "같은 이메일 자동 통합"은 도메인 이벤트가 필요한가요? (예: AccountsMerged)

**[Answer]** 별도의 AccountsMerged 이벤트는 생성하지 않습니다. **ProviderLinked 이벤트로 통합**하여 처리합니다.

**구조:**
- 이벤트명: ProviderLinked
- 속성: userId, provider, linkedAt, isAutoLinked (boolean)
- isAutoLinked: true면 자동 통합, false면 수동 연결

**근거:**
- "계정 통합"과 "Provider 연결"은 기술적으로 동일한 행동 (User에 Identity 추가)
- isAutoLinked 플래그로 자동/수동 구분 가능
- 이벤트 개수 최소화 (DRY 원칙)
- 구독자가 하나의 핸들러로 두 시나리오 처리 가능
- Supabase Automatic Account Linking과 자연스럽게 통합

**발행 시점:**
- 첫 로그인 시 같은 이메일 감지 시: isAutoLinked = true
- 프로필 페이지에서 수동 연결 시: isAutoLinked = false

**Supabase 통합:**
Supabase가 자동으로 Identity를 추가하면, Authentication Unit은 변경 감지 후 ProviderLinked 이벤트 발행.

**[Question]** Admin Console에서 계정 상태를 변경할 때, Authentication Unit에서 이벤트를 발행해야 할까요?

**[Answer]** 예, **Authentication Unit에서 이벤트를 발행해야 합니다.** Admin Console이 트리거하더라도 UserActivated / UserDeactivated 이벤트를 동일하게 발행합니다.

**근거:**
- DDD 원칙: Aggregate는 상태 변경 시 항상 도메인 이벤트 발행 (호출자 무관)
- 다른 Unit (Dashboard, Widget, Notification)이 이 이벤트를 구독하여 기능 차단/알림 처리
- deactivatedBy 필드로 Admin 정보 포함하여 감사 로그 추적 가능

**호출 흐름:**
1. Admin Console이 Authentication.deactivateUser(userId, reason, adminId) 호출
2. User.deactivate(reason, adminId) 실행
3. UserDeactivated 이벤트 발행
4. EventBus를 통해 모든 구독자에게 전파

**이벤트 구조:**
- 속성: userId, reason, deactivatedBy (Admin ID), deactivatedAt
- deactivatedBy 필드로 누가 비활성화했는지 추적

**중요:**
별도의 Admin 전용 이벤트는 생성하지 않습니다. 단일 이벤트로 모든 경우를 처리합니다.

### 단계 5: 도메인 서비스 식별

- [ ] 여러 애그리게이트에 걸친 비즈니스 로직 식별
- [ ] 엔티티나 값 객체에 속하지 않는 도메인 로직 식별
- [ ] 각 도메인 서비스의 책임 정의
- [ ] 도메인 서비스와 애플리케이션 서비스 구분

**[Question]** "같은 이메일 자동 통합" 로직은 도메인 서비스인가요? (예: AccountMergeService)

**[Answer]** 아니오, **별도의 Domain Service를 생성하지 않습니다**. Supabase Automatic Account Linking에 완전히 위임하며, Infrastructure Layer에서 변경을 감지하여 이벤트를 발행합니다.

**구조:**
- **Supabase Auth**: 같은 이메일 감지 및 Identity 자동 추가
- **Infrastructure Layer**: `auth.identities` 변경 감지 (Webhook 또는 Polling)
- **Application Service**: ProviderLinked 이벤트 발행 (isAutoLinked=true)
- **Domain Service 없음**

**근거:**
- Supabase Automatic Account Linking은 안정적이고 검증된 기능
- US1.1 요구사항에 추가적인 통합 비즈니스 규칙이 명시되지 않음
- Authentication Unit의 "얇은 도메인 레이어" 특성과 일치
- Q11에서 정의한 ProviderLinked(isAutoLinked=true) 이벤트로 자연스럽게 통합
- 불필요한 추상화 제거 (YAGNI 원칙)

**처리 흐름:**
1. 사용자가 새로운 Provider로 로그인 시도
2. Supabase가 동일 이메일을 가진 기존 계정 감지
3. Supabase가 자동으로 해당 User의 auth.identities에 새 Identity 추가
4. Infrastructure Layer가 변경 감지 (Webhook: auth.user.identity.created)
5. Application Service가 ProviderLinked 이벤트 발행 (isAutoLinked=true)

**향후 확장:**
"특정 Provider 조합 제한", "이메일 도메인별 통합 정책" 같은 복잡한 비즈니스 규칙이 추가되면, AccountMergePolicy(Domain Service)로 리팩토링 고려.

**[Question]** "비활성 계정 로그인 차단"은 도메인 서비스인가요, 아니면 Policy인가요?

**[Answer]** 둘 다 아닙니다. **User Aggregate의 canLogin() 메서드**로 구현합니다.

**구조:**
- User Aggregate에 `canLogin(): boolean` 메서드 정의
- Application Service에서 로그인 시 `user.canLogin()` 호출하여 검증
- false 반환 시 로그인 거부 및 적절한 에러 반환

**근거:**
- Q4에서 이미 "비활성 계정 로그인 차단"을 User의 불변 조건으로 정의
- 현재 로직은 단순 상태 검증 (`status === 'inactive'`)
- Aggregate가 자신의 유효성을 검증하는 것이 DDD 원칙에 부합
- User가 자신의 상태를 직접 검증 (높은 응집도)
- Authentication Unit의 "얇은 도메인 레이어" 특성에 적합

**Application Service 통합:**
- 로그인 플로우에서 User 조회 후 `canLogin()` 호출
- false면 "계정이 비활성화되었습니다" 에러 반환
- Supabase Auth 세션 생성 전에 검증

**향후 확장:**
"IP 차단", "로그인 시도 횟수 제한", "디바이스 제한" 같은 복잡한 규칙이 추가되면, ILoginPolicy 인터페이스로 리팩토링하여 여러 정책을 조합. 현재는 YAGNI 원칙 적용.

**[Question]** Supabase Auth와의 통신은 도메인 서비스 인터페이스로 정의해야 할까요? (예: IAuthenticationProvider)

**[Answer]**

### 단계 6: 정책(Policy) 정의

- [ ] 비즈니스 규칙과 제약사항 식별
- [ ] 정책의 트리거 조건 정의
- [ ] 정책의 실행 결과 정의
- [ ] 정책 간 우선순위 정의

**[Question]** "비활성 계정 로그인 차단" 정책은 어디에 정의해야 할까요?

**[Answer]**

**[Question]** "최소 1개 Provider 연결 유지" 같은 정책이 필요한가요? (마지막 Provider 연결 해제 방지)

**[Answer]**

**[Question]** 세션 만료 정책은 도메인 레이어에서 정의해야 할까요, 아니면 Supabase에 위임해야 할까요?

**[Answer]**

### 단계 7: 리포지토리 인터페이스 정의

- [ ] 각 애그리게이트별 리포지토리 인터페이스 정의
- [ ] 필요한 조회 메서드 정의
- [ ] 저장/삭제 메서드 정의
- [ ] 트랜잭션 경계 정의

**[Question]** UserRepository는 Supabase Auth와 어떻게 통합되어야 할까요? Supabase의 auth.users 테이블과 별도 profile 테이블을 사용하나요?

**[Answer]**

**[Question]** Session은 별도 Repository가 필요한가요, 아니면 Supabase Auth에 완전히 위임하나요?

**[Answer]**

**[Question]** User 조회 시 linkedProviders 정보도 함께 로드해야 할까요? (Eager Loading vs Lazy Loading)

**[Answer]**

### 단계 8: Supabase Auth 통합 전략

- [ ] Supabase Auth의 역할 정의
- [ ] Domain Layer와 Infrastructure Layer의 경계 식별
- [ ] Supabase Auth 추상화 인터페이스 정의

**[Question]** Supabase Auth는 Infrastructure Layer에서 어떻게 추상화해야 할까요?

**[Answer]**

**[Question]** OAuth 인증 플로우는 도메인 모델에 포함되어야 할까요, 아니면 Infrastructure의 구현 세부사항인가요?

**[Answer]**

**[Question]** Supabase의 Account Linking 기능을 그대로 사용할까요, 아니면 도메인 로직으로 래핑해야 할까요?

**[Answer]**

### 단계 9: 도메인 모델 문서 작성

- [ ] domain_model.md 파일 생성
- [ ] 식별된 모든 전술적 패턴 문서화
  - [ ] 애그리게이트 다이어그램
  - [ ] 엔티티 정의
  - [ ] 값 객체 정의
  - [ ] 도메인 이벤트 목록
  - [ ] 도메인 서비스 정의
  - [ ] 정책 정의
  - [ ] 리포지토리 인터페이스
- [ ] 각 요소 간 관계 및 상호작용 설명
- [ ] 비즈니스 규칙 및 제약사항 명시
- [ ] Supabase Auth 통합 전략 명시

### 단계 10: 검증 및 검토

- [ ] 모든 사용자 스토리가 도메인 모델로 구현 가능한지 검증
- [ ] DDD 전술적 패턴이 올바르게 적용되었는지 검토
- [ ] 도메인 모델의 복잡도가 적절한지 평가
- [ ] 다른 Unit과의 통합 계약 일치 여부 확인
- [ ] 피드백 반영 및 최종 승인

## 참고 문서

- `docs/aidlc/inception/units/authentication.md` - 요구사항 및 사용자 스토리
- `docs/aidlc/inception/units/integration_contract.md` - 단위 간 인터페이스 계약
- `docs/aidlc/construction/admin-console/domain_model.md` - Admin Console Unit 도메인 모델 (참고용)

## 주의사항

- 코드 스니펫을 생성하지 않습니다
- 설계 문서만 작성합니다
- 중요한 결정은 질문을 통해 명확히 합니다
- Supabase Auth에 대한 과도한 의존성을 피하고, 도메인 로직을 명확히 분리합니다

## Authentication Unit의 특성

Authentication Unit은 다음과 같은 특성을 가집니다:

1. **Supabase Auth 의존성**: 대부분의 인증 로직이 Supabase에 위임됨
2. **얇은 도메인 레이어**: 복잡한 비즈니스 로직이 적음
3. **Infrastructure 중심**: OAuth 플로우, 세션 관리는 Supabase가 처리
4. **공유 개념**: User는 여러 Unit에서 사용하는 공통 개념
5. **상태 관리 책임**: 계정 활성화/비활성화는 Admin Console과 협력

따라서 도메인 모델 설계 시:
- **과도한 추상화 피하기**: Supabase Auth의 기능을 불필요하게 재구현하지 않음
- **핵심 도메인 로직 식별**: User 생명주기, 계정 연결 정책 등
- **명확한 경계 설정**: Infrastructure Layer와 Domain Layer의 책임 분리
- **통합 계약 준수**: integration_contract.md에 정의된 인터페이스 제공

---

## 다음 단계

계획을 검토하고 승인해 주시면, 각 단계별로 질문에 답변을 받아가며 도메인 모델 설계를 진행하겠습니다.
