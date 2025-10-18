# 프롬프트 01: 시스템 아키텍트 역할 부여

```bash
당신의 과제: 학습 콘텐츠 자동화 시스템 개선 프로젝트를 수행합니다.

**프로젝트 배경:**
- 현재 7개 AI 에이전트가 순차 실행되어 학습 콘텐츠 자동 생성
  * content-initiator: 파일 초기화
  * overview-writer: Overview 섹션 생성
  * concepts-writer: Core Concepts 섹션 생성 (Easy/Normal/Expert 3단계)
  * visualization-writer: React 시각화 컴포넌트 생성
  * practice-writer: Code Patterns + Experiments 생성
  * quiz-writer: Quiz 섹션 생성
  * content-validator: 품질 검증
- 데이터 전달: Work Status Markers (HTML 주석) + 마크다운 파일
- 오케스트레이션: Bash 스크립트 순차 실행
- 1개 콘텐츠 생성 소요 시간: 50-80분

**현재 시스템 한계:**
- 에이전트 간 입출력 계약이 암묵적
- Work Status Markers 표준화 부재
- 재시작 메커니즘 없음 (중간 실패 시 처음부터 재실행)
- 품질 측정 방법 부재 (Pass/Fail만 제공)

**선정된 아키텍처:**
- Modular Monolithic Pipeline Architecture
- 설계 방법: DDD 경량화 (Bounded Context = Filter)

**개선 목표:**
- Filter 계약 명시화
- Pipe 메커니즘 설계 (Work Status Markers 표준)
- 에이전트 프롬프트 개선
- 오케스트레이션 스크립트 개선
- 품질 측정 시스템 구축

이 시스템을 AI-DLC 방식으로 접근하여, 명시적이고 개선 가능한 Pipeline Architecture로 발전시켜주세요.
```
