import SwiftUI
import SwiftData

struct ClaimTransactionsSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var unclaimedTransactions: [Transaction]
    
    let parent: any ParentModel
    
    init(parent: any ParentModel) {
        self.parent = parent
        
        let targetDate = parent.timeStart
        let startWindow = targetDate.addingTimeInterval(-12 * 3600)
        let endWindow = parent.timeEnd?.addingTimeInterval(12 * 3600) ?? targetDate.addingTimeInterval(12 * 3600)
        
        let predicate = #Predicate<Transaction> { t in
            t.parentInstanceRid == nil &&
            t.parentTripRid == nil &&
            t.timeStart >= startWindow &&
            t.timeStart <= endWindow
        }
        _unclaimedTransactions = Query(filter: predicate, sort: \.timeStart)
    }
    
    private var filteredTransactions: [Transaction] {
        unclaimedTransactions.filter { $0.parentInstance == nil && $0.parentTrip == nil }
    }
    
    private func claim(transaction: Transaction) {
        var t = transaction
        t.setParent(parent)
        t.markAsModified()
    }
    
    var body: some View {
        let displayTransactions = filteredTransactions
        Section("Claim Transactions") {
            if displayTransactions.isEmpty {
                Text("No unclaimed transactions nearby")
                    .foregroundColor(.secondary)
            } else {
                ForEach(displayTransactions) { transaction in
                    Button(action: {
                        withAnimation {
                            claim(transaction: transaction)
                        }
                    }) {
                        HStack {
                            TransactionRowView(transaction: transaction)
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
    }
}
