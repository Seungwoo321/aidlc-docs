# 학습 콘텐츠 자동화 시스템: 시스템 아키텍처 선정 보고서

**작성일**: 2025-10-16
**개발 방법론**: AI-DLC (AI-Driven Development Lifecycle)
**목적**: 7개 AI 에이전트 기반 학습 콘텐츠 자동화 시스템에 최적의 시스템 아키텍처 선정

---

## Executive Summary

### 보고서의 목적

본 보고서는 **AI-DLC 방법론을 적용하여** 학습 콘텐츠 자동화 시스템을 개발할 때, **가장 적합한 시스템 아키텍처**를 선정하기 위해 작성되었습니다.

**중요한 구분**:
- **개발 방법론**: AI-DLC (확정)
- **시스템 아키텍처**: 본 보고서의 비교 대상
- **설계 방법**: 아키텍처 선정 후 결정

```
┌──────────────────────────────────────────────────────────┐
│  개발 방법론 레이어 (어떻게 개발할 것인가)                 │
│  AI-DLC (고정)                                           │
│  - Inception: 의도 → 유닛 분해 → 계획                    │
│  - Construction: 도메인 설계 → 논리 설계 → 코드 생성     │
│  - Operations: 배포 → 모니터링 → 유지보수                │
└──────────────────────────────────────────────────────────┘
                         ↓ (적용)
┌──────────────────────────────────────────────────────────┐
│  시스템 아키텍처 레이어 (시스템을 어떻게 구조화할 것인가)  │
│  Pipeline vs Layered vs Event-Driven vs ... (본 보고서)  │
└──────────────────────────────────────────────────────────┘
                         ↓ (적용)
┌──────────────────────────────────────────────────────────┐
│  설계 방법 레이어 (어떻게 설계할 것인가)                  │
│  DDD 경량화 vs 기타 설계 방법 (아키텍처 선정 후 결정)     │
└──────────────────────────────────────────────────────────┘
```

### 분석 대상 시스템

**시스템 구조**:
- **7개 AI 에이전트**: content-initiator → overview-writer → concepts-writer → visualization-writer → practice-writer → quiz-writer → content-validator
- **입력**: category.yaml (토픽 메타데이터)
- **출력**: 5개 섹션으로 구성된 학습 콘텐츠 마크다운 (Overview, Core Concepts, Code Patterns, Experiments, Quiz)
- **데이터 전달**: Work Status Markers (HTML 주석 기반)
- **오케스트레이션**: Bash 스크립트 (`content-generator-v6.sh`)

**시스템 특성**:
- 완전 자동화 (콘텐츠 생성 중 인간 개입 없음)
- 순차 의존성 (각 에이전트는 이전 에이전트의 출력 필요)
- 파일 기반 상태 관리 (마크다운 파일 + HTML 주석)
- 품질 검증: 파서 테스트 (test/test-*.mjs)

---

## 1. 현재 시스템 심층 분석

### 1.1 시스템 구조 분석

#### 에이전트 체인
```
category.yaml
    ↓
[content-initiator]  - Work Status Markers 초기화
    ↓
[overview-writer]    - Overview 섹션 생성
    ↓
[concepts-writer]    - Core Concepts 섹션 생성 (3단계 난이도)
    ↓
[visualization-writer] - React 시각화 컴포넌트 생성
    ↓
[practice-writer]    - Code Patterns + Experiments 생성
    ↓
[quiz-writer]        - Quiz 섹션 생성
    ↓
[content-validator]  - 품질 검증 (100점 만점)
    ↓
마크다운 파일 완성
```

#### 데이터 흐름

**입력**:
- `category.yaml`: 토픽 메타데이터 (제목, 설명, 난이도, 카테고리)
- 이전 에이전트가 작성한 마크다운 섹션

**처리**:
- 각 에이전트는 **마크다운 파일**을 읽고, 자신의 섹션을 추가
- **Work Status Markers** (HTML 주석)로 작업 상태 기록
  ```html
  <!-- CURRENT_AGENT: overview-writer -->
  <!-- PROGRESS: pending -->
  <!-- HANDOFF LOG:
  [DONE] content-initiator: 초기화 완료
  -->
  ```

**출력**:
- 단일 마크다운 파일 (5개 섹션 포함)
- React 시각화 컴포넌트 (선택적)

#### 의존성 분석

**순차 의존성 (Strong Sequential Dependency)**:
- content-initiator → overview-writer: 파일 초기화 필요
- overview-writer → concepts-writer: Overview 섹션 참조 필요
- concepts-writer → visualization-writer: Concepts 섹션에서 시각화 대상 식별
- visualization-writer → practice-writer: 시각화 통합 확인 필요
- practice-writer → quiz-writer: 실습 내용 기반 퀴즈 생성
- quiz-writer → content-validator: 전체 콘텐츠 검증

**데이터 의존성 특징**:
- 각 에이전트는 **누적된 콘텐츠**를 읽음 (이전 모든 섹션)
- 이전 섹션의 품질이 다음 섹션에 영향
- **재시작 불가능성**: 중간 단계 실패 시 처음부터 재생성 필요

#### 상태 관리 메커니즘

**Work Status Markers**:
```html
<!-- WORK STATUS MARKERS -->
<!-- CURRENT_AGENT: concepts-writer -->
<!-- PROGRESS: in-progress -->
<!-- STARTED: 2025-10-16 14:30 -->
<!-- UPDATED: 2025-10-16 14:45 -->
<!-- HANDOFF LOG:
[DONE] content-initiator: 초기화 - 2025-10-16 14:25
[DONE] overview-writer: Overview 완료 - 2025-10-16 14:35
-->
```

**특징**:
- 파일 내장 상태 관리 (마크다운 HTML 주석)
- 외부 DB 없음 (자기완결적)
- 텍스트 파싱 기반 (정규표현식)

### 1.2 현재 시스템의 강점

1. **단순성 (Simplicity)**
   - 외부 의존성 최소 (파일 시스템만)
   - 이해하기 쉬운 순차 흐름
   - 디버깅 용이 (마크다운 파일로 모든 상태 확인 가능)

2. **자기완결성 (Self-Contained)**
   - 마크다운 파일 = 데이터 + 메타데이터 + 상태
   - 버전 관리 용이 (Git으로 전체 히스토리 추적)
   - 이식성 높음 (파일만 있으면 어디서든 실행)

3. **추적 가능성 (Traceability)**
   - Work Status Markers로 전체 작업 히스토리 기록
   - HANDOFF LOG로 에이전트 간 핸드오프 추적
   - 파서 테스트로 구조적 품질 검증

4. **인간 가독성 (Human Readability)**
   - 마크다운 형식으로 인간이 직접 읽고 수정 가능
   - Work Status Markers도 HTML 주석으로 투명하게 노출
   - 디버깅 시 파일만 열면 전체 상태 파악 가능

### 1.3 현재 시스템의 한계

1. **순차 처리만 가능 (Sequential Only)**
   - 병렬 처리 불가능 (7개 에이전트가 순차 실행)
   - 전체 소요 시간 = 각 에이전트 소요 시간의 합
   - 예상 시간: 50-80분 (1개 콘텐츠)

2. **재시작 메커니즘 부재 (No Restart Mechanism)**
   - 중간 실패 시 처음부터 재실행
   - 부분 완료 상태 복구 어려움
   - 시간 낭비 (이미 완료된 에이전트도 재실행)

3. **암묵적 계약 (Implicit Contracts)**
   - 에이전트 간 입출력 형식이 명시적이지 않음
   - 에이전트 프롬프트에 I/O 명세 부재
   - 새 에이전트 추가 시 통합 방법 모호

4. **상태 관리 취약성 (State Management Fragility)**
   - HTML 주석 파싱 오류에 취약
   - Work Status Markers 형식 불일치 가능
   - 동시성 제어 없음 (파일 잠금만)

5. **품질 측정 부재 (No Quality Metrics)**
   - 파서 테스트는 Pass/Fail만 제공
   - 정량적 품질 점수 없음
   - 개선 우선순위 결정 근거 부족

---

## 2. 시스템 아키텍처 후보 비교

### 2.1 Pipeline Architecture (Pipes and Filters)

#### 개요
Pipes and Filters는 데이터 흐름 중심의 아키텍처 패턴으로, **Filter**(독립적 처리 컴포넌트)와 **Pipe**(데이터 전달 메커니즘)로 구성됩니다.

#### 구조
```
Input → [Filter 1] → Pipe → [Filter 2] → Pipe → ... → [Filter N] → Output
```

**핵심 개념**:
- **Filter**: 입력을 받아 처리하고 출력하는 독립적 컴포넌트
- **Pipe**: Filter 간 데이터 전달 채널
- **Sequential Processing**: 순차 또는 병렬 처리 가능
- **Transformation**: 각 Filter가 데이터를 변환

#### 현재 시스템과의 매핑

| Pipeline 개념 | 현재 시스템 |
|--------------|------------|
| Filter | 7개 AI 에이전트 |
| Pipe | Work Status Markers + 마크다운 파일 |
| Input | category.yaml |
| Output | 완성된 마크다운 파일 |
| Sequential Processing | Bash 스크립트 순차 실행 |

#### 장점

1. **자연스러운 매핑**
   - 현재 시스템이 이미 암묵적 Pipeline 구조
   - 에이전트 = Filter, 파일 = Pipe
   - 설계 명시화만으로 개선 가능 (대규모 리팩토링 불필요)

2. **명확한 데이터 흐름**
   - 단방향 데이터 흐름 (category.yaml → 완성된 파일)
   - 각 Filter의 입출력 명확
   - 디버깅 용이 (특정 Filter의 출력 확인)

3. **독립적 Filter 개선**
   - 각 Filter를 독립적으로 개선 가능
   - 다른 Filter에 영향 없음 (I/O 계약만 유지)
   - 테스트 용이 (Filter 단위 테스트)

4. **확장 가능성**
   - 새로운 Filter 추가 용이
   - 기존 Pipeline에 삽입 또는 추가
   - 조건부 Filter 실행 가능 (예: visualization-writer 건너뛰기)

5. **AI-DLC Construction 단계와 정렬**
   - Construction: 도메인 설계 → 논리 설계 → 코드 생성
   - Pipeline: Filter 0 → Filter 1 → ... → Filter N
   - 각 Filter가 Construction의 한 단계 수행

#### 단점

1. **순차 의존성 고착화**
   - Pipeline은 기본적으로 순차 처리
   - 병렬 처리는 별도 설계 필요 (Branch Pipeline)
   - 전체 소요 시간 증가

2. **중간 상태 관리 복잡성**
   - Pipe 메커니즘 설계 필요
   - Work Status Markers 표준화 필요
   - 재시작 메커니즘 구현 복잡

3. **Filter 간 결합도**
   - 각 Filter가 이전 Filter의 출력 형식에 의존
   - 출력 형식 변경 시 하류 Filter 모두 영향
   - 계약 관리 부담

#### AI-DLC 적용 방법

**Inception 단계**:
- 의도: "학습 콘텐츠 자동화 시스템 개선"
- 유닛 분해:
  - Unit 1: Filter 계약 명시화
  - Unit 2: Pipe 메커니즘 설계
  - Unit 3: 에이전트 프롬프트 개선
  - Unit 4: 오케스트레이션 개선

**Construction 단계**:
- 도메인 설계: Filter 계약 문서 (입력/출력/품질 기준)
- 논리 설계: Pipe 메커니즘 (Work Status Markers 표준, 재시작 알고리즘)
- 코드 생성: 에이전트 프롬프트 개선, 스크립트 개선

**설계 방법 제안**:
- DDD 경량화: Filter를 Bounded Context로, Pipe를 Integration Event로 매핑
- 전술적 패턴 최소화 (Aggregate, Repository 불필요)
- 유비쿼터스 언어 활용 (Filter, Pipe, Work Status Markers)

#### 종합 평가

**AI-DLC 적합성**: ⭐⭐⭐⭐⭐ (5/5)
- Construction 단계와 자연스럽게 매핑
- 유닛 분해 용이 (Filter 단위)
- 도메인 설계 = Filter 계약, 논리 설계 = Pipe 메커니즘

**현재 시스템 적합성**: ⭐⭐⭐⭐⭐ (5/5)
- 이미 암묵적 Pipeline 구조
- 명시화만으로 개선 가능
- 대규모 리팩토링 불필요

**구현 복잡도**: ⭐⭐⭐☆☆ (3/5)
- Filter 계약 명시화: 중간
- Pipe 메커니즘 설계: 중간
- 재시작 메커니즘: 복잡

**확장성**: ⭐⭐⭐⭐☆ (4/5)
- 새 Filter 추가: 쉬움
- 병렬 처리: 별도 설계 필요
- 조건부 실행: 가능

**총점**: 17/20 (85%)

---

### 2.2 Layered Architecture (계층형 아키텍처)

#### 개요
Layered Architecture는 시스템을 **수평 계층**(Horizontal Layers)으로 분리하는 패턴으로, 각 계층이 특정 책임을 담당합니다.

#### 전통적 구조
```
┌─────────────────────────┐
│  Presentation Layer     │ (UI, API)
├─────────────────────────┤
│  Business Logic Layer   │ (도메인 로직)
├─────────────────────────┤
│  Data Access Layer      │ (DB, 파일 I/O)
└─────────────────────────┘
```

#### 현재 시스템에의 적용 시도

**옵션 A: 기능별 계층화**
```
┌─────────────────────────┐
│  Validation Layer       │ (content-validator)
├─────────────────────────┤
│  Content Generation     │ (overview, concepts, practice, quiz)
├─────────────────────────┤
│  Visualization Layer    │ (visualization-writer)
├─────────────────────────┤
│  Infrastructure Layer   │ (content-initiator, 파일 I/O)
└─────────────────────────┘
```

**옵션 B: 책임별 계층화**
```
┌─────────────────────────┐
│  Quality Assurance      │ (content-validator)
├─────────────────────────┤
│  Content Creation       │ (모든 writer 에이전트)
├─────────────────────────┤
│  Data Management        │ (content-initiator, 상태 관리)
└─────────────────────────┘
```

#### 장점

1. **계층별 책임 분리**
   - 각 계층이 명확한 책임
   - 계층 내 응집도 향상
   - 관심사 분리 (Separation of Concerns)

2. **계층 단위 개선**
   - 특정 계층만 개선 가능
   - 다른 계층에 영향 최소화
   - 테스트 용이 (계층 단위 테스트)

3. **표준 패턴**
   - 널리 알려진 패턴
   - 개발자 친숙도 높음
   - 학습 곡선 낮음

#### 단점

1. **순차 의존성과 상충 (Critical Issue)**
   - Layered Architecture는 "상위 계층 → 하위 계층" 호출 가정
   - 현재 시스템: "content-initiator → overview → concepts → ... → validator"
   - 이는 **계층 구조가 아니라 체인 구조**
   - 억지로 계층화하면 개념적 혼란 발생

2. **데이터 흐름 불일치**
   - Layered: 각 계층이 전체 데이터 접근
   - 현재 시스템: 각 에이전트가 누적 데이터만 접근
   - **누적 변환 (Cumulative Transformation)** 특성과 맞지 않음

3. **재사용성 저하**
   - 각 에이전트가 특정 순서에서만 의미 있음
   - overview-writer는 첫 번째에서만 동작
   - 계층 간 독립성 확보 불가

4. **과도한 추상화**
   - 계층화를 위한 계층화 (Over-engineering)
   - 시스템 복잡도 증가
   - 명확한 이점 없음

#### AI-DLC 적용 시 문제

**Inception 단계**:
- 유닛 분해 시 계층별로 나누기 어려움
- 각 에이전트가 독립적 유닛이 아니라 순차 의존적
- 볼트(Bolt) 정의 모호 (계층 단위? 에이전트 단위?)

**Construction 단계**:
- 도메인 설계 시 계층 간 경계 정의 어려움
- 논리 설계 시 계층 간 데이터 흐름 불명확
- 코드 생성 시 계층 간 인터페이스 복잡

**설계 방법**:
- DDD 경량화 적용 어려움 (계층 ≠ Bounded Context)
- 전략적 설계 시 Context Map 그리기 어려움

#### 종합 평가

**AI-DLC 적합성**: ⭐⭐☆☆☆ (2/5)
- Inception 단계: 유닛 분해 어려움
- Construction 단계: 도메인 설계와 불일치
- 순차 흐름과 개념적 불일치

**현재 시스템 적합성**: ⭐⭐☆☆☆ (2/5)
- 순차 의존성과 상충
- 누적 변환 특성과 맞지 않음
- 억지 계층화 필요

**구현 복잡도**: ⭐⭐⭐⭐☆ (4/5)
- 대규모 리팩토링 필요
- 계층 간 인터페이스 설계 복잡
- 개념적 혼란 발생 가능

**확장성**: ⭐⭐⭐☆☆ (3/5)
- 새 에이전트 추가: 계층 결정 필요
- 계층 간 의존성 관리 복잡
- 병렬 처리: 계층 내에서만 가능

**총점**: 11/20 (55%)

**결론**: Layered Architecture는 현재 시스템의 **순차 체인 구조**와 근본적으로 맞지 않음. 계층화를 강제하면 개념적 혼란만 가중.

---

### 2.3 Event-Driven Architecture (이벤트 주도 아키텍처)

#### 개요
Event-Driven Architecture는 **이벤트** 생성, 감지, 소비를 통해 컴포넌트 간 통신하는 패턴입니다.

#### 구조
```
[Producer 1] ──┐
[Producer 2] ──┼──→ [Event Bus] ──┬──→ [Consumer 1]
[Producer 3] ──┘                   ├──→ [Consumer 2]
                                   └──→ [Consumer 3]
```

**핵심 개념**:
- **Event**: 시스템에서 발생한 의미 있는 상태 변화
- **Producer**: 이벤트 발행자
- **Consumer**: 이벤트 구독자
- **Event Bus**: 이벤트 전달 메커니즘
- **Asynchronous**: 비동기 처리

#### 현재 시스템에의 적용 시도

**이벤트 정의**:
```javascript
// Event 1: 파일 초기화 완료
{
  type: "FILE_INITIALIZED",
  filePath: "...",
  timestamp: "...",
  initiator: "content-initiator"
}

// Event 2: Overview 섹션 완료
{
  type: "OVERVIEW_COMPLETED",
  filePath: "...",
  content: "...",
  timestamp: "...",
  writer: "overview-writer"
}

// Event 3: Concepts 섹션 완료
{
  type: "CONCEPTS_COMPLETED",
  filePath: "...",
  content: "...",
  visualizations: [...],
  timestamp: "...",
  writer: "concepts-writer"
}
```

**에이전트 매핑**:
- content-initiator: FILE_INITIALIZED 이벤트 발행
- overview-writer: FILE_INITIALIZED 구독 → OVERVIEW_COMPLETED 발행
- concepts-writer: OVERVIEW_COMPLETED 구독 → CONCEPTS_COMPLETED 발행
- ...

#### 장점

1. **느슨한 결합 (Loose Coupling)**
   - Producer와 Consumer 독립적
   - 에이전트 간 직접 의존성 없음
   - 새 Consumer 추가 용이

2. **비동기 처리 (Asynchronous)**
   - 에이전트 비동기 실행 가능
   - 병렬 처리 용이 (독립적 이벤트)
   - 확장성 향상

3. **이벤트 소싱 (Event Sourcing)**
   - 모든 이벤트 기록 가능
   - 재생 가능 (Replay)
   - 감사 추적 (Audit Trail) 용이

4. **유연성 (Flexibility)**
   - 런타임 동적 구독 가능
   - 이벤트 변환 용이 (Event Transformer)
   - 복잡한 워크플로 구현 가능

#### 단점

1. **순차 의존성과 상충 (Critical Issue)**
   - 현재 시스템: 강한 순차 의존성
   - overview-writer는 반드시 content-initiator 후 실행
   - concepts-writer는 반드시 overview-writer 후 실행
   - **이벤트 순서 보장 필요** → EDA의 장점 상실

2. **최종 일관성 문제 (Eventual Consistency)**
   - EDA는 기본적으로 최종 일관성
   - 현재 시스템: 강한 일관성 필요 (각 섹션이 이전 섹션에 의존)
   - **순서 위반 시 잘못된 콘텐츠 생성**

3. **복잡도 급증 (Complexity Explosion)**
   - Event Bus 인프라 필요 (예: Kafka, RabbitMQ)
   - 이벤트 순서 보장 메커니즘 필요
   - 실패 처리 복잡 (보상 트랜잭션)
   - 디버깅 어려움 (분산 추적 필요)

4. **과도한 설계 (Over-engineering)**
   - 현재 시스템: 단일 마크다운 파일 생성
   - EDA: 마이크로서비스 간 통신에 적합
   - **단순한 순차 처리에 EDA는 과도**

5. **상태 관리 어려움**
   - 현재: 마크다운 파일에 모든 상태
   - EDA: 분산 상태 관리 필요
   - 재시작 시 상태 복원 복잡

#### AI-DLC 적용 시 문제

**Inception 단계**:
- 유닛 분해 시 이벤트 중심으로 나누기 어려움
- 각 에이전트가 독립적이지 않음 (순차 의존)
- 이벤트 정의 복잡 (데이터 포함 vs 참조만)

**Construction 단계**:
- 도메인 설계: 이벤트 스키마 정의 복잡
- 논리 설계: Event Bus 선택, 순서 보장 메커니즘 설계
- 코드 생성: 이벤트 핸들러, 보상 트랜잭션 구현

**설계 방법**:
- DDD 경량화: 이벤트 = Domain Event?
- 하지만 현재 시스템은 도메인 이벤트보다 "단계 완료" 이벤트
- 개념적 불일치

#### 실험적 평가: 병렬 처리 가능성

**가정**: concepts-writer와 practice-writer를 병렬 실행?
- concepts-writer: Overview → Concepts
- practice-writer: Overview → Practice (Concepts 불필요?)

**현실**:
- practice-writer는 Concepts를 참조해야 함 (개념 기반 실습)
- quiz-writer는 모든 섹션 참조 필요
- **진정한 병렬 처리 불가능**

**결론**: 순차 의존성으로 인해 EDA의 핵심 장점(비동기, 병렬) 활용 불가

#### 종합 평가

**AI-DLC 적합성**: ⭐⭐☆☆☆ (2/5)
- Inception 단계: 이벤트 중심 유닛 분해 부적합
- Construction 단계: 복잡도만 증가
- 순차 흐름과 철학적 불일치

**현재 시스템 적합성**: ⭐☆☆☆☆ (1/5)
- 순차 의존성과 근본적 상충
- 비동기 처리 장점 활용 불가
- 과도한 인프라 필요

**구현 복잡도**: ⭐☆☆☆☆ (1/5)
- Event Bus 인프라 필요
- 순서 보장 메커니즘 복잡
- 분산 시스템 복잡도
- 디버깅 및 모니터링 어려움

**확장성**: ⭐⭐⭐⭐☆ (4/5)
- 새 Consumer 추가 용이
- 병렬 처리 가능 (이론적)
- 하지만 현재 시스템에는 불필요

**총점**: 8/20 (40%)

**결론**: Event-Driven Architecture는 현재 시스템의 **강한 순차 의존성** 및 **단순한 처리 흐름**과 근본적으로 맞지 않음. 비동기 처리의 장점을 활용할 수 없으며, 복잡도만 급증.

---

### 2.4 Microservices Architecture (마이크로서비스 아키텍처)

#### 개요
Microservices Architecture는 애플리케이션을 **독립적으로 배포 가능한 작은 서비스**로 분해하는 패턴입니다.

#### 구조
```
[Client] ──→ [API Gateway]
                ↓
    ┌───────────┼───────────┬───────────┐
    ↓           ↓           ↓           ↓
[Service 1] [Service 2] [Service 3] [Service 4]
    ↓           ↓           ↓           ↓
  [DB 1]      [DB 2]      [DB 3]      [DB 4]
```

**핵심 원칙**:
- **Single Responsibility**: 각 서비스가 하나의 비즈니스 기능
- **Independence**: 독립적 배포, 확장, 실패
- **Decentralization**: 분산 데이터 관리
- **API Communication**: HTTP/gRPC/Message Queue

#### 현재 시스템에의 적용 시도

**서비스 매핑**:
```
┌─────────────────────────┐
│ content-initiator-service │ (POST /initialize)
└─────────────────────────┘
          ↓
┌─────────────────────────┐
│ overview-writer-service  │ (POST /overview)
└─────────────────────────┘
          ↓
┌─────────────────────────┐
│ concepts-writer-service  │ (POST /concepts)
└─────────────────────────┘
          ↓
        ...
```

**데이터 관리**:
- 각 서비스가 자신의 마크다운 섹션 생성
- 중앙 오케스트레이터가 섹션 결합
- 또는 공유 파일 시스템 사용

#### 장점

1. **독립적 배포**
   - 각 에이전트를 독립적으로 업데이트 가능
   - 다른 에이전트에 영향 없음
   - 버전 관리 용이

2. **기술 스택 다양성**
   - 각 서비스가 다른 언어/프레임워크 사용 가능
   - overview-writer: Python, concepts-writer: Node.js 등
   - 최적 도구 선택 가능

3. **독립적 확장**
   - 병목 서비스만 확장 가능
   - concepts-writer가 느리면 인스턴스 추가
   - 리소스 효율적

4. **팀 자율성**
   - 각 서비스를 다른 팀이 개발 가능
   - 명확한 API 계약만 준수
   - 조직 확장성

#### 단점

1. **과도한 분산 (Over-distribution)**
   - 현재 시스템: 단일 마크다운 파일 생성
   - Microservices: 7개 독립 서비스 + 오케스트레이터
   - **단순한 작업에 과도한 인프라**

2. **순차 의존성 유지**
   - Microservices로 전환해도 순차 호출 필요
   - overview-service → concepts-service → ...
   - **Microservices의 독립성 장점 활용 불가**

3. **네트워크 오버헤드**
   - 서비스 간 HTTP/gRPC 통신
   - 네트워크 지연, 실패 가능성
   - 현재: 파일 I/O (빠름) vs. 네트워크 (느림)

4. **운영 복잡도 폭발**
   - 7개 서비스 배포, 모니터링, 로깅
   - 서비스 디스커버리, 로드 밸런싱
   - 분산 추적 (Distributed Tracing)
   - **단일 개발자/소규모 팀에 부담**

5. **데이터 일관성 문제**
   - 각 서비스가 독립적 데이터 저장?
   - 또는 공유 파일 시스템? (Microservices 철학 위배)
   - 트랜잭션 관리 복잡 (Saga Pattern)

6. **디버깅 어려움**
   - 7개 서비스에 걸친 요청 추적
   - 로그 수집 및 중앙화 필요
   - 현재: 단일 파일로 모든 상태 확인

#### AI-DLC 적용 시 문제

**Inception 단계**:
- 유닛 분해: 각 에이전트를 독립 서비스로?
- 하지만 순차 의존성으로 인해 독립적이지 않음
- 유닛의 "독립적 구축" 조건 미충족

**Construction 단계**:
- 도메인 설계: 각 서비스의 도메인 모델?
- 논리 설계: 서비스 간 통신 프로토콜, API 계약
- 코드 생성: 각 서비스 구현 + 오케스트레이터

**설계 방법**:
- DDD 적용: 각 서비스 = Bounded Context?
- 하지만 에이전트는 독립적 비즈니스 도메인이 아님
- 단순히 처리 단계일 뿐

#### 실용성 평가

**현재 시스템 규모**:
- 1개 콘텐츠 생성: 50-80분
- 처리량: 하루 10-20개 콘텐츠 (예상)
- **Microservices 도입 정당화 불가**

**Microservices 도입 기준** (일반적):
- 팀 크기: 5-10개 팀 이상
- 트래픽: 초당 수백-수천 요청
- 독립 배포 필요성: 서비스별 릴리즈 사이클 다름
- **현재 시스템: 모든 기준 미충족**

#### 종합 평가

**AI-DLC 적합성**: ⭐⭐☆☆☆ (2/5)
- Inception 단계: 독립적 유닛이 아님
- Construction 단계: 과도한 인프라
- 소규모 시스템에 부적합

**현재 시스템 적합성**: ⭐☆☆☆☆ (1/5)
- 단순한 작업에 과도한 복잡도
- 순차 의존성으로 독립성 확보 불가
- 네트워크 오버헤드만 증가

**구현 복잡도**: ⭐☆☆☆☆ (1/5)
- 7개 서비스 개발, 배포, 운영
- 서비스 디스커버리, API Gateway
- 분산 모니터링, 로깅
- 소규모 팀에 과도한 부담

**확장성**: ⭐⭐⭐⭐⭐ (5/5)
- 독립적 확장 가능 (이론적)
- 팀 확장성 높음
- 하지만 현재 규모에 불필요

**총점**: 9/20 (45%)

**결론**: Microservices Architecture는 현재 시스템의 **규모와 복잡도**에 과도함. 순차 의존성으로 인해 독립성 장점을 활용할 수 없으며, 운영 복잡도만 폭발적으로 증가.

---

### 2.5 Monolithic Architecture (모놀리식 아키텍처)

#### 개요
Monolithic Architecture는 애플리케이션을 **단일 배포 단위**로 구축하는 전통적 패턴입니다.

#### 구조
```
┌─────────────────────────────────┐
│      Monolithic Application     │
│  ┌───────────────────────────┐  │
│  │   Presentation Layer      │  │
│  ├───────────────────────────┤  │
│  │   Business Logic Layer    │  │
│  ├───────────────────────────┤  │
│  │   Data Access Layer       │  │
│  └───────────────────────────┘  │
│                                 │
│  Database                       │
└─────────────────────────────────┘
```

**특징**:
- 단일 코드베이스
- 단일 배포 단위
- 단일 데이터베이스
- 공유 메모리 통신

#### 현재 시스템 평가

**현재 시스템은 이미 Monolithic**:
- 단일 Bash 스크립트 (`content-generator-v6.sh`)
- 7개 에이전트가 단일 프로세스에서 순차 실행
- 공유 파일 시스템
- 단일 배포 (스크립트 + 에이전트 프롬프트)

#### 장점

1. **단순성 (Simplicity)**
   - 이해하기 쉬운 구조
   - 디버깅 용이
   - 배포 단순 (단일 스크립트)

2. **성능 (Performance)**
   - 네트워크 오버헤드 없음
   - 파일 I/O로 빠른 데이터 공유
   - 공유 메모리 접근

3. **개발 생산성**
   - 단일 코드베이스
   - 통합 테스트 용이
   - 리팩토링 쉬움

4. **소규모 팀 적합**
   - 복잡한 인프라 불필요
   - 운영 부담 최소
   - 빠른 개발 사이클

#### 단점

1. **확장성 제한**
   - 전체를 확장해야 함 (부분 확장 불가)
   - 단일 실패 지점 (Single Point of Failure)

2. **기술 스택 고정**
   - 단일 언어/프레임워크
   - 새 기술 도입 어려움

3. **배포 단위**
   - 작은 변경도 전체 재배포
   - 배포 리스크 높음

#### 현재 시스템 맥락에서의 평가

**규모**:
- 현재: 단일 스크립트 + 7개 에이전트 프롬프트
- 코드 규모: ~1300줄 (스크립트) + ~500줄 (각 프롬프트)
- **Monolithic으로 충분**

**복잡도**:
- 순차 처리 로직
- 파일 기반 상태 관리
- **복잡도 낮음**

**팀 규모**:
- 예상: 1-3명 개발자
- **Monolithic 적합**

**확장 필요성**:
- 처리량: 하루 10-20개 콘텐츠
- **수직 확장(더 빠른 머신)으로 충분**

#### AI-DLC 적용

**Inception 단계**:
- 유닛 분해: 기능별 모듈로 분해 가능
- 하지만 Monolithic 내에서 분해
- 독립 배포 불필요

**Construction 단계**:
- 도메인 설계: 모듈 내 도메인 모델
- 논리 설계: 모듈 간 인터페이스
- 코드 생성: 단일 코드베이스

**설계 방법**:
- DDD 경량화: Modular Monolith 패턴
- 모듈 = Bounded Context
- 하지만 독립 배포 불필요

#### 종합 평가

**AI-DLC 적합성**: ⭐⭐⭐⭐☆ (4/5)
- Inception 단계: 모듈 단위 유닛 분해 가능
- Construction 단계: 단순하고 명확
- 소규모 시스템에 적합

**현재 시스템 적합성**: ⭐⭐⭐⭐⭐ (5/5)
- 이미 Monolithic 구조
- 규모와 복잡도에 적합
- 변경 불필요

**구현 복잡도**: ⭐⭐⭐⭐⭐ (5/5)
- 현재 구조 유지
- 추가 인프라 불필요
- 단순한 개선만 필요

**확장성**: ⭐⭐⭐☆☆ (3/5)
- 수직 확장으로 충분
- 수평 확장 어려움 (하지만 불필요)
- 부분 확장 불가

**총점**: 17/20 (85%)

**결론**: Monolithic Architecture는 현재 시스템에 적합. 하지만 "Monolithic"은 배포 관점의 분류일 뿐, **내부 구조**는 별도로 설계 필요. Pipeline Architecture를 Monolithic 내부 구조로 채택 가능.

---

## 3. 아키텍처 비교 종합

### 3.1 점수 요약

| 아키텍처 | AI-DLC 적합성 | 현재 시스템 적합성 | 구현 복잡도 | 확장성 | 총점 | 백분율 |
|---------|--------------|-------------------|------------|--------|------|--------|
| **Pipeline** | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐☆☆ (3) | ⭐⭐⭐⭐☆ (4) | **17/20** | **85%** |
| Layered | ⭐⭐☆☆☆ (2) | ⭐⭐☆☆☆ (2) | ⭐⭐⭐⭐☆ (4) | ⭐⭐⭐☆☆ (3) | 11/20 | 55% |
| Event-Driven | ⭐⭐☆☆☆ (2) | ⭐☆☆☆☆ (1) | ⭐☆☆☆☆ (1) | ⭐⭐⭐⭐☆ (4) | 8/20 | 40% |
| Microservices | ⭐⭐☆☆☆ (2) | ⭐☆☆☆☆ (1) | ⭐☆☆☆☆ (1) | ⭐⭐⭐⭐⭐ (5) | 9/20 | 45% |
| **Monolithic** | ⭐⭐⭐⭐☆ (4) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐☆☆ (3) | **17/20** | **85%** |

### 3.2 심층 분석

#### Pipeline Architecture (1위)

**핵심 강점**:
1. 현재 시스템과 자연스러운 매핑 (이미 암묵적 Pipeline)
2. AI-DLC Construction 단계와 완벽 정렬
3. 명시화만으로 개선 가능 (대규모 리팩토링 불필요)
4. 독립적 Filter 개선 및 테스트 용이

**적용 전략**:
- **Modular Monolithic Pipeline**: Monolithic 배포 + Pipeline 내부 구조
- 단일 스크립트 내에서 Filter 체인 실행
- 파일 기반 Pipe 메커니즘 유지
- Work Status Markers 표준화

**AI-DLC Inception 단계 적용**:
```
의도: "학습 콘텐츠 자동화 시스템 개선"
    ↓
유닛 분해:
  - Unit 1: Filter 계약 명시화 (7개 Filter)
  - Unit 2: Pipe 메커니즘 설계 (Work Status Markers)
  - Unit 3: 에이전트 프롬프트 개선
  - Unit 4: 오케스트레이션 개선
```

**AI-DLC Construction 단계 적용**:
```
도메인 설계:
  - Filter: 입력 계약, 출력 계약, 품질 기준
  - Pipe: Work Status Markers 표준, 데이터 전달 프로토콜
    ↓
논리 설계:
  - Filter 실행 순서 결정 알고리즘
  - 재시작 메커니즘 (마지막 완료 Filter부터)
  - 실패 처리 로직
    ↓
코드 생성:
  - 에이전트 프롬프트에 I/O 계약 통합
  - 오케스트레이션 스크립트 개선
```

#### Monolithic Architecture (1위 공동)

**Monolithic은 배포 관점**:
- Monolithic vs. Microservices는 **배포 단위**의 구분
- **내부 구조**는 별도 설계 필요
- Pipeline Architecture를 Monolithic 내부 구조로 채택

**실제 권장**:
- **Modular Monolithic Pipeline Architecture**
- Monolithic 배포 (단일 스크립트)
- Pipeline 내부 구조 (Filter 체인)
- 모듈별 응집도 높은 설계

### 3.3 기각된 아키텍처 이유

#### Layered Architecture
- **근본적 불일치**: 순차 체인 ≠ 계층 구조
- **개념적 혼란**: 억지 계층화 필요
- **명확한 이점 없음**: Pipeline이 더 자연스러움

#### Event-Driven Architecture
- **순차 의존성 상충**: 이벤트 순서 보장 필요 → EDA 장점 상실
- **과도한 복잡도**: Event Bus, 분산 추적, 보상 트랜잭션
- **단순 작업에 부적합**: 마크다운 파일 생성에 EDA는 과도

#### Microservices Architecture
- **규모 부적합**: 소규모 시스템에 과도한 인프라
- **독립성 확보 불가**: 순차 의존성으로 독립 배포 의미 없음
- **운영 부담**: 7개 서비스 배포, 모니터링, 로깅

---

## 4. 최종 권장 사항

### 4.1 권장 아키텍처

**Modular Monolithic Pipeline Architecture**

```
┌─────────────────────────────────────────────────────────┐
│  Monolithic Deployment (단일 스크립트)                   │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Pipeline Architecture (내부 구조)                 │  │
│  │                                                   │  │
│  │  Input                                            │  │
│  │    ↓                                              │  │
│  │  [Filter 1: content-initiator]                    │  │
│  │    ↓ (Pipe: Work Status Markers + 마크다운)       │  │
│  │  [Filter 2: overview-writer]                      │  │
│  │    ↓                                              │  │
│  │  [Filter 3: concepts-writer]                      │  │
│  │    ↓                                              │  │
│  │  [Filter 4: visualization-writer]                 │  │
│  │    ↓                                              │  │
│  │  [Filter 5: practice-writer]                      │  │
│  │    ↓                                              │  │
│  │  [Filter 6: quiz-writer]                          │  │
│  │    ↓                                              │  │
│  │  [Filter 7: content-validator]                    │  │
│  │    ↓                                              │  │
│  │  Output                                           │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 4.2 선정 근거

#### 1. 현재 시스템과의 일치성
- 이미 암묵적 Pipeline 구조
- **명시화만으로 개선 가능**
- 대규모 리팩토링 불필요
- 기존 강점 (단순성, 자기완결성) 유지

#### 2. AI-DLC 방법론 적합성
- **Inception 단계**: Filter 단위 유닛 분해 자연스러움
- **Construction 단계**:
  - 도메인 설계 = Filter 계약
  - 논리 설계 = Pipe 메커니즘
  - 코드 생성 = 에이전트 프롬프트 + 스크립트
- **Operations 단계**: 품질 측정 시스템 통합

#### 3. 설계 방법론 적용 가능성
- **DDD 경량화 적용 가능**:
  - Filter = Lightweight Bounded Context
  - Pipe = Integration Event (단순화)
  - 유비쿼터스 언어: Filter, Pipe, Work Status Markers
- **전술적 패턴 최소화**:
  - Aggregate, Repository 불필요
  - Entity, Value Object도 과도
  - **Filter 계약**만으로 충분

#### 4. 구현 실용성
- 현재 규모에 적합 (단일 개발자/소규모 팀)
- 점진적 개선 가능
- 운영 부담 최소
- 명확한 개선 경로

### 4.3 구체적 개선 방안

#### Phase 1: Filter 계약 명시화
**목표**: 암묵적 계약을 명시적으로 문서화

**작업**:
1. 각 Filter의 **입력 계약** 문서 작성
   - 필수 입력 데이터
   - 입력 형식 및 위치
   - 선행 조건

2. 각 Filter의 **출력 계약** 문서 작성
   - 생성할 섹션 및 구조
   - 출력 형식 (마크다운)
   - 후행 조건

3. 각 Filter의 **품질 기준** 정의
   - 파서 테스트 참조
   - 구조적 요구사항
   - 내용적 요구사항

**AI-DLC 적용**:
- Inception: Unit 1로 계획
- Construction: 도메인 설계 단계

#### Phase 2: Pipe 메커니즘 설계
**목표**: Work Status Markers 표준화 및 재시작 메커니즘 구현

**작업**:
1. **Work Status Markers 표준** 정의
   - 마커 형식 (Syntax)
   - 마커 종류 (CURRENT_AGENT, PROGRESS, HANDOFF LOG)
   - 마커 위치 규칙

2. **데이터 전달 프로토콜** 설계
   - 마크다운 파일 구조
   - 섹션별 읽기/쓰기 권한
   - Filter 간 데이터 흐름

3. **재시작 메커니즘** 구현
   - 마지막 완료 Filter 식별 알고리즘
   - 다음 Filter 자동 결정
   - 중복 작업 방지

**AI-DLC 적용**:
- Inception: Unit 2로 계획
- Construction: 논리 설계 단계

#### Phase 3: 에이전트 프롬프트 개선
**목표**: Filter 계약을 프롬프트에 통합

**작업**:
1. 각 에이전트 프롬프트에 **입력 계약 섹션** 추가
2. 각 에이전트 프롬프트에 **출력 계약 섹션** 추가
3. 각 에이전트 프롬프트에 **품질 기준 섹션** 추가
4. 각 에이전트 프롬프트에 **자체 점검 체크리스트** 추가

**AI-DLC 적용**:
- Inception: Unit 3으로 계획
- Construction: 코드 생성 단계

#### Phase 4: 오케스트레이션 스크립트 개선
**목표**: Pipeline 실행 로직 개선

**작업**:
1. **Work Status Markers 기반 실행**
   - 마커 읽기/쓰기 함수
   - 다음 Filter 자동 결정
   - 완료된 Filter 건너뛰기

2. **재시작 메커니즘 구현**
   - `--restart` 옵션 강화
   - 마지막 완료 지점 자동 식별
   - 실패 지점부터 재시작

3. **조건부 Filter 실행**
   - `--skip-{filter}` 옵션
   - `--only={filter}` 옵션
   - Filter 실행 조건 설정

4. **성능 로깅**
   - Filter별 실행 시간 측정
   - 병목 지점 식별
   - 성능 데이터 수집

**AI-DLC 적용**:
- Inception: Unit 4로 계획
- Construction: 코드 생성 단계

### 4.4 설계 방법론: DDD 경량화

#### 전통적 DDD vs. 경량화된 DDD

| DDD 요소 | 전통적 DDD | 경량화된 DDD (현재 프로젝트) | 채택 여부 |
|---------|-----------|---------------------------|----------|
| **전략적 설계** |
| Bounded Context | 도메인별 경계 | Filter별 책임 경계 | ✅ 채택 (단순화) |
| Context Map | 복잡한 관계 매핑 | Filter 체인 다이어그램 | ✅ 채택 (단순화) |
| Ubiquitous Language | 도메인 용어 | Filter, Pipe, Work Status Markers | ✅ 채택 |
| **전술적 설계** |
| Aggregate | 복잡한 일관성 경계 | - | ❌ 불필요 |
| Entity | 식별자 기반 객체 | - | ❌ 불필요 |
| Value Object | 불변 객체 | 마크다운 섹션 (개념만) | △ 개념만 |
| Repository | 데이터 접근 추상화 | - | ❌ 불필요 |
| Domain Service | 도메인 로직 | Filter (에이전트) | ✅ 채택 (재해석) |
| Domain Event | 도메인 변화 이벤트 | HANDOFF LOG 항목 | ✅ 채택 (단순화) |

#### 채택하는 DDD 요소

1. **Bounded Context → Filter 책임 경계**
   - 각 Filter가 자신의 책임 영역을 명확히 정의
   - 예: concepts-writer는 "Core Concepts 섹션 생성"만 담당
   - 다른 Filter의 책임에 간섭하지 않음

2. **Context Map → Pipeline 다이어그램**
   - Filter 간 관계를 Pipeline 다이어그램으로 표현
   - 데이터 흐름 및 의존성 명시
   - 간단한 순차 체인으로 표현 가능

3. **Ubiquitous Language**
   - **Filter**: 독립적 처리 컴포넌트 (AI 에이전트)
   - **Pipe**: 데이터 전달 메커니즘 (Work Status Markers + 마크다운 파일)
   - **Work Status Markers**: 작업 상태 추적 메커니즘
   - **HANDOFF LOG**: Filter 간 핸드오프 기록
   - **Contract**: Filter의 입력/출력 명세

4. **Domain Service → Filter (재해석)**
   - DDD의 Domain Service: 엔티티나 값 객체에 속하지 않는 도메인 로직
   - 현재 프로젝트: Filter가 Domain Service 역할
   - 각 Filter가 "섹션 생성"이라는 도메인 로직 수행

5. **Domain Event → HANDOFF LOG (단순화)**
   - DDD의 Domain Event: 도메인에서 발생한 의미 있는 사건
   - 현재 프로젝트: HANDOFF LOG 항목이 Domain Event 역할
   - 예: `[DONE] overview-writer: Overview 완료`

#### 불필요한 DDD 요소 (과도한 설계)

1. **Aggregate**
   - 트랜잭션 일관성 경계
   - 현재 시스템: 트랜잭션 개념 불필요 (순차 파일 쓰기)
   - **결론**: 불필요

2. **Entity**
   - 식별자로 구분되는 도메인 객체
   - 현재 시스템: 객체 지향 설계 불필요
   - **결론**: 불필요

3. **Value Object**
   - 불변 값 객체
   - 현재 시스템: 마크다운 섹션을 "개념적 값 객체"로 볼 수는 있지만, 명시적 구현 불필요
   - **결론**: 개념만 활용

4. **Repository**
   - 데이터 접근 추상화
   - 현재 시스템: 파일 I/O가 직접적이고 단순
   - **결론**: 불필요

#### 경량화된 DDD 적용 예시

**Filter 계약 문서** (Bounded Context 명세):
```markdown
# concepts-writer Filter Contract

## Bounded Context
- 책임: Core Concepts 섹션 생성
- 범위: Easy/Normal/Expert 3단계 난이도 설명 + 시각화 메타데이터
- 경계: Overview 섹션 이후, Practice 섹션 이전

## Ubiquitous Language
- Concept: 핵심 개념 (1개 토픽당 2-3개)
- Difficulty Level: Easy, Normal, Expert
- Visualization Metadata: 시각화 컴포넌트 정보

## Input Contract
- category.yaml: 토픽 메타데이터
- Overview 섹션: 개요 내용 (이전 Filter 출력)

## Output Contract
- Core Concepts 섹션: 2-3개 Concept, 각 3단계
- Visualization Metadata: 선택적

## Domain Event
- [DONE] concepts-writer: Core Concepts 완료 (HANDOFF LOG)
```

**Context Map** (Pipeline 다이어그램):
```
[content-initiator] ──→ [overview-writer] ──→ [concepts-writer]
                                                      ↓
                                          [visualization-writer]
                                                      ↓
                                            [practice-writer]
                                                      ↓
                                              [quiz-writer]
                                                      ↓
                                          [content-validator]
```

### 4.5 향후 확장 전략

#### 단기 (1-3개월): 명시화 및 개선
- Filter 계약 문서 작성
- Work Status Markers 표준화
- 재시작 메커니즘 구현
- 에이전트 프롬프트 개선

#### 중기 (3-6개월): 품질 측정 및 최적화
- 품질 측정 시스템 구축 (Phase 5)
- 손실 함수 정의 (0-100점 점수)
- 성능 모니터링 및 병목 지점 최적화
- 자동 개선 루프 구축

#### 장기 (6개월+): 선택적 확장
- **Parallel Pipeline**: 독립적 Filter 병렬 실행 (가능하다면)
- **Branch Pipeline**: 조건부 Filter 체인 (A/B 테스트)
- **Caching Pipe**: 중간 결과 캐싱 (재시작 최적화)
- **Distributed Pipeline**: 다중 머신 분산 실행 (규모 증가 시)

---

## 5. 결론

### 5.1 최종 권장: Modular Monolithic Pipeline Architecture

**핵심 이유**:
1. **현재 시스템과의 자연스러운 매핑**: 이미 암묵적 Pipeline, 명시화만 필요
2. **AI-DLC 방법론 완벽 정렬**: Inception/Construction/Operations 단계와 일치
3. **DDD 경량화 적용 가능**: Bounded Context = Filter, 전술적 패턴 최소화
4. **실용적 개선 경로**: 점진적 개선, 대규모 리팩토링 불필요
5. **현재 규모 적합**: 소규모 팀, 단순한 배포, 최소 운영 부담

### 5.2 설계 방법: DDD 경량화

**채택 요소**:
- Bounded Context (Filter 책임 경계)
- Context Map (Pipeline 다이어그램)
- Ubiquitous Language (Filter, Pipe, Contract)
- Domain Service (Filter = 도메인 서비스)
- Domain Event (HANDOFF LOG)

**불채택 요소** (과도한 설계):
- Aggregate, Entity, Repository (객체 지향 불필요)
- 전술적 패턴 대부분 (단순 파일 기반 시스템)

### 5.3 AI-DLC 적용 로드맵

**Inception 단계** (1-2주):
```
의도: "학습 콘텐츠 자동화 시스템을 Pipeline Architecture로 명시적 설계"
    ↓
유닛 분해:
  - Unit 1: Filter 계약 명시화 (2-3일)
  - Unit 2: Pipe 메커니즘 설계 (2-3일)
  - Unit 3: 에이전트 프롬프트 개선 (3-5일)
  - Unit 4: 오케스트레이션 개선 (2-3일)
  - Unit 5: 품질 측정 방법 구축 (2-3일)
```

**Construction 단계** (2-3주):
```
각 유닛별로 순차 실행:
  도메인 설계 → 논리 설계 → 코드 생성
  ↓
  검증 (파서 테스트, 통합 테스트)
```

**Operations 단계** (지속적):
```
- 품질 데이터 수집 (10-20개 콘텐츠)
- 성능 분석 및 병목 지점 식별
- 개선 루프 (측정 → 분석 → 개선 → 재측정)
```

### 5.4 핵심 메시지

> **현재 시스템은 이미 Pipeline Architecture의 암묵적 구현입니다.**
> **필요한 것은 대규모 리팩토링이 아니라 명시화입니다.**

**Pipeline Architecture 선정 근거**:
- ✅ 자연스러운 매핑 (이미 암묵적 Pipeline)
- ✅ AI-DLC 방법론 정렬 (Construction 단계 = Filter 체인)
- ✅ DDD 경량화 적용 가능 (Bounded Context = Filter)
- ✅ 점진적 개선 가능 (명시화 → 표준화 → 최적화)
- ✅ 현재 규모 적합 (소규모 팀, 단순 배포)

**기각된 아키텍처**:
- ❌ Layered: 순차 체인 ≠ 계층 구조
- ❌ Event-Driven: 순차 의존성 상충, 과도한 복잡도
- ❌ Microservices: 규모 부적합, 운영 부담 폭발

**Monolithic은 배포 관점**:
- Monolithic vs. Microservices = 배포 단위의 구분
- 내부 구조는 Pipeline Architecture
- **Modular Monolithic Pipeline = 최적 조합**

---

## 부록 A: AI-DLC 프롬프트 생성 가이드

### A.1 Inception 단계 프롬프트

```markdown
# 프롬프트 2: Inception - 개선 영역 정의

당신의 역할: 전문 소프트웨어 아키텍트로서, 학습 콘텐츠 자동화 시스템의 개선 필요 영역을 독립적으로 구축 가능한 여러 유닛으로 분해하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(aidlc-docs/inception/plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요. 어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제: 다음 개선 필요 영역을 독립적으로 구축할 수 있는 여러 유닛으로 분해하세요.

**개선 필요 영역:**
- 에이전트 간 입출력 계약이 암묵적
- Pipe 메커니즘(Work Status Markers)이 명시적이지 않음
- 에이전트 프롬프트 파일에 명확한 I/O 명세 부재
- 오케스트레이션 스크립트 개선 필요
- 시스템 품질 측정 방법 부재

**아키텍처 컨텍스트:**
- 선정된 아키텍처: Pipeline Architecture (Pipes and Filters)
- 배포 방식: Modular Monolithic
- 설계 방법: DDD 경량화 (Bounded Context = Filter)

각 유닛은 단일 팀이 구축할 수 있는 높은 응집도를 가진 개선 작업을 포함해야 합니다. 유닛들은 서로 느슨하게 결합(loosely coupled)되어야 합니다.

aidlc-docs/inception/ 디렉터리를 생성하고, inception/units/ 폴더에 각 유닛에 대한 개별 .md 파일을 작성하세요.

**각 유닛 문서에 포함할 내용:**
- 목표: 이 유닛이 해결하는 시스템 문제
- 현재 상태 (As-Is): 문제점
- 목표 상태 (To-Be): 개선 사항, 기대 효과, 성공 기준
- 범위: 포함(In Scope), 제외(Out of Scope)
- 의존성: 선행 유닛, 후속 유닛
- 산출물: 생성할 파일/문서 목록
- 검증 기준: 체크리스트

각 유닛 간 통합 계약(integration contract)을 생성하고, 각 유닛의 의존성과 실행 순서를 aidlc-docs/inception/units/integration_plan.md 파일에 정의하세요.

아직 기술적 시스템 설계는 시작하지 마세요. 유닛 정의와 우선순위 결정에만 집중하세요.
```

### A.2 Construction 단계 프롬프트

```markdown
# 프롬프트 3: Construction - Filter 계약 명시화

당신의 역할: 전문 소프트웨어 아키텍트로서, Pipeline Architecture의 각 Filter 계약을 명시적으로 문서화하는 업무를 담당합니다.

앞으로의 작업을 계획하고 md 파일(aidlc-docs/construction/plan.md)에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요. 어떤 단계든 제가 명확히 해야 할 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요. 계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 동일한 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제: 7개 Filter의 입출력 계약을 명시적으로 문서화하세요. 다음 파일들을 참조하세요:
- .claude/agents/*.md (현재 에이전트 프롬프트)
- test/test-*.mjs (파서 테스트)
- public/content/ko/*/01-*.md (생성된 콘텐츠 샘플)

aidlc-docs/construction/filters/ 디렉터리에 각 Filter의 계약 문서를 작성하세요.

**Filter 목록:**
1. content-initiator
2. overview-writer
3. concepts-writer
4. visualization-writer
5. practice-writer
6. quiz-writer
7. content-validator

**각 Filter 계약 문서 구조:**
1. 입력 계약: 파일 경로, 필수 섹션, Work Status Markers, 선행 조건
2. 출력 계약: 생성 섹션, 구조, 최소 길이, Work Status Markers 업데이트
3. 품질 기준: 파서 테스트 항목, 검증 체크리스트
4. 오류 처리: 오류 유형, 재시도 전략, 실패 시 다음 Filter 통지 방법

**DDD 경량화 적용:**
- 각 Filter = Bounded Context (책임 경계 명확히)
- Ubiquitous Language 사용 (Filter, Pipe, Contract, Work Status Markers)
- 전술적 패턴 최소화 (Aggregate, Repository 불필요)

의사코드만 작성하세요. 실제 코드는 생성하지 마세요.
```

---

**문서 끝**

**작성 완료일**: 2025-10-16
**검토 요청**: 본 보고서는 선입견 없는 객관적 분석을 목표로 작성되었습니다. Pipeline Architecture 선정은 현재 시스템 구조, AI-DLC 방법론 적합성, 실용적 구현 가능성을 종합 평가한 결과입니다.
