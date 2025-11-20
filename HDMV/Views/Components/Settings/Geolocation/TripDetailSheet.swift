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
                path: $viewModel.editor.path,
                pathRid: $viewModel.editor.pathRid,
                isShowingSelector: $viewModel.isShowingPathSelector
            )
            
            if viewModel.editor.path == nil {
                
                if let metrics = viewModel.editor.pathMetrics {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Metrics Set")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            Label("\(metrics.distance.formatted()) m", systemImage: "ruler")
                            Label("+\(metrics.elevationGain.formatted()) m", systemImage: "arrow.up.right")
                            Label("-\(metrics.elevationLoss.formatted()) m", systemImage: "arrow.down.right")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        Divider().padding(.vertical, 4)
                        
                        HStack {
                            Button("Edit") {
                                viewModel.isShowingMetricsEditSheet = true
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                withAnimation {
                                    viewModel.editor.pathMetrics = nil
                                }
                            } label: {
                                Text("Remove")
                                    .foregroundStyle(.red)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                    
                } else {
                    Button {
                        viewModel.isShowingMetricsEditSheet = true
                    } label: {
                        Label("Add Custom Metrics", systemImage: "plus.circle")
                    }
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
