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
            Text("Contexts: \(contextRids.count)")
            Text("Linked Files: \(linkedFilePaths.count)")
            
            NamedStringDisplayView(name: "SyncStatus", value: syncStatusRaw)
        }
    }
}
