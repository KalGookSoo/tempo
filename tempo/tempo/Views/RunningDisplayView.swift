import SwiftUI
import UIKit

/// 준비/운동/휴식/일시정지/완료 같은 상태 색상 토큰. `docs/native-style-guide.md` "상태 색상"
/// 참고. 다크 모드에서는 시스템 색상(`.systemYellow` 등) 그대로가 검정 배경과 충분히
/// 대비되지만, 라이트 모드에서는(특히 노랑) 채도가 너무 옅어 흰 배경 위 텍스트로 쓰였을 때
/// 잘 안 보인다(직접 확인한 문제). 그래서 라이트/다크 모드별로 명도·채도를 다르게 지정한
/// 동적 `UIColor`로 만든다 — `UITraitCollection`을 보고 자동으로 전환되므로, 시스템
/// 시맨틱 컬러처럼 모드가 바뀔 때 별도 처리 없이 알아서 바뀐다.
extension Color {
    static let prepare = Color.stateColor(
        light: UIColor(red: 0.72, green: 0.53, blue: 0.00, alpha: 1),
        dark: .systemYellow
    )
    static let work = Color.stateColor(
        light: UIColor(red: 0.10, green: 0.55, blue: 0.20, alpha: 1),
        dark: .systemGreen
    )
    static let rest = Color.stateColor(
        light: UIColor(red: 0.00, green: 0.45, blue: 0.50, alpha: 1),
        dark: .systemTeal
    )
    static let danger = Color.stateColor(
        light: UIColor(red: 0.75, green: 0.10, blue: 0.10, alpha: 1),
        dark: .systemRed
    )

    private static func stateColor(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
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
struct RunningDisplayView: View {
    let primaryText: String
    let statusLabel: String?
    let statusColor: Color
    let secondaryText: String?
    let secondaryFont: Font
    let fontSize: CGFloat

    init(
        primaryText: String,
        statusLabel: String? = nil,
        statusColor: Color = .primary,
        secondaryText: String? = nil,
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
                Text(LocalizedStringKey(secondaryText))
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
        secondaryText: "라운드 2 / 8",
        fontSize: 64
    )
}
