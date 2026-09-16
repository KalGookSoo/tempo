import OSLog
import SwiftData
import SwiftUI
import UIKit

/// `.programs` 화면. 저장된 인터벌 프로그램(기본 4종 + 사용자 프리셋) 목록을 `@Query`로
/// 실시간 조회한다. 기본 프리셋은 항상 seed되어 있으므로 실제로는 거의 비지 않지만, 방어적으로
/// fallback도 남겨둔다. docs/navigation-structure.md "프로그램 목록 `.intervalPrograms`" 참고.
struct IntervalProgramsView: View {
    @Query(filter: #Predicate<TimerPreset> { $0.deletedAt == nil }, sort: \TimerPreset.sortOrder)
    private var presets: [TimerPreset]

    @Environment(\.modelContext)
    private var modelContext

    @Environment(Router.self)
    private var router

    @State private var isWatchInstallAlertPresented = false

    /// 배포된 빌드에서도 실기기 콘솔(Console.app)로 확인할 수 있는 로그(이슈 #89).
    private static let watchSyncLogger = Logger(subsystem: "kr.me.seesaw.tempo", category: "WatchSync")

    var body: some View {
        Group {
            if presets.isEmpty {
                ContentUnavailableView {
                    Label("저장된 프로그램이 없어요", systemImage: "list.bullet")
                } description: {
                    Text("새 프로그램을 만들어 저장해보세요.")
                }
            } else {
                List(presets) { preset in
                    NavigationLink(value: IntervalRoute.programDetail(id: preset.id.uuidString)) {
                        VStack(alignment: .leading) {
                            Text(preset.name)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            try? PresetRepository(modelContext: modelContext).delete(preset)
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("프로그램 목록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 애플워치는 아이폰하고만 페어링되는 구조라 아이패드에서는 이 버튼이
            // 눌려도 기능적으로 아무 의미가 없다(WatchConnectivity 자체가 아이패드
            // 미지원) — 눌러도 반응 없는 버튼으로 보이지 않도록 아예 숨긴다(#100).
            if UIDevice.current.userInterfaceIdiom == .phone {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // 페어링된 애플워치는 있는데 tempo 앱이 없으면 설치를 안내한다
                        // — 애플이 앱에서 워치 설치를 직접 트리거하는 공식 API를 제공하지
                        // 않아서, 여기서 문구로 안내하는 선에서 그친다(#92).
                        if WatchSyncSender.shared.isPairedButNotInstalled {
                            Self.watchSyncLogger.notice("워치 연동 버튼: 설치 안내 alert 표시(전송은 계속 시도)")
                            isWatchInstallAlertPresented = true
                        }
                        let snapshots = presets.map { WatchPresetSnapshot(id: $0.id, name: $0.name, config: $0.config) }
                        WatchSyncSender.shared.send(presets: snapshots)
                    } label: {
                        Image(systemName: "applewatch")
                    }
                    .accessibilityLabel("애플워치에 프로그램 목록 보내기")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: IntervalRoute.new) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("새 프로그램")
            }
        }
        .alert("애플워치에 tempo 설치", isPresented: $isWatchInstallAlertPresented) {
            Button("확인") {}
        } message: {
            Text("아이폰의 Watch 앱에서 tempo를 설치하면 손목에서 바로 확인할 수 있어요.")
        }
    }
}

#Preview {
    NavigationStack {
        IntervalProgramsView()
    }
    .modelContainer(for: TimerPreset.self, inMemory: true)
}
