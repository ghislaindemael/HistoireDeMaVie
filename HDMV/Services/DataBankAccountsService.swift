import Foundation

final class DataBankAccountsService: SupabaseDataService<DataBankAccountDTO, DataBankAccountPayload> {
    
    init() {
        super.init(tableName: "data_bank_accounts")
    }
    
    // MARK: Semantic methods
    
    func fetchBankAccounts(includeArchived: Bool = false) async throws -> [DataBankAccountDTO] {
        try await fetch(includeArchived: includeArchived)
    }
    
    func createBankAccount(payload: DataBankAccountPayload) async throws -> DataBankAccountDTO {
        try await create(payload: payload)
    }
    
    func updateBankAccount(rid: Int, payload: DataBankAccountPayload) async throws -> DataBankAccountDTO {
        try await update(rid: rid, payload: payload)
    }
    
    func deleteBankAccount(id: Int) async throws -> Bool {
        try await delete(rid: id)
    }
}
