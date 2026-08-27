//
//  SettingsRecordingsView.swift
//  tempo
//

import SwiftData
import SwiftUI

/// 설정 탭의 "녹음한 사운드" 화면. 마이크로 직접 녹음한 알림 큐 사운드를
/// 등록/재생/이름변경/삭제(CRUD)한다. docs/local-persistence-strategy.md
/// "파일 저장 전략", 이슈 #8 참고.
struct SettingsRecordingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<SoundAsset> { $0.deletedAt == nil }, sort: \SoundAsset.createdAt, order: .reverse)
    private var assets: [SoundAsset]

    @State private var recorder = SoundRecorder()
    @State private var errorMessage: String?
    @State private var renamingAsset: SoundAsset?
    @State private var renameText = ""

    private var recordings: [SoundAsset] {
        assets.filter { $0.kind == .recorded }
    }

    var body: some View {
        Group {
            if recorder.permissionStatus == .denied {
                ContentUnavailableView {
                    Label("마이크 권한이 필요해요", systemImage: "mic.slash")
                } description: {
                    Text("설정 앱 > tempo에서 마이크 권한을 허용해주세요.")
                }
            } else if recordings.isEmpty {
                ContentUnavailableView {
                    Label("녹음한 사운드가 없어요", systemImage: "mic")
                } description: {
                    Text("마이크 버튼을 눌러 알림 큐로 쓸 소리를 녹음해보세요.")
                }
            } else {
                List(recordings) { asset in
                    Button {
                        recorder.preview(asset)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(asset.name)
                            if let durationMs = asset.durationMs {
                                Text(formattedDuration(durationMs))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            delete(asset)
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                        Button {
                            startRenaming(asset)
                        } label: {
                            Label("이름 변경", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("녹음한 사운드")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    toggleRecording()
                } label: {
                    Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle")
                }
                .disabled(recorder.permissionStatus == .denied)
                .accessibilityLabel(recorder.isRecording ? "녹음 정지" : "녹음 시작")
            }
        }
        .alert(
            "실패했습니다",
            isPresented: Binding(get: { errorMessage != nil }, set: {
                if !$0 {
                    errorMessage = nil
                }
            }),
            actions: { Button("확인") {} },
            message: { Text(errorMessage ?? "") }
        )
        .alert(
            "이름 변경",
            isPresented: Binding(get: { renamingAsset != nil }, set: {
                if !$0 {
                    renamingAsset = nil
                }
            })
        ) {
            TextField("이름", text: $renameText)
            Button("취소", role: .cancel) {}
            Button("저장") {
                confirmRenaming()
            }
        }
        .task {
            recorder.refreshPermissionStatus()
            if recorder.permissionStatus == .undetermined {
                await recorder.requestPermission()
            }
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            guard let result = recorder.stopRecording() else { return }
            do {
                try SoundAssetRepository(modelContext: modelContext).createRecordedAsset(
                    id: result.id,
                    name: "녹음 \(recordings.count + 1)",
                    durationMs: result.durationMs
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            do {
                try recorder.startRecording()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func startRenaming(_ asset: SoundAsset) {
        renamingAsset = asset
        renameText = asset.name
    }

    private func confirmRenaming() {
        guard let renamingAsset else { return }
        do {
            try SoundAssetRepository(modelContext: modelContext).rename(renamingAsset, to: renameText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ asset: SoundAsset) {
        do {
            try SoundAssetRepository(modelContext: modelContext).delete(asset)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func formattedDuration(_ durationMs: Int) -> String {
        let totalSeconds = durationMs / 1000
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

#Preview {
    NavigationStack {
        SettingsRecordingsView()
    }
    .modelContainer(for: SoundAsset.self, inMemory: true)
}
