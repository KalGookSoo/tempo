//
//  SchemaV1.swift
//  tempo
//

import SwiftData

/// 초기 스키마. docs/local-persistence-strategy.md "마이그레이션 원칙" 참고.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimerPreset.self, CueProfile.self, SoundAsset.self, AppSettings.self]
    }
}
