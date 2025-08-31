//
//  MyActivitiesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct MyActivitiesPage: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appNavigator: AppNavigator
    
    @StateObject private var viewModel = MyActivitiesPageViewModel()
    
    @State private var instanceToEdit: ActivityInstance?
    @State private var tripLegToEdit: TripLeg?
    
    var body: some View {
        NavigationStack {
            mainListView
                .navigationTitle("My Activities")
                .logPageToolbar(
                    refreshAction: { await viewModel.syncWithServer() },
                    syncAction: { await viewModel.uploadLocalChanges() },
                    addNowAction: { viewModel.createNewInstanceInCache() },
                    addAtNoonAction: { viewModel.createNewInstanceAtNoonInCache() },
                    hasLocalChanges: viewModel.hasLocalChanges
                )
                .task(id: viewModel.selectedDate) {
                    viewModel.fetchLocalDataForSelectedDate()
                }
                .onAppear {
                    if let navDate = appNavigator.selectedDate {
                        viewModel.selectedDate = navDate
                        appNavigator.selectedDate = nil
                    }
                    viewModel.setup(modelContext: modelContext)
                }
                .sheet(item: $instanceToEdit) { instance in
                    ActivityInstanceDetailSheet(
                        instance: instance,
                        viewModel: viewModel,
                    )
                }
                .sheet(item: $tripLegToEdit) { leg in
                    TripLegDetailSheet(
                        tripLeg: leg,
                        vehicles: viewModel.vehicles,
                        cities: viewModel.cities,
                        places: viewModel.places
                    )
                }
                .syncingOverlay(viewModel.isLoading)
            
        }
    }
    
    private var mainListView: some View {
        VStack(spacing: 12) {
            DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                .padding(.horizontal)
            
            List {
                ForEach($viewModel.instances) { $instance in
                    VStack {
                        let activity = viewModel.findActivity(by: instance.activity_id)
                        let instanceTripLegs = viewModel.tripLegs(for: instance.id)
                        let instanceVehicles = viewModel.tripsVehicles(for: instanceTripLegs)
                        let instancePlaces = viewModel.tripsPlaces(for: instanceTripLegs)
                        let hasActiveLegs = instanceTripLegs.contains { $0.time_end == nil }
                        
                        ActivityInstanceRowView(
                            instance: instance,
                            activity: activity,
                            tripLegs: instanceTripLegs,
                            tripLegsVehicles: instanceVehicles,
                            tripLegsPlaces: instancePlaces,
                            onStartTripLeg: { parentId in
                                viewModel.createNewTripLegInCache(parent_id: parentId)
                            },
                            onEditTripLeg: { leg in
                                self.tripLegToEdit = leg
                            },
                            onEndTripLeg: { leg in
                                viewModel.endTripLeg(leg: leg)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            instanceToEdit = instance
                        }
                        if instance.time_end == nil && !hasActiveLegs {
                            EndItemButton(title: "End Activity") {
                                viewModel.endActivityInstance(instance: instance)
                            }
                        }
                    }
                    
                }
            }
            
        }
    }
}
