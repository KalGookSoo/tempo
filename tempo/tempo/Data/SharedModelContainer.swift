import Foundation
import OSLog
import SwiftData

enum SharedModelContainer {
    /// 배포된 빌드에서도 확인할 수 있는 로그(이슈 #89). 아래 `fatalError`는 그 자체로
    /// 크래시 리포트에 메시지가 남지만, Console.app에서도 바로 찾을 수 있게 fault로도 남긴다.
    private static let logger = Logger(subsystem: "kr.me.seesaw.tempo", category: "ModelContainer")

    /// 앱 실행용 `ModelContainer`를 만들고, 필요하면 기본 프리셋을 seed한다.
    static func make() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(
                for: Schema(versionedSchema: SchemaV3.self),
                migrationPlan: MigrationPlan.self,
                configurations: [configuration]
            )
            try PresetSeeder.seedDefaultsIfNeeded(in: container.mainContext)
            try SoundAssetSeeder.seedDefaultsIfNeeded(in: container.mainContext)
            try CueProfileSeeder.seedDefaultIfNeeded(in: container.mainContext)
            try SettingsRepository(modelContext: container.mainContext).seedDefaultIfNeeded()
            return container
        } catch {
            logger.fault("ModelContainer 생성 실패: \(error.localizedDescription)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
