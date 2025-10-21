//
//  TripDetailViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.10.2025.
//


import SwiftUI
import SwiftData

@MainActor
class TripDetailViewModel: ObservableObject {
    @Published var editor: TripEditor
    @Published var isShowingPathSelector = false
    @State var showEndTime: Bool = true
    
    private var trip: Trip
    private let modelContext: ModelContext

    init(trip: Trip, modelContext: ModelContext) {
        self.trip = trip
        self.editor = TripEditor(trip: trip)
        self.modelContext = modelContext
        self.showEndTime = trip.time_end != nil
    }

    func selectPath(path: Path) {
        editor.path = path
    }

    func onDone(completion: @escaping () -> Void) {
        editor.apply(to: trip)
        trip.markAsModified()
        
        do {
            try modelContext.save()
            completion()
        } catch {
            print("❌ Failed to save Trip: \(error)")
        }
    }
}
