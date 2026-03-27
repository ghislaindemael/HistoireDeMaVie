//
//  ParsedGPXData.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//

import Foundation

struct ParsedGPXData {
    let metrics: PathMetrics
    let geojsonCoordinates: GeoJSONLineString
    let timeStart: Date
    let timeEnd: Date
}
