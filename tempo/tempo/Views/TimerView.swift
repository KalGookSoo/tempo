//
//  TimerView.swift
//  tempo
//

import SwiftData
import SwiftUI

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var engine = TimerEngine()
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 64
    @State private var isEndSoundPickerPresented = false
    @State private var cueConfig: CueConfig?
    @State private var previousState: TimerState?
    @Query(filter: #Predicate<SoundAsset> { $0.deletedAt == nil })
    private var soundAssets: [SoundAsset]

    private struct TickKey: Equatable {
        let state: TimerState
        let seconds: Int
    }

    var body: some View {
        NavigationStack {
            Group {
                if engine.state == .idle {
                    ScrollView {
                        VStack(spacing: 24) {
                            timeDisplay
                            countdownPicker
                            controlButtons
                            settingsForm
                        }
                        .padding(.vertical)
                    }
                } else {
                    // 실행 중에는 피커가 필요 없어서 숨기고, 남는 공간만큼 시간 표시를
                    // 화면 가운데로 띄운다.
                    VStack(spacing: 24) {
                        Spacer()
                        timeDisplay
                        Spacer()
                        controlButtons
                        settingsForm
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
            }
            .sheet(isPresented: $isEndSoundPickerPresented) {
                EndSoundPickerView(
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
        guard let cueConfig else { return }
        defer { previousState = state }

        if previousState != .completed, state == .completed {
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
                fontSize: timerFontSize
            )
            .task(id: TickKey(state: engine.state, seconds: seconds)) {
                triggerCuesIfNeeded(state: engine.state, seconds: seconds)
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

    private var settingsForm: some View {
        Form {
            TextField("레이블", text: Binding(get: { engine.label }, set: { engine.label = $0 }))

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
        .disabled(engine.state != .idle)
    }

    /// 시작 전에는 리셋할 대상이 없어 버튼을 보여주지 않는다. 일시정지 중에만 리셋을
    /// 제공한다(완료 시 리셋은 trailingButton이 담당).
    @ViewBuilder
    private var leadingButton: some View {
        if engine.state == .paused {
            RunningControlButton(title: "리셋", style: .reset) { engine.reset() }
        }
    }

    @ViewBuilder
    private var trailingButton: some View {
        switch engine.state {
        case .idle:
            RunningControlButton(title: "시작", style: .start) { engine.start(at: .now) }
                .disabled(engine.configuredSeconds == 0)
        case .running:
            RunningControlButton(title: "일시정지", style: .pause) { engine.pause(at: .now) }
        case .paused:
            RunningControlButton(title: "재개", style: .start) { engine.resume(at: .now) }
        case .completed:
            RunningControlButton(title: "리셋", style: .reset) { engine.reset() }
        default:
            EmptyView()
        }
    }

    private var selectedEndSoundName: String {
        guard let id = engine.endSoundAssetID else { return "없음" }
        return soundAssets.first(where: { $0.id == id })?.name ?? "없음"
    }

    private func formatted(seconds: Int) -> String {
        TimerEngine.formattedClock(seconds: seconds)
    }
}

#Preview {
    TimerView()
        .modelContainer(for: SoundAsset.self, inMemory: true)
}
