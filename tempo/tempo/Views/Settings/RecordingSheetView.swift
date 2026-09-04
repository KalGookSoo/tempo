import SwiftUI

/// 마이크 버튼을 누르면 화면 하단에서 올라오는 녹음 시트. 음성 메모 앱처럼 녹음을
/// 시작/정지한 뒤 저장 또는 취소를 고르게 한다. 저장은 호출부(`onSave`)에 위임하고,
/// 취소하면 임시로 쓰인 파일을 지운다. 이슈 #28 참고.
struct RecordingSheetView: View {
    let recorder: SoundRecorder
    let onSave: (_ id: UUID, _ durationMs: Int, _ waveformSamples: [Float]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    /// `recorder.lastRecordingResult`는 새 녹음을 시작하면 nil로 되돌아가므로, 아직
    /// 한 번도 녹음을 멈추지 않은 상태와 방금 멈춘 상태를 그대로 구분해준다 — 최대
    /// 길이 도달로 자동 정지됐을 때도(버튼을 누르지 않아도) 곧바로 반영된다.
    private var isStopped: Bool {
        recorder.lastRecordingResult != nil
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(statusText)
                .font(.headline)
                .foregroundStyle(.secondary)

            if recorder.isRecording || isStopped {
                Text(elapsedText)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.secondary)

                WaveformView(samples: recorder.levelSamples, color: recorder.isRecording ? .red : .accentColor)
                    .frame(height: 48)
                    .padding(.horizontal)
            }

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
            "버튼을 눌러 녹음을 시작하세요(최대 \(Int(SoundRecorder.maxDuration))초)"
        }
    }

    private var elapsedText: String {
        let elapsed = recorder.isRecording ? recorder.elapsedTime : (Double(recorder.lastRecordingResult?.durationMs ?? 0) / 1000)
        return String(format: "%.1f / %.0f초", elapsed, SoundRecorder.maxDuration)
    }

    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stopRecording()
        } else {
            do {
                try recorder.startRecording()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func discard() {
        if let result = recorder.lastRecordingResult {
            RecordedSoundFileStore.deleteFile(for: result.id)
        }
        dismiss()
    }

    private func save() {
        guard let result = recorder.lastRecordingResult else { return }
        onSave(result.id, result.durationMs, recorder.levelSamples)
        dismiss()
    }
}

#Preview {
    RecordingSheetView(recorder: SoundRecorder(), onSave: { _, _, _ in })
}
