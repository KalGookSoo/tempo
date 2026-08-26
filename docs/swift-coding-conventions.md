# Tempo Swift 코딩 컨벤션

## 목적

이 문서는 tempo iOS 네이티브 앱을 개발할 때 따를 Swift 코딩 컨벤션을 정의한다.
별도의 커스텀 규칙을 만들지 않고, Apple 공식 [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)를 그대로 따른다.

## 핵심 원칙

- **사용하는 곳에서의 명확성이 간결함보다 중요하다.** 이름이 길어지더라도, 호출하는 코드를 읽었을 때 무슨 일이 일어나는지 명확해야 한다.
- **모든 선언에는 문서화 주석을 남긴다.** `///`로 시작하는 문서 주석을 타입, 메서드, 속성에 작성한다.
- **모호함보다는 명확함을 우선한다.** 짧지만 애매한 이름보다, 길더라도 뜻이 분명한 이름을 쓴다.

## 대소문자 규칙

| 대상                         | 규칙                          | 예시                                             |
|----------------------------|-----------------------------|------------------------------------------------|
| 타입, 프로토콜                   | UpperCamelCase              | `TimerPreset`, `Codable`, `IntervalConfig`     |
| 변수, 상수, 함수, 메서드, enum case | lowerCamelCase              | `prepareSeconds`, `func startTimer()`, `.work` |
| 전역 상수                      | lowerCamelCase (특별한 접두사 없음) | `let defaultRounds = 8`                        |

## 네이밍

### 필요한 단어는 남기고, 불필요한 단어는 뺀다

타입 정보에서 이미 드러나는 단어는 이름에서 뺀다.

```swift
// 지양
func remove(element: Element) -> Element

// 권장
func remove(_ member: Element) -> Element
```

### 역할에 맞는 이름을 쓴다

타입이 아니라 그 값이 하는 역할을 기준으로 이름을 짓는다.

```swift
// 지양
var string: String

// 권장
var name: String
```

### 유창하게 읽히도록 이름을 짓는다

메서드 호출부가 문장처럼 읽혀야 한다.

```swift
presetRepository.insert(preset, at: sortOrder)
segments.removeAll(where: { $0.seconds == 0 })
```

### Boolean은 단정문처럼 읽히게 짓는다

```swift
var isEmpty: Bool
var hasCustomSound: Bool
func contains(_ element: Element) -> Bool
```

### 부수효과가 있는지 없는지에 따라 동사/명사를 구분한다

원본을 바꾸는(mutating) 메서드는 동사형, 새 값을 반환하는(nonmutating) 메서드는 형용사/명사형이나 `ed`/`ing`을 붙인다.

```swift
// mutating (원본을 바꿈)
array.sort()
array.append(item)

// nonmutating (새 값 반환)
let sorted = array.sorted()
let appended = array + [item]
```

이 프로젝트에서는 예를 들어 `TimerPreset`을 복제할 때 `duplicate()`(새 인스턴스 반환)와 `applyDuplicate()`(현재 인스턴스를 변경) 같은 식으로 구분한다.

### 프로토콜 이름

- 어떤 능력을 나타내는 프로토콜: `-able`/`-ible` 접미사 (`Codable`, `Equatable`)
- 무엇인지를 나타내는 프로토콜: 명사 (`Collection`, `SoundAssetRepository`)

### 인자 레이블(argument label)

- 인자를 구분할 필요가 없으면 레이블을 생략한다: `min(a, b)`
- 그 외에는 레이블을 붙여서 호출부가 문장처럼 읽히게 한다: `Timer(prepareSeconds: 10, rounds: 8)`
- 팩토리 메서드는 `make`로 시작한다: `static func makeDefaultPreset() -> TimerPreset`

## 접근 제어

- 기본값은 `private`(또는 `fileprivate`)로 최대한 좁게 잡는다.
- 다른 타입/모듈에서 실제로 필요할 때만 `internal`(기본값, 생략 가능) 또는 `public`으로 넓힌다.
- SwiftData `@Model` 클래스의 저장 프로퍼티처럼 외부에서 읽고 써야 하는 경우를 제외하면, 계산이나 헬퍼 로직은 `private`으로 감춘다.

## 불변성

- 값이 바뀌지 않으면 `var`보다 `let`을 쓴다.
- 구조체(`struct`)를 기본으로 쓰고, SwiftData `@Model`처럼 참조 타입(`class`)이 꼭 필요한 경우에만 클래스를 쓴다.

## 코드 구성

- 프로토콜 conformance는 `extension`으로 분리한다.

```swift
struct IntervalSegment {
    var type: Kind
    var seconds: Int
}

extension IntervalSegment: Codable {}
extension IntervalSegment: Hashable {}
```

- 파일 안에서 섹션을 나눌 때는 `// MARK: -`를 쓴다.

```swift
// MARK: - Lifecycle

// MARK: - Actions
```

- 조건에서 일찍 빠져나갈 때는 `if`보다 `guard`를 우선한다.

```swift
guard let program = program else { return }
```

## 문서화 주석

공개 타입/메서드/속성에는 `///` 문서 주석을 남긴다.

```swift
/// 저장된 인터벌 프로그램을 이름 기준으로 조회한다.
/// - Parameter name: 검색할 프로그램 이름.
/// - Returns: 일치하는 프로그램. 없으면 `nil`.
func findPreset(named name: String) -> TimerPreset?
```

## 포맷팅

들여쓰기 정리는 Xcode의 `Editor > Structure > Re-Indent` (`Ctrl + I`)로도 할 수 있지만, 줄바꿈/공백/import 정렬 같은 세부 포맷팅까지 일관되게 맞추기 위해 **SwiftFormat**을 사용한다.

### 설치

```bash
brew install swiftformat
```

### 설정

저장소 루트의 `.swiftformat` 파일에 규칙을 정의한다. 커스텀 규칙은 최소로 두고, 프로젝트의 Swift 버전(`SWIFT_VERSION = 5.0`)과 Xcode 기본 들여쓰기(4 스페이스)만 명시한다.

```text
--swiftversion 5.0
--indent 4
```

### 사용

```bash
# 포맷팅 위반 여부만 확인 (파일을 바꾸지 않음)
swiftformat --lint tempo/tempo

# 실제로 포맷 적용
swiftformat tempo/tempo
```

커밋 전에 `swiftformat --lint`로 확인하는 것을 권장한다. 반복적으로 수행하려면 Xcode의 `Build Phases`에 `swiftformat "$SRCROOT"` 같은 Run Script 단계를 추가해서 빌드할 때마다 자동으로 정리되게 할 수도 있다 (선택 사항).
