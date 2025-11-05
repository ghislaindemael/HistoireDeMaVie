//
//  DataWipeDetailView.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.06.2025.
//

import SwiftUI
import SwiftData

struct DataWipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appNavigator: AppNavigator
    @Environment(\.dismiss) private var dismiss
    
    @State private var items: [any PersistentModel] = []
    
    
    /// The specific model type this view will manage (e.g., Meal.self).
    let modelType: any PersistentModel.Type
    
    @State private var count: Int = 0
    @State private var isShowingConfirmAlert = false
    
    private var modelName: String {
        String(describing: modelType)
    }
    
    private var unsyncedItemsCount: Int {
        let syncableItems = items.compactMap { $0 as? any SyncableModel }
        return syncableItems.filter { $0.syncStatus != .synced }.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            List {
                ForEach(items, id: \.persistentModelID) { item in
                    Button(action: {
                        navigateToItem(item)
                    }) {
                        describeView(for: item)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            
            HStack {
                Text("Total objects: ")
                Spacer()
                Text("\(count)")
                    .font(.title2.bold())
            }
            HStack {
                Text("Unsnyced items: ")
                Spacer()
                Text("\(unsyncedItemsCount)")
                    .font(.title2.bold())
            }
                                    
            Button(role: .destructive) {
                isShowingConfirmAlert = true
            } label: {
                Label("Delete All \(modelName) Objects", systemImage: "trash.fill")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(count == 0)
        }
        .padding()
        .navigationTitle(modelName)
        .onAppear(perform: fetchItems)
        .alert("Are you sure?", isPresented: $isShowingConfirmAlert) {
            Button("Delete All", role: .destructive, action: deleteAllData)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You are about to permanently delete \(count) \(modelName) objects. This action cannot be undone.")
        }
    }
    
    /// Fetches the count of objects for the current model type.
    private func fetchItems() {
        do {
            switch modelType {
                case is Activity.Type:
                    let descriptor = FetchDescriptor<Activity>(
                        sortBy: [SortDescriptor(\Activity.name)]
                    )
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is ActivityInstance.Type:
                    let descriptor = FetchDescriptor<ActivityInstance>(
                        sortBy: [SortDescriptor(\ActivityInstance.timeStart, order: .reverse)]
                    )
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is AgendaEntry.Type:
                    let descriptor = FetchDescriptor<AgendaEntry>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is Trip.Type:
                    let descriptor = FetchDescriptor<Trip>(
                        sortBy: [SortDescriptor(\Trip.timeStart, order: .reverse)]
                    )
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is Country.Type:
                    let descriptor = FetchDescriptor<Country>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is City.Type:
                    let descriptor = FetchDescriptor<City>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is Path.Type:
                    let descriptor = FetchDescriptor<Path>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is Place.Type:
                    let descriptor = FetchDescriptor<Place>(
                        sortBy: [SortDescriptor(\.name)]
                    )
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is Person.Type:
                    let descriptor = FetchDescriptor<Person>()
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is Interaction.Type:
                    let descriptor = FetchDescriptor<Interaction>(
                        sortBy: [SortDescriptor(\Interaction.timeStart, order: .reverse)]
                    )
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                case is Vehicle.Type:
                    let descriptor = FetchDescriptor<Vehicle>(
                        sortBy: [SortDescriptor(\.name)]
                    )
                    let results = try modelContext.fetch(descriptor)
                    items = results
                    count = results.count
                default:
                    print("Warning: Unhandled model type in fetchItems: \(modelType)")
                    items = []
                    count = 0
            }
        } catch {
            print("Failed to fetch items: \(error)")
            items = []
            count = 0
        }
    }
    
    
    /// Performs the deletion of all objects for the current model type.
    private func deleteAllData() {
        do {
            try modelContext.delete(model: modelType)
            print("Successfully deleted all \(modelName) objects.")
            fetchItems()
        } catch {
            print("Failed to delete \(modelName) objects: \(error)")
        }
    }
    
    private func describeView(for item: any PersistentModel) -> AnyView {
        if let debugItem = item as? any DebugViewable {
            return debugItem.erasedDebugView
        } else {
            return AnyView(
                VStack {
                    Text("⚠️ Model is not DebugViewable")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("Type: \(String(describing: type(of: item)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                    .padding()
            )
        }
    }
    
    private func deleteItem(_ item: any PersistentModel) {
        modelContext.delete(item)
        do {
            try modelContext.save()
            fetchItems()
        } catch {
            print("Failed to delete item: \(error)")
        }
    }
    
    private func navigateToItem(_ item: any PersistentModel) {
        if let instance = item as? ActivityInstance {
            appNavigator.selectedDate = instance.timeStart
            appNavigator.selectedTab = .activities
            dismiss()
        }
        if let interaction = item as? Interaction {
            appNavigator.selectedDate = interaction.timeStart
            if interaction.parentInstanceRid != nil {
                appNavigator.selectedTab = .activities
            } else {
                appNavigator.selectedTab = .interactions
            }
            dismiss()
        }
        if let trip = item as? Trip {
            appNavigator.selectedDate = trip.timeStart
            appNavigator.selectedTab = .activities
            dismiss()
        }
    }
}


#Preview {
    NavigationStack {
        DataWipeDetailView(modelType: AgendaEntry.self)
    }
    .modelContainer(for: AgendaEntry.self)
}
