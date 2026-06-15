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
    
    var rid: Int?
    var text: String = ""
    var timeStart: Date = Date() // Equivalent to `date` in DB
    var timeEnd: Date? = nil
    var authorString: String?
    
    var personRid: Int?
    var mediaItemRid: Int?
    var mediaProgress: String?
    var context: String?
    
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
    var mediaItem: DataMediaItem?
    
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
         mediaItem: DataMediaItem? = nil,
         mediaProgress: String? = nil,
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
        self.mediaItem = mediaItem
        self.mediaProgress = mediaProgress
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
        self.mediaItemRid = dto.media_item_id
        self.mediaProgress = dto.media_progress
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
        self.mediaProgress = dto.media_progress
        self.context = dto.context
        
        self.personRid = dto.person_id
        self.mediaItemRid = dto.media_item_id
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
        self.media_item_id = quote.mediaItem?.rid ?? quote.mediaItemRid
        self.media_progress = quote.mediaProgress
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
    
    var mediaItem: DataMediaItem?
    var mediaItemRid: Int?
    
    var mediaProgress: String?
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
        self.mediaItem = quote.mediaItem
        self.mediaItemRid = quote.mediaItemRid
        self.mediaProgress = quote.mediaProgress
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
        
        quote.mediaItem = self.mediaItem
        quote.mediaItemRid = self.mediaItem?.rid ?? self.mediaItemRid
        
        quote.mediaProgress = self.mediaProgress
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
