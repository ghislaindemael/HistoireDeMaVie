//
//  TripLegDetailViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.10.2025.
//


import SwiftUI
import SwiftData

@MainActor
class TripLegDetailViewModel: ObservableObject {
    @Published var editor: TripLegEditor
    @Published var isShowingPathSelector = false
    @Published var showEndTime: Bool
    
    private var tripLeg: TripLeg
    private let modelContext: ModelContext

    init(tripLeg: TripLeg, modelContext: ModelContext) {
        self.tripLeg = tripLeg
        self.editor = TripLegEditor(tripLeg: tripLeg)
        self.modelContext = modelContext
        self.showEndTime = tripLeg.time_end != nil
    }

    func selectPath(pathId: Int) {
        editor.path_id = pathId
    }

    func onDone(completion: @escaping () -> Void) {
        if !showEndTime {
            editor.time_end = nil
        }
        editor.apply(to: tripLeg)
        
        do {
            try modelContext.save()
            completion()
        } catch {
            print("❌ Failed to save TripLeg: \(error)")
        }
    }
}
