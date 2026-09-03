import SwiftData
import SwiftUI

/// `.run(programID:)` 화면. `programID`로 실제 `TimerPreset`을 조회해서 `IntervalRunner`를
/// 만들고, 화면에 들어오는 즉시 실행을 시작한다("실행" 액션은 프로그램 상세 화면에서 이미
/// 눌렸으므로 이 화면은 대기 없이 바로 진행한다). docs/navigation-structure.md
/// "인터벌 실행 `.intervalRun(programID:)`" 참고. 구간이 바뀔 때마다(또는 시작 전 카운트다운
/// 구간마다) `CueEventDetector`로 알림 이벤트를 판정해 `CueTriggerPlayer`로 재생한다
/// (이슈 #15).
struct IntervalRunView: View {
    let programID: String

    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 64

    @State private var runner: IntervalRunner?
    @State private var presetNotFound = false
    @State private var cueConfig: CueConfig?
    @State private var previousStep: IntervalStep?
    @State private var programName = ""
    private static let notificationIdentifier = "interval.end"

    private struct TickKey: Equatable {
        let stepID: Int?
        let remainingSeconds: Int?
    }

    var body: some View {
        Group {
            if let runner {
                runningContent(runner: runner)
            } else if presetNotFound {
                ContentUnavailableView {
                    Label("프로그램을 찾을 수 없음", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("프로그램 ID: \(programID)")
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("인터벌 실행")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if runner?.state != .completed {
                NotificationScheduler.cancel(identifier: Self.notificationIdentifier)
            }
        }
        .task {
            load()
        }
    }

    private func runningContent(runner: IntervalRunner) -> some View {
        // 원형 프로그레스 링을 정수 초 단위가 아니라 실제 경과 시간 그대로 매끄럽게
        // 채우기 위해, 1초에 한 번이 아니라 화면 갱신에 맞춰 촘촘한 주기로 다시 계산한다.
        // 진행 중이 아닐 때(대기/일시정지/완료)는 어차피 값이 안 바뀌므로 타임라인을
        // 멈춰 불필요한 갱신을 막는다.
        let isPaused = runner.state != .running && runner.state != .preparing

        let totalDuration = runner.steps.reduce(0) { $0 + $1.seconds }
        let remaining = totalDuration - Int(runner.totalElapsed(at: .now))
        let message = "인터벌 프로그램이 종료되었습니다"

        return TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { context in
            let progress = runner.currentProgress(at: context.date)

            VStack(spacing: 24) {
                Spacer()

                if let progress {
                    stepContent(
                        roundLabel: roundLabel(for: progress.step),
                        statusLabel: statusLabel(for: progress.step),
                        statusColor: statusColor(for: progress.step, runnerState: runner.state),
                        remainingSeconds: progress.remainingSeconds,
                        elapsedInStep: progress.elapsedInStep,
                        totalSeconds: progress.step.seconds
                    )
                } else if let lastStep = runner.steps.last {
                    // 완료 후에도 대기/운동/휴식 화면과 같은 구성(라운드 표시 + 상태
                    // 배지 + 링)을 그대로 쓰고, 라벨만 "완료"로 바꾼다 — 화면마다
                    // 레이아웃이 갑자기 달라지지 않도록.
                    stepContent(
                        roundLabel: roundLabel(for: lastStep),
                        statusLabel: "완료",
                        statusColor: .danger,
                        remainingSeconds: 0,
                        elapsedInStep: Double(lastStep.seconds),
                        totalSeconds: lastStep.seconds
                    )
                } else {
                    // 라운드가 0이라 steps가 아예 비어있는 극단적인 경우의 최후 폴백.
                    RunningDisplayView(
                        primaryText: "완료",
                        statusColor: .danger,
                        fontSize: timerFontSize
                    )
                }

                Spacer()

                HStack {
                    if runner.state == .paused || runner.state == .completed {
                        RunningControlButton(title: "리셋", style: .reset) {
                            runner.reset()
                            NotificationScheduler.cancel(identifier: Self.notificationIdentifier)
                        }
                    }

                    Spacer()

                    if runner.state == .running || runner.state == .preparing {
                        RunningControlButton(title: "일시정지", style: .pause) {
                            runner.pause(at: .now)
                            NotificationScheduler.cancel(identifier: Self.notificationIdentifier)
                        }
                    } else if runner.state == .paused {
                        RunningControlButton(title: "재개", style: .start) {
                            runner.resume(at: .now)
                            NotificationScheduler.schedule(
                                identifier: Self.notificationIdentifier,
                                secondsRemaining: remaining,
                                title: programName,
                                message: message
                            )
                        }
                    } else {
                        RunningControlButton(title: "시작", style: .start) {
                            runner.start(at: .now)
                            NotificationScheduler.schedule(identifier: Self.notificationIdentifier, secondsRemaining: totalDuration, title: programName, message: message)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id: TickKey(stepID: progress?.step.id, remainingSeconds: progress?.remainingSeconds)) {
                triggerCuesIfNeeded(progress: progress, state: runner.state)
            }
            // 화면 자동 잠금 방지 신호. 1초 단위로 묶어 보낸다(ScreenAwakeLease의 유예
            // 시간 5초보다 훨씬 촘촘하다). 화면을 벗어나 이 TimelineView 틱이 멈추면
            // 신호도 자연히 끊긴다. 이슈 #53 참고.
            .task(id: Int(context.date.timeIntervalSinceReferenceDate)) {
                if runner.state == .running {
                    ScreenAwakeLease.renew()
                }
            }
        }
    }

    /// 대기/운동/휴식/완료 화면이 공유하는 "라운드 표시 + 상태 배지 + 링" 구성.
    private func stepContent(
        roundLabel: String?,
        statusLabel: String,
        statusColor: Color,
        remainingSeconds: Int,
        elapsedInStep: TimeInterval,
        totalSeconds: Int
    ) -> some View {
        VStack(spacing: 16) {
            if let roundLabel {
                Text(roundLabel)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.secondary)
            }

            Text(statusLabel)
                .font(.title3.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15), in: Capsule())
                .foregroundStyle(statusColor)

            IntervalCountdownRing(
                remainingSeconds: remainingSeconds,
                elapsedInStep: elapsedInStep,
                totalSeconds: totalSeconds,
                color: statusColor,
                fontSize: timerFontSize
            )
        }
    }

    /// 준비 구간(`step.round == 0`)에서도 "라운드 1 / N"으로 보여준다 — 준비/운동/휴식/완료
    /// 화면이 전부 같은 레이아웃(라운드 표시 줄이 있는 상태)을 갖게 해서, 구간이 바뀔 때마다
    /// 이 줄이 있다 없다 하면서 아래 배지/링이 위아래로 움직이지 않도록 한다.
    private func roundLabel(for step: IntervalStep) -> String? {
        guard step.totalRounds > 0 else { return nil }
        return "라운드 \(step.round) / \(step.totalRounds)"
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

    private func triggerCuesIfNeeded(progress: IntervalRunner.Progress?, state: TimerState) {
        guard state != .idle, let cueConfig else { return }

        let events = CueEventDetector.events(
            previousStep: previousStep,
            currentProgress: progress,
            countdownLeadSeconds: cueConfig.countdownLeadSeconds
        )

        for kind in events {
            if let event = CueEventDetector.event(for: kind, in: cueConfig) {
                CueTriggerPlayer.play(event, soundAsset: resolvedSoundAsset(for: event, kind: kind))
            } else if case .countdownLead = kind {
                // countdownLead는 이벤트별 설정이 따로 없다 — 시작 전 알림 시점(초)이
                // 0보다 클 때 사운드+진동으로 알린다.
                let event = CueConfig.Event(mode: .soundAndVibration, soundAssetID: nil)
                CueTriggerPlayer.play(event, soundAsset: resolvedSoundAsset(for: event, kind: kind))
            }
        }

        previousStep = progress?.step
    }

    /// `event.soundAssetID`가 지정돼 있으면 그걸, 아니면 이벤트 종류별 기본 사운드
    /// (`SoundAssetSeeder.defaultSoundName(for:)`)를 이름으로 조회한다.
    private func resolvedSoundAsset(for event: CueConfig.Event, kind: CueEventKind) -> SoundAsset? {
        if let soundAssetID = event.soundAssetID {
            return try? modelContext.fetch(
                FetchDescriptor<SoundAsset>(predicate: #Predicate { $0.id == soundAssetID })
            ).first
        }

        let defaultName = SoundAssetSeeder.defaultSoundName(for: kind)
        return try? modelContext.fetch(
            FetchDescriptor<SoundAsset>(predicate: #Predicate { $0.name == defaultName })
        ).first
    }

    private func load() {
        guard runner == nil, !presetNotFound else { return }

        guard
            let id = UUID(uuidString: programID),
            let preset = try? PresetRepository(modelContext: modelContext).findPreset(id: id)
        else {
            presetNotFound = true
            return
        }

        cueConfig = resolveCueConfig(cueProfileID: preset.cueProfileID)
        runner = IntervalRunner(config: preset.config)
        programName = preset.name
    }

    private func resolveCueConfig(cueProfileID: UUID?) -> CueConfig? {
        if let cueProfileID,
           let profile = try? modelContext.fetch(
               FetchDescriptor<CueProfile>(predicate: #Predicate { $0.id == cueProfileID })
           ).first
        {
            return profile.config
        }

        return try? modelContext.fetch(
            FetchDescriptor<CueProfile>(predicate: #Predicate { $0.isDefault })
        ).first?.config
    }
}

#Preview {
    NavigationStack {
        IntervalRunView(programID: "preview")
    }
    .environment(Router())
}
