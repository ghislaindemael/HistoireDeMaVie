//
//  ActivityInstance.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import Foundation
import SwiftData
import SwiftUI

struct ActivityOptionPill: Identifiable {
    let id = UUID()
    let optionSlug: String
    let label: String
    let icon: String?
    let isDefault: Bool
    let replacesActivityName: Bool
}

@Model
final class ActivityInstance: LogModel {
    
    @Attribute(.unique) var rid: Int?
    var timeStart: Date
    var timeEnd: Date?
    var timed: Bool = true
    var percentage: Int
    
    var activityRid: Int?
    var parentInstanceRid: Int?
    var parentTripRid: Int?
    @Attribute var childrenDisplayModeRaw: String = ChildrenDisplayMode.all.rawValue
    
    var details: String?
    var activity_details: Data?
    
    var fitFilePath: String?
    
    var persons: [Person] = []
    var personRids: [Int] = []
    var contextRids: [Int] = []
    
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = ActivityInstanceDTO
    typealias Payload = ActivityInstancePayload
    typealias Editor = ActivityInstanceEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var activity: Activity?
    
    @Relationship(deleteRule: .nullify)
    var parentInstance: ActivityInstance?
    
    @Relationship(deleteRule: .nullify)
    var parentTrip: Trip?
    
    @Relationship(deleteRule: .nullify, inverse: \ActivityInstance.parentInstance)
    var childActivities: [ActivityInstance] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Trip.parentInstance)
    var childTrips: [Trip] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Interaction.parentInstance)
    var childInteractions: [Interaction] = []
    
    @Relationship(deleteRule: .nullify, inverse: \LifeEvent.parentInstance)
    var childLifeEvents: [LifeEvent] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Quote.parentInstance)
    var childQuotes: [Quote] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.parentInstance)
    var childTransactions: [Transaction] = []
    
    // MARK: Relationship conformance

    // MARK: Init
    
    init(
        rid: Int? = nil,
        timeStart: Date = .now,
        timeEnd: Date? = nil,
        timed: Bool = true,
        percentage: Int = 100,
        activityRid: Int? = nil,
        parentRid: Int? = nil,
        details: String? = nil,
        activity_details: ActivityDetails? = nil,
        fitFilePath: String? = nil,
        syncStatus: SyncStatus = .unsynced
    ) {
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.activityRid = activityRid
        self.parentInstanceRid = parentRid
        self.details = details
        self.percentage = percentage
        self.fitFilePath = fitFilePath
        self.syncStatus = syncStatus
        self.decodedActivityDetails = activity_details
    }
    
    var decodedActivityDetails: ActivityDetails? {
        get {
            guard let data = activity_details else { return nil }
            return try? JSONDecoder().decode(ActivityDetails.self, from: data)
        }
        set {
            activity_details = try? JSONEncoder().encode(newValue)
        }
    }
    
    var resolvedOptionsPills: [ActivityOptionPill] {
        guard let activity = self.activity,
              let mappedOptions = decodedActivityDetails?.options,
              !mappedOptions.isEmpty else {
            return []
        }
        
        let sortedMappings = activity.optionMappings.sorted { $0.priority < $1.priority }
        var pills: [ActivityOptionPill] = []
        
        for mapping in sortedMappings {
            guard let option = mapping.option else { continue }
            guard let selectedValueSlug = mappedOptions[option.slug] else { continue }
            
            let config = option.config
            let choice = config?.choices?.first(where: { $0.slug == selectedValueSlug })
            let label = choice?.label ?? selectedValueSlug
            let icon = choice?.icon
            let isDefault = (selectedValueSlug == config?.defaultValue)
            let replaces = config?.replacesActivityName ?? false
            
            pills.append(ActivityOptionPill(
                optionSlug: option.slug,
                label: label,
                icon: icon,
                isDefault: isDefault,
                replacesActivityName: replaces
            ))
        }
        
        return pills
    }
    
    convenience init(fromDto dto: ActivityInstanceDTO) {
        self.init()
        self.rid = dto.id
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.activityRid = dto.activity_id
        self.parentInstanceRid = dto.parent_instance_id
        self.parentTripRid = dto.parent_trip_id
        self.details = dto.details
        self.percentage = dto.percentage ?? 100
        self.fitFilePath = dto.fit_file_path
        self.decodedActivityDetails = dto.activity_details
        self.personRids = dto.person_ids ?? []
        self.contextRids = dto.context_ids ?? []
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: ActivityInstanceDTO) {
        self.timeStart = dto.time_start
        self.timeEnd = dto.time_end
        self.activityRid = dto.activity_id
        self.parentInstanceRid = dto.parent_instance_id
        self.parentTripRid = dto.parent_trip_id
        self.details = dto.details
        self.percentage = dto.percentage ?? 100
        self.fitFilePath = dto.fit_file_path
        self.decodedActivityDetails = dto.activity_details
        self.personRids = dto.person_ids ?? []
        self.contextRids = dto.context_ids ?? []
        
        let currentRids = Set(self.persons.compactMap { $0.rid })
        let newRids = Set(dto.person_ids ?? [])
        if currentRids != newRids {
            self.persons = []
        }
        
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return activityRid != nil
    }
    
}

struct ActivityInstanceDTO: Codable, Identifiable {
    let id: Int
    let time_start: Date
    let time_end: Date?
    let activity_id: Int?
    let parent_instance_id: Int?
    let parent_trip_id: Int?
    let details: String?
    let percentage: Int?
    let fit_file_path: String?
    let activity_details: ActivityDetails?
    let person_ids: [Int]?
    let context_ids: [Int]?
}


struct ActivityInstancePayload: Codable, InitializableWithModel {
    
    typealias Model = ActivityInstance
    
    let time_start: Date
    let time_end: Date?
    @ExplicitNull var activity_id: Int?
    @ExplicitNull var parent_instance_id: Int?
    @ExplicitNull var parent_trip_id: Int?
    
    let details: String?
    let percentage: Int
    let fit_file_path: String?
    let activity_details: ActivityDetails?
    let person_ids: [Int]
    let context_ids: [Int]
    
    init?(from instance: ActivityInstance) {
        guard instance.isValid() else {
            print("-> ActivityInstance \(instance.id) is invalid.")
            return nil
        }
        
        self.time_start = instance.timeStart
        self.time_end = instance.timeEnd
        self.activity_id = instance.activityRid
        self.parent_instance_id = instance.parentInstanceRid
        self.parent_trip_id = instance.parentTripRid
        self.details = instance.details
        self.percentage = instance.percentage
        self.fit_file_path = instance.fitFilePath
        self.person_ids = instance.personRids
        self.context_ids = instance.contextRids
        
        if var details = instance.decodedActivityDetails {
            details.removeFields()
            self.activity_details = details
        } else {
            self.activity_details = nil
        }
    }
}

struct ActivityInstanceEditor: TimeTrackable, EditorProtocol, LinkedParent {
    var timeStart: Date
    var timeEnd: Date?
    var timed: Bool
    var percentage: Int
    var activity: Activity?
    var parentInstance: ActivityInstance? {
        didSet {
            parentInstanceRid = parentInstance?.rid
        }
    }
    var parentInstanceRid: Int?
    var parentTrip: Trip? {
        didSet {
            parentTripRid = parentTrip?.rid
        }
    }
    var parentTripRid: Int?
    var details: String?
    var fitFilePath: String?
    var decodedActivityDetails: ActivityDetails?
    
    var persons: [Person] = []
    var personRids: [Int] = []
    var contextRids: [Int] = []
    
    typealias Model = ActivityInstance
    
    /// Initializes an editor from an existing ActivityInstance.
    init(from instance: ActivityInstance) {
        self.timeStart = instance.timeStart
        self.timeEnd = instance.timeEnd
        self.timed = instance.timed
        self.percentage = instance.percentage
        self.activity = instance.activity
        self.parentInstance = instance.parentInstance
        self.parentInstanceRid = instance.parentInstanceRid
        self.parentTrip = instance.parentTrip
        self.parentTripRid = instance.parentTripRid
        self.details = instance.details
        self.fitFilePath = instance.fitFilePath
        self.decodedActivityDetails = instance.decodedActivityDetails
        
        self.persons = instance.persons
        self.personRids = instance.personRids
        self.contextRids = instance.contextRids
    }
    
    func apply(to instance: ActivityInstance) {
        instance.timeStart = self.timeStart
        instance.timeEnd = self.timeEnd
        instance.timed = self.timed
        instance.percentage = self.percentage
        instance.activity = self.activity
        instance.activityRid = self.activity?.rid
        instance.parentInstance = self.parentInstance
        instance.parentInstanceRid = self.parentInstanceRid
        instance.parentTrip = self.parentTrip
        instance.parentTripRid = self.parentTripRid
        instance.details = self.details
        instance.fitFilePath = self.fitFilePath
        instance.decodedActivityDetails = self.decodedActivityDetails
        
        instance.persons = self.persons
        instance.personRids = self.persons.compactMap { $0.rid }
        instance.contextRids = self.contextRids
    }
}

extension ActivityInstance {
    @discardableResult
    static func create(in context: ModelContext, date: Date) -> ActivityInstance {
        let smartDate = date.smartCreationTime
        let isToday = Calendar.current.isDateInToday(date)
        
        let newInstance = ActivityInstance(timeStart: smartDate)
        if !isToday {
            newInstance.timeEnd = smartDate.addingTimeInterval(3600) // 1 hour later
        }
        
        context.insert(newInstance)
        try? context.save()
        return newInstance
    }
    @discardableResult
    static func createChild(in context: ModelContext, parent: any ParentModel, filterDate: Date) -> ActivityInstance {
        let calendar = Calendar.current
        let childStart: Date
        let childEnd: Date?
        
        if calendar.isDateInToday(filterDate) {
            childStart = Date()
            childEnd = nil
        } else {
            childStart = parent.timeStart.addingTimeInterval(1)
            let parentDuration: TimeInterval
            if let end = parent.timeEnd {
                parentDuration = end.timeIntervalSince(parent.timeStart)
            } else {
                parentDuration = .infinity
            }
            
            if parentDuration < 15 * 60 {
                let parentActualEnd = parent.timeEnd ?? parent.timeStart.addingTimeInterval(parentDuration)
                childEnd = parentActualEnd.addingTimeInterval(-1)
            } else {
                childEnd = childStart.addingTimeInterval(15 * 60)
            }
        }
        
        var newInstance = ActivityInstance(timeStart: childStart)
        newInstance.timeEnd = childEnd
        newInstance.setParent(parent)
        context.insert(newInstance)
        try? context.save()
        return newInstance
    }
}
