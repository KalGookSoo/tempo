//
//  HomeView.swift
//  tempo
//

import SwiftUI

/// `NavigationStack`의 루트 화면. 사용자가 바로 실행할 타이머 유형을 선택한다.
/// docs/navigation-structure.md의 "홈" 정의 참고.
struct HomeView: View {
    var body: some View {
        List {
            NavigationLink(value: Route.timer) {
                Label("타이머", systemImage: "timer")
            }
            NavigationLink(value: Route.stopwatch) {
                Label("스톱워치", systemImage: "stopwatch")
            }
            NavigationLink(value: Route.interval) {
                Label("인터벌", systemImage: "repeat")
            }
        }
        .navigationTitle("tempo")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
