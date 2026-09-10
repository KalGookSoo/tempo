import SwiftUI

/// 워치용 원형 조작 버튼. 아이폰의 `RunningControlButton`과 동일한 배경색 규칙(시작/재개는
/// 초록, 일시정지는 빨강, 리셋은 중립 회색)을 따르되, 작은 화면에 맞춰 텍스트 없이
/// 아이콘만 표시하고 지름을 줄였다.
struct WatchControlButton: View {
    enum Style {
        case start
        case pause
        case reset

        var backgroundColor: Color {
            switch self {
            case .start: .green
            case .pause: .red
            case .reset: Color(red: 58 / 255, green: 58 / 255, blue: 60 / 255) // 아이폰 다크모드 systemGray5와 동일
            }
        }

        var foregroundColor: Color {
            switch self {
            case .start, .pause: .white
            case .reset: .primary
            }
        }
    }

    let systemImage: String
    let style: Style
    let action: () -> Void

    private static let diameter: CGFloat = 32

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.footnote.bold())
                .foregroundStyle(style.foregroundColor)
                .frame(width: Self.diameter, height: Self.diameter)
                .background(style.backgroundColor, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 12) {
        WatchControlButton(systemImage: "arrow.counterclockwise", style: .reset) {}
        WatchControlButton(systemImage: "pause.fill", style: .pause) {}
        WatchControlButton(systemImage: "play.fill", style: .start) {}
    }
}
