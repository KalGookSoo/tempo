import SwiftUI

/// 음량 레벨(0...1) 샘플을 막대 그래프 형태의 파형으로 그린다. 녹음 중 실시간 파형과
/// 녹음 목록의 정적 파형이 이 뷰를 함께 쓴다(이슈 #64).
struct WaveformView: View {
    let samples: [Float]
    var color: Color = .accentColor

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .center, spacing: 2) {
                ForEach(Array(samples.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color)
                        .frame(height: max(2, CGFloat(level) * proxy.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

#Preview {
    WaveformView(samples: (0 ..< 40).map { _ in Float.random(in: 0 ... 1) })
        .frame(height: 40)
        .padding()
}
