# Tempo 테스트 전략

moov 프로젝트에서는 "집계·계산 로직을 View 안에 그대로 두면 나중에 View를 인스턴스화하지 않고는 테스트할 수 없다"는 문제를 구현 이후에야 발견해 되돌아가 리팩터링했다. tempo는 이 문서의 원칙을 구현 시작 시점부터 지켜, 같은 실수를 반복하지 않았다.

## 현재 상태

- `tempoTests`에 순수 로직(엔진/디텍터/리포지토리) 유닛 테스트가 여럿 있다(`IntervalRunnerTests`, `CueEventDetectorTests`, `TimerEngineTests`, `StopwatchEngineTests`, `PresetRepositoryTests` 등) — 전부 **Swift Testing**(`import Testing`, `@Test`, `#expect`)으로 작성한다.
- `tempoUITests/tempoUITests.swift`는 Xcode 템플릿 스캐폴딩 그대로 **XCTest**로 남아있다 — 아래 "UI 테스트" 절의 핵심 플로우는 아직 자동화되지 않았다.
- CI(`.github/workflows/ci.yml`)는 빌드/포맷만 자동 확인한다 — GitHub 호스팅 러너의 시뮬레이터 런타임 구성 문제로 유닛/UI 테스트는 CI에 자동화돼 있지 않다. PR을 올리기 전에 로컬에서 `xcodebuild test`로 직접 돌려서 통과를 확인한다(`.github/CONTRIBUTING.md` "풀 리퀘스트 제출" 참고).

## 원칙: 시간 계산/스케줄링 로직은 View 밖의 순수 타입으로 분리한다

타이머 앱의 핵심은 "시간이 흐르는 동안의 상태 전이" 그 자체이지 화면이 아니다. 인터벌 진행 계산, 큐 트리거 판정, 프리셋 검증을 View의 `@State`나 타이머 콜백 클로저 안에 직접 넣지 않는다. `Timer.publish` 등 실제 시계열은 얇은 어댑터로만 쓰고, "현재 틱에서 무엇을 해야 하는가"는 SwiftData `@Model`이나 View에 의존하지 않는 순수 struct/함수로 계산한다. `docs/local-persistence-strategy.md`가 이미 `IntervalConfig`/`CueConfig`를 `Codable` struct로 분리해둔 것과 같은 방향이다.

## 유닛 테스트 (`tempoTests`, Swift Testing)

우선순위:

1. **인터벌 실행 시퀀스 계산** — `IntervalConfig(rounds, prepareSeconds, segments)` → 실행할 구간을 순서대로 펼친 배열(`Fn`/`Cn` 라벨, 라운드 반복 포함). `docs/timer-functional-spec.md`의 "피라미드 인터벌" 예시(`F1 01:30`/`C1 00:30`/`F2 01:00`/`C2 00:20`/`F3 00:30`/`C3 00:10`을 8라운드 반복)와 "EMOM" 예시(휴식 `00:00` 구간은 건너뜀)를 그대로 테스트 케이스로 옮긴다.
2. **기본 프리셋 값 고정(회귀 테스트)** — seed되는 `tabata`(20초/10초/8라운드), `fgb_3r`(5분/1분/3라운드), `emom`(휴식 0초, 최대 99회)이 스펙 수치와 정확히 일치하는지. 나중에 실수로 숫자가 바뀌는 것을 막는다.
3. **시간 표시 포맷팅** — 타이머 `MM:SS`(`00:00`~`99:59`), 스톱워치 `MM:SS.CS`(`00:00.00`~`99:59.99`), 인터벌 `Fn`/`Cn` 라벨. 최댓값·0 근접 경계값을 포함한다.
4. **알림 큐 트리거 판정** — 경과/잔여 시간과 `CueConfig`(`countdownLeadSeconds: 3` 등)를 입력받아 "지금 어떤 이벤트가 발동해야 하는가"를 판정하는 순수 함수. 준비 카운트다운 시작/시작 전 카운트다운/운동 시작/휴식 시작/구간 종료/운동 종료/라운드 종료/마지막 라운드 진입/전체 종료, 9개 이벤트 각각 최소 1개 케이스를 둔다.
5. **프리셋 입력값 검증** — 인터벌 세트 수(1~9), 라운드 수(1~99), 구간 시간(`00:00`~`99:59`) 범위를 벗어난 입력을 거부하는지.
6. **SwiftData 통합 테스트**(in-memory `ModelContainer`) — 앱 최초 실행 시 기본 프리셋 3개가 seed되는지, 프리셋(기본/커스텀 구분 없이) 생성·수정·삭제가 정상 동작하는지, 기본 프리셋을 복제해 만든 `custom` 프리셋을 수정해도 원본이 그대로인지, `SoundAsset`/`TimerPreset`을 soft delete(`deletedAt` 설정)한 뒤 목록 조회에서 제외되는지, soft delete된 기본 프리셋이 앱 재실행 시 다시 시드되지 않는지.
7. **사운드 파일 경로 생성 규칙** — `SoundAsset.id` 기반으로 `sounds/imported/`·`sounds/recorded/` 아래 파일명이 생성되고, 사용자가 입력한 이름을 파일명으로 그대로 쓰지 않는지.

3, 4, 5, 7번은 순수 함수/타입만으로 검증 가능하다. 6번만 `ModelContainer(for:, isStoredInMemoryOnly: true)`를 매 테스트마다 새로 만드는 공통 헬퍼가 필요하다.

## UI 테스트 (`tempoUITests`, XCTest)

전체 화면 조합을 다 훑지 않고, 회귀가 가장 아플 핵심 플로우만 커버한다.

1. 홈 → 타이머 → 모드 토글(카운트다운 ↔ 카운트업) → 시작 → 일시정지 → 재개 → 리셋
2. 홈 → 인터벌 → 새 프로그램(이름/구간/라운드 입력) → 저장 → 프로그램 상세 화면에 반영
3. 프로그램 목록 → 상세 → 실행 → 완료 → 홈 복귀(`navigationPath` 전체 초기화 확인)
4. 기본 제공 프리셋(Tabata) 복제 → 이름 변경 → 저장 → 사용자 프리셋 목록에 별도 항목으로 반영되고 원본 기본 프리셋은 그대로 남아있는지

## 컨벤션

- 유닛 테스트는 Xcode가 이미 스캐폴딩한 대로 **Swift Testing**(`import Testing`, `@Test`, `#expect`)을 쓴다. XCTest로 되돌리지 않는다.
- UI 테스트는 템플릿대로 **XCTest** 유지.
- 인메모리 `ModelContainer` 생성 헬퍼를 `tempoTests` 내 공용 파일로 두어 테스트마다 중복 작성하지 않는다.

## 다음 단계

남은 건 "UI 테스트" 절에 나열한 핵심 플로우 4가지를 `tempoUITests`에 실제로 작성하는 것이다. 그 전까지는 회귀를 사람이 직접 확인해야 한다.
