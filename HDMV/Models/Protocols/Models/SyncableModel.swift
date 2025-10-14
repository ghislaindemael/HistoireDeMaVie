//
//  SyncableModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.08.2025.
//


import SwiftData

protocol SyncableModel: AnyObject {
    associatedtype Payload
    var rid: Int? { get set }
    var syncStatusRaw: String { get set }
    func isValid() -> Bool
}

extension SyncableModel {
    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .undef }
        set { syncStatusRaw = newValue.rawValue }
    }
    
    func markAsModified() {
        Task { @MainActor in
            syncStatus = .local
        }
    }
}
