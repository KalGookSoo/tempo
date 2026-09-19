import SwiftUI

struct ContentView: View {
    @StateObject private var receiver = WatchSyncReceiver.shared
    @State private var runner: IntervalRunner?
    @State private var previousStep: IntervalStep?
    @State private var isLeaveConfirmationPresented = false
    @State private var programName = ""
    @State private var scheduledCueIdentifiers: [String] = []

    /// 준비/운동·휴식/일시정지 중에는 목록으로 돌아가면 잃을 진행 상황이 있어 확인이
    /// 필요하다. 아직 시작 전이거나 이미 끝난 상태는 잃을 게 없어 바로 나갈 수 있다.
    /// 아이폰 실행 화면의 뒤로가기 확인(#74)과 같은 기준이다.
    private var needsLeaveConfirmation: Bool {
        switch runner?.state {
        case .preparing?, .running?, .paused?: true
        default: false
        }
    }

    var body: some View {
        if let runner {
            runningContent(runner: runner)
        } else {
            presetListContent
        }
    }

    /// 아이폰 프로그램 목록 화면에서 "애플워치 연동" 버튼을 눌러야 이 목록이 채워진다.
    /// 그 뒤로는 아이폰과 통신하지 않고, 고른 프로그램을 워치 안에서 완전히 로컬로
    /// 실행한다.
    private var presetListContent: some View {
        NavigationStack {
            Group {
                if receiver.presets.isEmpty {
                    ContentUnavailableView {
                        Label("동기화된 프로그램 없음", systemImage: "applewatch.slash")
                    } description: {
                        Text("아이폰 프로그램 목록에서\n애플워치 연동 버튼을 눌러주세요")
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List(receiver.presets) { preset in
                        Button(preset.name) {
                            runner = IntervalRunner(config: preset.config)
                            programName = preset.name
                        }
                    }
                }
            }
            .navigationTitle("프로그램")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        receiver.requestRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("목록 갱신")
                }
            }
        }
        .task {
            receiver.loadCachedContext()
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
        .alert(
            "프로그램을 중단할까요?",
            isPresented: $isLeaveConfirmationPresented
        ) {
            Button("계속하기", role: .cancel) {}
            Button("중단하고 나가기", role: .destructive) {
                exitToList()
            }
        } message: {
            Text("지금 나가면 진행 중인 인터벌이 중단되고 처음부터 다시 시작해야 합니다.")
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
                fontSize: ringFontSize,
                statusFontSizeScale: 1.15
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

        // 프로그램 목록으로 돌아가는 버튼. 우측 상단은 시스템 시계가 차지하고 있어
        // 좌측 상단에 놓는다 — 하단 버튼과 같은 대각선 오프셋 공식을 위쪽에 그대로
        // 적용한 것뿐이라 링이나 다른 버튼과 겹치지 않는다. 실행 상태와 무관하게
        // 항상 보인다. 진행 중(준비/운동·휴식/일시정지)일 때는 바로 나가지 않고
        // 확인을 먼저 받는다 — 안 그러면 실수로 눌러서 진행 상황을 잃기 쉽다.
        WatchControlButton(systemImage: "list.bullet", style: .reset) { handleExit() }
            .offset(x: -cornerOffset, y: -cornerOffset)

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
        guard let runner else { return }
        runner.start(at: .now)
        let requests = buildNotificationRequests(for: runner)
        scheduledCueIdentifiers = requests.map(\.identifier)
        NotificationScheduler.schedule(requests)
    }

    private func handlePause() {
        guard let runner else { return }
        runner.pause(at: .now)
        NotificationScheduler.cancel(scheduledCueIdentifiers)
        scheduledCueIdentifiers.removeAll()
    }

    private func handleResume() {
        guard let runner else { return }
        runner.resume(at: .now)
        let requests = buildNotificationRequests(for: runner)
        scheduledCueIdentifiers = requests.map(\.identifier)
        NotificationScheduler.schedule(requests)
    }

    private func handleReset() {
        guard let runner else { return }
        runner.reset()
        NotificationScheduler.cancel(scheduledCueIdentifiers)
        scheduledCueIdentifiers.removeAll()
    }

    private func handleExit() {
        if needsLeaveConfirmation {
            isLeaveConfirmationPresented = true
        } else {
            exitToList()
        }
    }

    private func cueMessage(for kind: CueEventKind) -> String {
        switch kind {
        case .prepareStart: String(localized: "준비를 시작합니다")
        case .workStart: String(localized: "운동을 시작합니다")
        case .restStart: String(localized: "휴식을 시작합니다")
        case .segmentEnd: String(localized: "구간이 종료되었습니다")
        case .workEnd: String(localized: "운동 구간이 종료되었습니다")
        case .roundEnd: String(localized: "라운드가 종료되었습니다")
        case .finalRoundEnter: String(localized: "마지막 라운드입니다")
        case .finish: String(localized: "인터벌 프로그램이 종료되었습니다")
        case .countdownLead: ""
        }
    }

    private func buildNotificationRequests(for runner: IntervalRunner) -> [NotificationRequest] {
        guard let progress = runner.currentProgress(at: .now) else { return [] }
        let events = CueEventDetector.upcomingEvents(steps: runner.steps, from: progress)

        return events.enumerated().map { index, event in
            NotificationRequest(
                identifier: "watch.interval.cue.\(index)",
                secondsRemaining: event.secondsUntil,
                title: programName,
                message: cueMessage(for: event.kind),
                sound: .default
            )
        }
    }

    private func exitToList() {
        NotificationScheduler.cancel(scheduledCueIdentifiers)
        scheduledCueIdentifiers.removeAll()
        runner = nil
    }
}

#Preview {
    ContentView()
}
