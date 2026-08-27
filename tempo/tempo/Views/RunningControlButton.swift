//
//  RunningControlButton.swift
//  tempo
//

import SwiftUI

/// 타이머/스톱워치/인터벌 실행 화면이 공유하는 원형 조작 버튼. iOS 기본 시계 앱처럼
/// 좌우 핵심 동작(시작/일시정지/재개/리셋)이 크고 색으로 구분되는 원형 버튼으로
/// 눈에 띄게 보이도록 한다.
struct RunningControlButton: View {
    /// 색상은 동작의 의미가 직관적으로 읽히도록 고정한다: 시작/재개는 초록(진행),
    /// 일시정지는 주황(주의), 리셋은 중립 회색(위험한 동작이 아님).
    enum Style {
        case start
        case pause
        case reset

        var backgroundColor: Color {
            switch self {
            case .start: .green
            case .pause: .orange
            case .reset: Color(.systemGray5)
            }
        }

        var foregroundColor: Color {
            switch self {
            case .start, .pause: .white
            case .reset: .primary
            }
        }
    }

    let title: String
    let style: Style
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    private static let diameter: CGFloat = 84

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(style.foregroundColor)
                .frame(width: Self.diameter, height: Self.diameter)
                .background(style.backgroundColor, in: Circle())
        }
        .opacity(isEnabled ? 1 : 0.4)
    }
}

#Preview {
    HStack(spacing: 24) {
        RunningControlButton(title: "리셋", style: .reset) {}
        RunningControlButton(title: "일시정지", style: .pause) {}
        RunningControlButton(title: "시작", style: .start) {}
    }
}
