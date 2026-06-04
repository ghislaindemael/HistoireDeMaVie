//
//  LifeContextsDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI
import SwiftData

struct LifeContextsDisplayView: View {
    @Environment(\.modelContext) private var modelContext
    
    let contextRids: [Int]
    
    @State private var fetchedContexts: [LifeContext] = []
    
    var body: some View {
        if !contextRids.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                if !fetchedContexts.isEmpty {
                    ForEach(fetchedContexts) { context in
                        HStack(spacing: 4) {
                            if let icon = context.icon, !icon.isEmpty {
                                IconView(iconString: icon)
                            } else {
                                Image(systemName: "tag.fill")
                            }
                            Text(context.name)
                                .fontWeight(.semibold)
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                        Text("\(contextRids.count) Contexts (Uncached)")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(0.15))
            .foregroundColor(.purple)
            .cornerRadius(8)
            .onAppear {
                fetchContexts()
            }
        }
    }
    
    private func fetchContexts() {
        guard !contextRids.isEmpty else { return }
        do {
            let descriptor = FetchDescriptor<LifeContext>()
            let allLocal = try modelContext.fetch(descriptor)
            self.fetchedContexts = allLocal.filter {
                guard let rid = $0.rid else { return false }
                return contextRids.contains(rid)
            }
        } catch {
            print("Failed to fetch life contexts: \(error)")
        }
    }
}
