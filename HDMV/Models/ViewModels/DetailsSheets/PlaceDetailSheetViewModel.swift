//
//  PathDetailViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//


import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
class PlaceDetailSheetViewModel: ObservableObject {
    @Published var editor: PlaceEditor

    private var place: Place
    private let modelContext: ModelContext
    
    init(place: Place, modelContext: ModelContext) {
        self.place = place
        self.editor = PlaceEditor(from: place)
        self.modelContext = modelContext
    }

    // MARK: - User Actions

    func onDone() {
        editor.apply(to: place)
        place.markAsModified()
        
        do {
            try modelContext.save()
            print("✅ Place \(place.id) saved to context.")
        } catch {
            print("❌ Failed to save place to context: \(error)")
        }
    }
}
