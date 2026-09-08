import SwiftUI

/// 음량 레벨(0...1) 샘플을 막대 그래프 형태의 파형으로 그린다. 녹음 중 실시간 파형과
/// 녹음 목록의 정적 파형이 이 뷰를 함께 쓴다(이슈 #64).
///
/// 막대는 고정 너비(`barWidth`)로 그리고, 컨테이너 너비에 맞는 개수만큼만 보여준다.
/// 샘플이 그 개수보다 많으면(예: 목록의 좁은 미리보기 칸에 5초 녹음 ~100개 샘플을
/// 그대로 넣으면) 막대 하나가 안 보일 만큼 얇아지는 문제가 있었다 — 구간별 평균으로
/// 다운샘플링해서, 녹음 전체 길이의 파형 모양은 유지하면서 막대는 항상 눈에 보이는
/// 굵기로 그린다.
struct WaveformView: View {
    let samples: [Float]
    var color: Color = .accentColor

    private static let barWidth: CGFloat = 2
    private static let barSpacing: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            let barCount = max(1, Int(proxy.size.width / (Self.barWidth + Self.barSpacing)))
            let displaySamples = Self.downsample(samples, to: barCount)
            HStack(alignment: .center, spacing: Self.barSpacing) {
                ForEach(Array(displaySamples.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color)
                        .frame(width: Self.barWidth, height: max(2, CGFloat(level) * proxy.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private static func downsample(_ samples: [Float], to barCount: Int) -> [Float] {
        guard samples.count > barCount, barCount > 0 else { return samples }
        let bucketSize = Double(samples.count) / Double(barCount)
        return (0 ..< barCount).map { i in
            let start = Int(Double(i) * bucketSize)
            let end = max(start + 1, min(samples.count, Int(Double(i + 1) * bucketSize)))
            let bucket = samples[start ..< end]
            return bucket.reduce(0, +) / Float(bucket.count)
        }
    }
}

#Preview {
    WaveformView(samples: (0 ..< 40).map { _ in Float.random(in: 0 ... 1) })
        .frame(height: 40)
        .padding()
}
