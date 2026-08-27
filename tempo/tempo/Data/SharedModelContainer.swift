//
//  SharedModelContainer.swift
//  tempo
//

import Foundation
import SwiftData

enum SharedModelContainer {
    /// 앱 실행용 `ModelContainer`를 만들고, 필요하면 기본 프리셋을 seed한다.
    static func make() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(
                for: Schema(versionedSchema: SchemaV2.self),
                migrationPlan: MigrationPlan.self,
                configurations: [configuration]
            )
            try PresetSeeder.seedDefaultsIfNeeded(in: container.mainContext)
            try SoundAssetSeeder.seedDefaultsIfNeeded(in: container.mainContext)
            try CueProfileSeeder.seedDefaultIfNeeded(in: container.mainContext)
            try SettingsRepository(modelContext: container.mainContext).seedDefaultIfNeeded()
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
