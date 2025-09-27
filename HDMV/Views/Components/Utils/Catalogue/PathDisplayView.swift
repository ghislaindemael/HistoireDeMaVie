//
//  PathDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 27.09.2025.
//


// PathDisplayView.swift

import SwiftUI
import SwiftData

struct PathDisplayView: View {
    @Query private var paths: [Path]
    
    private let pathId: Int
    
    private var path: Path? {
        paths.first
    }

    init(pathId: Int) {
        self.pathId = pathId
        
        _paths = Query(filter: #Predicate { $0.id == pathId })
    }
    
    var body: some View {
        if let path = path {
            PathRowView(path: path)
        } else {
            HStack {
                Text("Uncached Path (ID: \(pathId))")
                Spacer()
                Image(systemName: "exclamationmark.triangle")
            }
            .foregroundColor(.orange)
        }
    }
}
