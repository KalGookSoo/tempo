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
                TimelineView(.periodic(from: .now, by: 0.01)) { context in
                    let status = defaultRunningStatusInfo(for: engine.state)

                    RunningDisplayView(
                        primaryText: StopwatchEngine.formattedClock(elapsed: engine.elapsed(at: context.date)),
                        statusLabel: status.label,
                        statusColor: status.color,
                        fontSize: timerFontSize
                    )
                    // 화면 자동 잠금 방지 신호. 0.01초마다 매번 부를 필요는 없어서 1초 단위로
                    // 묶어 보낸다(ScreenAwakeLease의 유예 시간 5초보다 훨씬 촘촘하다). 화면을
                    // 벗어나 이 TimelineView 틱이 멈추면 신호도 자연히 끊긴다. 이슈 #53 참고.
                    .task(id: Int(context.date.timeIntervalSinceReferenceDate)) {
                        if engine.state == .running {
                            ScreenAwakeLease.renew()
                        }
                    }
                }

                HStack {
                    RunningControlButton(title: isRunning ? "랩" : "리셋", style: .reset) {
                        if isRunning {
                            engine.recordLap(at: .now)
                        } else {
                            engine.reset()
                            TimerLiveActivityController.end(kind: .stopwatch)
                        }
                    }
                    .disabled(engine.state == .idle && engine.laps.isEmpty)

                    Spacer()

                    RunningControlButton(title: isRunning ? "정지" : "시작", style: isRunning ? .pause : .start) {
                        if isRunning {
                            engine.stop(at: .now)
                            TimerLiveActivityController.start(
                                kind: .stopwatch,
                                title: "스톱워치",
                                displayMode: .paused,
                                referenceDate: .now,
                                staticText: StopwatchEngine.formattedClock(elapsed: engine.elapsed(at: .now)),
                                statusLabel: "일시정지"
                            )
                        } else if engine.state == .idle {
                            engine.start(at: .now)
                            TimerLiveActivityController.start(
                                kind: .stopwatch,
                                title: "스톱워치",
                                displayMode: .countUp,
                                referenceDate: .now,
                                staticText: StopwatchEngine.formattedClock(elapsed: 0),
                                statusLabel: "진행 중"
                            )
                        } else {
                            engine.resume(at: .now)
                            let elapsed = engine.elapsed(at: .now)
                            TimerLiveActivityController.start(
                                kind: .stopwatch,
                                title: "스톱워치",
                                displayMode: .countUp,
                                referenceDate: Date.now.addingTimeInterval(-elapsed),
                                staticText: StopwatchEngine.formattedClock(elapsed: elapsed),
                                statusLabel: "진행 중"
                            )
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
