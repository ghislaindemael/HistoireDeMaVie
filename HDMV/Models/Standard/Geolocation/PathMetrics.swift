//
//  PathMetrics.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//


import Foundation

/// A container for summary metrics of a path, like distance and elevation.
/// Conforming to Codable allows it to be stored as a single JSON object.
struct PathMetrics: Codable, Equatable, Hashable {
    var distance: Double = 0      // in meters
    var elevationGain: Double = 0 // in meters
    var elevationLoss: Double = 0 // in meters
    var pathDescription: String? = "" // description of path taken
    
    enum CodingKeys: String, CodingKey {
        case distance
        case elevationGain
        case elevationLoss
        case pathDescription
    }
    
    init() {}
    
    init(
        distance: Double = 0,
        elevationGain: Double = 0,
        elevationLoss: Double = 0,
        pathDescription: String = ""
    ) {
        self.distance = distance
        self.elevationGain = elevationGain
        self.elevationLoss = elevationLoss
        self.pathDescription = pathDescription
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        distance = try container.decodeIfPresent(Double.self, forKey: .distance) ?? 0
        elevationGain = try container.decodeIfPresent(Double.self, forKey: .elevationGain) ?? 0
        elevationLoss = try container.decodeIfPresent(Double.self, forKey: .elevationLoss) ?? 0
        pathDescription = try container.decodeIfPresent(String.self, forKey: .pathDescription) ?? ""
    }
    
}
