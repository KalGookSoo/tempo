import SwiftData
import SwiftUI

/// `.programs` 화면. 저장된 인터벌 프로그램(기본 4종 + 사용자 프리셋) 목록을 `@Query`로
/// 실시간 조회한다. 기본 프리셋은 항상 seed되어 있으므로 실제로는 거의 비지 않지만, 방어적으로
/// fallback도 남겨둔다. docs/navigation-structure.md "프로그램 목록 `.intervalPrograms`" 참고.
struct IntervalProgramsView: View {
    @Query(filter: #Predicate<TimerPreset> { $0.deletedAt == nil }, sort: \TimerPreset.sortOrder)
    private var presets: [TimerPreset]

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
                            Text(preset.kind == .default ? "기본 프리셋" : "내 프리셋")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("프로그램 목록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: IntervalRoute.new) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("새 프로그램")
            }
        }
    }
}

#Preview {
    NavigationStack {
        IntervalProgramsView()
    }
    .modelContainer(for: TimerPreset.self, inMemory: true)
}
