//
//  CatalogueRowControlsView.swift
//  HDMV
//

import SwiftUI

struct CatalogueRowControlsView<Model: CatalogueModel>: View {
    let model: Model
    var isFavorite: Bool? = nil
    var onFavoriteToggle: ((Model) -> Void)? = nil
    var onToggle: ((Model) -> Void)? = nil
    
    var body: some View {
        HStack {
            if !model.archived {
                if let isFav = isFavorite, let onFav = onFavoriteToggle {
                    Button {
                        onFav(model)
                    } label: {
                        Image(systemName: isFav ? "star.fill" : "star")
                            .foregroundColor(isFav ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if model.archived {
                Image(systemName: "archivebox.fill")
                    .foregroundColor(.secondary)
                    .imageScale(.medium)
            } else if let onToggle = onToggle {
                CacheToggleButton(model: model, onToggle: onToggle)
            }
            
            SyncStatusIndicator(status: model.syncStatus)
        }
    }
}
