import SwiftUI
import SwiftData

struct ClaimLifeEventsSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var unclaimedLifeEvents: [LifeEvent]
    
    let parent: any ParentModel
    
    init(parent: any ParentModel) {
        self.parent = parent
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: parent.timeStart)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date.now
        
        let predicate = #Predicate<LifeEvent> { event in
            event.parentInstanceRid == nil &&
            event.parentTripRid == nil &&
            event.timeStart >= startOfDay &&
            event.timeStart < endOfDay
        }
        
        _unclaimedLifeEvents = Query(filter: predicate, sort: \.timeStart)
    }
    
    private func claim(event: LifeEvent) {
        var mutableEvent = event
        mutableEvent.setParent(parent)
        mutableEvent.markAsModified()
        try? modelContext.save()
    }
    
    var body: some View {
        Section("Claim Life Events") {
            if unclaimedLifeEvents.isEmpty {
                Text("No unclaimed life events available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(unclaimedLifeEvents) { event in
                    LifeEventRowView(event: event, selectedDate: parent.timeStart)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            claim(event: event)
                        }
                }
            }
        }
    }
}
