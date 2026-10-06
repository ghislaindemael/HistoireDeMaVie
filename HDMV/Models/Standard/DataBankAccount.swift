//
//  DataBankAccount.swift
//  HDMV
//
//  Created by Ghislain Demael on 06.10.2026.
//

import Foundation
import SwiftData

@Model
final class DataBankAccount: CatalogueModel {
    
    @Attribute(.unique) var rid: Int?
    var name: String
    var currency: String
    var institution: String?
    
    // e.g. "checking", "savings", "credit_card", "cash"
    var accountTypeRaw: String
    
    var archived: Bool = false
    var cache: Bool = false
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = DataBankAccountDTO
    typealias Payload = DataBankAccountPayload
    typealias Editor = DataBankAccountEditor
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.sourceAccount)
    var outgoingTransactions: [Transaction] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.targetAccount)
    var incomingTransactions: [Transaction] = []
    
    // MARK: - Init
    
    init(
        rid: Int? = nil,
        name: String = "",
        currency: String = "",
        institution: String? = nil,
        accountTypeRaw: String = "checking",
        archived: Bool = false,
        cache: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.currency = currency
        self.institution = institution
        self.accountTypeRaw = accountTypeRaw
        self.archived = archived
        self.cache = cache
        self.syncStatusRaw = syncStatus.rawValue
    }
    
    convenience init(fromDto dto: DataBankAccountDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        self.currency = dto.currency
        self.institution = dto.institution
        self.accountTypeRaw = dto.type
        self.archived = dto.is_archived
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func update(fromDto dto: DataBankAccountDTO) {
        self.name = dto.name
        self.currency = dto.currency
        self.institution = dto.institution
        self.accountTypeRaw = dto.type
        self.archived = dto.is_archived
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        return !name.isEmpty && !currency.isEmpty
    }
}

struct DataBankAccountDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let currency: String
    let institution: String?
    let type: String
    let is_archived: Bool
}

struct DataBankAccountPayload: Codable, InitializableWithModel {
    typealias Model = DataBankAccount
    
    let name: String
    let currency: String
    let institution: String?
    let type: String
    let is_archived: Bool
    
    init?(from model: DataBankAccount) {
        guard model.isValid() else { return nil }
        self.name = model.name
        self.currency = model.currency
        self.institution = model.institution
        self.type = model.accountTypeRaw
        self.is_archived = model.archived
    }
}

struct DataBankAccountEditor: EditorProtocol, CachableModel {
    var name: String?
    var currency: String?
    var institution: String?
    var accountTypeRaw: String?
    var archived: Bool
    var cache: Bool
    
    init(from bankAccount: DataBankAccount) {
        self.name = bankAccount.name
        self.currency = bankAccount.currency
        self.institution = bankAccount.institution
        self.accountTypeRaw = bankAccount.accountTypeRaw
        self.archived = bankAccount.archived
        self.cache = bankAccount.cache
    }
    
    func apply(to bankAccount: DataBankAccount) {
        if let name = self.name { bankAccount.name = name }
        if let currency = self.currency { bankAccount.currency = currency }
        if let institution = self.institution { bankAccount.institution = institution }
        if let accountTypeRaw = self.accountTypeRaw { bankAccount.accountTypeRaw = accountTypeRaw }
        bankAccount.archived = self.archived
        bankAccount.cache = self.cache
    }
}
