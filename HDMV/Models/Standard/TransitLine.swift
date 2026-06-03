//
//  TransitLine.swift
//  HDMV
//

import SwiftData
import Foundation

@Model
final class TransitLine: CatalogueModel {
    
    @Attribute(.unique) var rid: Int?
    @Attribute(.unique) var name: String = "Unset"
    var allowedVehicleRids: [Int]?
    
    var cache: Bool = false
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias Payload = TransitLinePayload
    typealias DTO = TransitLineDTO
    typealias Editor = TransitLineEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .cascade, inverse: \TransitStop.line)
    var stops: [TransitStop]?
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.transitLine)
    var trips: [Trip]?
    
    // MARK: - Init
    
    init(
        rid: Int? = nil,
        name: String = "Unset",
        allowedVehicleRids: [Int]? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.allowedVehicleRids = allowedVehicleRids
        self.cache = cache
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: TransitLineDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        self.allowedVehicleRids = dto.allowed_vehicle_ids
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    // MARK: - Update
    
    func update(fromDto dto: TransitLineDTO) {
        self.name = dto.name
        self.allowedVehicleRids = dto.allowed_vehicle_ids
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    // MARK: - Validation
    
    func isValid() -> Bool {
        return name.isNotUnset()
    }
}

struct TransitLineDTO: Codable, Sendable, Identifiable {
    var id: Int
    var name: String
    var allowed_vehicle_ids: [Int]?
    var archived: Bool?
}

struct TransitLinePayload: Codable, InitializableWithModel {
    typealias Model = TransitLine
    
    var name: String
    var allowed_vehicle_ids: [Int]?
    var archived: Bool
    
    init?(from line: TransitLine) {
        guard line.isValid() else { return nil }
        self.name = line.name
        self.allowed_vehicle_ids = line.allowedVehicleRids
        self.archived = line.archived
    }
}

struct TransitLineEditor: EditorProtocol {
    var rid: Int?
    var name: String
    var allowedVehicleRids: [Int]?
    var cache: Bool
    var archived: Bool
    
    typealias Model = TransitLine
    
    init(from line: TransitLine) {
        self.rid = line.rid
        self.name = line.name
        self.allowedVehicleRids = line.allowedVehicleRids
        self.cache = line.cache
        self.archived = line.archived
    }
    
    func apply(to line: TransitLine) {
        line.name = name
        line.allowedVehicleRids = allowedVehicleRids
        line.cache = cache
        line.archived = archived
    }
}
