import SwiftUI

extension Place: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let rid {
                Text(verbatim: "RID: \(rid)")
            } else {
                Text("RID: –")
                    .foregroundStyle(.secondary)
            }
            Text("Name: \(name)")
            if let cid = cityRid  {
                Text("City RID: \(cid)")
            } else {
                Text("City RID : Unset")
                    .bold()
                    .foregroundStyle(.red)
            }
        }
    }
}
