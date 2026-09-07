# Tempo 네이티브 스타일가이드

## 목적

이 문서는 tempo 앱의 기본 디자인 체계를 정의한다. 목표는 별도의 커스텀 디자인 시스템을 만들지 않고, **iOS/iPadOS 기본 앱(시계, 타이머 등)과 동일한 느낌의 절제된 네이티브 스타일**을 따르는 것이다. 장식보다 조작, 상태, 시간
정보가 먼저 보여야 한다는 목표는 유지하되, 이를 커스텀 컬러 팔레트나 커스텀 컴포넌트가 아니라 **시스템 기본값**으로 달성한다.

구현은 SwiftUI 표준 컴포넌트와 SF Symbols를 기준으로 한다. 커스텀 컴포넌트 라이브러리를 따로 만들지 않고, `Button`, `List`, `Form`, `NavigationStack` 같은 표준 컨트롤을 기본 스타일 그대로 사용한다.

## 디자인 원칙

- **시스템을 따른다**: 색상, 폰트, 간격, 모양 전부 iOS 표준값을 그대로 쓴다. 커스텀 값은 상태 색상처럼 기능상 꼭 필요한 경우에만 최소로 둔다.
- **꾸미지 않는다**: 그림자, 굵은 보더, 강한 색면 같은 장식 요소를 별도로 만들지 않는다.
- **빠른 판독**: 타이머 숫자와 상태 텍스트는 멀리서도 읽혀야 한다.
- **기능 우선**: 장식보다 조작, 상태, 시간 정보가 먼저 보여야 한다.
- **다크 모드는 시스템이 처리한다**: 라이트/다크 모드별 색상을 직접 정의하지 않는다. 시스템 컬러(semantic color)를 쓰면 자동으로 전환된다.

## 컬러

커스텀 팔레트를 정의하지 않는다. 배경, 표면, 텍스트, 보더는 모두 시스템 시맨틱 컬러를 그대로 사용한다 (`Color.primary`, `Color.secondary`, `Color(.systemBackground)`,
`Color(.secondarySystemBackground)`, `Color(.separator)` 등). 라이트/다크 모드 대응은 시스템이 자동으로 처리하므로 별도 팔레트 테이블이 필요 없다.

앱의 정체성과 상태를 나타내는 최소한의 강조색만 아래처럼 시스템 색상에 매핑해서 쓴다.

| 용도            | 시스템 컬러       |
|---------------|--------------|
| 앱 강조색(accent) | `.orange`    |
| 운동(work)      | `.green`     |
| 휴식(rest)      | `.teal`      |
| 준비(prepare)   | `.yellow`    |
| 종료/경고(danger) | `.red`       |
| 비활성/보조 텍스트    | `.secondary` |

이 색상들은 Xcode의 Accent Color / Asset Catalog에 등록해서 쓰고, 하드코딩된 hex 값을 쓰지 않는다. 시스템 색상이므로 라이트/다크 모드에서 자동으로 적절한 톤으로 보정된다.

## 타입 시스템

커스텀 폰트를 도입하지 않는다. 시스템 폰트(San Francisco)를 그대로 쓰고, SwiftUI의 Dynamic Type 텍스트 스타일(`.largeTitle`, `.title`, `.title2`, `.title3`, `.headline`,
`.body`, `.callout`, `.footnote`, `.caption`)을 용도에 맞게 사용한다. 사용자가 시스템 텍스트 크기를 키우면 앱 전체가 그에 맞춰 자동으로 커져야 한다.

| 용도            | 텍스트 스타일                                 |
|---------------|-----------------------------------------|
| 화면 제목         | `.largeTitle` 또는 내비게이션 타이틀 기본값          |
| 섹션 제목         | `.title2` / `.headline`                 |
| 본문            | `.body`                                 |
| 보조 설명         | `.footnote` / `.caption`                |
| 타이머 숫자(실행 화면) | `.largeTitle` 이상 + `.monospacedDigit()` |

타이머/스톱워치 숫자에는 `.monospacedDigit()` modifier를 적용해서 숫자가 바뀔 때 자릿수가 흔들리지 않게 한다. 이 외에 별도 mono 폰트나 커스텀 폰트 스택은 두지 않는다.

## 간격과 레이아웃

커스텀 spacing scale을 정의하지 않는다. SwiftUI 기본 padding, `List`/`Form`의 기본 inset, safe area를 그대로 따른다. 화면마다 임의로 다른 여백 값을 쓰지 않고, 표준 컨트롤이 제공하는 기본 여백을
우선한다.

- 커스텀 레이아웃이 꼭 필요한 화면(타이머 실행 화면 등)에서만 최소한으로 여백을 직접 조정한다.
- 리스트 형태 화면(프로그램 목록, 도움말 목록 등)은 `List`를 그대로 쓴다.

## Shape와 Elevation

- 커스텀 보더, radius, shadow 스케일을 정의하지 않는다.
- 카드, 버튼, 그룹은 표준 SwiftUI 스타일(`.buttonStyle(.bordered)`, `.buttonStyle(.borderedProminent)`, `groupedListStyle` 등)이 제공하는 모양과 그림자를 그대로 쓴다.
- 흐린 shadow든 hard shadow든 직접 그려 넣지 않는다.

## 기본 컴포넌트

커스텀 UI 컴포넌트 라이브러리를 따로 만들지 않는다. SwiftUI가 기본으로 제공하는 컴포넌트를 그대로 쓴다.

| 용도       | SwiftUI 컴포넌트                                           |
|----------|--------------------------------------------------------|
| 화면/섹션 제목 | Navigation title, `Text` + 표준 텍스트 스타일                  |
| 본문, 설명   | `Text`                                                 |
| 목록       | `List`, `Section`                                      |
| 버튼       | `Button` (`.bordered`, `.borderedProminent`, `.plain`) |
| 입력       | `TextField`, `Stepper`, `Picker`(wheel)                |
| 선택/토글    | `Toggle`, `Picker` (segmented)                         |
| 구분선      | `Divider` 또는 `List`의 기본 구분선                            |
| 액션 목록/메뉴 | `Menu`, `ContextMenu`                                  |

화면 코드에서 매번 스타일을 직접 반복해서 붙이지 않는다는 원칙은 유지하되, 이를 위해 커스텀 컴포넌트를 만드는 대신 표준 컴포넌트 + `ViewModifier`(스타일이 정말 반복되는 경우에만) 정도로 최소화한다.

### 버튼

- 주요 실행(시작, 저장): `.borderedProminent`, tint는 상황에 맞는 상태 색상(`work`) 또는 앱 강조색(`accent`).
- 보조 동작(편집, 복제, 취소): `.bordered` 또는 `.plain`.
- 파괴적 동작(삭제, 초기화): `.bordered` + `role: .destructive` (시스템이 자동으로 빨간색 처리).
- 최소 터치 영역은 44x44를 유지한다 (표준 컨트롤은 기본으로 이 값을 충족한다).

### 타이머 표시

- 앱의 핵심 컴포넌트다. 시간 숫자는 화면에서 가장 커야 한다.
- 운동 상태는 `work`, 휴식 상태는 `rest`, 준비 상태는 `prepare`, 종료/경고 상태는 `danger` 색상을 tint로 사용한다.
- 숫자는 `.monospacedDigit()`을 적용해 레이아웃이 흔들리지 않게 한다.
- 별도의 카드나 프레임으로 감싸지 않고, 화면 배경 위에 숫자와 상태 텍스트만 크게 배치하는 것을 우선한다.

## Iconography

아이콘은 SF Symbols를 사용한다. 커스텀 아이콘 세트를 도입하지 않는다.

| 기능    | SF Symbol                          |
|-------|------------------------------------|
| 시작    | `play.fill`                        |
| 일시정지  | `pause.fill`                       |
| 정지    | `stop.fill`                        |
| 리셋    | `arrow.counterclockwise`           |
| 편집    | `pencil`                           |
| 저장    | `checkmark`                        |
| 삭제    | `trash`                            |
| 복제    | `plus.square.on.square`            |
| 사운드   | `speaker.wave.2.fill`              |
| 무음    | `speaker.slash.fill`               |
| 진동    | `iphone.radiowaves.left.and.right` |
| 녹음    | `mic.fill`                         |
| 설정    | `gearshape.fill`                   |
| 프리셋   | `list.bullet`                      |
| 밝기    | `sun.max.fill`                     |
| 다크 모드 | `moon.fill`                        |

아이콘 크기와 굵기는 SF Symbols의 기본 `Font`/`imageScale` 연동을 그대로 따르고, 별도로 strokeWidth 같은 값을 지정하지 않는다. 아이콘 색은 현재 텍스트/tint 색을 따른다.

## 상태 색상

| 상태   | 색상              |
|------|-----------------|
| 준비   | `prepare`       |
| 운동   | `work`          |
| 휴식   | `rest`          |
| 일시정지 | 앱 강조색(`accent`) |
| 완료   | `danger`        |
| 비활성  | `.secondary`    |

상태 색상은 배경, badge, tint 중 하나 이상에 반영한다. 텍스트 색만 바꾸는 방식은 피한다.

## 접근성

- Dynamic Type을 지원하고, 텍스트 크기가 커져도 레이아웃이 깨지지 않아야 한다.
- 색상만으로 상태를 전달하지 않는다 (아이콘/텍스트를 함께 사용한다).
- 아이콘 버튼에는 `accessibilityLabel`을 제공한다.
- 주요 조작 버튼은 최소 44x44 터치 영역을 가진다.
- 타이머 실행 중 핵심 상태는 텍스트로도 표시한다.
- VoiceOver, Reduce Motion 같은 시스템 접근성 설정을 존중한다 (커스텀 애니메이션을 넣게 되면 `Reduce Motion` 설정을 확인한다).

## 구현 기준

- 커스텀 `ViewModifier`/컴포넌트는 정말로 반복되는 경우에만 만들고, 그 안에서도 시스템 스타일(색상, 폰트, 컨트롤 스타일)을 감싸는 정도로만 쓴다.
- 화면마다 색상 hex 값이나 임의의 폰트 크기를 직접 쓰지 않는다. 이 문서에 정의된 상태 색상 매핑과 표준 텍스트 스타일만 사용한다.
- 다크 모드를 위한 별도 분기 코드를 작성하지 않는다. 시스템 시맨틱 컬러를 쓰면 자동으로 처리된다.

## 금지 규칙

- 커스텀 컬러 팔레트, 커스텀 폰트, 커스텀 shadow/보더 스케일을 새로 만들지 않는다.
- 표준 컨트롤 스타일을 임의로 재구현하지 않는다 (예: 버튼을 직접 그려서 만들지 않는다).
- 한 화면을 한 색상 계열로 강하게 채우지 않는다.
- 타이머 숫자보다 장식 요소가 더 눈에 띄게 만들지 않는다.
- 표준 UI 패턴(내비게이션, 리스트, 폼)을 벗어난 독자적인 레이아웃을 만들지 않는다.
