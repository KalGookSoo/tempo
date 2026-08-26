//
//  CueConfig.swift
//  tempo
//

import Foundation

/// 알림 큐 규칙. SwiftData `@Model` 프로퍼티 타입으로 직접 저장한다(JSON 문자열 직렬화 없음).
/// 프로젝트의 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 설정 때문에 기본으로는 이 타입의
/// Codable 준수까지 MainActor로 격리되어, SwiftData가 백그라운드에서 인코딩할 때 충돌한다
/// (Swift 6 언어 모드에서는 경고가 아니라 에러). 순수 값 타입이라 `nonisolated`로 격리를 뺀다.
/// docs/local-persistence-strategy.md "CueProfile" 참고.
nonisolated struct CueConfig: Codable, Hashable {
    /// 없음/사운드/진동/사운드+진동. 이벤트마다 따로 고를 수 있다.
    nonisolated enum Mode: String, Codable, CaseIterable, Identifiable {
        case none
        case sound
        case vibration
        case soundAndVibration

        var id: String {
            rawValue
        }

        var displayName: String {
            switch self {
            case .none: "없음"
            case .sound: "사운드"
            case .vibration: "진동"
            case .soundAndVibration: "사운드 + 진동"
            }
        }

        var playsSound: Bool {
            self == .sound || self == .soundAndVibration
        }

        var playsVibration: Bool {
            self == .vibration || self == .soundAndVibration
        }
    }

    nonisolated struct Event: Codable, Hashable {
        var mode: Mode
        /// `SoundAsset.id` 참조. `nil`이면 MVP 기본 사운드를 쓴다(#16에서 실제 사운드 확보,
        /// #8에서 직접 녹음 지정 — 이 필드로 이미 수용 가능).
        var soundAssetID: UUID?
    }

    /// 시작 전 카운트다운 알림 시점(초). `0`이면 "없음". `1`/`3`/`5`/`10` 중에서 고른다.
    var countdownLeadSeconds: Int

    var prepareStart: Event
    var workStart: Event
    var restStart: Event
    var segmentEnd: Event
    var roundEnd: Event
    var finalRoundEnter: Event
    var finish: Event
}
