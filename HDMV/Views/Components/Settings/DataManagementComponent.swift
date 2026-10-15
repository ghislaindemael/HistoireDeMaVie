//  DataManagementComponent.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.06.2025.
//  Updated on 19.07.2025.
//

import SwiftUI
import SwiftData

struct DataManagementComponent: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var isRepairingRelationships: Bool = false
    @State private var isExpanded: Bool = false
    
    private let modelTypes: [any PersistentModel.Type] = [
        ActivityInstance.self,
        Trip.self,
        Transaction.self,
        Interaction.self,
        LifeEvent.self,
        Quote.self,
        AgendaEntry.self,
        VaultTask.self
    ]
    
    init(expanded: Bool = false) {
        _isExpanded = State(initialValue: expanded)
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 4) {
                Button {
                    Task {
                        isRepairingRelationships = true
                        do {
                            try ActivityInstanceSyncer(modelContext: modelContext).resolveRelationships()
                            try TripSyncer(modelContext: modelContext).resolveRelationships()
                            try LifeEventSyncer(modelContext: modelContext).resolveRelationships()
                            try TransactionSyncer(modelContext: modelContext).resolveRelationships()
                            try InteractionSyncer(modelContext: modelContext).resolveRelationships()
                            try QuoteSyncer(modelContext: modelContext).resolveRelationships()
                            if modelContext.hasChanges {
                                try modelContext.save()
                            }
                            ToastManager.shared.showToast(message: "Relationships Repaired", systemImage: "checkmark.shield.fill", color: .green)
                        } catch {
                            print("❌ Failed to repair relationships: \(error)")
                            ToastManager.shared.showToast(message: "Repair Failed", systemImage: "xmark.shield.fill", color: .red)
                        }
                        isRepairingRelationships = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(isRepairingRelationships ? "Resolving Relationships..." : "Resolve Relationships & Links")
                        Spacer()
                        if isRepairingRelationships {
                            ProgressView()
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
                
                Divider()
                ForEach(modelTypes.indices, id: \.self) { index in
                    let modelType = modelTypes[index]
                    ModelRow(modelType: modelType)
                    
                    if index < modelTypes.count - 1 {
                        Divider()
                    }
                }
                
                Divider()
                IconCacheRow()
                
            }
            .padding(.top, 8)
        } label: {
            Text("Cache")
                .foregroundColor(.red)
                .font(.headline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red, lineWidth: 1)
        )
    }
    
    /// A private view for each row to keep the body clean.
    private func ModelRow(modelType: any PersistentModel.Type) -> some View {
        NavigationLink {
            DataWipeDetailView(modelType: modelType)
        } label: {
            HStack {
                Text(String(describing: modelType))
                Spacer()
                Text("\(fetchCount(for: modelType))")
                    .fontWeight(.bold)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        
    }
    
    private func IconCacheRow() -> some View {
        NavigationLink {
            IconCacheManagerView()
        } label: {
            HStack {
                Text("SVG Icons")
                    .foregroundColor(.purple)
                Spacer()
                IconCacheCountView()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Data Operations
        
    /// Fetches the current count for a given model type from the context.
    /// This function remains largely the same as it is the most type-safe approach.
    private func fetchCount<T: PersistentModel>(for modelType: T.Type) -> Int {
        do {
            return try modelContext.fetchCount(FetchDescriptor<T>())
        } catch {
            print("❌ Failed to fetch count for \(modelType): \(error)")
            return 0
        }
    }
}


#Preview {
    NavigationStack {
        VStack {
            DataManagementComponent(expanded: true)
            Spacer()
        }
        .padding()
    }
    .modelContainer(for: [AgendaEntry.self, Trip.self, City.self, Place.self, Person.self, Interaction.self, LifeContext.self, Quote.self])
}

struct IconCacheCountView: View {
    @State private var cacheCount: Int = 0
    
    var body: some View {
        Text("\(cacheCount)")
            .fontWeight(.bold)
            .onAppear {
                updateCount()
            }
    }
    
    private func updateCount() {
        Task {
            self.cacheCount = await IconCacheService.shared.getCacheCount()
        }
    }
}
