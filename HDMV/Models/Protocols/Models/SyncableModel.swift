//
//  SyncableModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.08.2025.
//


import SwiftData

protocol SyncableModel: AnyObject {
    associatedtype Payload
    associatedtype DTO
    var rid: Int? { get set }
    var syncStatusRaw: String { get set }
    init(fromDto dto: DTO)
    func update(fromDto dto: DTO)
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
    
    var syncPriority: Int {
        switch SyncStatus.safeInit(syncStatusRaw) {
            case .local, .failed:
                return 0
            case .syncing:
                return 1
            case .toDelete:
                return 2
            case .synced:
                return 3
            case .undef:
                return 4
        }
    }
}
