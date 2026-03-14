//
//  Transaction.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.02.2026.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Transaction: LogModel {
    
    @Attribute(.unique) var rid: Int?
    var timeStart: Date
    var timeEnd: Date?
    var executionDate: Date?
    
    var amount: Decimal?
    var realAmount: Decimal?
    var currency: String?
    var myCost: Decimal?
    
    var bankAmount: Decimal?
    var bankCurrency: String?
    
    var isCash: Bool = false
    
    var typeRid: Int?
    var parentInstanceRid: Int?
    var payerRid: Int?
    var contextRid: Int?
    
    var details: String?
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = TransactionDTO
    typealias Payload = TransactionPayload
    typealias Editor = TransactionEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var parentInstance: ActivityInstance?
    
    @Relationship(deleteRule: .nullify)
    var payer: Person?
    
    @Relationship(deleteRule: .nullify)
    var type: TransactionType?
    
    // MARK: Init
    
    init(
        rid: Int? = nil,
        timeStart: Date = .now,
        timeEnd: Date? = nil,
        executionDate: Date? = nil,
        amount: Decimal? = nil,
        realAmount: Decimal? = nil,
        currency: String? = nil,
        myCost: Decimal? = nil,
        bankAmount: Decimal? = nil,
        bankCurrency: String? = nil,
        isCash: Bool = false,
        typeRid: Int? = nil,
        parentInstanceRid: Int? = nil,
        payerRid: Int? = nil,
        contextRid: Int? = nil,
        details: String? = nil,
        syncStatus: SyncStatus = SyncStatus.local,
        parentInstance: ActivityInstance? = nil,
        payer: Person? = nil,
        type: TransactionType? = nil
    ){
        self.rid = rid
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.executionDate = executionDate
        self.amount = amount
        self.realAmount = realAmount
        self.currency = currency
        self.myCost = myCost
        self.bankAmount = bankAmount
        self.bankCurrency = bankCurrency
        self.isCash = isCash
        self.typeRid = typeRid
        self.parentInstanceRid = parentInstanceRid
        self.payerRid = payerRid
        self.contextRid = contextRid
        self.details = details
        self.syncStatusRaw = syncStatusRaw
        self.parentInstance = parentInstance
        self.payer = payer
        self.type = type
    }
    
    convenience init(fromDto dto: TransactionDTO) {
        self.init()
        self.rid = dto.id
        self.timeStart = dto.time_start
        self.executionDate = dto.execution_date
        self.amount = dto.amount
        self.realAmount = dto.real_amount
        self.currency = dto.currency
        self.myCost = dto.my_cost
        self.bankAmount = dto.bank_amount
        self.bankCurrency = dto.bank_currency
        self.isCash = dto.is_cash
        self.typeRid = dto.type_id
        self.parentInstanceRid = dto.parent_instance_id
        self.payerRid = dto.payer_id
        self.contextRid = dto.context_id
        self.details = dto.details
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func update(fromDto dto: TransactionDTO) {
        self.timeStart = dto.time_start
        self.executionDate = dto.execution_date
        self.amount = dto.amount
        self.realAmount = dto.real_amount
        self.currency = dto.currency
        self.myCost = dto.my_cost
        self.bankAmount = dto.bank_amount
        self.bankCurrency = dto.bank_currency
        self.isCash = dto.is_cash
        self.typeRid = dto.type_id
        self.parentInstanceRid = dto.parent_instance_id
        self.payerRid = dto.payer_id
        self.contextRid = dto.context_id
        self.details = dto.details
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        return amount != nil && currency != nil
    }
}

struct TransactionDTO: Codable, Identifiable {
    let id: Int
    let time_start: Date
    let execution_date: Date?
    
    let amount: Decimal?
    let real_amount: Decimal?
    let currency: String?
    let my_cost: Decimal?
    
    let bank_amount: Decimal?
    let bank_currency: String?
    
    let is_cash: Bool
    
    let type_id: Int?
    let parent_instance_id: Int?
    let payer_id: Int?
    let context_id: Int?
    
    let details: String?
}

struct TransactionPayload: Codable, InitializableWithModel {
    
    typealias Model = Transaction
    
    let time_start: Date
    let execution_date: Date?
    
    let amount: Decimal?
    let real_amount: Decimal?
    let currency: String?
    let my_cost: Decimal?
    
    let bank_amount: Decimal?
    let bank_currency: String?
    
    let is_cash: Bool
    
    let type_id: Int?
    let parent_instance_id: Int?
    let payer_id: Int?
    let context_id: Int?
    
    let details: String?
    
    init?(from transaction: Transaction) {
        guard transaction.isValid() else {
            print("-> Transaction \(transaction.rid ?? -1) is invalid.")
            return nil
        }
        
        self.time_start = transaction.timeStart
        self.execution_date = transaction.executionDate
        
        self.amount = transaction.amount
        self.real_amount = transaction.realAmount
        self.currency = transaction.currency
        self.my_cost = transaction.myCost
        
        self.bank_amount = transaction.bankAmount
        self.bank_currency = transaction.bankCurrency
        
        self.is_cash = transaction.isCash
        
        self.type_id = transaction.typeRid
        self.parent_instance_id = transaction.parentInstanceRid
        self.payer_id = transaction.payerRid
        self.context_id = transaction.contextRid
        
        self.details = transaction.details
    }
}


struct TransactionEditor: EditorProtocol {
    
    var timeStart: Date
    var timeEnd: Date?
    var executionDate: Date?
    
    var amount: Decimal?
    var realAmount: Decimal?
    var currency: String?
    var myCost: Decimal?
    
    var bankAmount: Decimal?
    var bankCurrency: String?
    
    var isCash: Bool
    
    var type: TransactionType?
    var parentInstance: ActivityInstance?
    var payer: Person?
    
    // Helper RIDs for saving
    var typeRid: Int?
    var parentInstanceRid: Int?
    var payerRid: Int?
    var contextRid: Int?
    
    var details: String?
    
    typealias Model = Transaction
    
    init(from transaction: Transaction) {
        self.timeStart = transaction.timeStart
        self.timeEnd = transaction.timeEnd
        self.executionDate = transaction.executionDate
        
        self.amount = transaction.amount
        self.realAmount = transaction.realAmount
        self.currency = transaction.currency
        self.myCost = transaction.myCost
        
        self.bankAmount = transaction.bankAmount
        self.bankCurrency = transaction.bankCurrency
        
        self.isCash = transaction.isCash
        
        // Relationships
        self.type = transaction.type
        self.typeRid = transaction.typeRid
        
        self.parentInstance = transaction.parentInstance
        self.parentInstanceRid = transaction.parentInstanceRid
        
        self.payer = transaction.payer
        self.payerRid = transaction.payerRid
        
        self.contextRid = transaction.contextRid
        
        self.details = transaction.details
    }
    
    func apply(to transaction: Transaction) {
        transaction.timeStart = self.timeStart
        transaction.timeEnd = self.timeEnd
        transaction.executionDate = self.executionDate
        
        transaction.amount = self.amount
        transaction.realAmount = self.realAmount
        transaction.currency = self.currency
        transaction.myCost = self.myCost
        
        transaction.bankAmount = self.bankAmount
        transaction.bankCurrency = self.bankCurrency
        
        transaction.isCash = self.isCash
        
        // Apply relationships (Object + RID)
        transaction.type = self.type
        transaction.typeRid = self.type?.rid ?? self.typeRid
        
        transaction.parentInstance = self.parentInstance
        transaction.parentInstanceRid = self.parentInstance?.rid ?? self.parentInstanceRid
        
        transaction.payer = self.payer
        transaction.payerRid = self.payer?.rid ?? self.payerRid
        
        transaction.contextRid = self.contextRid
        
        transaction.details = self.details
    }
}
