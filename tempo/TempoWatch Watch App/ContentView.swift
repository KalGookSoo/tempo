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

            // 애플 워치 기본 타이머 앱처럼 화면을 최대한 쓴다. 라운드 표시(6시)와 상태
            // 배지(12시), 조작 버튼(좌우 하단 코너)을 전부 링 위에 겹쳐서, 별도 줄이
            // 차지하는 공간 없이 화면 전체를 링에 그대로 쓴다 — 그래야 라운드 텍스트
            // 때문에 링이 아래로 처지지 않고 화면 정중앙에 온다.
            GeometryReader { geo in
                let computedRingFontSize = ringFontSize(for: geo.size)

                Group {
                    if let progress {
                        stepContent(
                            round: progress.step.round,
                            totalRounds: progress.step.totalRounds,
                            statusLabel: statusLabel(for: progress.step),
                            statusColor: statusColor(for: progress.step, runnerState: runner.state),
                            remainingSeconds: progress.remainingSeconds,
                            elapsedInStep: progress.elapsedInStep,
                            totalSeconds: progress.step.seconds,
                            ringFontSize: computedRingFontSize,
                            runner: runner
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
                            ringFontSize: computedRingFontSize,
                            runner: runner
                        )
                    } else {
                        Text("완료") // 라운드가 0인 극단적인 경우의 최후 폴백
                    }
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

    /// 링 지름(`fontSize * 3.8`)이 화면을 최대한 채우도록 fontSize를 역산한다.
    /// 라운드 표시, 상태 배지, 버튼 모두 링 위에 겹쳐서 놓이므로(stepContent,
    /// controlButtons 참고) 화면 크기 자체를 그대로 쓴다.
    private func ringFontSize(for size: CGSize) -> CGFloat {
        min(size.width, size.height) / 3.8
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

    /// 중심(숫자)과 링 사이 몇 %에 배지/라운드 표시를 둘지. IntervalCountdownRing의
    /// 12시 배지 오프셋 비율과 동일한 값 — 6시 라운드 표시도 같은 비율로 맞춘다.
    private let roundLabelVerticalOffsetRatio: CGFloat = 0.5

    private func stepContent(
        round: Int,
        totalRounds: Int,
        statusLabel: String,
        statusColor: Color,
        remainingSeconds: Int,
        elapsedInStep: TimeInterval,
        totalSeconds: Int,
        ringFontSize: CGFloat,
        runner: IntervalRunner
    ) -> some View {
        ZStack {
            IntervalCountdownRing(
                remainingSeconds: remainingSeconds,
                elapsedInStep: elapsedInStep,
                totalSeconds: totalSeconds,
                color: statusColor,
                statusLabel: statusLabel,
                fontSize: ringFontSize
            )

            // 라운드 표시(N / N)를 링 밖 별도 줄 대신 6시 방향 안쪽에 겹친다 — 별도
            // 줄이 차지하던 높이가 없어져서 링이 화면 정중앙에 온다.
            if totalRounds > 0 {
                Text("\(round) / \(totalRounds)")
                    .font(.headline)
                    .foregroundStyle(statusColor)
                    .offset(y: (ringFontSize * 3.8 / 2) * roundLabelVerticalOffsetRatio)
            }

            controlButtons(runner: runner, ringDiameter: ringFontSize * 3.8)
        }
    }

    /// 시작/일시정지/재개/리셋 조작 버튼. 링 아래 따로 줄을 두지 않고, 원이 정사각형
    /// 안에서 채우지 못하는 좌우 하단 코너에 겹쳐 놓는다(#91) — 그래야 버튼 자리를
    /// 예약하지 않고도 링을 최대 크기로 키울 수 있다. 버튼 중심을 링 중심에서
    /// "링 반지름 + 버튼 반지름 + 여백"만큼 45도(코너 방향) 대각선으로 띄우면, 둘
    /// 사이 거리가 항상 두 반지름의 합 이상이 되어 크기와 무관하게 절대 겹치지 않는다.
    @ViewBuilder
    private func controlButtons(runner: IntervalRunner, ringDiameter: CGFloat) -> some View {
        let buttonDiameter: CGFloat = 32
        let gap: CGFloat = 8
        let distanceFromCenter = ringDiameter / 2 + buttonDiameter / 2 + gap
        let cornerOffset = distanceFromCenter / 1.41421356 // 대각선(45도) 성분

        if runner.state == .paused || runner.state == .completed {
            WatchControlButton(systemImage: "arrow.counterclockwise", style: .reset) { handleReset() }
                .offset(x: -cornerOffset, y: cornerOffset)
        }
        if runner.state == .running || runner.state == .preparing {
            WatchControlButton(systemImage: "pause.fill", style: .pause) { handlePause() }
                .offset(x: cornerOffset, y: cornerOffset)
        } else if runner.state == .paused {
            WatchControlButton(systemImage: "play.fill", style: .start) { handleResume() }
                .offset(x: cornerOffset, y: cornerOffset)
        } else {
            WatchControlButton(systemImage: "play.fill", style: .start) { handleStart() }
                .offset(x: cornerOffset, y: cornerOffset)
        }
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
