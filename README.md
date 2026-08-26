# tempo

크로스핏/스트렝스 트레이닝을 염두에 둔 다목적 iOS 타이머 앱. 타이머(카운트다운/카운트업), 스톱워치, 인터벌 타이밍(Tabata/FGB/EMOM 등 기본 프리셋 포함)을 하나의 앱에서 다룬다.

Swift/SwiftUI 네이티브 앱이며, 이전에 React Native(Expo)로 개발하던 코드는 삭제하고 처음부터 다시 만들고 있다. 옛 React Native 구현은 `archive/expo-rn` 브랜치에 참고용으로 남아 있다.

## 시작하기

1. `tempo/tempo.xcodeproj`를 Xcode로 연다.
2. `tempo` 스킴을 선택하고 시뮬레이터 또는 실기기에서 실행한다.

별도 패키지 설치나 빌드 도구 설정은 필요 없다 — SwiftUI + SwiftData 표준 스택만 사용한다.

## 기술 스택

- Swift, SwiftUI
- SwiftData(로컬 영속화)
- SwiftFormat(`.swiftformat`: `--swiftversion 5.0 --indent 4`)

## 문서

기획/설계 문서는 [`docs/`](docs)에 있다.

- [기능명세서](docs/timer-functional-spec.md)
- [내비게이션 구조도](docs/navigation-structure.md)
- [로컬 영속화 전략](docs/local-persistence-strategy.md)
- [네이티브 스타일 가이드](docs/native-style-guide.md)
- [Swift 코딩 컨벤션](docs/swift-coding-conventions.md)
- [테스트 전략](docs/testing-strategy.md)
- [유즈케이스](docs/use-cases)

## 기여

기여 방법은 [`.github/CONTRIBUTING.md`](.github/CONTRIBUTING.md)를 참고한다.
