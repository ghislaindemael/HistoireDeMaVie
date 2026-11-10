//
//  TrackMapView.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.11.2026.
//

import SwiftUI
import MapKit

struct TrackMapView: View {
    let track: GeoJSONLineString
    var title: String = "GPS Track"
    var strokeColor: Color = .blue
    
    @State private var position: MapCameraPosition = .automatic
    @Environment(\.dismiss) private var dismiss
    
    private var coordinates: [CLLocationCoordinate2D] {
        track.coordinates.compactMap { pt -> CLLocationCoordinate2D? in
            guard pt.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pt[1], longitude: pt[0])
        }
    }
    
    var body: some View {
        NavigationStack {
            Map(position: $position, interactionModes: [.pan, .zoom]) {
                if !coordinates.isEmpty {
                    MapPolyline(coordinates: coordinates)
                        .stroke(strokeColor, lineWidth: 4)
                    
                    if let first = coordinates.first {
                        Marker("Start", coordinate: first)
                            .tint(.green)
                    }
                    
                    if let last = coordinates.last, coordinates.count > 1 {
                        Marker("End", coordinate: last)
                            .tint(.red)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                setupCamera()
            }
        }
    }
    
    private func setupCamera() {
        guard let region = boundingRegion(for: coordinates) else { return }
        position = .region(region)
    }
    
    private func boundingRegion(for coords: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coords.isEmpty else { return nil }
        var minLat = coords[0].latitude
        var maxLat = coords[0].latitude
        var minLon = coords[0].longitude
        var maxLon = coords[0].longitude
        
        for coord in coords {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        
        let deltaLat = max((maxLat - minLat) * 1.4, 0.005)
        let deltaLon = max((maxLon - minLon) * 1.4, 0.005)
        
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: deltaLat, longitudeDelta: deltaLon)
        )
    }
}
