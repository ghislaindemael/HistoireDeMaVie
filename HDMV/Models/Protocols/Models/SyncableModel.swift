//
//  SyncableModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.08.2025.
//


import SwiftData

protocol SyncableModel: PersistentModel {
    associatedtype Payload
    var id: Int { get set }
    var syncStatusRaw: String { get set }
    func isValid() -> Bool
}

extension SyncableModel {
    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .undef }
        set { syncStatusRaw = newValue.rawValue }
    }
}
