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
    @Binding var lifeEventToEdit: LifeEvent?
    @Binding var quoteToEdit: Quote?
    
    @State private var isTripDropTargeted = false
    
    let level: Int
    
    @ViewBuilder
    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
            
            if let linked = item as? any LinkedParent, linked.hasAmbiguousParents {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .offset(x: -4, y: 4)
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        switch item {
            case let parentItem as any ParentModel:
                ParentModelHierarchyView(
                    parent: parentItem,
                    level: level,
                    instanceToEdit: $instanceToEdit,
                    tripToEdit: $tripToEdit,
                    interactionToEdit: $interactionToEdit,
                    lifeEventToEdit: $lifeEventToEdit,
                    quoteToEdit: $quoteToEdit
                )
                
            case let interaction as Interaction:
                InteractionRowView(interaction: interaction, onEnd: {
                    viewModel.endInteraction(interaction: interaction)
                })
                .onTapGesture(count: 2){
                    interactionToEdit = interaction
                }
                .draggable(DraggableLogItem.interaction(interaction.persistentModelID))
                
            case let lifeEvent as LifeEvent:
                LifeEventRowView(event: lifeEvent, selectedDate: viewModel.filterDate)
                    .onTapGesture(count: 2) {
                        lifeEventToEdit = lifeEvent
                    }
                    .draggable(DraggableLogItem.lifeEvent(lifeEvent.persistentModelID))
            
            case let quote as Quote:
                QuoteRowView(quote: quote)
                    .onTapGesture(count: 2) {
                        quoteToEdit = quote
                    }
                    .draggable(DraggableLogItem.quote(quote.persistentModelID))
                    
            default:
                EmptyView()
        }
    }
}
