//
//  LogItemRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.10.2025.
//


import SwiftUI

struct LogItemRowView: View {
    
    @EnvironmentObject var viewModel: MyActivitiesPageViewModel

    let item: any LogModel
    
    @Binding var instanceToEdit: ActivityInstance?
    @Binding var tripLegToEdit: TripLeg?
    @Binding var interactionToEdit: PersonInteraction?

    
    let level: Int

    @ViewBuilder
    var body: some View {
        switch item {
        case let activity as ActivityInstance:
            ActivityHierarchyView(
                instance: activity,
                level: level,
                instanceToEdit: $instanceToEdit,
                tripLegToEdit: $tripLegToEdit,
                interactionToEdit: $interactionToEdit
            )
        case let tripLeg as TripLeg:
                TripLegRowView(tripLeg: tripLeg, onEnd: {
                    viewModel.endTripLeg(leg: tripLeg)
                })
                .onTapGesture {
                    tripLegToEdit = tripLeg
                }
                .padding(.leading, CGFloat(level) * 20)

        case let interaction as PersonInteraction:
                PersonInteractionRowView(interaction: interaction, onEnd: {
                    viewModel.endInteraction(interaction: interaction)
                })
                .onTapGesture {
                    interactionToEdit = interaction
                }
                .padding(.leading, CGFloat(level) * 20)

        default:
            EmptyView()
        }
    }
}
