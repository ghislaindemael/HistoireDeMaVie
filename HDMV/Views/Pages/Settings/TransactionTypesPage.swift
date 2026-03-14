//
//  TransactionTypesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//


import SwiftUI

struct TransactionTypesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TransactionTypesPageViewModel()
    @State private var typeToEdit: TransactionType?
    
    var body: some View {
        NavigationStack {
            List {
                OutlineGroup(viewModel.transactionTypes, children: \.optionalChildren) { type in
                    Button(action: {
                        typeToEdit = type
                    }) {
                        TransactionTypeRowView(type: type) { t in
                            withAnimation(.snappy) {
                                viewModel.updateModel(t) { concreteType in
                                    concreteType.cache.toggle()
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Transaction Types")
            .simpleLogToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: { viewModel.createTransactionType() }
            )
            .sheet(item: $typeToEdit) { type in
                TransactionTypeDetailSheet(type: type, modelContext: modelContext)
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .syncingOverlay(viewModel.isLoading)
        }
    }
}
