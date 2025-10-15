# Query Unit (공유 데이터 레이어)

## 단위 개요

**책임**: 클라이언트 데이터 페칭, 캐싱, 상태 관리를 위한 공유 레이어

**주요 목표**:
- BFF API 클라이언트 제공
- 서버 상태 관리 (TanStack Query)
- 일관된 캐싱 전략
- 에러 처리 표준화

## 제공하는 기능

### 1. API Client

모든 Feature Module이 BFF API Routes를 호출하기 위한 클라이언트를 제공합니다.

**제공 영역**:
- Dashboard API 호출
- Widget API 호출
- Data Integration API 호출
- Subscription API 호출
- Admin API 호출
- Authentication API 호출

**책임**:
- 자동 인증 토큰 첨부
- 에러 응답 표준화
- 요청/응답 타입 안정성

### 2. React Query Hooks

Feature Module별로 서버 상태를 관리하는 Hooks를 제공합니다.

**제공 영역**:
- Dashboard Hooks
- Widget Hooks
- Data Integration Hooks
- Subscription Hooks
- Admin Hooks

**책임**:
- 자동 캐싱 및 재검증
- 낙관적 업데이트
- 무한 스크롤
- 폴링 및 실시간 갱신

### 3. Query Key 관리

캐시 무효화 및 프리페칭을 위한 Query Key 체계를 제공합니다.

**책임**:
- 일관된 Query Key 네이밍
- 캐시 무효화 규칙
- 프리페칭 전략

## 캐싱 전략

### 데이터 유형별 캐시 정책

| 데이터 유형 | 캐시 시간 | 갱신 정책 |
|-----------|---------|---------|
| 대시보드 목록 | 5분 | 마운트 시 갱신 |
| 대시보드 상세 | 1분 | 마운트 시 갱신 |
| 위젯 데이터 | 30초 | 마운트 시 갱신 |
| 지표 데이터 | 1시간 | 마운트 안 함 |
| 구독 정보 | 5분 | 마운트 시 갱신 |
| 사용자 프로필 | 10분 | 마운트 안 함 |

### 캐시 무효화 규칙

- 대시보드 생성 → 대시보드 목록 무효화
- 대시보드 수정 → 해당 대시보드 상세 무효화
- 위젯 추가 → 대시보드 상세 + 위젯 목록 무효화
- 플랜 업그레이드 → 구독 정보 + 제한사항 무효화

## 에러 처리

### 표준화된 에러 응답

integration_contract.md에 정의된 ErrorCode를 사용하여 에러를 표준화합니다.

**에러 카테고리**:
- 인증 에러 (AUTH_REQUIRED, SESSION_EXPIRED)
- 구독 에러 (PLAN_LIMIT_EXCEEDED)
- 데이터 에러 (DATA_NOT_FOUND, API_ERROR)
- 검증 에러 (VALIDATION_ERROR)
- 네트워크 에러 (NETWORK_ERROR)

## 의존성

### 입력 의존성

- **@e-torch/core**: 공통 타입, 에러 정의

### 제공 대상

- **모든 Feature Module**: React Query Hooks, API Client
- **apps/web**: 사용자 앱 데이터 페칭
- **apps/admin**: 관리자 앱 데이터 페칭

## 기술 요구사항

### 패키지 구조

```
packages/query/
├── src/
│   ├── lib/              # API Client, Query Client 설정
│   ├── hooks/            # Feature Module별 React Hooks
│   ├── services/         # 비즈니스 로직 (API Routes에서 이전)
│   └── types/            # API 요청/응답 타입
├── package.json
└── tsconfig.json
```

### 주요 라이브러리

- TanStack React Query (서버 상태 관리)
- @e-torch/core (공통 타입)

### 인증 토큰 관리

Supabase 세션에서 자동으로 토큰을 가져와 API 요청에 첨부합니다.

## 보안 요구사항

- API 요청에 자동으로 인증 토큰 첨부
- 토큰 만료 시 자동 갱신 또는 로그아웃
- 민감한 데이터 로깅 방지

## 성능 최적화 전략

- 프리페칭으로 사용자 경험 개선
- 무한 스크롤 지원
- 배치 페칭으로 네트워크 요청 최소화
- 낙관적 업데이트로 즉각적인 피드백
