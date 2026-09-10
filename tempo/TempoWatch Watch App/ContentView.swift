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

            // 애플 워치 기본 타이머 앱처럼 화면 전체 높이를 쓴다: 라운드 표시는 위에,
            // 조작 버튼은 맨 아래 좌우 끝에 고정하고, 링은 그 사이 남는 공간을 GeometryReader로
            // 재서 꽉 채운다(이슈 리뷰: 스크롤 없이도 잘리지 않게).
            GeometryReader { geo in
                VStack(spacing: 4) {
                    if let progress {
                        stepContent(
                            round: progress.step.round,
                            totalRounds: progress.step.totalRounds,
                            statusLabel: statusLabel(for: progress.step),
                            statusColor: statusColor(for: progress.step, runnerState: runner.state),
                            remainingSeconds: progress.remainingSeconds,
                            elapsedInStep: progress.elapsedInStep,
                            totalSeconds: progress.step.seconds,
                            ringFontSize: ringFontSize(for: geo.size)
                        )
                    } else if let lastStep = runner.steps.last {
                        stepContent(
                            round: lastStep.round,
                            totalRounds: lastStep.totalRounds,
                            statusLabel: "완료",
                            statusColor: .danger,
                            remainingSeconds: 0,
                            elapsedInStep: Double(lastStep.seconds),
                            totalSeconds: lastStep.seconds,
                            ringFontSize: ringFontSize(for: geo.size)
                        )
                    } else {
                        Text("완료") // 라운드가 0인 극단적인 경우의 최후 폴백
                    }

                    Spacer(minLength: 0)

                    controlButtons(runner: runner)
                }
                .frame(width: geo.size.width, height: geo.size.height)
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

    /// 링 지름(`fontSize * 3.8`)이 화면에서 남는 공간을 최대한 채우도록 fontSize를
    /// 역산한다. 라운드 표시 줄과 하단 버튼 줄이 차지하는 높이를 빼고 남은 정사각형
    /// 영역에 맞춘다.
    private func ringFontSize(for size: CGSize) -> CGFloat {
        let roundLabelHeight: CGFloat = 20
        let buttonRowHeight: CGFloat = 32
        let spacing: CGFloat = 4 * 2
        let availableHeight = size.height - roundLabelHeight - buttonRowHeight - spacing
        return min(size.width, availableHeight) / 3.8
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
            return .paused
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
        totalSeconds: Int,
        ringFontSize: CGFloat
    ) -> some View {
        VStack(spacing: 4) {
            if totalRounds > 0 {
                Text("\(round) / \(totalRounds)")
                    .font(.headline)
                    .foregroundStyle(statusColor)
            }
            IntervalCountdownRing(
                remainingSeconds: remainingSeconds,
                elapsedInStep: elapsedInStep,
                totalSeconds: totalSeconds,
                color: statusColor,
                statusLabel: statusLabel,
                fontSize: ringFontSize
            )
        }
    }

    /// 시작/일시정지/재개/리셋 조작 버튼 줄. 진행 중/완료 화면 둘 다 이 함수를
    /// 공유한다(#91) — 아이폰의 조작 버튼 조건(HStack)과 동일한 상태별 노출 규칙.
    @ViewBuilder
    private func controlButtons(runner: IntervalRunner) -> some View {
        HStack {
            if runner.state == .paused || runner.state == .completed {
                WatchControlButton(systemImage: "arrow.counterclockwise", style: .reset) { handleReset() }
            }
            Spacer()
            if runner.state == .running || runner.state == .preparing {
                WatchControlButton(systemImage: "pause.fill", style: .pause) { handlePause() }
            } else if runner.state == .paused {
                WatchControlButton(systemImage: "play.fill", style: .start) { handleResume() }
            } else {
                WatchControlButton(systemImage: "play.fill", style: .start) { handleStart() }
            }
        }
        .frame(maxWidth: .infinity)
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
