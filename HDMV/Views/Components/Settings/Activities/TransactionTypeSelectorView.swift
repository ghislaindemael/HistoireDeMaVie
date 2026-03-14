//
//  TransactionTypeSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2025.
//

import SwiftUI
import SwiftData

struct TransactionTypeSelectorView: View {
    @Binding var selectedType: TransactionType?
    @Query var typesTree: [TransactionType]
    
    init(selectedType: Binding<TransactionType?>) {
        _selectedType = selectedType
        let predicate = #Predicate<TransactionType> { $0.parentRid == nil && $0.cache == true }
        _typesTree = Query(filter: predicate, sort: \.name)
    }
    
    var body: some View {
        GenericTreeSelectorView(
            items: typesTree,
            childrenKeyPath: \.cachedOptionalChildren,
            selection: $selectedType,
            title: "Select a Transaction Type",
            noneButtonText: "None"
        )
    }
}

struct ParentTransactionTypeSelector: View {
    let types: [TransactionType]
    @Binding var selectedParent: TransactionType?
    
    var body: some View {
        GenericTreeSelectorView(
            items: types,
            childrenKeyPath: \.cachedOptionalChildren,
            selection: $selectedParent,
            title: "Select Parent",
            noneButtonText: "Top Level (No Parent)"
        )
    }
}
