import Foundation
import SwiftData

@MainActor
final class PathSyncer: BaseSyncer<Path, PathDTO, PathPayload> {

    override func pullChanges() async throws {
        // 1. Fetch DTOs from server
        let dtos: [PathDTO] = try await fetchFromServer()
        
        // 2. Build a local cache of existing Paths
        let existingPaths = try modelContext.fetch(FetchDescriptor<Path>())
        var localCache = Dictionary(uniqueKeysWithValues: existingPaths.map { ($0.id, $0) })
        
        for dto in dtos {
            if let path = localCache[dto.id] {
                // update existing
                try path.update(fromDto: dto, context: modelContext)
            } else {
                // create new
                let newPath = try Path(fromDto: dto, context: modelContext)
                localCache[newPath.id] = newPath
            }
        }
        
        try modelContext.save()
    }

    override func resolveRelationships(for model: Path, from dto: PathDTO, using localCache: [Int : Path]) async throws {
        // Not much needed for Path because we store Place objects
        // Fetch Place references from context
        if let start = try modelContext.fetch(FetchDescriptor<Place>(predicate: #Predicate { $0.id == dto.place_start_id })).first {
            model.placeStart = start
        }
        if let end = try modelContext.fetch(FetchDescriptor<Place>(predicate: #Predicate { $0.id == dto.place_end_id })).first {
            model.placeEnd = end
        }
    }

    override func createOnServer(payload: PathPayload) async throws -> PathDTO {
        // Call your server API to create, return the DTO
        fatalError()
    }

    override func updateOnServer(id: Int, payload: PathPayload) async throws -> PathDTO {
        // Call your server API to update, return the DTO
        fatalError()
    }

    override func deleteFromServer(_ id: Int) async throws {
        // Call your server API to delete
        fatalError()
    }

}
