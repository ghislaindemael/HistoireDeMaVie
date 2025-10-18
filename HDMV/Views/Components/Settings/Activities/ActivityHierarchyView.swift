//
//  ActivityHierarchyView.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//

// ActivityHierarchyView.swift (Final, Corrected Version)

import SwiftUI

struct ActivityHierarchyView: View {
    let instance: ActivityInstance
    let level: Int
    
    @EnvironmentObject var viewModel: MyActivitiesPageViewModel
    
    @State private var isDropTargeted: Bool = false
    
    @Binding var instanceToEdit: ActivityInstance?
    @Binding var tripToEdit: Trip?
    @Binding var interactionToEdit: PersonInteraction?
    
    private let indentationAmount: CGFloat = 20
    private let indicatorWidth: CGFloat = 2
    private let indicatorColor: Color = .gray.opacity(0.4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                if level > 0 {
                    indicatorColor
                        .frame(width: indicatorWidth)
                        .padding(.leading, (CGFloat(level) * indentationAmount) - indicatorWidth)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    let hasActiveTrips = instance.trips?.contains { $0.time_end == nil } ?? false
                    let hasActiveInteractions = instance.interactions?.contains { $0.time_end == nil } ?? false
                    
                    ActivityInstanceRowView(
                        instance: instance,
                        selectedDate: viewModel.filterDate
                    )
                    
                    if instance.time_end == nil && !hasActiveTrips && !hasActiveInteractions {
                        if !hasActiveTrips {
                            StartItemButton(title: "Start Trip") {
                                viewModel.createTrip(parent: instance)
                            }
                        }
                        EndItemButton(title: "End Activity") {
                            viewModel.endActivityInstance(instance: instance)
                        }
                    }
                }
                .padding(.leading, level == 0 ? 0 : 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    instanceToEdit = instance
                }
            }
            .padding(.vertical, 8)
            .background(isDropTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .dropDestination(for: DraggableLogItem.self) { items, location in
                guard let droppedItem = items.first else { return false }
                viewModel.reparent(draggedItem: droppedItem, to: instance)
                return true
            } isTargeted: { isTargeted in
                self.isDropTargeted = isTargeted
            }
            
            if !instance.sortedChildren.isEmpty {
                ForEach(instance.sortedChildren, id: \.id) { item in
                    LogItemRowView(
                        item: item,
                        instanceToEdit: $instanceToEdit,
                        tripToEdit: $tripToEdit,
                        interactionToEdit: $interactionToEdit,
                        level: level + 1
                    )
                }
            }
        }
        .draggable(DraggableLogItem.activity(instance.persistentModelID))
    }
}

extension ActivityInstance {
    var sortedChildren: [any LogModel] {
        var allChildren: [any LogModel] = []
        
        if let childActivities = self.childActivities {
            allChildren.append(contentsOf: childActivities)
        }
        if let trips = self.trips {
            allChildren.append(contentsOf: trips)
        }
        if let interactions = self.interactions {
            allChildren.append(contentsOf: interactions)
        }
        return allChildren.sorted(by: { $0.time_start < $1.time_start })
    }
}
