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
    @ObservedObject var settings = SettingsStore.shared
    
    @State private var isDropTargeted: Bool = false
    
    @Binding var instanceToEdit: ActivityInstance?
    @Binding var tripToEdit: Trip?
    @Binding var interactionToEdit: Interaction?
    
    private let indentationAmount: CGFloat = 20
    private let indicatorWidth: CGFloat = 2
    private let indicatorColor: Color = .gray.opacity(0.4)
    private let contentLeadingPadding: CGFloat = 8
    private let verticalPadding: CGFloat = 8
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            ActivityInstanceRowView(
                instance: instance,
                selectedDate: viewModel.filterDate,
            )
            .background(isDropTargeted ? Color.green.opacity(0.2) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { instanceToEdit = instance }
            .cornerRadius(8)
            .dropDestination(for: DraggableLogItem.self) { items, location in
                guard let droppedItem = items.first else { return false }
                viewModel.reparent(draggedItem: droppedItem, to: instance)
                return true
            } isTargeted: { isTargeted in
                self.isDropTargeted = isTargeted
            }
            .draggable(DraggableLogItem.activity(instance.persistentModelID))
            
            if !filteredAndSortedChildren.isEmpty {
                HStack(alignment: .top, spacing: contentLeadingPadding) {
                    
                    indicatorColor
                        .frame(width: indicatorWidth)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(filteredAndSortedChildren, id: \.id) { item in
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
            }
            
            let hasActiveTrips = instance.trips?.contains { $0.timeEnd == nil } ?? false
            let hasActiveInteractions = instance.interactions?.contains { $0.timeEnd == nil } ?? false
            
            if instance.timeEnd == nil || settings.planningMode == true {
                if (instance.activity?.can(.create_trips) == true) {
                    if !hasActiveTrips  {
                        StartItemButton(title: "Start Trip") {
                            viewModel.createTrip(parent: instance)
                        }
                        .padding(.bottom, 4)
                    }
                }
                
                if instance.timeEnd == nil && !hasActiveTrips && !hasActiveInteractions {
                    EndItemButton(title: "End Activity") {
                        viewModel.endActivityInstance(instance: instance)
                    }
                }
            }
            
        }
    }
    
    private var filteredAndSortedChildren: [any LogModel] {
        let allSortedChildren = instance.sortedChildren
        
        switch viewModel.filterMode {
            case .byDate:
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: viewModel.filterDate)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                    return []
                }
                let future = Date.distantFuture
                
                return allSortedChildren.filter { item in
                    item.timeStart < endOfDay && (item.timeEnd ?? future) > startOfDay
                }
                
            case .byActivity:
                return []
        }
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
        return allChildren.sorted(by: { $0.timeStart < $1.timeStart })
    }
    
    
}
