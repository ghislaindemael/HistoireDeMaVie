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

struct TripDetails: Codable {
    
}

struct PlaceDetails: Codable {
    var placeId: Int?
}

// MARK: The handler

struct ActivityDetails: Codable {
    var type: ActivityType
    var meal: MealDetails?
    var reading: ReadingDetails?
    var trip: TripDetails?
    
    var place: PlaceDetails?
}


