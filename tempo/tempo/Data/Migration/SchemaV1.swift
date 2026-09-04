import Foundation
import SwiftData

/// 초기 스키마. docs/local-persistence-strategy.md "마이그레이션 원칙" 참고.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimerPreset.self, CueProfile.self, SoundAsset.self, AppSettings.self]
    }

    /// v1 시점 `AppSettings`의 형태 스냅샷(`hasCompletedOnboarding` 없음). 앱 코드는 항상
    /// 최신 형태인 최상위 `AppSettings`(Data/Models/AppSettings.swift)를 쓴다. SchemaV1과
    /// SchemaV2가 서로 다른 체크섬을 갖도록(동일하면 SwiftData가 "Duplicate version
    /// checksums" 예외를 던진다) 변경된 모델만 버전별로 스냅샷해서 구분한다.
    @Model
    final class AppSettings {
        var themeMode: ThemeMode
        var bigTimerDigitsEnabled: Bool
        var updatedAt: Date

        init(themeMode: ThemeMode = .system, bigTimerDigitsEnabled: Bool = false, updatedAt: Date) {
            self.themeMode = themeMode
            self.bigTimerDigitsEnabled = bigTimerDigitsEnabled
            self.updatedAt = updatedAt
        }
    }

    /// v1 시점 `SoundAsset`의 형태 스냅샷(`waveformSamples` 없음). 이슈 #64에서
    /// `waveformSamples`가 추가되며 SchemaV3이 새로 생겼다 — AppSettings와 같은 이유로,
    /// 바뀌기 전 형태를 여기 그대로 얼려둔다.
    @Model
    final class SoundAsset {
        @Attribute(.unique) var id: UUID
        var kind: SoundAssetKind
        var name: String
        var relativePath: String?
        var durationMs: Int?
        var createdAt: Date
        var deletedAt: Date?

        init(
            id: UUID = UUID(),
            kind: SoundAssetKind,
            name: String,
            relativePath: String? = nil,
            durationMs: Int? = nil,
            createdAt: Date,
            deletedAt: Date? = nil
        ) {
            self.id = id
            self.kind = kind
            self.name = name
            self.relativePath = relativePath
            self.durationMs = durationMs
            self.createdAt = createdAt
            self.deletedAt = deletedAt
        }
    }
}
