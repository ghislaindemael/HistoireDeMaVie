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
    
    @StateObject private var viewModel: ActivityDetailSheetViewModel
    
    let activity: Activity
    @Query var activityTree: [Activity]

    
    init(activity: Activity, modelContext: ModelContext) {
        self.activity = activity
        _viewModel = StateObject(wrappedValue: ActivityDetailSheetViewModel(activity: activity, modelContext: modelContext))
        let predicate = #Predicate<Activity> { $0.parent == nil }
        _activityTree = Query(filter: predicate, sort: \.name)
    }
    
        
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name.orEmpty())
                    TextField("Slug", text: $viewModel.editor.slug.orEmpty())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    HStack {
                        TextField("Icon", text: $viewModel.editor.icon.orEmpty())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Spacer()
                        IconView(iconString: activity.icon ?? "")
                    }
                    NavigationLink(destination: ParentActivitySelector(
                        activities: activityTree,
                        selectedParent: $viewModel.editor.parent)
                    ) {
                        HStack {
                            Text("Parent Activity")
                            Spacer()
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
                    Toggle("Selectable", isOn: $viewModel.editor.selectable)
                    Toggle("Cached", isOn: $viewModel.editor.cache)
                    Toggle("Archived", isOn: $viewModel.editor.archived)
                }
                
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                await onDone()
            }
        }
    }
    
    /// Handles the logic when the "Done" button is tapped.
    private func onDone() async {
        activity.markAsModified()
        
        do {
            try modelContext.save()
            print("✅ Activity '\(activity.name ?? "TOSET")' saved to context.")
        } catch {
            print("❌ Failed to save activity to context: \(error)")
        }
        
    }
    
    
}


