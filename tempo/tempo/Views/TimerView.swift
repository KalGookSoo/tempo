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
            ScrollView {
                VStack(spacing: 24) {
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

                    HStack {
                        VStack {
                            Text("시").font(.caption)
                            Picker("시", selection: Binding(get: { engine.hours }, set: { engine.hours = $0 })) {
                                ForEach(0 ..< 24, id: \.self) { value in
                                    Text("\(value)").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                        }

                        VStack {
                            Text("분").font(.caption)
                            Picker("분", selection: Binding(get: { engine.minutes }, set: { engine.minutes = $0 })) {
                                ForEach(0 ..< 60, id: \.self) { value in
                                    Text("\(value)").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                        }

                        VStack {
                            Text("초").font(.caption)
                            Picker("초", selection: Binding(get: { engine.seconds }, set: { engine.seconds = $0 })) {
                                ForEach(0 ..< 60, id: \.self) { value in
                                    Text("\(value)").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                    }
                    .padding(.horizontal)
                    .disabled(engine.state != .idle)

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

                    HStack {
                        leadingButton
                        Spacer()
                        trailingButton
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
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

    @ViewBuilder
    private var leadingButton: some View {
        switch engine.state {
        case .idle:
            Button("취소") { cancel() }
        case .paused:
            Button("리셋") { engine.reset() }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var trailingButton: some View {
        switch engine.state {
        case .idle:
            Button("시작") { engine.start(at: .now) }
                .disabled(engine.configuredSeconds == 0)
        case .running:
            Button("일시정지") { engine.pause(at: .now) }
        case .paused:
            Button("재개") { engine.resume(at: .now) }
        case .completed:
            Button("리셋") { engine.reset() }
        default:
            EmptyView()
        }
    }

    private func cancel() {
        engine.reset()
        engine.configuredSeconds = 0
        engine.label = "타이머"
        engine.endSoundAssetID = nil
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
