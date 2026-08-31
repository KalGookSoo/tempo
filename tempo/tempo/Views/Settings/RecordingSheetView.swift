import SwiftUI

/// 마이크 버튼을 누르면 화면 하단에서 올라오는 녹음 시트. 음성 메모 앱처럼 녹음을
/// 시작/정지한 뒤 저장 또는 취소를 고르게 한다. 저장은 호출부(`onSave`)에 위임하고,
/// 취소하면 임시로 쓰인 파일을 지운다. 이슈 #28 참고.
struct RecordingSheetView: View {
    let recorder: SoundRecorder
    let onSave: (_ id: UUID, _ durationMs: Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var stoppedResult: (id: UUID, durationMs: Int)?
    @State private var errorMessage: String?

    private var isStopped: Bool {
        stoppedResult != nil
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(statusText)
                .font(.headline)
                .foregroundStyle(.secondary)

            Button {
                toggleRecording()
            } label: {
                Image(systemName: recorder.isRecording ? "stop.circle.fill" : "circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.red)
            }
            .disabled(isStopped)

            if isStopped {
                HStack(spacing: 32) {
                    Button("취소", role: .destructive) {
                        discard()
                    }
                    Button("저장") {
                        save()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .presentationDetents([.medium])
        .interactiveDismissDisabled(recorder.isRecording)
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
    }

    private var statusText: String {
        if recorder.isRecording {
            "녹음 중..."
        } else if isStopped {
            "녹음 완료 — 저장하시겠어요?"
        } else {
            "버튼을 눌러 녹음을 시작하세요"
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            stoppedResult = recorder.stopRecording()
        } else {
            do {
                try recorder.startRecording()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func discard() {
        if let stoppedResult {
            RecordedSoundFileStore.deleteFile(for: stoppedResult.id)
        }
        dismiss()
    }

    private func save() {
        guard let stoppedResult else { return }
        onSave(stoppedResult.id, stoppedResult.durationMs)
        dismiss()
    }
}

#Preview {
    RecordingSheetView(recorder: SoundRecorder(), onSave: { _, _ in })
}
