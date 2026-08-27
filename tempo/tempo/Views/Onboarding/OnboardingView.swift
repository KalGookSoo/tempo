//
//  OnboardingView.swift
//  tempo
//

import SwiftUI

/// 앱 최초 실행 시 `.fullScreenCover`로 띄우는 온보딩 화면. "건너뛰기"/"시작하기" 둘 다
/// `onComplete`를 호출한다 — 이슈 #9: "완료(또는 건너뛰기)하면 이후 재실행 시 다시
/// 표시되지 않는다".
struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingPagesView(steps: OnboardingContent.steps)

            HStack {
                Button("건너뛰기") {
                    onComplete()
                }
                .foregroundStyle(.secondary)

                Spacer()

                Button("시작하기") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
