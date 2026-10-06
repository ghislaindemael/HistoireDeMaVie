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
    
    var amount: Double?
    var realAmount: Double?
    var currency: String?
    var myCost: Double?
    
    var bankAmount: Double?
    var bankCurrency: String?
    
    var typeRid: Int?
    var parentTripRid: Int?
    var parentInstanceRid: Int?
    var payerRid: Int?
    var sourceAccountRid: Int?
    var targetAccountRid: Int?
    var contextRids: [Int] = []
    
    var details: String?
    var log_details: Data?
    
    var decodedLogDetails: LogDetails? {
        get {
            guard let data = log_details else { return nil }
            return try? JSONDecoder().decode(LogDetails.self, from: data)
        }
        set {
            log_details = try? JSONEncoder().encode(newValue)
        }
    }
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = TransactionDTO
    typealias Payload = TransactionPayload
    typealias Editor = TransactionEditor
    
    // MARK: - Semantic Helpers
    @Transient var transactionTime: Date {
        get { timeStart }
        set { timeStart = newValue }
    }
    
    var resolvedOptionsPills: [ActivityOptionPill] {
        guard let transactionType = self.type,
              let mappedOptions = decodedLogDetails?.options,
              !mappedOptions.isEmpty else {
            return []
        }
        
        let sortedMappings = transactionType.optionMappings.sorted { $0.priority < $1.priority }
        var pills: [ActivityOptionPill] = []
        
        for mapping in sortedMappings {
            guard let option = mapping.option else { continue }
            guard let selectedValueSlug = mappedOptions[option.slug] else { continue }
            
            let config = option.config
            pills.append(ActivityOptionPill(
                optionSlug: option.slug,
                label: option.name,
                value: config.getChoice(for: selectedValueSlug)?.label ?? selectedValueSlug,
                type: option.type,
                replacesActivityName: false
            ))
        }
        
        return pills
    }
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var parentInstance: ActivityInstance?
    
    @Relationship(deleteRule: .nullify)
    var parentTrip: Trip?
    
    @Relationship(deleteRule: .nullify)
    var payer: Person?
    
    @Relationship(deleteRule: .nullify)
    var type: TransactionType?
    
    @Relationship(deleteRule: .nullify)
    var sourceAccount: DataBankAccount?
    
    @Relationship(deleteRule: .nullify)
    var targetAccount: DataBankAccount?
    
    // MARK: Init
    
    init(
        rid: Int? = nil,
        timeStart: Date = .now,
        timeEnd: Date? = nil,
        executionDate: Date? = nil,
        amount: Double? = nil,
        realAmount: Double? = nil,
        currency: String? = nil,
        myCost: Double? = nil,
        bankAmount: Double? = nil,
        bankCurrency: String? = nil,
        typeRid: Int? = nil,
        parentInstanceRid: Int? = nil,
        parentTripRid: Int? = nil,
        payerRid: Int? = nil,
        sourceAccountRid: Int? = nil,
        targetAccountRid: Int? = nil,
        contextRids: [Int] = [],
        details: String? = nil,
        syncStatus: SyncStatus = SyncStatus.unsynced,
        parentInstance: ActivityInstance? = nil,
        parentTrip: Trip? = nil,
        payer: Person? = nil,
        type: TransactionType? = nil,
        sourceAccount: DataBankAccount? = nil,
        targetAccount: DataBankAccount? = nil
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
        self.typeRid = typeRid
        self.parentInstanceRid = parentInstanceRid
        self.parentTripRid = parentTripRid
        self.payerRid = payerRid
        self.sourceAccountRid = sourceAccountRid
        self.targetAccountRid = targetAccountRid
        self.contextRids = contextRids
        self.details = details
        self.syncStatus = syncStatus
        self.parentInstance = parentInstance
        self.parentTrip = parentTrip
        self.payer = payer
        self.type = type
        self.sourceAccount = sourceAccount
        self.targetAccount = targetAccount
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
        self.typeRid = dto.type_id
        self.parentInstanceRid = dto.parent_instance_id
        self.parentTripRid = dto.parent_trip_id
        self.payerRid = dto.payer_id
        self.sourceAccountRid = dto.source_account_id
        self.targetAccountRid = dto.target_account_id
        self.contextRids = dto.context_ids ?? []
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
        self.typeRid = dto.type_id
        self.parentInstanceRid = dto.parent_instance_id
        self.parentTripRid = dto.parent_trip_id
        self.payerRid = dto.payer_id
        self.sourceAccountRid = dto.source_account_id
        self.targetAccountRid = dto.target_account_id
        self.contextRids = dto.context_ids ?? []
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
    
    let amount: Double?
    let real_amount: Double?
    let currency: String?
    let my_cost: Double?
    
    let bank_amount: Double?
    let bank_currency: String?
    
    let type_id: Int?
    let parent_instance_id: Int?
    let parent_trip_id: Int?
    let payer_id: Int?
    let source_account_id: Int?
    let target_account_id: Int?
    let context_ids: [Int]?
        
    let details: String?
    let log_details: LogDetails?
}

struct TransactionPayload: Codable, InitializableWithModel {
    typealias Model = Transaction
    
    let time: Date
    let execution_time: Date?
    
    let amount: Double?
    let real_amount: Double?
    let currency: String?
    let my_cost: Double?
    
    let bank_amount: Double?
    let bank_currency: String?
    
    let type_id: Int?
    @ExplicitNull var parent_instance_id: Int?
    @ExplicitNull var parent_trip_id: Int?
    let payer_id: Int?
    let source_account_id: Int?
    let target_account_id: Int?
    let context_ids: [Int]
    
    let details: String?
    let log_details: LogDetails?
    
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
        
        self.type_id = transaction.typeRid
        self.parent_instance_id = transaction.parentInstanceRid
        self.parent_trip_id = transaction.parentTripRid
        self.payer_id = transaction.payerRid
        self.source_account_id = transaction.sourceAccountRid
        self.target_account_id = transaction.targetAccountRid
        self.context_ids = transaction.contextRids
        
        self.details = transaction.details
        if var details = transaction.decodedLogDetails {
            details.removeFields()
            self.log_details = details
        } else {
            self.log_details = nil
        }
    }
}


struct TransactionEditor: EditorProtocol {
    
    var timeStart: Date
    var executionDate: Date?
    
    var amount: Double?
    var realAmount: Double?
    var currency: String?
    var myCost: Double?
    
    var bankAmount: Double?
    var bankCurrency: String?
    
    var type: TransactionType?
    var parentInstance: ActivityInstance?
    var parentTrip: Trip?
    var payer: Person?
    var sourceAccount: DataBankAccount?
    var targetAccount: DataBankAccount?
    
    var typeRid: Int?
    var parentTripRid: Int?
    var parentInstanceRid: Int?
    var payerRid: Int?
    var sourceAccountRid: Int?
    var targetAccountRid: Int?
    var contextRids: [Int] = []
    
    var details: String?
    var decodedLogDetails: LogDetails?
    
    var isIncome: Bool = false
    
    typealias Model = Transaction
    
    init(from transaction: Transaction) {
        self.timeStart = transaction.transactionTime
        self.executionDate = transaction.executionDate
        
        // In the double-entry system, income vs expense is usually 
        // derived from source/target accounts instead of sign,
        // but keeping it here if your UI still needs the explicit toggle.
        self.isIncome = (transaction.amount ?? -1) > 0

        self.amount = transaction.amount.map { abs($0) }
        self.myCost = transaction.myCost.map { abs($0) }
        self.realAmount = transaction.realAmount.map { abs($0) }
        self.bankAmount = transaction.bankAmount.map { abs($0) }
        self.currency = transaction.currency ?? "CHF"
        self.bankCurrency = transaction.bankCurrency ?? "CHF"
        
        // Relationships
        self.type = transaction.type
        self.typeRid = transaction.typeRid
        
        self.parentInstance = transaction.parentInstance
        self.parentInstanceRid = transaction.parentInstanceRid
        
        self.parentTrip = transaction.parentTrip
        self.parentTripRid = transaction.parentTripRid
        
        self.payer = transaction.payer
        self.payerRid = transaction.payerRid
        
        self.sourceAccount = transaction.sourceAccount
        self.sourceAccountRid = transaction.sourceAccountRid
        
        self.targetAccount = transaction.targetAccount
        self.targetAccountRid = transaction.targetAccountRid
        
        self.contextRids = transaction.contextRids
        
        self.details = transaction.details
        self.decodedLogDetails = transaction.decodedLogDetails
    }
    
    func applySign(to value: Double?) -> Double? {
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
        
        transaction.type = self.type
        transaction.typeRid = self.type?.rid ?? self.typeRid
        
        transaction.parentInstance = self.parentInstance
        transaction.parentInstanceRid = self.parentInstance?.rid ?? self.parentInstanceRid
        
        transaction.parentTrip = self.parentTrip
        transaction.parentTripRid = self.parentTrip?.rid ?? self.parentTripRid
        
        transaction.payer = self.payer
        transaction.payerRid = self.payer?.rid ?? self.payerRid
        
        transaction.sourceAccount = self.sourceAccount
        transaction.sourceAccountRid = self.sourceAccount?.rid ?? self.sourceAccountRid
        
        transaction.targetAccount = self.targetAccount
        transaction.targetAccountRid = self.targetAccount?.rid ?? self.targetAccountRid
        
        transaction.contextRids = self.contextRids
        
        transaction.details = self.details
        transaction.decodedLogDetails = self.decodedLogDetails
    }
    
    // MARK: - Semantic Helpers
    @Transient var transactionTime: Date {
        get { timeStart }
        set { timeStart = newValue }
    }
}


extension Transaction: LinkedParent {}

extension Transaction {
    @discardableResult
    static func create(in context: ModelContext, date: Date) -> Transaction {
        let smartDate = date.smartCreationTime
        let newTransaction = Transaction(timeStart: smartDate)
        context.insert(newTransaction)
        try? context.save()
        return newTransaction
    }
}
