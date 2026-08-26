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
    nonisolated struct Event: Codable, Hashable {
        var soundId: String
        var vibration: Bool
    }

    var countdownCueSeconds: [Int]
    var useVibrationWhenMuted: Bool
    var prepareStart: Event
    var workStart: Event
    var restStart: Event
    var finish: Event
}
