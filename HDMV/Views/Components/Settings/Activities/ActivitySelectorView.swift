//
//  ActivitySelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 03.09.2025.
//

import SwiftUI
import SwiftData

struct ActivitySelectorView: View {
    @Binding var selectedActivity: Activity?
    @Query var activityTree: [Activity]
    
    init(selectedActivity: Binding<Activity?>) {
        _selectedActivity = selectedActivity
        let predicate = #Predicate<Activity> { $0.parentRid == nil && $0.cache == true }
        _activityTree = Query(filter: predicate, sort: \.name)
    }
    
    var body: some View {
        GenericTreeSelectorView(
            items: activityTree,
            childrenKeyPath: \.cachedOptionalChildren,
            selection: $selectedActivity,
            title: "Select an Activity",
            noneButtonText: "None"
        )
    }
}

struct ParentActivitySelector: View {
    let activities: [Activity]
    @Binding var selectedParent: Activity?
    
    var body: some View {
        GenericTreeSelectorView(
            items: activities,
            childrenKeyPath: \.cachedOptionalChildren,
            selection: $selectedParent,
            title: "Select Parent",
            noneButtonText: "Top Level (No Parent)"
        )
    }
}
