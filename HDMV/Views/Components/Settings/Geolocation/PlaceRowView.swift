//
//  PlaceRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct PlaceRowView: View {
    let place: Place
    
    var body: some View {
        Text(place.name)
    }
}