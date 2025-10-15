# Admin Console Unit - Domain Model

## 문서 정보

- **작성일**: 2025-10-10
- **대상 Unit**: Admin Console Unit
- **사용자 스토리**: US6.1 ~ US6.11 (11개)
- **설계 방법론**: Domain-Driven Design (DDD)
- **아키텍처**: Clean Architecture + Event-Driven Architecture

---

## 1. 바운디드 컨텍스트 및 유비쿼터스 언어

### 1.1 바운디드 컨텍스트

**컨텍스트명**: Admin Console

**설계 결정**: 단일 바운디드 컨텍스트로 관리

**근거**:

- 모든 기능이 동일한 도메인 전문가(관리자)에 의해 수행됨
- 긴밀한 참조 관계와 공통 유비쿼터스 언어 공유
- Inception 단계에서 이미 독립 단위로 정의됨
- 각 관리 기능은 독립적인 Aggregate로 분리하여 응집도 유지

### 1.2 유비쿼터스 언어 정의

#### 지표 관리 도메인 (US6.1, US6.2)

| 용어 | 정의 | 비고 |
|------|------|------|
| **Indicator** | 경제 지표 - KOSIS/ECOS/OECD/CUSTOM 소스로부터 제공되는 데이터 | 핵심 도메인 개념 |
| **Source** | 지표의 데이터 출처 유형 | KOSIS, ECOS, OECD, CUSTOM |
| **DataSource** | 실제 API 엔드포인트 및 인증 정보를 가진 데이터 제공자 | Aggregate Root |
| **ApiParams** | 외부 API 호출에 필요한 파라미터 집합 | 유연한 구조 (Record<string, any>) |
| **연결 테스트** | API 호출 및 응답 시간 확인 작업 | 비즈니스 프로세스 |
| **재탐색** | 외부 API 스펙 변경 시 파라미터 자동 추출 및 갱신 | 특별한 비즈니스 프로세스 |
| **CustomDataPoint** | CUSTOM 소스 지표에 대한 수동 입력 데이터 포인트 | Entity (Indicator 내부) |

#### 사용자 관리 도메인 (US6.3)

| 용어 | 정의 | 비고 |
|------|------|------|
| **User** | 플랫폼 사용자 | Aggregate Root |
| **Plan** | 사용자 구독 플랜 | Free, Pro |
| **플랜 수동 변경** | 관리자가 사용자 플랜을 직접 변경하는 작업 | 변경 사유 필수 |
| **변경 사유** | 플랜 변경 또는 계정 상태 변경의 근거 | Value Object |
| **만료일** | 플랜 변경의 유효 기간 | null이면 영구 변경 |
| **ActivityLog** | 사용자 활동 기록 | 감사 로그 |
| **계정 활성화/비활성화** | 사용자 계정의 사용 가능 여부 | 약관 위반, 어뷰징 대응 |

#### 데이터 소스 관리 도메인 (US6.4)

| 용어 | 정의 | 비고 |
|------|------|------|
| **DataSource** | 외부 데이터 제공자 | Aggregate Root |
| **EncryptedApiKey** | 암호화된 API 키 | Value Object |
| **활성화/비활성화** | 데이터 소스의 사용 가능 여부 | 상태 관리 |
| **변경 이력** | 데이터 소스 설정 변경 추적 | 감사 추적 |

#### 플랜 제한 관리 도메인 (US6.5)

| 용어 | 정의 | 비고 |
|------|------|------|
| **PlanLimit** | 플랜별 제한사항 설정 | Aggregate Root |
| **제한값** | 대시보드 수, 위젯 수 등의 허용 한도 | 동적 관리 |
| **Price** | 플랜 가격 | Value Object (금액 + 통화) |
| **적용 기간** | 제한값의 유효 기간 | null이면 영구 적용 |

#### 템플릿 관리 도메인 (US6.6)

| 용어 | 정의 | 비고 |
|------|------|------|
| **Template** | 사전 구성된 대시보드 템플릿 | Aggregate Root |
| **활성화/비활성화** | 템플릿의 사용자 노출 여부 | 상태 관리 |
| **사용 통계** | 템플릿 사용 횟수 추적 | 조회 전용 데이터 |

#### 카테고리 관리 도메인 (US6.7)

| 용어 | 정의 | 비고 |
|------|------|------|
| **Category** | 지표 또는 템플릿 분류 체계 | Aggregate Root |
| **CategoryCode** | 카테고리 고유 식별자 | 불변 값 |
| **CategoryType** | 카테고리 유형 | indicator, template |
| **순서** | 카테고리 표시 순서 | 관리자가 조정 가능 |
| **사용 개수** | 카테고리에 속한 항목 수 | 삭제 정책 결정 기준 |

#### 컨텐츠 관리 도메인 (US6.9, US6.10, US6.11)

| 용어 | 정의 | 비고 |
|------|------|------|
| **Report** | 사용자가 제출한 컨텐츠 신고 | Aggregate Root |
| **신고 사유** | 투자 권유, 사기, 스팸 등 | 열거형 |
| **조치** | 신고에 대한 관리자의 대응 | 경고, 삭제, 정지, 무혐의 |
| **UserViolation** | 사용자의 위반 이력 기록 | Aggregate Root |
| **단계적 제재** | 위반 횟수에 따른 자동 제재 시스템 | 1회 경고 → 2회 48시간 정지 → 3회 영구 정지 |
| **ContentDetection** | 자동 탐지된 위험 컨텐츠 | 도메인 개념 (별도 Aggregate 아님) |
| **플래깅** | 위험 패턴 자동 탐지 표시 | 비즈니스 프로세스 |
| **위험도** | 탐지된 컨텐츠의 위험 수준 | high, medium, low |
| **오탐** | 정상 컨텐츠를 위험으로 잘못 판단 | 학습 및 개선 필요 |

---

## 2. 애그리게이트 설계

### 2.1 애그리게이트 개요

**총 9개의 독립 Aggregate Root 정의**

각 Aggregate는 트랜잭션 일관성 경계를 형성하며, 다른 Aggregate를 ID로만 참조하여 느슨한 결합을 유지합니다.

### 2.2 Aggregate 1: Indicator

**Aggregate Root**: Indicator

**책임**:

- 경제 지표 메타데이터 관리
- 외부 API 연결 정보 유지
- CUSTOM 소스의 경우 CustomDataPoint 관리

**불변 조건 (Invariants)**:

- Indicator는 유효한 Source와 DataSource를 가져야 함
- CUSTOM 소스만 CustomDataPoint를 가질 수 있음
- CustomDataPoint의 날짜는 중복될 수 없음
- Indicator는 유효한 Category를 참조해야 함

**포함된 엔티티**:

- **CustomDataPoint**: CUSTOM 소스 지표의 수동 입력 데이터 포인트
  - 속성: dataPointId, date, value, createdBy, createdAt, updatedBy, updatedAt
  - 생명주기: Indicator와 함께 생성/삭제 (Cascade Delete)
  - 식별자: dataPointId + indicatorId 조합

**참조하는 Aggregate**:

- Category (categoryCode로 참조)
- DataSource (dataSourceId로 참조)

**주요 도메인 메서드**:

- `updateApiParams()`: API 파라미터 재탐색 및 갱신
- `addDataPoint()`: CustomDataPoint 추가 (CUSTOM 소스만)
- `updateDataPoint()`: CustomDataPoint 값 수정
- `deleteDataPoint()`: CustomDataPoint 삭제
- `delete()`: Indicator 삭제 (정책 검증 포함)

**비즈니스 규칙**:

- CUSTOM 소스 지표 삭제 시 강력한 확인 절차 필요 (재인증)
- CUSTOM이 아닌 소스는 CustomDataPoint 추가 불가
- 위젯에서 사용 중인 지표는 삭제 불가 (IndicatorDeletionPolicy)

### 2.3 Aggregate 2: User

**Aggregate Root**: User

**책임**:

- 사용자 기본 정보 관리
- 플랜 수동 변경 기록
- 계정 상태 관리

**불변 조건 (Invariants)**:

- User는 유효한 email을 가져야 함
- 플랜 변경 시 변경 사유가 반드시 기록되어야 함
- 계정 비활성화 시 사유가 반드시 기록되어야 함

**참조하는 Aggregate**:

- Subscription (별도 Unit) - userId로 참조

**주요 도메인 메서드**:

- `changePlanManually()`: 관리자에 의한 플랜 변경
- `activateAccount()`: 계정 활성화
- `deactivateAccount()`: 계정 비활성화

**비즈니스 규칙**:

- 실제 Subscription 변경은 Subscription Unit에서 처리
- Admin Console은 변경 요청 및 사유 기록만 담당
- 플랜 변경 시 만료일 설정 가능 (null이면 영구 변경)

**설계 결정**:

- Subscription은 별도 Unit에서 관리되는 Aggregate
- User Aggregate는 Subscription을 소유하지 않고 userId로만 참조
- 구독 변경은 Subscription Unit의 서비스를 호출

### 2.4 Aggregate 3: DataSource

**Aggregate Root**: DataSource

**책임**:

- 외부 데이터 제공자 정보 관리
- API 엔드포인트 및 인증 정보 보관
- 데이터 소스 활성화/비활성화

**불변 조건 (Invariants)**:

- DataSource는 고유한 name을 가져야 함
- API Key는 반드시 암호화되어 저장되어야 함
- baseUrl은 유효한 URL 형식이어야 함

**Value Objects**:

- **EncryptedApiKey**: 암호화된 API 키
  - 암호화/복호화 로직 캡슐화
  - 평문 노출 방지

**주요 도메인 메서드**:

- `updateApiKey()`: API 키 갱신
- `activate()`: 데이터 소스 활성화
- `deactivate()`: 데이터 소스 비활성화 (정책 검증 포함)

**비즈니스 규칙**:

- 활성 지표를 가진 데이터 소스는 비활성화 시 경고
- API Key 접근은 감사 로그에 기록
- 변경 이력 영구 보관

### 2.5 Aggregate 4: PlanLimit

**Aggregate Root**: PlanLimit

**책임**:

- 플랜별 제한사항 설정 관리
- 플랜 가격 정보 관리
- 제한값 버전 관리

**불변 조건 (Invariants)**:

- PlanLimit는 유효한 planType을 가져야 함 (Free, Pro)
- 제한값은 0 이상이어야 함
- 가격은 0 이상이어야 함

**Value Objects**:

- **Price**: 플랜 가격 (금액 + 통화 단위)
  - 속성: amount (number), currency (string)
  - 비즈니스 규칙: amount >= 0

**주요 도메인 메서드**:

- `updateLimit()`: 제한값 수정
- `updatePrice()`: 가격 수정
- `addNewLimit()`: 새로운 제한 항목 추가

**비즈니스 규칙**:

- 제한값 변경 시 적용 기간 설정 가능
- 변경 이력 조회 가능 (버전 관리)
- 즉시 반영 (재배포 불필요)

### 2.6 Aggregate 5: Template

**Aggregate Root**: Template

**책임**:

- 대시보드 템플릿 정의 관리
- 템플릿 활성화/비활성화
- 사용 통계 추적

**불변 조건 (Invariants)**:

- Template는 유효한 name을 가져야 함
- Template는 유효한 Category를 참조해야 함
- widgetCount는 0 이상이어야 함

**참조하는 Aggregate**:

- Category (categoryCode로 참조)

**주요 도메인 메서드**:

- `update()`: 템플릿 메타데이터 수정
- `activate()`: 템플릿 활성화
- `deactivate()`: 템플릿 비활성화

**비즈니스 규칙**:

- 활성 템플릿만 사용자에게 노출
- 사용 통계는 조회 전용 데이터 (Query Model)

### 2.7 Aggregate 6: Category

**Aggregate Root**: Category

**책임**:

- 지표 및 템플릿 카테고리 관리
- 카테고리 순서 관리
- 카테고리 활성화/비활성화

**불변 조건 (Invariants)**:

- Category는 고유한 code를 가져야 함
- CategoryType은 indicator 또는 template이어야 함
- 동일 type 내에서 order는 중복될 수 없음

**주요 도메인 메서드**:

- `update()`: 카테고리 이름 수정
- `reorder()`: 카테고리 순서 변경
- `activate()`: 카테고리 활성화
- `deactivate()`: 카테고리 비활성화
- `delete()`: 카테고리 삭제 (정책 검증 포함)

**비즈니스 규칙**:

- 사용 중인 카테고리는 삭제 불가 (CategoryDeletionPolicy)
- 대안: 재할당 후 삭제 또는 비활성화
- 순서 변경 시 다른 카테고리와 중복 방지

### 2.8 Aggregate 7: Report

**Aggregate Root**: Report

**책임**:

- 사용자 신고 접수 및 추적
- 신고 검토 프로세스 관리
- 조치 실행 및 기록

**불변 조건 (Invariants)**:

- Report는 유효한 dashboardId를 참조해야 함
- 신고 사유는 열거형 값 중 하나여야 함
- 조치 실행 시 조치 사유가 반드시 기록되어야 함
- resolutionType이 suspension인 경우 suspensionDuration이 필수

**주요 도메인 메서드**:

- `startReview()`: 검토 시작
- `resolve()`: 조치 실행
  - 조치 유형: warning, deletion, suspension, dismissed
  - 조치 사유 필수 기록

**비즈니스 규칙**:

- Dashboard Unit의 `DashboardReported` 이벤트 구독하여 Report 생성
- 신고 접수 후 48시간 내 1차 검토 (SLA)
- 조치 내역 영구 보관 (법적 분쟁 대비)
- 신고자 정보 익명성 보장

**상태 전이**:

```
[대기] → [검토 중] → [조치 완료]
```

### 2.9 Aggregate 8: UserViolation

**Aggregate Root**: UserViolation

**책임**:

- 사용자별 위반 이력 누적
- 단계적 제재 시스템 관리
- 제재 만료 추적

**불변 조건 (Invariants)**:

- UserViolation은 유효한 userId를 참조해야 함
- 위반 이력은 시간 순서대로 누적되어야 함
- 제재 타입이 temporary_suspension인 경우 expiresAt이 필수

**주요 도메인 메서드**:

- `recordViolation()`: 위반 이력 추가
- `applySanction()`: 제재 적용
  - 자동 제재: 단계적 제재 시스템 (1회 경고 → 2회 48시간 정지 → 3회 영구 정지)
  - 수동 제재: 관리자 판단으로 즉시 정지
- `expireSanction()`: 제재 만료 (스케줄러 호출)

**비즈니스 규칙**:

- `ReportResolved` 이벤트 구독 후 위반 이력 추가
- 단계적 제재 시스템:
  - 1회 위반: 경고 (이메일 + 앱 내 알림)
  - 2회 위반: 48시간 게시 제한
  - 3회 위반: 계정 영구 정지
- temporary_suspension은 48시간 후 자동 만료
- 제재 내역 영구 보관

**US6.3의 `UserAccountStatusChanged`와 구분**:

- UserViolation: 위반 이력 기반 제재 (컨텐츠 관리)
- User.deactivateAccount(): 일반 계정 관리 (약관 위반, 어뷰징 등)

### 2.10 도메인 개념: ContentDetection

**설계 결정**: ContentDetection은 별도 Aggregate가 아님

**이유**:

- 자동 탐지 결과는 상태가 아닌 이벤트로 처리
- 플래깅된 대시보드는 Dashboard Unit에서 비공개 처리
- 관리자 검토 결과는 Report Aggregate로 변환

**도메인 이벤트**:

- `DashboardFlagged`: 위험 패턴 탐지 시 발행
- `FlaggedContentReviewed`: 관리자 검토 완료 시 발행

**비즈니스 프로세스**:

1. 일일 배치 스케줄러가 신규/수정 대시보드 스캔
2. 위험 패턴 탐지 시 `DashboardFlagged` 이벤트 발행
3. Dashboard Unit이 이벤트 구독하여 위험도에 따라 처리:
   - 높음: 즉시 비공개 + 작성자 알림
   - 중간: 검토 대기열 추가
   - 낮음: 로그만 기록, 공개 유지
4. 관리자가 오탐 여부 검토
5. `FlaggedContentReviewed` 이벤트 발행:
   - false_positive: Dashboard Unit이 대시보드 복원
   - confirmed_violation: Report 생성 → 조치 프로세스 진행

---

## 3. 엔티티와 값 객체

### 3.1 엔티티 (Entities)

#### 3.1.1 Aggregate Root Entities (9개)

모든 Aggregate Root는 고유 식별자와 생명주기를 가진 엔티티입니다.

1. **Indicator**
   - 식별자: indicatorId (UUID)
   - 생명주기: 등록 → 활성 → 삭제
   - 변경 가능 속성: name, description, apiParams, categoryCode

2. **User**
   - 식별자: userId (UUID)
   - 생명주기: 가입 → 활성/비활성 → 탈퇴
   - 변경 가능 속성: email, name, role, status

3. **DataSource**
   - 식별자: dataSourceId (UUID)
   - 생명주기: 등록 → 활성/비활성
   - 변경 가능 속성: name, baseUrl, encryptedApiKey, isActive

4. **PlanLimit**
   - 식별자: planType (열거형: Free, Pro)
   - 생명주기: 생성 → 수정 (삭제 없음)
   - 변경 가능 속성: limits (동적), price

5. **Template**
   - 식별자: templateId (UUID)
   - 생명주기: 생성 → 활성/비활성 → 삭제
   - 변경 가능 속성: name, description, categoryCode, isActive

6. **Category**
   - 식별자: categoryCode (문자열, 불변)
   - 생명주기: 생성 → 활성/비활성 → 삭제
   - 변경 가능 속성: name, order, isActive

7. **Report**
   - 식별자: reportId (UUID)
   - 생명주기: 접수 → 검토 중 → 조치 완료
   - 변경 가능 속성: status, reviewedBy, resolutionType

8. **UserViolation**
   - 식별자: userId + reportId 조합 (복합 키)
   - 생명주기: 기록 → 누적 → 제재
   - 변경 가능 속성: cumulativeViolationCount, sanctions

9. **ActivityLog**
   - 식별자: logId (UUID)
   - 생명주기: 생성 → 영구 보관 (변경 없음)
   - 불변 속성: 모든 속성 불변 (감사 로그)

#### 3.1.2 내부 Entity (1개)

1. **CustomDataPoint**
   - 부모 Aggregate: Indicator
   - 식별자: dataPointId (UUID)
   - 생명주기: Indicator와 함께 생성/삭제 (Cascade Delete)
   - 불변 조건: 동일 Indicator 내에서 date 중복 불가
   - 변경 가능 속성: value, updatedBy, updatedAt

### 3.2 값 객체 (Value Objects)

값 객체는 식별자가 없고 불변이며, 도메인 로직을 캡슐화합니다.

#### 3.2.1 EncryptedApiKey

**목적**: API 키 암호화 및 보안 관리

**속성**:

- encryptedValue (string): 암호화된 API 키 값
- algorithm (string): 암호화 알고리즘 (예: AES-256-GCM)

**도메인 로직**:

- 생성 시 자동 암호화
- 복호화 메서드 제공 (권한 검증 필요)
- 평문 노출 방지 (toString() 오버라이드)

**불변성**: 생성 후 변경 불가 (새 객체 생성)

**동등성**: encryptedValue 기준

#### 3.2.2 ChangeReason

**목적**: 플랜 변경 또는 계정 상태 변경의 근거

**속성**:

- reason (string): 변경 사유
- category (열거형): 사전 정의된 사유 카테고리 (예: "고객 요청", "약관 위반", "테스트 계정")

**도메인 로직**:

- 검증: 최소 10자, 최대 500자
- 사전 정의된 카테고리에서 선택 또는 직접 입력

**불변성**: 생성 후 변경 불가

**동등성**: reason + category 조합 기준

#### 3.2.3 Price

**목적**: 플랜 가격 정보 표현

**속성**:

- amount (number): 금액
- currency (string): 통화 단위 (예: "KRW", "USD")

**도메인 로직**:

- 검증: amount >= 0
- 통화 변환 로직 (선택 사항)
- 포맷팅 메서드 (예: "₩10,000")

**불변성**: 생성 후 변경 불가

**동등성**: amount + currency 조합 기준

#### 3.2.4 ApiParams

**설계 결정**: Value Object로 도입하지 않음, `Record<string, any>`로 유연하게 유지

**이유**:

1. KOSIS, ECOS, OECD의 공식 문서는 동적 페이지로 AI-DLC 도구 환경에서 자동 접근 불가
2. 외부 기관이 파라미터 구조를 변경할 경우 타입 정의가 정상 요청을 차단할 위험
3. US6.4 요구사항: "재배포 없이 즉시 대응" - 관리자가 파라미터를 자유롭게 조정 가능해야 함
4. US6.2 "연결 테스트" 기능으로 실제 API 호출을 통해 유효성 검증

**타입 안정성 < 유연성**: 실무 요구사항과 외부 API 불확실성을 고려한 실용적 설계

---

## 4. 도메인 이벤트

### 4.1 도메인 이벤트 개요

**총 31개의 도메인 이벤트 정의**

도메인 이벤트는 비즈니스적으로 중요한 상태 변경을 나타내며, Aggregate Root가 발행합니다.

**명명 규칙**: 과거형 (Created, Updated, Deleted 등)

**발행 시점**: Repository 저장 성공 후 (트랜잭션 커밋 후)

### 4.2 Indicator Aggregate 이벤트 (4개)

#### 4.2.1 IndicatorCreated

**발행 시점**: 새 지표 등록 완료 후

**속성**:

- indicatorId: 지표 ID
- name: 지표명
- source: 소스 유형 (KOSIS, ECOS, OECD, CUSTOM)
- categoryCode: 카테고리 코드
- createdBy: 등록 관리자 ID
- createdAt: 등록 시간

**이벤트 구독자**: 통계 집계 서비스

#### 4.2.2 IndicatorUpdated

**발행 시점**: 지표 메타데이터 수정 완료 후

**속성**:

- indicatorId: 지표 ID
- changedFields: 변경된 필드 목록 (old, new 값 포함)
  - name
  - description
  - categoryCode
- updatedBy: 수정 관리자 ID
- updatedAt: 수정 시간

**이벤트 구독자**: Data Integration Unit (캐시 무효화)

#### 4.2.3 IndicatorApiParamsUpdated

**발행 시점**: API 파라미터 재탐색 및 갱신 완료 후

**속성**:

- indicatorId: 지표 ID
- oldParams: 기존 파라미터
- newParams: 새 파라미터
- updatedBy: 수정 관리자 ID
- updatedAt: 수정 시간

**특별한 이벤트 이유**: `IndicatorUpdated`와 별도 - "재탐색" 기능의 특별한 비즈니스 프로세스

**이벤트 구독자**: 알림 서비스 (관리자에게 파라미터 변경 통보)

#### 4.2.4 IndicatorDeleted

**발행 시점**: 지표 삭제 완료 후

**속성**:

- indicatorId: 지표 ID
- source: 소스 유형
- deletedBy: 삭제 관리자 ID
- deletedAt: 삭제 시간

**이벤트 구독자**: Widget Library Unit (위젯 정리)

**참고**: CUSTOM 소스 지표 삭제 시 CustomDataPoint는 Cascade Delete (별도 이벤트 발행 안 함)

### 4.3 User Aggregate 이벤트 (2개)

#### 4.3.1 UserPlanManuallyChanged

**발행 시점**: 관리자에 의한 플랜 변경 완료 후

**속성**:

- userId: 사용자 ID
- oldPlan: 기존 플랜 (Free, Pro)
- newPlan: 새 플랜
- reason: 변경 사유 (ChangeReason Value Object)
- expiresAt: 만료일 (null이면 영구 변경)
- changedBy: 관리자 ID
- changedAt: 변경 시간

**이벤트 구독자**: Subscription Unit (실제 구독 변경 처리)

#### 4.3.2 UserAccountStatusChanged

**발행 시점**: 계정 활성화/비활성화 완료 후

**속성**:

- userId: 사용자 ID
- oldStatus: 기존 상태 (active, inactive)
- newStatus: 새 상태
- reason: 변경 사유
- changedBy: 관리자 ID
- changedAt: 변경 시간

**이벤트 구독자**: Authentication Unit (로그인 차단 또는 해제)

### 4.4 DataSource Aggregate 이벤트 (3개)

#### 4.4.1 DataSourceAdded

**발행 시점**: 새 데이터 소스 등록 완료 후

**속성**:

- dataSourceId: 데이터 소스 ID
- name: 데이터 소스명
- baseUrl: API 엔드포인트
- addedBy: 등록 관리자 ID
- addedAt: 등록 시간

**이벤트 구독자**: Data Integration Unit (새 소스 클라이언트 초기화)

#### 4.4.2 DataSourceApiKeyUpdated

**발행 시점**: API 키 갱신 완료 후

**속성**:

- dataSourceId: 데이터 소스 ID
- updatedBy: 수정 관리자 ID
- updatedAt: 수정 시간

**보안**: 암호화된 API Key 값은 이벤트에 미포함

**이벤트 구독자**: 감사 로그 서비스

#### 4.4.3 DataSourceStatusChanged

**발행 시점**: 데이터 소스 활성화/비활성화 완료 후

**속성**:

- dataSourceId: 데이터 소스 ID
- oldStatus: 기존 상태 (active, inactive)
- newStatus: 새 상태
- changedBy: 관리자 ID
- changedAt: 변경 시간

**이벤트 구독자**: Data Integration Unit (데이터 수집 중단 또는 재개)

### 4.5 PlanLimit Aggregate 이벤트 (2개)

#### 4.5.1 PlanLimitUpdated

**발행 시점**: 플랜 제한값 수정 완료 후

**속성**:

- planType: 플랜 유형 (Free, Pro)
- limitKey: 제한 항목 키 (예: "maxDashboards")
- oldValue: 기존 값 (null이면 신규 항목 추가)
- newValue: 새 값
- expiresAt: 적용 만료일 (null이면 영구 적용)
- updatedBy: 관리자 ID
- updatedAt: 수정 시간

**이벤트 구독자**: 모든 Unit (제한 캐시 무효화)

#### 4.5.2 PlanPriceUpdated

**발행 시점**: 플랜 가격 수정 완료 후

**속성**:

- planType: 플랜 유형
- oldPrice: 기존 가격 (Price Value Object)
- newPrice: 새 가격
- currency: 통화 단위
- updatedBy: 관리자 ID
- updatedAt: 수정 시간

**이벤트 구독자**: Subscription Unit (가격 정보 동기화)

### 4.6 Template Aggregate 이벤트 (3개)

#### 4.6.1 TemplateCreated

**발행 시점**: 새 템플릿 생성 완료 후

**속성**:

- templateId: 템플릿 ID
- name: 템플릿명
- categoryCode: 카테고리 코드
- widgetCount: 위젯 개수
- createdBy: 관리자 ID
- createdAt: 생성 시간

**이벤트 구독자**: Dashboard Unit (템플릿 목록 동기화)

#### 4.6.2 TemplateUpdated

**발행 시점**: 템플릿 메타데이터 수정 완료 후

**속성**:

- templateId: 템플릿 ID
- changedFields: 변경된 필드 목록
  - name
  - categoryCode
  - widgetCount
- updatedBy: 관리자 ID
- updatedAt: 수정 시간

**이벤트 구독자**: Dashboard Unit (템플릿 캐시 무효화)

#### 4.6.3 TemplateStatusChanged

**발행 시점**: 템플릿 활성화/비활성화 완료 후

**속성**:

- templateId: 템플릿 ID
- oldStatus: 기존 상태 (active, inactive)
- newStatus: 새 상태
- changedBy: 관리자 ID
- changedAt: 변경 시간

**이벤트 구독자**: Dashboard Unit (사용자 노출 여부 제어)

### 4.7 Category Aggregate 이벤트 (5개)

#### 4.7.1 CategoryCreated

**발행 시점**: 새 카테고리 생성 완료 후

**속성**:

- categoryCode: 카테고리 코드
- name: 카테고리명
- type: 카테고리 유형 (indicator, template)
- createdBy: 관리자 ID
- createdAt: 생성 시간

**이벤트 구독자**: 모든 Unit (카테고리 목록 동기화)

#### 4.7.2 CategoryUpdated

**발행 시점**: 카테고리 이름 수정 완료 후

**속성**:

- categoryCode: 카테고리 코드
- changedFields: 변경된 필드 목록
  - name
- updatedBy: 관리자 ID
- updatedAt: 수정 시간

**이벤트 구독자**: 모든 Unit (카테고리 캐시 무효화)

#### 4.7.3 CategoryReordered

**발행 시점**: 카테고리 순서 변경 완료 후

**속성**:

- categoryCode: 카테고리 코드
- oldOrder: 기존 순서
- newOrder: 새 순서
- reorderedBy: 관리자 ID
- reorderedAt: 변경 시간

**이벤트 구독자**: Data Integration Unit (카테고리 표시 순서 갱신)

#### 4.7.4 CategoryStatusChanged

**발행 시점**: 카테고리 활성화/비활성화 완료 후

**속성**:

- categoryCode: 카테고리 코드
- oldStatus: 기존 상태 (active, inactive)
- newStatus: 새 상태
- changedBy: 관리자 ID
- changedAt: 변경 시간

**이벤트 구독자**: 모든 Unit (비활성 카테고리 사용자 노출 제어)

#### 4.7.5 CategoryDeleted

**발행 시점**: 카테고리 삭제 완료 후

**속성**:

- categoryCode: 카테고리 코드
- deletedBy: 관리자 ID
- deletedAt: 삭제 시간

**이벤트 구독자**: 모든 Unit (카테고리 제거)

### 4.8 CustomDataPoint 관련 이벤트 (4개)

**참고**: CustomDataPoint는 Indicator Aggregate의 내부 Entity이므로, 모든 이벤트는 Indicator Aggregate Root가 발행합니다.

#### 4.8.1 CustomDataPointsImported

**발행 시점**: CSV 일괄 업로드 완료 후

**속성**:

- indicatorId: 상위 Indicator ID
- importedCount: 성공적으로 추가된 데이터 개수
- failedCount: 검증 실패 개수
- dateRange: 데이터의 시간 범위
  - from: 시작 날짜
  - to: 종료 날짜
- importedBy: 관리자 ID
- importedAt: 업로드 시간

**비즈니스 규칙**: CSV 일괄 업로드는 하나의 트랜잭션으로 처리 (이벤트 1개 발행)

**이벤트 구독자**: 통계 집계 서비스

#### 4.8.2 CustomDataPointCreated

**발행 시점**: 개별 데이터 포인트 추가 완료 후

**속성**:

- indicatorId: 상위 Indicator ID
- dataPointId: 데이터 포인트 ID
- date: 데이터 시점
- value: 데이터 값
- createdBy: 관리자 ID
- createdAt: 생성 시간

**이벤트 구독자**: Data Integration Unit (데이터 동기화)

#### 4.8.3 CustomDataPointUpdated

**발행 시점**: 데이터 포인트 값 수정 완료 후

**속성**:

- indicatorId: 상위 Indicator ID
- dataPointId: 데이터 포인트 ID
- date: 데이터 시점
- oldValue: 수정 전 값
- newValue: 수정 후 값
- updatedBy: 관리자 ID
- updatedAt: 수정 시간

**이벤트 구독자**: Data Integration Unit (데이터 동기화)

#### 4.8.4 CustomDataPointDeleted

**발행 시점**: 데이터 포인트 삭제 완료 후

**속성**:

- indicatorId: 상위 Indicator ID
- dataPointId: 데이터 포인트 ID
- date: 데이터 시점
- deletedValue: 삭제된 값 (감사 로그용)
- deletedBy: 관리자 ID
- deletedAt: 삭제 시간

**이벤트 구독자**: Data Integration Unit (데이터 동기화)

### 4.9 Report Aggregate 이벤트 (3개)

#### 4.9.1 ReportCreated

**발행 시점**: 신고 접수 완료 후

**속성**:

- reportId: 신고 ID
- dashboardId: 신고된 대시보드 ID
- reportedBy: 신고자 ID (익명 처리 가능)
- reportReason: 신고 사유 (investment_solicitation, fraud, spam, other)
- reportDescription: 신고 상세 사유
- createdAt: 접수 시간

**비즈니스 규칙**: Dashboard Unit의 `DashboardReported` 이벤트를 구독하여 생성

**이벤트 구독자**: 알림 서비스 (관리자에게 신고 접수 통보)

#### 4.9.2 ReportReviewStarted

**발행 시점**: 관리자가 검토 시작 시

**속성**:

- reportId: 신고 ID
- reviewedBy: 검토 시작한 관리자 ID
- reviewStartedAt: 검토 시작 시간

**비즈니스 규칙**: SLA 모니터링용 (48시간 내 검토)

**이벤트 구독자**: 모니터링 시스템

#### 4.9.3 ReportResolved

**발행 시점**: 조치 실행 완료 후

**속성**:

- reportId: 신고 ID
- dashboardId: 신고된 대시보드 ID
- dashboardAuthorId: 대시보드 작성자 ID
- resolutionType: 조치 유형 (warning, deletion, suspension, dismissed)
- resolutionReason: 조치 사유 (필수)
- suspensionDuration: 계정 정지 시간 (시간 단위, suspension인 경우만)
- resolvedBy: 조치 실행한 관리자 ID
- resolvedAt: 조치 시간

**비즈니스 규칙**: `resolutionType`으로 4가지 조치를 하나의 이벤트로 통합

**이벤트 구독자**:

- UserViolation Aggregate (위반 이력 기록)
- Dashboard Unit (대시보드 삭제 처리)
- Authentication Unit (계정 정지 처리)
- 알림 서비스 (작성자 및 신고자에게 결과 통보)

### 4.10 UserViolation Aggregate 이벤트 (3개)

#### 4.10.1 UserViolationRecorded

**발행 시점**: 위반 이력 추가 완료 후

**속성**:

- userId: 위반 사용자 ID
- reportId: 원인이 된 신고 ID
- violationType: 위반 유형 (investment_solicitation, fraud, spam, other)
- dashboardId: 위반 대시보드 ID
- cumulativeViolationCount: 누적 위반 횟수 (1회, 2회, 3회...)
- recordedAt: 기록 시간

**비즈니스 규칙**: `ReportResolved` 이벤트 구독 후 위반 이력 추가

**이벤트 구독자**: 통계 집계 서비스

#### 4.10.2 UserSanctionApplied

**발행 시점**: 제재 적용 완료 후

**속성**:

- userId: 제재 대상 사용자 ID
- sanctionType: 제재 유형 (warning, temporary_suspension, permanent_ban)
- reason: 제재 사유
- isAutomatic: 자동 제재 여부 (단계적 제재 시스템)
- appliedBy: 수동 제재인 경우 관리자 ID (null이면 자동)
- expiresAt: temporary_suspension인 경우 만료 시간 (null이면 영구)
- cumulativeViolationCount: 현재 누적 위반 횟수
- appliedAt: 제재 시간

**비즈니스 규칙**:

- 단계적 제재 시스템: 1회 경고 → 2회 48시간 정지 → 3회 영구 정지
- isAutomatic = true: 단계적 제재 시스템에 의한 자동 제재
- isAutomatic = false: 관리자 판단에 의한 수동 제재

**이벤트 구독자**:

- Authentication Unit (로그인 차단 또는 기능 제한)
- Dashboard Unit (대시보드 생성/수정 차단)
- 알림 서비스 (사용자에게 제재 통보)

#### 4.10.3 UserSanctionExpired

**발행 시점**: 제재 만료 시 (스케줄러에 의해 자동 발행)

**속성**:

- userId: 제재 해제 사용자 ID
- expiredSanctionType: 만료된 제재 유형 (현재는 temporary_suspension만)
- sanctionAppliedAt: 제재가 적용된 시간
- expiredAt: 만료 시간

**비즈니스 규칙**: temporary_suspension은 48시간 후 자동 만료

**이벤트 구독자**:

- Authentication Unit (로그인 제한 해제)
- Dashboard Unit (기능 제한 해제)
- 알림 서비스 (사용자에게 제재 해제 통보)

### 4.11 ContentDetection 관련 이벤트 (2개)

#### 4.11.1 DashboardFlagged

**발행 시점**: 위험 패턴 자동 탐지 후

**속성**:

- dashboardId: 플래깅된 대시보드 ID
- authorId: 작성자 ID
- riskLevel: 위험도 (high, medium, low)
- detectedPatterns: 탐지된 키워드 패턴 목록
- riskScore: 위험도 점수 (0-100)
- detectedAt: 탐지 시간
- scanBatchId: 배치 작업 ID (추적용)

**비즈니스 규칙**: 일일 배치 스케줄러가 신규/수정 대시보드 스캔 후 발행

**이벤트 구독자**:

- Dashboard Unit (위험도에 따라 즉시 비공개 처리)
- 알림 서비스 (high인 경우 관리자에게 즉시 알림)

#### 4.11.2 FlaggedContentReviewed

**발행 시점**: 관리자 검토 완료 후

**속성**:

- dashboardId: 검토된 대시보드 ID
- reviewResult: 검토 결과 (false_positive, confirmed_violation)
- reviewNotes: 검토 의견
- detectedPatterns: 원래 탐지된 패턴 (오탐 학습용)
- reportId: confirmed_violation인 경우 생성된 Report ID (null이면 false_positive)
- reviewedBy: 관리자 ID
- reviewedAt: 검토 시간

**비즈니스 규칙**:

- false_positive: 오탐으로 판정 → Dashboard Unit이 대시보드 복원
- confirmed_violation: 위반 확인 → Report 생성 → 조치 프로세스 진행

**이벤트 구독자**:

- Dashboard Unit (대시보드 복원 또는 계속 비공개)
- Report Aggregate (confirmed_violation인 경우 Report 생성)
- 탐지 룰 엔진 (오탐 패턴 학습)

### 4.12 이벤트 간 인과 관계

#### 4.12.1 신고 대응 프로세스

```
Dashboard Unit: DashboardReported
    ↓ (구독)
Admin Console: ReportCreated → ReportReviewStarted → ReportResolved
    ↓ (구독)
Admin Console: UserViolationRecorded → UserSanctionApplied
    ↓ (구독)
Authentication Unit: 로그인 차단 또는 기능 제한
Dashboard Unit: 대시보드 생성/수정 차단
```

#### 4.12.2 자동 탐지 프로세스

```
자동 탐지 배치:
Admin Console: DashboardFlagged(high)
    ↓ (구독)
Dashboard Unit: 대시보드 비공개 처리
    ↓ (오탐 검토)
Admin Console: FlaggedContentReviewed(false_positive) → Dashboard Unit: 대시보드 복원
Admin Console: FlaggedContentReviewed(confirmed_violation) → ReportCreated → 신고 대응 프로세스
```

#### 4.12.3 단계적 제재 프로세스

```
UserSanctionApplied(temporary_suspension) → 48시간 후 → UserSanctionExpired
```

#### 4.12.4 플랜 변경 프로세스

```
UserPlanManuallyChanged
    ↓ (구독)
Subscription Unit: SubscriptionUpdated
```

#### 4.12.5 지표 삭제 프로세스

```
IndicatorDeleted (CUSTOM 소스)
    → CustomDataPoint Cascade Delete (Entity이므로 별도 이벤트 발행 안 함)
```

#### 4.12.6 카테고리 관리 프로세스

```
CategoryUpdated
    ↓ (구독, 선택 사항)
Data Integration Unit: 카테고리 캐시 무효화
```

### 4.13 도메인 이벤트 vs Application Event 구분

| 구분 | 도메인 이벤트 | Application Event |
|------|--------------|-------------------|
| **목적** | 비즈니스 상태 변경 전파 | 기술적 이벤트, 시스템 모니터링 |
| **예시** | IndicatorCreated, UserSanctionApplied | IndicatorConnectionTested, ContentScanExecuted, DetectionRuleUpdated |
| **발행 위치** | Domain Layer (Aggregate) | Application/Infrastructure Layer |
| **구독자** | 다른 Unit의 Domain Layer | 같은 Unit의 Application Service, 모니터링 시스템 |
| **보장** | 비즈니스 일관성 유지에 중요 | 최선 노력, 실패해도 비즈니스 영향 적음 |

**Application Event 예시** (도메인 이벤트가 아님):

- `IndicatorConnectionTested`: 조회 작업이므로 도메인 상태 변경 없음
- `ContentScanExecuted`: 배치 완료는 Infrastructure Event
- `DetectionRuleUpdated`: 탐지 룰 설정 변경은 시스템 설정 변경

---

## 5. 도메인 서비스

도메인 서비스는 여러 Aggregate에 걸친 비즈니스 로직이나 엔티티/값 객체에 속하지 않는 도메인 로직을 캡슐화합니다.

### 5.1 도메인 서비스 vs 애플리케이션 서비스 구분

| 구분 | 도메인 서비스 | 애플리케이션 서비스 |
|------|--------------|-------------------|
| **위치** | Domain Layer | Application Layer |
| **책임** | 비즈니스 로직 및 규칙 정의 | Use Case 조율, 트랜잭션 관리 |
| **의존성** | 도메인 객체, Repository 인터페이스 | 도메인 서비스, Infrastructure 서비스 |
| **예시** | IndicatorConnectionTestService | CreateIndicatorUseCase |

### 5.2 Domain Service 1: IndicatorConnectionTestService

**책임**: 지표의 외부 API 연결 테스트 수행 및 결과 판단

**협력 객체**:

- IIndicatorRepository: 지표 조회 및 저장
- IIndicatorApiClientFactory: 소스별 API 클라이언트 제공

**주요 메서드**:

- `testIndicatorConnection(indicatorId: string): Promise<ConnectionTestResult>`
  - Indicator 조회
  - 소스별 API Client 선택
  - 실제 API 호출 수행
  - 비즈니스 규칙 적용: 응답 시간 > 5초이면 경고
  - 결과 반환

**비즈니스 규칙**:

- 응답 시간이 5초 이상이면 경고 추가
- 연결 테스트 결과는 Indicator에 기록 (Application Event 발행)

**역할 분담**:

- 도메인 서비스: "무엇을 테스트해야 하는가" 정의
- 인프라 레이어: "어떻게 호출하는가" 구현 (HTTP 요청, 에러 처리, 타임아웃)

### 5.3 Domain Service 2: CategoryDeletionPolicy

**책임**: 카테고리 삭제 가능 여부 검증 및 재할당 로직

**협력 객체**:

- IIndicatorRepository: 카테고리별 지표 수 조회
- IDashboardRepository: 카테고리별 대시보드 수 조회
- ITemplateRepository: 카테고리별 템플릿 수 조회

**주요 메서드**:

- `canDelete(categoryCode: string): Promise<CategoryDeletionResult>`
  - 사용 중인 항목 수 집계 (Indicator, Dashboard, Template)
  - 사용 중이면 삭제 불가 판정 및 세부 정보 반환
  - 사용 중이지 않으면 삭제 허용
- `reassignItemsAndDelete(categoryCode: string, targetCategoryCode: string): Promise<void>`
  - 모든 사용 항목을 대체 카테고리로 재할당
  - 트랜잭션으로 처리 (원자성 보장)

**비즈니스 규칙**:

- 사용 중인 카테고리는 절대 삭제 불가 (데이터 무결성)
- 대안 1: 재할당 후 삭제 (관리자가 대체 카테고리 지정)
- 대안 2: 비활성화 (isActive = false)로 신규 사용 방지, 기존 항목 유지

**정책 우선순위**:

1. 강제 삭제 불가
2. 재할당 옵션 제공
3. 비활성화 대안

### 5.4 Domain Service 3: IndicatorDeletionPolicy

**책임**: 지표 삭제 가능 여부 검증

**협력 객체**:

- IWidgetRepository (Widget Library Unit): 지표를 사용하는 위젯 수 조회

**주요 메서드**:

- `canDelete(indicatorId: string): Promise<DeletionResult>`
  - 위젯에서 사용 중인지 확인
  - 사용 중이면 삭제 불가 판정 및 영향받는 위젯 수 반환
  - 사용 중이지 않으면 삭제 허용

**비즈니스 규칙**:

- 위젯에서 사용 중인 지표는 삭제 불가
- CUSTOM 소스 지표 삭제 시 강력한 확인 절차 필요 (재인증)

### 5.5 Domain Service 4: DataSourceDeactivationPolicy

**책임**: 데이터 소스 비활성화 가능 여부 검증

**협력 객체**:

- IIndicatorRepository: 데이터 소스별 활성 지표 수 조회

**주요 메서드**:

- `canDeactivate(dataSourceId: string): Promise<DeactivationResult>`
  - 해당 소스의 활성 지표 개수 확인
  - 활성 지표가 있으면 비활성화 가능하지만 경고 반환
  - 활성 지표가 없으면 비활성화 허용

**비즈니스 규칙**:

- 활성 지표가 있는 데이터 소스도 비활성화 가능 (강제 차단 아님)
- 비활성화 시 데이터 수집 실패 경고 표시
- 관리자 판단에 맡김

### 5.6 Domain Service 5: StepwiseSanctionPolicy

**책임**: 단계적 제재 시스템 규칙 적용

**협력 객체**:

- IUserViolationRepository: 사용자별 누적 위반 횟수 조회

**주요 메서드**:

- `determineSanction(userId: string, cumulativeViolationCount: number): SanctionDecision`
  - 누적 위반 횟수에 따라 제재 유형 결정
  - 1회: 경고 (warning)
  - 2회: 48시간 게시 제한 (temporary_suspension)
  - 3회 이상: 계정 영구 정지 (permanent_ban)
  - 제재 결정 반환 (sanctionType, expiresAt, reason)

**비즈니스 규칙**:

- 단계적 제재 시스템은 자동 적용 (isAutomatic = true)
- 관리자는 수동으로 즉시 정지 가능 (isAutomatic = false)
- temporary_suspension은 48시간 (2일) 후 자동 만료

---

## 6. 정책 (Policies)

정책은 비즈니스 규칙과 제약사항을 정의합니다. 정책의 의도(WHAT)는 도메인 레이어에서 정의하고, 검증 메커니즘(HOW)은 Application/Infrastructure 레이어에서 구현합니다.

### 6.1 Policy 1: IAdminAuthorizationPolicy

**목적**: 관리자 권한 검증 및 보안 정책

**정의 위치**: Domain Layer (인터페이스)

**구현 위치**: Application Layer (SupabaseAdminAuthorizationPolicy)

**정책 메서드**:

- `canManageIndicators(user: User): boolean`
  - 지표 관리 권한 확인
  - 규칙: user.role === 'admin'
- `canManageUsers(user: User): boolean`
  - 사용자 관리 권한 확인
  - 규칙: user.role === 'admin'
- `canDeleteDashboard(user: User, dashboard: Dashboard): boolean`
  - 대시보드 삭제 권한 확인
  - 규칙: user.role === 'admin' 또는 dashboard.ownerId === user.id
- `requiresReAuthentication(operation: AdminOperation): boolean`
  - 민감한 작업 시 재인증 필요 여부 확인
  - 민감한 작업 목록: DELETE_CUSTOM_INDICATOR, CHANGE_USER_PLAN, UPDATE_API_KEY, SUSPEND_USER_ACCOUNT

**비즈니스 규칙**:

- 모든 관리 작업은 admin 역할 필수
- 민감한 작업은 재인증 필요 (5분 이내 로그인 확인)
- 재인증 실패 시 작업 차단

**레이어별 책임**:

- Domain: 정책 의도 정의 (인터페이스)
- Application: 정책 구현 (역할 검증 로직)
- Infrastructure: 재인증 메커니즘 (Supabase 세션 확인)

### 6.2 Policy 2: CategoryDeletionPolicy

**목적**: 카테고리 삭제 시 데이터 무결성 보장

**정의 위치**: Domain Layer (Domain Service)

**정책 규칙**:

1. **강제 삭제 불가**: 사용 중인 카테고리는 절대 삭제 불가
2. **재할당 옵션 제공**: 관리자가 대체 카테고리 지정 시 항목 재할당 후 삭제
3. **비활성화 대안**: 삭제 대신 isActive = false로 설정하여 신규 사용 방지, 기존 항목 유지

**트리거 조건**:

- 관리자가 카테고리 삭제 시도 시

**실행 결과**:

- 사용 중이면: CategoryInUseError 발생, 세부 정보 제공 (Indicator 수, Dashboard 수, Template 수)
- 사용 중이지 않으면: 삭제 허용

### 6.3 Policy 3: IndicatorDeletionPolicy

**목적**: 지표 삭제 시 위젯 무결성 보장

**정의 위치**: Domain Layer (Domain Service)

**정책 규칙**:

1. 위젯에서 사용 중인 지표는 삭제 불가
2. CUSTOM 소스 지표 삭제 시 강력한 확인 절차 필요

**트리거 조건**:

- 관리자가 지표 삭제 시도 시

**실행 결과**:

- 위젯에서 사용 중이면: IndicatorInUseError 발생, 영향받는 위젯 수 제공
- 사용 중이지 않으면: 삭제 허용
- CUSTOM 소스이면: ReAuthenticationRequiredError 발생 (재인증 필요)

### 6.4 Policy 4: DataSourceDeactivationPolicy

**목적**: 데이터 소스 비활성화 시 영향 최소화

**정의 위치**: Domain Layer (Domain Service)

**정책 규칙**:

1. 활성 지표가 있는 데이터 소스도 비활성화 가능 (강제 차단 아님)
2. 비활성화 시 경고 표시: "Deactivating will cause data fetch failures"

**트리거 조건**:

- 관리자가 데이터 소스 비활성화 시도 시

**실행 결과**:

- 활성 지표가 있으면: 비활성화 가능하지만 경고 반환
- 활성 지표가 없으면: 비활성화 허용

### 6.5 Policy 5: StepwiseSanctionPolicy

**목적**: 위반 사용자에 대한 단계적 제재 자동 적용

**정의 위치**: Domain Layer (Domain Service)

**정책 규칙**:

1. **1회 위반**: 경고 (warning) - 이메일 + 앱 내 알림
2. **2회 위반**: 48시간 게시 제한 (temporary_suspension)
3. **3회 이상 위반**: 계정 영구 정지 (permanent_ban)

**트리거 조건**:

- UserViolationRecorded 이벤트 발행 시

**실행 결과**:

- 누적 위반 횟수에 따라 자동 제재 적용 (UserSanctionApplied 이벤트 발행)
- temporary_suspension은 48시간 후 자동 만료 (UserSanctionExpired 이벤트 발행)

**정책 간 우선순위**:

- 자동 제재 (isAutomatic = true)가 기본
- 관리자 수동 제재 (isAutomatic = false)가 우선 (즉시 정지 가능)

### 6.6 Policy 6: ContentFlaggingPolicy

**목적**: 위험 컨텐츠 자동 탐지 및 조치

**정의 위치**: Infrastructure Layer (탐지 룰 엔진)

**정책 규칙**:

1. **높음 (high)**: 즉시 비공개 + 작성자 알림
2. **중간 (medium)**: 검토 대기열 추가
3. **낮음 (low)**: 로그만 기록, 공개 유지

**트리거 조건**:

- 일일 배치 스케줄러가 신규/수정 대시보드 스캔 시

**위험 패턴**:

- 특정 종목명 + 행동 유도 ("삼성전자 사세요")
- 수익 보장 표현 ("100% 수익", "반드시 오른다")
- 타이밍 단정 ("내일 급등", "곧 폭등")
- 외부 유료 서비스 링크 ("텔레그램", "카톡방")

**실행 결과**:

- DashboardFlagged 이벤트 발행
- Dashboard Unit이 위험도에 따라 자동 조치
- 관리자 검토 후 FlaggedContentReviewed 이벤트 발행

---

## 7. 리포지토리 인터페이스

리포지토리는 Aggregate Root 단위로만 정의합니다. 내부 엔티티는 Aggregate Root를 통해 접근합니다.

### 7.1 리포지토리 설계 원칙

**원칙**:

- 리포지토리는 Aggregate Root 단위로만 정의
- 내부 엔티티(CustomDataPoint)는 별도 Repository 없음
- 읽기 전용 쿼리는 Query Repository 별도 정의 가능 (CQRS)
- 트랜잭션 경계는 Unit of Work 패턴으로 관리

**예외**:

- 읽기 전용 Query Repository: 복잡한 조회, 성능 최적화 필요 시

### 7.2 Repository 1: IIndicatorRepository

**Aggregate Root**: Indicator

**주요 메서드**:

- `save(indicator: Indicator): Promise<void>`
  - Indicator Aggregate Root 저장 (CustomDataPoint 포함)
  - 트랜잭션 내에서 원자적으로 저장
- `delete(indicator: Indicator): Promise<void>`
  - Indicator 삭제 (CustomDataPoint Cascade Delete)
- `findById(id: string): Promise<Indicator | null>`
  - ID로 Indicator 조회 (CustomDataPoint 포함)
- `findBySource(source: DataSourceType): Promise<Indicator[]>`
  - 소스 유형별 Indicator 목록 조회
- `findAll(filter?: IndicatorFilter): Promise<Indicator[]>`
  - 필터링된 Indicator 목록 조회
- `countByCategoryCode(categoryCode: string): Promise<number>`
  - 카테고리별 Indicator 수 조회 (CategoryDeletionPolicy용)
- `countByDataSource(dataSourceId: string): Promise<number>`
  - 데이터 소스별 Indicator 수 조회 (DataSourceDeactivationPolicy용)

**CustomDataPoint 접근**:

- CustomDataPoint는 Indicator를 통해서만 접근
- Indicator.addDataPoint(), updateDataPoint(), deleteDataPoint() 메서드 사용
- Indicator.save() 호출 시 CustomDataPoint도 함께 저장

### 7.3 Repository 2: IUserRepository

**Aggregate Root**: User

**주요 메서드**:

- `save(user: User): Promise<void>`
  - User Aggregate Root 저장
- `findById(id: string): Promise<User | null>`
  - ID로 User 조회
- `findByEmail(email: string): Promise<User | null>`
  - 이메일로 User 조회
- `findAll(filter?: UserFilter): Promise<User[]>`
  - 필터링된 User 목록 조회
- `countByPlan(planType: PlanType): Promise<number>`
  - 플랜별 User 수 조회 (통계용)

### 7.4 Repository 3: IDataSourceRepository

**Aggregate Root**: DataSource

**주요 메서드**:

- `save(dataSource: DataSource): Promise<void>`
  - DataSource Aggregate Root 저장
- `delete(dataSource: DataSource): Promise<void>`
  - DataSource 삭제
- `findById(id: string): Promise<DataSource | null>`
  - ID로 DataSource 조회
- `findByName(name: string): Promise<DataSource | null>`
  - 이름으로 DataSource 조회 (고유성 검증용)
- `findAll(filter?: { isActive?: boolean }): Promise<DataSource[]>`
  - 필터링된 DataSource 목록 조회

### 7.5 Repository 4: IPlanLimitRepository

**Aggregate Root**: PlanLimit

**주요 메서드**:

- `save(planLimit: PlanLimit): Promise<void>`
  - PlanLimit Aggregate Root 저장
- `findByPlanType(planType: PlanType): Promise<PlanLimit | null>`
  - 플랜 유형으로 PlanLimit 조회
- `findAll(): Promise<PlanLimit[]>`
  - 모든 PlanLimit 조회
- `findHistoryByPlanType(planType: PlanType): Promise<PlanLimit[]>`
  - 플랜별 변경 이력 조회 (버전 관리)

### 7.6 Repository 5: ITemplateRepository

**Aggregate Root**: Template

**주요 메서드**:

- `save(template: Template): Promise<void>`
  - Template Aggregate Root 저장
- `delete(template: Template): Promise<void>`
  - Template 삭제
- `findById(id: string): Promise<Template | null>`
  - ID로 Template 조회
- `findAll(filter?: TemplateFilter): Promise<Template[]>`
  - 필터링된 Template 목록 조회
- `countByCategoryCode(categoryCode: string): Promise<number>`
  - 카테고리별 Template 수 조회 (CategoryDeletionPolicy용)

### 7.7 Repository 6: ICategoryRepository

**Aggregate Root**: Category

**주요 메서드**:

- `save(category: Category): Promise<void>`
  - Category Aggregate Root 저장
- `delete(category: Category): Promise<void>`
  - Category 삭제
- `findByCode(code: string): Promise<Category | null>`
  - 코드로 Category 조회
- `findAll(filter?: CategoryFilter): Promise<Category[]>`
  - 필터링된 Category 목록 조회
- `findMaxOrder(type: CategoryType): Promise<number>`
  - 카테고리 유형별 최대 순서 값 조회 (순서 관리용)

### 7.8 Repository 7: IReportRepository

**Aggregate Root**: Report

**주요 메서드**:

- `save(report: Report): Promise<void>`
  - Report Aggregate Root 저장
- `findById(id: string): Promise<Report | null>`
  - ID로 Report 조회
- `findAll(filter?: ReportFilter): Promise<Report[]>`
  - 필터링된 Report 목록 조회 (상태, 신고 사유 등)
- `findByDashboardId(dashboardId: string): Promise<Report[]>`
  - 대시보드별 신고 목록 조회
- `findPendingReports(): Promise<Report[]>`
  - 대기 중인 신고 목록 조회 (SLA 모니터링용)

### 7.9 Repository 8: IUserViolationRepository

**Aggregate Root**: UserViolation

**주요 메서드**:

- `save(userViolation: UserViolation): Promise<void>`
  - UserViolation Aggregate Root 저장
- `findByUserId(userId: string): Promise<UserViolation | null>`
  - 사용자별 위반 이력 조회
- `findAll(filter?: UserViolationFilter): Promise<UserViolation[]>`
  - 필터링된 위반 이력 목록 조회
- `findActiveSanctions(): Promise<UserViolation[]>`
  - 활성 제재 목록 조회 (만료 처리용)

### 7.10 Repository 9: IActivityLogRepository

**특수 목적**: 감사 로그 전용 Repository

**주요 메서드**:

- `save(log: ActivityLog): Promise<void>`
  - ActivityLog 저장 (트랜잭션 내)
- `saveIndependent(log: ActivityLog): Promise<void>`
  - ActivityLog 별도 트랜잭션으로 저장 (롤백 시에도 로그 보존)
- `findByUserId(userId: string, limit?: number): Promise<ActivityLog[]>`
  - 사용자별 활동 로그 조회
- `findByDateRange(startDate: Date, endDate: Date): Promise<ActivityLog[]>`
  - 기간별 활동 로그 조회

**설계 결정**:

- 감사 로그는 AuditLoggingDecorator 패턴으로 보장
- 트랜잭션 실패 시에도 로그는 별도 트랜잭션으로 보존 (saveIndependent)

### 7.11 트랜잭션 경계: IUnitOfWork

**목적**: 트랜잭션 관리 및 여러 Repository 조율

**주요 메서드**:

- `begin(): Promise<void>` - 트랜잭션 시작
- `commit(): Promise<void>` - 트랜잭션 커밋
- `rollback(): Promise<void>` - 트랜잭션 롤백

**Repository 접근**:

- `indicators: IIndicatorRepository`
- `users: IUserRepository`
- `dataSources: IDataSourceRepository`
- `planLimits: IPlanLimitRepository`
- `templates: ITemplateRepository`
- `categories: ICategoryRepository`
- `reports: IReportRepository`
- `userViolations: IUserViolationRepository`
- `activityLogs: IActivityLogRepository`

**사용 패턴**:

- Use Case에서 UnitOfWork를 통해 여러 Repository 접근
- 트랜잭션 내에서 모든 작업 수행
- 성공 시 commit, 실패 시 rollback

### 7.12 읽기 전용 Query Repository (CQRS 패턴)

**목적**: 복잡한 조회 및 성능 최적화

**예시**: ICustomDataPointQueryRepository

**주요 메서드**:

- `findByDateRange(indicatorId: string, startDate: Date, endDate: Date): Promise<CustomDataPointQueryModel[]>`
  - 날짜 범위로 데이터 포인트 조회 (JOIN, 집계 포함)
- `findByIndicatorIdPaginated(indicatorId: string, page: number, pageSize: number): Promise<{ items: CustomDataPointQueryModel[], total: number }>`
  - 페이징 조회
- `getStatistics(indicatorId: string): Promise<DataPointStatistics>`
  - 통계 조회 (count, min, max, avg, latestDate)

**Query Model**: DTO 형태의 읽기 전용 모델

**설계 결정**:

- 쓰기 작업은 Aggregate Root를 통해서만
- 읽기 작업은 Query Repository로 성능 최적화
- CQRS 패턴으로 읽기/쓰기 분리

---

## 8. Aggregate 상세 설계

### 8.1 Indicator Aggregate 상세

**Aggregate Root**: Indicator

**속성**:

- indicatorId: string (UUID)
- name: string
- description: string
- source: DataSourceType (KOSIS, ECOS, OECD, CUSTOM)
- dataSourceId: string (DataSource 참조)
- categoryCode: string (Category 참조)
- apiParams: Record<string, any>
- customDataPoints: CustomDataPoint[] (CUSTOM 소스만)
- createdBy: string
- createdAt: Date
- updatedBy: string
- updatedAt: Date

**불변 조건**:

- source와 dataSourceId는 유효해야 함
- CUSTOM 소스만 customDataPoints를 가질 수 있음
- customDataPoints의 date는 중복될 수 없음
- categoryCode는 유효한 Category를 참조해야 함

**도메인 메서드**:

- `update(name, description, categoryCode)`
- `updateApiParams(newParams)` - 재탐색 기능
- `addDataPoint(date, value, addedBy)` - CUSTOM 소스만
- `updateDataPoint(date, newValue, updatedBy)`
- `deleteDataPoint(date, deletedBy)`
- `delete(deletedBy, authPolicy)` - 정책 검증 포함

**내부 엔티티: CustomDataPoint**

**속성**:

- dataPointId: string (UUID)
- date: Date
- value: number
- createdBy: string
- createdAt: Date
- updatedBy: string
- updatedAt: Date

**불변 조건**:

- date는 동일 Indicator 내에서 중복 불가
- value는 숫자여야 함

**생명주기**: Indicator와 함께 생성/삭제 (Cascade Delete)

### 8.2 User Aggregate 상세

**Aggregate Root**: User

**속성**:

- userId: string (UUID)
- email: string
- name: string
- role: UserRole (admin, user)
- status: UserStatus (active, inactive)
- createdAt: Date
- updatedAt: Date

**불변 조건**:

- email은 유효한 이메일 형식이어야 함
- role은 admin 또는 user여야 함

**도메인 메서드**:

- `changePlanManually(newPlan, reason, expiresAt, changedBy)` - 플랜 수동 변경
- `activateAccount(reason, changedBy)`
- `deactivateAccount(reason, changedBy)`

**참조 관계**:

- Subscription (별도 Unit) - userId로 참조
- 실제 Subscription 변경은 Subscription Unit 호출

### 8.3 DataSource Aggregate 상세

**Aggregate Root**: DataSource

**속성**:

- dataSourceId: string (UUID)
- name: string
- baseUrl: string
- encryptedApiKey: EncryptedApiKey (Value Object)
- isActive: boolean
- createdBy: string
- createdAt: Date
- updatedBy: string
- updatedAt: Date

**불변 조건**:

- name은 고유해야 함
- baseUrl은 유효한 URL 형식이어야 함
- API Key는 반드시 암호화되어 저장되어야 함

**도메인 메서드**:

- `updateApiKey(newApiKey, updatedBy)`
- `activate(changedBy)`
- `deactivate(changedBy, deactivationPolicy)` - 정책 검증 포함

### 8.4 PlanLimit Aggregate 상세

**Aggregate Root**: PlanLimit

**속성**:

- planType: PlanType (Free, Pro)
- limits: Record<string, number> (예: { maxDashboards: 10, maxWidgets: 20 })
- price: Price (Value Object)
- expiresAt: Date | null
- updatedBy: string
- updatedAt: Date

**불변 조건**:

- planType은 Free 또는 Pro여야 함
- limits의 값은 0 이상이어야 함
- price.amount는 0 이상이어야 함

**도메인 메서드**:

- `updateLimit(limitKey, newValue, expiresAt, updatedBy)`
- `updatePrice(newPrice, updatedBy)`
- `addNewLimit(limitKey, value, expiresAt, updatedBy)`

### 8.5 Template Aggregate 상세

**Aggregate Root**: Template

**속성**:

- templateId: string (UUID)
- name: string
- description: string
- categoryCode: string (Category 참조)
- widgetCount: number
- isActive: boolean
- createdBy: string
- createdAt: Date
- updatedBy: string
- updatedAt: Date

**불변 조건**:

- name은 유효해야 함
- categoryCode는 유효한 Category를 참조해야 함
- widgetCount는 0 이상이어야 함

**도메인 메서드**:

- `update(name, description, categoryCode, updatedBy)`
- `activate(changedBy)`
- `deactivate(changedBy)`

### 8.6 Category Aggregate 상세

**Aggregate Root**: Category

**속성**:

- categoryCode: string (불변 식별자)
- name: string
- type: CategoryType (indicator, template)
- order: number
- isActive: boolean
- createdBy: string
- createdAt: Date
- updatedBy: string
- updatedAt: Date

**불변 조건**:

- categoryCode는 고유해야 함
- type은 indicator 또는 template이어야 함
- 동일 type 내에서 order는 중복될 수 없음

**도메인 메서드**:

- `update(name, updatedBy)`
- `reorder(newOrder, reorderedBy)` - 순서 중복 검증
- `activate(changedBy)`
- `deactivate(changedBy)`
- `delete(deletedBy, deletionPolicy)` - 정책 검증 포함

### 8.7 Report Aggregate 상세

**Aggregate Root**: Report

**속성**:

- reportId: string (UUID)
- dashboardId: string (Dashboard 참조)
- reportedBy: string (익명 처리 가능)
- reportReason: ReportReason (investment_solicitation, fraud, spam, other)
- reportDescription: string
- status: ReportStatus (pending, in_review, resolved)
- reviewedBy: string | null
- reviewStartedAt: Date | null
- resolutionType: ResolutionType | null (warning, deletion, suspension, dismissed)
- resolutionReason: string | null
- suspensionDuration: number | null (시간 단위)
- resolvedBy: string | null
- resolvedAt: Date | null
- createdAt: Date

**불변 조건**:

- reportReason은 열거형 값이어야 함
- 조치 실행 시 resolutionReason이 반드시 기록되어야 함
- resolutionType이 suspension인 경우 suspensionDuration이 필수

**도메인 메서드**:

- `startReview(reviewedBy)` - 검토 시작
- `resolve(resolutionType, resolutionReason, suspensionDuration, resolvedBy)` - 조치 실행

**상태 전이**:

- pending → in_review (startReview 호출 시)
- in_review → resolved (resolve 호출 시)

### 8.8 UserViolation Aggregate 상세

**Aggregate Root**: UserViolation

**속성**:

- userId: string (User 참조)
- violations: ViolationRecord[] (위반 이력 목록)
  - reportId: string
  - violationType: ViolationType
  - dashboardId: string
  - recordedAt: Date
- cumulativeViolationCount: number
- sanctions: SanctionRecord[] (제재 이력 목록)
  - sanctionType: SanctionType (warning, temporary_suspension, permanent_ban)
  - reason: string
  - isAutomatic: boolean
  - appliedBy: string | null
  - expiresAt: Date | null
  - appliedAt: Date
- activeSanction: SanctionRecord | null (현재 활성 제재)

**불변 조건**:

- 위반 이력은 시간 순서대로 누적되어야 함
- sanctionType이 temporary_suspension인 경우 expiresAt이 필수

**도메인 메서드**:

- `recordViolation(reportId, violationType, dashboardId)` - 위반 이력 추가
- `applySanction(sanctionType, reason, isAutomatic, appliedBy, expiresAt)` - 제재 적용
- `expireSanction()` - 제재 만료 (스케줄러 호출)

**비즈니스 규칙**:

- 단계적 제재 시스템 자동 적용 (StepwiseSanctionPolicy)
- temporary_suspension은 48시간 후 자동 만료

### 8.9 ActivityLog (감사 로그)

**특수 목적 Entity**: 감사 로그 전용

**속성**:

- logId: string (UUID)
- userId: string (관리자 ID)
- action: string (Use Case 이름)
- status: LogStatus (success, failed)
- details: any | null (작업 세부 정보)
- error: string | null (실패 사유)
- ipAddress: string
- userAgent: string
- executionTime: number (밀리초)
- timestamp: Date

**불변 조건**:

- 모든 속성 불변 (감사 로그는 변경 불가)
- 민감 정보는 자동 마스킹 (password, apiKey, token, secret 등)

**생명주기**: 생성 → 영구 보관 (삭제 없음)

**저장 메커니즘**:

- AuditLoggingDecorator 패턴으로 모든 Use Case에 자동 적용
- 성공 로그: 트랜잭션 내 저장 (ActivityLogRepository.save)
- 실패 로그: 별도 트랜잭션 저장 (ActivityLogRepository.saveIndependent) - 롤백 시에도 보존

---

## 9. 비즈니스 규칙 및 제약사항 요약

### 9.1 지표 관리 (US6.1, US6.2)

1. **지표 등록**:
   - 4가지 소스 지원: KOSIS, ECOS, OECD, CUSTOM
   - 유효한 Category 참조 필수
   - API 파라미터는 유연한 구조 (Record<string, any>)

2. **지표 수정**:
   - 메타데이터 수정 가능 (name, description, categoryCode)
   - API 파라미터 재탐색 및 갱신 지원 (재배포 불필요)

3. **지표 삭제**:
   - 위젯에서 사용 중인 지표는 삭제 불가 (IndicatorDeletionPolicy)
   - CUSTOM 소스 지표 삭제 시 재인증 필요
   - CUSTOM 소스 지표 삭제 시 CustomDataPoint Cascade Delete

4. **연결 테스트**:
   - 응답 시간 > 5초이면 경고
   - 실패 시 원인 표시

### 9.2 사용자 관리 (US6.3)

1. **플랜 변경**:
   - 변경 사유 필수 기록 (ChangeReason Value Object)
   - 만료일 설정 가능 (null이면 영구 변경)
   - 실제 Subscription 변경은 Subscription Unit에서 처리

2. **계정 관리**:
   - 활성화/비활성화 시 사유 필수 기록
   - 비활성화 시 로그인 차단 (Authentication Unit과 연동)

### 9.3 데이터 소스 관리 (US6.4)

1. **데이터 소스 추가**:
   - 고유한 name 필수
   - API Key는 암호화 저장 (EncryptedApiKey Value Object)

2. **데이터 소스 비활성화**:
   - 활성 지표가 있어도 비활성화 가능하지만 경고 표시
   - 데이터 수집 실패 위험 안내

### 9.4 플랜 제한 관리 (US6.5)

1. **제한값 수정**:
   - 즉시 반영 (재배포 불필요)
   - 적용 기간 설정 가능 (null이면 영구 적용)
   - 변경 이력 조회 가능

2. **새 제한 항목 추가**:
   - 동적 추가 가능
   - 플랜별 제한 구분

### 9.5 템플릿 관리 (US6.6)

1. **템플릿 생성**:
   - 유효한 Category 참조 필수
   - widgetCount 0 이상

2. **템플릿 활성화/비활성화**:
   - 활성 템플릿만 사용자에게 노출

### 9.6 카테고리 관리 (US6.7)

1. **카테고리 생성**:
   - 고유한 categoryCode 필수 (불변)
   - type은 indicator 또는 template

2. **카테고리 삭제**:
   - 사용 중인 카테고리는 삭제 불가 (CategoryDeletionPolicy)
   - 대안: 재할당 후 삭제 또는 비활성화

3. **카테고리 순서 변경**:
   - 동일 type 내에서 order 중복 불가

### 9.7 수동 데이터 관리 (US6.8)

1. **CustomDataPoint 추가**:
   - CUSTOM 소스 지표만 가능
   - date 중복 불가 (동일 Indicator 내)

2. **CSV 일괄 업로드**:
   - 데이터 검증 필수
   - 미리보기 테이블 표시 후 확인
   - 하나의 트랜잭션으로 처리

3. **CustomDataPoint 삭제**:
   - Indicator 삭제 시 Cascade Delete

### 9.8 신고 관리 (US6.9)

1. **신고 접수**:
   - Dashboard Unit의 `DashboardReported` 이벤트 구독
   - 신고자 정보 익명성 보장

2. **신고 검토**:
   - 48시간 내 1차 검토 (SLA)
   - 대시보드 원본 내용 전체 확인
   - 작성자 이전 위반 내역 조회

3. **조치 실행**:
   - 4가지 조치 유형: warning, deletion, suspension, dismissed
   - 조치 사유 필수 기록
   - 작성자 및 신고자에게 결과 통보

4. **조치 내역**:
   - ActivityLog에 자동 기록
   - 영구 보관 (법적 분쟁 대비)

### 9.9 위반 사용자 관리 (US6.10)

1. **위반 이력 기록**:
   - `ReportResolved` 이벤트 구독 후 자동 기록
   - 위반 유형별 분류 (investment_solicitation, fraud, spam, other)

2. **단계적 제재 시스템**:
   - 1회 위반: 경고 (warning)
   - 2회 위반: 48시간 게시 제한 (temporary_suspension)
   - 3회 이상: 계정 영구 정지 (permanent_ban)

3. **제재 적용**:
   - 자동 제재 (isAutomatic = true): 단계적 제재 시스템
   - 수동 제재 (isAutomatic = false): 관리자 판단으로 즉시 정지

4. **제재 만료**:
   - temporary_suspension은 48시간 후 자동 만료
   - 스케줄러가 만료 처리

5. **제재 내역**:
   - 사용자에게 통보 (위반 사유, 제재 기간, 이의 제기 방법)
   - 영구 보관

### 9.10 자동 탐지 (US6.11)

1. **자동 스캔**:
   - 일일 배치 실행 (신규/수정 대시보드 대상)
   - 위험 패턴 탐지 (키워드 룰 엔진)

2. **위험 패턴**:
   - 특정 종목명 + 행동 유도
   - 수익 보장 표현
   - 타이밍 단정
   - 외부 유료 서비스 링크

3. **자동 조치**:
   - 높음 (high): 즉시 비공개 + 작성자 알림
   - 중간 (medium): 검토 대기열 추가
   - 낮음 (low): 로그만 기록, 공개 유지

4. **오탐 처리**:
   - 관리자가 "문제 없음" 판정 가능
   - 오탐 패턴 학습 (재탐지 방지)
   - Dashboard Unit이 대시보드 복원

5. **탐지 룰 관리**:
   - 키워드 룰 버전 관리
   - 언제든 수정 가능
   - 정규표현식 기반

### 9.11 보안 및 감사

1. **관리자 권한 검증**:
   - 모든 관리 작업은 admin 역할 필수
   - 민감한 작업은 재인증 필요 (5분 이내 로그인 확인)

2. **감사 로그**:
   - 모든 관리자 작업 자동 기록 (AuditLoggingDecorator)
   - 성공/실패 모두 기록
   - 민감 정보 자동 마스킹 (password, apiKey, token, secret)
   - 트랜잭션 실패 시에도 로그 보존 (별도 트랜잭션)

3. **API Key 보안**:
   - 암호화 저장 (EncryptedApiKey Value Object)
   - 접근 로그 기록
   - 토글 방식 표시/숨김

4. **신고자 보호**:
   - 신고자 정보 익명성 보장
   - 신고 내역 영구 보관

---

## 10. Aggregate 간 참조 관계

### 10.1 참조 방식

**원칙**: Aggregate 간에는 ID로만 참조 (느슨한 결합)

**예외**: 없음 (모든 Aggregate는 ID 참조)

### 10.2 참조 관계 다이어그램

```
Indicator
  ├─ references: DataSource (dataSourceId)
  ├─ references: Category (categoryCode)
  └─ contains: CustomDataPoint[] (내부 Entity)

User
  └─ references: Subscription (별도 Unit, userId로 참조)

DataSource
  └─ (참조 없음)

PlanLimit
  └─ (참조 없음)

Template
  └─ references: Category (categoryCode)

Category
  └─ (참조 없음)

Report
  ├─ references: Dashboard (별도 Unit, dashboardId로 참조)
  └─ references: User (reportedBy, reviewedBy, resolvedBy)

UserViolation
  ├─ references: User (userId)
  └─ references: Report (reportId)

ContentDetection (도메인 개념, Aggregate 아님)
  └─ references: Dashboard (별도 Unit, dashboardId로 참조)
```

### 10.3 참조 무결성

**도메인 레이어**:

- ID 참조만 유지
- 실제 데이터 조회는 Application Layer에서 처리

**Application Layer**:

- Use Case에서 여러 Aggregate 조율
- 참조 무결성 검증 (존재 여부 확인)

**예시**:

- Indicator 생성 시 categoryCode가 유효한 Category를 참조하는지 확인
- Report 생성 시 dashboardId가 유효한 Dashboard를 참조하는지 확인 (Dashboard Unit 호출)

---

## 11. 결론

### 11.1 도메인 모델 요약

**Admin Console Unit**은 관리자 전용 기능을 제공하며, 다음과 같이 설계되었습니다:

1. **단일 바운디드 컨텍스트**: "Admin Console"
2. **9개의 독립 Aggregate**: Indicator, User, DataSource, PlanLimit, Template, Category, Report, UserViolation + ActivityLog (감사 로그)
3. **31개의 도메인 이벤트**: 비즈니스 상태 변경을 이벤트로 전파
4. **5개의 도메인 서비스**: 여러 Aggregate에 걸친 비즈니스 로직 캡슐화
5. **6개의 정책**: 비즈니스 규칙 및 제약사항 정의
6. **9개의 Repository 인터페이스**: Aggregate Root 단위 저장소

### 11.2 주요 설계 결정

1. **CustomDataPoint는 Indicator의 내부 Entity**
   - 별도 Aggregate가 아님
   - Indicator와 생명주기 공유 (Cascade Delete)

2. **Subscription은 별도 Unit**
   - Admin Console은 플랜 변경 요청 및 사유 기록만 담당
   - 실제 Subscription 변경은 Subscription Unit에서 처리

3. **감사 로그는 AuditLoggingDecorator 패턴**
   - 도메인 이벤트가 아닌 횡단 관심사로 처리
   - 트랜잭션 실패 시에도 로그 보존 (별도 트랜잭션)

4. **apiParams는 유연한 구조 (Record<string, any>)**
   - Value Object로 도입하지 않음
   - 외부 API 스펙 변경에 즉시 대응 (재배포 불필요)
   - "연결 테스트" 기능으로 유효성 검증

5. **ContentDetection은 별도 Aggregate가 아님**
   - 자동 탐지 결과는 이벤트로 처리 (DashboardFlagged, FlaggedContentReviewed)
   - Dashboard Unit이 위험도에 따라 자동 조치

### 11.3 비즈니스 규칙 강조

1. **데이터 무결성**:
   - 사용 중인 카테고리는 삭제 불가
   - 위젯에서 사용 중인 지표는 삭제 불가

2. **보안 및 감사**:
   - 모든 관리자 작업 자동 기록
   - 민감한 작업은 재인증 필요
   - API Key 암호화 저장

3. **단계적 제재 시스템**:
   - 1회 경고 → 2회 48시간 정지 → 3회 영구 정지
   - 자동 제재와 수동 제재 구분

4. **신고 대응 SLA**:
   - 48시간 내 1차 검토
   - 조치 내역 영구 보관 (법적 분쟁 대비)

### 11.4 다음 단계

**논리적 설계 (Logical Design)**로 진행:

- Clean Architecture 레이어 매핑
- Supabase 스키마 설계
- Next.js API Routes 설계
- EventBus 구현 방식 선택
- 배포 아키텍처 설계

**구현 (Implementation)**:

- Phase 1: Foundation (완료)
- Phase 2: Core Aggregates (Indicators & Categories)
- Phase 3: Templates & Data Sources
- Phase 4: User Management
- Phase 5: Content Moderation (Reports, Violations, Detection)
- Phase 6: Advanced Features
- Phase 7: Testing & Optimization
- Phase 8: Deployment

---

**문서 종료**
