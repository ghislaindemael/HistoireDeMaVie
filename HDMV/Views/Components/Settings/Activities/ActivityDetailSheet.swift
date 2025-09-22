//
//  ActivityDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.09.2025.
//


import SwiftUI
import SwiftData

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
                
                Section("Capabilities") {
                    ForEach(ActivityCapability.allCases) { capability in
                        VStack(alignment: .leading) {
                            Toggle(capability.label, isOn: Binding(
                                get: { activity.hasCapability(capability) },
                                set: { _ in activity.toggleCapability(capability) }
                            ))
                            
                            if activity.hasCapability(capability) {
                                Toggle("Mark as Required", isOn: Binding(
                                    get: { activity.isRequired(capability) },
                                    set: { _ in activity.toggleRequired(capability) }
                                ))
                                .padding(.leading, 10)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .animation(.default, value: activity.allowedCapabilities)
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


