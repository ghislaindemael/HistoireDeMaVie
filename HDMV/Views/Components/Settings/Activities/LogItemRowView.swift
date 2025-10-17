import SwiftUI

struct LogItemRowView: View {
    // This view accepts any item that conforms to our protocol
    let item: any LogModel
    
    // Pass through the bindings needed by the subviews
    @Binding var instanceToEdit: ActivityInstance?
    @Binding var tripLegToEdit: TripLeg?
    @Binding var interactionToEdit: PersonInteraction?
    
    // Pass through any other needed parameters, like the level
    let level: Int

    @ViewBuilder
    var body: some View {
        // Use a switch to handle each concrete type
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
            TripLegRowView(leg: tripLeg)
                // You can add gestures and modifiers for trip legs here
                .onTapGesture {
                    tripLegToEdit = tripLeg
                }
                .padding(.leading, CGFloat(level) * 20) // Apply indentation for non-hierarchical children

        case let interaction as PersonInteraction:
            PersonInteractionRowView(interaction: interaction)
                // You can add gestures and modifiers for interactions here
                .onTapGesture {
                    interactionToEdit = interaction
                }
                .padding(.leading, CGFloat(level) * 20) // Apply indentation

        default:
            // A fallback in case you add new types to LogModel
            EmptyView()
        }
    }
}