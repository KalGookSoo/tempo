import ActivityKit
import SwiftUI
import WidgetKit

/// `TimerActivityAttributes` Live Activity의 잠금화면/다이나믹 아일랜드 레이아웃.
/// 앱 쪽(`TimerLiveActivityController`)이 시작/일시정지/재개 시점에만 상태를
/// 갱신해주고, 실제 카운트다운/카운트업 숫자는 `Text(_:style:.timer)`가 시스템
/// 차원에서 알아서 실시간으로 그려준다(이슈 #52).
///
/// `title`/`statusLabel`은 앱이 고정 어휘("스톱워치", "진행 중" 등)로 채워 넘기는
/// `String`이라, `Text(LocalizedStringKey(...))`로 감싸야 String Catalog에서 찾아
/// 번역한다 — 감싸지 않으면 기기 언어와 무관하게 항상 한국어 원문 그대로 보인다.
/// String Catalog(`Localizable.xcstrings`)는 `tempo`/`TempoWidget` 두 타겟이 모두
/// 동기화하는 `Shared/` 폴더에 둬서 이 타겟에서도 조회된다.
struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(LocalizedStringKey(context.attributes.title))
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimeText(state: context.state)
                        .font(.title3.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(LocalizedStringKey(context.state.statusLabel))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                TimeText(state: context.state)
                    .font(.caption2.monospacedDigit())
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

private struct LockScreenView: View {
    let attributes: TimerActivityAttributes
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(attributes.title))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(state.statusLabel))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            TimeText(state: state)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }
}

/// 상태에 맞는 시간 텍스트. 카운트다운/카운트업은 `.timer` 스타일이 실시간으로
/// 갱신해준다(미래 날짜면 카운트다운, 과거 날짜면 카운트업). 일시정지 중엔 멈춰있는
/// 값을 그대로 보여준다.
private struct TimeText: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        switch state.displayMode {
        case .countdown, .countUp:
            Text(state.referenceDate, style: .timer)
        case .paused:
            Text(state.staticText)
        }
    }
}
