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
    
    let activity: Activity
    @Binding var decodedActivityDetails: ActivityDetails?
    
    // We sort the mappings by priority
    var sortedMappings: [DataActivityOptionMapping] {
        activity.optionMappings.sorted { $0.priority < $1.priority }
    }
    
    var body: some View {
        if !sortedMappings.isEmpty {
            Section(header: headerView("Options")) {
                ForEach(sortedMappings) { mapping in
                    if let option = mapping.option {
                        DynamicOptionRow(
                            option: option,
                            details: $decodedActivityDetails
                        )
                    }
                }
            }
        }
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

struct DynamicOptionRow: View {
    let option: DataActivityOption
    @Binding var details: ActivityDetails?
    
    private var optionValue: Binding<String> {
        Binding(
            get: {
                details?.options?[option.slug] ?? ""
            },
            set: { newValue in
                if details == nil {
                    details = ActivityDetails()
                }
                if details?.options == nil {
                    details?.options = [:]
                }
                
                if newValue.isEmpty {
                    details?.options?[option.slug] = nil
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
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(choices, id: \.self) { choice in
                                        let isSelected = optionValue.wrappedValue.components(separatedBy: ",").contains(choice)
                                        Text(choice)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(isSelected ? .white : .primary)
                                            .clipShape(Capsule())
                                            .onTapGesture {
                                                var current = optionValue.wrappedValue.components(separatedBy: ",").filter { !$0.isEmpty }
                                                if isSelected {
                                                    current.removeAll { $0 == choice }
                                                } else {
                                                    current.append(choice)
                                                }
                                                optionValue.wrappedValue = current.joined(separator: ",")
                                            }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Picker(option.name, selection: optionValue) {
                            Text("None").tag("")
                            ForEach(choices, id: \.self) { choice in
                                Text(choice).tag(choice)
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
                
            default:
                Text("Unsupported type: \(option.typeRaw)")
                    .foregroundStyle(.red)
            }
        }
    }
}
