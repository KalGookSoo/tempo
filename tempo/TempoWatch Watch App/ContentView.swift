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
                        statusColor: statusColor(for: progress.step, runnerState: runner.state),
                        remainingSeconds: progress.remainingSeconds,
                        elapsedInStep: progress.elapsedInStep,
                        totalSeconds: progress.step.seconds
                    )
                    controlButtons(runner: runner)
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
                    controlButtons(runner: runner)
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

    private func statusColor(for step: IntervalStep, runnerState: TimerState) -> Color {
        if runnerState == .paused {
            return .accentColor
        }
        switch step.kind {
        case .prepare: return .prepare
        case .work: return .work
        case .rest: return .rest
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

    /// 시작/일시정지/재개/리셋 조작 버튼 줄. 진행 중/완료 화면 둘 다 이 함수를
    /// 공유한다(#91) — 아이폰의 조작 버튼 조건(HStack)과 동일한 상태별 노출 규칙.
    @ViewBuilder
    private func controlButtons(runner: IntervalRunner) -> some View {
        HStack(spacing: 12) {
            if runner.state == .paused || runner.state == .completed {
                Button { handleReset() } label: { Image(systemName: "arrow.counterclockwise") }
            }
            if runner.state == .running || runner.state == .preparing {
                Button { handlePause() } label: { Image(systemName: "pause.fill") }
            } else if runner.state == .paused {
                Button { handleResume() } label: { Image(systemName: "play.fill") }
            } else {
                Button { handleStart() } label: { Image(systemName: "play.fill") }
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func handleStart() {
        WatchControlSender.send(.start)
    }

    private func handlePause() {
        WatchControlSender.send(.pause)
    }

    private func handleResume() {
        WatchControlSender.send(.resume)
    }

    private func handleReset() {
        WatchControlSender.send(.reset)
    }
}

#Preview {
    ContentView()
}
