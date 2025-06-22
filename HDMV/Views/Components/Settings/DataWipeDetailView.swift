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
    @Environment(\.dismiss) private var dismiss
    
    /// The specific model type this view will manage (e.g., Meal.self).
    let modelType: any PersistentModel.Type
    
    @State private var count: Int = 0
    @State private var isShowingConfirmAlert = false
    
    private var modelName: String {
        String(describing: modelType)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("This tool will permanently delete all data for the selected model type.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                Text("Objects to delete:")
                Spacer()
                Text("\(count)")
                    .font(.title.bold())
            }
            
            Spacer()
            
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
        .onAppear(perform: fetchCount)
        .alert("Are you sure?", isPresented: $isShowingConfirmAlert) {
            Button("Delete All", role: .destructive, action: deleteAllData)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You are about to permanently delete \(count) \(modelName) objects. This action cannot be undone.")
        }
    }
    
    /// Fetches the count of objects for the current model type.
    private func fetchCount() {
        do {
            switch modelType {
                case is Meal.Type:
                    let descriptor = FetchDescriptor<Meal>()
                    count = try modelContext.fetchCount(descriptor)
                case is AgendaEntry.Type:
                    let descriptor = FetchDescriptor<AgendaEntry>()
                    count = try modelContext.fetchCount(descriptor)
                case is Trip.Type:
                    let descriptor = FetchDescriptor<Trip>()
                    count = try modelContext.fetchCount(descriptor)
                default:
                    print("Warning: Unhandled model type in fetchCount: \(modelType)")
                    count = 0
            }
        } catch {
            print("Failed to fetch count for \(modelName): \(error)")
            count = 0
        }
        
    }
    
    /// Performs the deletion of all objects for the current model type.
    private func deleteAllData() {
        do {
            try modelContext.delete(model: modelType)
            print("Successfully deleted all \(modelName) objects.")
            fetchCount()
        } catch {
            print("Failed to delete \(modelName) objects: \(error)")
        }
    }
}


#Preview {
    NavigationStack {
        // Example for previewing with the Meal model
        DataWipeDetailView(modelType: Meal.self)
    }
    .modelContainer(for: Meal.self)
}
