//
//  IntervalNewView.swift
//  tempo
//

import SwiftUI

/// `.new` 화면 자리. 이름/구간 구성/라운드/알림 큐 입력 폼은 후속 이슈(인터벌 편집 UI)에서
/// 구현한다. 지금은 라우팅 확인용으로 저장 시 상세 화면으로 이동하는 흐름만 갖춘다.
/// docs/navigation-structure.md "새 프로그램 `.intervalNew`" 참고.
struct IntervalNewView: View {
    @Environment(Router.self) private var router

    var body: some View {
        ContentUnavailableView {
            Label("새 프로그램", systemImage: "plus")
        } description: {
            Text("이름/구간/라운드 입력 폼은 아직 구현되지 않았습니다.")
        }
        .navigationTitle("새 프로그램")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    router.push(IntervalRoute.programDetail(id: "placeholder"))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        IntervalNewView()
    }
    .environment(Router())
}
