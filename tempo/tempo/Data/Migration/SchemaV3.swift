import SwiftData

/// `SoundAsset.waveformSamples` 필드 추가(이슈 #64). 기존 필드에 기본값(`[]`)이 있는
/// 단순 추가라 lightweight 마이그레이션으로 처리한다. docs/local-persistence-strategy.md
/// "마이그레이션 원칙" 참고.
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimerPreset.self, CueProfile.self, SoundAsset.self, AppSettings.self]
    }
}
