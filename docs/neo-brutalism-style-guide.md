# Tempo 네오 부르탈리즘 스타일가이드

## 목적

이 문서는 tempo 앱의 기본 디자인 체계를 정의한다. 목표는 크로스핏 타이머 앱에 어울리는 강한 대비, 선명한 정보 위계, 빠른 조작감을 가진 네오 부르탈리즘 스타일을 일관되게 적용하는 것이다.

구현은 NativeWind와 lucide-react-native를 기준으로 한다.
heading, paragraph, table, button, menu, list, link 같은 표현 요소는 React 컴포넌트로 표준화하여 사용한다.

## 디자인 원칙

- 강한 대비: 배경, 텍스트, 보더의 대비를 크게 둔다.
- 명확한 면: 카드, 버튼, 메뉴는 굵은 외곽선과 단단한 색면으로 구분한다.
- 낮은 반경: radius는 작게 유지한다.
- 실제 그림자: 흐린 shadow 대신 x/y offset이 있는 단단한 shadow를 쓴다.
- 빠른 판독: 타이머 숫자와 상태 텍스트는 멀리서도 읽혀야 한다.
- 기능 우선: 장식보다 조작, 상태, 시간 정보가 먼저 보여야 한다.

## 컬러 토큰

색상은 Tailwind theme token으로 옮길 수 있도록 이름을 고정한다.

### 공통 팔레트

| Token    | Hex       | 용도              |
|----------|-----------|-----------------|
| `ink`    | `#111111` | 기본 텍스트, 보더, 그림자 |
| `paper`  | `#FFF8E8` | 라이트 배경          |
| `chalk`  | `#F7F7F2` | 라이트 표면          |
| `night`  | `#151515` | 다크 배경           |
| `coal`   | `#222222` | 다크 표면           |
| `steel`  | `#676767` | 보조 텍스트          |
| `white`  | `#FFFFFF` | 다크 모드 주요 텍스트    |
| `red`    | `#FF4D4D` | 위험, 종료, 강한 경고   |
| `orange` | `#FF9F1C` | 준비, 대기, 주의      |
| `yellow` | `#FFD447` | 강조, 선택 상태       |
| `green`  | `#21C55D` | 운동, 시작, 성공      |
| `cyan`   | `#00C2FF` | 휴식, 보조 강조       |
| `blue`   | `#3A86FF` | 정보, 링크          |
| `pink`   | `#FF5DA2` | 특수 강조           |

### 라이트 모드 시맨틱 컬러

| Token           | Value    |
|-----------------|----------|
| `bg`            | `paper`  |
| `surface`       | `chalk`  |
| `surfaceStrong` | `white`  |
| `text`          | `ink`    |
| `textMuted`     | `steel`  |
| `border`        | `ink`    |
| `shadow`        | `ink`    |
| `primary`       | `yellow` |
| `work`          | `green`  |
| `rest`          | `cyan`   |
| `prepare`       | `orange` |
| `danger`        | `red`    |

### 다크 모드 시맨틱 컬러

| Token           | Value     |
|-----------------|-----------|
| `bg`            | `night`   |
| `surface`       | `coal`    |
| `surfaceStrong` | `#2D2D2D` |
| `text`          | `white`   |
| `textMuted`     | `#B8B8B8` |
| `border`        | `white`   |
| `shadow`        | `#000000` |
| `primary`       | `yellow`  |
| `work`          | `green`   |
| `rest`          | `cyan`    |
| `prepare`       | `orange`  |
| `danger`        | `red`     |

## 타입 시스템

### 폰트

| Token     | Font stack                          | 용도            |
|-----------|-------------------------------------|---------------|
| `display` | `Spline Sans`, `Inter`, system sans | 헤딩, 타이머 숫자    |
| `body`    | `Inter`, system sans                | 본문, 메뉴, 버튼    |
| `mono`    | system monospace                    | 숫자, 코드, 시간 표시 |

### 크기

| Token        | Size | Line height | Weight | 용도         |
|--------------|-----:|------------:|-------:|------------|
| `display-xl` |   96 |         104 |    900 | 미러링 타이머    |
| `display-lg` |   72 |          80 |    900 | 모바일 실행 타이머 |
| `h1`         |   40 |          48 |    900 | 화면 제목      |
| `h2`         |   32 |          40 |    900 | 섹션 제목      |
| `h3`         |   24 |          32 |    800 | 카드/패널 제목   |
| `body-lg`    |   18 |          28 |    600 | 주요 설명      |
| `body`       |   16 |          24 |    500 | 기본 본문      |
| `body-sm`    |   14 |          20 |    500 | 보조 설명      |
| `caption`    |   12 |          16 |    700 | 라벨, 메타 정보  |

### 타이포그래피 규칙

- 글자 간격은 기본 `0`을 유지한다.
- 타이머 숫자는 가능하면 `tabular-nums` 또는 mono 스타일을 사용한다.
- 헤딩은 짧고 단단하게 쓴다.
- 본문은 1줄 32자 내외로 끊기게 설계한다.
- 버튼 텍스트는 1줄을 우선하되 좁은 화면에서는 아이콘 중심 버튼을 사용한다.

## 간격과 그리드

### Spacing scale

| Token | Value |
|-------|------:|
| `0`   |     0 |
| `1`   |     4 |
| `2`   |     8 |
| `3`   |    12 |
| `4`   |    16 |
| `5`   |    20 |
| `6`   |    24 |
| `8`   |    32 |
| `10`  |    40 |
| `12`  |    48 |
| `16`  |    64 |

### Layout grid

- 모바일 기본 여백: 16
- 태블릿/가로 화면 기본 여백: 24
- 섹션 간격: 32
- 컴포넌트 내부 간격: 12 또는 16
- 리스트 아이템 간격: 8
- 실행 화면은 4px spacing scale을 유지하되, 타이머 영역은 화면 높이에 맞춰 유연하게 확장한다.

### Responsive columns

| 화면       | 컬럼 |
|----------|---:|
| 작은 모바일   |  4 |
| 일반 모바일   |  4 |
| 태블릿 세로   |  8 |
| 태블릿 가로/웹 | 12 |

카드 목록은 모바일에서 1열, 넓은 화면에서 2-3열을 기본으로 한다.

## Shape와 Elevation

### Border

| Token           | Value | 용도           |
|-----------------|------:|--------------|
| `border-thin`   |     2 | 보조 요소        |
| `border`        |     3 | 기본 컴포넌트      |
| `border-strong` |     4 | 주요 버튼, 실행 화면 |

### Radius

| Token  | Value | 용도           |
|--------|------:|--------------|
| `none` |     0 | 테이블, divider |
| `sm`   |     4 | 버튼, 입력       |
| `md`   |     8 | 카드, 메뉴       |

네오 부르탈리즘 컴포넌트는 기본적으로 `8`을 넘지 않는다.

### Shadow

흐린 그림자는 사용하지 않는다.

| Token            | Value    | 용도     |
|------------------|----------|--------|
| `shadow-hard-sm` | x 3, y 3 | 작은 버튼  |
| `shadow-hard`    | x 5, y 5 | 카드, 메뉴 |
| `shadow-hard-lg` | x 8, y 8 | 주요 패널  |

Pressed 상태에서는 shadow offset을 줄이고 요소를 같은 방향으로 이동시킨다.

## 기본 컴포넌트

HTML5의 표현 요소에 해당하는 UI는 직접 스타일을 반복하지 않고 공용 React 컴포넌트로 사용한다. `div`, `section`, `main`, `article`처럼 논리적 구획과 레이아웃을 나누는 요소는 화면 구조에 맞게 자유롭게 사용하되,
화면에 일관된 스타일을 드러내는 요소는 컴포넌트로 고정한다.

### 컴포넌트화 대상

| HTML 의미                 | React Native 컴포넌트 예시             | 용도                   |
|-------------------------|----------------------------------|----------------------|
| `h1`-`h6`               | `Heading`                        | 화면/섹션/카드 제목          |
| `p`                     | `Paragraph`                      | 본문, 설명               |
| `strong`, `em`, `small` | `Text` variants                  | 강조, 보조 텍스트           |
| `a`                     | `Link`                           | 외부 링크, 내부 이동         |
| `button`                | `Button`, `IconButton`           | 명령 실행                |
| `menu`                  | `Menu`, `MenuItem`               | 액션 목록                |
| `ul`                    | `UnorderedList`, `ListItem`      | 순서 없는 목록             |
| `ol`                    | `OrderedList`, `ListItem`        | 순서 있는 절차             |
| `table`                 | `Table`, `TableRow`, `TableCell` | 비교, 명세, key-value 정보 |
| `hr`                    | `Divider`                        | 수평 구분선               |
| `input`                 | `Input`, `NumberInput`           | 입력                   |

컴포넌트는 스타일 토큰과 접근성 기본값을 포함해야 한다. 화면 코드에서 동일한 스타일 className을 반복해서 붙이는 방식은 피한다.

### Heading

- `h1`: 화면의 주 제목에만 사용한다.
- `h2`: 화면 내부 주요 섹션에 사용한다.
- `h3`: 카드, 폼 그룹, 메뉴 그룹 제목에 사용한다.
- 헤딩은 기본적으로 `display` 폰트와 굵은 weight를 쓴다.
- 헤딩 아래 보조 문장은 `body-sm` 또는 `body`를 사용한다.

### Paragraph

- 기본 본문은 `body`를 사용한다.
- 정보 밀도가 높은 설정 화면은 `body-sm`을 허용한다.
- 중요한 안내문은 배경색이 있는 callout으로 분리한다.

### Link

- 링크는 `blue` 또는 `primary` 색을 사용한다.
- 링크 텍스트에는 밑줄 또는 두꺼운 bottom border를 사용한다.
- 외부 링크는 아이콘으로 외부 이동임을 표시할 수 있다.
- 버튼처럼 동작하는 링크는 `Button` 컴포넌트를 사용한다.

### Unordered list

- bullet은 기본 점 대신 굵은 사각형 또는 짧은 dash를 사용한다.
- 리스트 간격은 8을 기본으로 한다.
- 항목 안에 긴 설명을 넣기보다 한 항목 한 문장 원칙을 따른다.

### Ordered list

- 절차, 설정 단계, 실행 순서에 사용한다.
- 숫자는 굵게 표시한다.
- 각 단계는 한 동작으로 끝나야 한다.

### Table

- 보더는 `border` 두께를 사용한다.
- 헤더는 `primary` 또는 `surfaceStrong` 배경을 사용한다.
- 셀 padding은 12를 기본으로 한다.
- 모바일에서는 가로 스크롤보다 카드형 key-value 리스트로 전환하는 것을 우선한다.

### Menu

- 메뉴 컨테이너는 `surface` 배경, `border`, `shadow-hard`를 사용한다.
- 메뉴 아이템 높이는 최소 48이다.
- 선택된 메뉴는 `primary` 배경을 사용한다.
- destructive 메뉴는 `danger` 색을 사용한다.
- 메뉴 아이템에는 lucide 아이콘과 텍스트를 함께 사용할 수 있다.

### Button

버튼은 명령의 중요도에 따라 나눈다.

| Variant     | 용도                    |
|-------------|-----------------------|
| `primary`   | 시작, 저장, 주요 실행         |
| `secondary` | 편집, 복제, 옵션            |
| `danger`    | 삭제, 종료, 초기화           |
| `ghost`     | 보조 이동, 닫기             |
| `icon`      | 재생, 일시정지, 리셋 같은 도구 버튼 |

공통 규칙:

- 최소 터치 영역은 44x44다.
- 기본 border는 3이다.
- 기본 radius는 4다.
- primary 버튼은 `primary` 배경과 `ink` 텍스트를 쓴다.
- 실행 화면의 `Start` 버튼은 `work` 색을 사용한다.
- `Stop` 또는 종료 성격 버튼은 `danger` 색을 사용한다.
- 아이콘 버튼은 lucide 아이콘을 사용하고, 의미가 불명확하면 접근성 label을 제공한다.

Pressed 상태:

- shadow offset을 줄인다.
- 요소를 x 2, y 2만큼 이동한 것처럼 표현한다.
- 색상 변화보다 물리적으로 눌린 느낌을 우선한다.

Disabled 상태:

- opacity만 낮추지 않는다.
- 배경을 muted surface로 바꾸고, border와 text를 `textMuted`로 낮춘다.

### Divider / Horizon

- 수평 구분선은 `border` 색을 사용한다.
- 기본 두께는 2다.
- 중요한 섹션 구분은 3 또는 4를 사용한다.
- 여백은 위아래 16을 기본으로 한다.

### Input

- border 3, radius 4를 사용한다.
- 높이는 최소 48이다.
- focus 상태는 `primary` 배경 또는 두꺼운 outline으로 표시한다.
- 숫자 입력은 큰 mono 숫자와 steppers를 우선한다.

### Card

- 반복 항목, 프리셋, 설정 그룹에만 사용한다.
- 카드 안에 또 다른 카드를 넣지 않는다.
- 기본 스타일은 `surface`, `border`, `shadow-hard`, radius 8이다.
- 선택된 카드는 `primary` 또는 상태 색상 배경을 쓴다.

### Timer display

- 앱의 핵심 컴포넌트다.
- 시간 숫자는 화면에서 가장 커야 한다.
- 운동 상태는 `work`, 휴식 상태는 `rest`, 준비 상태는 `prepare`, 종료 상태는 `danger`를 사용한다.
- 미러링 화면에서는 조작 버튼보다 시간과 상태가 우선한다.
- 숫자와 라운드 정보는 고정 영역을 가져 레이아웃이 흔들리지 않아야 한다.

## Iconography

아이콘은 lucide-react-native를 사용한다.

### 기본 규칙

- 기본 크기: 24
- 작은 아이콘: 18 또는 20
- 큰 도구 아이콘: 32
- strokeWidth: 2.5
- 주요 실행 버튼은 3까지 허용한다.
- 아이콘 색은 현재 텍스트 색을 따른다.

### 추천 아이콘

| 기능    | 아이콘          |
|-------|--------------|
| 시작    | `Play`       |
| 일시정지  | `Pause`      |
| 정지    | `Square`     |
| 리셋    | `RotateCcw`  |
| 편집    | `Pencil`     |
| 저장    | `Save`       |
| 삭제    | `Trash2`     |
| 복제    | `Copy`       |
| 사운드   | `Volume2`    |
| 무음    | `VolumeX`    |
| 진동    | `Smartphone` |
| 녹음    | `Mic`        |
| 설정    | `Settings`   |
| 프리셋   | `ListChecks` |
| 밝기    | `Sun`        |
| 다크 모드 | `Moon`       |

## 상태 색상

| 상태   | 색상          |
|------|-------------|
| 준비   | `prepare`   |
| 운동   | `work`      |
| 휴식   | `rest`      |
| 일시정지 | `primary`   |
| 완료   | `danger`    |
| 비활성  | `textMuted` |

상태 색상은 배경, badge, border 중 하나 이상에 반영한다. 텍스트 색만 바꾸는 방식은 피한다.

## 접근성

- 텍스트와 배경 대비는 충분히 높게 유지한다.
- 색상만으로 상태를 전달하지 않는다.
- 아이콘 버튼에는 접근성 label을 제공한다.
- 주요 조작 버튼은 최소 44x44 터치 영역을 가진다.
- 타이머 실행 중 핵심 상태는 텍스트로도 표시한다.
- 다크 모드에서도 shadow와 border가 분리되어 보여야 한다.

## NativeWind 적용 기준

### 토큰화 우선순위

1. `tailwind.config`에 color, spacing, font, radius, borderWidth 토큰을 정의한다.
2. 반복되는 shadow, button, card 스타일은 컴포넌트 variant로 만든다.
3. 화면별 일회성 className은 레이아웃에만 사용한다.

### 컴포넌트 작성 원칙

- 공용 컴포넌트는 `components/ui` 같은 단일 위치에 둔다.
- 각 컴포넌트는 variant와 size를 명시적으로 가진다.
- 컴포넌트 내부에서 NativeWind className과 필요한 React Native style을 캡슐화한다.
- lucide 아이콘은 컴포넌트 props로 받아 일관된 size, strokeWidth, color를 적용한다.
- 접근성 label, role에 해당하는 React Native 접근성 prop은 컴포넌트 기본값으로 처리한다.
- 화면에서는 raw `Text`, raw `Pressable`에 스타일을 직접 붙이는 일을 최소화한다.

### 예시 className 방향

```tsx
<View className="rounded-md border-[3px] border-border bg-surface p-4 shadow-hard">
  <Text className="font-display text-h2 font-black text-text">Timer</Text>
</View>
```

React Native shadow 구현은 플랫폼 차이가 있으므로, hard shadow는 공용 컴포넌트에서 `boxShadow` 또는 platform style로 캡슐화한다.

## 금지 규칙

- 흐린 glassmorphism을 기본 스타일로 사용하지 않는다.
- radius가 큰 pill/card를 남용하지 않는다.
- 보더 없는 floating card를 만들지 않는다.
- 한 화면을 한 색상 계열만으로 채우지 않는다.
- 타이머 숫자보다 장식 요소가 더 눈에 띄게 만들지 않는다.
- 카드 안에 카드를 중첩하지 않는다.
