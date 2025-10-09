//
//  ActivityHierarchyView.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//

import SwiftUI

struct ActivityHierarchyView: View {
    let instance: ActivityInstance
    let level: Int
    
    @EnvironmentObject var viewModel: MyActivitiesPageViewModel
    
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
                    Rectangle()
                        .fill(indicatorColor)
                        .frame(width: indicatorWidth)
                        .padding(.leading, indentationAmount - indicatorWidth)
                }
                
                activityRow
                    .padding(.leading, level == 0 ? 0 : 5)
            }
            
            if let children = instance.children, !children.isEmpty {
                ForEach(children) { child in
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
    
    private var activityRow: some View {
        let instanceTripLegs = viewModel.tripLegs(for: instance.id)
        let instanceInteractions = viewModel.interactions(for: instance.id)
        let hasActiveLegs = instanceTripLegs.contains { $0.time_end == nil }
        let hasActiveInteractions = instanceInteractions.contains { $0.time_end == nil }
        
        return VStack(alignment: .leading, spacing: 4) {
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
            .contentShape(Rectangle())
            .onTapGesture {
                instanceToEdit = instance
            }
            
            if instance.time_end == nil && !hasActiveLegs && !hasActiveInteractions {
                EndItemButton(title: "End Activity") {
                    viewModel.endActivityInstance(instance: instance)
                }
                
            }
        }
    }
}
