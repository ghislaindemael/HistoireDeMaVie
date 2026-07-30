//
//  Quote.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftData
import Foundation

@Model
final class Quote: LogModel, TimeBound {
    
    @Attribute(.unique) var rid: Int?
    var text: String = ""
    var timeStart: Date = Date() // Equivalent to `date` in DB
    var timeEnd: Date? = nil
    var authorString: String?
    
    var personRid: Int?
    var context: String?
    var mediaDetailsData: Data?
    
    var parentInteractionRid: Int?
    var parentInstanceRid: Int?
    var parentTripRid: Int?
    
    var syncStatusRaw: String = SyncStatus.undef.rawValue
    
    typealias DTO = QuoteDTO
    typealias Payload = QuotePayload
    typealias Editor = QuoteEditor
    
    // MARK: Relationships
    
    @Relationship(deleteRule: .nullify)
    var person: Person?
    

    
    @Relationship(deleteRule: .nullify)
    var parentInteraction: Interaction?
    
    @Relationship(deleteRule: .nullify)
    var parentInstance: ActivityInstance?
    
    @Relationship(deleteRule: .nullify)
    var parentTrip: Trip?
    
    // MARK: Init
    
    init(rid: Int? = nil,
         text: String = "",
         timeStart: Date = .now,
         authorString: String? = nil,
         person: Person? = nil,
         mediaDetailsData: Data? = nil,
         context: String? = nil,
         parentInteraction: Interaction? = nil,
         parentInstance: ActivityInstance? = nil,
         parentTrip: Trip? = nil,
         syncStatus: SyncStatus = .unsynced
    ){
        self.rid = rid
        self.text = text
        self.timeStart = timeStart
        self.authorString = authorString
        self.person = person
        self.mediaDetailsData = mediaDetailsData
        self.context = context
        self.parentInteraction = parentInteraction
        self.parentInstance = parentInstance
        self.parentTrip = parentTrip
        self.syncStatus = syncStatus
    }
    
    convenience init(fromDto dto: QuoteDTO) {
        self.init()
        self.rid = dto.id
        self.text = dto.text
        self.timeStart = dto.date
        self.authorString = dto.author_string
        self.personRid = dto.person_id
        
        // Handle migration gracefully if old data is present but new data isn't
        if let details = dto.media_details {
            self.mediaDetailsData = try? JSONEncoder().encode(details)
        } else if let oldItemId = dto.media_item_id {
            let legacyDetails = MediaDetails(itemId: oldItemId, progress: dto.media_progress)
            self.mediaDetailsData = try? JSONEncoder().encode(legacyDetails)
        } else {
            self.mediaDetailsData = nil
        }
        
        self.context = dto.context
        self.parentInteractionRid = dto.parent_interaction_id
        self.parentInstanceRid = dto.parent_instance_id
        self.parentTripRid = dto.parent_trip_id
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: QuoteDTO) {
        self.text = dto.text
        self.timeStart = dto.date
        self.authorString = dto.author_string
        if let details = dto.media_details {
            self.mediaDetailsData = try? JSONEncoder().encode(details)
        } else if let oldItemId = dto.media_item_id {
            let legacyDetails = MediaDetails(itemId: oldItemId, progress: dto.media_progress)
            self.mediaDetailsData = try? JSONEncoder().encode(legacyDetails)
        } else {
            self.mediaDetailsData = nil
        }
        
        self.context = dto.context
        
        self.personRid = dto.person_id
        self.parentInteractionRid = dto.parent_interaction_id
        self.parentInstanceRid = dto.parent_instance_id
        self.parentTripRid = dto.parent_trip_id
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return !text.isEmpty
    }
}

// MARK: - DTO & Payload

struct QuoteDTO: Identifiable, Codable, Sendable {
    let id: Int
    let text: String
    let date: Date
    let author_string: String?
    let person_id: Int?
    let media_item_id: Int?
    let media_progress: String?
    let media_details: MediaDetails?
    let parent_interaction_id: Int?
    let parent_instance_id: Int?
    let parent_trip_id: Int?
    let context: String?
}

struct QuotePayload: Codable, InitializableWithModel {
    let text: String
    let date: Date
    let author_string: String?
    @ExplicitNull var person_id: Int?
    @ExplicitNull var media_item_id: Int?
    let media_progress: String?
    let media_details: MediaDetails?
    @ExplicitNull var parent_interaction_id: Int?
    @ExplicitNull var parent_instance_id: Int?
    @ExplicitNull var parent_trip_id: Int?
    let context: String?
    
    typealias Model = Quote
    
    init?(from quote: Quote) {
        guard quote.isValid() else { return nil }
        
        self.text = quote.text
        self.date = quote.timeStart
        self.author_string = quote.authorString
        self.person_id = quote.person?.rid ?? quote.personRid
        
        if let data = quote.mediaDetailsData, let details = try? JSONDecoder().decode(MediaDetails.self, from: data) {
            self.media_details = details
            self.media_item_id = details.itemId
            self.media_progress = details.progress
        } else {
            self.media_details = nil
            self.media_item_id = nil
            self.media_progress = nil
        }
        self.parent_interaction_id = quote.parentInteraction?.rid ?? quote.parentInteractionRid
        self.parent_instance_id = quote.parentInstance?.rid ?? quote.parentInstanceRid
        self.parent_trip_id = quote.parentTrip?.rid ?? quote.parentTripRid
        self.context = quote.context
    }
}

// MARK: - Editor

struct QuoteEditor: EditorProtocol, LinkedParent, TimeBound {
    var text: String
    var timeStart: Date
    var timeEnd: Date?
    var authorString: String?
    
    var person: Person?
    var personRid: Int?
    
    var mediaDetails: MediaDetails?
    var context: String?
    
    var parentInteraction: Interaction?
    var parentInteractionRid: Int?
    
    var parentInstance: ActivityInstance?
    var parentInstanceRid: Int?
    
    var parentTrip: Trip?
    var parentTripRid: Int?
    
    typealias Model = Quote
    
    init(from quote: Quote) {
        self.text = quote.text
        self.timeStart = quote.timeStart
        self.timeEnd = quote.timeEnd
        self.authorString = quote.authorString
        self.person = quote.person
        self.personRid = quote.personRid
        
        if let data = quote.mediaDetailsData, let details = try? JSONDecoder().decode(MediaDetails.self, from: data) {
            self.mediaDetails = details
        } else {
            self.mediaDetails = nil
        }
        
        self.context = quote.context
        
        self.parentInteraction = quote.parentInteraction
        self.parentInteractionRid = quote.parentInteractionRid
        self.parentInstance = quote.parentInstance
        self.parentInstanceRid = quote.parentInstanceRid
        self.parentTrip = quote.parentTrip
        self.parentTripRid = quote.parentTripRid
    }
    
    func apply(to quote: Quote) {
        quote.text = self.text
        quote.timeStart = self.timeStart
        quote.timeEnd = self.timeEnd
        quote.authorString = self.authorString
        
        quote.person = self.person
        quote.personRid = self.person?.rid ?? self.personRid
        
        if let details = self.mediaDetails {
            quote.mediaDetailsData = try? JSONEncoder().encode(details)
        } else {
            quote.mediaDetailsData = nil
        }
        
        quote.context = self.context
        
        quote.parentInteraction = self.parentInteraction
        quote.parentInteractionRid = self.parentInteraction?.rid ?? self.parentInteractionRid
        
        quote.parentInstance = self.parentInstance
        quote.parentInstanceRid = self.parentInstance?.rid ?? self.parentInstanceRid
        
        quote.parentTrip = self.parentTrip
        quote.parentTripRid = self.parentTrip?.rid ?? self.parentTripRid
        
        quote.markAsModified()
    }
}

extension Quote {
    @discardableResult
    static func create(in context: ModelContext, date: Date) -> Quote {
        let smartDate = date.smartCreationTime
        let newQuote = Quote(timeStart: smartDate)
        newQuote.timeEnd = smartDate
        context.insert(newQuote)
        try? context.save()
        return newQuote
    }
}
