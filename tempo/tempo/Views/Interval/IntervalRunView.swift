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
        .task {
            load()
        }
    }

    private func runningContent(runner: IntervalRunner) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let progress = runner.currentProgress(at: Date())

            VStack(spacing: 24) {
                Spacer()

                if let progress {
                    RunningDisplayView(
                        primaryText: IntervalRunner.formattedClock(seconds: progress.remainingSeconds),
                        statusLabel: statusLabel(for: progress.step),
                        statusColor: statusColor(for: progress.step, runnerState: runner.state),
                        secondaryText: progress.step.round > 0
                            ? "라운드 \(progress.step.round) / \(progress.step.totalRounds)"
                            : nil,
                        secondaryFont: .largeTitle.bold(),
                        fontSize: timerFontSize
                    )
                } else {
                    RunningDisplayView(
                        primaryText: "완료",
                        statusColor: .danger,
                        fontSize: timerFontSize
                    )
                }

                Spacer()

                HStack {
                    if runner.state == .paused {
                        RunningControlButton(title: "리셋", style: .reset) {
                            runner.reset()
                        }
                    }

                    Spacer()

                    if runner.state == .running || runner.state == .preparing {
                        RunningControlButton(title: "일시정지", style: .pause) {
                            runner.pause(at: .now)
                        }
                    } else if runner.state == .paused {
                        RunningControlButton(title: "재개", style: .start) {
                            runner.resume(at: .now)
                        }
                    } else {
                        RunningControlButton(title: "시작", style: .start) {
                            runner.start(at: .now)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id: TickKey(stepID: progress?.step.id, remainingSeconds: progress?.remainingSeconds)) {
                triggerCuesIfNeeded(progress: progress, state: runner.state)
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
