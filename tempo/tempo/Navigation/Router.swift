//
//  Router.swift
//  tempo
//

import SwiftUI

/// `NavigationStack`의 경로를 앱 전역에서 공유하기 위한 라우터.
/// `.environment(router)`로 주입하고, 화면에서는 `@Environment(Router.self)`로 꺼내 쓴다.
@Observable
final class Router {
    var path = NavigationPath()

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// 홈(NavigationStack 루트)까지 경로 전체를 초기화한다.
    /// 인터벌 실행 완료 후 홈으로 복귀하는 흐름에서 사용한다.
    func popToRoot() {
        path.removeLast(path.count)
    }
}
