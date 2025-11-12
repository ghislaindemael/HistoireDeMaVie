//
//  OrphanLogItemConnector.swift
//  HDMV
//
//  Created by Ghislain Demael on 12.11.2025.
//


import SwiftUI
import SwiftData

struct OrphanLogItemConnector: View {
    @Environment(\.modelContext) private var modelContext
    
    let parent: any ParentModel
    
    let showTrips: Bool
    let showInteractions: Bool
    let showLifeEvents: Bool
    
    @Query var orphanTrips: [Trip]
    @Query var orphanInteractions: [Interaction]
    @Query var orphanLifeEvents: [LifeEvent]
    
    init(
        parent: any ParentModel,
        showTrips: Bool = true,
        showInteractions: Bool = true,
        showLifeEvents: Bool = true
    ) {
        self.parent = parent
        self.showTrips = showTrips
        self.showInteractions = showInteractions
        self.showLifeEvents = showLifeEvents
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: parent.timeStart)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            _orphanTrips = Query(filter: #Predicate { _ in false })
            _orphanInteractions = Query(filter: #Predicate { _ in false })
            _orphanLifeEvents = Query(filter: #Predicate { _ in false })
            return
        }
        
        _orphanTrips = Query(filter: Self.buildTripPredicate(
            startOfDay: startOfDay,
            endOfDay: endOfDay
        ), sort: \.timeStart)
        
        _orphanInteractions = Query(filter: Self.buildInteractionPredicate(
            startOfDay: startOfDay,
            endOfDay: endOfDay
        ), sort: \.timeStart)
        
        _orphanLifeEvents = Query(filter: Self.buildLifeEventPredicate(
            startOfDay: startOfDay,
            endOfDay: endOfDay
        ), sort: \.timeStart)
        
    }

    
    var body: some View {
        tripSection
        interactionSection
        lifeEventSection
    }
    
    @ViewBuilder
    private var tripSection: some View {
        if showTrips && !orphanTrips.isEmpty {
            UnclaimedItemsView(
                title: "Claim Contained Trips",
                items: orphanTrips,
                onClaim: { trip in
                    claim(trip)
                },
                rowBuilder: { trip in
                    TripRowView(trip: trip)
                }
            )
        }
    }
    
    @ViewBuilder
    private var interactionSection: some View {
        if showInteractions && !orphanInteractions.isEmpty {
            UnclaimedItemsView(
                title: "Claim Contained Interactions",
                items: orphanInteractions,
                onClaim: { interaction in
                    claim(interaction)
                },
                rowBuilder: { interaction in
                    InteractionRowView(interaction: interaction)
                }
            )
        }
    }
    
    @ViewBuilder
    private var lifeEventSection: some View {
        if showLifeEvents && !orphanLifeEvents.isEmpty {
            UnclaimedItemsView(
                title: "Claim Contained Life Events",
                items: orphanLifeEvents,
                onClaim: { event in
                    claim(event)
                },
                rowBuilder: { event in
                    LifeEventRowView(event: event, selectedDate: parent.timeStart)
                }
            )
        }
    }
    
    
    private func claim(_ trip: Trip) {
        if let instance = parent as? ActivityInstance {
            trip.setParentInstance(instance)
            trip.markAsModified()
            save()
        }
    }
    
    private func claim(_ interaction: Interaction) {
        if let instance = parent as? ActivityInstance {
            interaction.parentInstance = instance
        } else if let trip = parent as? Trip {
            interaction.parentTrip = trip
        }
        interaction.markAsModified()
        save()
    }
    
    private func claim(_ lifeEvent: LifeEvent) {
         if let instance = parent as? ActivityInstance {
            lifeEvent.parentInstance = instance
         } else if let trip = parent as? Trip {
            lifeEvent.parentTrip = trip
         }
         lifeEvent.markAsModified()
         save()
    }
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to claim item: \(error)")
        }
    }
    
    private static func buildTripPredicate(startOfDay: Date, endOfDay: Date) -> Predicate<Trip> {
        let future = Date.distantFuture
        
        let p1 = #Predicate<Trip> { $0.parentInstanceRid == nil }
        let p2 = #Predicate<Trip> { $0.timeStart < endOfDay }
        let p3 = #Predicate<Trip> { ($0.timeEnd ?? future) > startOfDay }
        
        return #Predicate<Trip> { trip in
            p1.evaluate(trip) && p2.evaluate(trip) && p3.evaluate(trip)
        }
    }
    
    private static func buildInteractionPredicate(startOfDay: Date, endOfDay: Date) -> Predicate<Interaction> {
        let future = Date.distantFuture
        
        let p1 = #Predicate<Interaction> { $0.parentInstanceRid == nil }
        let p2 = #Predicate<Interaction> { $0.parentTripRid == nil }
        let p3 = #Predicate<Interaction> { $0.timeStart < endOfDay }
        let p4 = #Predicate<Interaction> { ($0.timeEnd ?? future) > startOfDay }
        
        return #Predicate<Interaction> { interaction in
            p1.evaluate(interaction) &&
            p2.evaluate(interaction) &&
            p3.evaluate(interaction) &&
            p4.evaluate(interaction)
        }
    }
    
    private static func buildLifeEventPredicate(startOfDay: Date, endOfDay: Date) -> Predicate<LifeEvent> {
        let p1 = #Predicate<LifeEvent> { $0.parentInstanceRid == nil }
        let p2 = #Predicate<LifeEvent> { $0.parentTripRid == nil }
        let p3 = #Predicate<LifeEvent> { $0.timeStart >= startOfDay }
        let p4 = #Predicate<LifeEvent> { $0.timeStart < endOfDay }
        
        return #Predicate<LifeEvent> { event in
            p1.evaluate(event) && p2.evaluate(event) && p3.evaluate(event) && p4.evaluate(event)
        }
    }
    
    
    
    
}
