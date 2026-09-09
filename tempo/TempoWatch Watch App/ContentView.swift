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
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let progress = runner.currentProgress(at: context.date)

            Group {
                if let progress {
                    stepContent(
                        round: progress.step.round,
                        totalRounds: progress.step.totalRounds,
                        statusLabel: statusLabel(for: progress.step),
                        statusColor: statusColor(for: progress.step),
                        remainingSeconds: progress.remainingSeconds,
                        elapsedInStep: progress.elapsedInStep,
                        totalSeconds: progress.step.seconds
                    )
                } else if let lastStep = runner.steps.last {
                    stepContent(
                        round: lastStep.round,
                        totalRounds: lastStep.totalRounds,
                        statusLabel: "완료",
                        statusColor: .danger,
                        remainingSeconds: 0,
                        elapsedInStep: Double(lastStep.seconds),
                        totalSeconds: lastStep.seconds
                    )
                } else {
                    Text("완료") // 라운드가 0인 극단적인 경우의 최후 폴백
                }
            }
            .task(id: progress?.step.id) {
                let events = CueEventDetector.events(previousStep: previousStep, currentProgress: progress, countdownLeadSeconds: 0)
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

    private func statusColor(for step: IntervalStep) -> Color {
        switch step.kind {
        case .prepare: .prepare
        case .work: .work
        case .rest: .rest
        }
    }

    private func stepContent(
        round: Int,
        totalRounds: Int,
        statusLabel: String,
        statusColor: Color,
        remainingSeconds: Int,
        elapsedInStep: TimeInterval,
        totalSeconds: Int
    ) -> some View {
        VStack(spacing: 8) {
            if totalRounds > 0 {
                Text("\(round) / \(totalRounds)")
                    .font(.headline)
                    .foregroundStyle(statusColor)
            }
            Text(LocalizedStringKey(statusLabel))
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.15), in: Capsule())
                .foregroundStyle(statusColor)
            IntervalCountdownRing(
                remainingSeconds: remainingSeconds,
                elapsedInStep: elapsedInStep,
                totalSeconds: totalSeconds,
                color: statusColor,
                fontSize: 24
            )
        }
    }
}

#Preview {
    ContentView()
}
