//
//  Router.swift
//  tempo
//

import SwiftUI

/// 탭 하나의 `NavigationStack` 경로를 화면 계층 안에서 공유하기 위한 라우터.
/// 탭마다 별도의 `Router` 인스턴스를 만들어 `.environment(router)`로 그 탭의
/// `NavigationStack`에만 주입한다(예: 인터벌 탭 전용 Router, 설정 탭 전용 Router).
/// 화면에서는 `@Environment(Router.self)`로 꺼내 쓴다.
@Observable
final class Router {
    var path = NavigationPath()

    func push<Route: Hashable>(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// 이 탭의 루트까지 경로 전체를 초기화한다.
    func popToRoot() {
        path.removeLast(path.count)
    }
}
