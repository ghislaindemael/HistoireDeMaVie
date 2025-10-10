//
//  TripLegDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct TripLegDetailSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TripLegDetailViewModel
    
    init(tripLeg: TripLeg, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: TripLegDetailViewModel(
            tripLeg: tripLeg,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                timeSection
                vehicleSection
                
                Section("Start Place") {
                    PlaceSelectorView(selectedPlaceId: $viewModel.editor.place_start_id)
                }
                Section("End Place") {
                    PlaceSelectorView(selectedPlaceId: $viewModel.editor.place_end_id)
                }
                pathSection
                detailsSection
            }
            .navigationTitle("Trip Leg Details")
            .standardSheetToolbar(onDone: {
                viewModel.onDone {
                    dismiss()
                }
            })
            .sheet(isPresented: $viewModel.isShowingPathSelector) {
                PathSelectorSheet(
                    startPlaceId: viewModel.editor.place_start_id,
                    endPlaceId: viewModel.editor.place_end_id,
                    onPathSelected: viewModel.selectPath
                )
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var timeSection: some View {
        Section(header: Text("Time")) {
            FullTimePicker(label: "Start Time", selection: $viewModel.editor.time_start)
            Toggle("End Time?", isOn: $viewModel.showEndTime)
            if viewModel.showEndTime {
                FullTimePicker(label: "End Time", selection: Binding(
                    get: { viewModel.editor.time_end ?? Date() },
                    set: { viewModel.editor.time_end = $0 }
                ))
            }
        }
    }
    
    private var vehicleSection: some View {
        Section("Vehicle") {
            VehicleSelectorView(
                selectedVehicleId: $viewModel.editor.vehicle_id,
                amDriver: $viewModel.editor.am_driver
            )
        }
    }
    
    private var pathSection: some View {
        Section(header: Text("Path")) {
            PathDisplayView(pathId: viewModel.editor.path_id)
            
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
