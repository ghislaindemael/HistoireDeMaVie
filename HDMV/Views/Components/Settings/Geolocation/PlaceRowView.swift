//
//  PlaceRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct PlaceRowView: View {
    
    let place: Place
    let onCacheToggle: (Place) -> Void
    var onFavoriteToggle: ((Place) -> Void)? = nil

    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if let icon = place.placeType?.icon, !icon.isEmpty {
                            IconView(iconString: icon, size: 16)
                        }
                        UnsettableTextView(
                            text: place.name,
                            font: .body,
                            isItalicized: place.archived
                        )
                        if place.isVirtual {
                            Text("Virtual")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.12))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    if let address = place.address, !address.isEmpty {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                CatalogueRowControlsView(
                    model: place,
                    isFavorite: place.isFavorite,
                    onFavoriteToggle: onFavoriteToggle,
                    onToggle: onCacheToggle
                )
            }
        }
    }
}
