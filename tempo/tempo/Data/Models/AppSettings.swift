//
//  AppSettings.swift
//  tempo
//

import Foundation
import SwiftData

/// 앱 전역 설정. 항목 수가 적어 범용 key-value 대신 필드별 타입 있는 속성으로 관리한다.
/// 앱 인스턴스당 row가 하나만 존재한다(없으면 seed 단계에서 기본값으로 생성).
/// docs/local-persistence-strategy.md "AppSettings" 참고.
@Model
final class AppSettings {
    var themeMode: ThemeMode
    var bigTimerDigitsEnabled: Bool
    var hasCompletedOnboarding: Bool = false
    var updatedAt: Date

    init(
        themeMode: ThemeMode = .system,
        bigTimerDigitsEnabled: Bool = false,
        hasCompletedOnboarding: Bool = false,
        updatedAt: Date
    ) {
        self.themeMode = themeMode
        self.bigTimerDigitsEnabled = bigTimerDigitsEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.updatedAt = updatedAt
    }
}

enum ThemeMode: String, Codable {
    case system
    case light
    case dark
}
