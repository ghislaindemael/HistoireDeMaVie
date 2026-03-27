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
                TimeSection(editor: $viewModel.editor)
                vehicleSection
                
                Section("Start Place") {
                    PlaceSelectorView(
                        selectedPlace: $viewModel.editor.placeStart,
                        linkedPlaceRid: viewModel.editor.placeStartRid
                    )
                }
                Section("End Place") {
                    PlaceSelectorView(
                        selectedPlace: $viewModel.editor.placeEnd,
                        linkedPlaceRid: viewModel.editor.placeEndRid
                    )
                }
                pathSection
                detailsSection
                
                Section("Companions") {
                    NavigationLink {
                        MultiPersonSelectorView(selectedPersons: $viewModel.editor.persons)
                    } label: {
                        HStack {
                            Text("With")
                            Spacer()
                            Text(viewModel.editor.persons.formattedNames(emptyFallback: "None"))
                                .foregroundStyle(viewModel.editor.persons.isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                        }
                    }
                }
                
                if viewModel.editor.parentInstance != nil || viewModel.editor.parentInstanceRid != nil {
                    Section("Hierarchy") {
                        Button("Remove from Parent", role: .destructive) {
                            viewModel.editor.parentInstance = nil
                            viewModel.editor.parentInstanceRid = nil
                        }
                    }
                }
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
            .sheet(isPresented: $viewModel.isShowingMetricsEditSheet) {
                PathMetricsEditSheet(
                    currentMetrics: viewModel.editor.pathMetrics,
                    onSave: { newMetrics in
                        viewModel.editor.pathMetrics = newMetrics
                    }
                )
            }
            .alert("Name Your Route", isPresented: $viewModel.isShowingPathPromotionAlert) {
                TextField("e.g. Morning Commute", text: $viewModel.newPathName)
                Button("Cancel", role: .cancel) {
                    viewModel.newPathName = ""
                }
                Button("Save Path") {
                    viewModel.promoteToReusablePath()
                }
                .disabled(viewModel.newPathName.trimmingCharacters(in: .whitespaces).isEmpty)
            } message: {
                Text("This will save the GPS track and metrics as a reusable path in your library.")
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var vehicleSection: some View {
        Section("Vehicle") {
            VehicleSelectorView(
                selectedVehicle: $viewModel.editor.vehicle,
                amDriver: $viewModel.editor.amDriver
            )
        }
    }
    
    private var pathSection: some View {
        Section(header: Text("Path & Metrics")) {
            
            PathSelector(
                path: viewModel.editor.path,
                pathRid: viewModel.editor.pathRid,
                isShowingSelector: $viewModel.isShowingPathSelector,
                onSelect: { newPath, newRid in
                    viewModel.editor.path = newPath
                    viewModel.editor.pathRid = newRid
                    viewModel.editor.pathMetrics = nil
                    viewModel.editor.geojsonTrack = nil
                },
                onClear: {
                    viewModel.editor.path = nil
                    viewModel.editor.pathRid = nil
                }
            )
            
                
            if viewModel.editor.geojsonTrack != nil {
                Button {
                    // TODO: Open a full-screen map to view the route
                    print("Show Map View")
                } label: {
                    Label("View GPS Track", systemImage: "map")
                        .foregroundStyle(.blue)
                }
            }
                
            if let metrics = viewModel.editor.pathMetrics {
                PathMetricsRowView(metrics: metrics)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.isShowingMetricsEditSheet = true
                    }
                    
                Button {
                    if viewModel.canPromoteToPath {
                        viewModel.isShowingPathPromotionAlert = true
                    } else {
                        print("Cannot promote: Missing Start Place, End Place, or Metrics.")
                    }
                } label: {
                    Label("Save as Reusable Path", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                        .foregroundStyle(viewModel.canPromoteToPath ? .green : .gray)
                }
                .disabled(!viewModel.canPromoteToPath)
                    
                Button(role: .destructive) {
                    withAnimation {
                        viewModel.editor.pathMetrics = nil
                        viewModel.editor.geojsonTrack = nil
                    }
                } label: {
                    Label("Delete custom metrics", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                    .buttonStyle(.plain)
                    
            } else {
                Button {
                    viewModel.isShowingMetricsEditSheet = true
                } label: {
                    Label("Add Custom Metrics", systemImage: "plus.circle")
                }
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
