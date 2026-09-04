import SwiftData
import SwiftUI

/// 사운드 선택 시트. `SoundAsset`(기본 제공/가져오기/직접 녹음)을 그대로 조회해서
/// 보여준다 — 고정된 목록을 별도로 두지 않는다. 타이머 화면("타이머 종료 시")과
/// 알림 큐 설정 화면(이벤트별 사운드)이 공유한다. docs/use-cases/timer.md 참고.
struct EndSoundPickerView: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<SoundAsset> { $0.deletedAt == nil })
    private var soundAssets: [SoundAsset]
    @Binding var selection: UUID?

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selection = nil
                    dismiss()
                } label: {
                    row(title: "없음", isSelected: selection == nil)
                }

                ForEach(soundAssets) { asset in
                    Button {
                        selection = asset.id
                        dismiss()
                    } label: {
                        row(title: asset.name, isSelected: selection == asset.id)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func row(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(LocalizedStringKey(title))
                .foregroundStyle(.primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
}

#Preview {
    EndSoundPickerView(title: "타이머 종료 시", selection: .constant(nil))
        .modelContainer(for: SoundAsset.self, inMemory: true)
}
