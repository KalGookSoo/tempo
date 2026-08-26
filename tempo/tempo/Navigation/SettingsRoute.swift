//
//  SettingsRoute.swift
//  tempo
//

import Foundation

/// 설정 탭 안에서만 쓰는 값 기반 라우트. 설정 탭도 자체 `NavigationStack`을 가진다.
enum SettingsRoute: Hashable {
    case help
    case onboarding
    case version
    case cue
}
