//
//  DataLogOptionSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct DataLogOptionSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DataLogOption.name) private var allOptions: [DataLogOption]
    
    var excludedSlugs: Set<String> = []
    let onSelect: (DataLogOption) -> Void
    
    @State private var searchText: String = ""
    @State private var expandedCategories: Set<String> = []
    
    init(excludedSlugs: Set<String> = [], onSelect: @escaping (DataLogOption) -> Void) {
        self.excludedSlugs = excludedSlugs
        self.onSelect = onSelect
    }
    
    private struct CategoryGroup: Identifiable {
        var id: String { name }
        let name: String
        let options: [DataLogOption]
    }
    
    private var availableOptions: [DataLogOption] {
        let activeOptions = allOptions.filter { !$0.archived }
        if excludedSlugs.isEmpty {
            return activeOptions
        }
        return activeOptions.filter { !excludedSlugs.contains($0.slug) }
    }
    
    private var filteredOptions: [DataLogOption] {
        let base = availableOptions
        guard !searchText.isEmpty else { return base }
        return base.filter { option in
            option.name.localizedCaseInsensitiveContains(searchText) ||
            option.slug.localizedCaseInsensitiveContains(searchText) ||
            (option.category?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var unsetOptions: [DataLogOption] {
        filteredOptions.filter { $0.slug.hasPrefix("!") || $0.slug == "unset" }
    }
    
    private var categorizedOptions: [DataLogOption] {
        filteredOptions.filter { !$0.slug.hasPrefix("!") && $0.slug != "unset" }
    }
    
    private var categoryGroups: [CategoryGroup] {
        let grouped = Dictionary(grouping: categorizedOptions) { option -> String in
            let cat = option.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return cat.isEmpty ? "General" : cat
        }
        
        return grouped.map { name, options in
            CategoryGroup(
                name: name,
                options: options.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            )
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    private func isCategoryExpanded(_ categoryName: String) -> Binding<Bool> {
        Binding(
            get: {
                if !searchText.isEmpty { return true }
                return expandedCategories.contains(categoryName)
            },
            set: { isExpanded in
                if isExpanded {
                    expandedCategories.insert(categoryName)
                } else {
                    expandedCategories.remove(categoryName)
                }
            }
        )
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search options", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func optionRow(_ option: DataLogOption) -> some View {
        Button {
            onSelect(option)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(option.slug)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(option.typeRaw.capitalized)
                    .font(.caption2)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !availableOptions.isEmpty {
                    searchBar
                }
                
                List {
                    if !unsetOptions.isEmpty {
                        Section {
                            ForEach(unsetOptions) { option in
                                optionRow(option)
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.orange)
                                Text("New / Unset")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                Spacer()
                                Text("\(unsetOptions.count)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    ForEach(categoryGroups) { group in
                        DisclosureGroup(isExpanded: isCategoryExpanded(group.name)) {
                            ForEach(group.options) { option in
                                optionRow(option)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "folder")
                                    .foregroundStyle(.blue)
                                Text(group.name)
                                    .font(.headline)
                                Spacer()
                                Text("\(group.options.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .overlay {
                    if availableOptions.isEmpty {
                        ContentUnavailableView(
                            "No Options Available",
                            systemImage: "slider.horizontal.3",
                            description: Text("All available log options are already added.")
                        )
                    } else if categoryGroups.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .navigationTitle("Select Option")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                if !categoryGroups.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            withAnimation {
                                if expandedCategories.count == categoryGroups.count {
                                    expandedCategories.removeAll()
                                } else {
                                    expandedCategories = Set(categoryGroups.map(\.name))
                                }
                            }
                        } label: {
                            Image(systemName: expandedCategories.count == categoryGroups.count ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        }
                        .help(expandedCategories.count == categoryGroups.count ? "Collapse All" : "Expand All")
                    }
                }
            }
        }
    }
}
