# AI DLC 프롬프트 - E-Torch

## 1. 시스템 아키텍트 역할 부여

```bash
당신의 과제: E-Torch 경제지표 대시보드 서비스를 구축하는 프로젝트를 수행합니다.

**프로젝트 배경:**
- 경제 데이터 분석가들이 여러 소스(KOSIS, ECOS, OECD)의 데이터를 통합 분석하기 어려움
- 맞춤형 대시보드 구성의 어려움
- 비전문가도 쉽게 사용할 수 있는 시각화 도구 부재

**통합 목표:**
- 9가지 차트/텍스트 위젯으로 경제지표 시각화
- 드래그앤드롭 방식의 대시보드 편집기
- KOSIS, ECOS, OECD, CUSTOM 데이터 소스 통합
- Google, Kakao SNS 로그인
- Free/Pro 구독 플랜 관리

**핵심 기능 영역:**
- 위젯 관리 (9가지 차트/텍스트 위젯 생성/편집/공유)
- 대시보드 관리 (드래그앤드롭 레이아웃 편집, 공유, 버전 관리)
- 데이터 통합 (KOSIS, ECOS, OECD, CUSTOM API 통합 및 캐싱)
- 인증 (Google, Kakao OAuth, Supabase Auth)
- 구독 관리 (Free/Pro 플랜, 동적 제한 관리)
- 관리자 콘솔 (지표 관리, 사용자 관리, 컨텐츠 관리)

**기술 스택:**
- Frontend: Next.js 15 (App Router) + React 19
- Styling: Tailwind CSS + Radix UI
- State: Zustand (Client) + TanStack Query (Server)
- Charts: Recharts
- Backend: Next.js API Routes (BFF Pattern)
- Database: Supabase PostgreSQL
- Auth: Supabase Auth
- Deployment: Vercel + Supabase
- Monorepo: Turborepo + pnpm workspace

**아키텍처 전략:**
- BFF (Backend-for-Frontend) + Feature Module Architecture
- Multi-Zone: apps/web (사용자), apps/admin (관리자)
- 9개 packages: authentication, dashboard, widget-library, data-integration, subscription, admin-console, query, ui, core
- TypeScript Interface + Zod Schema 기반 타입 안정성
- TanStack Query를 통한 서버 상태 관리
- DDD 패턴 미사용 (Aggregate, Repository, Domain Events 없음)

**제약사항:**
- Vercel Serverless Functions: 최대 10초 실행 시간
- Supabase Free Tier: 500MB 데이터베이스
- KOSIS/ECOS/OECD API: Rate Limiting 준수
- 초기 로드 (LCP): < 2.5초

이 프로젝트를 AI-DLC 방식으로 접근하여, BFF + Feature Module 기반의 확장 가능한 데이터 시각화 솔루션을 설계해주세요.
```
