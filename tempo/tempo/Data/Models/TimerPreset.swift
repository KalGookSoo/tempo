import Foundation
import SwiftData

/// 기본 프리셋과 사용자 프리셋을 저장한다. MVP에서 프리셋은 인터벌 전용이다 — 타이머의
/// 카운트다운/카운트업은 프리셋으로 저장하지 않는다. docs/local-persistence-strategy.md
/// "TimerPreset" 참고.
@Model
final class TimerPreset {
    @Attribute(.unique) var id: UUID
    var kind: PresetKind
    var mode: String
    var name: String
    var presetDescription: String?
    var config: IntervalConfig
    var cueProfileID: UUID?
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date? // soft delete

    init(
        id: UUID = UUID(),
        kind: PresetKind,
        mode: String = "interval",
        name: String,
        presetDescription: String? = nil,
        config: IntervalConfig,
        cueProfileID: UUID? = nil,
        sortOrder: Int,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.mode = mode
        self.name = name
        self.presetDescription = presetDescription
        self.config = config
        self.cueProfileID = cueProfileID
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

enum PresetKind: String, Codable {
    case `default`
    case custom
}
