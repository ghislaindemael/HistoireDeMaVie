//
//  ActivitySelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 03.09.2025.
//

import SwiftUI
import SwiftData

struct ActivitySelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedActivity: Activity?
    
    @Query var activityTree: [Activity]
    
    init(selectedActivity: Binding<Activity?>) {
        _selectedActivity = selectedActivity        
        let predicate = #Predicate<Activity> { $0.parentRid == nil }
        _activityTree = Query(filter: predicate, sort: \.name)
    }
    
    
    var body: some View {
        List {
            Button("None") {
                selectedActivity = nil
                dismiss()
            }
            
            OutlineGroup(activityTree, children: \.optionalChildren) { activity in
                Button(action: {
                    selectedActivity = activity
                    dismiss()
                }) {
                    HStack {
                        IconView(iconString: activity.icon ?? "")
                        Text(activity.name)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("Select an Activity")
    }
}
