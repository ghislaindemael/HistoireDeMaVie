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
            CatalogueRowControlsView(model: account, onToggle: onCacheToggle)
        }
        .foregroundStyle(.primary)
    }
}
