import Foundation
import SwiftUI
import SwiftData

@MainActor
class MyTransactionsPageViewModel: ObservableObject {
    

    
    private var modelContext: ModelContext?
    private var masterSyncer: MasterSyncer?
    private var settings: SettingsStore = SettingsStore.shared
    
    @Published var isLoading: Bool = false
    
    @Published var filterMode: TimelineFilterMode = .daily {
        didSet { scrollResetID = UUID() }
    }
    @Published var filterDate: Date = .now {
        didSet { scrollResetID = UUID() }
    }
    
    @Published var filterStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now {
        didSet { scrollResetID = UUID(); fetchTransactions() }
    }
    @Published var filterEndDate: Date = .now {
        didSet { scrollResetID = UUID(); fetchTransactions() }
    }
    @Published var filterTransactionType: TransactionType? {
        didSet { scrollResetID = UUID(); fetchTransactions() }
    }
    
    @Published var scrollResetID = UUID()
    
    @Published var transactions: [Transaction] = []
    
    var hasLocalChanges: Bool {
        transactions.contains { $0.syncStatus != .synced }
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.masterSyncer = MasterSyncer(modelContext: modelContext)
    }
    
    // MARK: - Data Fetching
    
    func fetchTransactions() {
        guard let context = modelContext else { return }
        
        do {
            if filterMode == .daily {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: filterDate)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
                
                let predicate = #Predicate<Transaction> {
                    $0.timeStart >= startOfDay && $0.timeStart < endOfDay
                }
                
                let descriptor = FetchDescriptor<Transaction>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
                )
                
                self.transactions = try context.fetch(descriptor)
            } else {
                let startOfDay = Calendar.current.startOfDay(for: filterStartDate)
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: filterEndDate)) ?? .now
                
                let typeId = filterTransactionType?.rid
                
                // SwiftData predicate workaround: optional bindings or compound filters can be tricky.
                let predicate = #Predicate<Transaction> {
                    $0.timeStart >= startOfDay && $0.timeStart < endOfDay
                }
                
                let descriptor = FetchDescriptor<Transaction>(
                    predicate: predicate,
                    sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
                )
                
                var fetched = try context.fetch(descriptor)
                
                if let typeId = typeId {
                    fetched = fetched.filter { $0.typeRid == typeId }
                }
                
                self.transactions = fetched
            }
        } catch {
            print("Error during transaction fetch: \(error)")
            self.transactions = []
        }
    }
    
    // MARK: - Core Synchronization Logic
    
    func refreshFromServer() async {
        isLoading = true
        defer { isLoading = false }
        await masterSyncer?.sync(
            filterMode: self.filterMode,
            date: self.filterDate,
            transactionTypeRid: self.filterTransactionType?.rid,
            startDate: self.filterStartDate,
            endDate: self.filterEndDate
        )
        fetchTransactions()
    }
    
    func uploadLocalChanges() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await masterSyncer?.pushChanges()
        } catch {
            print("Transaction changes upload failed: \(error)")
        }
        fetchTransactions()
    }
    
    // MARK: User Actions
    
    func createTransaction(date: Date? = nil) {
        guard let context = modelContext else { return }
        let creationDate = (date ?? filterDate).smartCreationTime
        updateFilterDateIfNeeded(for: creationDate)
        
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
    
    private func updateFilterDateIfNeeded(for smartDate: Date) {
        let calendar = Calendar.current
        if calendar.isDateInToday(smartDate) && !calendar.isDateInToday(filterDate) {
            filterDate = .now
        }
    }
}

