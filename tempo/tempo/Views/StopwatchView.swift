//
//  StopwatchView.swift
//  tempo
//

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
                    Button(isRunning ? "랩" : "리셋") {
                        if isRunning {
                            engine.recordLap(at: .now)
                        } else {
                            engine.reset()
                        }
                    }
                    .disabled(engine.state == .idle && engine.laps.isEmpty)

                    Spacer()

                    Button(isRunning ? "정지" : "시작") {
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
                        Spacer()
                        Text(StopwatchEngine.formattedClock(elapsed: lap.lapDuration))
                            .foregroundStyle(.secondary)
                        Text(StopwatchEngine.formattedClock(elapsed: lap.cumulativeDuration))
                            .monospacedDigit()
                    }
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
