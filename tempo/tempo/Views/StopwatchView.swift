//
//  StopwatchView.swift
//  tempo
//

import SwiftUI

/// `.stopwatch` 화면 자리. 실제 스톱워치 로직은 후속 이슈에서 구현한다.
/// docs/timer-functional-spec.md "2. 스톱워치" 참고.
struct StopwatchView: View {
    var body: some View {
        ContentUnavailableView {
            Label("스톱워치", systemImage: "stopwatch")
        } description: {
            Text("스톱워치 화면은 아직 구현되지 않았습니다.")
        }
        .navigationTitle("스톱워치")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StopwatchView()
    }
}
