//
//  TimeUtils.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import Foundation
import SwiftData

func combineDateTime(date: Date, timeString: String) -> Date {
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    
    let timeParts = timeString.split(separator: ":").compactMap { Int($0) }
    guard timeParts.count == 3 else {
        return date // fallback: just the date without time
    }
    
    var combinedComponents = DateComponents()
    combinedComponents.year = dateComponents.year
    combinedComponents.month = dateComponents.month
    combinedComponents.day = dateComponents.day
    combinedComponents.hour = timeParts[0]
    combinedComponents.minute = timeParts[1]
    combinedComponents.second = timeParts[2]
    
    return calendar.date(from: combinedComponents) ?? date
}

// MARK: - TimeZone Formatting Helpers

enum TimeZoneFormatUtils {
    
    static func calendar(for timeZone: TimeZone?) -> Calendar {
        var cal = Calendar.current
        if let tz = timeZone {
            cal.timeZone = tz
        }
        return cal
    }
    
    /// Formats `HH:mm` in the specified `TimeZone` (or `.current` if nil).
    static func formatTime(_ date: Date, in timeZone: TimeZone?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone ?? .current
        return formatter.string(from: date)
    }
    
    /// Formats `HH:mm:ss` in the specified `TimeZone` (or `.current` if nil).
    static func formatTimeWithSeconds(_ date: Date, in timeZone: TimeZone?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone ?? .current
        return formatter.string(from: date)
    }
    
    /// Returns `"dd/MM"` if `date` (evaluated in `timeZone`) does not fall on the same calendar day as `selectedDate`.
    static func displayDateIfNeeded(for date: Date, comparedTo selectedDate: Date, in timeZone: TimeZone?) -> String? {
        let targetCal = calendar(for: timeZone)
        let dateParts = targetCal.dateComponents([.year, .month, .day], from: date)
        
        // Compare against the selectedDate's nominal year/month/day
        let selectedParts = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        
        if dateParts.year != selectedParts.year ||
           dateParts.month != selectedParts.month ||
           dateParts.day != selectedParts.day {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = timeZone ?? .current
            return formatter.string(from: date)
        }
        return nil
    }
    
    /// Returns the offset badge string, e.g. `"(+1h)"` or `"(-5h)"`, when `targetTimeZone` has a different UTC offset
    /// than `referenceTimeZone` (defaults to `TimeZone.current`) at `date`.
    static func offsetBadgeString(
        for date: Date,
        in targetTimeZone: TimeZone?,
        relativeTo referenceTimeZone: TimeZone = .current
    ) -> String? {
        guard let targetTZ = targetTimeZone else { return nil }
        let diffSeconds = targetTZ.secondsFromGMT(for: date) - referenceTimeZone.secondsFromGMT(for: date)
        guard diffSeconds != 0 else { return nil }
        
        let sign = diffSeconds > 0 ? "+" : "-"
        let totalMinutes = abs(diffSeconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if minutes == 0 {
            return "(\(sign)\(hours)h)"
        } else {
            return String(format: "(%@%dh%02d)", sign, hours, minutes)
        }
    }
}

// MARK: - TimeZone Resolution Engine

enum TimeZoneResolver {
    
    static func fetchPlace(withId id: Int?, in context: ModelContext?) -> Place? {
        guard let placeId = id, let context = context else { return nil }
        let predicate = #Predicate<Place> { $0.rid == placeId }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
    
    static func resolvePlaceTimeZone(place: Place?, placeRid: Int?, in context: ModelContext?) -> TimeZone? {
        if let resolved = place?.resolvedTimeZone {
            return resolved
        }
        if let fetched = fetchPlace(withId: placeRid ?? place?.rid, in: context) {
            return fetched.resolvedTimeZone
        }
        return nil
    }
    
    /// Finds the timezone of the most recent known Place at or before `date` (since the user hasn't moved).
    /// If no prior place exists in cache before `date`, falls back to the earliest known place after `date`.
    static func latestPlaceTimeZone(at date: Date, in context: ModelContext?) -> TimeZone? {
        guard let context = context else { return nil }
        
        // 1. Check most recent Trip at or before `date`
        let priorTripsPredicate = #Predicate<Trip> { $0.timeStart <= date }
        var priorTripsDescriptor = FetchDescriptor(
            predicate: priorTripsPredicate,
            sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
        )
        priorTripsDescriptor.fetchLimit = 30
        let recentTrips = (try? context.fetch(priorTripsDescriptor)) ?? []
        
        var latestTripTime: Date = .distantPast
        var latestTripTZ: TimeZone? = nil
        
        for trip in recentTrips {
            if let end = trip.timeEnd, end <= date {
                if let tz = resolvePlaceTimeZone(place: trip.placeEnd, placeRid: trip.placeEndRid, in: context)
                    ?? resolvePlaceTimeZone(place: trip.placeStart, placeRid: trip.placeStartRid, in: context) {
                    latestTripTime = end
                    latestTripTZ = tz
                    break
                }
            } else {
                // Ongoing or overlapping trip at `date`
                if let tz = resolvePlaceTimeZone(place: trip.placeStart, placeRid: trip.placeStartRid, in: context)
                    ?? resolvePlaceTimeZone(place: trip.placeEnd, placeRid: trip.placeEndRid, in: context) {
                    latestTripTime = trip.timeStart
                    latestTripTZ = tz
                    break
                }
            }
        }
        
        // 2. Check most recent ActivityInstance with a linked Place at or before `date`
        let priorActivitiesPredicate = #Predicate<ActivityInstance> { $0.timeStart <= date }
        var priorActivitiesDescriptor = FetchDescriptor(
            predicate: priorActivitiesPredicate,
            sortBy: [SortDescriptor(\.timeStart, order: .reverse)]
        )
        priorActivitiesDescriptor.fetchLimit = 30
        let recentActivities = (try? context.fetch(priorActivitiesDescriptor)) ?? []
        
        var latestActivityTime: Date = .distantPast
        var latestActivityTZ: TimeZone? = nil
        
        for activity in recentActivities {
            guard let placeId = activity.decodedLogDetails?.place?.placeId else { continue }
            if let tz = resolvePlaceTimeZone(place: activity.decodedLogDetails?.place?.place, placeRid: placeId, in: context) {
                latestActivityTime = activity.timeEnd != nil && activity.timeEnd! <= date ? activity.timeEnd! : activity.timeStart
                latestActivityTZ = tz
                break
            }
        }
        
        if latestTripTZ != nil || latestActivityTZ != nil {
            if latestActivityTime >= latestTripTime, let actTZ = latestActivityTZ {
                return actTZ
            }
            if let tripTZ = latestTripTZ {
                return tripTZ
            }
            return latestActivityTZ
        }
        
        // 3. Secondary fallback: if single-day cache has no items before `date`, check earliest item after `date`
        let nextTripsPredicate = #Predicate<Trip> { $0.timeStart > date }
        var nextTripsDescriptor = FetchDescriptor(
            predicate: nextTripsPredicate,
            sortBy: [SortDescriptor(\.timeStart, order: .forward)]
        )
        nextTripsDescriptor.fetchLimit = 15
        let upcomingTrips = (try? context.fetch(nextTripsDescriptor)) ?? []
        
        var earliestNextTripTime: Date = .distantFuture
        var earliestNextTripTZ: TimeZone? = nil
        for trip in upcomingTrips {
            // The start place of the next trip is where the user was before that trip started
            if let tz = resolvePlaceTimeZone(place: trip.placeStart, placeRid: trip.placeStartRid, in: context)
                ?? resolvePlaceTimeZone(place: trip.placeEnd, placeRid: trip.placeEndRid, in: context) {
                earliestNextTripTime = trip.timeStart
                earliestNextTripTZ = tz
                break
            }
        }
        
        let nextActivitiesPredicate = #Predicate<ActivityInstance> { $0.timeStart > date }
        var nextActivitiesDescriptor = FetchDescriptor(
            predicate: nextActivitiesPredicate,
            sortBy: [SortDescriptor(\.timeStart, order: .forward)]
        )
        nextActivitiesDescriptor.fetchLimit = 15
        let upcomingActivities = (try? context.fetch(nextActivitiesDescriptor)) ?? []
        
        var earliestNextActivityTime: Date = .distantFuture
        var earliestNextActivityTZ: TimeZone? = nil
        for activity in upcomingActivities {
            guard let placeId = activity.decodedLogDetails?.place?.placeId else { continue }
            if let tz = resolvePlaceTimeZone(place: activity.decodedLogDetails?.place?.place, placeRid: placeId, in: context) {
                earliestNextActivityTime = activity.timeStart
                earliestNextActivityTZ = tz
                break
            }
        }
        
        if earliestNextTripTZ != nil || earliestNextActivityTZ != nil {
            if earliestNextTripTime <= earliestNextActivityTime, let tripTZ = earliestNextTripTZ {
                return tripTZ
            }
            return earliestNextActivityTZ ?? earliestNextTripTZ
        }
        
        return nil
    }
}

// MARK: - Model Extensions for TimeZone Resolution

extension Trip {
    func resolvedStartTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeStart, placeRid: placeStartRid, in: ctx) {
            return tz
        }
        if let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeEnd, placeRid: placeEndRid, in: ctx) {
            return tz
        }
        if let parentTZ = parentInstance?.resolvedDirectOrInheritedTimeZone(in: ctx) {
            return parentTZ
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
    
    func resolvedEndTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeEnd, placeRid: placeEndRid, in: ctx) {
            return tz
        }
        if let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeStart, placeRid: placeStartRid, in: ctx) {
            return tz
        }
        if let parentTZ = parentInstance?.resolvedDirectOrInheritedTimeZone(in: ctx) {
            return parentTZ
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeEnd ?? timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
}

extension ActivityInstance {
    func resolvedDirectOrInheritedTimeZone(
        forEnd: Bool = false,
        in context: ModelContext? = nil,
        visited: Set<PersistentIdentifier> = []
    ) -> TimeZone? {
        guard !visited.contains(self.persistentModelID) else { return nil }
        var nextVisited = visited
        nextVisited.insert(self.persistentModelID)
        
        let ctx = context ?? self.modelContext
        
        // 1. Direct place on this ActivityInstance
        if let placeDetails = decodedLogDetails?.place,
           let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeDetails.place, placeRid: placeDetails.placeId, in: ctx) {
            return tz
        }
        
        // 2. Child Trips (useful for Travel parent activities spanning multiple places)
        if !childTrips.isEmpty {
            let sortedTrips = childTrips.sorted { $0.timeStart < $1.timeStart }
            if forEnd {
                for trip in sortedTrips.reversed() {
                    if let tz = TimeZoneResolver.resolvePlaceTimeZone(place: trip.placeEnd, placeRid: trip.placeEndRid, in: ctx)
                        ?? TimeZoneResolver.resolvePlaceTimeZone(place: trip.placeStart, placeRid: trip.placeStartRid, in: ctx) {
                        return tz
                    }
                }
            } else {
                for trip in sortedTrips {
                    if let tz = TimeZoneResolver.resolvePlaceTimeZone(place: trip.placeStart, placeRid: trip.placeStartRid, in: ctx)
                        ?? TimeZoneResolver.resolvePlaceTimeZone(place: trip.placeEnd, placeRid: trip.placeEndRid, in: ctx) {
                        return tz
                    }
                }
            }
        }
        
        // 3. Child Activities with a direct place
        if !childActivities.isEmpty {
            let sortedChildren = childActivities.sorted { $0.timeStart < $1.timeStart }
            let list = forEnd ? Array(sortedChildren.reversed()) : sortedChildren
            for child in list {
                if let placeDetails = child.decodedLogDetails?.place,
                   let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeDetails.place, placeRid: placeDetails.placeId, in: ctx) {
                    return tz
                }
            }
        }
        
        // 4. Parent Trip or Parent Instance
        if let parentTrip = self.parentTrip {
            return forEnd ? parentTrip.resolvedEndTimeZone(in: ctx) : parentTrip.resolvedStartTimeZone(in: ctx)
        }
        if let parentInstance = self.parentInstance {
            return parentInstance.resolvedDirectOrInheritedTimeZone(forEnd: forEnd, in: ctx, visited: nextVisited)
        }
        
        return nil
    }
    
    func resolvedStartTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let tz = resolvedDirectOrInheritedTimeZone(forEnd: false, in: ctx) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
    
    func resolvedEndTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let tz = resolvedDirectOrInheritedTimeZone(forEnd: true, in: ctx) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeEnd ?? timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
}

extension Interaction {
    func resolvedStartTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let parentTrip = self.parentTrip {
            return parentTrip.resolvedStartTimeZone(in: ctx)
        }
        if let parentInstance = self.parentInstance,
           let tz = parentInstance.resolvedDirectOrInheritedTimeZone(forEnd: false, in: ctx) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
    
    func resolvedEndTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let parentTrip = self.parentTrip {
            return parentTrip.resolvedEndTimeZone(in: ctx)
        }
        if let parentInstance = self.parentInstance,
           let tz = parentInstance.resolvedDirectOrInheritedTimeZone(forEnd: true, in: ctx) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeEnd ?? timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
}

extension LifeEvent {
    func resolvedStartTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let parentTrip = self.parentTrip {
            return parentTrip.resolvedStartTimeZone(in: ctx)
        }
        if let parentInstance = self.parentInstance,
           let tz = parentInstance.resolvedDirectOrInheritedTimeZone(forEnd: false, in: ctx) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
    
    func resolvedEndTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let parentTrip = self.parentTrip {
            return parentTrip.resolvedEndTimeZone(in: ctx)
        }
        if let parentInstance = self.parentInstance,
           let tz = parentInstance.resolvedDirectOrInheritedTimeZone(forEnd: true, in: ctx) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeEnd ?? timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
}

extension Transaction {
    func resolvedStartTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let parentTrip = self.parentTrip {
            return parentTrip.resolvedStartTimeZone(in: ctx)
        }
        if let parentInstance = self.parentInstance,
           let tz = parentInstance.resolvedDirectOrInheritedTimeZone(forEnd: false, in: ctx) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
    
    func resolvedEndTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let parentTrip = self.parentTrip {
            return parentTrip.resolvedEndTimeZone(in: ctx)
        }
        if let parentInstance = self.parentInstance,
           let tz = parentInstance.resolvedDirectOrInheritedTimeZone(forEnd: true, in: ctx) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeEnd ?? timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
}

extension Quote {
    func resolvedStartTimeZone(in context: ModelContext? = nil) -> TimeZone {
        let ctx = context ?? self.modelContext
        if let parentInteraction = self.parentInteraction {
            return parentInteraction.resolvedStartTimeZone(in: ctx)
        }
        if let parentTrip = self.parentTrip {
            return parentTrip.resolvedStartTimeZone(in: ctx)
        }
        if let parentInstance = self.parentInstance,
           let tz = parentInstance.resolvedDirectOrInheritedTimeZone(forEnd: false, in: ctx) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeStart, in: ctx) {
            return latestTZ
        }
        return .current
    }
}

// MARK: - Editor Extensions for Distant TimeZone Editing

extension ActivityInstanceEditor {
    func resolvedStartTimeZone(for instance: ActivityInstance, in context: ModelContext?) -> TimeZone {
        if let placeDetails = decodedLogDetails?.place,
           let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeDetails.place, placeRid: placeDetails.placeId, in: context) {
            return tz
        }
        if let parentTrip = self.parentTrip {
            return parentTrip.resolvedStartTimeZone(in: context)
        }
        if let parentInstance = self.parentInstance {
            return parentInstance.resolvedStartTimeZone(in: context)
        }
        if let tz = instance.resolvedDirectOrInheritedTimeZone(forEnd: false, in: context) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeStart, in: context) {
            return latestTZ
        }
        return .current
    }
    
    func resolvedEndTimeZone(for instance: ActivityInstance, in context: ModelContext?) -> TimeZone {
        if let placeDetails = decodedLogDetails?.place,
           let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeDetails.place, placeRid: placeDetails.placeId, in: context) {
            return tz
        }
        if let parentTrip = self.parentTrip {
            return parentTrip.resolvedEndTimeZone(in: context)
        }
        if let parentInstance = self.parentInstance {
            return parentInstance.resolvedEndTimeZone(in: context)
        }
        if let tz = instance.resolvedDirectOrInheritedTimeZone(forEnd: true, in: context) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeEnd ?? timeStart, in: context) {
            return latestTZ
        }
        return .current
    }
}

extension TripEditor {
    func resolvedStartTimeZone(in context: ModelContext?) -> TimeZone {
        if let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeStart, placeRid: placeStartRid, in: context) {
            return tz
        }
        if let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeEnd, placeRid: placeEndRid, in: context) {
            return tz
        }
        if let parentInstance = self.parentInstance,
           let tz = parentInstance.resolvedDirectOrInheritedTimeZone(forEnd: false, in: context) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeStart, in: context) {
            return latestTZ
        }
        return .current
    }
    
    func resolvedEndTimeZone(in context: ModelContext?) -> TimeZone {
        if let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeEnd, placeRid: placeEndRid, in: context) {
            return tz
        }
        if let tz = TimeZoneResolver.resolvePlaceTimeZone(place: placeStart, placeRid: placeStartRid, in: context) {
            return tz
        }
        if let parentInstance = self.parentInstance,
           let tz = parentInstance.resolvedDirectOrInheritedTimeZone(forEnd: true, in: context) {
            return tz
        }
        if let latestTZ = TimeZoneResolver.latestPlaceTimeZone(at: timeEnd ?? timeStart, in: context) {
            return latestTZ
        }
        return .current
    }
}
