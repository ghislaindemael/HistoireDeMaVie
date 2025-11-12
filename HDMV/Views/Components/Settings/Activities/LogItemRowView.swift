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
    
    @State private var isTripDropTargeted = false
    
    let level: Int
    
    @ViewBuilder
    var body: some View {
        switch item {
            case let parentItem as any ParentModel:
                ParentModelHierarchyView(
                    parent: parentItem,
                    level: level,
                    instanceToEdit: $instanceToEdit,
                    tripToEdit: $tripToEdit,
                    interactionToEdit: $interactionToEdit
                    
                )
                
            case let interaction as Interaction:
                InteractionRowView(interaction: interaction, onEnd: {
                    viewModel.endInteraction(interaction: interaction)
                })
                .onTapGesture(count: 2){
                    interactionToEdit = interaction
                }
                .draggable(DraggableLogItem.interaction(interaction.persistentModelID))
            default:
                EmptyView()
        }
    }
}
