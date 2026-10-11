//
//  PlaceGeometryMapView.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.10.2025.
//

import SwiftUI
import MapKit

struct PlaceGeometryMapView: View {
    let geometry: PlaceGeometry
    
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $position, interactionModes: [.pan, .zoom]) {
            switch geometry.type {
            case .point:
                if let lat = geometry.centerLatitude, let lon = geometry.centerLongitude {
                    Marker("Location", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        .tint(.red)
                }
                
            case .circle:
                if let lat = geometry.centerLatitude, let lon = geometry.centerLongitude {
                    let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    let radius = geometry.radiusMeters ?? 50.0
                    
                    MapCircle(center: center, radius: radius)
                        .foregroundStyle(Color.blue.opacity(0.2))
                        .stroke(Color.blue, lineWidth: 2)
                    
                    Marker("Center", coordinate: center)
                        .tint(.blue)
                }
                
            case .lineString:
                let coords = (geometry.lineCoordinates ?? []).compactMap { pt -> CLLocationCoordinate2D? in
                    guard pt.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: pt[1], longitude: pt[0])
                }
                if !coords.isEmpty {
                    MapPolyline(coordinates: coords)
                        .stroke(Color.orange, lineWidth: 3)
                }
                
            case .polygon:
                let coords = (geometry.polygonCoordinates?.first ?? []).compactMap { pt -> CLLocationCoordinate2D? in
                    guard pt.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: pt[1], longitude: pt[0])
                }
                if !coords.isEmpty {
                    MapPolygon(coordinates: coords)
                        .foregroundStyle(Color.purple.opacity(0.25))
                        .stroke(Color.purple, lineWidth: 2)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .onAppear {
            setupCamera()
        }
    }
    
    private func setupCamera() {
        guard let lat = geometry.centerLatitude, let lon = geometry.centerLongitude else { return }
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        switch geometry.type {
        case .point:
            position = .region(MKCoordinateRegion(
                center: center,
                latitudinalMeters: 600,
                longitudinalMeters: 600
            ))
        case .circle:
            let radius = geometry.radiusMeters ?? 50.0
            let spanDistance = max(radius * 3.5, 300.0)
            position = .region(MKCoordinateRegion(
                center: center,
                latitudinalMeters: spanDistance,
                longitudinalMeters: spanDistance
            ))
        case .lineString:
            let coords = (geometry.lineCoordinates ?? []).compactMap { pt -> CLLocationCoordinate2D? in
                guard pt.count >= 2 else { return nil }
                return CLLocationCoordinate2D(latitude: pt[1], longitude: pt[0])
            }
            if let region = boundingRegion(for: coords) {
                position = .region(region)
            } else {
                position = .region(MKCoordinateRegion(center: center, latitudinalMeters: 800, longitudinalMeters: 800))
            }
        case .polygon:
            let coords = (geometry.polygonCoordinates?.first ?? []).compactMap { pt -> CLLocationCoordinate2D? in
                guard pt.count >= 2 else { return nil }
                return CLLocationCoordinate2D(latitude: pt[1], longitude: pt[0])
            }
            if let region = boundingRegion(for: coords) {
                position = .region(region)
            } else {
                position = .region(MKCoordinateRegion(center: center, latitudinalMeters: 800, longitudinalMeters: 800))
            }
        }
    }
    
    private func boundingRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        
        let deltaLat = max((maxLat - minLat) * 1.5, 0.003)
        let deltaLon = max((maxLon - minLon) * 1.5, 0.003)
        
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: deltaLat, longitudeDelta: deltaLon)
        )
    }
}
