//
//  ActivityDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.09.2025.
//


import SwiftUI
import SwiftData

struct PermissionOption: Identifiable {
    let id: String
    let label: String
}

let availablePermissions: [PermissionOption] = [
    .init(id: "trips", label: "Can create Trip Legs"),
    .init(id: "people", label: "Can create Interactions"),
    .init(id: "place", label: "Can attach Place")
]


struct ActivityDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    /// Use @Bindable to allow direct two-way editing of the model object.
    @Bindable var activity: Activity
        
    /// Pass the viewModel to get the list of possible parent activities.
    @ObservedObject var viewModel: ActivitiesPageViewModel
    
    private var parentName: String {
        if let parentId = activity.parent_id,
           let parent = viewModel.allActivities.first(where: { $0.id == parentId }) {
            return parent.name
        }
        return "Top Level"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $activity.name)
                    TextField("Slug", text: $activity.slug)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    HStack {
                        TextField("Icon", text: $activity.icon)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Spacer()
                        IconView(iconString: activity.icon)
                    }
                    NavigationLink(destination: ParentActivitySelector(
                        activities: viewModel.activityTree,
                        selectedParentId: $activity.parent_id)
                    ) {
                        HStack {
                            Text("Parent")
                            Spacer()
                            Text(parentName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Permissions") {
                    ForEach(availablePermissions) { option in
                        Toggle(option.label, isOn: activity.binding(for: option.id))
                    }
                }

                
                Section("Usage") {
                    Toggle("Selectable", isOn: $activity.selectable)
                    Toggle("Cached", isOn: $activity.cache)
                    Toggle("Archived", isOn: $activity.archived)
                }
                
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar(isFormValid: !activity.name.isEmpty) {
                await onDone()
            }
        }
    }
    
    /// Handles the logic when the "Done" button is tapped.
    private func onDone() async {
        activity.syncStatus = .local
        
        do {
            try modelContext.save()
            print("✅ Activity '\(activity.name)' saved to context.")
        } catch {
            print("❌ Failed to save activity to context: \(error)")
        }
        
    }
    
    
}


