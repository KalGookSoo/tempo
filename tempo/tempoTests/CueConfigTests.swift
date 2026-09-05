import Foundation
@testable import tempo
import Testing

/// 이슈 #75: `workEnd` 필드 추가 전에 저장된 `CueConfig`도 안전하게 디코딩되는지
/// 확인한다(디코딩 실패로 앱이 크래시하면 안 된다).
@Suite("CueConfig")
struct CueConfigTests {
    @Test("workEnd 키가 없는 옛 데이터를 디코딩하면 꺼짐(.none)으로 기본값이 채워진다")
    func decodingLegacyDataWithoutWorkEndFallsBackToNone() throws {
        let legacyJSON = """
        {
            "countdownLeadSeconds": 3,
            "prepareStart": { "mode": "none", "soundAssetID": null },
            "workStart": { "mode": "soundAndVibration", "soundAssetID": null },
            "restStart": { "mode": "none", "soundAssetID": null },
            "segmentEnd": { "mode": "none", "soundAssetID": null },
            "roundEnd": { "mode": "none", "soundAssetID": null },
            "finalRoundEnter": { "mode": "none", "soundAssetID": null },
            "finish": { "mode": "soundAndVibration", "soundAssetID": null }
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(CueConfig.self, from: legacyJSON)

        #expect(config.workEnd == CueConfig.Event(mode: .none, soundAssetID: nil))
        #expect(config.workStart.mode == .soundAndVibration)
    }

    @Test("workEnd를 지정한 뒤 인코딩·디코딩하면 그대로 유지된다")
    func encodingAndDecodingRoundTripsWorkEnd() throws {
        let assetID = UUID()
        let none = CueConfig.Event(mode: .none, soundAssetID: nil)
        var config = CueConfig(
            countdownLeadSeconds: 3,
            prepareStart: none,
            workStart: none,
            restStart: none,
            segmentEnd: none,
            workEnd: none,
            roundEnd: none,
            finalRoundEnter: none,
            finish: none
        )
        config.workEnd = CueConfig.Event(mode: .sound, soundAssetID: assetID)

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(CueConfig.self, from: data)

        #expect(decoded.workEnd == CueConfig.Event(mode: .sound, soundAssetID: assetID))
    }
}
