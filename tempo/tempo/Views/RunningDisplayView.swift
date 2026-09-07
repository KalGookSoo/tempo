import SwiftUI

/// 준비/운동/휴식/일시정지/완료 같은 상태 색상 토큰. `docs/native-style-guide.md` "상태 색상"
/// 참고 — 커스텀 hex 대신 시스템 시맨틱 컬러에 매핑한다.
extension Color {
    static let prepare = Color.yellow
    static let work = Color.green
    static let rest = Color.teal
    static let danger = Color.red
}

/// 준비/운동/휴식 구간이 없는 화면(타이머, 스톱워치)의 공통 상태->라벨/색상 매핑.
/// 인터벌은 구간(`IntervalStep.Kind`)이 따로 있어 각자 매핑한다. 모든 상태에 라벨을
/// 채워서(상태별로 nil을 섞지 않음) `RunningDisplayView`의 상태 배지 유무에 따라
/// 화면 높이가 바뀌지 않도록 한다(이슈 #40).
func defaultRunningStatusInfo(for state: TimerState) -> (label: String?, color: Color) {
    switch state {
    case .idle: ("대기 중", .secondary)
    case .running: ("진행 중", .primary)
    case .paused: ("일시정지", .accentColor)
    case .completed: ("완료", .danger)
    default: (nil, .primary)
    }
}

/// 타이머/스톱워치/인터벌 실행 화면이 공유하는 "큰 시간 숫자 + 상태 배지" 표시 블록.
/// 컨트롤 버튼/픽커 같은 화면별 요소는 포함하지 않는다 — 화면마다 이 블록 아래에 이어붙인다.
/// `docs/native-style-guide.md` "타이머 표시"(카드로 감싸지 않고 배경 위에 숫자만 크게 배치),
/// `docs/use-cases/mirrored-timer-display.md`(멀리서도 읽혀야 함) 참고. 이슈 #17.
///
/// `secondaryText`는 `String?`이 아니라 `Text?`를 받는다 — 호출부가 이미 완성된 문자열을
/// 만들어서 넘기면(예: 라운드 숫자가 박힌 "라운드 3 / 8") `LocalizedStringKey`로 감싸도
/// 그 문자열 전체와 정확히 일치하는 카탈로그 키가 없어 절대 번역되지 않는다. 호출부가
/// `Text("라운드 \(round) / \(total)")`처럼 리터럴 보간으로 직접 만들거나, 고정된 값 하나를
/// `Text(LocalizedStringKey(fixedWord))`로 감싸서 넘기게 해서 이 문제를 원천적으로 막는다.
struct RunningDisplayView: View {
    let primaryText: String
    let statusLabel: String?
    let statusColor: Color
    let secondaryText: Text?
    let secondaryFont: Font
    let fontSize: CGFloat

    init(
        primaryText: String,
        statusLabel: String? = nil,
        statusColor: Color = .primary,
        secondaryText: Text? = nil,
        secondaryFont: Font = .headline,
        fontSize: CGFloat
    ) {
        self.primaryText = primaryText
        self.statusLabel = statusLabel
        self.statusColor = statusColor
        self.secondaryText = secondaryText
        self.secondaryFont = secondaryFont
        self.fontSize = fontSize
    }

    var body: some View {
        VStack(spacing: 8) {
            if let secondaryText {
                secondaryText
                    .font(secondaryFont)
                    .foregroundStyle(.secondary)
            }

            if let statusLabel {
                Text(LocalizedStringKey(statusLabel))
                    .font(.title3.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(statusColor)
            }

            Text(primaryText)
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundStyle(statusColor)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RunningDisplayView(
        primaryText: "00:20",
        statusLabel: "운동",
        statusColor: .work,
        secondaryText: Text("라운드 2 / 8"),
        fontSize: 64
    )
}
