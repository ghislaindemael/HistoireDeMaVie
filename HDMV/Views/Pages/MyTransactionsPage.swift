//
//  MyTransactionsPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//


import SwiftUI
import SwiftData

struct MyTransactionsPage: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject private var settings: SettingsStore
    
    @StateObject private var viewModel = MyTransactionsPageViewModel()
    @State private var transactionToEdit: Transaction? = nil
    
    // MARK: Setup
    private func onAppear() {
        if let navDate = appNavigator.selectedDate {
            viewModel.filterDate = navDate
            if settings.appMode == .live {
                appNavigator.selectedDate = nil
            }
        }
        viewModel.setup(modelContext: modelContext)
        viewModel.fetchTransactions()
    }
    
    var body: some View {
        NavigationStack {
            mainListView
                .navigationTitle("Finances")
                .onAppear(perform: onAppear)
                .syncingOverlay(viewModel.isLoading)
                .logPageToolbar(
                    refreshAction: { await viewModel.refreshFromServer() },
                    syncAction: { await viewModel.uploadLocalChanges() },
                    onAdd: { viewModel.createTransaction() },
                    trailingOptions: {
                        Section("Advanced") {
                            Button(action: { print("Import Bank CSV") }) {
                                Label("Import Bank Data", systemImage: "arrow.down.doc.fill")
                            }
                        }
                    }
                )
                .onChange(of: viewModel.filterMode) { viewModel.fetchTransactions() }
                .onChange(of: viewModel.filterDate) {
                    viewModel.fetchTransactions()
                    appNavigator.selectedDate = viewModel.filterDate
                }
                .sheet(item: $transactionToEdit) { transaction in
                    TransactionDetailSheet(
                        transaction: transaction,
                        modelContext: modelContext
                    )
                }
        }
        .environmentObject(viewModel)
    }
    
    // MARK: - View Components
    private var mainListView: some View {
        VStack(spacing: 12) {
            GenericFilterControlView(
                filterMode: $viewModel.filterMode,
                filterDate: $viewModel.filterDate,
                filterStartDate: $viewModel.filterStartDate,
                filterEndDate: $viewModel.filterEndDate,
                advancedFilterLabel: "Type"
            ) {
                NavigationLink {
                    TransactionTypeSelectorView(selectedType: $viewModel.filterTransactionType)
                } label: {
                    Text(viewModel.filterTransactionType?.name ?? "Select one")
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.transactions) { transaction in
                        TransactionRowView(transaction: transaction)
                            .onTapGesture {
                                transactionToEdit = transaction
                            }
                    }
                }
                .padding(.horizontal)
            }
            .id(viewModel.scrollResetID)
        }
    }
}
