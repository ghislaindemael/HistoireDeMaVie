import SwiftUI

extension AgendaEntry: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading) {
            if let rid = rid {
                Text("Remote ID: \(rid)")
            } else {
                Text("Unsynced")
                    .bold()
                    .foregroundStyle(.orange)
            }
            NamedStringDisplayView(name: "Summary", value: daySummary)
            Text("Mood: \((mood))%")
            NamedStringDisplayView(name: "MoodComments", value: moodComments)
            
            NamedStringDisplayView(name: "SyncStatus", value: syncStatusRaw)
        }
    }
}
