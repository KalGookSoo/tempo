import SwiftUI

struct ContentView: View {
    @StateObject private var receiver = WatchSyncReceiver.shared

    var body: some View {
        if let snapshot = receiver.latestSnapshot {
            Text(snapshot.programName)
            Text("\(Int(snapshot.elapsedSeconds))초 경과")
        } else {
            Text("대기 중")
        }
    }
}

#Preview {
    ContentView()
}
