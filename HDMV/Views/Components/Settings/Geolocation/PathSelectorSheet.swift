//
//  PathSelectorSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 27.09.2025.
//


import SwiftUI
import SwiftData

struct PathSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let startPlaceId: Int?
    let endPlaceId: Int?
    let onPathSelected: (Int) -> Void
    
    @State private var exactMatches: [Path] = []
    @State private var partialMatches: [Path] = []
    @State private var otherPaths: [Path] = []
    
    @State private var showAllPaths = false
    
    init(
        startPlaceId: Int? = nil,
        endPlaceId: Int? = nil,
        onPathSelected: @escaping (Int) -> Void
    ) {
        self.startPlaceId = startPlaceId
        self.endPlaceId = endPlaceId
        self.onPathSelected = onPathSelected
    }
    
    var body: some View {
        NavigationView {
            Form {
                if !exactMatches.isEmpty {
                    Section("Exact Matches") {
                        ForEach(exactMatches) { path in
                            pathRow(for: path)
                        }
                    }
                }
                
                
                if !partialMatches.isEmpty {
                    Section("Partial Matches") {
                        ForEach(partialMatches) { path in
                            pathRow(for: path)
                        }
                    }
                }
                
                Section {
                    Toggle("Show All Other Cached Paths", isOn: $showAllPaths)
                    if showAllPaths {
                        ForEach(otherPaths) { path in
                            pathRow(for: path)
                        }
                    }
                }
                
                
            }
            .navigationTitle("Select a Path")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                fetchInitialPaths()
            }
            .onChange(of: showAllPaths) {
                if showAllPaths && otherPaths.isEmpty {
                    fetchOtherPaths()
                }
            }
        }
    }
    
    // MARK: - Data Fetching Methods
    
    private func fetchInitialPaths() {
        guard let startId = startPlaceId, let endId = endPlaceId else { return }
        
        
        let predicate = #Predicate<Path> { $0.cache == true }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\Path.name)])
        guard let cachedPaths = try? modelContext.fetch(descriptor) else { return }
        
        self.exactMatches = cachedPaths.filter { $0.place_start_id == startId && $0.place_end_id == endId }
        
        let exactMatchIds = Set(self.exactMatches.map { $0.id })
        self.partialMatches = cachedPaths.filter { path in
            guard !exactMatchIds.contains(path.id) else { return false }
            return path.place_start_id == startId || path.place_end_id == endId
        }
        
    }
    
    private func fetchOtherPaths() {
        let predicate = #Predicate<Path> { $0.cache == true }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\Path.name)])
        guard let cachedPaths = try? modelContext.fetch(descriptor) else { return }
        
        var displayedIds = Set(partialMatches.map { $0.id })
        let exactMatchIds = Set(exactMatches.map { $0.id })
        displayedIds.formUnion(exactMatchIds)
        
        self.otherPaths = cachedPaths.filter { !displayedIds.contains($0.id) }
    }
    
    /// A helper view builder to avoid repeating the button/row code.
    @ViewBuilder
    private func pathRow(for path: Path) -> some View {
        Button(action: {
            onPathSelected(path.id)
            dismiss()
        }) {
            PathRowView(path: path)
        }
        .buttonStyle(.plain)
    }
}
