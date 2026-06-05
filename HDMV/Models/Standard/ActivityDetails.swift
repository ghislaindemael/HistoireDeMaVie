//
//  ActivityMetadata.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

// MARK: The JSON objects

struct MediaDetails: Codable {
    var itemId: Int
    var progress: String? // e.g. "Chapter 4", "Pages 40-90", "S1E4"
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
    
    // Modern Activity media logs
    var media: [MediaDetails]?
    
    var place: PlaceDetails?
    
    mutating func removeFields() {
        place?.removeFields()
    }
}
