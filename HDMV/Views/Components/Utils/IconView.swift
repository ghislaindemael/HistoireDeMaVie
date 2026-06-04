//
//  IconView.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.07.2025.
//

import SwiftUI

struct IconView: View {
    let iconString: String
    var size: CGFloat = 25
    var tint: Color = .primary
    
    private enum IconType {
        case sfSymbol
        case asset
        case emoji
        case svg
        case unknown
    }
    
    private var detectedType: IconType {
        if iconString.isEmpty {
            return .unknown
        } else if UIImage(systemName: iconString) != nil {
            return .sfSymbol
        } else if UIImage(named: iconString) != nil {
            return .asset
        } else if iconString.unicodeScalars.count == 1,
                  iconString.unicodeScalars.first?.properties.isEmoji == true {
            return .emoji
        } else if iconString.hasSuffix(".svg") {
            return .svg
        }
        return .unknown
    }
    
    var body: some View {
        switch detectedType {
            case .sfSymbol:
                Image(systemName: iconString)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(tint)
                
            case .asset:
                Image(iconString) // xcassets
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(tint)
                
            case .emoji:
                Text(iconString)
                    .font(.system(size: size))
                
            case .svg:
                CachedSVGIconView(filename: iconString, size: size, tint: tint)
                
            case .unknown:
                Image(systemName: "questionmark.circle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(.gray)
        }
    }
}

// MARK: - Cached SVG Handler
import SVGView

struct CachedSVGIconView: View {
    let filename: String
    let size: CGFloat
    let tint: Color
    
    @State private var fileURL: URL? = nil
    @State private var isDownloading = false
    @State private var hasError = false
    
    var body: some View {
        Group {
            if let fileURL = fileURL {
                SVGView(contentsOf: fileURL)
                    .frame(width: size, height: size)
                    .colorMultiply(tint)
            } else if hasError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(.orange)
            } else {
                // Downloading or Loading state
                ProgressView()
                    .frame(width: size, height: size)
            }
        }
        .task {
            await loadIcon()
        }
    }
    
    private func loadIcon() async {
        // 1. Check if already cached
        if let existing = await IconCacheService.shared.getCachedIconURL(filename: filename) {
            self.fileURL = existing
            return
        }
        
        // 2. Otherwise download
        self.isDownloading = true
        do {
            let downloaded = try await IconCacheService.shared.downloadAndCacheIcon(filename: filename)
            self.fileURL = downloaded
        } catch {
            print("Failed to download SVG \(filename): \(error)")
            self.hasError = true
        }
        self.isDownloading = false
    }
}

