import SwiftUI

/// 인터벌 실행 화면의 원형 프로그레스 카운트다운. 준비/운동/휴식 구간 모두에 쓰이며,
/// 매초 진행률만큼 링이 채워진다. 색상은 호출부가 구간 상태색(`statusColor(for:)`)을
/// 그대로 넘겨준다.
struct IntervalCountdownRing: View {
    let remainingSeconds: Int
    let elapsedInStep: TimeInterval
    let totalSeconds: Int
    let color: Color
    let statusLabel: String
    let fontSize: CGFloat
    /// 상태 배지 글자 크기(statusFontSize)에 곱하는 배율. 아이폰은 기본값 1.0(변화
    /// 없음), 워치 화면만 살짝 더 키우고 싶을 때 호출부에서 1보다 큰 값을 넘긴다.
    var statusFontSizeScale: CGFloat = 1.0

    private var lineWidth: CGFloat {
        fontSize * 0.18
    }

    /// 상태 배지 글자 크기. 시계 숫자(`fontSize`)와 같은 비율(아이폰의 기존
    /// title3 약 20pt를 fontSize 76 기준으로 역산한 0.26)로 스케일하되, 워치처럼
    /// fontSize가 훨씬 작을 때도 읽을 수 있도록 최소 11pt를 보장한다.
    private var statusFontSize: CGFloat {
        max(fontSize * 0.26, 11) * statusFontSizeScale
    }

    /// 링 반지름. 배지를 중심(숫자)에서 12시 방향 링 쪽으로 얼마나 띄울지 계산하는 기준.
    private var radius: CGFloat {
        fontSize * 3.8 / 2
    }

    /// 배지를 중심~12시 사이 어느 지점에 둘지. 0이면 숫자와 겹치는 정중앙, 1이면 링에
    /// 닿는 위치이고, 0.5는 그 정확히 중간 지점이다. 값만 바꾸면 위치가 조정된다.
    private let badgeVerticalOffsetRatio: CGFloat = 0.5

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
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // 시계 숫자는 항상 원의 정중앙에 그대로 둔다. 배지를 같은 스택에 넣어
            // 함께 가운데 정렬해버리면 배지 높이만큼 숫자가 아래로 밀리기 때문에,
            // 배지는 별도로 얹어 badgeVerticalOffsetRatio만큼(기본 중심~12시의 절반)
            // 위로 띄운다.
            Text(IntervalRunner.formattedClock(seconds: remainingSeconds))
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            Text(LocalizedStringKey(statusLabel))
                .font(.system(size: statusFontSize, weight: .bold))
                .padding(.horizontal, statusFontSize * 0.6)
                .padding(.vertical, statusFontSize * 0.2)
                .background(color.opacity(0.15), in: Capsule())
                .foregroundStyle(color)
                .offset(y: -radius * badgeVerticalOffsetRatio)
        }
        .frame(width: fontSize * 3.8, height: fontSize * 3.8)
    }
}

#Preview {
    IntervalCountdownRing(remainingSeconds: 7, elapsedInStep: 3.4, totalSeconds: 10, color: .prepare, statusLabel: "운동", fontSize: 64)
}
