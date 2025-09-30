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
    
    private let pathId: Int?
    
    private var path: Path? {
        paths.first
    }

    init(pathId: Int?) {
        self.pathId = pathId
        if let id = pathId {
            _paths = Query(filter: #Predicate { $0.id == id })
        } else {
            _paths = Query(filter: #Predicate { _ in false })
        }
    }
    
    var body: some View {
        if let path = path {
            PathRowView(path: path)
        } else if pathId == nil {
            HStack {
                Text("Unset path")
                Spacer()
                Image(systemName: "exclamationmark.triangle")
            }
            .foregroundColor(.red)
        } else {
            HStack {
                Text("Uncached Path (ID: \(pathId ?? -1))")
                Spacer()
                Image(systemName: "exclamationmark.triangle")
            }
            .foregroundColor(.orange)
        }
    }
}
