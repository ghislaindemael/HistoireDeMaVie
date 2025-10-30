//
//  LogItemRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.10.2025.
//


import SwiftUI

struct LogItemRowView: View {
    
    @EnvironmentObject var viewModel: MyActivitiesPageViewModel
    @ObservedObject var settings: SettingsStore = SettingsStore.shared

    let item: any LogModel
    
    @Binding var instanceToEdit: ActivityInstance?
    @Binding var tripToEdit: Trip?
    @Binding var interactionToEdit: Interaction?

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
            .draggable(DraggableLogItem.activity(activity.persistentModelID))

        case let trip as Trip:
                TripRowView(
                    trip: trip,
                    smallDisplay: settings.smallDisplay,
                    onEnd: {
                        viewModel.endTrip(trip: trip)
                })
                .onTapGesture {
                    tripToEdit = trip
                }
                .draggable(DraggableLogItem.trip(trip.persistentModelID))

        case let interaction as Interaction:
                InteractionRowView(interaction: interaction, onEnd: {
                    viewModel.endInteraction(interaction: interaction)
                })
                .onTapGesture {
                    interactionToEdit = interaction
                }
                .draggable(DraggableLogItem.interaction(interaction.persistentModelID))
        default:
            EmptyView()
        }
    }
}
