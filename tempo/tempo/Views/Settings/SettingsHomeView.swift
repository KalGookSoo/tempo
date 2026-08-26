//
//  SettingsHomeView.swift
//  tempo
//

import SwiftUI

/// 설정 탭의 루트 화면. moov의 "관리" 탭처럼 도움말/온보딩/버전 정보를 모아 보여준다.
struct SettingsHomeView: View {
    var body: some View {
        List {
            NavigationLink(value: SettingsRoute.help) {
                Label("도움말", systemImage: "questionmark.circle")
            }
            NavigationLink(value: SettingsRoute.onboarding) {
                Label("사용법 다시 보기", systemImage: "sparkles")
            }
            NavigationLink(value: SettingsRoute.version) {
                Label("버전 정보", systemImage: "info.circle")
            }
        }
        .navigationTitle("설정")
    }
}

#Preview {
    NavigationStack {
        SettingsHomeView()
    }
}
