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
    @State private var interactionToEdit: PersonInteraction?
    
    var body: some View {
        NavigationStack {
            mainListView
                .navigationTitle("My Activities")
                .onAppear(perform: onAppear)
                .syncingOverlay(viewModel.isLoading)
                .logPageToolbar(
                    refreshAction: { await viewModel.syncWithServer() },
                    hasLocalChanges: viewModel.hasLocalChanges,
                    syncAction: { await viewModel.uploadLocalChanges() },
                    singleTapAction: { viewModel.createActivtiyInstance() },
                    longPressAction: { viewModel.createActivityInstanceForDate() },
                )
                .onChange(of: viewModel.filterMode) { viewModel.fetchInstances() }
                .onChange(of: viewModel.selectedDate) { viewModel.fetchInstances() }
                .onChange(of: viewModel.filterActivityId) { viewModel.fetchInstances() }
                .onChange(of: viewModel.filterStartDate) { viewModel.fetchInstances() }
                .onChange(of: viewModel.filterEndDate) { viewModel.fetchInstances() }
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
        }
    }
    
    private var mainListView: some View {
        VStack(spacing: 12) {
            FilterControlView(viewModel: viewModel)
            
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
                            selectedDate: viewModel.selectedDate,
                            onStartTripLeg: { parentId in
                                viewModel.createTripLeg(parent_id: parentId)
                            },
                            onEditTripLeg: { leg in
                                self.tripLegToEdit = leg
                            },
                            onEndTripLeg: { leg in
                                viewModel.endTripLeg(leg: leg)
                            },
                            onStartInteraction: { parentId in
                                viewModel.createInteraction(parent_id: parentId)
                            },
                            onEditInteraction: { interaction in
                                self.interactionToEdit = interaction
                            },
                            onEndInteraction: { interaction in
                                viewModel.endInteraction(interaction: interaction)
                                
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
    
    private func onAppear() {
        if let navDate = appNavigator.selectedDate {
            viewModel.selectedDate = navDate
            appNavigator.selectedDate = nil
        }
        viewModel.setup(modelContext: modelContext)
        viewModel.fetchInstances()
    }
}
