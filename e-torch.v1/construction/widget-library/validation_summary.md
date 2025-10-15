# Widget Library Unit - 도메인 모델 검증 요약

## 개요

이 문서는 Widget Library Unit의 도메인 모델이 모든 사용자 스토리 (US3.1 ~ US3.8)를 충족하는지 검증합니다.

## 검증 결과: ✅ 통과

모든 8개 사용자 스토리가 도메인 모델로 구현 가능하며, DDD 전술적 패턴이 올바르게 적용되었습니다.

---

## US3.1: 위젯 생성 ✅

**요구사항**:
- 내 위젯 페이지에서 새 위젯 생성
- 대시보드 편집 중 새 위젯 생성
- 위젯 타입 선택
- 지표 검색 및 선택
- 시각화 옵션 설정
- 내 위젯 라이브러리에 저장
- 선택적으로 대시보드 추가 가능

**도메인 모델 구현**:
- ✅ `Widget.create(type, ownerId, initialParams)` 정적 팩토리 메서드
- ✅ `WidgetType` Enum (9가지 타입)
- ✅ `WidgetParameters` Zod Schema (indicatorId, dateRange, chartConfig 등)
- ✅ `IWidgetRepository.save(widget)` 저장
- ✅ WidgetCreated 도메인 이벤트 발행
- ✅ Application Service에서 대시보드 추가 로직 조율

**구현 흐름**:
```
User → Application Service →
  1. Widget.create(type, userId, params)
  2. WidgetCreated 이벤트 발행
  3. IWidgetRepository.save(widget)
  4. (선택) Dashboard Unit API 호출하여 대시보드 추가
```

---

## US3.2: 위젯 편집 ✅

**요구사항**:
- 지표 변경 가능
- 시각화 옵션 변경 가능
- 편집 중 미리보기
- 변경사항이 위젯 라이브러리에 저장
- **해당 위젯을 사용하는 모든 대시보드에 즉시 반영**

**도메인 모델 구현**:
- ✅ `Widget.update(name, description, parameters)` 메서드
- ✅ `updatedAt` 타임스탬프 갱신
- ✅ **참조 기반 아키텍처**: Dashboard는 widgetId만 저장 → 렌더링 시 최신 Widget 조회
- ✅ **WidgetUpdated 이벤트 발행하지 않음** (설계 결정)
- ✅ TanStack Query 캐시 무효화로 Frontend 실시간성 보장

**"즉시 반영" 구현 원리**:
```
Dashboard 렌더링 시:
  1. Dashboard.getWidgetIds() → ['widget-1', 'widget-2', ...]
  2. 각 widgetId로 IWidgetRepository.findById() 호출
  3. 항상 최신 Widget 조회 (데이터 복사본 없음)
  4. 이벤트 없이 자동으로 "즉시 반영" 달성
```

**설계 근거**:
- Dashboard가 Widget 데이터를 복사하지 않고 ID 참조만 저장
- WidgetUpdated 이벤트 발행 시 불필요한 복잡도 및 성능 저하
- 참조 기반 아키텍처가 요구사항을 자연스럽게 충족

---

## US3.3: 공개 위젯 추가 ✅

**요구사항**:
- 공개 위젯 갤러리에서 추가
- 대시보드 편집 모달에서 추가
- 공개 대시보드 조회 중 추가
- **원본 설정을 복사한 새 위젯 생성**
- 새 위젯이 내 위젯 라이브러리에 저장
- **복사된 위젯은 독립적으로 편집 가능**
- Free 플랜 대시보드당 위젯 6개 제한 체크

**도메인 모델 구현**:
- ✅ `Widget.copy(newOwnerId)` 메서드 (Deep Copy)
- ✅ 새 ID 발급, 파라미터 deep clone
- ✅ `isPublic = false`, `copyCount = 0` 초기화
- ✅ 원본과 완전히 독립적인 별도 Widget Aggregate
- ✅ 원본의 `copyCount` 증가 (인기도 지표)
- ✅ 플랜 제한은 Subscription Unit 정책 (Application Service에서 검증)

**복사 흐름**:
```
User → Application Service →
  1. IWidgetRepository.findById(widgetId)
  2. if (!originalWidget.isPublic) throw WidgetNotPublicError
  3. copiedWidget = originalWidget.copy(currentUserId)
  4. IWidgetRepository.save(copiedWidget)
  5. originalWidget.incrementCopyCount()
  6. IWidgetRepository.save(originalWidget)
  7. Dashboard Unit API 호출하여 선택한 대시보드에 배치
```

**설계 근거**:
- US3.3 명시: "복사된 위젯은 독립적으로 편집 가능"
- Deep Copy로 원본 변경 시 복사본에 영향 없음 보장
- 향후 "업데이트 확인" 기능 필요 시 `copiedFrom` 메타데이터 추가 가능

---

## US3.4: 내 위젯을 다른 대시보드에 배치 ✅

**요구사항**:
- 내 위젯 페이지에서 대시보드에 추가
- 대시보드 편집 모달에서 내 위젯 선택
- 배치된 위젯 메뉴에서 다른 대시보드에 추가
- **위젯 편집 시 해당 위젯을 사용하는 모든 대시보드에 자동 반영**
- Free 플랜 대시보드당 위젯 6개 제한 체크

**도메인 모델 구현**:
- ✅ Dashboard Unit이 widgetId 참조 저장
- ✅ **US3.2와 동일한 참조 기반 아키텍처**로 "자동 반영" 구현
- ✅ Application Service가 Dashboard Unit API 호출하여 위젯 배치
- ✅ 플랜 제한 검증은 Dashboard Unit의 Application Service에서 수행

**배치 흐름**:
```
User → Application Service →
  1. IWidgetRepository.findById(widgetId)
  2. if (widget.ownerId != currentUserId) throw UnauthorizedError
  3. Dashboard Unit API: POST /api/dashboards/{dashboardId}/widgets
     Body: { widgetId }
  4. Dashboard Unit에서 플랜 제한 검증 (Subscription Unit 호출)
  5. Dashboard.addWidget(widgetId) 실행
```

**설계 근거**:
- US3.4의 "자동 반영"은 US3.2와 동일한 메커니즘
- Dashboard가 Widget을 참조하므로 복사 없이 재사용 가능
- Widget Unit은 Dashboard의 존재를 모름 (단방향 의존성)

---

## US3.5: 내 위젯 라이브러리 관리 ✅

**요구사항**:
- 내가 생성한 모든 위젯 목록 표시
- 위젯 타입별 필터링
- 지표별 필터링
- **위젯별 사용 중인 대시보드 수 확인**
- 공개/비공개 상태 토글
- 위젯 편집 및 삭제

**도메인 모델 구현**:
- ✅ `IWidgetRepository.findByOwnerId(ownerId)` 쿼리 메서드
- ✅ `IWidgetRepository.findByType(type)` 쿼리 메서드 (선택)
- ✅ `Widget.publish()`, `Widget.unpublish()` 메서드
- ✅ **대시보드 수 확인**: Application Service가 Dashboard Unit API 호출
- ✅ `Widget.update()`, `Widget.delete()` 메서드

**대시보드 사용 개수 조회 흐름**:
```
User → Application Service →
  1. IWidgetRepository.findById(widgetId)
  2. Dashboard Unit API: GET /api/dashboards/widgets/{widgetId}/usage
  3. Dashboard Unit이 자신의 DashboardRepository로 COUNT 쿼리 실행
  4. Response: { count: number }
  5. Presentation Layer에 전달
```

**설계 근거**:
- Widget Aggregate는 Dashboard를 몰라야 함 (단방향 참조)
- WidgetRepository가 Dashboard 테이블 조회 시 Repository 경계 위반
- Unit 간 통신은 Application Layer에서 조율

---

## US3.6: 위젯 삭제 ✅

**요구사항**:
- 사용 중인 대시보드 확인 및 표시
- 삭제 경고 메시지 표시
- 위젯 라이브러리에서 삭제
- **해당 위젯을 사용하는 모든 대시보드에서 자동 제거**

**도메인 모델 구현**:
- ✅ `Widget.delete()` 메서드 (Soft Delete: `deletedAt` 설정)
- ✅ **WidgetDeleted 도메인 이벤트** 발행
- ✅ **Dashboard Unit의 WidgetDeletedEventHandler**가 이벤트 구독
- ✅ 이벤트 핸들러가 `Dashboard.removeWidget(widgetId)` 호출하여 참조 제거
- ✅ 사용 대시보드 확인은 US3.5와 동일 (Application Service → Dashboard Unit API)

**삭제 흐름**:
```
User → Application Service →
  1. Dashboard Unit API: GET /api/dashboards/widgets/{widgetId}/usage
  2. Presentation Layer에 경고 다이얼로그 표시
  3. 사용자 확인 후 Widget.delete() 실행
  4. deletedAt = now()
  5. WidgetDeleted 이벤트 발행
  6. IWidgetRepository.save(widget)

Dashboard Unit (비동기):
  WidgetDeletedEventHandler →
    1. Dashboard.removeWidget(widgetId)
    2. 모든 대시보드에서 위젯 참조 제거
    3. 실패 시 재시도 메커니즘 (Message Queue)
```

**설계 근거**:
- Soft Delete로 데이터 복구 가능성 및 감사 로그 보장
- 이벤트 기반으로 Widget Unit과 Dashboard Unit 느슨한 결합 (Loose Coupling)
- Eventual Consistency 허용 (삭제 후 대시보드 정리는 수 초 지연 가능)
- 고아 참조(orphaned reference) 방어: 렌더링 시 Widget 조회 실패로 안전 처리

---

## US3.7: 공개 위젯 갤러리 탐색 ✅

**요구사항**:
- 공개된 모든 위젯 목록 표시
- 인기 위젯 Top 10 섹션
- 카테고리별 탐색
- 위젯 타입별 필터링
- 지표별 필터링
- 키워드 검색
- 위젯 미리보기
- "내 대시보드에 추가" 버튼

**도메인 모델 구현**:
- ✅ **쿼리 모델 (CQRS Read Model)** - 별도 Aggregate 아님
- ✅ `IWidgetRepository.findPublicWidgets(sortBy, limit, offset)` 쿼리 메서드
- ✅ `sortBy: 'popular'` (copyCount DESC) 또는 `'latest'` (createdAt DESC)
- ✅ `Widget.copyCount` 속성으로 인기도 추적
- ✅ Application Service의 `WidgetGalleryService`로 유비쿼터스 언어 유지
- ✅ "내 대시보드에 추가"는 US3.3 복사 로직 재사용

**갤러리 조회 흐름**:
```
User → Application Service → WidgetGalleryService →
  IWidgetRepository.findPublicWidgets({
    sortBy: 'popular', // 또는 'latest'
    limit: 20,
    offset: 0,
    type: 'BAR_CHART' // 선택적 필터
  }) → Widget[]
```

**설계 근거**:
- US3.7의 요구사항은 단순 조회 (트랜잭션 경계 불필요)
- Widget 테이블을 `isPublic=true` 조건으로 직접 조회하여 실시간 일관성 보장
- 향후 Elasticsearch 추가 시 Query Layer만 교체하면 되어 확장 용이
- 큐레이션/추천 기능 추가 시 별도 Aggregate로 승격 검토 가능

---

## US3.8: 데이터 내보내기 ✅

**요구사항**:
- 차트 데이터를 CSV/Excel로 내보내기
- 파일명에 위젯명과 날짜 포함
- 현재 표시된 기간의 데이터만 내보내기
- Free 플랜 사용자 기능 비활성화 및 업그레이드 안내

**도메인 모델 구현**:
- ✅ **도메인 로직 없음** (Infrastructure 관심사)
- ✅ Application Service가 Widget 조회 후 Data Integration Unit API 호출
- ✅ `Widget.parameters` 추출 (indicatorId, dateRange)
- ✅ 플랜 검증은 Subscription Unit 정책 (Application Service에서 확인)

**내보내기 흐름**:
```
User → Application Service →
  1. Subscription Unit API: GET /api/subscriptions/{userId}/plan
  2. if (plan == 'FREE') return { error: 'Upgrade Required' }
  3. IWidgetRepository.findById(widgetId)
  4. Data Integration Unit API: POST /api/data/export
     Body: {
       indicatorId: widget.parameters.indicatorId,
       dateRange: widget.parameters.dateRange,
       format: 'csv' // 또는 'excel'
     }
  5. Response: File Download
```

**설계 근거**:
- 데이터 내보내기는 Widget 도메인 로직이 아닌 Infrastructure 기능
- Data Integration Unit이 실제 데이터 조회 및 파일 생성 담당
- Widget Unit은 파라미터 제공만 책임
- Clean Architecture의 관심사 분리 (Separation of Concerns) 준수

---

## 전체 검증 매트릭스

| 사용자 스토리 | 도메인 모델 구현 | 핵심 패턴 | 상태 |
|--------------|------------------|-----------|------|
| US3.1: 위젯 생성 | Widget.create(), WidgetCreated 이벤트 | Aggregate, Factory Method, Domain Event | ✅ |
| US3.2: 위젯 편집 | Widget.update(), 참조 기반 아키텍처 | Aggregate, 이벤트 없는 설계 | ✅ |
| US3.3: 공개 위젯 추가 | Widget.copy(), Deep Copy | Aggregate Method, Value Object Clone | ✅ |
| US3.4: 내 위젯 배치 | 참조 기반 아키텍처, Dashboard Unit 연계 | Aggregate Reference, Application Service 조율 | ✅ |
| US3.5: 위젯 라이브러리 관리 | IWidgetRepository 쿼리, Dashboard Unit API | Repository Pattern, Unit 간 통신 | ✅ |
| US3.6: 위젯 삭제 | Widget.delete(), WidgetDeleted 이벤트 | Soft Delete, Event-Driven, Eventual Consistency | ✅ |
| US3.7: 공개 위젯 갤러리 | findPublicWidgets(), CQRS Read Model | Query Model, Repository Pattern | ✅ |
| US3.8: 데이터 내보내기 | Widget.parameters, Data Integration Unit 연계 | Infrastructure Layer, 관심사 분리 | ✅ |

---

## DDD 전술적 패턴 검증

### Aggregate ✅
- **Widget Aggregate Root**: 단일 Aggregate로 모든 위젯 타입 관리
- **트랜잭션 경계**: 개별 위젯 단위
- **불변 조건**: 소유자, 타입, 파라미터 검증
- **작은 Aggregate 원칙**: Pro 사용자 대량 위젯 시나리오 대응

### Entity ✅
- **Widget Entity**: UUID 식별자, 생명주기 메서드, 불변 조건 보장
- **Aggregate 내 로직 집중**: 엔티티에 최대한 로직 배치

### Value Object ✅
- **WidgetType**: TypeScript Union Type Enum (컴파일 타임 타입 체크)
- **WidgetParameters**: Zod Schema (타입 + 런타임 검증)
- **DateRange**: Zod Schema (불변성, 동등성, 검증 로직)

### Domain Event ✅
- **WidgetCreated**: 위젯 생성 추적
- **WidgetPublished**: 공개 갤러리 업데이트
- **WidgetDeleted**: Dashboard Unit 비동기 정리
- **WidgetRestored**: 향후 복구 기능
- **WidgetUpdated 없음**: 참조 기반 설계로 불필요

### Domain Service ❌ (의도적으로 없음)
- WidgetFactory 불필요: Widget.create() 정적 메서드로 충분
- 복사 로직: Widget.copy() 인스턴스 메서드
- 렌더링: Presentation Layer 책임

### Policy ❌ (의도적으로 없음)
- 공개 조건 없음: 단순 상태 변경
- 플랜 제한: Subscription 도메인 책임
- 삭제 경고: UX 관심사, 정책 아님

### Repository ✅
- **IWidgetRepository**: 기본 CRUD + 필수 쿼리
- **Aggregate per Repository**: Widget Aggregate 전용
- **최소 인터페이스**: 복잡한 검색은 별도 SearchRepository로 분리 가능
- **쿼리 메서드**: findByOwnerId, findPublicWidgets, findByType

---

## Clean Architecture 검증 ✅

### Dependency Rule 준수
- **Domain Layer**: 외부 의존성 없음 (Pure TypeScript/Zod)
- **Application Layer**: Domain Layer만 의존
- **Infrastructure Layer**: Domain 인터페이스 구현
- **Presentation Layer**: Application Layer (Use Cases) 의존

### Bounded Context 독립성 ✅
- Widget Unit은 Dashboard Unit을 모름 (단방향 의존성)
- Unit 간 통신은 Application Layer에서 API 호출로 조율
- Dashboard → Widget 참조: ID 참조만 사용
- 이벤트 기반 느슨한 결합: WidgetDeleted 이벤트

### 레이어 분리 ✅
- **Domain**: Widget, WidgetType, WidgetParameters, IWidgetRepository
- **Application**: WidgetApplicationService, WidgetGalleryService, Use Cases
- **Infrastructure**: SupabaseWidgetRepository, EventPublisher
- **Presentation**: WidgetRenderer, WidgetList, WidgetGallery

---

## 확장성 및 유지보수성 검증 ✅

### 1. 위젯 타입 추가
- ✅ WidgetType Enum에 타입 추가
- ✅ 해당 타입 Zod Schema 정의
- ✅ WIDGET_TYPE_METADATA 업데이트
- ✅ Presentation Layer 렌더링 컴포넌트 추가
- ✅ **기존 코드 수정 최소화**

### 2. 공개 조건 추가 (예: 승인 필요)
- ✅ PublishingPolicy 도메인 서비스 생성
- ✅ Widget.publish() 메서드에 정책 적용
- ✅ WidgetApprovalRequested 이벤트 추가
- ✅ **기존 Aggregate 구조 유지**

### 3. 검색 기능 추가
- ✅ Elasticsearch 기반 별도 SearchRepository 생성
- ✅ WidgetIndexed 이벤트 추가
- ✅ Elasticsearch 동기화 EventHandler 구현
- ✅ **도메인 모델 변경 없음**

### 4. 협업 기능 추가
- ✅ 새 Aggregate: WidgetCollaboration
- ✅ WidgetPermission 값 객체
- ✅ WidgetShared 이벤트
- ✅ **Widget Aggregate와 독립적으로 추가 가능**

---

## 비기능 요구사항 검증 ✅

### 성능
- ✅ 데이터베이스 인덱스: (ownerId, deletedAt), (isPublic, copyCount)
- ✅ 쿼리 최적화: N+1 문제 방어, 페이지네이션
- ✅ TanStack Query 캐시: 클라이언트 성능 향상

### 동시성
- ✅ 낙관적 잠금 (Optimistic Locking): version 필드
- ✅ 작은 Aggregate: Pro 사용자 대량 위젯 동시 수정 가능

### 데이터 무결성
- ✅ Soft Delete: 실수 복구 가능, 감사 로그
- ✅ Zod Schema 검증: 런타임 데이터 유효성
- ✅ 불변 조건: Aggregate 내 검증

### 확장성
- ✅ Eventual Consistency: 위젯 삭제 후 대시보드 정리 비동기
- ✅ 이벤트 기반 아키텍처: Message Queue로 확장 가능
- ✅ CQRS Read Model: 향후 Elasticsearch 전환 용이

---

## 결론

### ✅ 검증 통과

Widget Library Unit의 도메인 모델은 다음을 충족합니다:

1. **모든 사용자 스토리 (US3.1 ~ US3.8) 구현 가능** ✅
2. **DDD 전술적 패턴 올바르게 적용** ✅
   - Aggregate, Entity, Value Object, Domain Event, Repository 적절히 사용
   - Domain Service, Policy는 의도적으로 제외 (YAGNI 원칙)
3. **Clean Architecture 원칙 준수** ✅
   - Dependency Rule, Bounded Context 독립성, 레이어 분리
4. **확장성 및 유지보수성 보장** ✅
   - 위젯 타입 추가, 기능 확장 시 최소 변경
5. **비기능 요구사항 충족** ✅
   - 성능, 동시성, 데이터 무결성, 확장성

### 주요 설계 결정

1. **참조 기반 아키텍처** (US3.2, US3.4):
   - Dashboard가 Widget 데이터를 복사하지 않고 ID 참조만 저장
   - "즉시 반영" 요구사항을 이벤트 없이 자연스럽게 충족

2. **Deep Copy 전략** (US3.3):
   - 공개 위젯 복사 시 완전히 독립적인 복사본 생성
   - 원본과 복사본 간 영향 없음 보장

3. **이벤트 기반 삭제** (US3.6):
   - WidgetDeleted 이벤트로 Dashboard Unit과 느슨한 결합
   - Eventual Consistency로 확장성 확보

4. **쿼리 모델 갤러리** (US3.7):
   - 별도 Aggregate 없이 Repository 쿼리로 구현
   - 향후 Elasticsearch 전환 용이

### 다음 단계

✅ Construction 단계 다음 작업:
1. Logical Architecture 설계 (클래스 다이어그램, 시퀀스 다이어그램)
2. 데이터베이스 스키마 설계
3. API 엔드포인트 설계
4. 구현 (Code Generation)

---

**작성일**: 2025-10-11
**검증자**: Claude (AI-DLC Agent)
**승인 대기**: 사용자 최종 검토
