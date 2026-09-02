import Foundation
import SwiftData

/// 앱 최초 실행 시 기본 제공 사운드 5종을 `SoundAsset(kind: .builtin)`으로 등록한다.
/// 파일은 `Resources/Sounds/`에 번들로 포함돼 있다. `docs/timer-functional-spec.md`
/// "기본 사운드" 참고.
enum SoundAssetSeeder {
    /// 이미 있는 이름은 건너뛰고, 아직 없는 기본 사운드만 추가한다(앱 업데이트로 기본
    /// 사운드가 늘어났을 때, 이미 일부가 시드된 기존 설치에도 새로 생긴 것만 채워 넣기 위함).
    static func seedDefaultsIfNeeded(in modelContext: ModelContext) throws {
        let existingNames = try Set(
            modelContext.fetch(FetchDescriptor<SoundAsset>())
                .filter { $0.kind == .builtin }
                .map(\.name)
        )
        let missingSeeds = defaultSeeds.filter { !existingNames.contains($0.name) }
        guard !missingSeeds.isEmpty else { return }

        let now = Date()
        for seed in missingSeeds {
            let asset = SoundAsset(kind: .builtin, name: seed.name, relativePath: seed.fileName, createdAt: now)
            modelContext.insert(asset)
        }
        try modelContext.save()
    }

    /// 이벤트 종류별 기본 사운드 이름. `docs/timer-functional-spec.md` "기본 사운드"의
    /// "운동/휴식 시작 = 더블 비프, 카운트다운 = 짧은 비프, 전체 종료 = 긴 비프(3초)"를
    /// 따른다. 소리만 듣고도 성격이 구분되도록 이벤트를 세 그룹으로 나눈다 — 시작
    /// (운동/휴식): 더블 비프, 카운트다운: 싱글 비프, 종료: 긴 비프. 그 외(준비 시작,
    /// 구간/라운드 종료, 마지막 라운드 진입)는 지금처럼 짧은 비프를 그대로 쓴다.
    /// `CueConfig.Event.soundAssetID`가 지정되지 않았을 때(MVP 기본값) 이 이름으로 조회한다.
    static func defaultSoundName(for kind: CueEventKind) -> String {
        switch kind {
        case .finish:
            "긴 비프 (3초)"
        case .workStart, .restStart:
            "더블 비프"
        default:
            "짧은 비프"
        }
    }

    static let defaultSeeds: [(name: String, fileName: String)] = [
        ("짧은 비프", "beep.wav"),
        ("긴 비프", "beep-long.wav"),
        ("종료음", "finish.wav"),
        ("긴 비프 (3초)", "beep-3s.wav"),
        ("더블 비프", "beep-double.wav"),
    ]
}
