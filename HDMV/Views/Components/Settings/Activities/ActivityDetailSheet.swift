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
    
    @Query var activityTree: [Activity]

    init(activity: Activity, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: ActivityDetailSheetViewModel(
            model: activity,
            modelContext: modelContext
        ))
        let predicate = #Predicate<Activity> { $0.parent == nil }
        _activityTree = Query(filter: predicate, sort: \.name)
    }
    
        
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name)
                    TextField("Slug", text: $viewModel.editor.slug)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    HStack {
                        TextField("Icon", text: $viewModel.editor.icon.orEmpty())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Spacer()
                        IconView(iconString: viewModel.editor.icon ?? "")
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
                                get: { viewModel.editor.hasCapability(capability) },
                                set: { _ in viewModel.editor.toggleCapability(capability) }
                            ))
                            
                            if viewModel.editor.hasCapability(capability) {
                                Toggle("Mark as Required", isOn: Binding(
                                    get: { viewModel.editor.isRequired(capability) },
                                    set: { _ in viewModel.editor.toggleRequired(capability) }
                                ))
                                .padding(.leading, 10)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .animation(.default, value: viewModel.editor.allowedCapabilities)
                }

                Section("Usage") {
                    Toggle("Selectable", isOn: $viewModel.editor.selectable)
                    Toggle("Cached", isOn: $viewModel.editor.cache)
                    Toggle("Archived", isOn: $viewModel.editor.archived)
                }
                
                if viewModel.editor.parent != nil || viewModel.editor.parentRid != nil {
                    Section("Hierarchy") {
                        Button("Remove from Parent", role: .destructive) {
                            viewModel.editor.parent = nil
                            viewModel.editor.parentRid = nil
                        }
                    }
                }
                
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
    
    
    
}


