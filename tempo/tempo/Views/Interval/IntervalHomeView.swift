//
//  IntervalHomeView.swift
//  tempo
//

import SwiftUI

/// 인터벌 탭의 루트 화면. 인터벌 프로그램 관련 흐름의 진입점.
/// docs/navigation-structure.md "인터벌 `.interval`" 참고.
struct IntervalHomeView: View {
    var body: some View {
        List {
            NavigationLink(value: IntervalRoute.new) {
                Label("새 프로그램", systemImage: "plus")
            }
            NavigationLink(value: IntervalRoute.programs) {
                Label("프로그램 목록", systemImage: "list.bullet")
            }
            NavigationLink(value: IntervalRoute.help) {
                Label("도움말", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle("인터벌")
    }
}

#Preview {
    NavigationStack {
        IntervalHomeView()
    }
}
