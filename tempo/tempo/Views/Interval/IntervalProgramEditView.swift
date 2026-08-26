//
//  IntervalProgramEditView.swift
//  tempo
//

import SwiftUI

/// `.intervalProgramEdit(id:)` 화면 자리. 이름/준비·운동·휴식 시간/라운드/알림 큐 수정 폼은
/// `.intervalNew`와 동일한 단계형 흐름을 재사용할 예정이며 후속 이슈에서 구현한다.
/// 저장/취소 모두 상세 화면으로 복귀한다(이미 스택에 있으므로 pop). docs/navigation-structure.md
/// "프로그램 수정 `.intervalProgramEdit(id:)`" 참고.
struct IntervalProgramEditView: View {
    let id: String

    @Environment(Router.self) private var router

    var body: some View {
        ContentUnavailableView {
            Label("프로그램 수정", systemImage: "pencil")
        } description: {
            Text("프로그램 ID: \(id)")
        }
        .navigationTitle("프로그램 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { router.pop() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { router.pop() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        IntervalProgramEditView(id: "preview")
    }
    .environment(Router())
}
