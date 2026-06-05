//
//  IconCacheManagerView.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI

struct IconCacheManagerView: View {
    @State private var cachedFiles: [String] = []
    
    var body: some View {
        List {
            Section {
                Button(role: .destructive) {
                    Task {
                        await IconCacheService.shared.clearCache()
                        await loadFiles()
                    }
                } label: {
                    Label("Clear Entire SVG Cache", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(cachedFiles.isEmpty)
            }
            
            Section(header: Text("Cached Icons (\(cachedFiles.count))")) {
                ForEach(cachedFiles, id: \.self) { filename in
                    HStack {
                        IconView(iconString: filename, size: 30)
                            .padding(.trailing, 8)
                        Text(filename)
                    }
                }
                .onDelete { indexSet in
                    let filesToDelete = indexSet.map { cachedFiles[$0] }
                    Task {
                        for file in filesToDelete {
                            await IconCacheService.shared.deleteCachedIcon(filename: file)
                        }
                        await loadFiles()
                    }
                }
            }
        }
        .navigationTitle("SVG Cache")
        .task {
            await loadFiles()
        }
    }
    
    private func loadFiles() async {
        let files = await IconCacheService.shared.getCachedFiles()
        await MainActor.run {
            self.cachedFiles = files
        }
    }
}

#Preview {
    NavigationStack {
        IconCacheManagerView()
    }
}
