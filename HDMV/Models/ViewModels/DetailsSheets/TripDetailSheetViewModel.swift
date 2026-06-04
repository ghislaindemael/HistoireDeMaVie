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
    @Published var isShowingTransitLineSelector = false
    
    @Published var isShowingPathPromotionAlert = false
    @Published var newPathName = ""
    
    func selectPath(path: Path) {
        editor.path = path
        editor.pathRid = path.rid
        editor.transitLine = nil
        editor.transitLineRid = nil
    }
    
    func selectTransitLine(line: TransitLine) {
        editor.transitLine = line
        editor.transitLineRid = line.rid
        editor.path = nil
        editor.pathRid = nil
    }
    
    // MARK: - Transit Distance Calculation
    
    var canCalculateDistanceFromTransit: Bool {
        return editor.transitLine != nil 
            && (editor.placeStart != nil || editor.placeStartRid != nil) 
            && (editor.placeEnd != nil || editor.placeEndRid != nil)
            && editor.pathMetrics == nil
    }
    
    func calculateDistanceFromTransit() {
        guard let line = editor.transitLine,
              let stops = line.stops,
              let startPlaceRid = editor.placeStart?.rid ?? editor.placeStartRid,
              let endPlaceRid = editor.placeEnd?.rid ?? editor.placeEndRid else {
            return
        }
        
        let sortedStops = stops.sorted { $0.stopSequence < $1.stopSequence }
        
        guard let startIndex = sortedStops.firstIndex(where: { $0.station?.placeRid == startPlaceRid }),
              let endIndex = sortedStops.firstIndex(where: { $0.station?.placeRid == endPlaceRid }) else {
            print("Could not find start or end place in transit line stops")
            return
        }
        
        var totalDistance: Double = 0
        
        if startIndex < endIndex {
            // Forward journey
            for i in startIndex..<endIndex {
                if let dist = sortedStops[i].distanceToNext {
                    totalDistance += dist
                }
            }
        } else if startIndex > endIndex {
            // Backward journey
            // Going from higher sequence to lower sequence
            // e.g., Allaman (idx 5) to Rolle (idx 4)
            // Distance is stored on the lower indexed stop (Rolle has distanceToNext = Allaman)
            for i in endIndex..<startIndex {
                if let dist = sortedStops[i].distanceToNext {
                    totalDistance += dist
                }
            }
        }
        
        if totalDistance > 0 {
            withAnimation {
                editor.pathMetrics = PathMetrics(distance: totalDistance)
            }
        }
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
