//
//  OnboardingStep.swift
//  tempo
//

import Foundation

/// 온보딩 한 페이지의 내용. `OnboardingView`(최초 실행)와 `SettingsOnboardingView`
/// ("사용법 다시 보기")가 같은 콘텐츠를 공유한다.
struct OnboardingStep: Identifiable {
    let id: Int
    let systemImage: String
    let title: String
    let description: String
}

enum OnboardingContent {
    /// 이슈 #9 "기대하는 결과": tempo가 다목적 타이머 앱이라는 것, 기본 제공 프리셋,
    /// 직접 녹음 음성 큐를 소개한다.
    static let steps: [OnboardingStep] = [
        OnboardingStep(
            id: 0,
            systemImage: "timer",
            title: "하나의 앱, 세 가지 타이밍",
            description: "타이머, 스톱워치, 인터벌을 한 앱에서 오가며 쓸 수 있어요."
        ),
        OnboardingStep(
            id: 1,
            systemImage: "square.stack",
            title: "바로 쓰는 기본 프리셋",
            description: "Tabata, FGB, EMOM처럼 자주 쓰는 인터벌 구성이 기본으로 준비돼 있어요."
        ),
        OnboardingStep(
            id: 2,
            systemImage: "mic",
            title: "내 목소리로 알림 큐 만들기",
            description: "구간이 바뀔 때 들려줄 소리를 직접 녹음해서 등록할 수 있어요."
        ),
    ]
}
