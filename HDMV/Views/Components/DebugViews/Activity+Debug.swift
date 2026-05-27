import SwiftUI

extension Activity: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading) {
            if let rid = rid {
                Text("Remote ID: \(rid)")
            } else {
                Text("Unsynced")
                    .bold()
                    .foregroundStyle(.orange)
            }
            NamedStringDisplayView(name: "Name", value: name)
            NamedStringDisplayView(name: "Slug", value: slug)
            if let parentRid = parentRid {
                Text("Parent id: \(parentRid)")
            }
        }
    }
}
