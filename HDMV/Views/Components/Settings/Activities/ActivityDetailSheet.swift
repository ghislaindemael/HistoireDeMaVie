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
    
    @State private var isShowingOptionSelector = false

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
                
                Section("Custom Options") {
                    let sortedMappings = viewModel.model.optionMappings.sorted { 
                        if $0.priority == $1.priority {
                            return $0.optionSlug < $1.optionSlug
                        }
                        return $0.priority < $1.priority 
                    }
                    
                    List {
                        ForEach(sortedMappings) { mapping in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(mapping.option?.name ?? mapping.optionSlug)
                                        .font(.headline)
                                    Spacer()
                                    Text("Priority: \(mapping.priority)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Toggle("Required", isOn: Binding(
                                    get: { mapping.required },
                                    set: { newValue in
                                        mapping.required = newValue
                                        mapping.markAsModified()
                                    }
                                ))
                            }
                        }
                        .onMove { indices, newOffset in
                            var mappings = sortedMappings
                            mappings.move(fromOffsets: indices, toOffset: newOffset)
                            for (index, mapping) in mappings.enumerated() {
                                mapping.priority = index
                                mapping.markAsModified()
                            }
                        }
                        .onDelete { indices in
                            for index in indices {
                                let mapping = sortedMappings[index]
                                if let rid = mapping.rid {
                                    Task {
                                        _ = try? await DataActivityOptionMappingService().delete(rid: rid)
                                    }
                                }
                                modelContext.delete(mapping)
                                viewModel.model.optionMappings.removeAll { $0.id == mapping.id }
                            }
                        }
                    }
                    
                    Button("Add Option") {
                        isShowingOptionSelector = true
                    }
                }
                
                
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
            .sheet(isPresented: $isShowingOptionSelector) {
                DataActivityOptionSelectorView { selectedOption in
                    let newMapping = DataActivityOptionMapping(
                        activityRid: viewModel.model.rid ?? 0,
                        optionSlug: selectedOption.slug,
                        priority: viewModel.model.optionMappings.count,
                        syncStatus: .unsynced
                    )
                    newMapping.activity = viewModel.model
                    newMapping.option = selectedOption
                    modelContext.insert(newMapping)
                    viewModel.model.optionMappings.append(newMapping)
                }
            }
        }
    }
    
    
    
}


