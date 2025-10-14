//
//  CatalogueModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 13.10.2025.
//

import Foundation
import SwiftData

@available(iOS 18.0, macOS 15.0, *)
@Model
class CatalogueModel: SyncableModel {
    typealias Payload = Never
    
    var rid: Int? = nil
    var cache: Bool = true
    var archived: Bool = false
    var syncStatusRaw: String = SyncStatus.local.rawValue
    
    init(
        rid: Int? = nil,
        cache: Bool = false,
        archived: Bool = false,
        syncStatusRaw: String = "local"
    ) {
        self.rid = rid
        self.cache = cache
        self.archived = archived
        self.syncStatusRaw = syncStatusRaw
    }
    
    func isValid() -> Bool {
        fatalError("Subclasses must override `isValid()`")
    }
}
