import SwiftUI

extension Person: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let rid {
                Text(verbatim: "RID: \(rid)")
            } else {
                Text("RID: Unsynced")
                    .foregroundStyle(.orange)
            }
            NamedStringDisplayView(name: "Slug", value: slug)
            NamedStringDisplayView(name: "Name", value: name)
            NamedStringDisplayView(name: "Family name", value: familyName)
            NamedStringDisplayView(name: "Surname", value: surname, unsetTint: .yellow)
        }
    }
}
