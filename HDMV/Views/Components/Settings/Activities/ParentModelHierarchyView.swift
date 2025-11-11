//
//  ActivityHierarchyView.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//

import SwiftUI

struct ParentModelHierarchyView: View {
    let parent: any ParentModel
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
    private let contentLeadingPadding: CGFloat = 4
    private let verticalPadding: CGFloat = 8
    
    @ViewBuilder
    private var rowView: some View {
        if let instance = parent as? ActivityInstance {
            ActivityInstanceRowView(instance: instance, selectedDate: viewModel.filterDate)
        } else if let trip = parent as? Trip {
            TripRowView(trip: trip, smallDisplay: settings.smallDisplay)
        } else {
            EmptyView()
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            rowView
            .background(isDropTargeted ? Color.green.opacity(0.2) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                if let instance = parent as? ActivityInstance {
                    instanceToEdit = instance
                } else if let trip = parent as? Trip {
                    tripToEdit = trip
                }
            }
            .cornerRadius(8)
            .dropDestination(for: DraggableLogItem.self) { items, location in
                guard let droppedItem = items.first else { return false }
                viewModel.reparent(draggedItem: droppedItem, to: parent)
                return true
            } isTargeted: { isTargeted in
                self.isDropTargeted = isTargeted
            }
            .draggable(DraggableLogItem.activity(parent.persistentModelID))
            
            if !filteredAndSortedChildren.isEmpty {
                HStack(alignment: .top, spacing: contentLeadingPadding) {
                    
                    indicatorColor
                        .frame(width: indicatorWidth)
                    
                    VStack(alignment: .leading, spacing: 4) {
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
            
            if !invalidChildren.isEmpty {
                
                HStack(alignment: .top, spacing: contentLeadingPadding) {
                    Color.red
                        .frame(width: indicatorWidth)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(invalidChildren, id: \.id) { item in
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
            
            if parent.timeEnd == nil || settings.planningMode == true {
                if let instance = parent as? ActivityInstance {
                    
                    if (instance.activity?.can(.create_trips) == true) {
                        if !parent.hasActiveTrips()  {
                            StartItemButton(title: "Start Trip") {
                                viewModel.createTrip(parent: instance)
                            }
                            .padding(.bottom, 4)
                        }
                    }
                    
                }
                if parent.timeEnd == nil && !parent.hasActiveChild(), let instance = parent as? ActivityInstance {
                    EndItemButton(title: "End now") {
                        viewModel.endActivityInstance(instance: instance)
                    }
                }
                
            }
                
            
        }
    }
    
    private var filteredAndSortedChildren: [any LogModel] {
        let all = parent.sortedChildren
        guard let parentEnd = parent.timeEnd else { return [] }
        let parentStart = parent.timeStart
        
        switch viewModel.filterMode {
            case .byDate:
                return all.filter { item in
                    let end = item.timeEnd ?? parentEnd
                    return item.timeStart >= parentStart && end <= parentEnd
                }
                .sorted { $0.timeStart < $1.timeStart }
                
            case .byActivity:
                return []
        }
    }
    
    private var invalidChildren: [any LogModel] {
        guard let parentEnd = parent.timeEnd else { return [] }
        let parentStart = parent.timeStart
        
        return parent.sortedChildren.filter { item in
            let end = item.timeEnd ?? .distantFuture
            let startsAfterParentEnds = item.timeStart >= parentEnd
            let endsBeforeParentStarts = end <= parentStart
            return startsAfterParentEnds || endsBeforeParentStarts
        }
    }
}


