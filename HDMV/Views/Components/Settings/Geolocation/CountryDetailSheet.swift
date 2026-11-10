//
//  CountryDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.11.2026.
//

import SwiftUI
import SwiftData

struct CountryDetailSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: CountryDetailSheetViewModel
    @State private var searchText: String = ""
    let country: Country
    
    init(country: Country, modelContext: ModelContext) {
        self.country = country
        _viewModel = StateObject(wrappedValue: CountryDetailSheetViewModel(model: country, modelContext: modelContext))
    }
    
    private var filteredTimeZoneIdentifiers: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return [
                "Europe/Zurich",
                "Europe/London",
                "Europe/Paris",
                "Europe/Rome",
                "Europe/Berlin",
                "Europe/Amsterdam",
                "Europe/Vienna",
                "Europe/Monaco",
                "Europe/Vatican",
                "Africa/Cairo",
                "Africa/Tunis",
                "Asia/Tokyo",
                "America/New_York",
                "America/Los_Angeles"
            ]
        }
        return all.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name)
                    TextField("Slug", text: $viewModel.editor.slug)
                }
                
                Section("Time Zone (IANA)") {
                    HStack {
                        TextField("e.g. Europe/Zurich", text: Binding(
                            get: { viewModel.editor.timezone ?? "" },
                            set: { viewModel.editor.timezone = $0.isEmpty ? nil : $0 }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        
                        if viewModel.editor.timezone != nil {
                            Button {
                                viewModel.editor.timezone = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if let tzId = viewModel.editor.timezone, let tz = TimeZone(identifier: tzId) {
                        HStack {
                            Label("Valid IANA TimeZone", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Spacer()
                            if let badge = TimeZoneFormatUtils.offsetBadgeString(for: .now, in: tz) {
                                TimeZoneBadgeView(badge: badge)
                            } else {
                                Text("Same as local TZ")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else if let tzId = viewModel.editor.timezone, !tzId.isEmpty {
                        Label("Unrecognized TimeZone identifier", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                    
                    NavigationLink {
                        List {
                            ForEach(filteredTimeZoneIdentifiers, id: \.self) { identifier in
                                Button {
                                    viewModel.editor.timezone = identifier
                                } label: {
                                    HStack {
                                        Text(identifier)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if let tz = TimeZone(identifier: identifier),
                                           let badge = TimeZoneFormatUtils.offsetBadgeString(for: .now, in: tz) {
                                            TimeZoneBadgeView(badge: badge)
                                        }
                                        if viewModel.editor.timezone == identifier {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Color.accentColor)
                                        }
                                    }
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: "Search IANA timezones")
                        .navigationTitle("Select Time Zone")
                    } label: {
                        Text("Browse Time Zones")
                    }
                }
                
                UsageSectionView(isCached: $viewModel.editor.cache, isArchived: $viewModel.editor.archived)
            }
            .navigationTitle("Edit Country")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar {
                viewModel.onDone()
                dismiss()
            }
        }
    }
}
