//
//  SettingsOnboardingView.swift
//  tempo
//

import SwiftUI

/// `.onboarding` 화면 자리. 최초 실행 온보딩과 같은 콘텐츠를 설정에서 다시 볼 수 있게 한다.
/// 실제 온보딩 단계/콘텐츠는 후속 이슈에서 채운다.
struct SettingsOnboardingView: View {
    var body: some View {
        ContentUnavailableView {
            Label("사용법 다시 보기", systemImage: "sparkles")
        } description: {
            Text("온보딩 콘텐츠는 아직 구현되지 않았습니다.")
        }
        .navigationTitle("사용법 다시 보기")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsOnboardingView()
    }
}
