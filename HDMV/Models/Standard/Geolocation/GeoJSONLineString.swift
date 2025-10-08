//
//  GeoJSONLineString.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//


struct GeoJSONLineString: Codable {
    var type: String = "LineString"
    var coordinates: [[Double]]
}
