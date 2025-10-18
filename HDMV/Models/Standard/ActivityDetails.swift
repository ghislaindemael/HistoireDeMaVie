//
//  ActivityMetadata.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

// MARK: The JSON objects
struct ReadingDetails: Codable {
    var book_id: Int
    var pageCount: Int
}

struct PlaceDetails: Codable {
    var placeId: Int?
    var place: Place?
    
    enum CodingKeys: String, CodingKey {
        case placeId
        // place is intentionally skipped
    }
    
    mutating func removeFields() {
        self.place = nil
    }
}

// MARK: The handler

struct ActivityDetails: Codable {
    var meal: MealDetails?
    var reading: ReadingDetails?
    var place: PlaceDetails?
    
    mutating func removeFields() {
        place?.removeFields()
    }
}


