//
//  LinkedFilesPillView.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.10.2026.
//

import SwiftUI

struct LinkedFilesPillView: View {
    let fileTypes: [String]
    
    init(fileTypes: [String]) {
        self.fileTypes = fileTypes
    }
    
    init(filePaths: [String?]) {
        let exts = filePaths
            .compactMap { $0 }
            .compactMap { path -> String? in
                let ext = (path as NSString).pathExtension.lowercased()
                return ext.isEmpty ? nil : ext
            }
        
        var unique: [String] = []
        for ext in exts {
            if !unique.contains(ext) {
                unique.append(ext)
            }
        }
        self.fileTypes = unique.sorted()
    }
    
    init(trip: Trip) {
        var paths: [String] = trip.linkedFilePaths
        for child in trip.childTrips {
            paths.append(contentsOf: child.linkedFilePaths)
        }
        self.init(filePaths: paths)
    }
    
    init(instance: ActivityInstance) {
        var paths: [String] = instance.linkedFilePaths
        for childTrip in instance.childTrips {
            paths.append(contentsOf: childTrip.linkedFilePaths)
        }
        self.init(filePaths: paths)
    }
    
    var body: some View {
        if !fileTypes.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "paperclip")
                    .font(.subheadline)
                
                Text(fileTypes.map { ".\($0)" }.joined(separator: ", "))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.mint.opacity(0.15))
            .foregroundStyle(Color.mint)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
