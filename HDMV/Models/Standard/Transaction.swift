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
    
    // MARK: - Semantic Helpers
    @Transient var transactionTime: Date {
        get { timeStart }
        set { timeStart = newValue }
    }
    
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
        syncStatus: SyncStatus = SyncStatus.unsynced,
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
        self.syncStatus = syncStatus
        self.parentInstance = parentInstance
        self.payer = payer
        self.type = type
    }
    
    convenience init(fromDto dto: TransactionDTO) {
        self.init()
        self.rid = dto.id
        self.timeStart = dto.time
        self.executionDate = dto.execution_time
        self.amount = dto.amount
        self.realAmount = dto.real_amount
        self.currency = dto.currency
        self.myCost = dto.my_cost
        self.bankAmount = dto.bank_amount
        self.bankCurrency = dto.bank_currency
        self.isCash = dto.cash
        self.typeRid = dto.type_id
        self.parentInstanceRid = dto.parent_instance_id
        self.payerRid = dto.payer_id
        self.contextRid = nil
        self.details = dto.details
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func update(fromDto dto: TransactionDTO) {
        self.timeStart = dto.time
        self.executionDate = dto.execution_time
        self.amount = dto.amount
        self.realAmount = dto.real_amount
        self.currency = dto.currency
        self.myCost = dto.my_cost
        self.bankAmount = dto.bank_amount
        self.bankCurrency = dto.bank_currency
        self.isCash = dto.cash
        self.typeRid = dto.type_id
        self.parentInstanceRid = dto.parent_instance_id
        self.payerRid = dto.payer_id
        self.contextRid = nil
        self.details = dto.details
        self.syncStatusRaw = SyncStatus.synced.rawValue
    }
    
    func isValid() -> Bool {
        return amount != nil && currency != nil
    }
}

struct TransactionDTO: Codable, Identifiable {
    let id: Int
    
    let time: Date
    let execution_time: Date?
    
    let amount: Decimal?
    let real_amount: Decimal?
    let currency: String?
    let my_cost: Decimal?
    
    let bank_amount: Decimal?
    let bank_currency: String?
    
    let cash: Bool
    
    let type_id: Int?
    let parent_instance_id: Int?
    let payer_id: Int?
        
    let details: String?
}

struct TransactionPayload: Codable, InitializableWithModel {
    typealias Model = Transaction
    
    let time: Date
    let execution_time: Date?
    
    let amount: Decimal?
    let real_amount: Decimal?
    let currency: String?
    let my_cost: Decimal?
    
    let bank_amount: Decimal?
    let bank_currency: String?
    
    let cash: Bool
    
    let type_id: Int?
    let parent_instance_id: Int?
    let payer_id: Int?
    
    let details: String?
    
    init?(from transaction: Transaction) {
        guard transaction.isValid() else {
            print("-> Transaction \(transaction.rid ?? -1) is invalid.")
            return nil
        }
        
        self.time = transaction.timeStart
        self.execution_time = transaction.executionDate
        
        self.amount = transaction.amount
        self.real_amount = transaction.realAmount
        self.currency = transaction.currency
        self.my_cost = transaction.myCost
        
        self.bank_amount = transaction.bankAmount
        self.bank_currency = transaction.bankCurrency
        
        self.cash = transaction.isCash
        
        self.type_id = transaction.typeRid
        self.parent_instance_id = transaction.parentInstanceRid
        self.payer_id = transaction.payerRid
        
        self.details = transaction.details
    }
}


struct TransactionEditor: EditorProtocol {
    
    var timeStart: Date
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
    
    var typeRid: Int?
    var parentInstanceRid: Int?
    var payerRid: Int?
    var contextRid: Int?
    
    var details: String?
    
    var isIncome: Bool = false
    
    typealias Model = Transaction
    
    init(from transaction: Transaction) {
        self.timeStart = transaction.transactionTime
        self.executionDate = transaction.executionDate
        
        self.isIncome = (transaction.amount ?? -1) > 0

        self.amount = transaction.amount.map { abs($0) }
        self.myCost = transaction.myCost.map { abs($0) }
        self.realAmount = transaction.realAmount.map { abs($0) }
        self.bankAmount = transaction.bankAmount.map { abs($0) }
        self.currency = transaction.currency ?? "CHF"
        self.bankCurrency = transaction.bankCurrency ?? "CHF"
        
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
    
    func applySign(to value: Decimal?) -> Decimal? {
        guard let rawValue = value else { return nil }
        let absoluteValue = abs(rawValue)
        return self.isIncome ? absoluteValue : -absoluteValue
    }
    
    func apply(to transaction: Transaction) {
        transaction.timeStart = self.timeStart
        transaction.executionDate = self.executionDate
        
        transaction.amount = applySign(to: self.amount)
        transaction.realAmount = applySign(to: self.realAmount)
        transaction.myCost = applySign(to: self.myCost)
        transaction.bankAmount = applySign(to: self.bankAmount)
        
        transaction.currency = self.currency
        transaction.bankCurrency = self.bankCurrency
        
        transaction.isCash = self.isCash
        
        transaction.type = self.type
        transaction.typeRid = self.type?.rid ?? self.typeRid
        
        transaction.parentInstance = self.parentInstance
        transaction.parentInstanceRid = self.parentInstance?.rid ?? self.parentInstanceRid
        
        transaction.payer = self.payer
        transaction.payerRid = self.payer?.rid ?? self.payerRid
        
        transaction.contextRid = self.contextRid
        
        transaction.details = self.details
    }
    
    // MARK: - Semantic Helpers
    @Transient var transactionTime: Date {
        get { timeStart }
        set { timeStart = newValue }
    }
}
