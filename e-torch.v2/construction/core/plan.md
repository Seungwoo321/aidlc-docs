# Core Unit Feature Module 설계 계획

## 개요

**Feature Module**: Core Unit
**책임**: 공유 TypeScript 타입, 비즈니스 로직, 유틸리티 함수 제공
**아키텍처**: Pure TypeScript Package (React/BFF 없음), TypeScript + Zod, Tree-shakable Exports

## 목표

Core Unit Feature Module의 설계 문서를 작성하여 다음을 달성합니다:

1. **타입 안정성**: TypeScript Interface + Zod Schema로 컴파일 타임 + 런타임 검증
2. **단일 진실 공급원**: integration_contract.md의 43개 타입을 Zod Schema로 구현
3. **비즈니스 로직 중앙화**: Subscription, Widget, Data Integration, Content Moderation 로직
4. **유틸리티 제공**: 날짜/숫자 포맷팅, 문자열 처리, 배열 처리, 함수 제어
5. **상수 관리**: API 엔드포인트, 경로, 제한값, 정규식 중앙 관리

## Core Unit 특징

- **React Components 없음**: 순수 TypeScript 라이브러리
- **BFF API 없음**: 데이터 페칭 없음
- **최하위 레이어**: 다른 패키지에 의존하지 않음
- **모든 Feature Module의 기반**: 타입, 로직, 유틸리티 제공

## 포함된 기능

### 1. Domain Types (43개)
- User, Session, AuthContext
- Dashboard, Widget, WidgetLayout, WidgetType
- Indicator, DataSource, StandardizedData
- Subscription, PlanLimitConfig, DynamicPlanLimits
- DashboardTemplate, Category
- ActivityLog, CustomDataPoint
- ConsentLog, ViolationLog, DashboardReport, DetectionRule
- Error Types

### 2. DTO Types
- CreateDashboardDto, UpdateDashboardDto
- CreateWidgetDto, UpdateWidgetDto
- ReportDashboardDto, LogConsentDto
- Admin 관련 DTO

### 3. Business Logic
- Subscription: 플랜별 제한값, 권한 확인
- Widget: 타입 검증, 차트/텍스트 구분
- Data Integration: 데이터 소스별 변환
- Content Moderation: 위험 패턴 탐지, 위험도 계산
- User Violation: 누적 제재 판단

### 4. Utility Functions
- 날짜 포맷팅, 숫자 포맷팅
- 문자열 슬러그, 파일 크기 포맷팅
- 배열 처리 (chunk, groupBy)
- 함수 제어 (debounce, throttle)

### 5. Constants
- API 엔드포인트, 페이지 경로
- 로컬 스토리지 키, 쿼리 스트링 키
- 제한값, 정규식, 에러 메시지

## 아키텍처 질문 (사용자 승인 필요)

### [Question 1] Zod Schema 위치 전략

**선택지**:

**Option A: 타입과 Schema 동일 파일**
```
packages/core/src/types/
  dashboard.ts       # Dashboard Interface + DashboardSchema 함께
  widget.ts          # Widget Interface + WidgetSchema 함께
  user.ts            # User Interface + UserSchema 함께
```

**장점**:
- 타입과 Schema가 함께 있어 관리 용이
- 파일 개수 적음

**단점**:
- 파일 크기 커짐 (Interface + Schema)
- Schema를 사용하지 않는 곳에서도 번들 포함 가능

**Option B: 타입과 Schema 별도 파일**
```
packages/core/src/
  types/
    dashboard.ts     # Dashboard Interface만
    widget.ts        # Widget Interface만
  schemas/
    dashboard.ts     # DashboardSchema만
    widget.ts        # WidgetSchema만
```

**장점**:
- 트리 쉐이킹 최적화 (타입만 필요한 곳은 Schema 제외)
- 역할 분리 명확

**단점**:
- 파일 개수 많음 (2배)
- 타입 변경 시 두 파일 수정 필요

**Option C: Schema에서 타입 추론**
```
packages/core/src/schemas/
  dashboard.ts       # DashboardSchema 정의 후 타입 추론

// 사용
import { DashboardSchema } from '@e-torch/core/schemas'
type Dashboard = z.infer<typeof DashboardSchema>
```

**장점**:
- 단일 진실 공급원 (Schema가 타입 정의)
- 타입과 Schema 동기화 자동

**단점**:
- TypeScript 타입 우선 설계 불가
- 복잡한 타입은 추론 어려움
- IDE 자동완성 약간 느림

**권장**: Option B (타입과 Schema 별도 파일)

**이유**:
1. 트리 쉐이킹 최적화 (프론트엔드 번들 크기 중요)
2. TypeScript 우선 설계 (타입을 먼저 정의하고 Schema는 검증용)
3. 역할 분리 (타입 정의 vs 런타임 검증)
4. integration_contract.md의 타입을 TypeScript Interface로 먼저 정의한 후 Zod Schema 작성

### [Question 2] Business Logic 함수 순수성 전략

**선택지**:

**Option A: 완전 순수 함수**
```typescript
// 모든 파라미터를 명시적으로 받음
export function canCreateDashboard(
  currentCount: number,
  planLimits: DynamicPlanLimits
): boolean {
  const limit = planLimits.limits.get('dashboardLimit') as number
  return currentCount < limit
}
```

**장점**:
- 테스트 용이
- 예측 가능
- 외부 의존성 없음

**단점**:
- 호출 시 많은 파라미터 필요
- Context 전달 복잡

**Option B: Context 기반 함수**
```typescript
// Context를 받아서 필요한 값 추출
export function canCreateDashboard(context: {
  user: User
  subscription: Subscription
  planLimits: DynamicPlanLimits
}): boolean {
  // context에서 필요한 값 추출
}
```

**장점**:
- 호출 간편
- 확장 용이

**단점**:
- Context 타입 정의 필요
- 순수성 약간 낮음

**Option C: 하이브리드 (순수 함수 + Helper)**
```typescript
// 순수 함수
export function canCreateDashboard(
  currentCount: number,
  limit: number
): boolean {
  return currentCount < limit
}

// Helper (다른 패키지에서 제공)
// @e-torch/subscription에서:
export function useCanCreateDashboard() {
  const { currentCount, limit } = useSubscription()
  return canCreateDashboard(currentCount, limit)
}
```

**장점**:
- Core는 순수 함수만 제공 (테스트 용이)
- Feature Module에서 Context 통합

**단점**:
- 역할 분산 (Core + Feature Module)

**권장**: Option A (완전 순수 함수)

**이유**:
1. Core는 최하위 레이어로 외부 의존성 없어야 함
2. 테스트 용이성 (순수 함수는 입출력만 테스트)
3. Feature Module에서 Context를 가져와서 Core 함수 호출
4. 예측 가능성 (같은 입력 → 같은 출력)

### [Question 3] 상수 관리 전략

**선택지**:

**Option A: 단일 파일**
```typescript
// constants/index.ts
export const API_ENDPOINTS = { ... }
export const ROUTES = { ... }
export const STORAGE_KEYS = { ... }
export const LIMITS = { ... }
export const REGEX = { ... }
```

**장점**:
- 파일 개수 적음
- 모든 상수 한눈에 파악

**단점**:
- 파일 크기 커짐
- 트리 쉐이킹 어려움 (전체 import)

**Option B: 카테고리별 분리**
```typescript
constants/
  api.ts         # API_ENDPOINTS
  routes.ts      # ROUTES
  storage.ts     # STORAGE_KEYS
  limits.ts      # LIMITS
  regex.ts       # REGEX
  index.ts       # 모두 re-export
```

**장점**:
- 트리 쉐이킹 최적화
- 역할 분리 명확
- 파일 관리 용이

**단점**:
- 파일 개수 많음

**Option C: Feature별 분리**
```typescript
constants/
  dashboard.ts   # 대시보드 관련 상수
  widget.ts      # 위젯 관련 상수
  subscription.ts # 구독 관련 상수
  admin.ts       # 관리자 관련 상수
```

**장점**:
- Feature Module과 매핑 명확
- 관련 상수 그룹화

**단점**:
- 상수 중복 가능성 (예: API_ENDPOINTS)

**권장**: Option B (카테고리별 분리)

**이유**:
1. 트리 쉐이킹 최적화 (필요한 상수만 import)
2. 역할 분리 (API, 경로, 스토리지, 제한값, 정규식)
3. 파일 크기 관리 용이
4. Named export로 원하는 것만 import

### [Question 4] Error Type 제공 전략

**선택지**:

**Option A: Error Class**
```typescript
export class AppError extends Error {
  constructor(
    public code: ErrorCode,
    message: string,
    public details?: unknown
  ) {
    super(message)
  }
}

// 사용
throw new AppError('AUTH_REQUIRED', 'Authentication required')
```

**장점**:
- instanceof로 에러 타입 체크
- 표준 Error 프로토콜 따름

**단점**:
- Class 사용 (번들 크기 증가)
- 직렬화 어려움 (API 응답)

**Option B: Error Factory Function**
```typescript
export function createError(
  code: ErrorCode,
  message: string,
  details?: unknown
): AppError {
  return { code, message, details }
}

// 사용
throw createError('AUTH_REQUIRED', 'Authentication required')
```

**장점**:
- 순수 객체 (직렬화 쉬움)
- 번들 크기 작음

**단점**:
- instanceof 체크 불가
- 표준 Error 프로토콜 안 따름

**Option C: Error Type만 제공**
```typescript
export type AppError = {
  code: ErrorCode
  message: string
  details?: unknown
}

// Feature Module에서 에러 생성
```

**장점**:
- Core는 타입만 제공 (최소 역할)
- 에러 생성은 Feature Module 책임

**단점**:
- 에러 생성 로직 분산

**권장**: Option B (Error Factory Function)

**이유**:
1. API 응답과 호환 (순수 객체)
2. 직렬화 쉬움 (JSON.stringify)
3. 번들 크기 최소화
4. 에러 생성 로직 중앙화

### [Question 5] Utility 함수 네이밍 전략

**선택지**:

**Option A: 동사 시작 (일반적)**
```typescript
formatDate()
formatNumber()
formatCurrency()
formatFileSize()
slugify()
debounce()
throttle()
```

**장점**:
- 일반적인 JavaScript 컨벤션
- 액션 명확

**단점**:
- 긴 이름 (format 반복)

**Option B: 카테고리 Namespace**
```typescript
date.format()
date.relative()
number.format()
number.currency()
string.slugify()
fn.debounce()
fn.throttle()
```

**장점**:
- 카테고리 명확
- 자동완성 편리

**단점**:
- Import 방식 특수 (`import { date } from '@e-torch/core/utils'`)
- 트리 쉐이킹 어려움

**Option C: 접두사 사용**
```typescript
// 날짜
fmtDate()
fmtDateRelative()

// 숫자
fmtNumber()
fmtCurrency()

// 문자열
slugify()

// 함수
fnDebounce()
fnThrottle()
```

**장점**:
- 짧은 이름
- 카테고리 구분 가능

**단점**:
- 약어 가독성 낮음 (fmt)

**권장**: Option A (동사 시작)

**이유**:
1. JavaScript 커뮤니티 표준
2. 가독성 우수
3. 자동완성 지원 좋음
4. Named import로 트리 쉐이킹 지원

## 설계 단계 (7 Phase)

### Phase 1: 사전 조사 및 준비

- [x] integration_contract.md의 43개 타입 분석
- [x] 각 타입의 필드 및 관계 파악
- [x] 비즈니스 로직 함수 목록 작성 (Subscription 5, Widget 3, Data 2, Moderation 2, Violation 2)
- [x] 필요한 유틸리티 함수 목록 작성 (Date 3, Number 4, String 4, Array 4, Function 3)

### Phase 2: Type 정의 설계

- [x] 43개 Domain Type을 TypeScript Interface로 정의
- [x] 15개 DTO Type 정의 (Create/Update/Report/LogConsent/Admin)
- [x] 3개 Error Type 정의 (AppError, ErrorCode, createError)
- [x] 각 타입의 Zod Schema 정의 전략 (런타임 검증용, 별도 파일)

### Phase 3: Business Logic 설계

- [x] Subscription Logic 5개 함수 설계 (플랜별 제한값, 권한 확인)
- [x] Widget Logic 3개 함수 설계 (타입 검증, 차트/텍스트 구분)
- [x] Data Integration Logic 2개 함수 설계 (데이터 소스별 변환)
- [x] Content Moderation Logic 2개 함수 설계 (위험 패턴 탐지, 위험도 계산)
- [x] User Violation Logic 2개 함수 설계 (누적 제재 판단)

### Phase 4: Utility 함수 설계

- [x] 날짜 포맷팅 함수 3개 설계 (formatDate, formatDateRelative, parseDate)
- [x] 숫자 포맷팅 함수 4개 설계 (formatNumber, formatCurrency, formatPercent, formatCompact)
- [x] 문자열 처리 함수 4개 설계 (slugify, formatFileSize, truncate, capitalize)
- [x] 배열 처리 함수 4개 설계 (chunk, groupBy, unique, sortBy)
- [x] 함수 제어 함수 3개 설계 (debounce, throttle, memoize)

### Phase 5: Constants 설계

- [x] API 엔드포인트 상수 정의 (DASHBOARD, WIDGET, SUBSCRIPTION, ADMIN, MODERATION)
- [x] 페이지 경로 상수 정의 (apps/web, apps/admin)
- [x] 로컬 스토리지 키 상수 정의 (AUTH, PREFERENCES, DASHBOARD, WIDGET)
- [x] 제한값 상수 정의 (TEXT, FILES, PAGINATION, API, DATA)
- [x] 정규식 상수 정의 (EMAIL, URL, SLUG, VALIDATION, CONTENT_MODERATION)
- [x] 에러 메시지 상수 정의 (AUTH, SUBSCRIPTION, DATA, VALIDATION, NETWORK, SERVER)

### Phase 6: File Structure 설계

- [x] packages/core/ 디렉토리 구조 정의
- [x] types/ 폴더 구조 (domain, dto, errors)
- [x] schemas/ 폴더 구조 (domain, dto, errors) - 별도 파일
- [x] business/ 폴더 구조 (subscription, widget, data, moderation, violation)
- [x] utils/ 폴더 구조 (date, number, string, array, function)
- [x] constants/ 폴더 구조 (api, routes, storage, limits, regex, errors)
- [x] Export 전략 정의 (index.ts, Named exports, Subpath exports)

### Phase 7: 문서 작성 및 검증

- [x] feature_module_design.md 작성 (총 93개 항목)
- [x] 43개 Domain Type 완전 정의 확인
- [x] 14개 비즈니스 로직 함수 명세 작성
- [x] 18개 유틸리티 함수 명세 작성
- [x] 6개 Constants 카테고리 명세 작성
- [x] 다음 단계 (구현) 가이드 작성

## 다음 단계 (Implementation Phase)

설계 완료 후:

1. **Package 초기화**: packages/core/ 패키지 생성, package.json, tsconfig.json 설정
2. **Types 구현**: TypeScript Interface 정의
3. **Schemas 구현**: Zod Schema 구현
4. **Business Logic 구현**: 비즈니스 로직 함수 구현
5. **Utilities 구현**: 유틸리티 함수 구현
6. **Constants 구현**: 상수 정의
7. **단위 테스트**: Vitest로 모든 함수 테스트
8. **빌드 및 배포**: Turborepo로 빌드, npm publish

## 산출물

- `docs/aidlc-docs/construction/core/feature_module_design.md`
  - 43개 Domain Type 정의 (TypeScript Interface + Zod Schema)
  - DTO Type 정의
  - Error Type 정의
  - 비즈니스 로직 함수 명세 (Subscription, Widget, Data, Moderation, Violation)
  - 유틸리티 함수 명세 (Date, Number, String, Array, Function)
  - 상수 명세 (API, Routes, Storage, Limits, Regex)
  - File Structure
  - Export 전략
  - 다음 단계 가이드
  - **코드 스니펫 제외** (설계 명세만)
