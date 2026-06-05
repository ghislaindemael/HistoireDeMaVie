//
//  LifeContextsDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI
import SwiftData

struct LifeContextsDisplayView: View {
    let contextRids: [Int]
    
    var body: some View {
        if !contextRids.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(contextRids, id: \.self) { rid in
                    LifeContextPillView(contextId: rid)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
