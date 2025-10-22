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
    
}
