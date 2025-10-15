# Admin Console Unit - DDD 도메인 모델 설계 계획

## 목표

Admin Console Unit에 대해 도메인 주도 설계(DDD)를 사용하여 도메인 모델을 설계합니다.

## 작업 범위

- **대상 단위**: Admin Console Unit (admin-console.md)
- **포함된 사용자 스토리**: US6.1 ~ US6.8 (8개)
- **산출물**: `docs/aidlc/construction/admin-console/domain_model.md`

## 작업 단계

### 단계 1: 도메인 분석 및 바운디드 컨텍스트 식별

- [x] Admin Console Unit의 8개 사용자 스토리 재검토
- [x] 주요 도메인 개념 추출 및 정리
- [x] 바운디드 컨텍스트 경계 식별
- [x] 유비쿼터스 언어(Ubiquitous Language) 정의

**[Question]** Admin Console Unit 내에서 여러 개의 바운디드 컨텍스트로 분리해야 할까요, 아니면 단일 바운디드 컨텍스트로 관리해야 할까요?

**[Answer]** 단일 바운디드 컨텍스트 "Admin Console"로 관리합니다. 모든 기능이 동일한 도메인 전문가(관리자)에 의해 수행되고, 긴밀한 참조 관계와 공통 유비쿼터스 언어를 공유하며, 이미 Inception 단계에서 독립 단위로 정의되었습니다. 단, 각 관리 기능은 독립적인 Aggregate로 분리합니다.

**[Question]** 지표 관리, 사용자 관리, 템플릿 관리 등 7개의 주요 기능이 서로 독립적인 Aggregate로 분리되어야 할까요?

**[Answer]** 6개의 독립적인 Aggregate로 분리합니다. CustomData는 별도 Aggregate가 아닌 Indicator Aggregate의 내부 엔티티로 포함합니다. CUSTOM 소스 지표 삭제 시 CustomData는 Cascade Delete되며, 삭제 전 강력한 확인 절차와 감사 로그를 통해 안전성을 보장합니다.

**6개 Aggregate:**
1. Indicator Aggregate (CustomDataPoint 내부 엔티티 포함)
2. User Aggregate
3. DataSource Aggregate
4. PlanLimit Aggregate
5. Template Aggregate
6. Category Aggregate

### 단계 2: 애그리게이트 식별 및 경계 정의

- [x] 트랜잭션 일관성이 필요한 경계 식별
- [x] 각 애그리게이트의 루트 엔티티 결정
- [x] 애그리게이트 간 참조 방식 정의 (ID 참조 vs 객체 참조)
- [x] 애그리게이트별 불변 조건(Invariant) 정의

**[Question]** 지표(Indicator)와 카테고리(Category)의 관계는 어떻게 모델링해야 할까요? Category가 별도 Aggregate인가요, 아니면 Value Object인가요?

**[Answer]** Category는 별도 Aggregate Root입니다. CRUD 작업, 순서 변경, 활성화/비활성화 등 독립적인 생명주기를 가지며, 고유 식별자와 변경 가능한 속성(name, order, isActive 등)을 가집니다. Indicator는 Category를 ID(categoryCode)로 참조하여 느슨한 결합을 유지합니다.

**[Question]** 사용자 구독 변경 시 만료일 설정이 있는데, 이것이 별도 Aggregate인가요 아니면 User Aggregate의 일부인가요?

**[Answer]** Subscription은 별도 Unit(Subscription Unit)에서 관리되는 Aggregate입니다. Admin Console의 User Aggregate는 Subscription을 소유하지 않고 userId로만 참조합니다. 관리자의 구독 변경은 Subscription Unit의 서비스를 호출하며, Admin Console은 변경 사유와 만료일을 ActivityLog에 기록하는 역할만 담당합니다. 이를 통해 단일 책임 원칙과 데이터 일관성을 유지합니다.

**[Question]** 수동 데이터(CustomData)와 지표(Indicator)의 관계를 어떻게 모델링해야 할까요? 같은 Aggregate인가요?

**[Answer]** 같은 Aggregate입니다. CustomDataPoint는 Indicator Aggregate의 내부 엔티티로 포함됩니다. CUSTOM 소스 지표와 생명주기를 공유하며, Indicator 삭제 시 Cascade Delete됩니다.

### 단계 3: 엔티티와 값 객체 설계

- [x] 각 애그리게이트 내 엔티티 식별
- [x] 식별자가 필요한 개념(엔티티) vs 속성으로 정의 가능한 개념(값 객체) 구분
- [x] 값 객체의 불변성 및 동등성 정의
- [x] 엔티티의 생명주기 정의

**[Question]** API Key, 변경 사유, 가격 정보 등은 값 객체로 모델링해야 할까요?

**[Answer]** 모두 값 객체로 모델링합니다. EncryptedApiKey(암호화 로직 포함), ChangeReason(검증 로직 포함), Price(금액+통화, 비즈니스 규칙 포함) 각각 불변성을 가지며 식별자가 필요 없고 도메인 로직을 캡슐화합니다.

**[Question]** 지표의 API 파라미터(apiParams)는 어떻게 모델링해야 할까요? 각 소스(KOSIS, ECOS, OECD)마다 다른 구조를 가지는데요?

**[Answer]** `Record<string, any>`로 유연하게 유지하며, Value Object를 도입하지 않습니다.

**이유:**

1. **공식 문서 자동 접근 제약**: KOSIS, ECOS, OECD의 공식 문서는 존재하나 `.do` 확장자(JSP 기반) 및 동적 페이지로 인해 AI-DLC 도구 환경에서 자동 접근 불가. 명확한 필수 파라미터 정의를 위한 자동화된 검증 불가능
2. **외부 API 통제 불가**: 외부 기관이 파라미터 구조를 변경할 경우 타입 정의가 오히려 정상 요청을 차단할 위험
3. **US6.4 요구사항**: "재배포 없이 즉시 대응" - 관리자가 Admin Console에서 파라미터를 자유롭게 조정 가능해야 함
4. **검증 대체 수단**: US6.2 "연결 테스트" 기능으로 실제 API 호출을 통해 유효성 검증

**US6.2 "재탐색 및 갱신" 지원:**

- 외부 API 스펙 변경 시 "연결 테스트" 실패
- 관리자가 "재탐색" 버튼 클릭 → 원본 소스에서 파라미터 자동 추출
- `Indicator.updateApiParams(newParams: Record<string, any>)` 메서드로 업데이트
- 지표 삭제 후 재등록하는 불편함 제거

**도메인 모델:**

```typescript
Indicator Aggregate {
  apiParams: Record<string, any>  // 유연성 우선
  updateApiParams(newParams: Record<string, any>)  // 재탐색 지원
}
```

**타입 안정성 < 유연성** - 실무 요구사항과 외부 API 불확실성을 고려한 실용적 설계

### 단계 4: 도메인 이벤트 정의

- [x] 비즈니스적으로 중요한 상태 변경 식별
- [x] 각 도메인 이벤트의 이름과 속성 정의
- [x] 이벤트 발행 시점 정의
- [x] 이벤트 간 인과 관계 정의

**[Question]** 어떤 작업들이 도메인 이벤트로 발행되어야 할까요? (예: IndicatorCreated, UserSubscriptionChanged, CategoryReordered 등)

**[Answer]**

총 **31개의 도메인 이벤트**를 정의합니다. 각 Aggregate별로 비즈니스적으로 중요한 상태 변경을 이벤트로 발행합니다.

**1. Indicator Aggregate 이벤트 (US6.1, US6.2):**

```typescript
interface IndicatorCreated {
  indicatorId: string
  name: string
  source: 'KOSIS' | 'ECOS' | 'OECD' | 'CUSTOM'
  categoryCode: string
  createdBy: string
  createdAt: Date
}

interface IndicatorUpdated {
  indicatorId: string
  changedFields: {
    name?: { old: string, new: string }
    description?: { old: string, new: string }
    categoryCode?: { old: string, new: string }
  }
  updatedBy: string
  updatedAt: Date
}

interface IndicatorApiParamsUpdated {
  indicatorId: string
  oldParams: Record<string, any>
  newParams: Record<string, any>
  updatedBy: string
  updatedAt: Date
}

interface IndicatorDeleted {
  indicatorId: string
  source: 'KOSIS' | 'ECOS' | 'OECD' | 'CUSTOM'
  deletedBy: string
  deletedAt: Date
}
```

**참고:**
- `IndicatorApiParamsUpdated`는 `IndicatorUpdated`와 별도 이벤트 - "재탐색" 기능의 특별한 비즈니스 프로세스
- `IndicatorConnectionTested`는 도메인 이벤트로 발행하지 않음 - 조회 작업이므로 도메인 상태 변경 없음, Application Event로 처리

**2. User Aggregate 이벤트 (US6.3):**

```typescript
interface UserPlanManuallyChanged {
  userId: string
  oldPlan: 'Free' | 'Pro'
  newPlan: 'Free' | 'Pro'
  reason: string
  expiresAt: Date | null
  changedBy: string
  changedAt: Date
}

interface UserAccountStatusChanged {
  userId: string
  oldStatus: 'active' | 'inactive'
  newStatus: 'active' | 'inactive'
  reason: string
  changedBy: string
  changedAt: Date
}
```

**참고:**
- 실제 Subscription 변경은 Subscription Unit에서 처리
- Admin Console은 변경 요청 및 사유 기록 담당

**3. DataSource Aggregate 이벤트 (US6.4):**

```typescript
interface DataSourceAdded {
  dataSourceId: string
  name: string
  baseUrl: string
  addedBy: string
  addedAt: Date
}

interface DataSourceApiKeyUpdated {
  dataSourceId: string
  updatedBy: string
  updatedAt: Date
  // Note: 암호화된 API Key 값은 보안상 이벤트에 미포함
}

interface DataSourceStatusChanged {
  dataSourceId: string
  oldStatus: 'active' | 'inactive'
  newStatus: 'active' | 'inactive'
  changedBy: string
  changedAt: Date
}
```

**4. PlanLimit Aggregate 이벤트 (US6.5):**

```typescript
interface PlanLimitUpdated {
  planType: 'Free' | 'Pro'
  limitKey: string
  oldValue: number | null  // null이면 신규 항목 추가
  newValue: number
  expiresAt: Date | null
  updatedBy: string
  updatedAt: Date
}

interface PlanPriceUpdated {
  planType: 'Free' | 'Pro'
  oldPrice: number
  newPrice: number
  currency: string
  updatedBy: string
  updatedAt: Date
}
```

**5. Template Aggregate 이벤트 (US6.6):**

```typescript
interface TemplateCreated {
  templateId: string
  name: string
  categoryCode: string
  widgetCount: number
  createdBy: string
  createdAt: Date
}

interface TemplateUpdated {
  templateId: string
  changedFields: {
    name?: { old: string, new: string }
    categoryCode?: { old: string, new: string }
    widgetCount?: { old: number, new: number }
  }
  updatedBy: string
  updatedAt: Date
}

interface TemplateStatusChanged {
  templateId: string
  oldStatus: 'active' | 'inactive'
  newStatus: 'active' | 'inactive'
  changedBy: string
  changedAt: Date
}
```

**6. Category Aggregate 이벤트 (US6.7):**

```typescript
interface CategoryCreated {
  categoryCode: string
  name: string
  type: 'indicator' | 'template'
  createdBy: string
  createdAt: Date
}

interface CategoryUpdated {
  categoryCode: string
  changedFields: {
    name?: { old: string, new: string }
  }
  updatedBy: string
  updatedAt: Date
}

interface CategoryReordered {
  categoryCode: string
  oldOrder: number
  newOrder: number
  reorderedBy: string
  reorderedAt: Date
}

interface CategoryStatusChanged {
  categoryCode: string
  oldStatus: 'active' | 'inactive'
  newStatus: 'active' | 'inactive'
  changedBy: string
  changedAt: Date
}

interface CategoryDeleted {
  categoryCode: string
  deletedBy: string
  deletedAt: Date
}
```

**7. CustomDataPoint 관련 이벤트 (US6.8):**

```typescript
interface CustomDataPointsImported {
  indicatorId: string                    // 상위 Indicator Aggregate Root ID
  importedCount: number                  // 성공적으로 추가된 데이터 개수
  failedCount: number                    // 검증 실패 개수
  dateRange: {                           // 데이터의 시간 범위
    from: Date
    to: Date
  }
  importedBy: string                     // 관리자 ID
  importedAt: Date
}

interface CustomDataPointCreated {
  indicatorId: string                    // 상위 Indicator Aggregate Root ID
  dataPointId: string                    // 데이터 포인트 ID
  date: Date                             // 데이터 시점 (예: 2024-01-01)
  value: number                          // 데이터 값
  createdBy: string                      // 관리자 ID
  createdAt: Date
}

interface CustomDataPointUpdated {
  indicatorId: string                    // 상위 Indicator Aggregate Root ID
  dataPointId: string                    // 데이터 포인트 ID
  date: Date                             // 데이터 시점
  oldValue: number                       // 수정 전 값
  newValue: number                       // 수정 후 값
  updatedBy: string                      // 관리자 ID
  updatedAt: Date
}

interface CustomDataPointDeleted {
  indicatorId: string                    // 상위 Indicator Aggregate Root ID
  dataPointId: string                    // 데이터 포인트 ID
  date: Date                             // 데이터 시점
  deletedValue: number                   // 삭제된 값 (감사 로그용)
  deletedBy: string                      // 관리자 ID
  deletedAt: Date
}
```

**참고:**
- CustomDataPoint는 Indicator Aggregate의 내부 Entity
- 모든 이벤트는 Indicator Aggregate Root가 발행
- CSV 일괄 업로드는 하나의 트랜잭션으로 처리 (`CustomDataPointsImported` 1개 이벤트)

**8. Report Aggregate 이벤트 (US6.9):**

```typescript
interface ReportCreated {
  reportId: string                       // Report Aggregate Root ID
  dashboardId: string                    // 신고된 대시보드 ID
  reportedBy: string                     // 신고자 ID (익명 처리 가능)
  reportReason: 'investment_solicitation' | 'fraud' | 'spam' | 'other'
  reportDescription: string              // 신고 상세 사유
  createdAt: Date
}

interface ReportReviewStarted {
  reportId: string                       // Report Aggregate Root ID
  reviewedBy: string                     // 검토 시작한 관리자 ID
  reviewStartedAt: Date
}

interface ReportResolved {
  reportId: string                       // Report Aggregate Root ID
  dashboardId: string                    // 신고된 대시보드 ID
  dashboardAuthorId: string              // 대시보드 작성자 ID
  resolutionType: 'warning' | 'deletion' | 'suspension' | 'dismissed'
  resolutionReason: string               // 조치 사유 (필수)
  suspensionDuration?: number            // 계정 정지 시간 (시간 단위, suspension인 경우만)
  resolvedBy: string                     // 조치 실행한 관리자 ID
  resolvedAt: Date
}
```

**참고:**
- Dashboard Unit의 `DashboardReported` 이벤트를 구독하여 `ReportCreated` 발행
- `ReportReviewStarted`는 SLA 모니터링용 (비기능 요구사항: 48시간 내 검토)
- `ReportResolved`의 `resolutionType`으로 조치 유형 구분 (4가지 조치를 하나의 이벤트로 통합)

**9. UserViolation Aggregate 이벤트 (US6.10):**

```typescript
interface UserViolationRecorded {
  userId: string                         // 위반 사용자 ID
  reportId: string                       // 원인이 된 신고 ID
  violationType: 'investment_solicitation' | 'fraud' | 'spam' | 'other'
  dashboardId: string                    // 위반 대시보드 ID
  cumulativeViolationCount: number       // 누적 위반 횟수 (1회, 2회, 3회...)
  recordedAt: Date
}

interface UserSanctionApplied {
  userId: string                         // 제재 대상 사용자 ID
  sanctionType: 'warning' | 'temporary_suspension' | 'permanent_ban'
  reason: string                         // 제재 사유
  isAutomatic: boolean                   // 자동 제재 여부 (단계적 제재 시스템)
  appliedBy: string | null               // 수동 제재인 경우 관리자 ID
  expiresAt: Date | null                 // temporary_suspension인 경우 만료 시간
  cumulativeViolationCount: number       // 현재 누적 위반 횟수
  appliedAt: Date
}

interface UserSanctionExpired {
  userId: string                         // 제재 해제 사용자 ID
  expiredSanctionType: 'temporary_suspension'  // 만료된 제재 유형 (현재는 48시간만)
  sanctionAppliedAt: Date                // 제재가 적용된 시간
  expiredAt: Date                        // 만료 시간
}
```

**참고:**
- `UserViolationRecorded`: `ReportResolved` 이벤트 구독 후 위반 이력 추가
- `UserSanctionApplied`: 단계적 제재 시스템 (1회 경고 → 2회 48시간 정지 → 3회 영구 정지)
- `UserSanctionExpired`: 스케줄러가 expiresAt 확인 후 자동 발행
- US6.3의 `UserAccountStatusChanged`와 구분: 위반 이력 기반 제재 vs 일반 계정 관리

**10. ContentDetection 관련 이벤트 (US6.11):**

```typescript
interface DashboardFlagged {
  dashboardId: string                    // 플래깅된 대시보드 ID
  authorId: string                       // 작성자 ID
  riskLevel: 'high' | 'medium' | 'low'   // 위험도
  detectedPatterns: string[]             // 탐지된 키워드 패턴
  riskScore: number                      // 위험도 점수 (0-100)
  detectedAt: Date                       // 탐지 시간
  scanBatchId: string                    // 배치 작업 ID (추적용)
}

interface FlaggedContentReviewed {
  dashboardId: string                    // 검토된 대시보드 ID
  reviewResult: 'false_positive' | 'confirmed_violation'
  reviewNotes: string                    // 검토 의견
  detectedPatterns: string[]             // 원래 탐지된 패턴 (오탐 학습용)
  reportId: string | null                // confirmed_violation인 경우 생성된 Report ID
  reviewedBy: string                     // 관리자 ID
  reviewedAt: Date
}
```

**참고:**
- `DashboardAutoHidden` 이벤트는 불필요 - Dashboard Unit이 `DashboardFlagged(high)` 구독하여 자체 비공개 처리
- `DetectionRuleUpdated`는 도메인 이벤트가 아닌 Application Event로 처리
- `ContentScanExecuted` 배치 완료 이벤트는 Infrastructure Event로 처리

**발행 시점:**

- Aggregate Root의 상태 변경 메서드 내에서 이벤트 생성
- Repository 저장 성공 후 이벤트 발행 (트랜잭션 커밋 후)
- Domain Event는 과거형 명명 (Created, Updated, Deleted 등)

**이벤트 간 인과 관계:**

```
Dashboard Unit: DashboardReported
    ↓ (구독)
Admin Console: ReportCreated → ReportReviewStarted → ReportResolved
    ↓ (구독)
Admin Console: UserViolationRecorded → UserSanctionApplied
    ↓ (구독)
Authentication Unit: 로그인 차단 또는 기능 제한
Dashboard Unit: 대시보드 생성/수정 차단

자동 탐지:
Admin Console: DashboardFlagged(high)
    ↓ (구독)
Dashboard Unit: 대시보드 비공개 처리
    ↓ (오탐 검토)
Admin Console: FlaggedContentReviewed(false_positive) → 대시보드 복원
Admin Console: FlaggedContentReviewed(confirmed_violation) → ReportCreated

단계적 제재:
UserSanctionApplied(temporary_suspension) → 48시간 후 → UserSanctionExpired

플랜 변경:
UserPlanManuallyChanged
    ↓ (구독)
Subscription Unit: SubscriptionUpdated

지표 삭제:
IndicatorDeleted (CUSTOM 소스)
    → CustomDataPoint Cascade Delete (Entity이므로 별도 이벤트 발행 안 함)

카테고리 관리:
CategoryUpdated
    ↓ (구독, 선택 사항)
Data Integration Unit: 카테고리 캐시 무효화
```

**도메인 이벤트 vs Application Event 구분:**

| 구분 | 도메인 이벤트 | Application Event |
|------|--------------|-------------------|
| 목적 | 비즈니스 상태 변경 전파 | 기술적 이벤트, 시스템 모니터링 |
| 예시 | IndicatorCreated, UserSanctionApplied | IndicatorConnectionTested, ContentScanExecuted, DetectionRuleUpdated |
| 발행 위치 | Domain Layer (Aggregate) | Application/Infrastructure Layer |
| 구독자 | 다른 Unit의 Domain Layer | 같은 Unit의 Application Service, 모니터링 시스템 |
| 보장 | 비즈니스 일관성 유지에 중요 | 최선 노력, 실패해도 비즈니스 영향 적음 |

**총 31개 도메인 이벤트 요약:**

- Indicator Aggregate: 4개
- User Aggregate: 2개
- DataSource Aggregate: 3개
- PlanLimit Aggregate: 2개
- Template Aggregate: 3개
- Category Aggregate: 5개
- CustomDataPoint (Indicator 내 Entity): 4개
- Report Aggregate: 3개
- UserViolation Aggregate: 3개
- ContentDetection: 2개

**[Question]** 감사 로그 기록이 도메인 이벤트를 통해 이루어져야 할까요, 아니면 별도 메커니즘으로 처리해야 할까요?

**[Answer]**

### 단계 5: 도메인 서비스 식별

- [x] 여러 애그리게이트에 걸친 비즈니스 로직 식별
- [x] 엔티티나 값 객체에 속하지 않는 도메인 로직 식별
- [x] 각 도메인 서비스의 책임 정의
- [x] 도메인 서비스와 애플리케이션 서비스 구분

**[Question]** 지표 연결 테스트(testIndicatorConnection)는 도메인 서비스일까요, 아니면 인프라 레이어의 책임일까요?

**[Answer]**

**[Question]** 플랜 제한 검증 로직은 어디에 위치해야 할까요? Subscription Unit의 도메인 서비스를 호출해야 할까요?

**[Answer]**

### 단계 6: 정책(Policy) 정의

- [x] 비즈니스 규칙과 제약사항 식별
- [x] 정책의 트리거 조건 정의
- [x] 정책의 실행 결과 정의
- [x] 정책 간 우선순위 정의

**[Question]** "관리자 권한 검증", "민감한 작업 시 재인증" 등의 보안 정책은 도메인 레이어에서 정의해야 할까요?

**[Answer]**

**[Question]** 카테고리 삭제 시 "사용 중인 항목이 있으면 삭제 불가" 같은 정책은 어디에 정의해야 할까요?

**[Answer]**

### 단계 7: 리포지토리 인터페이스 정의

- [x] 각 애그리게이트별 리포지토리 인터페이스 정의
- [x] 필요한 조회 메서드 정의
- [x] 저장/삭제 메서드 정의
- [x] 트랜잭션 경계 정의

**[Question]** 리포지토리는 항상 Aggregate Root 단위로만 정의되어야 할까요? 예를 들어 CustomDataPoint를 직접 조회하는 리포지토리가 필요할까요?

**[Answer]**

**[Question]** 감사 로그 기록이 도메인 이벤트를 통해 이루어져야 할까요, 아니면 별도 메커니즘으로 처리해야 할까요?

**[Answer]**

별도 메커니즘으로 처리합니다. 도메인 이벤트는 보조 수단으로 활용합니다.

**이유:**

1. **감사 로그의 특수성:**
   - 보안 요구사항: "관리자의 모든 작업이 감사 로그로 기록되어야 한다" (admin-console.md:315)
   - 법적 증거 확보: 신고/제재 내역 영구 보존 (US6.9, US6.10)
   - **누락 불가**: 이벤트 구독 실패 시에도 로그는 반드시 기록되어야 함
   - **트랜잭션 일관성**: 비즈니스 작업과 감사 로그는 동일 트랜잭션 내에서 원자적으로 저장되어야 함

2. **도메인 이벤트의 한계:**
   - 비동기 처리: 이벤트 발행 후 구독자 처리 실패 시 로그 누락 가능
   - 보장 문제: 이벤트 버스 장애 시 감사 로그 손실 위험
   - 복잡도 증가: 모든 작업에 대해 이벤트 → 구독자 → 로그 체인 필요

**채택 방식: 횡단 관심사(Cross-Cutting Concern) 패턴**

```typescript
// Application Layer - Use Case Decorator
class AuditLoggingDecorator {
  async execute(useCase: AdminUseCase, context: AdminContext) {
    const startTime = Date.now()

    try {
      const result = await useCase.execute()

      // 성공 로그 - 트랜잭션 내에서 동기적으로 저장
      await activityLogRepository.save({
        userId: context.adminId,
        action: useCase.name,
        status: 'success',
        details: result.summary,
        ipAddress: context.ip,
        userAgent: context.userAgent,
        executionTime: Date.now() - startTime,
        timestamp: new Date()
      })

      return result
    } catch (error) {
      // 실패 로그 - 별도 트랜잭션으로 저장 (롤백되어도 로그는 보존)
      await activityLogRepository.saveIndependent({
        userId: context.adminId,
        action: useCase.name,
        status: 'failed',
        error: error.message,
        ipAddress: context.ip,
        userAgent: context.userAgent,
        executionTime: Date.now() - startTime,
        timestamp: new Date()
      })

      throw error
    }
  }
}
```

**도메인 이벤트는 보조 수단으로 활용:**

- 감사 로그는 Decorator 패턴으로 **보장**
- 도메인 이벤트는 **부가 기능** 트리거용:
  - 알림 발송 (UserWarned 이벤트 → 이메일 발송)
  - 통계 집계 (IndicatorCreated 이벤트 → 사용 통계 업데이트)
  - 다른 Unit 연동 (UserPlanManuallyChanged → Subscription Unit 호출)

**정리:**

| 구분 | 감사 로그 (ActivityLog) | 도메인 이벤트 |
|------|------------------------|--------------|
| 목적 | 법적 증거, 보안 추적 | 비즈니스 상태 전파 |
| 보장 | 필수 (트랜잭션 내 동기) | 최선 노력 (비동기) |
| 처리 | Decorator 패턴 | Event Bus |
| 실패 시 | 작업 자체 실패 | 재시도 또는 무시 |
| 보관 기간 | 영구 (최소 3년) | 필요 시 (통계 집계 후 삭제 가능) |

**결론:** 감사 로그는 별도 메커니즘(Decorator)으로 보장하고, 도메인 이벤트는 비즈니스 이벤트 전파 및 부가 기능 트리거 용도로 활용합니다.

### 단계 5: 도메인 서비스 식별

- [ ] 여러 애그리게이트에 걸친 비즈니스 로직 식별
- [ ] 엔티티나 값 객체에 속하지 않는 도메인 로직 식별
- [ ] 각 도메인 서비스의 책임 정의
- [ ] 도메인 서비스와 애플리케이션 서비스 구분

**[Question]** 지표 연결 테스트(testIndicatorConnection)는 도메인 서비스일까요, 아니면 인프라 레이어의 책임일까요?

**[Answer]**

둘 다입니다. 도메인 서비스가 인터페이스를 정의하고, 인프라 레이어가 구현을 제공합니다.

**도메인 레이어 - Domain Service:**

```typescript
// Domain Layer - Admin Console Unit
interface IIndicatorApiClient {
  testConnection(source: DataSource, apiParams: Record<string, any>): Promise<ConnectionTestResult>
}

class IndicatorConnectionTestService {
  constructor(
    private readonly indicatorRepo: IIndicatorRepository,
    private readonly apiClientFactory: IIndicatorApiClientFactory
  ) {}

  async testIndicatorConnection(indicatorId: string): Promise<ConnectionTestResult> {
    const indicator = await this.indicatorRepo.findById(indicatorId)
    if (!indicator) throw new IndicatorNotFoundError(indicatorId)

    // 도메인 로직: 연결 테스트 수행 및 결과 판단
    const apiClient = this.apiClientFactory.getClient(indicator.source)
    const result = await apiClient.testConnection(indicator.dataSource, indicator.apiParams)

    // 비즈니스 규칙: 응답 시간이 5초 이상이면 경고
    if (result.responseTime > 5000) {
      result.addWarning('Slow response time detected')
    }

    // 도메인 이벤트 발행
    indicator.recordConnectionTest(result)
    await this.indicatorRepo.save(indicator) // IndicatorConnectionTested 이벤트 발행

    return result
  }
}
```

**인프라 레이어 - API Client 구현:**

```typescript
// Infrastructure Layer - Data Integration Unit
class KosisApiClient implements IIndicatorApiClient {
  async testConnection(source: DataSource, apiParams: Record<string, any>): Promise<ConnectionTestResult> {
    const startTime = Date.now()

    try {
      // 실제 KOSIS API 호출
      const response = await axios.get(source.baseUrl, {
        params: apiParams,
        headers: { Authorization: source.decryptedApiKey },
        timeout: 10000
      })

      return {
        success: true,
        responseTime: Date.now() - startTime,
        statusCode: response.status,
        sampleData: response.data.slice(0, 3) // 샘플 데이터 3건
      }
    } catch (error) {
      return {
        success: false,
        responseTime: Date.now() - startTime,
        error: error.message
      }
    }
  }
}

class IndicatorApiClientFactory implements IIndicatorApiClientFactory {
  getClient(source: 'KOSIS' | 'ECOS' | 'OECD' | 'CUSTOM'): IIndicatorApiClient {
    switch (source) {
      case 'KOSIS': return new KosisApiClient()
      case 'ECOS': return new EcosApiClient()
      case 'OECD': return new OecdApiClient()
      case 'CUSTOM': return new CustomDataClient()
    }
  }
}
```

**역할 분담:**

| 레이어 | 책임 | 예시 |
|--------|------|------|
| Domain Service | 비즈니스 로직 및 규칙 정의 | 응답 시간 > 5초 경고, 이벤트 발행 |
| Domain Interface | 외부 의존성 추상화 | IIndicatorApiClient |
| Infrastructure | 실제 외부 API 호출 | HTTP 요청, 에러 처리, 타임아웃 |

**이유:**

- **관심사 분리**: 도메인은 "무엇을 테스트해야 하는가"를 정의, 인프라는 "어떻게 호출하는가"를 구현
- **테스트 용이성**: 도메인 서비스는 Mock API Client로 단위 테스트 가능
- **Clean Architecture**: 도메인이 인프라에 의존하지 않음 (의존성 역전)

**[Question]** 플랜 제한 검증 로직은 어디에 위치해야 할까요? Subscription Unit의 도메인 서비스를 호출해야 할까요?

**[Answer]**

플랜 제한 검증 로직은 **각 기능 Unit의 Application Service**에 위치합니다. Admin Console Unit은 제한 설정만 관리하고, Subscription Unit은 사용자의 현재 플랜 정보만 제공합니다.

**아키텍처:**

```
┌─────────────────────────────────────────────────────────────┐
│ Dashboard Unit - Application Service                        │
│                                                              │
│ class CreateDashboardUseCase {                              │
│   async execute(userId, dashboardData) {                    │
│     // 1. 현재 플랜 조회 (Subscription Unit)                │
│     const subscription = await subscriptionService          │
│       .getCurrentSubscription(userId)                       │
│                                                              │
│     // 2. 플랜 제한 조회 (Admin Console Unit)               │
│     const limits = await planLimitService                   │
│       .getPlanLimits(subscription.planType)                 │
│                                                              │
│     // 3. 현재 사용량 조회 (Dashboard Unit)                 │
│     const currentCount = await dashboardRepo                │
│       .countByUserId(userId)                                │
│                                                              │
│     // 4. 제한 검증 (Dashboard Unit 로컬 로직)              │
│     if (currentCount >= limits.maxDashboards) {             │
│       throw new PlanLimitExceededError(                     │
│         'maxDashboards',                                    │
│         currentCount,                                       │
│         limits.maxDashboards                                │
│       )                                                     │
│     }                                                       │
│                                                              │
│     // 5. 대시보드 생성                                      │
│     return await this.dashboardService.create(...)          │
│   }                                                         │
│ }                                                           │
└─────────────────────────────────────────────────────────────┘
         ▲                           ▲
         │                           │
         ├───────────────────────────┼──────────────┐
         │                           │              │
         ▼                           ▼              ▼
┌──────────────────┐  ┌──────────────────────┐  ┌─────────────────┐
│ Subscription     │  │ Admin Console        │  │ Dashboard       │
│ Unit             │  │ Unit                 │  │ Unit            │
│                  │  │                      │  │                 │
│ getCurrentSub()  │  │ getPlanLimits()      │  │ countByUserId() │
│ → planType: Pro  │  │ → maxDashboards: 50  │  │ → current: 45   │
└──────────────────┘  └──────────────────────┘  └─────────────────┘
```

**각 Unit의 책임:**

| Unit | 제공 기능 | 반환 데이터 |
|------|----------|------------|
| **Subscription Unit** | 사용자의 현재 구독 정보 조회 | `{ userId, planType: 'FREE' \| 'PRO', status, expiresAt }` |
| **Admin Console Unit** | 플랜별 제한 설정 조회 | `{ planType, maxDashboards, maxWidgets, dataRetentionDays, ... }` |
| **Dashboard Unit** | 사용자의 현재 사용량 조회 + 제한 검증 | 사용량 카운트 및 검증 로직 실행 |

**왜 검증 로직이 각 기능 Unit에 있어야 하는가?**

1. **단일 책임 원칙**:
   - Admin Console: 제한 "설정"만 관리
   - Subscription: 구독 "상태"만 관리
   - Dashboard/Widget: 실제 "기능 사용"과 제한 적용

2. **응집도**:
   - 대시보드 생성 로직과 대시보드 수 제한 검증은 함께 있어야 함
   - "대시보드를 생성할 수 있는가?"는 Dashboard Unit의 관심사

3. **변경 용이성**:
   - 플랜 제한 규칙 변경 시 Admin Console만 수정 (새로운 제한 항목 추가)
   - 각 기능 Unit은 자신에게 필요한 제한만 조회하여 적용

**공통 패턴 추출 (선택 사항):**

반복되는 검증 로직이 많다면 공통 헬퍼를 추출할 수 있습니다:

```typescript
// packages/core/src/services/plan-limit-checker.ts
class PlanLimitChecker {
  constructor(
    private readonly subscriptionService: ISubscriptionService,
    private readonly planLimitService: IPlanLimitService
  ) {}

  async checkLimit(
    userId: string,
    limitKey: string,
    currentUsage: number
  ): Promise<void> {
    const subscription = await this.subscriptionService.getCurrentSubscription(userId)
    const limits = await this.planLimitService.getPlanLimits(subscription.planType)
    const maxAllowed = limits[limitKey]

    if (currentUsage >= maxAllowed) {
      throw new PlanLimitExceededError(limitKey, currentUsage, maxAllowed)
    }
  }
}
```

**결론:**

- 검증 로직은 **기능을 수행하는 Unit의 Application Service**에 위치
- Subscription Unit은 현재 플랜 정보만 제공 (도메인 서비스 아님, 단순 조회)
- Admin Console Unit은 플랜 제한 설정만 제공 (도메인 서비스 아님, 단순 조회)
- 실제 검증은 Dashboard Unit, Widget Library Unit 등 각자의 Use Case에서 수행

### 단계 6: 정책(Policy) 정의

- [ ] 비즈니스 규칙과 제약사항 식별
- [ ] 정책의 트리거 조건 정의
- [ ] 정책의 실행 결과 정의
- [ ] 정책 간 우선순위 정의

**[Question]** "관리자 권한 검증", "민감한 작업 시 재인증" 등의 보안 정책은 도메인 레이어에서 정의해야 할까요?

**[Answer]**

**정책의 의도(WHAT)**는 도메인 레이어에서 정의하고, **검증 메커니즘(HOW)**은 Application/Infrastructure 레이어에서 구현합니다.

**도메인 레이어 - 정책 의도 정의:**

```typescript
// Domain Layer - Policy Interface
interface IAdminAuthorizationPolicy {
  // 도메인은 "누가 이 작업을 수행할 수 있는가"를 정의
  canManageIndicators(user: User): boolean
  canManageUsers(user: User): boolean
  canDeleteDashboard(user: User, dashboard: Dashboard): boolean
  requiresReAuthentication(operation: AdminOperation): boolean
}

// Domain Model - Aggregate에서 정책 참조
class Indicator {
  delete(deletedBy: User, authPolicy: IAdminAuthorizationPolicy) {
    // 비즈니스 규칙: 지표 삭제는 관리자만 가능
    if (!authPolicy.canManageIndicators(deletedBy)) {
      throw new UnauthorizedError('Only admins can delete indicators')
    }

    // CUSTOM 소스 지표 삭제 시 강력한 확인 필요 (도메인 규칙)
    if (this.source === 'CUSTOM' && !authPolicy.requiresReAuthentication('DELETE_CUSTOM_INDICATOR')) {
      throw new ReAuthenticationRequiredError('Deleting CUSTOM indicator requires re-authentication')
    }

    this.markAsDeleted()
    // IndicatorDeleted 이벤트 발행
  }
}
```

**Application Layer - 정책 구현:**

```typescript
// Application Layer - Policy Implementation
class SupabaseAdminAuthorizationPolicy implements IAdminAuthorizationPolicy {
  canManageIndicators(user: User): boolean {
    return user.role === 'admin'
  }

  canManageUsers(user: User): boolean {
    return user.role === 'admin'
  }

  canDeleteDashboard(user: User, dashboard: Dashboard): boolean {
    // 관리자는 모든 대시보드 삭제 가능 (신고 대응)
    // 일반 사용자는 자신의 대시보드만 삭제 가능
    return user.role === 'admin' || dashboard.ownerId === user.id
  }

  requiresReAuthentication(operation: AdminOperation): boolean {
    // 민감한 작업 목록 정의
    const sensitiveOperations = [
      'DELETE_CUSTOM_INDICATOR',
      'CHANGE_USER_PLAN',
      'UPDATE_API_KEY',
      'SUSPEND_USER_ACCOUNT'
    ]
    return sensitiveOperations.includes(operation)
  }
}
```

**Infrastructure Layer - 재인증 메커니즘:**

```typescript
// Infrastructure Layer - Re-authentication Check
class SupabaseReAuthenticationService {
  async verifyReAuthentication(userId: string, sessionToken: string): Promise<boolean> {
    // Supabase의 최근 로그인 시간 확인
    const { data: session } = await supabase.auth.getSession()
    const lastSignInAt = new Date(session.user.last_sign_in_at)
    const now = new Date()
    const minutesSinceLogin = (now.getTime() - lastSignInAt.getTime()) / 1000 / 60

    // 5분 이내 로그인만 재인증으로 인정
    return minutesSinceLogin <= 5
  }

  async requestReAuthentication(): Promise<void> {
    // 사용자에게 재로그인 프롬프트 표시
    // Supabase의 passwordless re-authentication 활용
    await supabase.auth.reauthenticate()
  }
}
```

**Use Case에서의 활용:**

```typescript
// Application Layer - Use Case
class DeleteIndicatorUseCase {
  constructor(
    private readonly indicatorRepo: IIndicatorRepository,
    private readonly authPolicy: IAdminAuthorizationPolicy,
    private readonly reAuthService: IReAuthenticationService,
    private readonly currentUser: User
  ) {}

  async execute(indicatorId: string) {
    const indicator = await this.indicatorRepo.findById(indicatorId)

    // 1. 재인증 필요 여부 확인 (Application Layer)
    if (this.authPolicy.requiresReAuthentication('DELETE_CUSTOM_INDICATOR')) {
      const isReAuthenticated = await this.reAuthService.verifyReAuthentication(
        this.currentUser.id,
        this.currentUser.sessionToken
      )

      if (!isReAuthenticated) {
        throw new ReAuthenticationRequiredError('Please re-authenticate to delete this indicator')
      }
    }

    // 2. 도메인 로직 실행 (권한 검증 포함)
    indicator.delete(this.currentUser, this.authPolicy)

    // 3. 저장
    await this.indicatorRepo.save(indicator)
  }
}
```

**레이어별 책임:**

| 레이어 | 책임 | 예시 |
|--------|------|------|
| **Domain** | 정책 의도 정의 (인터페이스) | "지표 삭제는 관리자만", "CUSTOM 지표 삭제는 재인증 필요" |
| **Application** | 정책 구현 | `user.role === 'admin'` 검증, 민감한 작업 목록 관리 |
| **Infrastructure** | 인증 메커니즘 | Supabase 세션 확인, 재로그인 프롬프트 |

**이유:**

1. **관심사 분리**: 도메인은 비즈니스 규칙에 집중, 인증 구현 세부사항과 분리
2. **테스트 용이성**: 도메인 로직은 Mock Policy로 단위 테스트 가능
3. **유연성**: 인증 시스템 변경(Supabase → Auth0) 시 도메인 로직은 불변

**결론:**

- 보안 정책의 **의도와 요구사항**은 도메인 레이어에서 인터페이스로 정의
- 실제 **검증 메커니즘**은 Application/Infrastructure 레이어에서 구현
- 도메인 모델은 정책 인터페이스에만 의존 (의존성 역전 원칙)

**[Question]** 카테고리 삭제 시 "사용 중인 항목이 있으면 삭제 불가" 같은 정책은 어디에 정의해야 할까요?

**[Answer]**

**도메인 레이어 - Domain Service**에서 정의합니다. 이것은 여러 Aggregate를 확인해야 하는 비즈니스 규칙이므로 Domain Service의 전형적인 사례입니다.

**문제 상황:**

- Category Aggregate는 자신이 Indicator나 Dashboard에서 사용 중인지 알 수 없음
- Indicator와 Dashboard는 Category를 ID로만 참조 (느슨한 결합)
- "사용 중인가?"는 여러 Aggregate를 조회해야 하는 비즈니스 규칙

**도메인 레이어 - Domain Service:**

```typescript
// Domain Layer - Domain Service
class CategoryDeletionPolicy {
  constructor(
    private readonly indicatorRepo: IIndicatorRepository,
    private readonly dashboardRepo: IDashboardRepository,
    private readonly templateRepo: ITemplateRepository
  ) {}

  async canDelete(categoryCode: string): Promise<CategoryDeletionResult> {
    // 비즈니스 규칙 검증
    const indicatorsUsingCategory = await this.indicatorRepo.countByCategoryCode(categoryCode)
    const dashboardsUsingCategory = await this.dashboardRepo.countByCategoryCode(categoryCode)
    const templatesUsingCategory = await this.templateRepo.countByCategoryCode(categoryCode)

    const totalUsage = indicatorsUsingCategory + dashboardsUsingCategory + templatesUsingCategory

    if (totalUsage > 0) {
      return {
        allowed: false,
        reason: 'Category is in use',
        details: {
          indicators: indicatorsUsingCategory,
          dashboards: dashboardsUsingCategory,
          templates: templatesUsingCategory
        }
      }
    }

    return { allowed: true }
  }

  // 대안: 사용 중인 항목을 다른 카테고리로 재할당
  async reassignItemsAndDelete(
    categoryCode: string,
    targetCategoryCode: string
  ): Promise<void> {
    // 트랜잭션으로 처리
    await this.indicatorRepo.updateCategoryCode(categoryCode, targetCategoryCode)
    await this.dashboardRepo.updateCategoryCode(categoryCode, targetCategoryCode)
    await this.templateRepo.updateCategoryCode(categoryCode, targetCategoryCode)

    // 재할당 완료 후 삭제 가능
  }
}
```

**Aggregate에서의 활용:**

```typescript
// Domain Model - Category Aggregate
class Category {
  private constructor(
    public readonly code: string,
    public name: string,
    public order: number,
    public isActive: boolean
  ) {}

  // 삭제 시도 (정책은 외부에서 주입)
  async delete(deletionPolicy: CategoryDeletionPolicy) {
    // 도메인 서비스를 통한 비즈니스 규칙 검증
    const result = await deletionPolicy.canDelete(this.code)

    if (!result.allowed) {
      throw new CategoryInUseError(
        `Cannot delete category ${this.code}: ${result.reason}`,
        result.details
      )
    }

    this.markAsDeleted()
    // CategoryDeleted 이벤트 발행
  }
}
```

**Application Layer - Use Case:**

```typescript
// Application Layer - Use Case
class DeleteCategoryUseCase {
  constructor(
    private readonly categoryRepo: ICategoryRepository,
    private readonly deletionPolicy: CategoryDeletionPolicy
  ) {}

  async execute(categoryCode: string, options?: { reassignTo?: string }) {
    const category = await this.categoryRepo.findByCode(categoryCode)
    if (!category) throw new CategoryNotFoundError(categoryCode)

    // 옵션 1: 재할당 후 삭제
    if (options?.reassignTo) {
      await this.deletionPolicy.reassignItemsAndDelete(categoryCode, options.reassignTo)
      await this.categoryRepo.delete(category)
      return { deleted: true, reassigned: true }
    }

    // 옵션 2: 바로 삭제 시도 (정책 검증 포함)
    await category.delete(this.deletionPolicy)
    await this.categoryRepo.delete(category)

    return { deleted: true, reassigned: false }
  }
}
```

**정책 우선순위 (비즈니스 규칙):**

1. **강제 삭제 불가**: 사용 중인 카테고리는 절대 삭제 불가 (데이터 무결성)
2. **재할당 옵션 제공**: 관리자가 대체 카테고리 지정 시 항목 재할당 후 삭제
3. **비활성화 대안**: 삭제 대신 `isActive = false`로 설정하여 신규 사용 방지, 기존 항목 유지

**다른 정책 예시 (동일 패턴 적용):**

```typescript
// 1. 지표 삭제 정책
class IndicatorDeletionPolicy {
  async canDelete(indicatorId: string): Promise<DeletionResult> {
    // 위젯에서 사용 중인지 확인
    const widgetsUsingIndicator = await this.widgetRepo.countByIndicatorId(indicatorId)

    if (widgetsUsingIndicator > 0) {
      return {
        allowed: false,
        reason: 'Indicator is used in widgets',
        affectedWidgets: widgetsUsingIndicator
      }
    }
    return { allowed: true }
  }
}

// 2. 데이터 소스 비활성화 정책
class DataSourceDeactivationPolicy {
  async canDeactivate(dataSourceId: string): Promise<DeactivationResult> {
    // 해당 소스의 활성 지표 개수 확인
    const activeIndicators = await this.indicatorRepo.countByDataSourceAndActive(dataSourceId, true)

    if (activeIndicators > 0) {
      return {
        allowed: false,
        reason: 'Data source has active indicators',
        warning: 'Deactivating will cause data fetch failures'
      }
    }
    return { allowed: true }
  }
}
```

**정리:**

| 정책 유형 | 위치 | 이유 |
|----------|------|------|
| **여러 Aggregate 확인 필요** | Domain Service | Category 삭제 시 Indicator/Dashboard 사용 여부 확인 |
| **단일 Aggregate 내 규칙** | Aggregate 메서드 | Category.reorder() - 순서 중복 방지 |
| **인증/권한 정책** | Application Layer (인터페이스는 Domain) | 관리자 권한 검증 |
| **외부 API 의존** | Infrastructure Layer | KOSIS API 연결 테스트 |

**결론:**

- "사용 중인 항목이 있으면 삭제 불가"는 **Domain Service**에서 정의
- 여러 Repository를 조회하여 비즈니스 규칙 검증
- Aggregate는 Domain Service를 주입받아 정책 적용
- Application Service(Use Case)는 Domain Service를 조율하여 비즈니스 흐름 구현

### 단계 7: 리포지토리 인터페이스 정의

- [ ] 각 애그리게이트별 리포지토리 인터페이스 정의
- [ ] 필요한 조회 메서드 정의
- [ ] 저장/삭제 메서드 정의
- [ ] 트랜잭션 경계 정의

**[Question]** 리포지토리는 항상 Aggregate Root 단위로만 정의되어야 할까요? 예를 들어 CustomDataPoint를 직접 조회하는 리포지토리가 필요할까요?

**[Answer]**

**원칙**: 리포지토리는 Aggregate Root 단위로만 정의합니다. **예외**: 읽기 전용 쿼리 모델은 별도 Query Repository를 허용합니다 (CQRS 패턴).

**Admin Console Unit의 6개 Aggregate와 Repository:**

```typescript
// 1. Indicator Aggregate Root Repository
interface IIndicatorRepository {
  // 저장/삭제 (Aggregate Root 단위)
  save(indicator: Indicator): Promise<void>
  delete(indicator: Indicator): Promise<void>

  // 조회 (Aggregate Root 단위, CustomDataPoint 포함)
  findById(id: string): Promise<Indicator | null>
  findAll(filter?: IndicatorFilter): Promise<Indicator[]>

  // 카운트 (정책 검증용)
  countByCategoryCode(categoryCode: string): Promise<number>
  countByDataSource(dataSourceId: string): Promise<number>
}

// 2. User Aggregate Root Repository
interface IUserRepository {
  save(user: User): Promise<void>
  findById(id: string): Promise<User | null>
  findAll(filter?: UserFilter): Promise<User[]>
  countByPlan(planType: PlanType): Promise<number>
}

// 3. DataSource Aggregate Root Repository
interface IDataSourceRepository {
  save(dataSource: DataSource): Promise<void>
  delete(dataSource: DataSource): Promise<void>
  findById(id: string): Promise<DataSource | null>
  findAll(filter?: { isActive?: boolean }): Promise<DataSource[]>
}

// 4. PlanLimit Aggregate Root Repository
interface IPlanLimitRepository {
  save(planLimit: PlanLimit): Promise<void>
  findByPlanType(planType: PlanType): Promise<PlanLimit | null>
  findAll(): Promise<PlanLimit[]>
}

// 5. Template Aggregate Root Repository
interface ITemplateRepository {
  save(template: Template): Promise<void>
  delete(template: Template): Promise<void>
  findById(id: string): Promise<Template | null>
  findAll(filter?: { isActive?: boolean }): Promise<Template[]>
  countByCategoryCode(categoryCode: string): Promise<number>
}

// 6. Category Aggregate Root Repository
interface ICategoryRepository {
  save(category: Category): Promise<void>
  delete(category: Category): Promise<void>
  findByCode(code: string): Promise<Category | null>
  findAll(filter?: { isActive?: boolean }): Promise<Category[]>
}
```

**CustomDataPoint는 별도 Repository가 없습니다:**

```typescript
// ❌ 잘못된 접근 - CustomDataPoint 전용 Repository
interface ICustomDataPointRepository {
  save(dataPoint: CustomDataPoint): Promise<void>
  findByIndicatorId(indicatorId: string): Promise<CustomDataPoint[]>
}

// ✅ 올바른 접근 - Indicator Aggregate를 통한 접근
class Indicator {
  private customDataPoints: CustomDataPoint[] = []

  addDataPoint(date: Date, value: number, addedBy: string) {
    // 비즈니스 규칙: CUSTOM 소스만 데이터 포인트 추가 가능
    if (this.source !== 'CUSTOM') {
      throw new InvalidOperationError('Only CUSTOM indicators can have manual data points')
    }

    // 중복 날짜 체크
    if (this.customDataPoints.some(p => p.date.getTime() === date.getTime())) {
      throw new DuplicateDateError(`Data point for ${date} already exists`)
    }

    this.customDataPoints.push(new CustomDataPoint(date, value, addedBy))
    // CustomDataPointCreated 이벤트 발행
  }

  updateDataPoint(date: Date, newValue: number, updatedBy: string) {
    const dataPoint = this.customDataPoints.find(p => p.date.getTime() === date.getTime())
    if (!dataPoint) throw new DataPointNotFoundError(date)

    dataPoint.update(newValue, updatedBy)
    // CustomDataPointUpdated 이벤트 발행
  }

  deleteDataPoint(date: Date, deletedBy: string) {
    const index = this.customDataPoints.findIndex(p => p.date.getTime() === date.getTime())
    if (index === -1) throw new DataPointNotFoundError(date)

    this.customDataPoints.splice(index, 1)
    // CustomDataPointDeleted 이벤트 발행
  }

  getDataPoints(startDate?: Date, endDate?: Date): CustomDataPoint[] {
    if (!startDate && !endDate) return this.customDataPoints

    return this.customDataPoints.filter(p =>
      (!startDate || p.date >= startDate) &&
      (!endDate || p.date <= endDate)
    )
  }
}

// Use Case에서의 사용
class UpdateCustomDataPointUseCase {
  constructor(private readonly indicatorRepo: IIndicatorRepository) {}

  async execute(indicatorId: string, date: Date, newValue: number, updatedBy: string) {
    // Aggregate Root를 통해 접근
    const indicator = await this.indicatorRepo.findById(indicatorId)
    if (!indicator) throw new IndicatorNotFoundError(indicatorId)

    // Aggregate가 비즈니스 규칙 적용
    indicator.updateDataPoint(date, newValue, updatedBy)

    // Aggregate Root 저장 (CustomDataPoint도 함께 저장됨)
    await this.indicatorRepo.save(indicator)
  }
}
```

**예외: 읽기 전용 Query Repository (CQRS 패턴)**

복잡한 조회나 성능 최적화가 필요한 경우, 읽기 전용 Query Repository를 별도로 정의할 수 있습니다:

```typescript
// 읽기 전용 - Query Model (DTO)
interface CustomDataPointQueryModel {
  indicatorId: string
  indicatorName: string
  date: Date
  value: number
  addedBy: string
  addedAt: Date
  updatedBy?: string
  updatedAt?: Date
}

// 읽기 전용 Query Repository
interface ICustomDataPointQueryRepository {
  // 복잡한 조회 (JOIN, 집계 등)
  findByDateRange(
    indicatorId: string,
    startDate: Date,
    endDate: Date
  ): Promise<CustomDataPointQueryModel[]>

  // 페이징 조회
  findByIndicatorIdPaginated(
    indicatorId: string,
    page: number,
    pageSize: number
  ): Promise<{ items: CustomDataPointQueryModel[], total: number }>

  // 통계 조회
  getStatistics(indicatorId: string): Promise<{
    count: number
    minValue: number
    maxValue: number
    avgValue: number
    latestDate: Date
  }>
}

// Application Layer - 읽기 전용 Use Case
class GetCustomDataPointsUseCase {
  constructor(
    private readonly queryRepo: ICustomDataPointQueryRepository // 읽기 전용
  ) {}

  async execute(indicatorId: string, startDate: Date, endDate: Date) {
    // 읽기 전용 쿼리는 Query Repository 사용
    return await this.queryRepo.findByDateRange(indicatorId, startDate, endDate)
  }
}
```

**Admin Console Unit 전체 Repository 정의:**

```typescript
// Domain Layer - Repository Interfaces
export interface IIndicatorRepository {
  save(indicator: Indicator): Promise<void>
  delete(indicator: Indicator): Promise<void>
  findById(id: string): Promise<Indicator | null>
  findBySource(source: DataSourceType): Promise<Indicator[]>
  findAll(filter?: IndicatorFilter): Promise<Indicator[]>
  countByCategoryCode(categoryCode: string): Promise<number>
  countByDataSource(dataSourceId: string): Promise<number>
}

export interface IUserRepository {
  save(user: User): Promise<void>
  findById(id: string): Promise<User | null>
  findByEmail(email: string): Promise<User | null>
  findAll(filter?: UserFilter): Promise<User[]>
  countByPlan(planType: PlanType): Promise<number>
}

export interface IDataSourceRepository {
  save(dataSource: DataSource): Promise<void>
  delete(dataSource: DataSource): Promise<void>
  findById(id: string): Promise<DataSource | null>
  findByName(name: string): Promise<DataSource | null>
  findAll(filter?: { isActive?: boolean }): Promise<DataSource[]>
}

export interface IPlanLimitRepository {
  save(planLimit: PlanLimit): Promise<void>
  findByPlanType(planType: PlanType): Promise<PlanLimit | null>
  findAll(): Promise<PlanLimit[]>
  findHistoryByPlanType(planType: PlanType): Promise<PlanLimit[]> // 변경 이력
}

export interface ITemplateRepository {
  save(template: Template): Promise<void>
  delete(template: Template): Promise<void>
  findById(id: string): Promise<Template | null>
  findAll(filter?: TemplateFilter): Promise<Template[]>
  countByCategoryCode(categoryCode: string): Promise<number>
}

export interface ICategoryRepository {
  save(category: Category): Promise<void>
  delete(category: Category): Promise<void>
  findByCode(code: string): Promise<Category | null>
  findAll(filter?: CategoryFilter): Promise<Category[]>
  findMaxOrder(type: CategoryType): Promise<number> // 순서 관리용
}

// 감사 로그 전용 Repository (Decorator에서 사용)
export interface IActivityLogRepository {
  save(log: ActivityLog): Promise<void>
  saveIndependent(log: ActivityLog): Promise<void> // 별도 트랜잭션
  findByUserId(userId: string, limit?: number): Promise<ActivityLog[]>
  findByDateRange(startDate: Date, endDate: Date): Promise<ActivityLog[]>
}
```

**트랜잭션 경계:**

```typescript
// Application Layer - Unit of Work 패턴
interface IUnitOfWork {
  begin(): Promise<void>
  commit(): Promise<void>
  rollback(): Promise<void>

  // Repository 접근
  indicators: IIndicatorRepository
  users: IUserRepository
  dataSources: IDataSourceRepository
  planLimits: IPlanLimitRepository
  templates: ITemplateRepository
  categories: ICategoryRepository
  activityLogs: IActivityLogRepository
}

// Use Case에서의 사용
class BulkImportCustomDataUseCase {
  constructor(private readonly uow: IUnitOfWork) {}

  async execute(indicatorId: string, dataPoints: { date: Date, value: number }[]) {
    await this.uow.begin()

    try {
      const indicator = await this.uow.indicators.findById(indicatorId)
      if (!indicator) throw new IndicatorNotFoundError(indicatorId)

      // Aggregate를 통해 일괄 추가
      dataPoints.forEach(({ date, value }) => {
        indicator.addDataPoint(date, value, currentUser.id)
      })

      // Aggregate Root 저장 (모든 CustomDataPoint 함께 저장)
      await this.uow.indicators.save(indicator)

      // 감사 로그 기록 (같은 트랜잭션)
      await this.uow.activityLogs.save({
        userId: currentUser.id,
        action: 'BULK_IMPORT_CUSTOM_DATA',
        details: { indicatorId, count: dataPoints.length }
      })

      await this.uow.commit()
    } catch (error) {
      await this.uow.rollback()
      throw error
    }
  }
}
```

**정리:**

| 구분 | 정의 여부 | 이유 |
|------|----------|------|
| **Aggregate Root (6개)** | ✅ Repository 정의 | Indicator, User, DataSource, PlanLimit, Template, Category |
| **내부 엔티티 (CustomDataPoint)** | ❌ Repository 없음 | Aggregate Root를 통해서만 접근 |
| **읽기 전용 Query (선택)** | ✅ Query Repository 가능 | 복잡한 조회, 성능 최적화 필요 시 |
| **감사 로그 (ActivityLog)** | ✅ Repository 정의 | 횡단 관심사, 모든 Use Case에서 사용 |

**결론:**

- 리포지토리는 **Aggregate Root 단위로만** 정의
- CustomDataPoint는 별도 Repository 없이 **Indicator를 통해 접근**
- 복잡한 읽기 쿼리는 **Query Repository** 별도 정의 가능 (CQRS)
- 트랜잭션 경계는 **Unit of Work** 패턴으로 관리

### 단계 8: 도메인 모델 문서 작성

- [x] domain_model.md 파일 생성
- [x] 식별된 모든 전술적 패턴 문서화
  - [x] 애그리게이트 다이어그램
  - [x] 엔티티 정의
  - [x] 값 객체 정의
  - [x] 도메인 이벤트 목록
  - [x] 도메인 서비스 정의
  - [x] 정책 정의
  - [x] 리포지토리 인터페이스
- [x] 각 요소 간 관계 및 상호작용 설명
- [x] 비즈니스 규칙 및 제약사항 명시

### 단계 9: 검증 및 검토

- [x] 모든 사용자 스토리가 도메인 모델로 구현 가능한지 검증
- [x] DDD 전술적 패턴이 올바르게 적용되었는지 검토
- [x] 도메인 모델의 복잡도가 적절한지 평가
- [ ] 피드백 반영 및 최종 승인

## 참고 문서

- `docs/aidlc/inception/units/admin-console.md` - 요구사항 및 사용자 스토리
- `docs/aidlc/inception/units/integration_contract.md` - 단위 간 인터페이스 계약

## 주의사항

- 코드 스니펫을 생성하지 않습니다
- 설계 문서만 작성합니다
- 중요한 결정은 질문을 통해 명확히 합니다

---

# 논리적 설계 (Logical Design)

## 목표

도메인 모델을 기반으로 실제 소프트웨어 구현을 위한 논리적 설계를 생성합니다.

## 작업 범위

- **입력 문서**:
  - `docs/aidlc/construction/admin-console/domain_model.md` (도메인 모델)
  - `docs/aidlc/inception/units/integration_contract.md` (통합 계약)
- **산출물**: `docs/aidlc/construction/admin-console/logical_design.md`
- **범위**: Admin Console Unit의 완전한 논리적 설계

## 작업 단계

### 단계 1: 시스템 아키텍처 개요

- [ ] Clean Architecture 레이어 정의
- [ ] Event-Driven 아키텍처 패턴 적용
- [ ] Next.js 15 + Supabase 기술 스택 매핑
- [ ] Micro Frontend 구조 내 Admin Console 위치 정의

**[Question 1-1]** Admin Console은 독립 Next.js 애플리케이션인가요, 아니면 Monorepo 내 package인가요?
- 참고: 현재 `apps/admin/`과 `apps/web/`이 모두 존재하며, Phase 1에서 `apps/admin/` 기본 구조를 생성했습니다.
- 선택지: (a) 독립 Next.js 앱 (apps/admin/), (b) Monorepo 내 패키지 (packages/admin-console/)

**[Answer]** (a) 독립 Next.js 앱 (`apps/admin/`)

**결정 근거:**
- Micro Frontend Architecture 원칙 준수
- 보안 격리 (관리자 기능을 완전히 분리된 앱으로 운영)
- 독립 배포 가능 (Admin Console과 User Dashboard의 릴리스 주기 분리)
- Phase 1에서 이미 생성한 apps/admin/ 구조 활용
- packages/를 통한 코드 공유로 중복 최소화

**[Question 1-2]** Supabase는 어떤 역할을 담당하나요?
- 선택지:
  - 인증 (Supabase Auth)
  - 데이터베이스 (PostgreSQL)
  - Storage (파일 저장)
  - Realtime (실시간 구독)
  - Edge Functions (서버리스)
- 참고: 현재 `apps/admin/.env.local`에 Supabase 설정이 있습니다.

**[Answer]**

### 단계 2: 레이어 구조 및 디렉토리 설계

- [ ] Domain Layer 디렉토리 구조
- [ ] Application Layer 디렉토리 구조
- [ ] Infrastructure Layer 디렉토리 구조
- [ ] Presentation Layer (Next.js Pages/Components) 구조
- [ ] 공유 패키지 구조 (packages/)

**[Question 2-1]** packages/ 디렉토리는 어떻게 구성되나요?
- 참고: 현재 `packages/core/`, `packages/ui/`, `packages/dashboard/` 등이 존재합니다.
- 선택지:
  - (a) packages/core: 공통 타입, 유틸리티, 상수
  - (b) packages/ui: 공유 UI 컴포넌트
  - (c) packages/query: 데이터 페칭 레이어 (React Query)
  - (d) packages/data-sources: 외부 API 클라이언트 (KOSIS, ECOS, OECD)
  - (e) 기타 구조
- 질문: Admin Console이 공유 패키지를 어떻게 활용할지 명확히 해주세요.

**[Answer]**

**[Question 2-2]** Admin Console의 Domain Layer는 별도 패키지인가요, 아니면 apps/admin 내부 디렉토리인가요?
- 참고: DDD에서 Domain Layer는 독립적이고 재사용 가능한 비즈니스 로직입니다.
- 선택지:
  - (a) `packages/admin-domain/`: 별도 패키지로 분리 (다른 앱에서도 참조 가능)
  - (b) `apps/admin/src/domain/`: apps/admin 내부 디렉토리 (Admin Console 전용)
- 질문: 다른 Unit(예: Dashboard Unit)이 Admin Console의 Domain Layer를 참조할 필요가 있나요?

**[Answer]**

### 단계 3: API 설계 (Next.js API Routes)

- [ ] REST API Endpoint 정의 (integration_contract 기반)
- [ ] Request/Response 스키마 정의
- [ ] 인증 및 권한 미들웨어 설계
- [ ] 에러 응답 표준 정의
- [ ] API 버전 관리 전략

**[Question 3-1]** API Routes는 `/api/admin/*` 패턴을 사용하나요?
- 참고: Next.js App Router에서는 `app/api/` 디렉토리를 사용합니다.
- 선택지:
  - (a) `/api/admin/indicators`, `/api/admin/users` 등 (관리자 전용 경로)
  - (b) `/api/indicators`, `/api/users` 등 (일반 경로, 권한으로만 구분)
  - (c) 별도 서브도메인 `admin.example.com/api/`
- 질문: User Dashboard(`apps/web`)의 API와 어떻게 구분할 계획인가요?

**[Answer]**

**[Question 3-2]** RESTful API 설계 시 리소스 중심인가요, 아니면 Use Case 중심인가요?
- 참고: integration_contract.md에 정의된 인터페이스를 고려해주세요.
- 선택지:
  - (a) 리소스 중심: `POST /api/admin/indicators`, `PUT /api/admin/indicators/:id`
  - (b) Use Case 중심: `POST /api/admin/indicators/test-connection`, `POST /api/admin/indicators/:id/re-explore`
  - (c) 하이브리드: CRUD는 리소스 중심, 특수 작업은 Use Case 중심
- 질문: US6.2 "재탐색 및 갱신", US6.9 "신고 처리" 같은 특수 작업을 어떻게 표현할 계획인가요?

**[Answer]**

### 단계 4: EventBus 및 도메인 이벤트 설계

- [ ] EventBus 구현 방식 선택 (In-Memory, Redis, Message Queue)
- [ ] 도메인 이벤트 발행 메커니즘
- [ ] 이벤트 구독 및 핸들러 패턴
- [ ] Unit 간 이벤트 통신 설계
- [ ] 이벤트 실패 및 재시도 전략

**[Question 4-1]** EventBus는 어떻게 구현하나요?
- 참고: domain_model.md에서 31개의 도메인 이벤트를 정의했습니다.
- 선택지:
  - (a) In-Memory EventEmitter (Node.js 내장): 단순하고 빠르지만, 서버 재시작 시 유실
  - (b) Redis Pub/Sub: 분산 환경 지원, 영속성 제한적
  - (c) 외부 Message Queue (RabbitMQ, AWS SQS): 높은 신뢰성, 복잡도 증가
  - (d) Supabase Realtime: Supabase 인프라 활용
- 질문: 이벤트 유실이 비즈니스에 미치는 영향은 어느 정도인가요? (예: `IndicatorCreated` 유실 시 통계만 누락 vs 중요 데이터 손실)

**[Answer]**

**[Question 4-2]** Unit 간 이벤트 통신은 동기인가요 비동기인가요?
- 참고: Admin Console이 `UserPlanManuallyChanged` 이벤트를 발행하면, Subscription Unit이 구독합니다.
- 선택지:
  - (a) 동기: 이벤트 처리가 완료될 때까지 대기 (트랜잭션 일관성 보장)
  - (b) 비동기: 이벤트 발행 후 즉시 반환 (성능 우수, 일관성 약함)
  - (c) 하이브리드: 중요 이벤트는 동기, 알림 등은 비동기
- 질문: 관리자가 플랜 변경 후 "성공" 메시지를 보기 전에, Subscription Unit의 업데이트가 완료되어야 하나요?

**[Answer]**

### 단계 5: Supabase 데이터 모델 및 스키마

- [ ] 9개 Aggregate를 위한 테이블 스키마 설계
- [ ] 외래 키 및 제약 조건 정의
- [ ] 인덱스 전략
- [ ] RLS (Row Level Security) 정책 설계
- [ ] 마이그레이션 전략

**[Question 5-1]** CustomDataPoint는 별도 테이블인가요, 아니면 JSONB 필드인가요?
- 참고: domain_model.md에서 CustomDataPoint는 Indicator Aggregate의 내부 엔티티로 정의했습니다.
- 선택지:
  - (a) 별도 테이블 `custom_data_points`: Indicator와 1:N 관계 (정규화, 쿼리 용이)
  - (b) JSONB 필드 `indicators.custom_data: jsonb[]`: 단일 테이블로 관리 (성능, Aggregate 일관성)
- 질문: US6.8 CSV 업로드 시 수천 개의 데이터 포인트를 저장할 수 있습니다. 쿼리 성능과 트랜잭션 일관성 중 어느 것이 더 중요한가요?

**[Answer]**

**[Question 5-2]** ActivityLog는 어디에 저장하나요?
- 참고: domain_model.md에서 AuditLoggingDecorator 패턴으로 모든 관리자 작업을 로깅하기로 결정했습니다.
- 선택지:
  - (a) Supabase 테이블 `activity_logs`: 다른 데이터와 함께 관리, 복잡한 쿼리 가능
  - (b) 별도 로그 시스템 (Elasticsearch, CloudWatch Logs): 대용량 로그 처리, 검색 최적화
  - (c) 하이브리드: 최근 3개월은 Supabase, 이전 데이터는 아카이브
- 질문: 보안 요구사항에 "영구 보관"이 명시되어 있습니다 (admin-console.md:315). 예상 로그 량은 얼마나 되나요?

**[Answer]**

**[Question 5-3]** Supabase RLS로 관리자 권한을 제어하나요, 아니면 Application Layer에서만 제어하나요?
- 참고: 보안 요구사항에 "관리자 역할이 인증 시 검증되어야 한다"고 명시되어 있습니다.
- 선택지:
  - (a) RLS만 사용: DB 레벨 보안, SQL Injection 방어, 복잡한 정책 관리 어려움
  - (b) Application Layer만 사용: 유연한 로직, RLS 미적용 시 보안 취약
  - (c) 둘 다 사용: 심층 방어(Defense in Depth), 중복 관리
- 질문: Admin Console은 관리자만 접근하는데, RLS를 추가로 적용할 필요가 있나요?

**[Answer]**

### 단계 6: 보안 설계

- [ ] 인증 흐름 (Supabase Auth)
- [ ] 관리자 권한 검증 전략
- [ ] 재인증 메커니즘 설계
- [ ] API Key 암호화 및 저장 방식
- [ ] CSRF, XSS 방어 전략
- [ ] Rate Limiting 및 DDoS 방어

**[Question 6-1]** 재인증은 어떻게 구현하나요?
- 참고: 보안 요구사항에 "민감한 작업 수행 시 재인증이 요구되어야 한다"고 명시되어 있습니다 (admin-console.md:316).
- 민감한 작업 예시: CUSTOM 지표 삭제, API Key 변경, 사용자 계정 정지
- 선택지:
  - (a) Supabase 내장 기능: `supabase.auth.reauthenticate()` 사용 (간단, 제한적)
  - (b) 세션 만료 시간 확인: 최근 로그인이 5분 이내인지 검증 (중간)
  - (c) 별도 재인증 플로우: 비밀번호 재입력 또는 OTP 요구 (강력, 복잡)
- 질문: 얼마나 자주 재인증을 요구할 계획인가요? (매 작업마다 vs 세션당 1회)

**[Answer]**

**[Question 6-2]** API Key 암호화는 어떤 알고리즘을 사용하나요?
- 참고: US6.4에서 DataSource의 API Key를 암호화 저장하고, 토글 방식으로 표시/숨김합니다.
- 선택지:
  - (a) AES-256-GCM (대칭키): 복호화 가능, 키 관리 중요
  - (b) RSA (비대칭키): 공개키로 암호화, 개인키로 복호화
  - (c) Supabase Vault: Supabase의 비밀 관리 기능 활용
- 질문: 암호화 키는 어디에 저장할 계획인가요? (환경 변수, AWS Secrets Manager, Supabase Vault)

**[Answer]**

### 단계 7: Unit 간 통합 설계

- [ ] integration_contract.md 기반 인터페이스 구현 방식
- [ ] Unit 간 직접 호출 vs 이벤트 통신 구분
- [ ] 순환 의존성 방지 전략
- [ ] Mock 구현체 제공 전략
- [ ] 계약 테스트 설계

**[Question 7-1]** Dashboard Unit이 Admin Console의 `getTemplates()`를 호출할 때, 어떻게 통신하나요?
- 참고: integration_contract.md에서 Admin Console이 `IAdminTemplateService.getTemplates()`를 제공한다고 정의되어 있습니다.
- 선택지:
  - (a) HTTP API: `GET /api/admin/templates` (독립 배포, 네트워크 오버헤드)
  - (b) 직접 import: `import { getTemplates } from '@repo/admin-console'` (타입 안전, 강한 결합)
  - (c) 하이브리드: 같은 프로세스면 직접 호출, 다른 프로세스면 HTTP
- 질문: Admin Console과 User Dashboard가 같은 서버에 배포되나요, 아니면 독립 배포되나요?

**[Answer]**

**[Question 7-2]** Subscription Unit의 `getPlanLimits()`는 Admin Console의 데이터를 어떻게 가져오나요?
- 참고: domain_model.md에서 플랜 제한 검증 로직은 각 기능 Unit에서 수행한다고 결정했습니다.
- 선택지:
  - (a) 동기 API 호출: `const limits = await adminConsoleService.getPlanLimits('Pro')`
  - (b) 캐싱된 데이터: Admin Console이 플랜 제한을 Redis/메모리에 캐싱, 다른 Unit이 읽기
  - (c) 데이터베이스 직접 조회: 각 Unit이 `plan_limits` 테이블을 직접 조회 (의존성 제거, 일관성 문제)
- 질문: 플랜 제한은 자주 변경되나요? (일 1회 vs 월 1회)

**[Answer]**

### 단계 8: 에러 처리 전략

- [ ] Domain Error 정의
- [ ] Application Error 정의
- [ ] HTTP Error 매핑 전략
- [ ] 에러 로깅 및 모니터링
- [ ] 사용자 친화적 에러 메시지

**[Question 8-1]** 도메인 에러를 HTTP Status Code로 어떻게 매핑하나요?
- 참고: domain_model.md에서 다양한 도메인 에러를 정의했습니다 (예: `IndicatorNotFoundError`, `CategoryInUseError`, `UnauthorizedError`).
- 선택지:
  - (a) 표준 매핑: NotFoundError → 404, UnauthorizedError → 401, InvalidOperationError → 400
  - (b) 커스텀 에러 코드: 도메인 에러마다 고유 코드 부여 (예: `E_INDICATOR_NOT_FOUND: 1001`)
  - (c) 하이브리드: HTTP Status + 상세 에러 코드
- 예시:
  ```json
  {
    "error": {
      "code": "INDICATOR_NOT_FOUND",
      "message": "지표를 찾을 수 없습니다.",
      "statusCode": 404,
      "details": { "indicatorId": "abc123" }
    }
  }
  ```
- 질문: 프론트엔드가 에러 코드를 활용하여 i18n 메시지를 표시할 계획인가요?

**[Answer]**

### 단계 9: 성능 및 확장성

- [ ] 캐싱 전략 (Redis, In-Memory, CDN)
- [ ] 데이터베이스 쿼리 최적화
- [ ] Lazy Loading 및 Pagination
- [ ] 배치 작업 설계 (자동 탐지 스캔, 제재 만료)
- [ ] 모니터링 및 알림 설계

**[Question 9-1]** 플랜 제한 설정은 캐싱하나요?
- 참고: PlanLimit는 자주 조회되지만 거의 변경되지 않는 데이터입니다.
- 선택지:
  - (a) Redis 캐싱: 분산 환경 지원, TTL 관리, 별도 인프라
  - (b) In-Memory 캐싱: 단순하고 빠름, 서버 재시작 시 캐시 손실, 분산 환경 문제
  - (c) 캐싱 없음: 매번 DB 조회, 부하 증가
- 질문: Admin Console이 플랜 제한을 변경하면, 실시간으로 다른 서비스에 반영되어야 하나요? (예: 즉시 vs 최대 5분 지연)

**[Answer]**

**[Question 9-2]** 배치 작업은 어떻게 스케줄링하나요?
- 참고: US6.11 자동 탐지 스캔(매일), US6.10 제재 만료 확인(시간마다) 등의 배치 작업이 필요합니다.
- 선택지:
  - (a) node-cron (서버 내장): 간단, 서버 재시작 시 스케줄 재설정, 단일 서버만 실행
  - (b) Supabase Edge Functions + pg_cron: Supabase 인프라 활용, PostgreSQL 트리거
  - (c) 별도 Worker 서비스: 전용 스케줄러 (Bull, Agenda), 독립 배포, 복잡도 증가
- 질문: 배치 작업 실패 시 알림이 필요한가요? (예: Slack, 이메일)

**[Answer]**

### 단계 10: 배포 아키텍처

- [ ] Vercel/Self-Hosted 배포 전략
- [ ] 환경 변수 관리
- [ ] CI/CD 파이프라인 설계
- [ ] Blue-Green 또는 Rolling 배포
- [ ] 모니터링 및 로깅 인프라

**[Question 10-1]** Admin Console은 독립 배포되나요, 아니면 전체 Monorepo와 함께 배포되나요?
- 참고: Micro Frontend Architecture에서 Admin Console(`apps/admin`)과 User Dashboard(`apps/web`)는 독립 Next.js 앱입니다.
- 선택지:
  - (a) 독립 배포: 각 앱을 별도 Vercel 프로젝트로 배포 (독립 릴리스, 별도 도메인)
  - (b) Monorepo 일괄 배포: 모든 앱을 함께 배포 (일관성, 의존성 관리 쉬움)
  - (c) 선택적 배포: 변경된 앱만 배포 (Turborepo 등)
- 질문: Admin Console과 User Dashboard의 릴리스 주기가 다른가요? (예: Admin은 주 1회, User는 일 1회)

**[Answer]**

**[Question 10-2]** Staging/Production 환경은 어떻게 분리하나요?
- 참고: 보안 요구사항을 고려하여 환경별 Supabase 프로젝트와 DB가 필요합니다.
- 선택지:
  - (a) 브랜치 기반: `main` → Production, `develop` → Staging
  - (b) Vercel Preview: PR마다 미리보기 환경 생성
  - (c) 별도 Supabase 프로젝트: Production/Staging/Development 각각 독립 DB
- 질문: Staging 환경에서 Production 데이터의 익명화된 복제본을 사용할 계획인가요?

**[Answer]**

### 단계 11: 논리적 설계 문서 작성

- [ ] logical_design.md 파일 생성
- [ ] 모든 설계 결정사항 문서화
  - [ ] 아키텍처 다이어그램
  - [ ] API 명세서
  - [ ] 데이터베이스 스키마
  - [ ] 이벤트 흐름도
  - [ ] 보안 설계
  - [ ] 배포 아키텍처
- [ ] Implementation Phase를 위한 가이드라인 작성

## 검증 및 승인

- [ ] 도메인 모델과의 일관성 검증
- [ ] integration_contract와의 호환성 검증
- [ ] 기술적 실현 가능성 검증
- [ ] 사용자 검토 및 승인

## 참고 문서

- `docs/aidlc/construction/admin-console/domain_model.md` - 도메인 모델 설계
- `docs/aidlc/inception/units/admin-console.md` - 요구사항 및 사용자 스토리
- `docs/aidlc/inception/units/integration_contract.md` - 단위 간 인터페이스 계약

## 주의사항

- 중요한 결정은 질문을 통해 명확히 합니다
- 모든 질문에 답변을 받은 후 설계 문서 작성을 시작합니다
- 설계 문서는 구현 가능한 수준의 상세도를 유지합니다
