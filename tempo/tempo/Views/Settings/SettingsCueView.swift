//
//  SettingsCueView.swift
//  tempo
//

import SwiftData
import SwiftUI

/// 전역 기본 알림 큐 설정 화면. `docs/use-cases/notification-cues.md` 참고. 프리셋별
/// 오버라이드(`TimerPreset.cueProfileID`)는 이 화면 범위 밖이다 — 지금은 전역 기본값만 다룬다.
struct SettingsCueView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<CueProfile> { $0.isDefault })
    private var profiles: [CueProfile]

    private static let countdownLeadOptions = [0, 1, 3, 5, 10]

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
                        eventRow("준비 카운트다운 시작", binding: eventBinding(profile, \.prepareStart))
                        eventRow("운동 시작", binding: eventBinding(profile, \.workStart))
                        eventRow("휴식 시작", binding: eventBinding(profile, \.restStart))
                        eventRow("구간 종료", binding: eventBinding(profile, \.segmentEnd))
                        eventRow("라운드 종료", binding: eventBinding(profile, \.roundEnd))
                        eventRow("마지막 라운드 진입", binding: eventBinding(profile, \.finalRoundEnter))
                        eventRow("전체 종료", binding: eventBinding(profile, \.finish))
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("알림 큐")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func eventRow(_ title: String, binding: Binding<CueConfig.Mode>) -> some View {
        Picker(title, selection: binding) {
            ForEach(CueConfig.Mode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
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
}

#Preview {
    NavigationStack {
        SettingsCueView()
    }
    .modelContainer(for: CueProfile.self, inMemory: true)
}
