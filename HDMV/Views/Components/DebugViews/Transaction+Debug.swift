import SwiftUI

extension Transaction: DebugViewable {
    var debugView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // MARK: - Identity & Sync
            HStack {
                if let rid = rid {
                    Text("Remote ID: \(rid)")
                } else {
                    Text("Unsynced")
                        .bold()
                        .foregroundStyle(.orange)
                }
                Spacer()
                SyncStatusIndicator(status: syncStatus)
            }
            
            // MARK: - Dates
            Text("Start: \(timeStart.formatted(date: .abbreviated, time: .shortened))")
            
            if let timeEnd {
                Text("End: \(timeEnd.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("End: In Progress")
            }
            
            if let executionDate {
                Text("Exec: \(executionDate.formatted(date: .abbreviated, time: .shortened))")
            }
            
            Divider()
            
            // MARK: - Financials
            if let amount, let currency {
                Text("Amount: \(amount.formatted()) \(currency)")
            } else {
                Text("Amount/Currency: Unset")
                    .bold()
                    .foregroundStyle(.red)
            }
            
            if let realAmount {
                Text("Real Amount: \(realAmount.formatted())")
            }
            
            if let myCost {
                Text("My Cost: \(myCost.formatted())")
            }
            
            if let bankAmount, let bankCurrency {
                Text("Bank Amount: \(bankAmount.formatted()) \(bankCurrency)")
            }
            
            Text("Is Cash: \(isCash ? "Yes" : "No")")
            
            Divider()
            
            // MARK: - Relationships
            if let typeRid {
                Text("Type RID: \(typeRid) (\(type != nil ? "✅ Loaded" : "❌ Missing"))")
            } else {
                Text("Type RID: Unset")
                    .bold()
                    .foregroundStyle(.red)
            }
            
            if let payerRid {
                Text("Payer RID: \(payerRid) (\(payer != nil ? "✅ Loaded" : "❌ Missing"))")
            } else {
                Text("Payer RID: Unset")
                    .foregroundStyle(.orange)
            }
            
            if let parentInstanceRid {
                Text("Parent Instance RID: \(parentInstanceRid) (\(parentInstance != nil ? "✅ Loaded" : "❌ Missing"))")
            } else {
                Text("Parent Instance RID: Unset")
                    .foregroundStyle(.secondary)
            }
            
            if let contextRid {
                Text("Context RID: \(contextRid)")
            } else {
                Text("Context RID: Unset")
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // MARK: - Details
            Text("Details: \(details ?? "N/A")")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
