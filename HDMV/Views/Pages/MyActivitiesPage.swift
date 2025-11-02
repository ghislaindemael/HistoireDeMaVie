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
    @EnvironmentObject private var settings: SettingsStore
    
    @StateObject private var viewModel = MyActivitiesPageViewModel()
    
    @State private var instanceToEdit: ActivityInstance?
    @State private var tripToEdit: Trip?
    @State private var interactionToEdit: Interaction?
    
    private func onAppear() {
        if let navDate = appNavigator.selectedDate {
            viewModel.filterDate = navDate
            if settings.planningMode == false {
                appNavigator.selectedDate = nil
            }
        }
        viewModel.setup(modelContext: modelContext)
        viewModel.fetchDailyData()
    }
    
    var body: some View {
        NavigationStack {
            mainListView
                .navigationTitle("My Activities")
                .onAppear(perform: onAppear)
                .syncingOverlay(viewModel.isLoading)
                .logPageToolbar(
                    refreshAction: { await viewModel.syncWithServer() },
                    syncAction: { await viewModel.uploadLocalChanges() },
                    singleTapAction: { viewModel.createActivityInstance() },
                    longPressAction: { viewModel.createActivityInstance(date: viewModel.filterDate) },
                )
                .onChange(of: viewModel.filterMode) { viewModel.fetchDailyData() }
                .onChange(of: viewModel.filterDate) {
                    viewModel.fetchDailyData()
                    appNavigator.selectedDate = viewModel.filterDate
                }
                .onChange(of: viewModel.filterActivity) { viewModel.fetchDailyData() }
                .onChange(of: viewModel.filterStartDate) { viewModel.fetchDailyData() }
                .onChange(of: viewModel.filterEndDate) { viewModel.fetchDailyData() }
                .sheet(item: $instanceToEdit,
                       onDismiss: {viewModel.fetchDailyData()}
                ) { instance in
                    ActivityInstanceDetailSheet(
                        instance: instance,
                        modelContext: modelContext,
                        availableTrips: viewModel.trips,
                        availableInteractions: viewModel.interactions
                    )
                }
                .sheet(item: $tripToEdit) { trip in
                    TripDetailSheet(
                        trip: trip,
                        modelContext: modelContext
                    )
                }
                .sheet(item: $interactionToEdit) { interaction in
                    InteractionDetailSheet(
                        interaction: interaction,
                        modelContext: modelContext
                    )
                }
        }
        .environmentObject(viewModel)
    }
    
    private var mainListView: some View {
        VStack(spacing: 12) {
            FilterControlView(viewModel: viewModel)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    let topLevelInstances = viewModel.instances.filter { $0.parent == nil }
                    
                    ForEach(topLevelInstances) { instance in
                        ActivityHierarchyView(
                            instance: instance,
                            level: 0,
                            instanceToEdit: $instanceToEdit,
                            tripToEdit: $tripToEdit,
                            interactionToEdit: $interactionToEdit
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    
}

