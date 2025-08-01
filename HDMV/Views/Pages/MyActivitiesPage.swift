//
//  ActivityInstancesPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct MyActivitiesPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = MyActivitiesPageViewModel()
    
    // The @Query is now the single source of truth for the list
    @Query private var instances: [ActivityInstance]
    @Query(sort: [SortDescriptor<Activity>(\.name)]) private var activities: [Activity]
    
    @State private var instanceToEdit: ActivityInstance?
    @State private var selectedDate: Date = .now
    
    var body: some View {
        NavigationStack {
            mainListView
                .navigationTitle("My Activities")
                .logPageToolbar(
                    refreshAction: {
                        await viewModel.syncWithServer(for: selectedDate)
                    },
                    syncAction: {
                        await viewModel.syncChanges()
                    },
                    addNowAction: {
                        viewModel.createNewInstanceInCache()
                    },
                    addAtNoonAction: {
                        viewModel.createNewInstanceAtNoonInCache(for: selectedDate)
                    },
                    hasLocalChanges: viewModel.hasLocalChanges
                )
                .task(id: selectedDate) {
                    await viewModel.syncWithServer(for: selectedDate)
                }
                .onAppear {
                    viewModel.setup(modelContext: modelContext)
                }
                .sheet(item: $instanceToEdit) { instance in
                    ActivityInstanceDetailSheet(
                        instance: instance,
                        activityTree: viewModel.activityTree
                    )
                }
                .overlay {
                    if viewModel.isLoading { ProgressView() }
                }
        }
    }
        
    
    
    private var mainListView: some View {
        VStack(spacing: 12) {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .padding(.horizontal)
            
            List {
                ForEach(viewModel.instances) { instance in
                    ActivityInstanceRowView(instance: instance, activities: activities)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            instanceToEdit = instance
                        }
                }
            }
        }
    }
    
    private var filteredInstances: [ActivityInstance] {
        instances.filter { instance in
            Calendar.current.isDate(instance.time_start, inSameDayAs: selectedDate)
        }
    }
}
