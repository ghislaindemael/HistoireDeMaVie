import SwiftUI

struct DataBankAccountRowView: View {
    
    let account: DataBankAccount
    let onCacheToggle: (DataBankAccount) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "building.columns")
                .frame(width: 24, alignment: .center)
            
            VStack(alignment: .leading) {
                Text(account.name)
                    .font(.body)
                Text("\(account.currency) • \(account.accountTypeRaw)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            CacheToggleButton(model: account) { acc in
                onCacheToggle(acc)
            }
            SyncStatusIndicator(status: account.syncStatus)
        }
        .foregroundStyle(.primary)
    }
}
