import Foundation
import SwiftData

struct DataFoodItemMacros: Codable, Equatable {
    var calories: Double?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
}

@Model
final class DataFoodItem: Identifiable, Hashable, CatalogueModel, TreeSelectable {
    var rid: Int?
    var name: String
    var parentId: Int?
    var parent: DataFoodItem? {
        didSet {
            parentId = parent?.rid
        }
    }
    
    @Relationship(deleteRule: .cascade, inverse: \DataFoodItem.parent)
    var children: [DataFoodItem] = []
    
    var icon: String? { return nil }
    var optionalChildren: [DataFoodItem]? { children.isEmpty ? nil : children.sorted(by: { $0.name < $1.name }) }
    var baseUnit: String?
    var macrosRaw: Data?
    var cache: Bool = true
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    @Relationship(deleteRule: .cascade, inverse: \DataFoodOptionMapping.foodItem)
    var optionMappings: [DataFoodOptionMapping]? = []
    
    typealias Payload = DataFoodItemPayload
    typealias DTO = DataFoodItemDTO
    typealias Editor = DataFoodItemEditor
    
    init(
        rid: Int? = nil,
        name: String = "Unset",
        parentId: Int? = nil,
        baseUnit: String? = nil,
        macros: DataFoodItemMacros? = nil,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.parentId = parentId
        self.baseUnit = baseUnit
        if let macros = macros {
            self.macrosRaw = try? JSONEncoder().encode(macros)
        }
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    var macros: DataFoodItemMacros? {
        get {
            guard let data = macrosRaw else { return nil }
            return try? JSONDecoder().decode(DataFoodItemMacros.self, from: data)
        }
        set {
            if let newMacros = newValue {
                macrosRaw = try? JSONEncoder().encode(newMacros)
            } else {
                macrosRaw = nil
            }
        }
    }
    
    convenience init(fromDto dto: DataFoodItemDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        self.parentId = dto.parent_id
        self.baseUnit = dto.base_unit
        if let mac = dto.macros {
            self.macrosRaw = try? JSONEncoder().encode(mac)
        }
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DataFoodItemDTO) {
        self.name = dto.name
        self.parentId = dto.parent_id
        self.baseUnit = dto.base_unit
        if let mac = dto.macros {
            self.macrosRaw = try? JSONEncoder().encode(mac)
        } else {
            self.macrosRaw = nil
        }
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return name != "Unset" && !name.isEmpty
    }
    
    var hasUnsyncedChanges: Bool { return self.syncStatus != .synced }
}

struct DataFoodItemDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let parent_id: Int?
    let base_unit: String?
    let macros: DataFoodItemMacros?
    let archived: Bool?
}

struct DataFoodItemPayload: Codable, InitializableWithModel {
    typealias Model = DataFoodItem
    
    let name: String
    let parent_id: Int?
    let base_unit: String?
    let macros: DataFoodItemMacros?
    let archived: Bool
    
    init?(from model: DataFoodItem) {
        guard model.isValid() else { return nil }
        self.name = model.name
        self.parent_id = model.parentId
        self.base_unit = model.baseUnit
        self.macros = model.macros
        self.archived = model.archived
    }
}

struct DataFoodItemEditor: CachableModel, EditorProtocol {
    var name: String
    var parentId: Int?
    var parent: DataFoodItem? {
        didSet {
            parentId = parent?.rid
        }
    }
    
    @Relationship(deleteRule: .cascade, inverse: \DataFoodItem.parent)
    var children: [DataFoodItem] = []
    
    var icon: String? { return nil }
    var optionalChildren: [DataFoodItem]? { children.isEmpty ? nil : children.sorted(by: { $0.name < $1.name }) }
    var baseUnit: String?
    var macros: DataFoodItemMacros?
    var cache: Bool = true
    var archived: Bool
    
    typealias Model = DataFoodItem
    
    init(from model: DataFoodItem) {
        self.name = model.name
        self.parentId = model.parentId
        self.parent = model.parent
        self.baseUnit = model.baseUnit
        self.macros = model.macros
        self.archived = model.archived
    }
    
    func apply(to model: DataFoodItem) {
        model.name = self.name
        model.parentId = self.parentId
        model.parent = self.parent
        model.baseUnit = self.baseUnit
        model.macros = self.macros
        model.cache = self.cache
        model.archived = self.archived
    }
}
