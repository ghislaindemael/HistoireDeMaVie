import Foundation
import SwiftData

@MainActor
final class LifeEventTypesSyncer: BaseSyncer<LifeEventType, LifeEventTypeDTO, LifeEventTypePayload> {
    
    private let typesService = LifeEventTypesService()
    private let settings: SettingsStore = SettingsStore.shared
        
    override func fetchRemoteModels(date: Date?) async throws -> [LifeEventTypeDTO] {
        return try await typesService.fetchTypes(includeArchived: settings.includeArchived)
    }
    
    override func createOnServer(payload: LifeEventTypePayload) async throws -> LifeEventTypeDTO {
        return try await typesService.createType(payload: payload)
    }
    
    override func updateOnServer(rid: Int, payload: LifeEventTypePayload) async throws -> LifeEventTypeDTO {
        return try await typesService.updateType(rid: rid, payload: payload)
    }
    
    override func deleteFromServer(_ id: Int) async throws {
        fatalError("LifeEventType deletion not implemented")
    }
    
    override func resolveRelationships() throws {
        
        let allTypes = try modelContext.fetch(FetchDescriptor<LifeEventType>())
        let modelsWithRid = allTypes.filter { $0.rid != nil }
        
        let typesCache = Dictionary(modelsWithRid.map { ($0.rid!, $0) },
                                       uniquingKeysWith: { (first, _) in first })
        
        for type in allTypes {
            guard let parentRid = type.parentRid else {
                if type.parent != nil {
                    type.parent = nil
                }
                continue
            }
            
            if type.parent?.rid != parentRid {
                type.parent = typesCache[parentRid]
            }
        }
    }
    
}
