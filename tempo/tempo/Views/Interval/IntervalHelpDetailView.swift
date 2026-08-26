//
//  IntervalHelpDetailView.swift
//  tempo
//

import SwiftUI

/// `.helpDetail(id:)` 화면 자리. 선택한 프로그램을 tempo 인터벌 입력값으로 만드는 방법
/// 설명은 후속 이슈에서 채운다. docs/navigation-structure.md "도움말 상세
/// `.intervalHelpDetail(id:)`" 참고.
struct IntervalHelpDetailView: View {
    let id: String

    var body: some View {
        ContentUnavailableView {
            Label("도움말", systemImage: "questionmark.circle")
        } description: {
            Text("'\(id)' 설명은 아직 구현되지 않았습니다.")
        } actions: {
            NavigationLink(value: IntervalRoute.new) {
                Label("새 프로그램 만들기", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("도움말")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        IntervalHelpDetailView(id: "tabata")
    }
}
