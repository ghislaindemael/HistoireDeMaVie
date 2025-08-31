//
//  SyncingOverlayExtension.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.08.2025.
//


import SwiftUI

extension View {
    @ViewBuilder
    func syncingOverlay(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ProgressView("Loading...")
                    .padding()
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }
        }
    }
}
