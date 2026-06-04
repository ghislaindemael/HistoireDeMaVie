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

    let trip: Trip
    
    init(trip: Trip, modelContext: ModelContext) {
        self.trip = trip
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
                
                Section(header: headerView("Start Place")) {
                    PlaceSelectorView(
                        selectedPlace: $viewModel.editor.placeStart,
                        linkedPlaceRid: viewModel.editor.placeStartRid,
                        selectedVehicle: viewModel.editor.vehicle
                    )
                }
                Section(header: headerView("End Place")) {
                    PlaceSelectorView(
                        selectedPlace: $viewModel.editor.placeEnd,
                        linkedPlaceRid: viewModel.editor.placeEndRid,
                        selectedVehicle: viewModel.editor.vehicle
                    )
                }
                pathSection
                detailsSection
                
                Section(header: headerView("Companions")) {
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
                
                HierarchySectionView(
                    model: trip,
                    hasParent: !viewModel.editor.hasNoParent(),
                    onRemoveFromParent: {
                        viewModel.editor.clearParents()
                    }
                )
                
                OrphanLogItemConnector(
                    parent: trip,
                    showTrips: false,
                    showInteractions: true,
                    showLifeEvents: true
                )
            }
            .scrollDismissesKeyboard(.interactively)
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
            .sheet(isPresented: $viewModel.isShowingTransitLineSelector) {
                TransitLineSelectorSheet(
                    selectedVehicle: viewModel.editor.vehicle,
                    onSelect: viewModel.selectTransitLine
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
        Section(header: headerView("Vehicle")) {
            VehicleSelectorView(
                selectedVehicle: $viewModel.editor.vehicle,
                amDriver: $viewModel.editor.amDriver
            )
        }
    }
    
    private func headerView(_ title: String) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
    
    private var pathSection: some View {
        Section(header: headerView("Path & Metrics")) {
            
            PathSelector(
                path: viewModel.editor.path,
                pathRid: viewModel.editor.pathRid,
                isShowingSelector: $viewModel.isShowingPathSelector,
                onSelect: { newPath, newRid in
                    viewModel.selectPath(path: newPath)
                },
                onClear: {
                    viewModel.editor.path = nil
                    viewModel.editor.pathRid = nil
                }
            )
            
            if viewModel.editor.path == nil && viewModel.editor.pathRid == nil {
                TransitLineSelector(
                    transitLine: viewModel.editor.transitLine,
                    transitLineRid: viewModel.editor.transitLineRid,
                    isShowingSelector: $viewModel.isShowingTransitLineSelector,
                    onSelect: { newLine, newRid in
                        viewModel.selectTransitLine(line: newLine)
                    },
                    onClear: {
                        viewModel.editor.transitLine = nil
                        viewModel.editor.transitLineRid = nil
                    }
                )
            }
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
                
                if viewModel.canCalculateDistanceFromTransit {
                    Button {
                        viewModel.calculateDistanceFromTransit()
                    } label: {
                        Label("Calculate Distance from Line", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                            .foregroundStyle(.blue)
                    }
                }
            }
            
        }
    }
    
    private var detailsSection: some View {
        Section(header: headerView("Details")) {
            TextField("Details", text: $viewModel.editor.details.bound, axis: .vertical)
                .lineLimit(4...)
        }
    }
    
    
}
