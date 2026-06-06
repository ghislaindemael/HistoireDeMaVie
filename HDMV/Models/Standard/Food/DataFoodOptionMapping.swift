import Foundation
import SwiftData

@Model
final class DataFoodOptionMapping: Identifiable, Hashable, CatalogueModel {
    var rid: Int?
    var priority: Int = 0
    var cache: Bool = true
    var archived: Bool = false
    var foodItem: DataFoodItem?
    var foodOption: DataFoodOption?
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    // Virtual references since we can't reliably trust SwiftData relationships during sync
    var foodItemRid: Int?
    var foodOptionRid: Int?
    
    typealias Payload = DataFoodOptionMappingPayload
    typealias DTO = DataFoodOptionMappingDTO
    typealias Editor = DataFoodOptionMappingEditor
    
    init(
        rid: Int? = nil,
        priority: Int = 0,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.priority = priority
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: DataFoodOptionMappingDTO) {
        self.init()
        self.rid = dto.id
        self.foodItemRid = dto.food_item_id
        self.foodOptionRid = dto.food_option_id
        self.priority = dto.priority
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DataFoodOptionMappingDTO) {
        self.foodItemRid = dto.food_item_id
        self.foodOptionRid = dto.food_option_id
        self.priority = dto.priority
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        // Need to have a valid relation to both items, or RIDs set
        return (foodItem != nil || foodItemRid != nil) && (foodOption != nil || foodOptionRid != nil)
    }
    
    var hasUnsyncedChanges: Bool { return self.syncStatus != .synced }
}

struct DataFoodOptionMappingDTO: Codable, Identifiable {
    let id: Int
    let food_item_id: Int
    let food_option_id: Int
    let priority: Int
}

struct DataFoodOptionMappingPayload: Codable, InitializableWithModel {
    typealias Model = DataFoodOptionMapping
    
    let food_item_id: Int
    let food_option_id: Int
    let priority: Int
    
    init?(from model: DataFoodOptionMapping) {
        guard model.isValid() else { return nil }
        
        let iid = model.foodItem?.rid ?? model.foodItemRid
        let oid = model.foodOption?.rid ?? model.foodOptionRid
        
        guard let finalIID = iid, let finalOID = oid else { return nil }
        
        self.food_item_id = finalIID
        self.food_option_id = finalOID
        self.priority = model.priority
        
    }
}

struct DataFoodOptionMappingEditor: CachableModel, EditorProtocol {
    var priority: Int
    var cache: Bool = true
    var archived: Bool = false
    typealias Model = DataFoodOptionMapping
    init(from model: DataFoodOptionMapping) {
        self.priority = model.priority
        self.cache = model.cache
        self.archived = model.archived
    }
    func apply(to model: DataFoodOptionMapping) {
        model.priority = self.priority
        model.cache = self.cache
        model.archived = self.archived
    }
}
