//
//  ActivityInstanceDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI
import SwiftData

struct ActivityInstanceDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var instance: ActivityInstance
    // The sheet receives the pre-fetched activity tree.
    let activityTree: [Activity]
    
    // State to manage the optional end time.
    @State private var hasEndTime: Bool
    
    init(instance: ActivityInstance, activityTree: [Activity]) {
        self.instance = instance
        self.activityTree = activityTree
        // Initialize the toggle state based on whether an end time exists.
        _hasEndTime = State(initialValue: instance.time_end != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Activity") {
                    // This now links to a dedicated view for hierarchical selection.
                    NavigationLink(destination: ActivitySelectorView(
                        activityTree: activityTree,
                        selectedActivityId: $instance.activity_id
                    )) {
                        HStack {
                            Text("Select Activity")
                            Spacer()
                            // Display the name of the currently selected activity.
                            if let selectedActivity = findActivity(by: instance.activity_id) {
                                Text(selectedActivity.name)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section("Basics") {
                    // Use the new FullTimePicker component.
                    FullTimePicker(label: "Start Time", selection: $instance.time_start)
                    
                    Toggle("Has End Time", isOn: $hasEndTime)
                    
                    if hasEndTime {
                        FullTimePicker(label: "End Time", selection: .init(
                            get: { instance.time_end ?? instance.time_start },
                            set: { instance.time_end = $0 }
                        ))
                    }
                }
                
                Section("Details") {
                    TextEditor(text: .init(
                        get: { instance.details ?? "" },
                        set: { instance.details = $0.isEmpty ? nil : $0 }
                    ))
                    .lineLimit(3...)
                }

            }
            .navigationTitle(instance.activity_id == nil ? "New Activity" : "Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar(isFormValid: true) {
                instance.syncStatus = .local
                if !hasEndTime {
                    instance.time_end = nil
                }
                try? modelContext.save()
                dismiss()
            }
        }
    }
    
    /// Helper function to find an activity by its ID in the tree.
    private func findActivity(by id: Int?) -> Activity? {
        guard let id = id else { return nil }
        return activityTree.flatMap { $0.flattened() }.first { $0.id == id }
    }
}

// MARK: - Hierarchical Activity Selector View
private struct ActivitySelectorView: View {
    @Environment(\.dismiss) private var dismiss
    let activityTree: [Activity]
    @Binding var selectedActivityId: Int?
    
    var body: some View {
        List {
            Button("None") {
                selectedActivityId = nil
                dismiss()
            }
            
            OutlineGroup(activityTree, children: \.optionalChildren) { activity in
                Button(action: {
                    selectedActivityId = activity.id
                    dismiss()
                }) {
                    ActivityRowView(activity: activity)
                }
            }
        }
        .navigationTitle("Select an Activity")
    }
}

