# Dashboard Feature Module 설계 계획

## 개요

**Feature Module**: Dashboard
**책임**: Dashboard CRUD, Template/Duplicate, Sharing, Bookmarks, Legal Consent, Disclaimer, Reporting (US2.1~US2.14)
**아키텍처**: Next.js 15 App Router + React 19 + TanStack Query v5 + Supabase

## 목표

Dashboard Feature Module 설계 문서를 작성하여 다음을 달성합니다:

1. **Comprehensive Coverage**: 14개 User Stories 완전 구현 (US2.1~US2.14)
2. **Modular Architecture**: React Components Tree + TanStack Query Hooks
3. **Type Safety**: TypeScript + Zod로 모든 데이터 검증
4. **Performance**: Lazy Loading, Viewport Optimization, Query Caching
5. **Security**: Legal Consent Logging, Ownership Verification, Access Control
6. **Integration**: Widget Library, Data Integration, Subscription, Authentication, Admin Console

## 포함된 사용자 스토리

### US2.1: 대시보드 목록 조회

- 사용자별 대시보드 목록 조회 (나만의 대시보드)
- 필터링: 카테고리, 작성일, 최근 수정일
- 정렬: 이름, 작성일, 수정일, 조회수
- 검색: 대시보드 이름, 설명
- 페이지네이션

### US2.2: 대시보드 상세 조회

- 대시보드 메타데이터 조회 (제목, 설명, 작성자, 작성일)
- 위젯 목록 조회 및 레이아웃 정보
- Lazy Loading: 뷰포트 내 위젯만 데이터 로드
- 위젯별 데이터 독립 로딩 (병렬 처리)

### US2.3: 공개 대시보드 탐색

- 공개된 대시보드 목록 조회 (is_public=true)
- 카테고리별 필터링
- 인기순 정렬 (조회수, 북마크 수)
- Read-only 미리보기

### US2.4: 빈 대시보드 생성

- 제목, 설명 입력
- 카테고리 선택
- 초기 레이아웃 설정
- Subscription Plan 제한 확인

### US2.5: 템플릿으로 대시보드 생성

- Admin Console 템플릿 목록 조회
- 템플릿 선택 및 미리보기
- 템플릿 복제 (위젯 + 레이아웃)
- 제목 자동 생성 (e.g., "S&P 500 대시보드 (복사본)")

### US2.6: 기존 대시보드 복제

- 대시보드 선택
- 복제 (위젯 + 레이아웃 + 데이터 설정)
- 제목 자동 생성

### US2.7: 대시보드 편집

- 제목, 설명 수정
- 카테고리 변경
- 위젯 추가/삭제/수정
- 레이아웃 변경 (드래그 앤 드롭)
- 실시간 저장 (auto-save)

### US2.8: 대시보드 삭제

- 소유권 확인
- Soft Delete (deleted_at 설정)
- 관련 데이터 정리 (북마크, 공유 링크)

### US2.9: 대시보드 공유

- 공유 링크 생성 (unique slug)
- 공개 여부 설정 (is_public)
- Read-only 접근 제어
- 링크 복사

### US2.10: 대시보드 북마크

- 북마크 추가/제거
- 북마크한 대시보드 목록 조회
- 북마크 개수 표시

### US2.11: 기본 대시보드 설정

- 사용자별 기본 대시보드 1개 설정
- 로그인 후 자동 리다이렉트

### US2.12: 대시보드 생성 시 법적 동의

- 동의 모달 표시 (첫 생성 시)
- 동의 내용 표시 (법적 책임, 투자 자문 금지)
- ConsentLog 기록 (3년 이상 보관)

### US2.13: 대시보드 조회 시 면책 고지

- 면책 모달 표시 (첫 조회 시)
- 면책 내용 표시 (투자 자문 아님, 참고 목적)
- ActivityLog 기록 (조회 이력)

### US2.14: 대시보드 신고

- 신고 모달 (신고 사유 선택)
- 신고 사유: 부적절한 콘텐츠, 오해의 소지, 투자 자문 의심, 기타
- 신고자 익명성 보호
- DashboardReport 기록

## 아키텍처 질문 (사용자 승인 필요)

### [Question 1] Component Hierarchy 전략

Dashboard Feature Module의 컴포넌트 계층 구조를 어떻게 설계할까?

**선택지**:

**Option A: Page-level Components Only**

```
packages/dashboard/
  src/
    components/
      DashboardListPage.tsx       # 모든 로직 포함
      DashboardDetailPage.tsx     # 모든 로직 포함
      DashboardCreatePage.tsx
      DashboardEditPage.tsx
```

**장점**:
- 파일 개수 적음
- 간단한 구조

**단점**:
- 컴포넌트 재사용 불가
- 파일 크기 커짐 (300+ lines)
- 테스트 복잡

**Option B: Container/Presentational Pattern**

```
packages/dashboard/
  src/
    containers/                   # 로직 + 데이터 fetching
      DashboardListContainer.tsx
      DashboardDetailContainer.tsx
    components/                   # UI only
      DashboardCard.tsx
      DashboardGrid.tsx
      DashboardHeader.tsx
      DashboardFilters.tsx
```

**장점**:
- 명확한 관심사 분리
- Presentational 컴포넌트 재사용 가능
- 테스트 용이

**단점**:
- 파일 개수 많음
- Container/Presentational 경계 모호 (Hooks 시대)

**Option C: Feature-based Hierarchy (권장)**

```
packages/dashboard/
  src/
    components/
      list/
        DashboardList.tsx         # Main list component
        DashboardCard.tsx         # Card UI
        DashboardFilters.tsx      # Filter UI
        DashboardSort.tsx         # Sort UI
      detail/
        DashboardDetail.tsx       # Main detail component
        DashboardHeader.tsx       # Header UI
        DashboardGrid.tsx         # Grid layout
        WidgetContainer.tsx       # Widget wrapper
      create/
        DashboardCreate.tsx       # Main create component
        DashboardForm.tsx         # Form UI
        TemplateSelector.tsx      # Template selection
      edit/
        DashboardEdit.tsx         # Main edit component
        EditToolbar.tsx           # Toolbar UI
        LayoutEditor.tsx          # Layout editor
      shared/
        ConsentModal.tsx          # Legal consent modal
        DisclaimerModal.tsx       # Disclaimer modal
        ReportModal.tsx           # Report modal
        ShareDialog.tsx           # Share dialog
        BookmarkButton.tsx        # Bookmark button
```

**장점**:
- Feature별 명확한 구조
- 컴포넌트 재사용 가능 (shared/)
- 파일 크기 적절 (50-150 lines)
- 테스트 용이

**단점**:
- 디렉토리 깊이 증가

**권장**: Option C (Feature-based Hierarchy)

**이유**:
1. Feature별 명확한 구조 (list, detail, create, edit, shared)
2. 컴포넌트 재사용 가능 (shared/ 디렉토리)
3. 파일 크기 적절 (50-150 lines)
4. 테스트 용이 (단위 테스트, 통합 테스트)
5. 확장 가능 (새로운 feature 추가 시 디렉토리만 추가)

### [Question 2] Dashboard Layout Engine 전략

Dashboard 위젯 레이아웃을 어떻게 구현할까?

**선택지**:

**Option A: react-grid-layout 라이브러리**

```typescript
import GridLayout from 'react-grid-layout'

export function DashboardGrid({ widgets, layout }) {
  return (
    <GridLayout
      layout={layout}
      cols={12}
      rowHeight={60}
      width={1200}
      onLayoutChange={handleLayoutChange}
    >
      {widgets.map(widget => (
        <div key={widget.id} data-grid={widget.layout}>
          <WidgetContainer widget={widget} />
        </div>
      ))}
    </GridLayout>
  )
}
```

**장점**:
- 검증된 라이브러리 (11k stars)
- 드래그 앤 드롭 기본 지원
- 반응형 레이아웃
- 충돌 감지 및 자동 정렬

**단점**:
- 외부 의존성 추가
- 커스터마이징 제약
- 번들 사이즈 증가 (~100KB)

**Option B: CSS Grid 기반 Custom Implementation**

```typescript
export function DashboardGrid({ widgets, layout }) {
  const gridStyles = {
    display: 'grid',
    gridTemplateColumns: 'repeat(12, 1fr)',
    gridAutoRows: '60px',
    gap: '16px'
  }

  return (
    <div style={gridStyles}>
      {widgets.map(widget => (
        <div
          key={widget.id}
          style={{
            gridColumn: `span ${widget.layout.width}`,
            gridRow: `span ${widget.layout.height}`
          }}
        >
          <WidgetContainer widget={widget} />
        </div>
      ))}
    </div>
  )
}
```

**장점**:
- 의존성 없음
- 완전한 제어
- 번들 사이즈 최소

**단점**:
- 드래그 앤 드롭 직접 구현 필요
- 충돌 감지 로직 필요
- 개발 시간 증가

**Option C: react-grid-layout + Lazy Import**

```typescript
// Dynamic import for code splitting
const GridLayout = dynamic(() => import('react-grid-layout'), {
  ssr: false,
  loading: () => <DashboardGridSkeleton />
})

export function DashboardGrid({ widgets, layout, editable }) {
  if (!editable) {
    // View mode: CSS Grid (no library)
    return <StaticDashboardGrid widgets={widgets} layout={layout} />
  }

  // Edit mode: react-grid-layout
  return (
    <GridLayout
      layout={layout}
      onLayoutChange={handleLayoutChange}
    >
      {/* ... */}
    </GridLayout>
  )
}
```

**장점**:
- View mode: 의존성 없음 (CSS Grid)
- Edit mode: 검증된 라이브러리
- Code splitting으로 번들 최적화

**단점**:
- 두 가지 구현 유지보수 필요

**권장**: Option C (react-grid-layout + Lazy Import)

**이유**:
1. View mode (대부분의 사용): CSS Grid로 가볍게 (의존성 없음)
2. Edit mode (소수의 사용): react-grid-layout로 UX 향상
3. Dynamic import로 번들 최적화 (edit mode 진입 시에만 로드)
4. 개발 시간 절약 (드래그 앤 드롭, 충돌 감지 구현 불필요)

### [Question 3] Widget Lazy Loading 전략

대시보드 상세 조회 시 위젯 데이터를 어떻게 로드할까?

**선택지**:

**Option A: Eager Loading (모든 위젯 동시 로드)**

```typescript
export function useDashboardDetail(dashboardId: string) {
  const { data: dashboard } = useQuery({
    queryKey: ['dashboards', dashboardId],
    queryFn: () => fetchDashboard(dashboardId)
  })

  const { data: widgetData } = useQueries({
    queries: dashboard.widgets.map(widget => ({
      queryKey: ['widgets', widget.id, 'data'],
      queryFn: () => fetchWidgetData(widget.id)
    }))
  })

  return { dashboard, widgetData }
}
```

**장점**:
- 간단한 구현
- 모든 데이터 즉시 표시

**단점**:
- 초기 로딩 시간 긴 (10+ widgets)
- 불필요한 API 호출 (뷰포트 밖 위젯)
- 사용자 경험 저하

**Option B: Viewport-based Lazy Loading (권장)**

```typescript
export function WidgetContainer({ widget }) {
  const ref = useRef<HTMLDivElement>(null)
  const isInViewport = useIntersectionObserver(ref, { threshold: 0.1 })

  const { data, isLoading } = useQuery({
    queryKey: ['widgets', widget.id, 'data'],
    queryFn: () => fetchWidgetData(widget.id),
    enabled: isInViewport  // 뷰포트 진입 시에만 로드
  })

  if (!isInViewport) {
    return <div ref={ref}><WidgetSkeleton /></div>
  }

  return (
    <div ref={ref}>
      {isLoading ? <WidgetSkeleton /> : <Widget data={data} />}
    </div>
  )
}
```

**장점**:
- 뷰포트 내 위젯만 로드
- 초기 로딩 시간 단축
- 네트워크 트래픽 감소
- 사용자 경험 향상

**단점**:
- Intersection Observer API 필요
- 스크롤 시 로딩 깜빡임

**Option C: Progressive Loading (순차 로드)**

```typescript
export function useDashboardDetail(dashboardId: string) {
  const { data: dashboard } = useQuery({
    queryKey: ['dashboards', dashboardId],
    queryFn: () => fetchDashboard(dashboardId)
  })

  // 위젯 순차 로드 (0번부터)
  const widgetQueries = useQueries({
    queries: dashboard.widgets.map((widget, index) => ({
      queryKey: ['widgets', widget.id, 'data'],
      queryFn: () => fetchWidgetData(widget.id),
      enabled: index === 0 || widgetQueries[index - 1]?.isSuccess
    }))
  })

  return { dashboard, widgetQueries }
}
```

**장점**:
- 순차 로딩으로 안정적
- 초기 위젯 빠르게 표시

**단점**:
- 전체 로딩 시간 긴
- 병렬 처리 불가

**권장**: Option B (Viewport-based Lazy Loading)

**이유**:
1. 뷰포트 내 위젯만 로드 (초기 로딩 시간 단축)
2. 사용자가 스크롤하면서 데이터 로드 (점진적 렌더링)
3. Intersection Observer API 표준 지원
4. TanStack Query의 `enabled` 옵션 활용
5. Skeleton UI로 로딩 상태 명확

### [Question 4] Dashboard State Management 전략

Dashboard 편집 시 상태 관리를 어떻게 할까?

**선택지**:

**Option A: Local State Only (useState)**

```typescript
export function DashboardEdit({ dashboard }) {
  const [title, setTitle] = useState(dashboard.title)
  const [description, setDescription] = useState(dashboard.description)
  const [widgets, setWidgets] = useState(dashboard.widgets)
  const [layout, setLayout] = useState(dashboard.layout)

  const handleSave = async () => {
    await updateDashboard({ id: dashboard.id, title, description, widgets, layout })
  }

  return (
    <div>
      <input value={title} onChange={e => setTitle(e.target.value)} />
      {/* ... */}
    </div>
  )
}
```

**장점**:
- 간단한 구현
- 의존성 없음

**단점**:
- 여러 컴포넌트 간 상태 공유 어려움
- Props drilling 발생
- Undo/Redo 구현 복잡

**Option B: Global State (Zustand/Jotai)**

```typescript
// store/dashboardEditStore.ts
import { create } from 'zustand'

export const useDashboardEditStore = create((set) => ({
  title: '',
  description: '',
  widgets: [],
  layout: [],
  setTitle: (title) => set({ title }),
  addWidget: (widget) => set(state => ({ widgets: [...state.widgets, widget] })),
  updateLayout: (layout) => set({ layout })
}))

// components/DashboardEdit.tsx
export function DashboardEdit() {
  const { title, setTitle } = useDashboardEditStore()
  return <input value={title} onChange={e => setTitle(e.target.value)} />
}
```

**장점**:
- 여러 컴포넌트 간 상태 공유 쉬움
- Props drilling 없음
- Middleware로 Undo/Redo 구현 가능

**단점**:
- 외부 의존성 추가
- 전역 상태 오용 가능
- 컴포넌트 간 결합도 증가

**Option C: TanStack Query + Optimistic Updates (권장)**

```typescript
export function useDashboardEdit(dashboardId: string) {
  const queryClient = useQueryClient()

  const updateMutation = useMutation({
    mutationFn: (updates) => updateDashboard(dashboardId, updates),
    onMutate: async (updates) => {
      // Optimistic update
      await queryClient.cancelQueries({ queryKey: ['dashboards', dashboardId] })
      const previous = queryClient.getQueryData(['dashboards', dashboardId])
      queryClient.setQueryData(['dashboards', dashboardId], old => ({ ...old, ...updates }))
      return { previous }
    },
    onError: (err, updates, context) => {
      // Rollback on error
      queryClient.setQueryData(['dashboards', dashboardId], context.previous)
    }
  })

  return { updateMutation }
}

// Auto-save with debounce
export function DashboardEdit({ dashboard }) {
  const { updateMutation } = useDashboardEdit(dashboard.id)
  const debouncedUpdate = useMemo(
    () => debounce((updates) => updateMutation.mutate(updates), 1000),
    [updateMutation]
  )

  return (
    <input
      defaultValue={dashboard.title}
      onChange={e => debouncedUpdate({ title: e.target.value })}
    />
  )
}
```

**장점**:
- 서버 상태와 동기화 (single source of truth)
- Optimistic updates로 즉각적인 UI 반응
- Auto-save 구현 용이 (debounce)
- 에러 시 자동 롤백

**단점**:
- Optimistic update 로직 복잡도

**권장**: Option C (TanStack Query + Optimistic Updates)

**이유**:
1. 서버 상태가 진실의 원천 (single source of truth)
2. Optimistic updates로 즉각적인 UI 반응
3. Auto-save 구현 용이 (debounce + mutation)
4. 에러 시 자동 롤백 (onError)
5. 추가 의존성 없음 (TanStack Query 이미 사용)

### [Question 5] Share Link Generation 전략

대시보드 공유 링크를 어떻게 생성하고 관리할까?

**선택지**:

**Option A: UUID-based Link**

```typescript
export async function generateShareLink(dashboardId: string) {
  const shareToken = crypto.randomUUID()
  await supabase
    .from('dashboard_shares')
    .insert({ dashboard_id: dashboardId, share_token: shareToken })

  return `https://etorch.app/share/${shareToken}`
}

// Access control
export async function getDashboardByShareToken(shareToken: string) {
  const { data } = await supabase
    .from('dashboard_shares')
    .select('dashboard_id')
    .eq('share_token', shareToken)
    .single()

  return await fetchDashboard(data.dashboard_id)
}
```

**장점**:
- 보안성 높음 (예측 불가)
- 별도 테이블로 관리 (dashboard_shares)
- 공유 링크별 접근 로그 기록 가능

**단점**:
- 추가 테이블 필요
- 두 번의 쿼리 (share_token → dashboard_id → dashboard)

**Option B: Slug-based Link (권장)**

```typescript
export async function generateShareLink(dashboardId: string, title: string) {
  const baseSlug = slugify(title)
  const uniqueSlug = await findUniqueSlug(baseSlug)

  await supabase
    .from('dashboards')
    .update({ slug: uniqueSlug, is_public: true })
    .eq('id', dashboardId)

  return `https://etorch.app/d/${uniqueSlug}`
}

// Access control
export async function getDashboardBySlug(slug: string) {
  const { data } = await supabase
    .from('dashboards')
    .select('*')
    .eq('slug', slug)
    .eq('is_public', true)
    .single()

  return data
}

// Unique slug generation
async function findUniqueSlug(baseSlug: string): Promise<string> {
  let slug = baseSlug
  let counter = 1

  while (true) {
    const { data } = await supabase
      .from('dashboards')
      .select('id')
      .eq('slug', slug)
      .single()

    if (!data) return slug
    slug = `${baseSlug}-${counter++}`
  }
}
```

**장점**:
- SEO 친화적 (의미 있는 URL)
- 단일 쿼리 (slug → dashboard)
- 추가 테이블 불필요

**단점**:
- Slug 충돌 처리 필요
- 보안성 낮음 (예측 가능)

**Option C: Hybrid (Slug + Access Token)**

```typescript
export async function generateShareLink(dashboardId: string, title: string) {
  const baseSlug = slugify(title)
  const uniqueSlug = await findUniqueSlug(baseSlug)
  const accessToken = crypto.randomUUID().slice(0, 8)  // Short token

  await supabase
    .from('dashboards')
    .update({ slug: uniqueSlug, access_token: accessToken, is_public: true })
    .eq('id', dashboardId)

  return `https://etorch.app/d/${uniqueSlug}?token=${accessToken}`
}

// Access control
export async function getDashboardBySlug(slug: string, token?: string) {
  const query = supabase
    .from('dashboards')
    .select('*')
    .eq('slug', slug)
    .eq('is_public', true)

  if (token) {
    query.eq('access_token', token)
  }

  const { data } = await query.single()
  return data
}
```

**장점**:
- SEO 친화적 + 보안성
- 선택적 토큰 (공개/비공개)

**단점**:
- URL 복잡도 증가
- 토큰 관리 필요

**권장**: Option B (Slug-based Link)

**이유**:
1. SEO 친화적 (의미 있는 URL: `/d/sp500-dashboard`)
2. 단일 쿼리로 대시보드 조회 (성능)
3. 추가 테이블 불필요 (dashboards 테이블에 slug 컬럼 추가)
4. 사용자 경험 향상 (URL 예측 가능)
5. 보안 요구사항 낮음 (공개 대시보드는 누구나 접근 가능)

### [Question 6] Legal Consent Modal 전략

대시보드 생성 시 법적 동의 모달을 어떻게 관리할까?

**선택지**:

**Option A: Session Storage**

```typescript
export function DashboardCreate() {
  const [showConsentModal, setShowConsentModal] = useState(() => {
    return !sessionStorage.getItem('consent_shown')
  })

  const handleConsent = () => {
    sessionStorage.setItem('consent_shown', 'true')
    setShowConsentModal(false)
    // No DB logging
  }

  return (
    <>
      {showConsentModal && <ConsentModal onAccept={handleConsent} />}
      <DashboardForm />
    </>
  )
}
```

**장점**:
- 간단한 구현
- DB 부하 없음

**단점**:
- 법적 기록 없음 (3년 보관 요구사항 미충족)
- 세션 종료 시 재표시

**Option B: User Profile Flag**

```typescript
export function DashboardCreate() {
  const { data: user } = useQuery({
    queryKey: ['user', 'profile'],
    queryFn: fetchUserProfile
  })

  const [showConsentModal, setShowConsentModal] = useState(!user.consent_accepted_at)

  const handleConsent = async () => {
    await supabase
      .from('profiles')
      .update({ consent_accepted_at: new Date() })
      .eq('id', user.id)

    setShowConsentModal(false)
  }

  return (
    <>
      {showConsentModal && <ConsentModal onAccept={handleConsent} />}
      <DashboardForm />
    </>
  )
}
```

**장점**:
- 사용자별 동의 상태 저장
- DB에 기록 (법적 요구사항 충족)

**단점**:
- 동의 이력 없음 (단일 timestamp만 저장)
- 약관 변경 시 재동의 처리 어려움

**Option C: ConsentLog Table (권장)**

```typescript
// Create consent log
export function useDashboardCreate() {
  const createConsentLog = useMutation({
    mutationFn: async (userId: string) => {
      await supabase.from('consent_logs').insert({
        user_id: userId,
        consent_type: 'dashboard_creation',
        consent_version: '1.0',
        ip_address: await getClientIP(),
        user_agent: navigator.userAgent,
        consented_at: new Date()
      })
    }
  })

  return { createConsentLog }
}

// Check consent status
export function useConsentStatus(userId: string) {
  return useQuery({
    queryKey: ['consent', userId, 'dashboard_creation'],
    queryFn: async () => {
      const { data } = await supabase
        .from('consent_logs')
        .select('id, consent_version, consented_at')
        .eq('user_id', userId)
        .eq('consent_type', 'dashboard_creation')
        .order('consented_at', { ascending: false })
        .limit(1)
        .single()

      const CURRENT_VERSION = '1.0'
      const needsConsent = !data || data.consent_version !== CURRENT_VERSION

      return { needsConsent, lastConsent: data }
    }
  })
}

// Component
export function DashboardCreate() {
  const { data: user } = useUser()
  const { data: consentStatus } = useConsentStatus(user.id)
  const { createConsentLog } = useDashboardCreate()

  const handleConsent = async () => {
    await createConsentLog.mutateAsync(user.id)
  }

  return (
    <>
      {consentStatus?.needsConsent && <ConsentModal onAccept={handleConsent} />}
      <DashboardForm />
    </>
  )
}
```

**장점**:
- 동의 이력 완전 기록 (3년 보관 요구사항 충족)
- 약관 버전 관리 (consent_version)
- 법적 증거 확보 (IP, User Agent)
- 약관 변경 시 재동의 처리 가능

**단점**:
- ConsentLog 테이블 추가 필요
- 추가 쿼리 필요

**권장**: Option C (ConsentLog Table)

**이유**:
1. 법적 요구사항 충족 (3년 이상 보관)
2. 동의 이력 완전 기록 (IP, User Agent, timestamp)
3. 약관 버전 관리 (변경 시 재동의 처리)
4. 감사 추적 (audit trail)
5. 법적 분쟁 시 증거 자료

### [Question 7] Dashboard Reporting Integration 전략

대시보드 신고 기능을 어떻게 구현할까?

**선택지**:

**Option A: Direct API Call**

```typescript
export function ReportModal({ dashboardId, onClose }) {
  const [reason, setReason] = useState('')

  const handleSubmit = async () => {
    await fetch('/api/reports', {
      method: 'POST',
      body: JSON.stringify({ dashboard_id: dashboardId, reason })
    })
    onClose()
  }

  return (
    <Modal>
      <select value={reason} onChange={e => setReason(e.target.value)}>
        <option value="inappropriate">부적절한 콘텐츠</option>
        <option value="misleading">오해의 소지</option>
        <option value="investment_advice">투자 자문 의심</option>
        <option value="other">기타</option>
      </select>
      <button onClick={handleSubmit}>신고</button>
    </Modal>
  )
}
```

**장점**:
- 간단한 구현

**단점**:
- Admin Moderation Feature Module과 중복
- 타입 안전성 없음
- 에러 처리 복잡

**Option B: Shared Contract from Admin Moderation**

```typescript
// packages/admin-moderation/src/contracts/AdminModerationContract.ts
export interface ReportDashboardInput {
  dashboard_id: string
  reason: 'inappropriate' | 'misleading' | 'investment_advice' | 'other'
  details?: string
}

// packages/dashboard/src/hooks/useReportDashboard.ts
import type { ReportDashboardInput } from '@etorch/admin-moderation'

export function useReportDashboard() {
  return useMutation({
    mutationFn: async (input: ReportDashboardInput) => {
      const { data, error } = await supabase
        .from('dashboard_reports')
        .insert({
          dashboard_id: input.dashboard_id,
          reason: input.reason,
          details: input.details,
          reporter_id: (await supabase.auth.getUser()).data.user?.id,
          status: 'pending'
        })

      if (error) throw error
      return data
    }
  })
}
```

**장점**:
- Admin Moderation Contract 재사용
- 타입 안전성
- 에러 처리 일관성

**단점**:
- packages/admin-moderation 의존성 추가
- 순환 의존성 위험

**Option C: Shared Types in Core + Independent Implementation (권장)**

```typescript
// packages/core/src/types/moderation.ts
export type ReportReason = 'inappropriate' | 'misleading' | 'investment_advice' | 'other'

export interface DashboardReport {
  id: string
  dashboard_id: string
  reporter_id: string
  reason: ReportReason
  details?: string
  status: 'pending' | 'reviewed' | 'dismissed'
  created_at: string
}

// packages/dashboard/src/hooks/useReportDashboard.ts
import type { ReportReason } from '@etorch/core'

export function useReportDashboard() {
  return useMutation({
    mutationFn: async (input: { dashboard_id: string; reason: ReportReason; details?: string }) => {
      const { data: user } = await supabase.auth.getUser()
      if (!user.user) throw new Error('Unauthorized')

      const { data, error } = await supabase
        .from('dashboard_reports')
        .insert({
          dashboard_id: input.dashboard_id,
          reason: input.reason,
          details: input.details,
          reporter_id: user.user.id,
          status: 'pending'
        })

      if (error) throw error
      return data
    }
  })
}

// packages/dashboard/src/components/shared/ReportModal.tsx
export function ReportModal({ dashboardId, onClose }) {
  const reportMutation = useReportDashboard()
  const [reason, setReason] = useState<ReportReason>('inappropriate')

  const handleSubmit = async () => {
    await reportMutation.mutateAsync({
      dashboard_id: dashboardId,
      reason,
      details: formData.details
    })
    toast.success('신고가 접수되었습니다.')
    onClose()
  }

  return <Modal>{/* ... */}</Modal>
}
```

**장점**:
- Core에서 공유 타입만 제공 (순환 의존성 없음)
- Dashboard Feature Module 독립적 구현
- Admin Moderation과 타입 일관성 유지
- Supabase 직접 호출로 간결

**단점**:
- Dashboard/Admin Moderation 양쪽에서 구현 필요

**권장**: Option C (Shared Types in Core + Independent Implementation)

**이유**:
1. Core에서 공유 타입만 제공 (순환 의존성 방지)
2. Dashboard Feature Module 독립적 구현 (결합도 낮음)
3. Admin Moderation과 타입 일관성 유지
4. Supabase 직접 호출로 간결 (BFF API 불필요)
5. 신고 데이터는 단순 CRUD (복잡한 비즈니스 로직 없음)

## 설계 단계 (8 Phase)

### Phase 1: 사전 조사 및 준비

- [ ] dashboard.md 14개 User Stories 분석
- [ ] Core Unit 의존성 확인 (Domain Types, Business Logic, Utilities)
- [ ] Widget Library Unit 인터페이스 확인 (WidgetContainer, WidgetProps)
- [ ] Data Integration Unit 인터페이스 확인 (useFetchData, useExportData)
- [ ] Subscription Unit 인터페이스 확인 (usePlanLimits, canCreateDashboard)
- [ ] Authentication Unit 인터페이스 확인 (useUser, useSession)
- [ ] Admin Console Unit 인터페이스 확인 (useTemplates, useCategories)

### Phase 2: Type 정의

- [ ] TypeScript Interface 작성 (20+ types)
  - [ ] DashboardListItem, DashboardDetail, DashboardCreate, DashboardUpdate
  - [ ] DashboardFilters, DashboardSort, DashboardSearch
  - [ ] TemplateListItem, TemplateFull
  - [ ] ShareLinkData, BookmarkData
  - [ ] ConsentData, DisclaimerData, ReportData
- [ ] Zod Schema 작성 (request validation용)
  - [ ] DashboardCreateSchema, DashboardUpdateSchema
  - [ ] ReportDashboardSchema
- [ ] Props 타입 정의 (30+ component props)

### Phase 3: React Components Tree 설계

- [ ] Component 계층 구조 설계 (Feature-based Hierarchy)
  - [ ] list/ (DashboardList, DashboardCard, Filters, Sort)
  - [ ] detail/ (DashboardDetail, Header, Grid, WidgetContainer)
  - [ ] create/ (DashboardCreate, Form, TemplateSelector)
  - [ ] edit/ (DashboardEdit, Toolbar, LayoutEditor)
  - [ ] shared/ (ConsentModal, DisclaimerModal, ReportModal, ShareDialog, BookmarkButton)
- [ ] Props 명세 작성 (각 컴포넌트별 props 타입)
- [ ] State 관리 전략 명세 (local state, TanStack Query)

### Phase 4: TanStack Query Hooks 설계

- [ ] Query Hooks 작성 (15+ hooks)
  - [ ] useDashboardList, useDashboardDetail, usePublicDashboards
  - [ ] useTemplates, useCategories
  - [ ] useBookmarks, useDefaultDashboard
  - [ ] useConsentStatus, useReportStatus
- [ ] Mutation Hooks 작성 (10+ hooks)
  - [ ] useCreateDashboard, useUpdateDashboard, useDeleteDashboard
  - [ ] useCloneDashboard, useCreateFromTemplate
  - [ ] useGenerateShareLink, useUpdateShareSettings
  - [ ] useBookmarkDashboard, useSetDefaultDashboard
  - [ ] useCreateConsentLog, useReportDashboard
- [ ] Query Key 전략 명세
- [ ] Cache 전략 명세 (staleTime, cacheTime, refetchOnWindowFocus)

### Phase 5: Business Logic 설계

- [ ] Selective Business Logic 작성 (4+ functions)
  - [ ] generateUniqueSlug (slug 중복 방지)
  - [ ] validateDashboardLayout (레이아웃 검증)
  - [ ] cloneDashboardWithWidgets (대시보드 복제 로직)
  - [ ] checkConsentRequired (동의 필요 여부 확인)
- [ ] Complex Validation 로직 (1+ functions)
  - [ ] validateDashboardForm (폼 검증)

### Phase 6: File Structure 설계

- [ ] packages/dashboard/ 디렉토리 구조 작성
- [ ] 파일 배치 계획 (components/, hooks/, services/, types/, schemas/)
- [ ] Export 전략 명세 (index.ts, subpath exports)

### Phase 7: Dependencies 및 Integration 설계

- [ ] Internal Dependencies 명세
  - [ ] @etorch/core (types, business logic, utils, constants)
  - [ ] @etorch/widget-library (WidgetContainer, WidgetProps)
  - [ ] @etorch/data-integration (useFetchData, useExportData)
  - [ ] @etorch/subscription (usePlanLimits, canCreateDashboard)
  - [ ] @etorch/authentication (useUser, useSession)
  - [ ] @etorch/ui (Button, Input, Modal, Dialog, etc.)
- [ ] External Dependencies 명세
  - [ ] react-grid-layout (layout engine)
  - [ ] @tanstack/react-query (data fetching)
  - [ ] zod (validation)
  - [ ] react-hook-form (form handling)
- [ ] Integration Points 명세 (Widget Library, Data Integration, Subscription)

### Phase 8: 문서 작성 및 검증

- [ ] feature_module_design.md 작성
- [ ] 타입 정의 섹션 작성 (TypeScript Interface, Zod Schema, Props)
- [ ] 컴포넌트 트리 섹션 작성 (hierarchy, props, state)
- [ ] TanStack Query Hooks 섹션 작성 (query, mutation, cache)
- [ ] Business Logic 섹션 작성 (selective functions)
- [ ] File Structure 섹션 작성
- [ ] Dependencies 섹션 작성
- [ ] 다음 단계 가이드 작성 (Implementation Phase)

## 다음 단계 (Implementation Phase)

설계 완료 후:

1. **File Structure 구축**: packages/dashboard/ 디렉토리 및 파일 생성
2. **Types 구현**: TypeScript Interface, Zod Schema 작성
3. **Hooks 구현**: TanStack Query Hooks 작성
4. **Components 구현**: React Components 작성 (list, detail, create, edit, shared)
5. **Business Logic 구현**: Services 작성 (slug generation, layout validation, clone logic)
6. **Integration 테스트**: Widget Library, Data Integration, Subscription과 통합 테스트
7. **E2E 테스트**: Playwright로 사용자 시나리오 테스트
8. **배포**: Turborepo 빌드 및 배포

## 산출물

- `docs/aidlc-docs/construction/dashboard/feature_module_design.md`
  - 20+ TypeScript Interface 정의
  - 15+ Zod Schema 정의
  - 30+ React Component 명세 (props, state, hierarchy)
  - 25+ TanStack Query Hooks 명세 (query, mutation, cache)
  - 5+ Business Logic 함수 명세
  - File Structure 명세 (packages/dashboard/)
  - Dependencies 명세 (internal/external)
  - Integration Points 명세
  - 다음 단계 가이드
  - **코드 스니펫 제외** (설계 명세만)
