import SwiftUI

struct StopwatchView: View {
    @State private var engine = StopwatchEngine()
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 64

    private var isRunning: Bool {
        engine.state == .running
    }

    var body: some View {
        NavigationStack {
            VStack {
                TimelineView(.periodic(from: .now, by: 0.1)) { context in
                    let status = defaultRunningStatusInfo(for: engine.state)

                    RunningDisplayView(
                        primaryText: StopwatchEngine.formattedClock(elapsed: engine.elapsed(at: context.date)),
                        statusLabel: status.label,
                        statusColor: status.color,
                        fontSize: timerFontSize
                    )
                }

                HStack {
                    RunningControlButton(title: isRunning ? "랩" : "리셋", style: .reset) {
                        if isRunning {
                            engine.recordLap(at: .now)
                        } else {
                            engine.reset()
                        }
                    }
                    .disabled(engine.state == .idle && engine.laps.isEmpty)

                    Spacer()

                    RunningControlButton(title: isRunning ? "정지" : "시작", style: isRunning ? .pause : .start) {
                        if isRunning {
                            engine.stop(at: .now)
                        } else if engine.state == .idle {
                            engine.start(at: .now)
                        } else {
                            engine.resume(at: .now)
                        }
                    }
                    .disabled(engine.state == .completed)
                }
                .padding(.horizontal)

                List(engine.laps.reversed()) { lap in
                    HStack {
                        Text("랩 \(lap.id)")
                            .font(.title3)
                        Spacer()
                        Text(StopwatchEngine.formattedClock(elapsed: lap.lapDuration))
                            .font(.title3)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text(StopwatchEngine.formattedClock(elapsed: lap.cumulativeDuration))
                            .font(.title3)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 6)
                }
                .listStyle(.plain)
            }
            .navigationTitle("스톱워치")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    StopwatchView()
}
