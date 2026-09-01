import SwiftUI

/// 인터벌 실행 화면의 원형 프로그레스 카운트다운. 준비/운동/휴식 구간 모두에 쓰이며,
/// 매초 진행률만큼 링이 채워진다. 색상은 호출부가 구간 상태색(`statusColor(for:)`)을
/// 그대로 넘겨준다.
struct IntervalCountdownRing: View {
    let remainingSeconds: Int
    let totalSeconds: Int
    let color: Color
    let fontSize: CGFloat

    private static let lineWidth: CGFloat = 10

    /// 남은 시간이 아니라 "이 초가 끝나는 시점"을 기준으로 계산한다. `remainingSeconds`는
    /// 절대 0이 되지 않고 1에서 바로 다음 구간으로 넘어가므로, 단순히
    /// `1 - remaining/total`로 계산하면 마지막 1초 동안 목표값이 `(total-1)/total`에서
    /// 멈춰 절대 100%에 도달하지 못한 채 다음 구간으로 전환돼버린다(이슈 #38). 그래서
    /// 마지막 남은 초가 끝나는 시점에 정확히 1.0이 되도록 한 틱 앞당겨 계산한다.
    private var progress: Double {
        guard totalSeconds > 0 else { return 1 }
        return Double(totalSeconds - remainingSeconds + 1) / Double(totalSeconds)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: Self.lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            Text(IntervalRunner.formattedClock(seconds: remainingSeconds))
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
        .frame(width: fontSize * 3.6, height: fontSize * 3.6)
    }
}

#Preview {
    IntervalCountdownRing(remainingSeconds: 7, totalSeconds: 10, color: .prepare, fontSize: 64)
}
