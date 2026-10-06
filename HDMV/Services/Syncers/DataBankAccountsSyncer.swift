import Foundation
import SwiftData

@MainActor
final class DataBankAccountsSyncer: BaseSyncer<DataBankAccount, DataBankAccountDTO, DataBankAccountPayload> {
    
    private let service = DataBankAccountsService()
    private let settings: SettingsStore = SettingsStore.shared
        
    override func fetchRemoteModels(date: Date?) async throws -> [DataBankAccountDTO] {
        return try await service.fetchBankAccounts(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: DataBankAccountPayload) async throws -> DataBankAccountDTO {
        return try await service.createBankAccount(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: DataBankAccountPayload) async throws -> DataBankAccountDTO {
        return try await service.updateBankAccount(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("DataBankAccount deletion not implemented")
    }
    
    override func resolveRelationships() throws {
        // No relationships to resolve for Bank Accounts
    }
}
