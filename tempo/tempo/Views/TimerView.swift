//
//  TimerView.swift
//  tempo
//

import SwiftUI

/// `.timer` 화면 자리. 카운트다운/카운트업 토글 및 실제 타이머 로직은 후속 이슈에서 구현한다.
/// docs/timer-functional-spec.md "1. 타이머" 참고.
struct TimerView: View {
    var body: some View {
        ContentUnavailableView {
            Label("타이머", systemImage: "timer")
        } description: {
            Text("카운트다운/카운트업 타이머 화면은 아직 구현되지 않았습니다.")
        }
        .navigationTitle("타이머")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TimerView()
    }
}
