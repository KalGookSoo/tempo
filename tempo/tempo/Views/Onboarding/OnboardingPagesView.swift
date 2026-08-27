//
//  OnboardingPagesView.swift
//  tempo
//

import SwiftUI

/// 온보딩 단계를 스와이프로 넘겨보는 페이지 콘텐츠. 최초 실행 온보딩과 설정의
/// "사용법 다시 보기"가 이 콘텐츠를 그대로 공유한다.
struct OnboardingPagesView: View {
    let steps: [OnboardingStep]

    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            ForEach(steps) { step in
                VStack(spacing: 16) {
                    Image(systemName: step.systemImage)
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)
                    Text(step.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(step.description)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .tag(step.id)
            }
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    OnboardingPagesView(steps: OnboardingContent.steps)
}
