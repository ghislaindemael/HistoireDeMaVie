//
//  TripDetailViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.10.2025.
//

import SwiftUI
import SwiftData

@MainActor
class TripDetailSheetViewModel: BaseDetailSheetViewModel<Trip, TripEditor> {
    
    @Published var isShowingPathSelector = false
    @Published var isShowingMetricsEditSheet = false
    
    @Published var isShowingPathPromotionAlert = false
    @Published var newPathName = ""
    
    func selectPath(path: Path) {
        editor.path = path
        editor.pathRid = path.rid
    }
    
    // MARK: - Path Promotion
    
    /// Returns true if the Trip has the necessary data to become a Reusable Path
    var canPromoteToPath: Bool {
        return (editor.placeStart != nil || editor.placeStartRid != nil) &&
        (editor.placeEnd != nil || editor.placeEndRid != nil) &&
        editor.pathMetrics != nil
    }
    
    func promoteToReusablePath() {
        let trimmedName = newPathName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newPath = Path(
            name: trimmedName,
            details: "Created from trip on \(editor.timeStart.formatted(date: .abbreviated, time: .omitted))",
            placeStart: editor.placeStart,
            placeEnd: editor.placeEnd,
            metrics: editor.pathMetrics ?? PathMetrics(),
            geojsonTrack: editor.geojsonTrack,
            cache: true,
            syncStatus: .local
        )
        
        newPath.placeStartRid = editor.placeStart?.rid ?? editor.placeStartRid
        newPath.placeEndRid = editor.placeEnd?.rid ?? editor.placeEndRid
        
        modelContext.insert(newPath)
        
        editor.path = newPath
        editor.pathRid = nil
        
        editor.pathMetrics = nil
        editor.geojsonTrack = nil
        
        newPathName = ""
        isShowingPathPromotionAlert = false
        
        try? modelContext.save()
    }
}
