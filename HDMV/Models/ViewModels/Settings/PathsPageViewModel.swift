//
//  ActivitiesPageViewModel.swift
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
            let onlineDict = Dictionary(uniqueKeysWithValues: onlinePaths.map { ($0.id, $0) })
            
            let descriptor = FetchDescriptor<Path>()
            let localPaths = try context.fetch(descriptor)
            let localDict = Dictionary(uniqueKeysWithValues: localPaths.map { ($0.id, $0) })
            
            for dto in onlinePaths {
                if let localPath = localDict[dto.id] {
                    if localPath.syncStatus == .synced {
                        localPath.update(fromDto: dto)
                    }
                } else {
                    context.insert(Path(fromDto: dto))
                }
            }
            
            for localPath in localPaths {
                if onlineDict[localPath.id] == nil && localPath.syncStatus == .synced {
                    context.delete(localPath)
                }
            }
            
            try context.save()
            
        } catch {
            print("Failed to fetch paths from server: \(error)")
        }
        
    }
    
    // MARK: Synchronization
    
    private func syncPath(path: Path, in context: ModelContext) async {
        if let payload = PathPayload(from: path) {
            do {
                if path.id < 0 {
                    let temporaryId = path.id
                    let newDTO = try await self.tripsService.createPath(payload: payload)
                    if let pathToUpdate = try context.fetch(FetchDescriptor<Path>()).first(where: { $0.id == temporaryId }) {
                        pathToUpdate.id = newDTO.id
                        pathToUpdate.syncStatus = SyncStatus.synced
                    }
                } else {
                    _ = try await self.tripsService.updatePath(id: path.id, payload: payload)
                }
                path.syncStatus = .synced
            } catch {
                path.syncStatus = .failed
                print("Failed to sync path: \(error).")
            }
        } else {
            print("Invalid path, skipping sync.")
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
            Path(
                id: TempIDGenerator.generate(for: Path.self, in: context),
                syncStatus: .local
            )
        
        context.insert(newPath)
        do {
            try context.save()
        } catch {
            print("Failed to create path: \(error)")
        }
    }
    
    

}
