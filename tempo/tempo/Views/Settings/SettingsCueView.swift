import SwiftData
import SwiftUI

/// 전역 기본 알림 큐 설정 화면. `docs/use-cases/notification-cues.md` 참고. 프리셋별
/// 오버라이드(`TimerPreset.cueProfileID`)는 이 화면 범위 밖이다 — 지금은 전역 기본값만 다룬다.
struct SettingsCueView: View {
    /// 사운드 선택 시트를 띄울 이벤트. `EndSoundPickerView`의 타이틀도 같이 들고 있는다.
    private struct SoundPickerTarget: Identifiable {
        let title: String
        let keyPath: WritableKeyPath<CueConfig, CueConfig.Event>
        var id: String {
            title
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<CueProfile> { $0.isDefault })
    private var profiles: [CueProfile]
    @Query(filter: #Predicate<SoundAsset> { $0.deletedAt == nil })
    private var soundAssets: [SoundAsset]

    @State private var soundPickerTarget: SoundPickerTarget?

    private static let countdownLeadOptions = [0, 3, 5, 10]

    private static let eventRows: [(title: String, keyPath: WritableKeyPath<CueConfig, CueConfig.Event>)] = [
        ("준비 카운트다운 시작", \.prepareStart),
        ("운동 시작", \.workStart),
        ("휴식 시작", \.restStart),
        ("구간 종료", \.segmentEnd),
        ("라운드 종료", \.roundEnd),
        ("마지막 라운드 진입", \.finalRoundEnter),
        ("전체 종료", \.finish),
    ]

    private var profile: CueProfile? {
        profiles.first
    }

    var body: some View {
        Group {
            if let profile {
                Form {
                    Section("시작 전 알림") {
                        Picker("알림 시점", selection: countdownLeadBinding(profile)) {
                            ForEach(Self.countdownLeadOptions, id: \.self) { seconds in
                                Text(seconds == 0 ? "없음" : "\(seconds)초").tag(seconds)
                            }
                        }
                    }

                    Section("이벤트별 알림") {
                        ForEach(Self.eventRows, id: \.title) { row in
                            eventRow(row.title, profile: profile, keyPath: row.keyPath)
                        }
                    }
                }
                .sheet(item: $soundPickerTarget) { target in
                    EndSoundPickerView(title: target.title, selection: soundAssetIDBinding(profile, target.keyPath))
                }
            } else {
                ProgressView()
            }
        }
        .constrainedWidth()
        .navigationTitle("알림 큐")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func eventRow(
        _ title: String,
        profile: CueProfile,
        keyPath: WritableKeyPath<CueConfig, CueConfig.Event>
    ) -> some View {
        Picker(title, selection: eventBinding(profile, keyPath)) {
            ForEach(CueConfig.Mode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }

        if profile.config[keyPath: keyPath].mode.playsSound {
            Button {
                soundPickerTarget = SoundPickerTarget(title: "\(title) 사운드", keyPath: keyPath)
            } label: {
                HStack {
                    Text("사운드")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(soundName(for: profile, keyPath: keyPath))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func soundName(for profile: CueProfile, keyPath: WritableKeyPath<CueConfig, CueConfig.Event>) -> String {
        guard let soundAssetID = profile.config[keyPath: keyPath].soundAssetID else { return "기본값" }
        return soundAssets.first { $0.id == soundAssetID }?.name ?? "기본값"
    }

    private func countdownLeadBinding(_ profile: CueProfile) -> Binding<Int> {
        Binding(
            get: { profile.config.countdownLeadSeconds },
            set: { newValue in
                profile.config.countdownLeadSeconds = newValue
                profile.updatedAt = .now
                try? modelContext.save()
            }
        )
    }

    private func eventBinding(
        _ profile: CueProfile,
        _ keyPath: WritableKeyPath<CueConfig, CueConfig.Event>
    ) -> Binding<CueConfig.Mode> {
        Binding(
            get: { profile.config[keyPath: keyPath].mode },
            set: { newValue in
                profile.config[keyPath: keyPath].mode = newValue
                profile.updatedAt = .now
                try? modelContext.save()
            }
        )
    }

    private func soundAssetIDBinding(
        _ profile: CueProfile,
        _ keyPath: WritableKeyPath<CueConfig, CueConfig.Event>
    ) -> Binding<UUID?> {
        Binding(
            get: { profile.config[keyPath: keyPath].soundAssetID },
            set: { newValue in
                profile.config[keyPath: keyPath].soundAssetID = newValue
                profile.updatedAt = .now
                try? modelContext.save()
            }
        )
    }
}

#Preview {
    NavigationStack {
        SettingsCueView()
    }
    .modelContainer(for: CueProfile.self, inMemory: true)
}
