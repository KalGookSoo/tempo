import SwiftUI

/// 인터벌 실행 화면의 원형 프로그레스 카운트다운. 준비/운동/휴식 구간 모두에 쓰이며,
/// 매초 진행률만큼 링이 채워진다. 색상은 호출부가 구간 상태색(`statusColor(for:)`)을
/// 그대로 넘겨준다.
struct IntervalCountdownRing: View {
    let remainingSeconds: Int
    let elapsedInStep: TimeInterval
    let totalSeconds: Int
    let color: Color
    let fontSize: CGFloat

    private static let lineWidth: CGFloat = 10

    /// 정수 초 단위(`remainingSeconds`)가 아니라 실제 경과 시간(`elapsedInStep`)을 그대로
    /// 진행률로 쓴다. 예전엔 초당 한 번만 갱신되는 정수 값을 `.animation`으로 매끄럽게
    /// 보이도록 흉내 내면서 "이 초가 끝나는 시점" 기준으로 한 틱 앞당겨 계산했는데(이슈
    /// #38), 그 보정이 구간이 막 시작된 시점에도 똑같이 적용돼서 시작하자마자 링이
    /// `1/totalSeconds`만큼 미리 차 있는 부작용이 있었다. 호출부(`IntervalRunView`)가
    /// 이제 실제 경과 시간을 촘촘한 주기로 다시 계산해서 넘겨주므로, 이 값을 그대로 쓰면
    /// 시작은 정확히 0, 끝은 정확히 1이 되고 보정 자체가 필요 없다.
    private var progress: Double {
        guard totalSeconds > 0 else { return 1 }
        return min(max(elapsedInStep / Double(totalSeconds), 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: Self.lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

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
    IntervalCountdownRing(remainingSeconds: 7, elapsedInStep: 3.4, totalSeconds: 10, color: .prepare, fontSize: 64)
}
