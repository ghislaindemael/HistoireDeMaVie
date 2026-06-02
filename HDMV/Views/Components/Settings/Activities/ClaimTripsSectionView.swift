import SwiftUI
import SwiftData

struct ClaimTripsSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dayTrips: [Trip]
    @State private var showAll: Bool = false
    
    let parent: any ParentModel
    
    init(parent: any ParentModel) {
        self.parent = parent
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: parent.timeStart)
        let endBoundDate = parent.timeEnd ?? Date.now
        let startOfEndBoundDay = calendar.startOfDay(for: endBoundDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfEndBoundDay) ?? Date.distantFuture
        let future = Date.distantFuture
        
        let predicate = #Predicate<Trip> { trip in
            trip.timeStart < endOfDay &&
            (trip.timeEnd ?? future) > startOfDay
        }
        
        _dayTrips = Query(filter: predicate, sort: \.timeStart, order: .reverse)
    }
    
    private var unclaimedTrips: [Trip] {
        dayTrips.filter { $0.parentInstanceRid == nil && $0.parentInstance == nil }
    }
    
    private var displayedTrips: [Trip] {
        showAll ? dayTrips : unclaimedTrips
    }
    
    private func claim(trip: Trip) {
        var mutableTrip = trip
        mutableTrip.setParent(parent)
        mutableTrip.markAsModified()
        try? modelContext.save()
    }
    
    var body: some View {
        Section("Claim Trips") {
            if displayedTrips.isEmpty {
                Text(showAll ? "No trips recorded today" : "No unclaimed trips available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(displayedTrips) { trip in
                    TripRowView(trip: trip)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            claim(trip: trip)
                            showAll = false // Reset after claiming if desired, or keep open
                        }
                }
            }
            
            if !showAll {
                Button("Show all trips of the day") {
                    withAnimation {
                        showAll = true
                    }
                }
            } else {
                Button("Hide claimed trips") {
                    withAnimation {
                        showAll = false
                    }
                }
            }
        }
    }
}
