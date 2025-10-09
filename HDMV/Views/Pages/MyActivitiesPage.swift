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
    
    private func onAppear() {
        if let navDate = appNavigator.selectedDate {
            viewModel.selectedDate = navDate
            appNavigator.selectedDate = nil
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
                    singleTapAction: { viewModel.createActivtiyInstance() },
                    longPressAction: { viewModel.createActivityInstanceForDate() },
                )
                .onChange(of: viewModel.filterMode) { viewModel.fetchDailyData() }
                .onChange(of: viewModel.selectedDate) { viewModel.fetchDailyData() }
                .onChange(of: viewModel.filterActivityId) { viewModel.fetchDailyData() }
                .onChange(of: viewModel.filterStartDate) { viewModel.fetchDailyData() }
                .onChange(of: viewModel.filterEndDate) { viewModel.fetchDailyData() }
                .sheet(item: $instanceToEdit) { instance in
                    ActivityInstanceDetailSheet(
                        instance: instance,
                        viewModel: viewModel,
                    )
                }
                .sheet(item: $tripLegToEdit) { leg in
                    TripLegDetailSheet(tripLeg: leg)
                }
                .sheet(item: $interactionToEdit) { interaction in
                    PersonInteractionEditSheet(interaction: interaction)
                }
        }
        .environmentObject(viewModel)
    }
    
    private var mainListView: some View {
        VStack(spacing: 12) {
            FilterControlView(viewModel: viewModel)
            
            List {
                let topLevelInstances = viewModel.instances.filter { $0.parent == nil }
                
                ForEach(topLevelInstances) { instance in
                    ActivityHierarchyView(
                        instance: instance,
                        level: 0,
                        instanceToEdit: $instanceToEdit,
                        tripLegToEdit: $tripLegToEdit,
                        interactionToEdit: $interactionToEdit
                    )
                }
            }
        }
    }
    
    
}
