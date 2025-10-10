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
    @Binding var tripLegToEdit: TripLeg?
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
                    let instanceTripLegs = viewModel.tripLegs(for: instance.id)
                    let instanceInteractions = viewModel.interactions(for: instance.id)
                    let hasActiveLegs = instanceTripLegs.contains { $0.time_end == nil }
                    let hasActiveInteractions = instanceInteractions.contains { $0.time_end == nil }
                    
                    ActivityInstanceRowView(
                        instance: instance,
                        tripLegs: instanceTripLegs,
                        interactions: instanceInteractions,
                        selectedDate: viewModel.selectedDate,
                        onStartTripLeg: { parentId in viewModel.createTripLeg(parent_id: parentId) },
                        onEditTripLeg: { leg in self.tripLegToEdit = leg },
                        onEndTripLeg: { leg in viewModel.endTripLeg(leg: leg) },
                        onStartInteraction: { parentId in viewModel.createInteraction(parent_id: parentId) },
                        onEditInteraction: { interaction in self.interactionToEdit = interaction },
                        onEndInteraction: { interaction in viewModel.endInteraction(interaction: interaction) }
                    )
                    
                    if instance.time_end == nil && !hasActiveLegs && !hasActiveInteractions {
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
            .draggable(DraggableActivityInstanceID(id: instance.id))
            .dropDestination(for: DraggableActivityInstanceID.self) { items, location in
                guard let droppedItem = items.first else { return false }
                viewModel.reparent(instanceId: droppedItem.id, toNewParentInstanceId: instance.id)
                return true
            } isTargeted: { isTargeted in
                self.isDropTargeted = isTargeted
            }
            
            if let children = instance.children, !children.isEmpty {
                ForEach(children.sorted(by: { $0.time_start < $1.time_start })) { child in
                    ActivityHierarchyView(
                        instance: child,
                        level: level + 1,
                        instanceToEdit: $instanceToEdit,
                        tripLegToEdit: $tripLegToEdit,
                        interactionToEdit: $interactionToEdit
                    )
                }
            }
        }
    }
}
