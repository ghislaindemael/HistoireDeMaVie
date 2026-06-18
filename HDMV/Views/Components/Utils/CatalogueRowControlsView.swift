//
//  CatalogueRowControlsView.swift
//  HDMV
//

import SwiftUI

struct CatalogueRowControlsView<Model: CatalogueModel>: View {
    let model: Model
    var onToggle: ((Model) -> Void)? = nil
    
    var body: some View {
        HStack {
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
