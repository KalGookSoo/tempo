import SwiftUI

/// `.onboarding` 화면. 최초 실행 온보딩(`OnboardingView`)과 같은 콘텐츠를 설정에서
/// 다시 볼 수 있게 한다.
struct SettingsOnboardingView: View {
    var body: some View {
        OnboardingPagesView(steps: OnboardingContent.steps)
            .constrainedWidth()
            .navigationTitle("사용법 다시 보기")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsOnboardingView()
    }
}
