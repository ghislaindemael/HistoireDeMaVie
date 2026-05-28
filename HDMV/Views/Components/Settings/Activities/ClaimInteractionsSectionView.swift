import SwiftUI
import SwiftData

struct ClaimInteractionsSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var unclaimedInteractions: [Interaction]
    
    let parent: any ParentModel
    
    init(parent: any ParentModel) {
        self.parent = parent
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: parent.timeStart)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date.now
        let future = Date.distantFuture
        
        let predicate = #Predicate<Interaction> { interaction in
            interaction.parentInstanceRid == nil &&
            interaction.parentTripRid == nil &&
            interaction.timeStart < endOfDay &&
            (interaction.timeEnd ?? future) > startOfDay
        }
        
        _unclaimedInteractions = Query(filter: predicate, sort: \.timeStart, order: .reverse)
    }
    
    private func claim(interaction: Interaction) {
        var mutableInteraction = interaction
        mutableInteraction.setParent(parent)
        mutableInteraction.markAsModified()
        try? modelContext.save()
    }
    
    var body: some View {
        Section("Claim Interactions") {
            if unclaimedInteractions.isEmpty {
                Text("No unclaimed interactions available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(unclaimedInteractions) { interaction in
                    InteractionRowView(interaction: interaction)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            claim(interaction: interaction)
                        }
                }
            }
        }
    }
}
