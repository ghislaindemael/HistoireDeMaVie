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
    var globalOptions: [DataLogOption] = []
    @Binding var decodedLogDetails: LogDetails?
    @Binding var isShowingOptionSelector: Bool
    var groupByCategory: Bool = false
    
    // We sort the items by priority without duplicate slugs
    var sortedItems: [DynamicOptionItem] {
        var result: [DynamicOptionItem] = []
        var seenSlugs = Set<String>()
        var seenOptionIds = Set<PersistentIdentifier>()
        
        let mappingItems = mappings.filter({ !$0.isDeleted && !$0.archived }).map { DynamicOptionItem(mapping: $0) }
        let globalItems = globalOptions.filter({ !$0.archived }).map { DynamicOptionItem(option: $0) }
        let allItems = (mappingItems + globalItems).sorted { $0.priority < $1.priority }
        
        for item in allItems {
            let opt = item.option ?? allOptions.first(where: { $0.slug == item.slug })
            if let opt = opt {
                if seenOptionIds.contains(opt.persistentModelID) { continue }
                seenOptionIds.insert(opt.persistentModelID)
            }
            
            let slug = opt?.slug ?? item.slug
            if !slug.isEmpty && !seenSlugs.contains(slug) {
                seenSlugs.insert(slug)
                result.append(item)
            }
        }
        return result
    }
    
    private var mappedOptionSlugs: Set<String> {
        var slugs = Set<String>()
        for item in sortedItems {
            slugs.insert(item.slug)
            if let opt = item.option ?? allOptions.first(where: { $0.slug == item.slug }) {
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
    
    private var resolvedMappedOptions: [DataLogOption] {
        sortedItems.compactMap { item in
            item.option ?? allOptions.first(where: { $0.slug == item.slug })
        }
    }
    
    private var groupedMappedOptions: [(category: String, options: [DataLogOption])] {
        var order: [String] = []
        var buckets: [String: [DataLogOption]] = [:]
        for opt in resolvedMappedOptions {
            let cat = (opt.category?.isEmpty == false ? opt.category! : "Other")
            if buckets[cat] == nil {
                order.append(cat)
                buckets[cat] = []
            }
            buckets[cat]?.append(opt)
        }
        return order.map { (category: $0, options: buckets[$0] ?? []) }
    }
    
    private func setCount(for options: [DataLogOption]) -> Int {
        guard let values = decodedLogDetails?.options else { return 0 }
        return options.filter { opt in
            if let val = values[opt.slug], !val.isEmpty {
                return true
            }
            return false
        }.count
    }
    
    var body: some View {
        Section(header: headerView("Options")) {
            if groupByCategory {
                ForEach(groupedMappedOptions, id: \.category) { group in
                    let activeCount = setCount(for: group.options)
                    DisclosureGroup {
                        ForEach(group.options, id: \.slug) { option in
                            DynamicOptionRow(
                                option: option,
                                details: $decodedLogDetails
                            )
                        }
                    } label: {
                        HStack {
                            Text(group.category)
                                .font(.body)
                            Spacer()
                            if activeCount > 0 {
                                Text("\(activeCount)/\(group.options.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(group.options.count)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            } else {
                ForEach(resolvedMappedOptions, id: \.slug) { option in
                    DynamicOptionRow(
                        option: option,
                        details: $decodedLogDetails
                    )
                }
            }
            
            ForEach(oneOffOptions, id: \.slug) { option in
                DynamicOptionRow(
                    option: option,
                    details: $decodedLogDetails,
                    onRemove: { removeOneOffOption(option.slug) }
                )
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
    var mappings: [DataLogOptionMapping] = []
    var globalOptions: [DataLogOption] = []
    @Binding var decodedLogDetails: LogDetails?
    
    private var allUsedSlugs: Set<String> {
        var slugs = Set(mappings.map(\.optionSlug))
        slugs.formUnion(globalOptions.map(\.slug))
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
        globalOptions: [DataLogOption] = [],
        decodedLogDetails: Binding<LogDetails?>
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            DynamicOptionSelectorSheet(
                mappings: mappings,
                globalOptions: globalOptions,
                decodedLogDetails: decodedLogDetails
            )
        }
    }
}

struct DynamicOptionRow: View {
    let option: DataLogOption
    @Binding var details: LogDetails?
    var onRemove: (() -> Void)? = nil
    
    @State private var isPromotedToMultiSelect: Bool = false
    
    private var isMultiSelect: Bool {
        if option.config?.multiselect == true { return true }
        if optionValue.wrappedValue.contains(",") { return true }
        return isPromotedToMultiSelect
    }
    
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
                    if onRemove != nil {
                        // For one-off options, keep the key so the row does not disappear while editing
                        details?.options?[option.slug] = ""
                    } else {
                        // For mapped options, removing the key is safe as mapped options are always retained in the UI
                        details?.options?.removeValue(forKey: option.slug)
                    }
                } else {
                    details?.options?[option.slug] = newValue
                }
            }
        )
    }
    
    private func demoteToSingleChoice() {
        withAnimation {
            isPromotedToMultiSelect = false
            var current = optionValue.wrappedValue.components(separatedBy: ",").filter { !$0.isEmpty }
            if current.count > 1 {
                optionValue.wrappedValue = current.first ?? ""
            }
        }
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
                if option.config?.multiline == true {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Value", text: optionValue, axis: .vertical)
                            .lineLimit(3...8)
                    }
                } else {
                    HStack {
                        Text(option.name)
                        Spacer()
                        TextField("Value", text: optionValue)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
            case .dropdown:
                if let config = option.config, let choices = config.choices {
                    let selectedSlugs = Set(optionValue.wrappedValue.components(separatedBy: ",").filter { !$0.isEmpty })
                    let visibleChoices = choices.filter { choice in
                        choice.archived != true || selectedSlugs.contains(choice.slug)
                    }
                    
                    if isMultiSelect {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(option.name)
                                if config.multiselect != true {
                                    Text("(Multi)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button {
                                        demoteToSingleChoice()
                                    } label: {
                                        Text("Single choice")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            FlowLayout(spacing: 6) {
                                ForEach(visibleChoices, id: \.slug) { choice in
                                    let isSelected = selectedSlugs.contains(choice.slug)
                                    HStack(spacing: 4) {
                                        if let icon = choice.icon {
                                            Image(systemName: icon)
                                        }
                                        Text(choice.label + (choice.archived == true ? " (Archived)" : ""))
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
                            ForEach(visibleChoices, id: \.slug) { choice in
                                Text(choice.label + (choice.archived == true ? " (Archived)" : "")).tag(choice.slug)
                            }
                        }
                    }
                } else {
                    Text("Invalid Dropdown Config")
                        .foregroundStyle(.red)
                }
                
            case .range:
                let minVal = option.config?.min ?? 0
                let maxVal = option.config?.max ?? 10
                let stepVal = option.config?.step ?? 1
                let sliderBinding = Binding<Double>(
                    get: { Double(optionValue.wrappedValue) ?? minVal },
                    set: { newValue in
                        if stepVal.truncatingRemainder(dividingBy: 1) == 0 {
                            optionValue.wrappedValue = String(Int(newValue.rounded()))
                        } else {
                            optionValue.wrappedValue = String(newValue)
                        }
                    }
                )
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(option.name)
                        Spacer()
                        Text(optionValue.wrappedValue.isEmpty ? "Unset" : optionValue.wrappedValue)
                            .foregroundStyle(optionValue.wrappedValue.isEmpty ? .secondary : .primary)
                            .monospacedDigit()
                    }
                    Slider(value: sliderBinding, in: minVal...maxVal, step: stepVal)
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let onRemove = onRemove {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
            
            if option.type == .dropdown, let config = option.config, config.choices != nil, config.multiselect != true {
                if isMultiSelect {
                    Button {
                        demoteToSingleChoice()
                    } label: {
                        Label("Single", systemImage: "arrow.uturn.backward")
                    }
                    .tint(.orange)
                } else {
                    Button {
                        withAnimation {
                            isPromotedToMultiSelect = true
                        }
                    } label: {
                        Label("Multi-choice", systemImage: "checklist")
                    }
                    .tint(.blue)
                }
            }
        }
        .contextMenu {
            if option.type == .dropdown, let config = option.config, config.choices != nil, config.multiselect != true {
                if isMultiSelect {
                    Button {
                        demoteToSingleChoice()
                    } label: {
                        Label("Switch to Single Choice", systemImage: "circle")
                    }
                } else {
                    Button {
                        withAnimation {
                            isPromotedToMultiSelect = true
                        }
                    } label: {
                        Label("Allow Multiple Choices", systemImage: "checklist")
                    }
                }
            }
            
            if let onRemove = onRemove {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove Option", systemImage: "trash")
                }
            }
        }
    }
}
