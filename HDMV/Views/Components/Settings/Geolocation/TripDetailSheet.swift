//
//  TripDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct TripDetailSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TripDetailSheetViewModel

    init(trip: Trip, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: TripDetailSheetViewModel(
            model: trip,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                TimeSection(editor: $viewModel.editor, timeOnly: true)
                vehicleSection
                
                Section("Start Place") {
                    PlaceSelectorView(selectedPlace: $viewModel.editor.placeStart)
                }
                Section("End Place") {
                    PlaceSelectorView(selectedPlace: $viewModel.editor.placeEnd)
                }
                pathSection
                detailsSection
            }
            .navigationTitle("Trip Detail")
            .standardSheetToolbar(onDone: {
                viewModel.onDone()
                dismiss()
            })
            .sheet(isPresented: $viewModel.isShowingPathSelector) {
                PathSelectorSheet(
                    startPlaceId: viewModel.editor.placeStart?.rid,
                    endPlaceId: viewModel.editor.placeEnd?.rid,
                    onPathSelected: viewModel.selectPath
                )
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var vehicleSection: some View {
        Section("Vehicle") {
            VehicleSelectorView(
                selectedVehicle: $viewModel.editor.vehicle,
                amDriver: $viewModel.editor.am_driver
            )
        }
    }
    
    private var pathSection: some View {
        Section(header: Text("Path")) {
            PathDisplayView(path: viewModel.editor.path)
            
            Button(action: { viewModel.isShowingPathSelector = true }) {
                Label("Select path", systemImage: "plus.circle.fill")
            }
        }
    }
    
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            TextEditor(text: $viewModel.editor.details.bound)
                .frame(minHeight: 100)
        }
    }
    
    
    
}
