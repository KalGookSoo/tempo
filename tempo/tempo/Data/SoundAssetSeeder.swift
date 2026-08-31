//
//  SoundAssetSeeder.swift
//  tempo
//

import Foundation
import SwiftData

/// 앱 최초 실행 시 기본 제공 사운드 4종을 `SoundAsset(kind: .builtin)`으로 등록한다.
/// 파일은 `Resources/Sounds/`에 번들로 포함돼 있다. `docs/timer-functional-spec.md`
/// "기본 사운드" 참고.
enum SoundAssetSeeder {
    static func seedDefaultsIfNeeded(in modelContext: ModelContext) throws {
        let existing = try modelContext.fetch(FetchDescriptor<SoundAsset>())
            .filter { $0.kind == .builtin }
        guard existing.isEmpty else { return }

        let now = Date()
        for seed in defaultSeeds {
            let asset = SoundAsset(kind: .builtin, name: seed.name, relativePath: seed.fileName, createdAt: now)
            modelContext.insert(asset)
        }
        try modelContext.save()
    }

    /// 이벤트 종류별 기본 사운드 이름. `docs/timer-functional-spec.md` "기본 사운드"의
    /// "운동 시작/휴식 시작/라운드 종료 = 짧은 비프, 전체 종료 = 긴 비프(3초)"를 따른다.
    /// `CueConfig.Event.soundAssetID`가 지정되지 않았을 때(MVP 기본값) 이 이름으로 조회한다.
    static func defaultSoundName(for kind: CueEventKind) -> String {
        switch kind {
        case .finish:
            "긴 비프 (3초)"
        default:
            "짧은 비프"
        }
    }

    static let defaultSeeds: [(name: String, fileName: String)] = [
        ("짧은 비프", "beep.wav"),
        ("긴 비프", "beep-long.wav"),
        ("종료음", "finish.wav"),
        ("긴 비프 (3초)", "beep-3s.wav"),
    ]
}
