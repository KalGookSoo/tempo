//
//  Route.swift
//  tempo
//

import Foundation

/// 앱의 화면 이동 대상을 표현하는 값 기반 라우트.
/// `NavigationStack`의 `navigationDestination(for: Route.self)`와 함께 쓴다.
/// 홈 화면은 `NavigationStack`의 루트이므로 별도 case가 필요 없다.
/// 정의는 docs/navigation-structure.md 참고.
enum Route: Hashable {
    case timer
    case stopwatch
    case interval
    case intervalNew
    case intervalPrograms
    case intervalProgramDetail(id: String)
    case intervalProgramEdit(id: String)
    case intervalHelp
    case intervalHelpDetail(id: String)
    case intervalRun(programID: String)
}
