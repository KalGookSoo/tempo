import SwiftUI

struct ContentView: View {
    @StateObject private var receiver = WatchSyncReceiver.shared
    @State private var runner: IntervalRunner?
    @State private var previousStep: IntervalStep?

    var body: some View {
        Group {
            if let runner {
                runningContent(runner: runner)
            } else {
                Text("대기 중")
            }
        }
        .onChange(of: receiver.latestSnapshot?.sentAt) {
            if let snapshot = receiver.latestSnapshot {
                runner = snapshot.makeRunner()
            }
        }
        .task {
            if let snapshot = receiver.latestSnapshot {
                runner = snapshot.makeRunner()
            }
        }
    }

    private func runningContent(runner: IntervalRunner) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 10, paused: false)) { context in
            let progress = runner.currentProgress(at: context.date)

            Group {
                if let progress {
                    VStack(spacing: 8) {
                        if progress.step.totalRounds > 0 {
                            Text("\(progress.step.round) / \(progress.step.totalRounds)")
                                .font(.headline)
                        }
                        Text(LocalizedStringKey(statusLabel(for: progress.step)))
                            .font(.caption)
                        Text(IntervalRunner.formattedClock(seconds: progress.remainingSeconds))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                } else {
                    Text("완료")
                }
            }
            .task(id: progress?.step.id) {
                let events = CueEventDetector.events(previousStep: previousStep, currentProgress: progress, countdownLeadSeconds: 0) // 시작 전 미리 알림은 이번 범위에서 제외
                if !events.isEmpty {
                    WatchCueTriggerPlayer.play()
                }
                previousStep = progress?.step
            }
        }
    }

    private func statusLabel(for step: IntervalStep) -> String {
        switch step.kind {
        case .prepare: "준비"
        case .work: "운동"
        case .rest: "휴식"
        }
    }
}

#Preview {
    ContentView()
}
