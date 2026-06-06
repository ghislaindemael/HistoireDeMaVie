import Foundation
import SwiftData

@Model
final class DataFoodRecipe: Identifiable, Hashable, CatalogueModel, TreeSelectable {
    var rid: Int?
    var name: String
    var parentId: Int?
    var parent: DataFoodRecipe? {
        didSet {
            parentId = parent?.rid
        }
    }
    
    @Relationship(deleteRule: .cascade, inverse: \DataFoodRecipe.parent)
    var children: [DataFoodRecipe] = []
    
    var icon: String? { return nil }
    var optionalChildren: [DataFoodRecipe]? { children.isEmpty ? nil : children.sorted(by: { $0.name < $1.name }) }
    
    var compositionRaw: Data? // [ComposedFood]
    var cache: Bool = true
    var archived: Bool = false
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias Payload = DataFoodRecipePayload
    typealias DTO = DataFoodRecipeDTO
    typealias Editor = DataFoodRecipeEditor
    
    init(
        rid: Int? = nil,
        name: String = "Unset",
        parentId: Int? = nil,
        compositionRaw: Data? = nil,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.parentId = parentId
        self.compositionRaw = compositionRaw
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: DataFoodRecipeDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        self.parentId = dto.parent_id
        if let comp = dto.composition {
            self.compositionRaw = try? JSONEncoder().encode(comp)
        }
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DataFoodRecipeDTO) {
        self.name = dto.name
        self.parentId = dto.parent_id
        if let comp = dto.composition {
            self.compositionRaw = try? JSONEncoder().encode(comp)
        } else {
            self.compositionRaw = nil
        }
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return name != "Unset" && !name.isEmpty
    }
    
    var hasUnsyncedChanges: Bool { return self.syncStatus != .synced }
}

struct DataFoodRecipeDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let parent_id: Int?
    let composition: [ComposedFood]?
    let archived: Bool?
}

struct DataFoodRecipePayload: Codable, InitializableWithModel {
    typealias Model = DataFoodRecipe
    
    let name: String
    let parent_id: Int?
    let composition: [ComposedFood]?
    let archived: Bool
    
    init?(from model: DataFoodRecipe) {
        guard model.isValid() else { return nil }
        self.name = model.name
        self.parent_id = model.parentId
        if let data = model.compositionRaw {
            self.composition = try? JSONDecoder().decode([ComposedFood].self, from: data)
        } else {
            self.composition = nil
        }
        self.archived = model.archived
    }
}

struct DataFoodRecipeEditor: CachableModel, EditorProtocol {
    var name: String
    var parentId: Int?
    var parent: DataFoodRecipe? {
        didSet {
            parentId = parent?.rid
        }
    }
    var cache: Bool = true
    var archived: Bool
    
    typealias Model = DataFoodRecipe
    init(from model: DataFoodRecipe) {
        self.name = model.name
        self.parentId = model.parentId
        self.parent = model.parent
        self.archived = model.archived
    }
    func apply(to model: DataFoodRecipe) {
        model.name = self.name
        model.parentId = self.parentId
        model.parent = self.parent
        model.cache = self.cache
        model.archived = self.archived
    }
}
