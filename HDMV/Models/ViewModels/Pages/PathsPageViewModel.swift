//
//  PathsPageViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import Foundation
import SwiftData

@MainActor
class PathsPageViewModel: ObservableObject {
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private let tripsService = TripsService()
    private var gpxParser = GPXParserService()
    private let storageService = StorageService()
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Data Fetching and Management
    
    func syncWithServer() async {
        guard let context = modelContext else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let onlinePaths = try await tripsService.fetchPaths()
            // Map by the server ID (rid)
            let onlineDict = Dictionary(uniqueKeysWithValues: onlinePaths.map { ($0.id, $0) })
            
            let descriptor = FetchDescriptor<Path>()
            let localPaths = try context.fetch(descriptor)
            
            // Map local paths by their rid
            let localDict = Dictionary(uniqueKeysWithValues: localPaths.compactMap { p in
                p.rid.map { ($0, p) }
            })

            for dto in onlinePaths {
                if let localPath = localDict[dto.id] {
                    if localPath.syncStatus == .synced {
                        localPath.update(fromDto: dto)
                    }
                } else {
                    context.insert(Path(fromDto: dto))
                }
            }
            
            // Pruning logic
            for localPath in localPaths {
                if let rid = localPath.rid, onlineDict[rid] == nil && localPath.syncStatus == .synced {
                    context.delete(localPath)
                }
            }
            
            try context.save()
        } catch {
            print("Error: \(error)")
        }
    }
    
    // MARK: Synchronization

    private func syncPath(path: Path, in context: ModelContext) async {
        guard let payload = PathPayload(from: path) else { return }
        
        do {
            // rid is nil or < 0 for local items
            if path.rid == nil {
                let newDTO = try await self.tripsService.createPath(payload: payload)
                // Update the rid from the server response
                path.rid = newDTO.id
                path.syncStatus = .synced
            } else {
                _ = try await self.tripsService.updatePath(id: path.rid!, payload: payload)
                path.syncStatus = .synced
            }
        } catch {
            path.syncStatus = .failed
        }
    }
    
    /// Uploads all activities marked as `.local` or `.failed` to the server.
    func syncLocalChanges() async {
        guard let context = modelContext else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allPathsInDB = try context.fetch(FetchDescriptor<Path>())
            
            let pathsToSync = allPathsInDB.filter {
                $0.syncStatus == .local || $0.syncStatus == .failed
            }
            
            guard !pathsToSync.isEmpty else {
                print("✅ No local activity changes to sync.")
                return
            }
            
            print("⏳ Syncing \(pathsToSync.count) paths...")
            
            await withTaskGroup(of: Void.self) { group in
                for path in pathsToSync {
                    group.addTask {
                        await self.syncPath(path: path, in: context)
                    }
                }
            }
            
            try context.save()
            print("✅ Sync complete. Refreshing from server...")
            await syncWithServer()
            
        } catch {
            print("❌ Failed to fetch paths for syncing: \(error)")
        }
    }
    
        
    // MARK: User Actions
    
    func createLocalPath() {
        guard let context = modelContext else { return }
        let newPath =
            Path(syncStatus: .local)
        context.insert(newPath)
        do {
            try context.save()
        } catch {
            print("Failed to create path: \(error)")
        }
    }
    
    

}
