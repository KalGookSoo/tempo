//
//  CueProfile.swift
//  tempo
//

import Foundation
import SwiftData

/// 알림 큐 프로필. docs/local-persistence-strategy.md "CueProfile" 참고.
@Model
final class CueProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var isDefault: Bool
    var config: CueConfig
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        isDefault: Bool = false,
        config: CueConfig,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.config = config
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
