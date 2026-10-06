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
    
    override init(model: Transaction, modelContext: ModelContext) {
        super.init(model: model, modelContext: modelContext)
    }
    
}
