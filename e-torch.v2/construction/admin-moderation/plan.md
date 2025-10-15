# Admin Moderation Feature Module 설계 계획

## 개요

**Feature Module**: Admin Moderation
**책임**: 컨텐츠 안전 및 규제 관리 (US6.9~6.11)
**아키텍처**: Multi-Zone (apps/admin), BFF + Feature Module, TypeScript + Zod + React + TanStack Query

## 목표

Admin Moderation Feature Module의 설계 문서를 작성하여 다음을 달성합니다:

1. **타입 안정성**: TypeScript Interface + Zod Schema로 컴파일 타임 + 런타임 검증
2. **명확한 계약**: AdminModerationContract의 10개 메서드를 React Components + TanStack Query Hooks로 매핑
3. **독립 배포**: packages/admin-moderation/ 패키지로 분리, apps/admin에서 사용
4. **재사용성**: packages/ui의 범용 컴포넌트 활용

## 포함된 사용자 스토리

### US6.9: 신고된 컨텐츠 관리

- 신고된 대시보드 목록 조회 (신고 사유, 접수일시, 신고자 수)
- 대시보드 상세 검토 (원본 내용, 작성자 이력)
- 조치 실행: 경고, 삭제, 계정 정지, 무혐의
- 조치 사유 기록 및 결과 통보
- ActivityLog 자동 기록

### US6.10: 컨텐츠 위반 사용자 관리

- 사용자별 위반 이력 조회 (경고 횟수, 삭제된 대시보드 수, 마지막 위반 날짜)
- 단계적 제재 시스템 (1회 경고 → 2회 48시간 제한 → 3회 영구 정지)
- 수동 제재 옵션
- 제재 내역 통보 및 ActivityLog 기록

### US6.11: 위험 컨텐츠 자동 탐지

- 위험 패턴 자동 스캔 (종목명 + 행동 유도, 수익 보장, 타이밍 단정, 외부 링크)
- 플래깅된 대시보드 목록 (키워드 하이라이트, 위험도 점수)
- 자동 조치 설정 (높음/중간/낮음)
- 오탐 처리 및 학습
- 탐지 룰 관리 (정규표현식 기반)

## 아키텍처 결정 (Admin Console에서 승인됨)

### 1. 레이아웃 구조: Simple Layout (packages/ui 재사용)

**결정**: packages/ui에 범용 AppLayout 구현, apps/admin에서 공유

**이유**:

- Multi-Zone + Monorepo 구조에 적합
- 범용 옵션 기반 설계 (navigation, showUserMenu, headerActions 등의 Props)
- Admin Console과 Admin Moderation이 동일한 AppLayout 사용, Props로 차이 처리

### 2. Query Key 전략: Resource 기반

**결정**: Resource 중심의 Query Key 구조 사용

**Resource 이름**:

- admin-moderation: `reports`, `violations`, `detection-rules`, `auto-detected`, `violation-stats`

**Query Key 예시**:

- `['reports', 'list', filters]`
- `['reports', reportId]`
- `['violations', 'user', userId]`
- `['violations', 'stats']`
- `['detection-rules', 'list']`
- `['auto-detected', 'list', filters]`

**이유**:

- TanStack Query 공식 권장 패턴
- Multi-Zone 구조에서 독립 QueryClient, Resource 이름 충돌 없음
- 2-3단계 구조로 짧고 직관적

### 3. Business Logic 분리: 선택적 분리

**결정**: 복잡한 검증 로직만 별도 Service로 분리

**분리할 Service** (복잡도 높음):

- **detectionRuleValidation.ts**: 정규표현식 패턴 검증, 위험 키워드 매칭 로직, 탐지 룰 충돌 체크
- **violationSeverityCalculator.ts**: 위반 심각도 계산 (누적 횟수, 위반 유형, 최근 위반 간격)

**Hook/컴포넌트에 포함** (복잡도 낮음):

- 신고 필터링: 간단한 쿼리 파라미터 처리
- 제재 기간 계산: 간단한 날짜 계산
- 조치 결과 포맷팅: UI 표시용 변환

## 설계 단계 (8 Phase)

### Phase 1: 사전 조사 및 준비

- [x] AdminModerationContract 분석 (10개 메서드)
- [x] 공통 타입 추출 (DashboardReport, ViolationLog, ViolationStats, DetectionRule)
- [x] 의존성 파악 (Authentication, Dashboard - 읽기 전용)

### Phase 2: Type 정의 설계

- [x] AdminModerationContract 10개 메서드의 TypeScript Interface 정의
- [x] 각 메서드의 Request/Response 타입 정의
- [x] Zod Schema 정의 (런타임 검증용)

### Phase 3: Component Tree 설계

- [x] 3개 주요 페이지 컴포넌트 계층 설계:
  - `/moderation/reports` - 신고 관리 (US6.9)
  - `/moderation/violations` - 위반 사용자 관리 (US6.10)
  - `/moderation/detection` - 자동 탐지 관리 (US6.11)
- [x] 공통 컴포넌트 재사용 (DataTable, FormDialog, ConfirmDialog 등)
- [x] 특수 컴포넌트 설계 (ViolationTimeline, DetectionRuleEditor, KeywordHighlighter)

### Phase 4: TanStack Query Hook 설계

- [x] 10개 메서드를 Query/Mutation Hook으로 매핑
- [x] Query Key 구조 정의 (Resource 기반)
- [x] Caching 전략 수립 (staleTime, cacheTime)
- [x] Invalidation 패턴 정의 (조치 실행 후 목록 갱신)

### Phase 5: Business Logic 분리 설계

- [x] detectionRuleValidation.ts 인터페이스 설계
- [x] violationSeverityCalculator.ts 인터페이스 설계
- [x] Service와 Hook의 통합 방식 정의

### Phase 6: File Structure 설계

- [x] packages/admin-moderation/ 패키지 구조 정의
- [x] apps/admin/app/(moderation)/ 라우팅 구조 정의
- [x] 컴포넌트, Hook, Service 파일 배치

### Phase 7: 보안 및 의존성 설계

- [x] 관리자 권한 검증 전략
- [x] 신고자 익명성 보호
- [x] 조치 로그 영구 보존 전략
- [x] 외부 패키지 의존성 정리
- [x] 내부 Feature Module 의존성 정리

### Phase 8: 문서 작성 및 검증

- [x] feature_module_design.md 작성
- [x] 모든 US6.9~6.11 요구사항 커버 확인
- [x] AdminModerationContract 10개 메서드 완전 매핑 확인
- [x] 다음 단계 (BFF API 구현) 가이드 작성

## 다음 단계 (Construction Phase)

설계 완료 후:

1. **BFF API 구현**: apps/admin/app/api/moderation/ 라우트 생성
2. **Supabase Schema**: dashboard_reports, violation_logs, detection_rules 테이블 설계
3. **Feature Module 구현**: packages/admin-moderation/ 패키지 구현
4. **통합 테스트**: Admin Console과의 통합 테스트
5. **배포**: Vercel Multi-Zone 배포 설정

## 산출물

- `docs/aidlc-docs/construction/admin-moderation/feature_module_design.md`
  - AdminModerationContract 10개 메서드의 완전한 설계
  - TypeScript Interface + Zod Schema (코드 스니펫 제외, 설계 명세만)
  - React Components Tree (3개 페이지)
  - TanStack Query Hooks (10개 메서드 매핑)
  - Business Logic 분리 전략
  - File Structure
  - 보안 고려사항
  - 다음 단계 가이드
