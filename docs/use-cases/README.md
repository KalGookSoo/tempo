# Tempo 사용자 유즈케이스

이 디렉터리는 tempo MVP의 기능별 사용자 유즈케이스를 정리한다.

Mermaid 다이어그램은 라이트 모드와 다크 모드에서 모두 읽기 쉽도록 고대비 색상만 사용한다.

## 문서 목록

- [타이머](./timer.md)
- [스톱워치](./stopwatch.md)
- [인터벌 타이밍](./interval-timing.md)
- [프리셋 관리](./preset-management.md)
- [알림 큐](./notification-cues.md)
- [미러링 실행 화면](./mirrored-timer-display.md)

## 공통 Mermaid 색상 기준

- 기본 노드: 흰 배경, 검은 텍스트, 검은 선
- 사용자 액션: 연한 노란 배경, 검은 텍스트, 검은 선
- 종료/완료: 연한 초록 배경, 검은 텍스트, 검은 선
- 오류/취소: 연한 빨강 배경, 검은 텍스트, 검은 선

## 앱 내 도움말과의 관계

설정 탭 "도움말"(`tempo/tempo/Views/Help/HelpTopic.swift`의 `HelpLibrary`)은 이 문서들의
"목적"/"기본 흐름"을 화면에 맞게 요약·각색한 것이다. 이 디렉터리의 문서가 원본(source of
truth)이므로, 기능이 바뀌면 여기 문서를 먼저 갱신하고 `HelpLibrary`의 해당 주제도 같이
갱신한다.
