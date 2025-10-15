# UI Unit (공유 UI 컴포넌트 라이브러리)

## 단위 개요

**책임**: 재사용 가능한 React 컴포넌트 및 디자인 시스템 제공

**주요 목표**:
- 일관된 UI/UX 경험 제공
- apps/web과 apps/admin 간 컴포넌트 공유
- 접근성(a11y) 표준 준수
- 반응형 디자인 지원
- 테마 및 다크 모드 관리

## 컴포넌트 계층

### 1. Base Components (기본 컴포넌트)

원자적 UI 컴포넌트로 재사용성을 최대화합니다.

**제공 컴포넌트**:
- Button, Input, Select, Checkbox, Radio, Switch
- Text, Heading, Link
- Card, Container, Stack, Grid
- Badge, Spinner, Skeleton, ProgressBar
- Icon

### 2. Composite Components (복합 컴포넌트)

여러 Base Component를 조합한 복잡한 UI를 제공합니다.

**제공 컴포넌트**:
- Modal, Drawer, Dropdown, Tooltip
- Toast Notification
- Tabs, Accordion
- DataTable
- Form, FormField
- SearchBar, Pagination
- EmptyState, ErrorBoundary

### 3. Chart Components (차트 컴포넌트)

US3.1에 정의된 9가지 위젯 타입을 지원하는 차트 컴포넌트를 제공합니다.

**차트 위젯 (7개)**:
- Time Series Chart
- Bar Chart
- Pie Chart
- Treemap
- Scatter Chart
- Radar Chart
- Radial Bar Chart

**텍스트 위젯 (2개)**:
- Text Custom (Markdown 지원)
- Text Data (지표 텍스트 표시)

### 4. Layout Components (레이아웃 컴포넌트)

앱 레이아웃 및 네비게이션을 제공합니다.

**제공 컴포넌트**:
- AppShell (전체 레이아웃)
- Sidebar, Header
- Breadcrumb
- GridLayout (대시보드 위젯 레이아웃)

## 디자인 시스템

### 디자인 토큰

일관된 스타일링을 위한 변수 체계를 정의합니다.

**토큰 카테고리**:
- Colors (Primary, Neutral, Semantic)
- Spacing (xs ~ xxl)
- Typography (Font Family, Size, Weight, Line Height)
- Border Radius
- Shadows
- Breakpoints (Mobile, Tablet, Desktop, Wide)

### 테마 관리

Light/Dark 모드를 지원하며, 동적 테마 전환이 가능합니다.

**테마 요소**:
- Color Palette
- Typography Scale
- Spacing Scale
- Component Variants

## 접근성 (a11y)

### 접근성 표준

WCAG AA 표준을 준수합니다.

**지원 사항**:
- 키보드 네비게이션 (Tab, Enter, Esc, Arrow keys)
- ARIA 속성 (role, aria-label, aria-pressed 등)
- 색상 대비 (최소 4.5:1)
- 스크린 리더 지원

## 반응형 디자인

### 모바일 우선 접근

모든 컴포넌트는 모바일 우선 방식으로 설계됩니다.

**Breakpoint**:
- Mobile: 640px
- Tablet: 768px
- Desktop: 1024px
- Wide: 1280px

## 의존성

### 입력 의존성

- **@e-torch/core**: 공통 타입, 유틸리티

### 제공 대상

- **모든 Feature Module**: 재사용 가능한 UI 컴포넌트
- **apps/web**: 사용자 앱 UI
- **apps/admin**: 관리자 앱 UI

## 기술 요구사항

### 패키지 구조

```
packages/ui/
├── src/
│   ├── components/
│   │   ├── base/              # 기본 컴포넌트
│   │   ├── composite/         # 복합 컴포넌트
│   │   ├── charts/            # 차트 컴포넌트
│   │   └── layout/            # 레이아웃 컴포넌트
│   ├── theme/                 # 디자인 토큰, 테마
│   ├── hooks/                 # useToast, useTheme 등
│   └── styles/                # Tailwind 설정
├── package.json
├── tailwind.config.js
└── tsconfig.json
```

### 주요 라이브러리

- React 19
- Tailwind CSS (스타일링)
- Radix UI (Headless 접근성 컴포넌트)
- Recharts (차트 렌더링)
- react-grid-layout (위젯 레이아웃)
- lucide-react (아이콘)

### 스타일링 전략

Tailwind CSS를 기본 스타일링 도구로 사용하며, Radix UI를 활용하여 접근성이 내장된 컴포넌트를 구현합니다.

## 테스트 전략

- Storybook으로 컴포넌트 문서화
- Visual Regression Testing (Chromatic/Percy)
- 접근성 테스트 (@axe-core/react)

## 성능 최적화 전략

- 코드 스플리팅 (차트 컴포넌트 동적 import)
- 트리 쉐이킹 (Named exports)
- Virtual Scrolling (대용량 리스트)
