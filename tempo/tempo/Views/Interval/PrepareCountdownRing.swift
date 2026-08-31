import SwiftUI

/// 인터벌 준비(prepare) 구간 전용 원형 프로그레스 카운트다운. 매초 진행률만큼
/// 링이 채워진다. 운동/휴식 구간에는 적용하지 않는다(이슈 #38 확인 필요 항목 —
/// 준비 구간에만 적용하기로 결정). 색상은 `Color.prepare`(노랑 계열)를 그대로 쓴다.
struct PrepareCountdownRing: View {
    let remainingSeconds: Int
    let totalSeconds: Int
    let fontSize: CGFloat

    private static let lineWidth: CGFloat = 12

    private var progress: Double {
        guard totalSeconds > 0 else { return 1 }
        return 1 - Double(remainingSeconds) / Double(totalSeconds)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.prepare.opacity(0.2), lineWidth: Self.lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.prepare, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            Text(IntervalRunner.formattedClock(seconds: remainingSeconds))
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.prepare)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
        .frame(width: fontSize * 2.8, height: fontSize * 2.8)
    }
}

#Preview {
    PrepareCountdownRing(remainingSeconds: 7, totalSeconds: 10, fontSize: 64)
}
