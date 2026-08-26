//
//  SettingsHelpView.swift
//  tempo
//

import SwiftUI

/// `.help` 화면 자리. 실제 이용 가이드 콘텐츠(각 타이머 모드 설명, 알림 큐 설정법 등)는
/// 후속 이슈에서 채운다.
struct SettingsHelpView: View {
    var body: some View {
        ContentUnavailableView {
            Label("도움말", systemImage: "questionmark.circle")
        } description: {
            Text("이용 가이드는 아직 구현되지 않았습니다.")
        }
        .navigationTitle("도움말")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsHelpView()
    }
}
