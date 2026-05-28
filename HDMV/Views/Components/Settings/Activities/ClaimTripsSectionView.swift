import SwiftUI
import SwiftData

struct ClaimTripsSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var unclaimedTrips: [Trip]
    
    let parent: any ParentModel
    
    init(parent: any ParentModel) {
        self.parent = parent
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: parent.timeStart)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date.now
        let future = Date.distantFuture
        
        let predicate = #Predicate<Trip> { trip in
            trip.parentInstance == nil &&
            trip.timeStart < endOfDay &&
            (trip.timeEnd ?? future) > startOfDay
        }
        
        _unclaimedTrips = Query(filter: predicate, sort: \.timeStart, order: .reverse)
    }
    
    private func claim(trip: Trip) {
        var mutableTrip = trip
        mutableTrip.setParent(parent)
        mutableTrip.markAsModified()
        try? modelContext.save()
    }
    
    var body: some View {
        Section("Claim Trips") {
            if unclaimedTrips.isEmpty {
                Text("No unclaimed trips available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(unclaimedTrips) { trip in
                    TripRowView(trip: trip)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            claim(trip: trip)
                        }
                }
            }
        }
    }
}
