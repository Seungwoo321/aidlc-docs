# Core Unit (공유 타입 및 비즈니스 로직)

## 단위 개요

**책임**: 공유 TypeScript 타입, 비즈니스 규칙, 유틸리티 함수 제공

**주요 목표**:
- 모든 Feature Module이 사용하는 공통 타입 정의
- 비즈니스 규칙 및 검증 로직 중앙화
- 일관된 데이터 변환 및 포맷팅
- 상수 및 설정 관리
- 타입 안정성 보장

## 제공하는 기능

### 1. Domain Types

integration_contract.md에 정의된 모든 도메인 타입을 제공합니다.

**제공 타입 (43개)**:
- User, Session, AuthContext
- Dashboard, Widget, WidgetLayout, WidgetType
- DashboardVersion, DashboardBookmark, ShareLink
- Indicator, DataSource, DataPeriod, StandardizedData
- Subscription, PlanType, SubscriptionStatus, UsageStats
- PlanLimitConfig, DynamicPlanLimits
- DashboardTemplate, Category
- ActivityLog, CustomDataPoint
- ConsentLog, ViolationLog, DashboardReport, DetectionRule
- Error Types (AppError, ErrorCode)

### 2. DTO Types (Data Transfer Objects)

API 요청/응답에 사용되는 DTO 타입을 제공합니다.

**제공 DTO**:
- CreateDashboardDto, UpdateDashboardDto
- CreateWidgetDto, UpdateWidgetDto
- ReportDashboardDto (US2.14)
- LogConsentDto (US2.12, US2.13)
- Admin 관련 DTO

### 3. TypeScript Interface + Zod Schema

컴파일 타임 타입 체크와 런타임 데이터 검증을 모두 지원합니다.

**제공 방식**:
- TypeScript Interface (컴파일 타임)
- Zod Schema (런타임 검증)
- DTO는 Zod Schema에서 타입 추론

### 4. Business Logic Functions

Feature Module 간 공유되는 핵심 비즈니스 로직을 제공합니다.

**Subscription 로직**:
- 플랜별 제한값 조회
- 대시보드 생성 가능 여부
- 위젯 추가 가능 여부
- 기능 접근 권한 확인
- 데이터 조회 기간 계산

**Widget 로직**:
- 차트/텍스트 위젯 구분
- 위젯 타입 검증

**Data Integration 로직**:
- 데이터 소스별 변환 (KOSIS, ECOS, OECD, CUSTOM)
- 표준화된 데이터 포맷 제공

**Content Moderation 로직 (US6.11)**:
- 위험 패턴 자동 탐지
- 위험도 점수 계산

**User Violation 로직 (US6.10)**:
- 위반 누적 제재 판단

### 5. Utility Functions

범용 유틸리티 함수를 제공합니다.

**제공 함수**:
- 날짜 포맷팅 (short, long, relative)
- 숫자 포맷팅 (decimal, percent, currency)
- 파일 크기 포맷팅
- 문자열 슬러그 생성
- 배열 처리 (chunk, groupBy)
- 함수 제어 (debounce, throttle)

### 6. Constants & Configuration

애플리케이션 상수를 제공합니다.

**제공 상수**:
- API 엔드포인트
- 로컬 스토리지 키
- 쿼리 스트링 키
- 페이지 경로 (apps/web, apps/admin)
- 제한값 (문자열 길이, 파일 크기 등)
- 정규 표현식
- 에러 메시지

### 7. Error Types

integration_contract.md의 ErrorCode와 일치하는 에러 타입을 제공합니다.

**에러 카테고리**:
- Authentication (AUTH_REQUIRED, SESSION_EXPIRED)
- Subscription (PLAN_LIMIT_EXCEEDED)
- Data (DATA_NOT_FOUND, API_ERROR)
- Validation (VALIDATION_ERROR)
- Network (NETWORK_ERROR)
- Server (SERVER_ERROR)

## 비즈니스 규칙

### Subscription 제한 (초기 기본값)

**Free 플랜**:
- 대시보드: 최대 3개
- 위젯: 대시보드당 최대 6개
- 데이터 조회: 최근 3년
- 버전 관리: 불가
- 즐겨찾기: 최대 10개
- 데이터 내보내기: 불가

**Pro 플랜**:
- 대시보드: 무제한
- 위젯: 무제한
- 데이터 조회: 전체 기간
- 버전 관리: 최근 10개 버전
- 즐겨찾기: 무제한
- 데이터 내보내기: 가능

**동적 관리**: 관리자가 US6.5를 통해 동적으로 변경 가능

### Content Moderation 규칙 (US6.11)

**위험 패턴 카테고리**:
- 투자 권유 (특정 종목 + 행동 유도)
- 허위 주장 (수익 보장 표현)
- 타이밍 단정 (내일 급등 등)
- 외부 서비스 (텔레그램, 카톡방)

**위험도 판정**:
- High: 고위험 패턴 2개 이상
- Medium: 고위험 1개 또는 중위험 2개 이상
- Low: 기타

### User Violation 제재 (US6.10)

**단계적 제재**:
- 1회 위반: 경고 (이메일 + 앱 내 알림)
- 2회 위반: 48시간 게시 제한
- 3회 위반: 계정 영구 정지

## 의존성

### 입력 의존성

- **없음** (최하위 레이어로 독립적)

### 제공 대상

- **모든 Feature Module**: 타입, 비즈니스 로직, 유틸리티
- **@e-torch/query**: API 요청/응답 타입
- **@e-torch/ui**: 공통 타입
- **apps/web**: 사용자 앱
- **apps/admin**: 관리자 앱

## 기술 요구사항

### 패키지 구조

```
packages/core/
├── src/
│   ├── types/            # 도메인 타입, DTO, 공통 타입
│   ├── schemas/          # Zod Schema
│   ├── business/         # 비즈니스 로직
│   ├── utils/            # 유틸리티 함수
│   ├── constants/        # 상수
│   └── index.ts
├── package.json
└── tsconfig.json
```

### 주요 라이브러리

- Zod (런타임 검증)

### 타입 Export 전략

Named exports로 트리 쉐이킹을 지원합니다.

## 타입 안정성

### 컴파일 타임 vs 런타임

- **TypeScript Interface**: 컴파일 타임 타입 체크
- **Zod Schema**: 런타임 데이터 검증
- **DTO**: Zod Schema에서 TypeScript 타입 추론

### 단일 진실 공급원 (Single Source of Truth)

integration_contract.md에 정의된 타입이 유일한 진실이며, core.md는 이를 Zod Schema로 구현합니다.

## 버전 관리

Semantic Versioning을 따릅니다.

- MAJOR: 하위 호환성 깨지는 타입 인터페이스 변경
- MINOR: 하위 호환되는 기능 추가
- PATCH: 버그 수정
