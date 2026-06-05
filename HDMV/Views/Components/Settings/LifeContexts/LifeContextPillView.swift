//
//  LifeContextPillView.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct LifeContextPillView: View {
    var explicitContext: LifeContext?
    var contextId: Int?
    
    @Query private var queriedContexts: [LifeContext]
    
    init(context: LifeContext? = nil, contextId: Int? = nil) {
        self.explicitContext = context
        self.contextId = contextId
        
        if let id = contextId {
            let filter = #Predicate<LifeContext> { $0.rid == id }
            _queriedContexts = Query(filter: filter)
        } else {
            _queriedContexts = Query(filter: #Predicate<LifeContext> { _ in false })
        }
    }
    
    private var resolvedContext: LifeContext? {
        if let context = explicitContext { return context }
        return queriedContexts.first
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = resolvedContext?.icon, !icon.isEmpty {
                IconView(iconString: icon, size: 14)
            } else {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
            }
            Text(resolvedContext?.name ?? "Unknown Context")
                .fontWeight(.semibold)
                .font(.caption)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.purple.opacity(0.15))
        )
        .foregroundColor(.purple)
    }
}
