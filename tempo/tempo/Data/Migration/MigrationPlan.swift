//
//  MigrationPlan.swift
//  tempo
//

import SwiftData

/// 스키마 버전 간 마이그레이션 계획. docs/local-persistence-strategy.md "마이그레이션 원칙" 참고.
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)]
    }
}
