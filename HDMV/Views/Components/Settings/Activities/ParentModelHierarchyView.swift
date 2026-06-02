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
    @Binding var lifeEventToEdit: LifeEvent?
    
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
            TripRowView(trip: trip)
        } else {
            EmptyView()
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            rowView
                .background(isDropTargeted ? Color.green.opacity(0.2) : Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    parent.advanceDisplayMode()
                }
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
            
            if parent.hasChildren() {
                if parent.childrenDisplayMode != .all {
                    collapsedIndicator
                }
                if parent.childrenDisplayMode != .none {
                    childrenSection
                }
            }
            
            
            if parent.timeEnd == nil || settings.planningMode == true,
               let instance = parent as? ActivityInstance {
                if (instance.activity?.can(.create_trips) == true) {
                    if !parent.hasOngoingTrips()  {
                        StartItemButton(title: "Start Trip") {
                            viewModel.createTrip(parent: instance)
                        }
                        
                    }
                }
                
            }
            
            if parent.timeEnd == nil, !parent.hasOngoingChild() {
                EndItemButton(title: "End now") {
                    if let instance = parent as? ActivityInstance {
                        viewModel.endActivityInstance(instance: instance)
                    } else if let trip = parent as? Trip {
                        viewModel.endTrip(trip: trip)
                    }
                }
            }
            
            
        }
    }
    
    @ViewBuilder
    private var collapsedIndicator: some View {
        let hidden = hiddenChildrenCount
        if hidden > 0 {
            HStack(spacing: 4) {
                Spacer()
                ForEach(0..<min(3, hidden), id: \.self) { _ in
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 4, height: 4)
                }
                Spacer()
            }
            .frame(height: 16)
            .frame(maxWidth: .infinity)
            .background(Color.primaryBackground, in: Capsule())
            .padding(.leading, indicatorWidth + contentLeadingPadding)
            .background(
                indicatorColor
                    .frame(width: indicatorWidth)
                    .cornerRadius(indicatorWidth / 2),
                alignment: .leading
            )
        }
    }
    
    @ViewBuilder
    private var childrenSection: some View {
        let children = allChildrenSorted
        if !children.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(children.enumerated()), id: \.element.id) { index, item in
                    LogItemRowView(
                        item: item,
                        instanceToEdit: $instanceToEdit,
                        tripToEdit: $tripToEdit,
                        interactionToEdit: $interactionToEdit,
                        lifeEventToEdit: $lifeEventToEdit,
                        level: level + 1
                    )
                    .padding(.bottom, index == children.count - 1 ? 0 : 4)
                    .padding(.leading, indicatorWidth + contentLeadingPadding)
                    .background(
                        lineColor(for: item)
                            .frame(width: indicatorWidth),
                        alignment: .leading
                    )
                }
            }
        }
    }
    
    private var allChildrenSorted: [any LogModel] {
        if parent.childrenDisplayMode == .none { return [] }
        
        let allValid = parent.children(overlapping: viewModel.filterDate)
        let allInvalid = parent.invalidChildren
        
        var combined = allValid
        for invalid in allInvalid {
            if !combined.contains(where: { $0.id == invalid.id }) {
                combined.append(invalid)
            }
        }
        
        if parent.childrenDisplayMode == .ongoing {
            combined = combined.filter { $0.timeEnd == nil && !($0 is LifeEvent) }
        }
        
        return combined.sorted { $0.timeStart < $1.timeStart }
    }
    
    private var hiddenChildrenCount: Int {
        let allValid = parent.children(overlapping: viewModel.filterDate)
        let allInvalid = parent.invalidChildren
        
        var combined = allValid
        for invalid in allInvalid {
            if !combined.contains(where: { $0.id == invalid.id }) {
                combined.append(invalid)
            }
        }
        
        if parent.childrenDisplayMode == .none {
            return combined.count
        } else if parent.childrenDisplayMode == .ongoing {
            let ongoingCount = combined.filter { $0.timeEnd == nil && !($0 is LifeEvent) }.count
            return max(0, combined.count - ongoingCount)
        } else {
            return 0
        }
    }
    
    private func lineColor(for child: any LogModel) -> Color {
        let parentStart = parent.timeStart
        let parentEnd = parent.timeEnd ?? Date.distantFuture
        let childStart = child.timeStart
        
        let childEnd: Date
        if child is LifeEvent && child.timeEnd == nil {
            childEnd = childStart
        } else {
            childEnd = child.timeEnd ?? Date.distantFuture
        }
        
        let completelyOutside = childEnd <= parentStart || childStart >= parentEnd
        if completelyOutside {
            return .red
        }
        
        let parentFullyContained = childStart < parentStart && childEnd > parentEnd
        if parentFullyContained {
            return .pink
        }
        
        let perfectlyContained = childStart >= parentStart && childEnd <= parentEnd
        if perfectlyContained {
            return indicatorColor
        }
        
        return .orange
    }
    
}
