//
//  PathDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 27.09.2025.
//

import SwiftUI
import SwiftData

struct PathDisplayView: View {
    @Query private var paths: [Path]
    private let pathRid: Int?
    private let directPath: Path?
    
    private var resolvedPath: Path? {
        directPath ?? paths.first
    }
    
    // MARK: - Init with pathId (query from DB)
    init(pathRid: Int?) {
        self.pathRid = pathRid
        self.directPath = nil
        
        if let id = pathRid {
            _paths = Query(filter: #Predicate { $0.rid == id })
        } else {
            _paths = Query(filter: #Predicate { _ in false })
        }
    }
    
    // MARK: - Init with direct Path instance
    init(path: Path?) {
        self.pathRid = path?.rid
        self.directPath = path
        
        _paths = Query(filter: #Predicate { _ in false })
    }
    
    // MARK: - Body
    var body: some View {
        if let path = resolvedPath {
            PathRowView(path: path, bubble: false)
        } else if pathRid == nil {
            HStack {
                Text("Unset path")
                Spacer()
                Image(systemName: "exclamationmark.triangle")
            }
            .foregroundColor(.red)
        } else {
            HStack {
                Text("Uncached Path (ID: \(pathRid!))")
                Spacer()
                Image(systemName: "exclamationmark.triangle")
            }
            .foregroundColor(.orange)
        }
    }
}
