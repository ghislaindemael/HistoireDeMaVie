//
//  SyncableModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.08.2025.
//


import SwiftData

protocol SyncableModel: PersistentModel {
    var syncStatus: SyncStatus { get set }
}
