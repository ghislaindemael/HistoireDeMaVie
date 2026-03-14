import Foundation
import SwiftUI
import SwiftData

@MainActor
class MyTransactionsPageViewModel: ObservableObject {
    
    enum FilterMode: Hashable {
        case byDate
        case byType
    }
    
    private var modelContext: ModelContext?
    private var transactionSyncer: BaseSyncer<Transaction, TransactionDTO, TransactionPayload>?
    private var settings: SettingsStore = SettingsStore.shared
    
    @Published var isLoading: Bool = false
    
    @Published var filterMode: FilterMode = .byDate
    @Published var filterDate: Date = .now
    
    @Published var transactions: [Transaction] = []
    
    var hasLocalChanges: Bool {
        transactions.contains { $0.syncStatus != .synced }
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Assuming you have or will create a TransactionSyncer subclass
        self.transactionSyncer = TransactionSyncer(modelContext: modelContext)
    }
    
    // MARK: - Data Fetching
    
    func fetchTransactions() {
        guard let context = modelContext else { return }
        
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: filterDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            let future = Date.distantFuture
            
            let predicate = #Predicate<Transaction> {
                $0.timeStart >= startOfDay && $0.timeStart < endOfDay
            }
            
            let descriptor = FetchDescriptor<Transaction>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
            )
            
            self.transactions = try context.fetch(descriptor)
        } catch {
            print("Error during transaction fetch: \(error)")
            self.transactions = []
        }
    }
    
    // MARK: - Core Synchronization Logic
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await transactionSyncer?.pullChanges(date: filterDate)
        } catch {
            print("Failed to sync transactions: \(error)")
        }
        fetchTransactions()
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await transactionSyncer?.pushChanges()
        } catch {
            print("Transaction changes upload failed: \(error)")
        }
        fetchTransactions()
    }
    
    // MARK: User Actions
    
    func createTransaction(date: Date? = nil) {
        guard let context = modelContext else { return }
        let creationDate = (date ?? filterDate).smartCreationTime
        
        let newTransaction = Transaction(
            timeStart: creationDate,
            syncStatus: .unsynced
        )
        
        context.insert(newTransaction)
        do {
            try context.save()
            self.transactions.insert(newTransaction, at: 0)
            self.transactions.sort { $0.timeStart > $1.timeStart }
        } catch {
            print("Failed to create transaction: \(error)")
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        guard let context = modelContext else { return }
        
        if transaction.rid == nil {
            context.delete(transaction)
        } else {
            transaction.syncStatus = .toDelete
        }
        try? context.save()
        fetchTransactions()
    }
}

