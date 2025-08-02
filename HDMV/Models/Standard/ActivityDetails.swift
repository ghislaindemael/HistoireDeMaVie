//
//  ActivityMetadata.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

// MARK: The JSON objects
struct MealDetails: Codable {
    var mealContent: String
}

struct ReadingDetails: Codable {
    var book_id: Int
    var pageCount: Int
}

struct TripDetails: Codable {
    
}

// MARK: The handler
enum ActivityDetails: Codable {
    case meal(MealDetails)
    case reading(ReadingDetails)
    case trip(TripDetails)
    case generic
    case unknown
    
    private enum CodingKeys: String, CodingKey {
        case type
        case payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "meal":
            let details = try container.decode(MealDetails.self, forKey: .payload)
            self = .meal(details)
        case "reading":
            let details = try container.decode(ReadingDetails.self, forKey: .payload)
            self = .reading(details)
        default:
            self = .unknown
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .meal(let details):
            try container.encode("meal", forKey: .type)
            try container.encode(details, forKey: .payload)
        case .reading(let details):
            try container.encode("reading", forKey: .type)
            try container.encode(details, forKey: .payload)
        case .trip(let details):
            try container.encode("trip", forKey: .type)
            try container.encode(details, forKey: .payload)
        case .generic:
            try container.encode("generic", forKey: .type)
        case .unknown:
            try container.encode("unknown", forKey: .type)
        }
        
    }
}
