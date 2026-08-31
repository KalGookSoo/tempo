# Tempo 로컬 영속화 전략

## 목적

tempo MVP는 네트워크 없이도 사용자의 인터벌 프리셋, 알림 큐 설정, 사운드 설정을 유지해야 한다.
이 문서는 로컬 우선 저장 전략을 정의한다.

## 결론

MVP의 기본 저장소는 `SwiftData`로 둔다.
사용자가 추가한 음원 파일과 직접 녹음 파일은 파일 시스템(`FileManager`)에 저장하고, SwiftData 모델에는 파일 식별자와 경로만 저장한다.

권장 프레임워크:

- `SwiftData`: 프리셋, 설정, 사운드 메타데이터 저장. `@Model` 매크로로 스키마를 Swift 코드로 선언하고, SwiftUI의 `@Query`와 바로 연동한다.
- `FileManager`: 사용자 음원 파일과 녹음 파일 저장.

SwiftData는 Apple의 기본 퍼시스턴스 프레임워크이므로, 별도 서드파티 DB 라이브러리를 붙이지 않고 iOS 표준 스택만으로 구현한다.

## 저장 대상

| 대상          | 저장소                    | 이유                                        |
|-------------|------------------------|-------------------------------------------|
| 기본 인터벌 프리셋  | 앱 코드 + SwiftData seed  | 기본값은 코드로 관리하고, 앱 최초 실행 시 저장소에 반영한다.       |
| 사용자 인터벌 프리셋 | SwiftData              | 이름, 라운드, 세트, 큐 옵션을 구조화해서 조회해야 한다.         |
| 알림 큐 설정     | SwiftData              | 전역 기본값과 프리셋별 오버라이드를 함께 다뤄야 한다.            |
| 사운드 큐 메타데이터 | SwiftData              | 기본 사운드, 사용자 파일, 녹음 파일을 같은 방식으로 선택해야 한다.   |
| 사용자 음원 파일   | File System            | 바이너리 파일은 모델에 넣지 않는다.                      |
| 직접 녹음 파일    | File System            | 파일로 저장하고 모델에는 참조만 남긴다.                    |
| 표시 설정       | SwiftData 모델(`AppSettings`) | 설정 항목 수가 적어 key-value 대신 필드별 타입 있는 속성으로 관리한다. |

## 저장하지 않을 대상

- 실행 중인 타이머의 매 tick 값
- 타이머의 카운트다운 / 카운트업 설정값
- 최근 실행 기록
- 히스토리 화면용 데이터
- 일시적인 UI 상태
- 화면 미러링 연결 상태

실행 중 앱이 종료된 뒤 복구가 필요해지면 `ActiveTimerSession` 같은 별도 모델을 추가한다.
MVP에서는 먼저 프리셋과 사용자 설정 영속화에 집중한다.

## MVP 제외 대상

### 최근 실행 기록과 히스토리

최근 실행 기록과 히스토리는 1차 MVP에서 제외한다.

- 사용자가 반복해서 쓰는 값은 실행 기록보다 프리셋으로 저장하는 편이 더 명확하다.
- 히스토리는 목록, 상세, 삭제, 보존 기간 같은 부가 정책을 함께 요구한다.
- 현재 목표는 운동 타이머를 빠르게 설정하고 실행하는 것이다.
- 기록을 저장하면 데이터 모델과 화면 범위가 커지지만, 핵심 사용성에 바로 필요하지 않다.

나중에 운동 로그, 통계, 최근 사용한 설정 다시 실행 기능이 필요해지면 별도 단계에서 추가한다.

## 왜 UserDefaults만 쓰지 않는가

`UserDefaults`는 간단한 설정 저장에는 좋지만, tempo의 핵심 데이터에는 약하다.

- 프리셋 목록, 기본 프리셋, 사용자 프리셋을 필터링하거나 정렬하기 어렵다.
- 프리셋별 알림 큐와 사운드 큐가 서로 참조될 때 하나의 plist 값이 계속 커진다.
- 마이그레이션 실수가 발생하면 전체 데이터를 망가뜨리기 쉽다.
- `@Query`로 SwiftUI 뷰에 자동 반영되는 이점을 얻을 수 없다.

따라서 SwiftData를 기준으로 잡고, 단순 설정(`AppSettings`)도 같은 저장 계층에서 모델로 관리한다.

## 데이터 모델

SwiftData는 `schema_migrations` 같은 버전 테이블을 직접 만들지 않는다. 스키마 버전 관리는 [마이그레이션 원칙](#마이그레이션-원칙)에서 설명하는 `VersionedSchema`/`SchemaMigrationPlan`으로
처리한다. 아래는 초기 스키마(SchemaV1)에 포함되는 모델이다.

### `TimerPreset`

기본 프리셋과 사용자 프리셋을 저장한다.

```swift
@Model
final class TimerPreset {
    @Attribute(.unique) var id: UUID
    var kind: PresetKind        // .default 또는 .custom
    var mode: String            // "interval"
    var name: String
    var presetDescription: String?
    var config: IntervalConfig  // 타이머 설정 (아래 정의 참고). String이 아닌 구조화된 타입으로 저장한다.
    var cueProfileID: UUID?
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?        // soft delete
}

enum PresetKind: String, Codable {
    case `default`
    case custom
}
```

MVP에서 프리셋은 인터벌 전용이다.
타이머의 카운트다운과 카운트업은 프리셋으로 저장하지 않는다.

`IntervalConfig` 정의 — SwiftData는 `Codable` struct/enum을 모델 속성 타입으로 직접 저장할 수 있으므로, JSON 문자열로 직렬화하지 않고 아래처럼 타입 있는 struct를 그대로 쓴다. 잘못된 필드명이나 값 타입은 컴파일 타임에 걸러진다.

```swift
struct IntervalConfig: Codable, Hashable {
    var rounds: Int
    var prepareSeconds: Int
    var segments: [IntervalSegment]
}

struct IntervalSegment: Codable, Hashable {
    enum Kind: String, Codable {
        case work
        case rest
    }
    var type: Kind
    var seconds: Int
}
```

예시:

```swift
IntervalConfig(
    rounds: 8,
    prepareSeconds: 10,
    segments: [
        IntervalSegment(type: .work, seconds: 20),
        IntervalSegment(type: .rest, seconds: 10),
    ]
)
```

### `CueProfile`

알림 큐 프로필을 저장한다.

```swift
@Model
final class CueProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var isDefault: Bool
    var config: CueConfig       // 큐 규칙 (아래 정의 참고). String이 아닌 구조화된 타입으로 저장한다.
    var createdAt: Date
    var updatedAt: Date
}
```

`CueConfig` 정의:

```swift
struct CueConfig: Codable, Hashable {
    enum Mode: String, Codable, CaseIterable, Identifiable {
        case none
        case sound
        case vibration
        case soundAndVibration
    }

    struct Event: Codable, Hashable {
        var mode: Mode
        var soundAssetID: UUID?   // SoundAsset.id 참조, nil이면 MVP 기본 사운드
    }

    var countdownLeadSeconds: Int   // 시작 전 알림 시점(초). 0/1/3/5/10 중 선택, 0=없음
    var prepareStart: Event
    var workStart: Event
    var restStart: Event
    var segmentEnd: Event
    var roundEnd: Event
    var finalRoundEnter: Event
    var finish: Event
}
```

이벤트는 `docs/timer-functional-spec.md` "알림 큐"가 정의한 8개(시작 전 카운트다운은 `countdownLeadSeconds` 하나로 전역 처리, 나머지 7개는 이벤트별 `Mode`) 그대로 대응한다. `soundId: String`(항상 값이 있어야 하는 문자열) 대신 `soundAssetID: UUID?`로 바꿔서, "사운드 없음"을 컴파일 타임에 안전하게 표현하고 `SoundAsset` 테이블을 직접 참조한다 — 임의의 문자열 ID를 손으로 맞추는 대신 실제 존재하는 사운드 row만 가리킬 수 있다.

예시:

```swift
let event = CueConfig.Event(mode: .soundAndVibration, soundAssetID: nil)
CueConfig(
    countdownLeadSeconds: 3,
    prepareStart: event,
    workStart: event,
    restStart: event,
    segmentEnd: event,
    roundEnd: event,
    finalRoundEnter: event,
    finish: event
)
```

### `SoundAsset`

기본 사운드, 사용자 음원, 직접 녹음 음성 큐를 관리한다.

```swift
@Model
final class SoundAsset {
    @Attribute(.unique) var id: UUID
    var kind: SoundAssetKind     // .builtin, .imported, .recorded
    var name: String
    var relativePath: String?   // 파일 시스템 경로(문서 디렉터리 기준 상대 경로) 또는 앱 asset 이름
    var durationMs: Int?
    var createdAt: Date
    var deletedAt: Date?        // soft delete
}

enum SoundAssetKind: String, Codable {
    case builtin
    case imported
    case recorded
}
```

사용자 파일을 삭제할 때는 모델을 soft delete하고, 실제 파일 삭제 실패 가능성을 별도 처리한다.

### `AppSettings`

설정 항목이 몇 개뿐이므로, 범용 key-value 모델 대신 필드별로 타입 있는 속성을 가진 단일 모델로 관리한다. 새 설정이 필요해지면 필드를 추가하면 되고, 문자열 key로 값을 찾아 JSON을 디코딩하는 간접 단계가 없어 컴파일 타임에 타입이 보장된다.

```swift
@Model
final class AppSettings {
    var themeMode: ThemeMode          // .system, .light, .dark
    var bigTimerDigitsEnabled: Bool
    var updatedAt: Date
}

enum ThemeMode: String, Codable {
    case system
    case light
    case dark
}
```

앱 인스턴스당 `AppSettings` row는 하나만 존재한다 (없으면 seed 단계에서 기본값으로 생성한다).

## 기본 프리셋 seed 전략

기본 프리셋은 앱 코드에 선언한다.

- `tabata`
- `fgb_3r`
- `emom`

앱 시작 시 저장소가 비어 있으면 기본 프리셋을 삽입한다.
기본 프리셋도 사용자가 수정·삭제할 수 있다(다른 프리셋과 동일하게 soft delete로 처리한다). 앱 업데이트로 기본값이 바뀌면 `seed_version` 기준으로 필요한 항목만 갱신한다.
사용자가 기본 프리셋을 삭제하면, 앱을 재실행해도 다시 생기지 않는다(시드 여부 판정이 `deletedAt`을 보지 않고 `kind == .default` row 존재만 확인하기 때문).

사용자는 기본 프리셋을 직접 수정할 수도 있고, 원본을 바꾸지 않고 싶으면 `custom` 프리셋으로 복제해서 편집할 수도 있다.

## 파일 저장 전략

사용자 음원과 녹음 파일은 앱 전용 document directory(`FileManager.default.urls(for: .documentDirectory, ...)`) 아래에 저장한다.

권장 디렉터리:

```text
sounds/
  imported/
  recorded/
```

파일명은 사용자 입력 이름을 직접 쓰지 않는다.
`SoundAsset.id` 기반으로 생성한다.

예시:

```text
sounds/recorded/sound_7f3a9c.m4a
sounds/imported/sound_a91bd2.mp3
```

모델에는 파일 경로와 메타데이터만 저장한다.
파일이 사라진 경우 앱은 해당 사운드를 사용할 수 없음 상태로 표시하고, 기본 사운드로 대체한다.

## 마이그레이션 원칙

- 모든 스키마 변경은 SwiftData의 `VersionedSchema`로 버전을 나누어 관리한다 (`SchemaV1`, `SchemaV2`, ...).
- 버전 간 변환은 `SchemaMigrationPlan`에 마이그레이션 stage로 정의한다. 속성 추가/삭제처럼 단순한 변경은 SwiftData의 lightweight 마이그레이션으로 자동 처리되고, 데이터 변환이 필요한 변경만 커스텀 stage를
  작성한다.
- 마이그레이션은 재실행되어도 안전해야 한다 (SwiftData가 현재 스토어 버전을 추적하고 필요한 stage만 적용한다).
- 사용자 데이터 삭제가 필요한 변경은 MVP에서는 피한다.

초기 스키마(`SchemaV1`)에 포함되는 모델:

1. `TimerPreset`
2. `CueProfile`
3. `SoundAsset`
4. `AppSettings`

## 데이터 접근 계층

화면(View)에서 SwiftData `ModelContext`를 직접 다루지 않는다.
저장소 접근은 repository 계층으로 숨긴다.

권장 구조:

```text
Data/
  Models/
    TimerPreset.swift
    IntervalConfig.swift
    CueProfile.swift
    CueConfig.swift
    SoundAsset.swift
    AppSettings.swift
  Migration/
    SchemaV1.swift
    MigrationPlan.swift
  Repositories/
    PresetRepository.swift
    CueProfileRepository.swift
    SoundAssetRepository.swift
    SettingsRepository.swift
```

화면은 repository를 통해 다음처럼 사용한다.

```swift
let presets = try await presetRepository.findIntervalPresets()
try await presetRepository.createCustomPreset(input)
```

목록을 표시하는 화면에서는 repository 대신 SwiftUI의 `@Query`로 SwiftData 모델을 직접 관찰할 수도 있다. 다만 생성/수정/삭제 같은 쓰기 동작과 seed, 파일 시스템 연동처럼 여러 모델에 걸친 로직은
repository로 모은다.

이 구조를 두면 나중에 클라우드 동기화나 백업 기능을 추가할 때 화면 코드를 크게 바꾸지 않아도 된다.

## 백업과 동기화 대비

MVP는 로컬 전용이다.
다만 나중에 계정 기반 동기화를 붙일 수 있도록 다음 규칙을 지킨다.

- 모든 사용자 생성 데이터는 `UUID`를 가진다.
- `createdAt`, `updatedAt`, `deletedAt`을 둔다.
- 삭제는 가능한 soft delete로 처리한다.

이렇게 해두면 나중에 서버 동기화, 파일 백업, 기기 이전 기능을 붙이기 쉽다.

## 구현 순서

1. SwiftData `@Model` 타입과 `ModelContainer` 설정을 추가한다.
2. 초기 스키마(`SchemaV1`)와 `SchemaMigrationPlan`을 만든다.
3. 기본 프리셋 seed를 넣는다.
4. 프리셋 repository를 만든다.
5. 인터벌 화면에서 사용자 프리셋 목록을 읽는다 (`@Query` 또는 repository).
6. 새 프리셋 저장과 편집을 repository로 연결한다.
7. 사운드 큐 메타데이터와 `FileManager` 기반 파일 저장을 연결한다.

## MVP 성공 기준

- 앱을 종료했다가 다시 열어도 사용자 프리셋이 유지된다.
- 기본 프리셋은 최초 실행 시 시드되며, 다른 프리셋과 마찬가지로 사용자가 수정·삭제할 수 있다.
- 사용자 프리셋은 생성, 수정, 삭제, 실행할 수 있다.
- 사운드 큐 설정은 앱 재시작 후에도 유지된다.
- 사용자 녹음 파일은 앱 재시작 후에도 다시 선택할 수 있다.
