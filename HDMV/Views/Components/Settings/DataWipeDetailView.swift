//
//  DataWipeDetailView.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.06.2025.
//

import SwiftUI
import SwiftData

extension PersistentModel {
    static func fetchAllErased(from context: ModelContext, limit: Int? = nil, offset: Int? = nil) throws -> [any PersistentModel] {
        var descriptor = FetchDescriptor<Self>()
        if let limit = limit { descriptor.fetchLimit = limit }
        if let offset = offset { descriptor.fetchOffset = offset }
        return try context.fetch(descriptor)
    }
    
    static func chunkedDelete(from context: ModelContext, filter: DataWipeDetailView.FilterOption) throws {
        if filter == .all {
            try context.delete(model: Self.self)
            try context.save()
            return
        }
        
        var offset = 0
        let batchSize = 500
        while true {
            var descriptor = FetchDescriptor<Self>()
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset
            let batch = try context.fetch(descriptor)
            if batch.isEmpty { break }
            
            var deletedCount = 0
            for item in batch {
                if let syncable = item as? any SyncableModel {
                    let isSynced = syncable.syncStatus == .synced
                    let matches = (filter == .synced && isSynced) || (filter == .unsynced && !isSynced)
                    if matches {
                        context.delete(item)
                        deletedCount += 1
                    }
                }
            }
            
            if deletedCount > 0 {
                try context.save()
                // If we deleted items, the remaining items shifted up, so we don't increase offset
            } else {
                offset += batchSize
            }
        }
    }
}

struct DataWipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appNavigator: AppNavigator
    @Environment(\.dismiss) private var dismiss
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case synced = "Synced"
        case unsynced = "Unsynced"
        
        var id: String { self.rawValue }
    }
    
    @State private var items: [any PersistentModel] = []
    
    
    /// The specific model type this view will manage (e.g., Meal.self).
    let modelType: any PersistentModel.Type
    
    @State private var count: Int = 0
    @State private var selectedFilter: FilterOption = .all
    @State private var isShowingConfirmAlert = false
    
    @State private var currentPage: Int = 0
    private let pageSize: Int = 50
    
    private var modelName: String {
        String(describing: modelType)
    }
    
    private var unsyncedItemsCount: Int {
        let syncableItems = items.compactMap { $0 as? any SyncableModel }
        return syncableItems.filter { $0.syncStatus != .synced }.count
    }
    
    private var filteredItems: [any PersistentModel] {
        switch selectedFilter {
        case .all:
            return items
        case .synced:
            return items.filter { ($0 as? any SyncableModel)?.syncStatus == .synced }
        case .unsynced:
            return items.filter {
                if let syncable = $0 as? any SyncableModel {
                    return syncable.syncStatus != .synced
                }
                return false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("Status Filter", selection: $selectedFilter) {
                ForEach(FilterOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            List {
                ForEach(filteredItems, id: \.persistentModelID) { item in
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
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
            .listStyle(.plain)
            
            HStack {
                Button("Previous") {
                    if currentPage > 0 {
                        currentPage -= 1
                        fetchItems()
                    }
                }
                .disabled(currentPage == 0)
                
                Spacer()
                Text("Page \(currentPage + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                
                Button("Next") {
                    if (currentPage + 1) * pageSize < count {
                        currentPage += 1
                        fetchItems()
                    }
                }
                .disabled((currentPage + 1) * pageSize >= count)
            }
            .padding(.horizontal)
            
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
                if selectedFilter == .synced {
                    Label("Delete Synced Objects (\(filteredItems.count))", systemImage: "trash.fill")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                } else if selectedFilter == .unsynced {
                    Label("Delete Unsynced Objects (\(filteredItems.count))", systemImage: "trash.fill")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Delete All \(modelName) Objects (\(count))", systemImage: "trash.fill")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(filteredItems.isEmpty)
        }
        .padding()
        .navigationTitle(modelName)
        .onAppear(perform: fetchItems)
        .alert("Are you sure?", isPresented: $isShowingConfirmAlert) {
            Button("Delete", role: .destructive, action: deleteAllData)
            Button("Cancel", role: .cancel) { }
        } message: {
            if selectedFilter == .all {
                Text("You are about to permanently delete \(filteredItems.count) \(modelName) objects. This action cannot be undone.")
            } else {
                Text("You are about to permanently delete \(filteredItems.count) \(selectedFilter.rawValue) \(modelName) objects. This action cannot be undone.")
            }
        }
    }
    
    /// Fetches the count of objects for the current model type.
    private func fetchItems() {
        do {
            let results = try modelType.fetchAllErased(from: modelContext, limit: pageSize, offset: currentPage * pageSize)
            
            // Apply dynamic sorting if applicable
            if let timeTrackable = results as? [any TimeTrackable] {
                self.items = timeTrackable.sorted { $0.timeStart > $1.timeStart } as! [any PersistentModel]
            } else if let activites = results as? [Activity] {
                self.items = activites.sorted { $0.name < $1.name }
            } else if let places = results as? [Place] {
                self.items = places.sorted { $0.name < $1.name }
            } else if let vehicles = results as? [Vehicle] {
                self.items = vehicles.sorted { ($0.name ?? "") < ($1.name ?? "") }
            } else {
                self.items = results
            }
            
            // Re-fetch the total count to ensure accurate pagination bounds
            self.count = fetchTotalCount()
            
        } catch {
            print("Failed to fetch items for \(modelName): \(error)")
            self.items = []
            self.count = 0
        }
    }
    
    private func fetchTotalCount() -> Int {
        do {
            let results = try modelType.fetchAllErased(from: modelContext, limit: nil, offset: nil)
            return results.count
        } catch {
            return 0
        }
    }

    
    
    /// Performs the deletion of objects based on the current filter.
    private func deleteAllData() {
        do {
            try modelType.chunkedDelete(from: modelContext, filter: selectedFilter)
            print("Successfully executed batch wipe for \(modelName).")
            
            // Reset to page 0 after mass delete
            currentPage = 0
            fetchItems()
            
        } catch {
            print("Failed to batch delete \(modelName) objects: \(error)")
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
        if let lifeEvent = item as? LifeEvent {
            appNavigator.selectedDate = lifeEvent.timeStart
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
