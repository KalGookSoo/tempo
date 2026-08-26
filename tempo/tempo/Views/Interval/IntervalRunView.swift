//
//  IntervalRunView.swift
//  tempo
//

import SwiftUI

/// `.run(programID:)` 화면 자리. 실행 중 큰 시간 숫자와 현재 구간/라운드 정보 표시,
/// 미러링 대응 레이아웃은 후속 이슈에서 구현한다. docs/navigation-structure.md
/// "인터벌 실행 `.intervalRun(programID:)`" 참고.
struct IntervalRunView: View {
    let programID: String

    @Environment(Router.self) private var router

    var body: some View {
        ContentUnavailableView {
            Label("인터벌 실행", systemImage: "play.fill")
        } description: {
            Text("프로그램 ID: \(programID)")
        } actions: {
            Button("완료") {
                router.popToRoot()
            }
            .buttonStyle(.borderedProminent)
            Button("설정 수정") {
                router.push(IntervalRoute.programEdit(id: programID))
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("인터벌 실행")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    NavigationStack {
        IntervalRunView(programID: "preview")
    }
    .environment(Router())
}
