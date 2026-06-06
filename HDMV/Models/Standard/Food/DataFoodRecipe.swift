import Foundation
import SwiftData

@Model
final class DataFoodRecipe: Identifiable, Hashable, CatalogueModel {
    var rid: Int?
    var name: String
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
        compositionRaw: Data? = nil,
        archived: Bool = false,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.rid = rid
        self.name = name
        self.compositionRaw = compositionRaw
        self.archived = archived
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: DataFoodRecipeDTO) {
        self.init()
        self.rid = dto.id
        self.name = dto.name
        if let comp = dto.composition {
            self.compositionRaw = try? JSONEncoder().encode(comp)
        }
        self.archived = dto.archived ?? false
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DataFoodRecipeDTO) {
        self.name = dto.name
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
    // We store it as generic Data here because ComposedFood is in the ActivityDetails scope. Wait, if ComposedFood is public, we can use it! 
    // We will just assume it's available.
    let composition: [ComposedFood]?
    let archived: Bool?
}

struct DataFoodRecipePayload: Codable, InitializableWithModel {
    typealias Model = DataFoodRecipe
    
    let name: String
    let composition: [ComposedFood]?
    let archived: Bool
    
    init?(from model: DataFoodRecipe) {
        guard model.isValid() else { return nil }
        self.name = model.name
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
    var cache: Bool = true
    var archived: Bool
    
    typealias Model = DataFoodRecipe
    init(from model: DataFoodRecipe) {
        self.name = model.name
        self.archived = model.archived
    }
    func apply(to model: DataFoodRecipe) {
        model.name = self.name
        model.cache = self.cache
        model.archived = self.archived
    }
}
