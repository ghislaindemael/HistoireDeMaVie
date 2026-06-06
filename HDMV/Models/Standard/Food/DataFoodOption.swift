import Foundation
import SwiftData

@Model
final class DataFoodOption: Identifiable, Hashable, CatalogueModel {
    var rid: Int?
    var slug: String
    var name: String
    var typeRaw: String
    var enumValuesRaw: Data? // [String]
    var isRequired: Bool = false
    var cache: Bool = true
    var archived: Bool = false
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    @Relationship(deleteRule: .cascade, inverse: \DataFoodOptionMapping.foodOption)
    var mappings: [DataFoodOptionMapping]? = []
    
    typealias Payload = DataFoodOptionPayload
    typealias DTO = DataFoodOptionDTO
    typealias Editor = DataFoodOptionEditor
    
    init(
        rid: Int? = nil,
        slug: String = "unset",
        name: String = "Unset",
        typeRaw: String = "text",
        enumValues: [String]? = nil,
        isRequired: Bool = false,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.slug = slug
        self.name = name
        self.typeRaw = typeRaw
        if let vals = enumValues {
            self.enumValuesRaw = try? JSONEncoder().encode(vals)
        }
        self.isRequired = isRequired
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    var enumValues: [String]? {
        get {
            guard let data = enumValuesRaw else { return nil }
            return try? JSONDecoder().decode([String].self, from: data)
        }
        set {
            if let newVals = newValue {
                enumValuesRaw = try? JSONEncoder().encode(newVals)
            } else {
                enumValuesRaw = nil
            }
        }
    }
    
    convenience init(fromDto dto: DataFoodOptionDTO) {
        self.init()
        self.rid = dto.id
        self.slug = dto.slug
        self.name = dto.name
        self.typeRaw = dto.type
        if let vals = dto.enum_values {
            self.enumValuesRaw = try? JSONEncoder().encode(vals)
        }
        self.isRequired = dto.is_required ?? false
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DataFoodOptionDTO) {
        self.slug = dto.slug
        self.name = dto.name
        self.typeRaw = dto.type
        if let vals = dto.enum_values {
            self.enumValuesRaw = try? JSONEncoder().encode(vals)
        } else {
            self.enumValuesRaw = nil
        }
        self.isRequired = dto.is_required ?? false
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return slug != "unset" && name != "Unset"
    }
    
    var hasUnsyncedChanges: Bool { return self.syncStatus != .synced }
}

struct DataFoodOptionDTO: Codable, Identifiable {
    let id: Int
    let slug: String
    let name: String
    let type: String
    let enum_values: [String]?
    let is_required: Bool?
    let archived: Bool?
}

struct DataFoodOptionPayload: Codable, InitializableWithModel {
    typealias Model = DataFoodOption
    
    let slug: String
    let name: String
    let type: String
    let enum_values: [String]?
    let is_required: Bool
    let archived: Bool
    
    init?(from model: DataFoodOption) {
        guard model.isValid() else { return nil }
        self.slug = model.slug
        self.name = model.name
        self.type = model.typeRaw
        self.enum_values = model.enumValues
        self.is_required = model.isRequired
        self.archived = model.archived
    }
}

struct DataFoodOptionEditor: CachableModel, EditorProtocol {
    var slug: String
    var name: String
    var typeRaw: String
    var enumValues: [String]?
    var isRequired: Bool
    var cache: Bool = true
    var archived: Bool
    
    typealias Model = DataFoodOption
    
    init(from model: DataFoodOption) {
        self.slug = model.slug
        self.name = model.name
        self.typeRaw = model.typeRaw
        self.enumValues = model.enumValues
        self.isRequired = model.isRequired
        self.archived = model.archived
    }
    
    func apply(to model: DataFoodOption) {
        model.slug = self.slug
        model.name = self.name
        model.typeRaw = self.typeRaw
        model.enumValues = self.enumValues
        model.isRequired = self.isRequired
        model.cache = self.cache
        model.archived = self.archived
    }
}
