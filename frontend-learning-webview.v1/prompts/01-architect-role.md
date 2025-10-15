# 프롬프트 1: 시스템 아키텍트 역할 부여

```bash
당신의 과제: 학습 콘텐츠 자동화 시스템 개발 프로젝트를 수행합니다.

**프로젝트 배경:**
- 현재 7개 서브에이전트가 순차적으로 학습 콘텐츠를 자동 생성하는 시스템이 작동 중
  * content-initiator → overview-writer → concepts-writer → visualization-writer → practice-writer → quiz-writer → content-validator
- 각 에이전트는 `.claude/agents/*.md` 파일로 정의됨
- 오케스트레이션: `scripts/content-generator-v6.sh`
- 출력: 마크다운 학습 콘텐츠 (public/content/ko/)

**개선 필요성:**
- 에이전트 간 입출력 계약이 암묵적
- Pipe 메커니즘(Work Status Markers)이 명시적이지 않음
- 에이전트 프롬프트 파일에 명확한 I/O 명세 부재
- 시스템 품질 측정 방법 부재

**개선 목표:**
- AI-DLC 방법론을 적용하여 시스템을 Pipeline Architecture로 명시적 설계
- 7개 에이전트 = 7개 Filter로 정의
- Filter 간 데이터 전달(Pipe) 메커니즘 명시화
- 에이전트 프롬프트 파일 개선
- 오케스트레이션 스크립트 개선
- 시스템 품질 측정 방법 구축

**핵심 구성 요소:**
- Filter: 7개 서브에이전트 (content-initiator, overview-writer, concepts-writer, visualization-writer, practice-writer, quiz-writer, content-validator)
- Pipe: Work Status Markers 기반 데이터 전달
- 오케스트레이션: Bash 스크립트로 7개 Filter 순차 실행
- 품질 검증: 파서 테스트 (test/test-*.mjs)

**제약사항:**
- 시스템은 완전 자동화 유지 (콘텐츠 생성 중 인간 개입 없음)
- 기존 생성된 콘텐츠와의 호환성 유지
- 파서 테스트 통과 필수

이 콘텐츠 생성 자동화 시스템을 AI-DLC 방법론과 Pipeline Architecture로 명시적 설계하여, 확장 가능하고 유지보수 가능한 시스템으로 개선해주세요.
```
