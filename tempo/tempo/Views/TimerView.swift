//
//  TimerView.swift
//  tempo
//

import SwiftData
import SwiftUI

struct TimerView: View {
    @State private var engine = TimerEngine()
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 64
    @State private var isEndSoundPickerPresented = false
    @Query(filter: #Predicate<SoundAsset> { $0.deletedAt == nil })
    private var soundAssets: [SoundAsset]

    var body: some View {
        NavigationStack {
            VStack {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let seconds = engine.state == .idle
                        ? engine.configuredSeconds
                        : engine.remainingOrElapsedSeconds(at: context.date)

                    Text(formatted(seconds: seconds))
                        .font(.system(size: timerFontSize, weight: .bold, design: .monospaced))
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
                .frame(maxHeight: 160)
                .scrollDisabled(true)
                .disabled(engine.state != .idle)

                HStack {
                    leadingButton
                    Spacer()
                    trailingButton
                }
                .padding(.horizontal)
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
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}

#Preview {
    TimerView()
        .modelContainer(for: SoundAsset.self, inMemory: true)
}
