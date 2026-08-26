//
//  IntervalProgramsView.swift
//  tempo
//

import SwiftUI

/// `.intervalPrograms` 화면. 저장된 사용자 인터벌 프로그램 목록.
/// 실제 데이터 소스(SwiftData)는 후속 이슈에서 연결하고, 지금은 빈 상태(fallback)만 보여준다.
/// docs/navigation-structure.md "프로그램 목록 `.intervalPrograms`" 참고.
struct IntervalProgramsView: View {
    var body: some View {
        ContentUnavailableView {
            Label("저장된 프로그램이 없어요", systemImage: "list.bullet")
        } description: {
            Text("새 프로그램을 만들어 저장해보세요.")
        }
        .navigationTitle("프로그램 목록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: Route.intervalNew) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("새 프로그램")
            }
            ToolbarItem(placement: .secondaryAction) {
                NavigationLink(value: Route.intervalHelp) {
                    Image(systemName: "questionmark.circle")
                }
                .accessibilityLabel("도움말")
            }
        }
    }
}

#Preview {
    NavigationStack {
        IntervalProgramsView()
    }
}
