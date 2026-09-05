import Foundation
import SwiftData

/// 앱 최초 실행 시 전역 기본 알림 큐 프로필을 하나 삽입한다. `docs/local-persistence-strategy.md`
/// "CueProfile", `docs/use-cases/notification-cues.md" 참고. 프리셋별 오버라이드
/// (`TimerPreset.cueProfileID`)는 이 기본 프로필을 대체하는 용도로 이미 열려 있다.
enum CueProfileSeeder {
    static func seedDefaultIfNeeded(in modelContext: ModelContext) throws {
        let existingDefaults = try modelContext.fetch(FetchDescriptor<CueProfile>())
            .filter(\.isDefault)
        guard existingDefaults.isEmpty else { return }

        let now = Date()
        let event = CueConfig.Event(mode: .soundAndVibration, soundAssetID: nil)
        let config = CueConfig(
            countdownLeadSeconds: 3,
            prepareStart: event,
            workStart: event,
            restStart: event,
            segmentEnd: event,
            // 운동 종료는 구간 종료와 달리 기본으로는 꺼둔다 — 켜두면 운동이 끝날 때마다
            // 구간 종료 알림과 겹쳐서 두 번 울리게 된다. 이슈 #75 참고.
            workEnd: CueConfig.Event(mode: .none, soundAssetID: nil),
            roundEnd: event,
            finalRoundEnter: event,
            finish: event
        )

        let profile = CueProfile(name: "기본 알림", isDefault: true, config: config, createdAt: now, updatedAt: now)
        modelContext.insert(profile)
        try modelContext.save()
    }
}
