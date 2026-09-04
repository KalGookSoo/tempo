import SwiftData
import SwiftUI

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var engine = TimerEngine()
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 64
    @State private var isEndSoundPickerPresented = false
    @State private var cueConfig: CueConfig?
    @State private var previousState: TimerState?

    /// 모달 상태 변수
    @State private var isLabelAlertPresented: Bool = false

    /// 사용자가 레이블을 입력하다가 취소할 경우 원복하기 위한 임시 변수
    @State private var draftLabel: String = ""
    @Query(filter: #Predicate<SoundAsset> { $0.deletedAt == nil })
    private var soundAssets: [SoundAsset]
    private static let notificationIdentifier = "timer.end"
    private struct TickKey: Equatable {
        let state: TimerState
        let seconds: Int
    }

    var body: some View {
        NavigationStack {
            // 전체 화면을 스크롤 가능하게 두면 CountdownWheelPicker(자체 스크롤 휠)와 위아래
            // 팬 제스처가 겹쳐서, 휠을 돌리려다 화면 전체가 스크롤되는 문제가 있었다. 이
            // 화면은 콘텐츠가 화면 높이에 들어오므로 ScrollView 없이 고정 레이아웃으로 둔다.
            Group {
                if engine.state == .idle {
                    // 대기 중에는 피커가 이미 설정된 시간을 그대로 보여주므로, 큰 숫자
                    // 표시(timeDisplay)는 굳이 중복해서 띄우지 않는다.
                    VStack(spacing: 24) {
                        countdownPicker
                        controlButtons
                        settingsForm
                    }
                    .padding(.vertical)
                } else {
                    // 실행 중에는 피커와 레이블/사운드 입력 폼이 필요 없어서 숨기고, 남는
                    // 공간만큼 시간 표시를 화면 가운데로 띄운다. 레이블은 timeDisplay 안
                    // secondaryText로 대신 보여준다.
                    VStack(spacing: 24) {
                        Spacer()
                        timeDisplay
                        Spacer()
                        controlButtons
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("타이머")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(engine.mode == .countdown ? "카운트다운" : "카운트업") {
                        engine.mode = engine.mode == .countdown ? .countUp : .countdown
                    }
                    .disabled(engine.state != .idle)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    AirPlayButton()
                        .frame(width: 28, height: 28)
                }
            }
            .sheet(isPresented: $isEndSoundPickerPresented) {
                EndSoundPickerView(
                    title: "타이머 종료 시",
                    selection: Binding(get: { engine.endSoundAssetID }, set: { engine.endSoundAssetID = $0 })
                )
            }
        }
        .task {
            cueConfig = try? modelContext.fetch(
                FetchDescriptor<CueProfile>(predicate: #Predicate { $0.isDefault })
            ).first?.config
        }
    }

    /// 시작 전 카운트다운(설정된 초 이하로 남았을 때)과 전체 종료 이벤트를 전역 기본 알림
    /// 큐 설정으로 재생한다. 타이머에는 준비/운동/휴식/라운드 개념이 없어 인터벌보다 훨씬
    /// 단순하다 — 이슈 #15.
    private func triggerCuesIfNeeded(state: TimerState, seconds: Int) {
        defer { previousState = state }
        let didJustComplete = previousState != .completed && state == .completed

        // Live Activity 종료는 알림 큐 설정(cueConfig) 유무와 무관하게 항상 처리한다.
        if didJustComplete {
            TimerLiveActivityController.end(kind: .timer)
        }

        guard let cueConfig else { return }

        if didJustComplete {
            let finishEvent = cueConfig.finish
            // 이 타이머에서 직접 고른 "타이머 종료 시" 사운드가 있으면 그걸 우선한다.
            // 재생 여부(모드)는 전역 알림 큐 설정을 그대로 따른다.
            let soundAsset = resolvedSoundAsset(
                soundAssetID: engine.endSoundAssetID ?? finishEvent.soundAssetID,
                defaultName: SoundAssetSeeder.defaultSoundName(for: .finish)
            )
            CueTriggerPlayer.play(finishEvent, soundAsset: soundAsset)
            return
        }

        guard state == .running else { return }

        let remainingUntilTarget = engine.mode == .countdown ? seconds : engine.configuredSeconds - seconds
        if cueConfig.countdownLeadSeconds > 0,
           remainingUntilTarget > 0,
           remainingUntilTarget <= cueConfig.countdownLeadSeconds
        {
            let event = CueConfig.Event(mode: .soundAndVibration, soundAssetID: nil)
            let soundAsset = resolvedSoundAsset(
                soundAssetID: nil,
                defaultName: SoundAssetSeeder.defaultSoundName(for: .countdownLead(secondsRemaining: remainingUntilTarget))
            )
            CueTriggerPlayer.play(event, soundAsset: soundAsset)
        }
    }

    /// 시작/재개 시점에 지금 모드(카운트다운/카운트업) 기준으로 Live Activity를
    /// (다시) 시작한다. `referenceDate`는 카운트다운이면 종료 예정 시각, 카운트업이면
    /// 이미 지난 경과 시간만큼 과거로 당긴 시작 시각이다 — 두 경우 모두 위젯의
    /// `Text(_:style:.timer)`가 그 시각 기준으로 알아서 실시간 카운트를 그린다.
    private func refreshLiveActivity(statusLabel: String) {
        let seconds = engine.remainingOrElapsedSeconds(at: .now)
        let displayMode: TimerActivityAttributes.ContentState.DisplayMode = engine.mode == .countdown ? .countdown : .countUp
        let referenceDate = engine.mode == .countdown
            ? Date.now.addingTimeInterval(TimeInterval(seconds))
            : Date.now.addingTimeInterval(-TimeInterval(seconds))
        TimerLiveActivityController.start(
            kind: .timer,
            title: effectiveLabel,
            displayMode: displayMode,
            referenceDate: referenceDate,
            staticText: formatted(seconds: seconds),
            statusLabel: statusLabel
        )
    }

    private func resolvedSoundAsset(soundAssetID: UUID?, defaultName: String) -> SoundAsset? {
        if let soundAssetID {
            return try? modelContext.fetch(
                FetchDescriptor<SoundAsset>(predicate: #Predicate { $0.id == soundAssetID })
            ).first
        }

        return try? modelContext.fetch(
            FetchDescriptor<SoundAsset>(predicate: #Predicate { $0.name == defaultName })
        ).first
    }

    private var timeDisplay: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let seconds = engine.state == .idle
                ? engine.configuredSeconds
                : engine.remainingOrElapsedSeconds(at: context.date)
            let status = defaultRunningStatusInfo(for: engine.state)

            RunningDisplayView(
                primaryText: formatted(seconds: seconds),
                statusLabel: status.label,
                statusColor: status.color,
                secondaryText: engine.state == .idle ? nil : effectiveLabel,
                fontSize: timerFontSize
            )
            .task(id: TickKey(state: engine.state, seconds: seconds)) {
                triggerCuesIfNeeded(state: engine.state, seconds: seconds)
            }
            // 화면 자동 잠금 방지 신호(1초에 한 번이면 충분 — ScreenAwakeLease의 유예 시간
            // 5초보다 훨씬 촘촘하다). 화면을 벗어나 이 TimelineView 틱이 멈추면 신호도
            // 자연히 끊겨 유예 시간 뒤 자동 잠금이 복구된다. 이슈 #53 참고.
            .task(id: seconds) {
                if engine.state == .running {
                    ScreenAwakeLease.renew()
                }
            }
            // 외부 디스플레이(TV)에 지금 보이는 값을 그대로 반영한다. 이슈 #63 참고.
            .task(id: TickKey(state: engine.state, seconds: seconds)) {
                ExternalDisplayController.shared.update(
                    .init(
                        primaryText: formatted(seconds: seconds),
                        statusLabel: status.label,
                        statusColor: status.color,
                        secondaryText: engine.state == .idle ? nil : effectiveLabel
                    )
                )
            }
        }
    }

    private var countdownPicker: some View {
        CountdownWheelPicker(
            hours: Binding(get: { engine.hours }, set: { engine.hours = $0 }),
            minutes: Binding(get: { engine.minutes }, set: { engine.minutes = $0 }),
            seconds: Binding(get: { engine.seconds }, set: { engine.seconds = $0 })
        )
        .frame(height: 180)
    }

    private var controlButtons: some View {
        HStack {
            leadingButton
            Spacer()
            trailingButton
        }
        .padding(.horizontal)
    }

    /// idle 상태에서만 쓴다 — 실행 중에는 레이블만 timeDisplay 위에 대신 보여주고,
    /// 이 폼(레이블 입력 + 종료 시 사운드)은 화면에서 아예 뺀다.
    private var settingsForm: some View {
        Form {
            Button {
                draftLabel = engine.label
                isLabelAlertPresented = true
            } label: {
                HStack {
                    Text("레이블")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(effectiveLabel)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                isEndSoundPickerPresented = true
            } label: {
                HStack {
                    Text("타이머 종료 시")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(selectedEndSoundName)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 160)
        .scrollDisabled(true)
        .alert("레이블", isPresented: $isLabelAlertPresented) {
            TextField("타이머", text: $draftLabel)
            Button("취소", role: .cancel) {}
            Button("저장") {
                engine.label = draftLabel
            }
        } message: {
            Text("비워두면 \"타이머\"로 표시됩니다.")
        }
    }

    /// 시작 전에는 리셋할 대상이 없어 버튼을 보여주지 않는다. 일시정지 중에만 리셋을
    /// 제공한다(완료 시 리셋은 trailingButton이 담당).
    @ViewBuilder
    private var leadingButton: some View {
        if engine.state == .paused {
            RunningControlButton(title: "리셋", style: .reset) {
                engine.reset()
                TimerLiveActivityController.end(kind: .timer)
            }
        }
    }

    @ViewBuilder
    private var trailingButton: some View {
        let message = "타이머가 종료되었습니다"
        switch engine.state {
        case .idle:
            RunningControlButton(title: "시작", style: .start) {
                engine.start(at: .now)
                if engine.mode == .countdown {
                    NotificationScheduler.schedule(identifier: Self.notificationIdentifier, secondsRemaining: engine.configuredSeconds, title: effectiveLabel, message: message)
                }
                refreshLiveActivity(statusLabel: "진행 중")
            }
            .disabled(engine.configuredSeconds == 0)
        case .running:
            RunningControlButton(title: "일시정지", style: .pause) {
                engine.pause(at: .now)
                NotificationScheduler.cancel(identifier: Self.notificationIdentifier)
                TimerLiveActivityController.start(
                    kind: .timer,
                    title: effectiveLabel,
                    displayMode: .paused,
                    referenceDate: .now,
                    staticText: formatted(seconds: engine.remainingOrElapsedSeconds(at: .now)),
                    statusLabel: "일시정지"
                )
            }
        case .paused:
            RunningControlButton(title: "재개", style: .start) {
                engine.resume(at: .now)
                if engine.mode == .countdown, engine.state == .running {
                    NotificationScheduler.schedule(identifier: Self.notificationIdentifier, secondsRemaining: engine.remainingOrElapsedSeconds(at: .now), title: effectiveLabel, message: message)
                }
                if engine.state == .running {
                    refreshLiveActivity(statusLabel: "진행 중")
                }
            }
        case .completed:
            RunningControlButton(title: "리셋", style: .reset) {
                engine.reset()
                NotificationScheduler.cancel(identifier: Self.notificationIdentifier)
                TimerLiveActivityController.end(kind: .timer)
            }
        default:
            EmptyView()
        }
    }

    private var selectedEndSoundName: String {
        guard let id = engine.endSoundAssetID else { return "없음" }
        return soundAssets.first(where: { $0.id == id })?.name ?? "없음"
    }

    /// 레이블을 비워두면 "타이머"로 처리한다.
    private var effectiveLabel: String {
        let trimmed = engine.label.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "타이머" : trimmed
    }

    private func formatted(seconds: Int) -> String {
        TimerEngine.formattedClock(seconds: seconds)
    }
}

#Preview {
    TimerView()
        .modelContainer(for: SoundAsset.self, inMemory: true)
}
