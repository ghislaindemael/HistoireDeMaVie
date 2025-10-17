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
class VehicleDetailSheetViewModel: ObservableObject {
    @Published var editor: VehicleEditor

    private var vehicle: Vehicle
    private let modelContext: ModelContext
    
    init(vehicle: Vehicle, modelContext: ModelContext) {
        self.vehicle = vehicle
        self.editor = VehicleEditor(from: vehicle)
        self.modelContext = modelContext
    }

    // MARK: - User Actions

    func onDone() {
        editor.apply(to: vehicle)
        vehicle.markAsModified()
        
        do {
            try modelContext.save()
            print("✅ Vehicle \(vehicle.id) saved to context.")
        } catch {
            print("❌ Failed to save vehicle to context: \(error)")
        }
    }
}
