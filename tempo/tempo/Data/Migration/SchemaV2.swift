import SwiftData

/// `AppSettings.hasCompletedOnboarding` 필드 추가. 기존 필드에 기본값이 있는 단순 추가라
/// lightweight 마이그레이션으로 처리한다. docs/local-persistence-strategy.md
/// "마이그레이션 원칙" 참고.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimerPreset.self, CueProfile.self, SoundAsset.self, AppSettings.self]
    }
}
