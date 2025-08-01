//
//  NewActivitySheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//


import SwiftUI

struct NewActivitySheet: View {
    @ObservedObject var viewModel: ActivitiesPageViewModel
    
    @State private var name: String = ""
    @State private var slug: String = ""
    @State private var selectedParent: Activity?
    @State private var icon: String = ""
    @State private var type: ActivityType = .generic
    
    @Environment(\.dismiss) private var dismiss
    
    private var isFormValid: Bool { !name.isEmpty && !slug.isEmpty }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Activity Details") {
                    TextField("Name", text: $name)
                    TextField("Slug", text: $slug)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("Icon", text: $icon)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Picker("Type", selection: $type) {
                        ForEach(ActivityType.allCases, id: \.self) { activityType in
                            Text(activityType.rawValue.capitalized).tag(activityType)
                        }
                    }
                }
                
                Section("Parent Activity") {
                    NavigationLink(destination: ParentSelectorView(
                        activities: viewModel.activityTree,
                        selectedParent: $selectedParent)
                    ) {
                        HStack {
                            Text("Parent")
                            Spacer()
                            Text(selectedParent?.name ?? "Top Level")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Activity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let iconForPayload = icon.trimmingCharacters(in: .whitespaces).isEmpty
                            ? (selectedParent?.icon ?? "")
                            : icon
                            
                            let payload = NewActivityPayload(
                                name: name,
                                slug: slug,
                                parent_id: selectedParent?.id,
                                icon: iconForPayload,
                                type: type
                            )
                            await viewModel.createActivity(payload: payload)
                            dismiss()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
}

struct ParentSelectorView: View {
    let activities: [Activity]
    @Binding var selectedParent: Activity?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Button("Top Level") {
                selectedParent = nil
                dismiss()
            }
            
            OutlineGroup(activities, children: \.optionalChildren) { activity in
                Button(action: {
                    selectedParent = activity
                    dismiss()
                }) {
                    HStack {
                        IconView(iconString: activity.icon)
                            .foregroundStyle(.primary)
                        Text(activity.name)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("Select Parent")
    } 
}
