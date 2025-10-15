# E-Torch AI DLC - 단계 1.2: 사용자 스토리 단위별 그룹화 계획

## 작업 목표

사용자 스토리를 독립적으로 구축 가능한 단위로 그룹화하여 높은 응집도와 느슨한 결합을 달성

## 작업 단계

### 단계 1: 사용자 스토리 분석

- [x] 6개 에픽과 37개 사용자 스토리 검토
- [x] 기능적 연관성 파악
- [x] 데이터 흐름 및 의존성 분석

### 단계 2: 단위(Unit) 정의

- [x] 독립 구축 가능한 단위 식별
- [x] 각 단위의 책임 범위 정의
- [x] 단위 간 인터페이스 포인트 파악

### 단계 3: 단위별 사용자 스토리 매핑

- [x] 각 단위에 관련 사용자 스토리 할당
- [x] 단위 내 응집도 검증
- [x] 단위 간 결합도 최소화 확인

### 단계 4: 단위별 문서 작성

- [x] dashboard.md - 대시보드 단위 (조회, 관리, 위젯 배치 포함)
- [x] widget-library.md - 위젯 라이브러리 단위
- [x] data-integration.md - 데이터 통합 단위
- [x] authentication.md - 인증 단위
- [x] subscription.md - 구독 관리 단위
- [x] admin-console.md - 관리자 콘솔 단위

### 단계 5: 통합 계약 정의

- [x] 각 단위의 공개 인터페이스 정의
- [x] 단위 간 데이터 교환 형식 명시
- [x] integration_contract.md 작성

## 예상 단위 구성

### Shell Application (통합 레이어 - 단위 아님)

**역할**: 전체 애플리케이션 컨테이너 및 통합 관리

**주요 기능**:

- 각 단위를 통합하는 컨테이너 역할
- 공통 라우팅 및 네비게이션 관리
- 인증 상태에 따른 메뉴 표시/숨김
- 권한 기반 단위 접근 제어
- 비즈니스 로직 없음 (순수 통합 레이어)

**포함 요소**:

- Main Layout (헤더, 사이드바, 푸터)
- Router Configuration
- Unit Loader (동적 단위 로딩)
- Common Error Boundary

### 1. Dashboard Unit (대시보드 단위)

**책임**: 대시보드 조회, 생성, 편집, 삭제 및 위젯 배치 관리

**포함 스토리**: US2.1, US2.2, US2.3, US2.4, US2.5, US2.6, US2.7, US2.8, US2.9, US2.10, US2.11

### 2. Widget Library Unit (위젯 라이브러리 단위)

**책임**: 위젯 생성, 편집, 복사, 삭제 관리 및 데이터 내보내기

**포함 스토리**: US3.1, US3.2, US3.3, US3.4, US3.5, US3.6, US3.7, US3.8

### 3. Data Integration Unit (데이터 통합 단위)

**책임**: 외부 API 호출 및 데이터 변환

**포함 스토리**: US4.1, US4.2, US4.3

### 4. Authentication Unit (인증 단위)

**책임**: SNS 로그인 및 프로필 관리

**포함 스토리**: US1.1, US1.2

### 5. Subscription Unit (구독 관리 단위)

**책임**: 구독 플랜, 결제, 플랜별 제한 관리

**포함 스토리**: US5.1, US5.2, US5.3, US5.4, US5.5

### 6. Admin Console Unit (관리자 콘솔 단위)

**책임**: 관리자 기능 및 지표 관리

**포함 스토리**: US6.1, US6.2, US6.3, US6.4, US6.5, US6.6, US6.7, US6.8

## 질문 사항

[Question] 제안된 6개 단위 구성이 적절한가요? 다른 그룹화 방식을 선호하시나요?
[Answer] 적절합니다. Authentication과 Subscription을 분리하여 단일 책임 원칙을 준수합니다.

[Question] Widget Factory Unit이 너무 많은 책임을 가지고 있나요? 위젯 라이브러리와 대시보드 배치를 분리해야 할까요?
[Answer]
  대시보드 배치는 Dashboard Unit에 포함되는 것이 맞다고 생각합니다.

  이유:

  1. 응집도: 위젯 배치는 "대시보드 편집(US2.2)"의 핵심 기능
  2. 데이터 관점: 배치 정보(위치, 크기)는 대시보드-위젯 연결 데이터의 일부
  3. 사용자 관점: 대시보드를 편집할 때 위젯을 배치하는 것은 하나의 작업

[Question] Data Integration Unit은 Next.js API Route 레이어만 담당하나요, 아니면 클라이언트의 데이터 페칭 로직도 포함하나요?
[Answer]
  Next.js API Route 레이어만 담당합니다.

  구조: 클라이언트 → TanStack Query → Next.js API Route → 외부 API (KOSIS/ECOS)

  Data Integration Unit의 책임:

- Next.js API Route 구현
- 외부 API 호출 및 데이터 변환
- API 파라미터 검증

  클라이언트의 TanStack Query 훅은 각 UI 단위(Dashboard 등)에 포함됩니다.

[Question] Admin Console Unit을 일반 사용자 대시보드와 완전히 독립된 애플리케이션으로 구축해야 하나요?
[Answer]
  네, Micro Frontend Architecture(MFA) 구조로 구축합니다.

  구조:

  1. Shell Application (통합 레이어)이 전체 앱을 컨테이너로 관리
     - Shell은 별도 단위가 아닌 인프라 레이어
     - 비즈니스 로직 없이 순수 통합 역할만 수행
  2. 각 기능을 독립적인 단위로 개발
     - User Dashboard: 일반 사용자용 단위들 (Dashboard, Widget Library)
     - Admin Console: 관리자용 단위
  3. 하나의 로그인으로 통합 인증 후 권한별로 단위 로드

  MFA의 장점:

- 독립적인 개발과 배포 가능
- 각 팀이 병렬로 작업 가능
- 부분 업데이트로 리스크 감소
- 사용자는 하나의 통합된 앱으로 인식

## 추가 질문 사항

[Question] 클라이언트 단위들 간의 상태 공유 방식은 어떻게 할까요? (Dashboard, Widget Library 간)
[Answer]
  현재 사용 중인 Zustand를 유지합니다.

  구조:

- 단위별로 독립된 스토어 생성
  - useDashboardStore (Dashboard)
  - useWidgetStore (Widget Library)
- 필요시 스토어 간 subscribe 패턴으로 상태 동기화
- TypeScript로 타입 안정성 보장

  장점:

- 이미 도입되어 학습 곡선 없음
- 간단하고 직관적인 API
- 번들 크기가 작음 (8KB)

[Question] Widget Library Unit과 Dashboard Unit 간의 데이터 동기화는 어떻게 처리할까요?
(예: 대시보드 삭제 시 위젯 처리)
[Answer]
  위젯은 대시보드와 독립적으로 관리됩니다.

  동작 방식:

- 대시보드 삭제: 레이아웃 정보만 삭제, 위젯은 유지
- 위젯 삭제: 해당 위젯을 사용하는 대시보드 레이아웃에서 제거
- 모든 위젯은 "owned" 모델 (참조 없음)

  흐름:

  1. 대시보드 삭제 시
     - WidgetLayout 테이블 레코드만 삭제
     - Widget 테이블은 변경 없음
  2. 위젯 삭제 시
     - Widget 테이블에서 삭제
     - 관련 WidgetLayout 레코드 cascade 삭제

[Question] 사용자 인증 정보는 모든 단위에서 어떻게 공유할까요? Context API, Redux, 또는 다른 상태관리?
[Answer]
  현재 사용 중인 React Context API를 유지합니다.

  구조:

- AuthContext: 인증 정보 (사용자, 토큰, 권한)
- ThemeContext: 테마 설정 (다크모드 등)
- 최상위 Provider로 전체 앱 래핑

  사용 이유:

- 이미 구현되어 안정적으로 동작 중
- 인증/테마는 자주 변경되지 않아 Context API 적합
- React 내장 기능으로 추가 라이브러리 불필요
- 전역적으로 필요한 정보에 적절

  Zustand와 역할 분리:

- Context API: 전역 설정 (인증, 테마)
- Zustand: 비즈니스 로직 상태 (대시보드, 위젯)

[Question] Data Integration Unit의 캐싱 전략은 어떻게 가져갈까요?
(예: 지표 데이터의 캐싱 주기, 무효화 정책)
[Answer]
  TanStack Query의 캐싱 기능을 활용하여 지표 주기별로 차등 적용합니다.

  캐싱 정책:

- 일간 데이터: staleTime 1시간, cacheTime 6시간
- 월간 데이터: staleTime 6시간, cacheTime 24시간
- 분기/연간 데이터: staleTime 24시간, cacheTime 7일

  추가 전략:

- 사용자가 명시적으로 새로고침 시 캐시 무효화
- 네트워크 오류 시 stale 데이터라도 표시
- 백그라운드에서 refetch하여 사용자 경험 개선

  서버 캐싱:

- Next.js API Route에서 추가 캐싱 레이어
- 외부 API 호출 최소화

[Question] 각 단위의 에러 처리와 로깅은 중앙화할까요, 아니면 각 단위별로 독립적으로 처리할까요?
[Answer]
  하이브리드 방식으로 처리합니다 (중앙 로깅 + 단위별 에러 처리).

  구조:

- 중앙 로깅: Sentry 무료 플랜 사용 (월 5,000 이벤트)
- 단위별 처리: 각 단위가 에러를 catch하고 사용자 친화적 UI 표시
- 공통 유틸: 에러 포맷팅, 메시지 변환 헬퍼

  에러 처리 흐름:

  1. 단위에서 에러 발생
  2. 단위별 에러 핸들러가 catch
  3. Sentry로 자동 전송 (백그라운드)
  4. 사용자에게 적절한 메시지 표시
  5. 개발 환경에서는 console.error 추가 출력

  장점:

- 프로덕션 에러 추적 가능
- 디버깅 용이
- 일관된 에러 처리
- 무료로 시작 가능

## 추가 검토 질문

[Question] MFA 구조에서 User Dashboard와 Admin Console 간 통신이 필요한 경우가 있을까요?
(예: 관리자가 일반 사용자 대시보드를 미리보기)
[Answer]
  특별한 통신이 필요하지 않습니다.

  권한 구조:

- 관리자 = 일반 사용자 기능 + Admin Console 접근 권한
- 관리자도 자신의 대시보드를 생성/편집/사용
- 두 앱은 독립적으로 동작

  라우팅:

- 일반 사용자: Dashboard 앱만 접근
- 관리자: Dashboard 앱 + Admin Console 앱 모두 접근
- Shell App에서 권한에 따라 메뉴 표시

  장점:

- 복잡한 앱 간 통신 불필요
- 관리자 계정으로 모든 기능 테스트 가능
- 권한 체계가 단순하고 명확

[Question] Subscription Unit과 Authentication Unit 간 인터페이스는 어떻게 정의할까요?
(예: 플랜 확인 시 인증 정보 필요)
[Answer]
  단방향 의존 구조로 설계합니다.

  의존 관계:

- Subscription Unit → Authentication Unit (의존)
- Authentication Unit은 Subscription을 모름 (독립적)

  인터페이스:

  ```
  // Subscription이 Authentication에서 가져오는 정보
  - user.id: 구독 정보 조회용
  - user.email: 결제 처리용

  // Subscription이 제공하는 정보 (다른 Unit이 사용)
  - subscription.plan: 현재 플랜 (free/pro)
  - subscription.limits: 플랜별 제한사항
  - subscription.expiryDate: 구독 만료일
  ```

  장점:

- 의존 방향이 명확하고 단순
- Authentication은 순수하게 인증만 담당
- Subscription 변경이 Authentication에 영향 없음

[Question] 위젯 라이브러리에서 위젯을 공개/비공개 설정하는 기능이 필요한가요?
(예: 다른 사용자가 참조할 수 있도록)
[Answer]
  네, 단순 공개/비공개 설정 기능이 필요합니다.

  위젯 공유 내용:

- 위젯은 파라미터와 설정값만 저장 (데이터 X)
- 지표 ID, 차트 타입, 기간 설정, 표시 옵션 등
- 실제 데이터는 각 사용자가 API 호출로 조회

  공개 설정:

  ```typescript
  widget.isPublic: boolean  // 단순 공개/비공개
  ```

  보안 고려사항:

- 공공 API (KOSIS, ECOS) 파라미터이므로 노출 안전
- 민감한 개인 데이터 없음
- 각 사용자의 API 권한으로 데이터 조회

  구현 방식:

- 공개 위젯은 위젯 라이브러리에서 검색 가능
- Free: 참조만 가능 (원본 수정 시 자동 반영)
- Pro: 복사도 가능 (독립적인 위젯 생성)

[Question] Data Integration Unit에서 API 요청 제한(Rate Limiting)을 어떻게 관리할까요?
(예: 외부 API의 일일 호출 제한)
[Answer]
  캐싱 중심으로 관리하며, 필요시 Rate Limiting 추가합니다.

  현재 API 제한 상황:

- KOSIS: 일일 호출 제한 없음 (1회당 최대 40,000건)
- ECOS: 구체적 제한 미공개 (과도한 요청 금지)
- 이미 코드에 Rate Limit 에러 처리 구현됨

  관리 전략:

  1. TanStack Query 캐싱 최대 활용
     - 긴 staleTime으로 불필요한 호출 방지
  2. Next.js API Route에서 응답 캐싱
     - 동일 요청에 대한 중복 호출 방지
  3. Exponential Backoff (이미 구현됨)
     - Rate Limit 에러 시 자동 재시도
  4. 필요시 메모리 기반 카운터 추가
     - 일일 호출 횟수 모니터링

  결론:

- 공공 API라 제한이 엄격하지 않음
- 캐싱 위주로 운영하면 충분
- 문제 발생 시 점진적으로 제한 추가

## 아키텍처 요약

### 전체 구조

- **Shell Application**: 통합 레이어 (단위가 아닌 컨테이너)
- **6개 독립 단위**: 각각 독립적으로 개발/배포 가능
- **공통 인증**: 단일 로그인 후 권한 기반 접근
- **MFA 구조**: Micro Frontend Architecture로 확장성 확보

### 단위 구성

1. **사용자 영역**: Dashboard, Widget Library
2. **데이터 영역**: Data Integration
3. **인증/권한**: Authentication, Subscription
4. **관리자 영역**: Admin Console

## 다음 단계

계획을 검토하고 승인해 주시면, 각 단위별 상세 문서 작성을 시작하겠습니다.
