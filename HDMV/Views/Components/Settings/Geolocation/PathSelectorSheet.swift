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
    let selectedVehicle: Vehicle?
    let onPathSelected: (Path) -> Void
    
    @State private var forwardMatches: [Path] = []
    @State private var reverseMatches: [Path] = []
    @State private var partialMatches: [Path] = []
    @State private var otherPaths: [Path] = []
    
    @State private var showAllPaths = false
    
    init(
        startPlaceId: Int? = nil,
        endPlaceId: Int? = nil,
        selectedVehicle: Vehicle? = nil,
        onPathSelected: @escaping (Path) -> Void
    ) {
        self.startPlaceId = startPlaceId
        self.endPlaceId = endPlaceId
        self.selectedVehicle = selectedVehicle
        self.onPathSelected = onPathSelected
    }
    
    var body: some View {
        NavigationView {
            Form {
                if !forwardMatches.isEmpty {
                    Section("Exact Matches") {
                        ForEach(forwardMatches) { path in
                            pathRow(for: path, isReversed: false)
                        }
                    }
                }
                
                if !reverseMatches.isEmpty {
                    Section("Reverse Matches") {
                        ForEach(reverseMatches) { path in
                            pathRow(for: path, isReversed: true)
                        }
                    }
                }
                
                if !partialMatches.isEmpty {
                    Section("Partial Matches") {
                        ForEach(partialMatches) { path in
                            pathRow(for: path, isReversed: false)
                        }
                    }
                }
                
                Section {
                    Toggle("Show All Other Cached Paths", isOn: $showAllPaths)
                    if showAllPaths {
                        ForEach(otherPaths) { path in
                            pathRow(for: path, isReversed: false)
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
    
    private func fetchCachedPaths() -> [Path] {
        let predicate = #Predicate<Path> { $0.cache == true && $0.archived == false }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\Path.name)])
        let allCached = (try? modelContext.fetch(descriptor)) ?? []
        return allCached.filter { $0.matchesVehicle(selectedVehicle) }
    }
    
    private func fetchInitialPaths() {
        let cachedPaths = fetchCachedPaths()
        
        guard let startId = startPlaceId, let endId = endPlaceId else {
            self.forwardMatches = []
            self.reverseMatches = []
            self.partialMatches = cachedPaths.filter { $0.matchesAnyPlace(startRid: startPlaceId, endRid: endPlaceId) }
            return
        }
        
        var forward: [Path] = []
        var reverse: [Path] = []
        var partial: [Path] = []
        
        for path in cachedPaths {
            switch path.matchDirection(startRid: startId, endRid: endId) {
            case .forward:
                forward.append(path)
            case .reverse:
                reverse.append(path)
            case nil:
                if path.matchesAnyPlace(startRid: startId, endRid: endId) {
                    partial.append(path)
                }
            }
        }
        
        self.forwardMatches = forward
        self.reverseMatches = reverse
        self.partialMatches = partial
    }
    
    private func fetchOtherPaths() {
        let cachedPaths = fetchCachedPaths()
        
        var displayedIds = Set(forwardMatches.map { $0.id })
        displayedIds.formUnion(reverseMatches.map { $0.id })
        displayedIds.formUnion(partialMatches.map { $0.id })
        
        self.otherPaths = cachedPaths.filter { !displayedIds.contains($0.id) }
    }
    
    @ViewBuilder
    private func pathRow(for path: Path, isReversed: Bool) -> some View {
        Button(action: {
            onPathSelected(path)
            dismiss()
        }) {
            PathRowView(path: path, isReversed: isReversed)
        }
        .buttonStyle(.plain)
    }
}
