import SwiftUI

extension Path: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let rid = rid {
                Text("Remote ID: \(rid)")
            } else {
                Text("Unsynced")
                    .bold()
                    .foregroundStyle(.orange)
            }
            NamedStringDisplayView(name: "Name", value: name)
            Text("Details: \(details ?? "Unset")")
            Text("Start place id: \(placeStart?.rid ?? -1)")
            Text("End place id: \(placeEnd?.rid ?? -1)")
        }
    }
}
