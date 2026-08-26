//
//  IntervalProgramDetailView.swift
//  tempo
//

import SwiftUI

/// `.intervalProgramDetail(id:)` 화면 자리. 저장된 인터벌 프로그램 설정 조회는 후속 이슈에서
/// 연결한다. docs/navigation-structure.md "프로그램 상세 `.intervalProgramDetail(id:)`" 참고.
struct IntervalProgramDetailView: View {
    let id: String

    var body: some View {
        ContentUnavailableView {
            Label("프로그램 상세", systemImage: "list.bullet.rectangle")
        } description: {
            Text("프로그램 ID: \(id)")
        } actions: {
            NavigationLink(value: Route.intervalRun(programID: id)) {
                Label("실행", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            NavigationLink(value: Route.intervalProgramEdit(id: id)) {
                Label("수정", systemImage: "pencil")
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("프로그램 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        IntervalProgramDetailView(id: "preview")
    }
}
