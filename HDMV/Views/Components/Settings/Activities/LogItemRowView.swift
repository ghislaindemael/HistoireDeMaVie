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
    @Binding var tripToEdit: Trip?
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
                tripToEdit: $tripToEdit,
                interactionToEdit: $interactionToEdit
            )
        case let trip as Trip:
                TripRowView(trip: trip, onEnd: {
                    viewModel.endTrip(trip: trip)
                })
                .onTapGesture {
                    tripToEdit = trip
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
