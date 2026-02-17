//
//  ParsedGPXData.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//


import Foundation
import CoreLocation
import CoreGPX

class GPXParserService {
    
    /// Parses a GPX file and returns distance/elevation metrics + GeoJSON coordinates
    func parse(url: URL) -> ParsedGPXData? {
        guard let gpx = GPXParser(withURL: url)?.parsedData() else {
            print("❌ CoreGPX failed to parse the file at \(url.path)")
            return nil
        }
        
        print("✅ Successfully parsed GPX file.")
        
        var totalDistance: Double = 0.0
        var totalGain: Double = 0.0
        var totalLoss: Double = 0.0
        var geojsonCoords: [[Double]] = []
        
        for track in gpx.tracks {
            for segment in track.segments {
                let metrics = calculateMetrics(for: segment.points)
                totalDistance += metrics.distance
                totalGain += metrics.gain
                totalLoss += metrics.loss
                
                geojsonCoords.append(contentsOf: convertPointsToGeoJSON(segment.points))
            }
        }
        
        let metrics =
            PathMetrics(
                distance: totalDistance,
                elevationGain: totalGain,
                elevationLoss: totalLoss
            )
        let geojsonTrack = GeoJSONLineString(coordinates: geojsonCoords)
        
        return ParsedGPXData(metrics: metrics, geojsonCoordinates: geojsonTrack)
    }
    
    // MARK: - Helpers
    
    private func calculateMetrics(for points: [GPXTrackPoint]) -> (distance: Double, gain: Double, loss: Double) {
        guard points.count > 1 else { return (0, 0, 0) }
        
        var distance: Double = 0.0
        var gain: Double = 0.0
        var loss: Double = 0.0
        
        for i in 1..<points.count {
            let previousPoint = points[i-1]
            let currentPoint = points[i]
            
            if let prevLat = previousPoint.latitude,
               let prevLon = previousPoint.longitude,
               let curLat = currentPoint.latitude,
               let curLon = currentPoint.longitude {
                
                let prevLocation = CLLocation(latitude: prevLat, longitude: prevLon)
                let curLocation = CLLocation(latitude: curLat, longitude: curLon)
                distance += curLocation.distance(from: prevLocation)
            }
            
            if let prevEle = previousPoint.elevation, let curEle = currentPoint.elevation {
                let diff = curEle - prevEle
                if diff > 0 {
                    gain += diff
                } else {
                    loss += abs(diff)
                }
            }
        }
        
        return (distance, gain, loss)
    }
    
    private func convertPointsToGeoJSON(_ points: [GPXTrackPoint]) -> [[Double]] {
        var coords: [[Double]] = []
        for point in points {
            if let lat = point.latitude, let lon = point.longitude {
                coords.append([lon, lat]) // GeoJSON format
            }
        }
        return coords
    }
}
