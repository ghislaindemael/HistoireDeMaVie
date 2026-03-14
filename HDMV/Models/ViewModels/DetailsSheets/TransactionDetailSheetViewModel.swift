//
//  TransactionDetailSheetViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.02.2026.
//

import SwiftUI
import SwiftData

@MainActor
class TransactionDetailSheetViewModel: BaseDetailSheetViewModel<Transaction, TransactionEditor> {
    
    @Published var availablePeople: [Person] = []
    
    override init(model: Transaction, modelContext: ModelContext) {
        super.init(model: model, modelContext: modelContext)
        fetchPeople()
    }
    
    private func fetchPeople() {
        let descriptor = FetchDescriptor<Person>(sortBy: [SortDescriptor(\.name)])
        self.availablePeople = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - Smart Logic
    
    /// Auto-calculates "My Cost" based on split logic if the user hasn't manually overridden it.
    func applySplitLogic(isEqualSplit: Bool, numberOfPeople: Int) {
        guard let total = editor.amount, numberOfPeople > 0 else { return }
        
        if isEqualSplit {
            editor.myCost = total / Decimal(numberOfPeople)
        } else {
            // Complex logic: handled manually by user inputting 'myCost'
        }
    }
    
    /// Toggles the 'Payer' logic
    func setPayer(person: Person?) {
        editor.payer = person
        editor.payerRid = person?.rid
    }
}
