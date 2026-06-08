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
        let endBoundDate = parent.timeEnd ?? Date.now
        let startOfEndBoundDay = calendar.startOfDay(for: endBoundDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfEndBoundDay) ?? Date.distantFuture
        
        let predicate = #Predicate<LifeEvent> { event in
            event.parentInstanceRid == nil &&
            event.parentTripRid == nil &&
            event.timeStart >= startOfDay &&
            event.timeStart < endOfDay
        }
        
        _unclaimedLifeEvents = Query(filter: predicate, sort: \.timeStart)
    }
    
    private var filteredLifeEvents: [LifeEvent] {
        unclaimedLifeEvents.filter { $0.parentInstance == nil && $0.parentTrip == nil }
    }
    
    private func claim(event: LifeEvent) {
        var mutableEvent = event
        mutableEvent.setParent(parent)
        mutableEvent.markAsModified()
        try? modelContext.save()
    }
    
    var body: some View {
        let displayEvents = filteredLifeEvents
        Section("Claim Life Events") {
            if displayEvents.isEmpty {
                Text("No unclaimed life events available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(displayEvents) { event in
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
