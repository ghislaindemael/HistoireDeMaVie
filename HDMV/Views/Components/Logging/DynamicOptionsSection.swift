//
//  DynamicOptionsSection.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct DynamicOptionsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DataLogOption.name) private var allOptions: [DataLogOption]
    
    let mappings: [DataLogOptionMapping]
    @Binding var decodedLogDetails: LogDetails?
    @Binding var isShowingOptionSelector: Bool
    
    // We sort the mappings by priority without duplicate slugs
    var sortedMappings: [DataLogOptionMapping] {
        var result: [DataLogOptionMapping] = []
        var seenSlugs = Set<String>()
        var seenOptionIds = Set<PersistentIdentifier>()
        
        for mapping in mappings.filter({ !$0.isDeleted && !$0.archived }).sorted(by: { $0.priority < $1.priority }) {
            let opt = mapping.option ?? allOptions.first(where: { $0.slug == mapping.optionSlug })
            if let opt = opt {
                if seenOptionIds.contains(opt.persistentModelID) { continue }
                seenOptionIds.insert(opt.persistentModelID)
            }
            
            let slug = opt?.slug ?? mapping.optionSlug
            if !slug.isEmpty && !seenSlugs.contains(slug) {
                seenSlugs.insert(slug)
                if !mapping.optionSlug.isEmpty {
                    seenSlugs.insert(mapping.optionSlug)
                }
                result.append(mapping)
            }
        }
        return result
    }
    
    private var mappedOptionSlugs: Set<String> {
        var slugs = Set<String>()
        for mapping in sortedMappings {
            slugs.insert(mapping.optionSlug)
            if let opt = mapping.option ?? allOptions.first(where: { $0.slug == mapping.optionSlug }) {
                slugs.insert(opt.slug)
            }
        }
        return slugs
    }
    
    private var existingOneOffSlugs: Set<String> {
        guard let keys = decodedLogDetails?.options?.keys else { return [] }
        return Set(keys).subtracting(mappedOptionSlugs)
    }
    
    private var oneOffOptions: [DataLogOption] {
        allOptions.filter { option in
            existingOneOffSlugs.contains(option.slug) && !mappedOptionSlugs.contains(option.slug)
        }
    }
    
    var body: some View {
        Section(header: headerView("Options")) {
            ForEach(sortedMappings, id: \.optionSlug) { mapping in
                if let option = mapping.option ?? allOptions.first(where: { $0.slug == mapping.optionSlug }) {
                    DynamicOptionRow(
                        option: option,
                        details: $decodedLogDetails
                    )
                }
            }
            
            ForEach(oneOffOptions, id: \.slug) { option in
                DynamicOptionRow(
                    option: option,
                    details: $decodedLogDetails
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeOneOffOption(option.slug)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        removeOneOffOption(option.slug)
                    } label: {
                        Label("Remove Option", systemImage: "trash")
                    }
                }
            }
            
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                isShowingOptionSelector = true
            } label: {
                Label("Add Option", systemImage: "plus")
            }
        }
    }
    
    private func removeOneOffOption(_ slug: String) {
        decodedLogDetails?.options?.removeValue(forKey: slug)
    }
    
    private func headerView(_ title: String) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

struct DynamicOptionSelectorSheet: View {
    let mappings: [DataLogOptionMapping]
    @Binding var decodedLogDetails: LogDetails?
    
    private var allUsedSlugs: Set<String> {
        var slugs = Set(mappings.map(\.optionSlug))
        if let options = decodedLogDetails?.options {
            slugs.formUnion(options.keys)
        }
        return slugs
    }
    
    var body: some View {
        DataLogOptionSelectorView(
            excludedSlugs: allUsedSlugs,
            onSelect: { selectedOption in
                addOption(selectedOption)
            }
        )
    }
    
    private func addOption(_ option: DataLogOption) {
        if decodedLogDetails == nil {
            decodedLogDetails = LogDetails()
        }
        if decodedLogDetails?.options == nil {
            decodedLogDetails?.options = [:]
        }
        
        if let defaultValue = option.config?.defaultValue, !defaultValue.isEmpty {
            decodedLogDetails?.options?[option.slug] = defaultValue
        } else if option.type == .boolean {
            decodedLogDetails?.options?[option.slug] = "true"
        } else {
            decodedLogDetails?.options?[option.slug] = ""
        }
    }
}

extension View {
    func dynamicOptionSelectorSheet(
        isPresented: Binding<Bool>,
        mappings: [DataLogOptionMapping] = [],
        decodedLogDetails: Binding<LogDetails?>
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            DynamicOptionSelectorSheet(
                mappings: mappings,
                decodedLogDetails: decodedLogDetails
            )
        }
    }
}

struct DynamicOptionRow: View {
    let option: DataLogOption
    @Binding var details: LogDetails?
    
    private var optionValue: Binding<String> {
        Binding(
            get: {
                details?.options?[option.slug] ?? ""
            },
            set: { newValue in
                if details == nil {
                    details = LogDetails()
                }
                if details?.options == nil {
                    details?.options = [:]
                }
                if newValue.isEmpty {
                    details?.options?.removeValue(forKey: option.slug)
                } else {
                    details?.options?[option.slug] = newValue
                }
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch option.type {
            case .boolean:
                Toggle(option.name, isOn: Binding(
                    get: { (details?.options?[option.slug] ?? "false") == "true" },
                    set: { optionValue.wrappedValue = $0 ? "true" : "false" }
                ))
                
            case .integer:
                HStack {
                    Text(option.name)
                    Spacer()
                    TextField("0", text: optionValue)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
            case .decimal:
                HStack {
                    Text(option.name)
                    Spacer()
                    TextField("0.0", text: optionValue)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
            case .text:
                HStack {
                    Text(option.name)
                    Spacer()
                    TextField("Value", text: optionValue)
                        .multilineTextAlignment(.trailing)
                }
                
            case .dropdown:
                if let config = option.config, let choices = config.choices {
                    if config.multiselect == true {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(option.name)
                            FlowLayout(spacing: 6) {
                                ForEach(choices, id: \.slug) { choice in
                                    let isSelected = optionValue.wrappedValue.components(separatedBy: ",").contains(choice.slug)
                                    HStack(spacing: 4) {
                                        if let icon = choice.icon {
                                            Image(systemName: icon)
                                        }
                                        Text(choice.label)
                                    }
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .clipShape(Capsule())
                                        .onTapGesture {
                                            var current = optionValue.wrappedValue.components(separatedBy: ",").filter { !$0.isEmpty }
                                            if isSelected {
                                                current.removeAll { $0 == choice.slug }
                                            } else {
                                                current.append(choice.slug)
                                            }
                                            optionValue.wrappedValue = current.joined(separator: ",")
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Picker(option.name, selection: optionValue) {
                            Text("None").tag("")
                            ForEach(choices, id: \.slug) { choice in
                                Text(choice.label).tag(choice.slug)
                            }
                        }
                    }
                } else {
                    Text("Invalid Dropdown Config")
                        .foregroundStyle(.red)
                }
                
            case .rating:
                // Simple rating UI
                HStack {
                    Text(option.name)
                    Spacer()
                    Picker("Rating", selection: optionValue) {
                        Text("Unrated").tag("")
                        ForEach(1...5, id: \.self) { i in
                            Text("\(i) Stars").tag("\(i)")
                        }
                    }
                }
                
            case .time:
                let binding = Binding<Date?>(
                    get: {
                        if optionValue.wrappedValue.isEmpty { return nil }
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm:ss"
                        // Fallback to HH:mm for old data
                        if let date = formatter.date(from: optionValue.wrappedValue) {
                            return date
                        }
                        formatter.dateFormat = "HH:mm"
                        return formatter.date(from: optionValue.wrappedValue)
                    },
                    set: { newDate in
                        if let d = newDate {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm:ss"
                            optionValue.wrappedValue = formatter.string(from: d)
                        } else {
                            optionValue.wrappedValue = ""
                        }
                    }
                )
                
                HStack {
                    FullTimePicker(label: option.name, selection: binding, hideDatePicker: true)
                }
                
            default:
                Text("Unsupported type: \(option.typeRaw)")
                    .foregroundStyle(.red)
            }
        }
    }
}
