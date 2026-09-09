import SwiftUI

struct ContentView: View {
    @StateObject private var receiver = WatchSyncReceiver.shared
    @State private var runner: IntervalRunner?

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
        TimelineView(.periodic(from: .now, by: 1)) { context in
            if let progress = runner.currentProgress(at: context.date) {
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
