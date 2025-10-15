# Widget Library Unit - DDD 도메인 모델 설계 계획

## 목표

Widget Library Unit에 대해 도메인 주도 설계(DDD)를 사용하여 도메인 모델을 설계합니다.

## 작업 범위

- **대상 단위**: Widget Library Unit (widget-library.md)
- **포함된 사용자 스토리**: US3.1 ~ US3.8 (8개)
- **산출물**: `docs/aidlc/construction/widget-library/domain_model.md`

## 작업 단계

### 단계 1: 도메인 분석 및 바운디드 컨텍스트 식별

- [ ] Widget Library Unit의 8개 사용자 스토리 재검토
- [ ] 주요 도메인 개념 추출 및 정리
- [ ] 바운디드 컨텍스트 경계 식별
- [ ] 유비쿼터스 언어(Ubiquitous Language) 정의

[Question] Widget Library는 단일 바운디드 컨텍스트인가요, 아니면 "위젯 관리"와 "차트 렌더링"을 별도 컨텍스트로 분리해야 할까요?
[Answer] 단일 바운디드 컨텍스트 "Widget Library"로 관리합니다. 모든 기능이 "위젯"이라는 핵심 도메인 개념을 공유하고, 위젯 생성-편집-렌더링이 하나의 흐름으로 긴밀히 연결되어 있으며, 이미 Inception 단계에서 독립 단위로 정의되었습니다. 차트 렌더링은 기술적 구현 레이어의 차이일 뿐 도메인 경계 분리 사유가 아닙니다.

[Question] 9가지 위젯 타입은 모두 동일한 Widget Aggregate로 모델링되어야 할까요, 아니면 타입별로 별도 Aggregate가 필요한가요?
[Answer] 단일 Widget Aggregate로 모델링합니다. 모든 타입이 동일한 생명주기(생성-편집-삭제-공개/비공개)를 가지며, 동일한 트랜잭션 경계(위젯 편집 시 모든 대시보드에 즉시 반영)와 공통 불변 조건(소유자, 공개 상태, 플랜 제한)을 공유합니다. 타입별 차이는 WidgetType 열거형과 타입별 파라미터 값 객체(ChartConfig, TextConfig 등)로 처리하며, WidgetFactory 도메인 서비스가 타입별 생성 로직을 담당합니다.

### 단계 2: 애그리게이트 식별 및 경계 정의

- [ ] 트랜잭션 일관성이 필요한 경계 식별
- [ ] 각 애그리게이트의 루트 엔티티 결정
- [ ] 애그리게이트 간 참조 방식 정의 (ID 참조 vs 객체 참조)
- [ ] 애그리게이트별 불변 조건(Invariant) 정의

[Question] Widget은 하나의 Aggregate인가요? 아니면 WidgetLibrary가 별도 Aggregate로 필요한가요?
[Answer] Widget만 Aggregate Root로 정의합니다. WidgetLibrary는 별도 Aggregate가 아닌 Application Service 레벨의 개념입니다. 이유: (1) 트랜잭션 일관성은 개별 위젯 단위로만 필요, (2) WidgetLibrary가 Aggregate Root면 모든 위젯 수정 시 전체 라이브러리 Lock 발생하여 동시성 저하, (3) Pro 사용자의 대량 위젯 시나리오에서 성능 문제, (4) DDD 원칙 "작은 Aggregate가 좋다" 부합. 위젯 소유권은 `Widget.ownerId` 속성으로 관리하고, "내 위젯 목록" 조회는 `WidgetRepository.findByOwnerId()` 쿼리 메서드로 처리합니다.

[Question] US3.3 공개 위젯 복사 시 "완전히 독립적인 복사본"을 만드나요, 아니면 원본과의 연결이 유지되어야 하나요?
[Answer] 완전히 독립적인 복사본(Deep Copy)을 생성합니다. US3.3에 "복사된 위젯은 독립적으로 편집 가능"이라고 명시되어 있으며, 원본 위젯 변경 시 복사본에 영향 없음을 보장합니다. `Widget.copy(newOwnerId)` 메서드가 새로운 ID와 소유자로 위젯을 생성하며, 파라미터는 deep clone합니다. 복사 후에는 원본과 완전히 독립적인 별도의 Widget Aggregate입니다. 향후 "업데이트 확인" 기능이 필요하면 `copiedFrom` 메타데이터를 선택적으로 추가할 수 있습니다.

[Question] US3.7 공개 위젯 갤러리는 별도 Aggregate인가요, 아니면 Widget Aggregate의 쿼리 모델인가요?
[Answer] 쿼리 모델(CQRS Read Model)입니다. 별도 Aggregate가 아닙니다. 이유: (1) US3.7의 요구사항은 단순 조회("공개된 위젯 목록", "인기순/최신순 정렬")로 트랜잭션 경계 불필요, (2) Widget 테이블을 `isPublic=true` 조건으로 직접 조회하여 실시간 일관성 보장, (3) 향후 Elasticsearch 추가 시 Query Layer만 교체하면 되어 확장 용이. Application Service에서 `WidgetGalleryService`로 유비쿼터스 언어를 유지하되, 내부적으로는 `WidgetQueryRepository.findPublicWidgets()` 쿼리 메서드를 사용합니다. 큐레이션/추천 기능이 추가되면 그때 Aggregate로 승격 검토합니다.

### 단계 3: 엔티티와 값 객체 설계

- [ ] 각 애그리게이트 내 엔티티 식별
- [ ] 식별자가 필요한 개념(엔티티) vs 속성으로 정의 가능한 개념(값 객체) 구분
- [ ] 값 객체의 불변성 및 동등성 정의
- [ ] 엔티티의 생명주기 정의

[Question] WidgetType은 값 객체인가요, 아니면 Enum인가요?
[Answer] 단순 TypeScript Union Type Enum입니다. 값 객체로 만들지 않습니다. 이유: (1) 9가지 위젯 타입은 고정된 상수로 런타임 추가 없음, (2) 현재 요구사항에 타입별 특별한 검증 로직이나 메타데이터가 없음, (3) TypeScript Union Type의 컴파일 타임 타입 체크와 IDE 자동완성 지원이 강력함, (4) JSON 직렬화가 자동으로 처리됨. 타입별 메타데이터(displayName, icon, category)는 별도 상수 객체 `WIDGET_TYPE_METADATA`로 관리합니다. 향후 타입별 검증 로직이나 행동(behavior)이 필요하면 그때 값 객체로 리팩토링합니다.

[Question] WidgetParameters는 값 객체인가요? 각 위젯 타입마다 다른 파라미터 구조를 가지는데 어떻게 모델링해야 할까요?
[Answer] Zod Schema를 사용하여 타입 안정성과 런타임 검증을 모두 확보합니다. 전통적인 값 객체 클래스 대신 Zod Schema로부터 TypeScript 타입을 자동 생성합니다. 이유: (1) Recharts는 버전 고정 시 API가 불변하므로 타입 정의 가능하고 해야 함 (Admin Console의 외부 API와 다름), (2) Recharts의 공식 타입 정의(@types/recharts)를 재사용 가능, (3) Zod Schema가 컴파일 타임 타입 + 런타임 검증 + Frontend/Backend 재사용을 모두 제공, (4) 직렬화 안전(함수 제외). 구현 방식: 핵심 파라미터(indicatorId, dateRange)는 필수 정의하고, Recharts 차트 옵션은 자주 쓰는 것만 선별하여 Schema화하며 `.passthrough()`로 확장 여지를 남깁니다. 점진적으로 Schema를 확장합니다.

### 단계 4: 도메인 이벤트 정의

- [ ] 비즈니스적으로 중요한 상태 변경 식별
- [ ] 각 도메인 이벤트의 이름과 속성 정의
- [ ] 이벤트 발행 시점 정의
- [ ] 이벤트 간 인과 관계 정의

[Question] 어떤 작업들이 도메인 이벤트로 발행되어야 할까요? (예: WidgetCreated, WidgetPublished, WidgetDeleted 등)
[Answer] 4개의 핵심 도메인 이벤트를 발행합니다: (1) **WidgetCreated**: 위젯 생성 완료 시 발행. 통계, 감사 로그, 알림 등 다른 Unit의 구독 필요. (2) **WidgetPublished**: 공개 상태 변경(비공개→공개) 시 발행. US3.4 공개 갤러리 업데이트, 추천 시스템 트리거, 소유자 알림 등에 활용. (3) **WidgetDeleted**: 위젯 삭제(Soft Delete) 시 발행. Dashboard Unit이 이벤트를 구독하여 해당 위젯 참조 제거 (US3.6). (4) **WidgetRestored** (선택): Soft Delete 복구 시 발행. 향후 복구 기능 추가 시 필요. **발행하지 않는 이벤트**: WidgetUpdated는 발행하지 않습니다. US3.2 "즉시 반영"은 참조 기반 조회로 자동 해결되며, 모든 편집마다 이벤트 발행 시 성능 저하 및 불필요한 복잡도 증가합니다. 이벤트는 비즈니스적으로 중요한 상태 변경(생성, 공개, 삭제)에만 사용합니다.

[Question] US3.2 "위젯 편집 시 모든 대시보드에 즉시 반영"은 도메인 이벤트로 처리해야 할까요?
[Answer] 아니오, 도메인 이벤트가 아닙니다. 참조 기반 아키텍처(Reference-based)로 자동 해결됩니다. 이유: (1) Dashboard는 Widget의 데이터 복사본이 아닌 widgetId 참조만 저장하므로, 렌더링 시점에 항상 최신 Widget을 조회하여 자동으로 "즉시 반영"이 구현됨. (2) WidgetUpdated 이벤트 발행 시 문제점: 매 편집마다 이벤트 발행으로 인한 오버헤드, 이벤트 핸들러가 실제로 할 작업 없음 (Dashboard는 이미 참조 사용 중), 불필요한 분산 시스템 복잡도 증가. (3) TanStack Query의 캐시 무효화 전략으로 Frontend 실시간성 보장: `queryClient.invalidateQueries(['widget', widgetId])`를 편집 완료 후 호출하여 클라이언트 캐시 갱신. 이는 Backend 이벤트가 아닌 Frontend 상태관리 영역입니다. "즉시 반영"은 아키텍처 설계로 달성되며, 이벤트는 필요 없습니다.

[Question] US3.6 위젯 삭제 시 "모든 대시보드에서 자동 제거"는 도메인 이벤트 구독자가 처리해야 할까요?
[Answer] 예, WidgetDeleted 도메인 이벤트를 Dashboard Unit이 구독하여 처리합니다. 이유: (1) 위젯 삭제는 Dashboard Aggregate의 상태 변경(위젯 참조 제거)을 트리거하므로 도메인 이벤트가 적합. (2) Widget Unit은 Dashboard의 존재를 몰라야 하며(단방향 의존성), 이벤트를 통한 느슨한 결합(Loose Coupling)이 Clean Architecture 원칙에 부합. (3) Soft Delete 패턴 사용: Widget.delete()는 `deletedAt` 타임스탬프만 설정하고 WidgetDeleted 이벤트 발행. Dashboard Unit의 WidgetDeletedEventHandler가 이벤트를 수신하여 `Dashboard.removeWidget(widgetId)` 호출. (4) 실패 처리: 이벤트 핸들러 실패 시 재시도 메커니즘(Message Queue)으로 eventual consistency 보장. Dashboard에 고아 참조(orphaned reference)가 남아도 렌더링 시 Widget 조회 실패로 안전하게 처리 가능. 이벤트 기반 접근이 확장성과 유지보수성 측면에서 우수합니다.

### 단계 5: 도메인 서비스 식별

- [ ] 여러 애그리게이트에 걸친 비즈니스 로직 식별
- [ ] 엔티티나 값 객체에 속하지 않는 도메인 로직 식별
- [ ] 각 도메인 서비스의 책임 정의
- [ ] 도메인 서비스와 애플리케이션 서비스 구분

[Question] WidgetFactory는 도메인 서비스인가요? 9가지 위젯 타입 생성 로직을 어떻게 구조화해야 할까요?
[Answer] WidgetFactory 도메인 서비스는 필요하지 않습니다. Widget Aggregate의 생성자(constructor)와 정적 팩토리 메서드로 충분합니다. 이유: (1) 위젯 생성 로직은 복잡한 도메인 규칙이 없으며, 단순히 타입별 기본 파라미터를 설정하는 수준입니다. (2) `Widget.create(type, ownerId, initialParams)` 정적 팩토리 메서드 하나로 모든 타입 생성 가능. 타입별 기본값은 `WIDGET_TYPE_DEFAULTS` 상수 객체로 관리. (3) WidgetFactory 도메인 서비스를 만들면 오히려 불필요한 레이어 추가로 복잡도만 증가. DDD 원칙 "엔티티에 로직을 최대한 배치"에 부합. (4) 여러 Aggregate를 조율하거나 복잡한 계산이 필요한 경우가 아니므로 도메인 서비스 불필요. 단순한 객체 생성은 Aggregate 자체 메서드로 처리하는 것이 Clean Architecture와 DDD 모두에 적합합니다.

[Question] US3.3 공개 위젯 복사 로직은 도메인 서비스인가요, 아니면 Widget.copy() 메서드인가요?
[Answer] Widget Aggregate의 인스턴스 메서드 `Widget.copy(newOwnerId)`로 구현합니다. 도메인 서비스가 아닙니다. 이유: (1) 복사 로직은 단일 Widget Aggregate 내부의 행동(behavior)이며, 자기 자신의 상태를 복제하는 것은 엔티티의 자연스러운 책임입니다. (2) 복사본 생성 로직: 새 ID 발급, 파라미터 Deep Clone, 소유자 변경, isPublic=false 초기화, 생성 시각 갱신. 이 모든 것이 Widget 자신의 속성 관련 로직입니다. (3) 도메인 서비스는 "여러 Aggregate를 조율"하거나 "Aggregate에 속하지 않는 도메인 로직"에만 사용. 복사는 단일 Aggregate 작업이므로 해당 없음. (4) Application Service에서 호출: `originalWidget.copy(currentUserId)`로 복사본 Widget 생성 후 `widgetRepository.save(copiedWidget)`. 간결하고 명확합니다. DDD 원칙 "풍부한 도메인 모델(Rich Domain Model)"을 따릅니다.

[Question] 위젯 렌더링(renderWidget)은 도메인 서비스일까요, 아니면 Presentation Layer의 책임일까요?
[Answer] Presentation Layer(React Components)의 책임입니다. 도메인 서비스가 아닙니다. 이유: (1) 렌더링은 "데이터를 어떻게 보여줄까"의 문제로, UI/UX 관심사(Presentation Concern)입니다. 도메인 모델은 "무엇을 표현하는가(What)"만 정의하고, "어떻게 그릴까(How)"는 Presentation Layer가 결정합니다. (2) Clean Architecture의 Dependency Rule: Domain Layer는 Presentation Layer를 알아서는 안 됩니다. 렌더링 로직이 도메인에 들어가면 Recharts, React 등 UI 라이브러리 의존성이 Domain Layer에 침투하여 아키텍처 위반. (3) 구현 방식: Domain Layer는 WidgetParameters 값 객체(Zod Schema)만 정의. Presentation Layer의 `<WidgetRenderer>` React 컴포넌트가 widgetType에 따라 적절한 차트 컴포넌트(`<BarChartWidget>`, `<TimeSeriesWidget>` 등)를 선택하여 렌더링. (4) 테스트 용이성: 도메인 로직은 UI 없이 단위 테스트 가능. 렌더링은 Storybook/Vitest로 별도 테스트. 관심사 분리(Separation of Concerns)가 명확합니다.

### 단계 6: 정책(Policy) 정의

- [ ] 비즈니스 규칙과 제약사항 식별
- [ ] 정책의 트리거 조건 정의
- [ ] 정책의 실행 결과 정의
- [ ] 정책 간 우선순위 정의

[Question] "공개/비공개 상태 토글"은 정책으로 정의해야 할까요? 특별한 공개 조건이 있나요?
[Answer] 정책(Policy)이 아닙니다. Widget Aggregate의 단순 상태 변경 메서드입니다. 이유: (1) US3.4에 공개 조건이나 제약사항이 명시되어 있지 않습니다. 소유자는 언제든지 자유롭게 공개/비공개를 토글할 수 있습니다. (2) `Widget.publish()`와 `Widget.unpublish()` 메서드로 충분. `isPublic` boolean 플래그를 변경하고 WidgetPublished 이벤트 발행. (3) 정책(Policy)은 "특정 조건 하에서 실행되는 복잡한 비즈니스 규칙"을 의미합니다 (예: "Pro 플랜만 공개 가능", "승인된 위젯만 공개", "일일 공개 횟수 제한"). 현재 요구사항에는 그런 규칙이 없습니다. (4) 향후 공개 조건 추가 시 (예: "부적절한 콘텐츠 검토") 그때 PublishingPolicy 도메인 서비스로 승격 가능. 현재는 YAGNI 원칙(You Aren't Gonna Need It)에 따라 단순하게 유지합니다.

[Question] US3.3 "Free 플랜은 대시보드당 위젯 6개 제한"은 Widget 도메인의 정책인가요, Subscription 도메인의 정책인가요?
[Answer] Subscription 도메인의 정책입니다. Widget 도메인은 관여하지 않습니다. 이유: (1) 플랜별 제한은 구독 관리의 핵심 비즈니스 규칙으로, Subscription Bounded Context의 책임입니다. (2) Widget 도메인에서 플랜 검증 시 문제점: Subscription 도메인에 대한 의존성 생성, 단일 책임 원칙(SRP) 위반, 테스트 복잡도 증가. (3) 구현 방식: Dashboard Unit의 Application Service에서 위젯 추가 전에 `SubscriptionService.checkWidgetQuota(userId, dashboardId)`를 호출하여 검증. Subscription Unit이 "Free 플랜 6개, Pro 무제한" 정책을 관리. (4) Widget Unit은 제한 없이 위젯 생성/복사 가능. 제한은 "대시보드에 위젯을 배치하는 시점"에 Dashboard Unit이 Subscription 정책을 확인하여 적용. 각 도메인의 경계와 책임이 명확히 분리됩니다.

[Question] 위젯 삭제 시 "사용 중인 대시보드 확인 및 경고"는 정책으로 구현해야 할까요?
[Answer] 정책이 아닙니다. Application Service의 조회 로직과 Presentation Layer의 확인 다이얼로그로 처리합니다. 이유: (1) "경고"는 사용자 경험(UX) 관심사로, 도메인 규칙이 아닙니다. 삭제를 막는 것이 아니라 단순히 정보를 표시하고 확인받는 것입니다. (2) US3.5 "위젯별 사용 중인 대시보드 수 확인"은 조회 기능입니다. 정책은 "행동을 제어하는 규칙"이지만, 이것은 "정보 표시"입니다. (3) 구현 방식: Application Service의 `WidgetApplicationService.getWidgetUsage(widgetId)` 쿼리 메서드가 Dashboard Unit API를 호출하여 사용 개수를 조회. Presentation Layer가 "이 위젯은 3개 대시보드에서 사용 중입니다. 삭제하시겠습니까?" 다이얼로그 표시. 사용자 승인 후 `Widget.delete()` 실행. (4) 삭제 자체는 항상 허용됩니다 (사용 여부와 무관). 정책이 개입할 비즈니스 규칙이 없습니다. 단순 조회 + UI 확인 흐름입니다.

### 단계 7: 리포지토리 인터페이스 정의

- [ ] 각 애그리게이트별 리포지토리 인터페이스 정의
- [ ] 필요한 조회 메서드 정의
- [ ] 저장/삭제 메서드 정의
- [ ] 트랜잭션 경계 정의

[Question] WidgetRepository는 어떤 조회 메서드가 필요한가요? (getMyWidgets, getPublicWidgets, getWidgetsByType 등)
[Answer] IWidgetRepository는 Aggregate 중심의 기본 CRUD와 필수 쿼리 메서드만 제공합니다: (1) **기본 CRUD**: `save(widget)`, `findById(widgetId)`, `delete(widgetId)` - 표준 Repository 패턴. (2) **소유자별 조회**: `findByOwnerId(ownerId)` - US3.1 "내 위젯 목록" 조회. 가장 빈번한 쿼리. (3) **공개 위젯 조회**: `findPublicWidgets(sortBy, limit, offset)` - US3.7 공개 갤러리. sortBy는 'popular'(복사 횟수), 'latest'(생성일) 등 지원. (4) **타입별 조회**: `findByType(widgetType)` - 선택적. 관리자 통계나 분석용. (5) **존재 확인**: `exists(widgetId)` - 삭제 전 검증 등에 활용. **제공하지 않는 메서드**: 복잡한 검색(제목, 태그, 카테고리)은 초기 버전에 불필요. 향후 필요 시 Elasticsearch 기반 별도 SearchRepository로 분리. Repository는 "Aggregate를 저장/조회하는 컬렉션 추상화"로, 최소한의 인터페이스를 유지하여 구현 변경 시 영향 최소화합니다.

[Question] US3.5 "위젯별 사용 중인 대시보드 수 확인"은 WidgetRepository의 책임인가요, 아니면 Dashboard 도메인을 조회해야 할까요?
[Answer] Dashboard 도메인을 조회해야 합니다. WidgetRepository의 책임이 아닙니다. 이유: (1) "대시보드 수"는 Dashboard Aggregate의 데이터이며, Widget Aggregate는 자신을 어디서 사용하는지 모릅니다 (단방향 참조: Dashboard → Widget). (2) WidgetRepository가 Dashboard 테이블을 조회하면 Repository 경계 위반. Repository는 자신이 관리하는 Aggregate의 테이블만 접근해야 합니다 (Repository per Aggregate 원칙). (3) 구현 방식: Application Service의 `WidgetApplicationService.getWidgetUsage(widgetId)` 메서드가 Dashboard Unit의 API를 호출: `GET /api/dashboards/widgets/{widgetId}/usage`. Dashboard Unit은 자신의 DashboardRepository로 `SELECT COUNT(*) FROM dashboards WHERE widget_ids @> :widgetId` 쿼리 실행. (4) Unit 간 통신은 Application Layer에서 조율. Domain Layer는 다른 Bounded Context를 직접 호출하지 않습니다. 이것이 Clean Architecture의 Dependency Rule과 DDD의 Bounded Context 독립성을 유지하는 방법입니다.

### 단계 8: 도메인 모델 문서 작성

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

### 단계 9: 검증 및 검토

- [ ] 모든 사용자 스토리가 도메인 모델로 구현 가능한지 검증
- [ ] DDD 전술적 패턴이 올바르게 적용되었는지 검토
- [ ] 도메인 모델의 복잡도가 적절한지 평가
- [ ] 피드백 반영 및 최종 승인

## 참고 문서

- `docs/aidlc/inception/units/widget-library.md` - 요구사항 및 사용자 스토리
- `docs/aidlc/inception/units/integration_contract.md` - 단위 간 인터페이스 계약

## 주의사항

- 코드 스니펫을 생성하지 않습니다
- 설계 문서만 작성합니다
- 중요한 결정은 질문을 통해 명확히 합니다
