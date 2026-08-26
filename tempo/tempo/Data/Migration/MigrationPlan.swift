//
//  MigrationPlan.swift
//  tempo
//

import SwiftData

/// 스키마 버전 간 마이그레이션 계획. 지금은 SchemaV1 하나뿐이라 단계가 없다.
/// 다음 버전이 추가되면 여기에 `MigrationStage`를 더한다.
/// docs/local-persistence-strategy.md "마이그레이션 원칙" 참고.
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
