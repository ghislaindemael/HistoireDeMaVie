//
//  DataLogOptionsPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct DataLogOptionsPage: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DataLogOptionsPageViewModel()
    
    @Query(FetchDescriptor<DataLogOption>(
        sortBy: [SortDescriptor(\.slug)]))
    private var options: [DataLogOption]
    
    @State private var optionToEdit: DataLogOption?
    @State private var searchText: String = ""
    @State private var expandedCategories: Set<String> = []
    
    private struct CategoryGroup: Identifiable {
        var id: String { name }
        let name: String
        let options: [DataLogOption]
    }
    
    private var filteredOptions: [DataLogOption] {
        guard !searchText.isEmpty else { return options }
        return options.filter { option in
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
    
    private var allCategoriesExpanded: Bool {
        let allNames = Set(categoryGroups.map(\.name))
        return !allNames.isEmpty && allNames.isSubset(of: expandedCategories)
    }
    
    private func toggleExpandAll() {
        withAnimation(.snappy) {
            if allCategoriesExpanded {
                expandedCategories.removeAll()
            } else {
                expandedCategories = Set(categoryGroups.map(\.name))
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
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
            
            Button(action: toggleExpandAll) {
                Image(systemName: allCategoriesExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .foregroundStyle(.blue)
                    .padding(8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func optionRow(_ option: DataLogOption) -> some View {
        Button(action: { optionToEdit = option }) {
            DataLogOptionRowView(option: option) { opt in
                withAnimation(.snappy) {
                    viewModel.updateModel(opt) { concreteOpt in
                        concreteOpt.cache.toggle()
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation {
                    viewModel.deleteOption(option)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                optionToEdit = option
            } label: {
                Label("Edit Option", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                withAnimation {
                    viewModel.deleteOption(option)
                }
            } label: {
                Label("Delete Option", systemImage: "trash")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !options.isEmpty {
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
                    if options.isEmpty {
                        ContentUnavailableView(
                            "No Log Options",
                            systemImage: "list.bullet.rectangle",
                            description: Text("Tap '+' to create your first option.")
                        )
                    } else if filteredOptions.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .navigationTitle("Log Options")
            .logPageToolbar(
                refreshAction: { await viewModel.refreshFromServer() },
                syncAction: { await viewModel.uploadLocalChanges() },
                onAdd: handleAddOption,
                fetchArchivedAction: { await viewModel.fetchArchivedFromServer() },
                purgeArchivedAction: { viewModel.purgeArchivedFromCache() },
                trailingOptions: {
                    Button(action: toggleExpandAll) {
                        Label(
                            allCategoriesExpanded ? "Collapse All" : "Expand All",
                            systemImage: allCategoriesExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                        )
                    }
                }
            )
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .sheet(item: $optionToEdit) { option in
                DataLogOptionDetailSheet(option: option, modelContext: modelContext)
            }
        }
    }
    
    private func handleAddOption() {
        if let unset = unsetOptions.first {
            optionToEdit = unset
        } else if let newOption = viewModel.createOption() {
            withAnimation(.snappy) {
                optionToEdit = newOption
            }
        }
    }
}
