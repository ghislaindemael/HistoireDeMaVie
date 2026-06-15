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
        let endBoundDate = parent.timeEnd ?? Date.now
        let startOfEndBoundDay = calendar.startOfDay(for: endBoundDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfEndBoundDay) ?? Date.distantFuture
        let future = Date.distantFuture
        
        let predicate = #Predicate<Interaction> { interaction in
            interaction.parentInstanceRid == nil &&
            interaction.parentTripRid == nil &&
            interaction.timeStart < endOfDay &&
            (interaction.timeEnd ?? future) > startOfDay
        }
        
        _unclaimedInteractions = Query(filter: predicate, sort: \.timeStart)
    }
    
    private var filteredInteractions: [Interaction] {
        unclaimedInteractions.filter { $0.parentInstance == nil && $0.parentTrip == nil }
    }
    
    private func claim(interaction: Interaction) {
        var mutableInteraction = interaction
        mutableInteraction.setParent(parent)
        mutableInteraction.markAsModified()
        try? modelContext.save()
    }
    
    var body: some View {
        let displayInteractions = filteredInteractions
        Section("Claim Interactions") {
            if displayInteractions.isEmpty {
                Text("No unclaimed interactions available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(displayInteractions) { interaction in
                    InteractionRowView(interaction: interaction, onEnd: nil)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            claim(interaction: interaction)
                        }
                }
            }
        }
    }
}
