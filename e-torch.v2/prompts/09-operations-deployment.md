# AI DLC 프롬프트 - E-Torch

## 9. 품질 보증 단계(Operations) - Vercel 배포 및 모니터링 계획

```bash
단계 3.2: Vercel 배포 및 모니터링 계획

당신의 역할: 전문 SRE (Site Reliability Engineer)로서, E-Torch를 Vercel에 배포하고 운영 모니터링 및 유지보수 계획을 수립하는 업무를 담당합니다.

앞으로의 작업을 계획하고 docs/aidlc-docs/operations/plan_deployment.md 파일에 계획의 각 단계별로 체크박스와 함께 단계를 작성하세요.

어떤 단계든 제가 확인이 필요한 부분이 있다면 [Question] 태그와 함께 질문을 추가하고 제가 답변을 채울 수 있도록 빈 [Answer] 태그를 생성하세요. 중요한 결정을 스스로 내리지 마세요.

계획을 완료한 후에는 제 검토와 승인을 요청하세요. 제 승인을 받은 후에는 계획을 한 번에 한 단계씩 실행할 수 있습니다. 각 단계를 완료할 때마다 계획서의 체크박스를 완료로 표시하세요.

당신의 과제: E-Torch 전체 시스템을 Vercel에 배포하고 운영 모니터링 체계를 구축합니다.

참고 문서:
- BFF API 설계: docs/aidlc-docs/construction/*/bff_api_design.md
- 구현 계획: docs/aidlc-docs/construction/*/implementation_plan.md

## Vercel 배포 전략

**Monorepo 배포**
- apps/web (사용자 대시보드)
- apps/admin (관리자 콘솔, 향후)
- Turborepo로 공유 패키지 자동 번들

**Environment Variables**
- Supabase: URL, Anon Key, Service Role Key
- TossPay: Secret Key, Client Key
- External APIs: KOSIS, ECOS, OECD API Keys

**Serverless Functions**
- 최대 실행 시간: 10초 (Hobby) / 60초 (Pro)
- Cold Start 최소화: Edge Runtime 활용

**Git 브랜치 전략**
- main → Production 배포
- develop → Preview 배포
- feature/* → Preview 배포

**Supabase 연동**
- Database Migrations (Supabase CLI)
- RLS (Row Level Security) 정책 설정

## 모니터링 전략

**1. Vercel Analytics**
- Core Web Vitals (LCP, FID, CLS)
- 페이지별 성능
- Serverless Functions 성능

**2. Supabase Dashboard**
- Database Performance (쿼리 실행 시간)
- RLS 정책 성능
- Storage 사용량

**3. TanStack Query DevTools**
- 개발 환경에서 캐시 상태 확인
- Production에서는 비활성화

**4. 에러 추적 (Sentry, 향후)**
- Frontend 에러 추적
- API 에러 추적
- Source Map 연동

## 성능 목표 (SLA)

**Frontend 성능**
- 차트 렌더링: < 2초
- 초기 로드 (LCP): < 2.5초
- 상호작용 응답 (FID): < 100ms

**Backend 성능**
- API 응답: < 500ms (p95)
- Supabase 쿼리: < 100ms (p95)

**가용성**
- Uptime: > 99.9%
- 에러율: < 1%

## 산출물

docs/aidlc-docs/operations/deployment_plan.md 파일에 다음을 포함하세요:

1. 배포 전략 개요 (Vercel 프로젝트, 환경변수, Serverless Functions)
2. 배포 워크플로우 (Git 브랜치, 자동 배포, 체크리스트)
3. Supabase 연동 (Migrations, RLS 정책)
4. CI/CD 파이프라인 (GitHub Actions)
5. 모니터링 전략 (Vercel Analytics, Supabase, DevTools, Sentry)
6. 성능 목표 (SLA)
7. 유지보수 계획 (Feature Module 업데이트, API 버전 관리, 의존성 업데이트)
8. 장애 대응 계획 (감지, 대응 절차, Rollback)

코드 스니펫을 생성하지 마세요. 계획 문서만 작성하세요.
```
