//
//  FullTimePickerSheetView.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.06.2025.
//

import SwiftUI

struct FullTimePicker: View {
    let label: String
    @Binding var selection: Date?
    
    private let placeholderColor = Color(.systemGray4)
    private let placeholderCornerRadius: CGFloat = 5
    
    @State private var isExpanded = false
    
    @State private var hour: Int = 0
    @State private var minute: Int = 0
    @State private var second: Int = 0
    
    @State private var selectedDateOnly: Date = Date()

    init(label: String, selection: Binding<Date?>) {
        self.label = label
        self._selection = selection
    }
    
    init(label: String, selection: Binding<Date>) {
        self.label = label
        self._selection = Binding<Date?>(
            get: { selection.wrappedValue },
            set: { selection.wrappedValue = $0 ?? selection.wrappedValue }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                Spacer()
                if selection != nil {
                    picker
                } else {
                    placeholder
                }
                
            }
            .animation(nil, value: isExpanded)
            
            if isExpanded && selection != nil {
                timeWheels
            }
        }
        .padding(.vertical, -6)
        .onAppear {
            updateComponentStates(from: selection)
        }
        .onChange(of: selection) { _, newDate in
            updateComponentStates(from: newDate)
            if newDate == nil { isExpanded = false }
        }
    }
    
    private func updateComponentStates(from date: Date?) {
        let calendar = Calendar.current
        let dateForComponents = date ?? Date()
        hour = calendar.component(.hour, from: dateForComponents)
        minute = calendar.component(.minute, from: dateForComponents)
        second = calendar.component(.second, from: dateForComponents)
        selectedDateOnly = calendar.startOfDay(for: dateForComponents)
    }
    
    private func mergeDateOnly(_ newDateOnlyPart: Date) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: newDateOnlyPart)
        components.hour = self.hour
        components.minute = self.minute
        components.second = self.second
        
        if let mergedDate = calendar.date(from: components) {
            if selection != mergedDate {
                selection = mergedDate
            }
        }
    }
    
    private func updateTimeFromWheels() {
        guard let baseDate = selection else {
            print("Warning: updateTimeFromWheels called when selection is nil. Ignoring.")
            return
        }
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hour
        components.minute = minute
        components.second = second
        
        if let newDate = calendar.date(from: components), newDate != baseDate {
            selection = newDate
        }
    }
    
    private func updatePickerState(from date: Date?) {
        let calendar = Calendar.current
        let current = date ?? Date()
        hour = calendar.component(.hour, from: current)
        minute = calendar.component(.minute, from: current)
        second = calendar.component(.second, from: current)
    }
    
    private func updateDate() {
        guard let existingDate = selection else {
            print("Warning: updateDate called when selection is nil. Ignoring.")
            return
        }
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: existingDate)
        components.hour = hour
        components.minute = minute
        components.second = second
        
        if let newDate = calendar.date(from: components), newDate != existingDate {
            selection = newDate
        }
    }
    
    private func setTimeToNow() {
        let now = Date()
        let calendar = Calendar.current
        let baseDate = selection ?? now
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        let nowComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        
        components.hour = nowComponents.hour
        components.minute = nowComponents.minute
        components.second = nowComponents.second
        
        if let newDate = calendar.date(from: components) {
            selection = newDate
            updateComponentStates(from: newDate)
        }
    }
    
    private func setTimeTo(hour: Int, minute: Int, second: Int) {
        let calendar = Calendar.current
        let baseDate = selection ?? Date()
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hour
        components.minute = minute
        components.second = second
        
        if let newDate = calendar.date(from: components) {
            selection = newDate
            updateComponentStates(from: newDate)
        }
    }
    
    @ViewBuilder
    private var picker: some View {
        HStack {
            DatePicker(
                "",
                selection: $selectedDateOnly,
                displayedComponents: .date
            )
            .labelsHidden()
            .onChange(of: selectedDateOnly) { _, newDate in
                mergeDateOnly(newDate)
            }
            
            Text(DateFormatter.timeOnly.string(from: selection!))
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(placeholderColor))
                )
                .fixedSize(horizontal: true, vertical: false)
                .contentShape(Rectangle())
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            setTimeToNow()
                        }
                        .exclusively(
                            before:
                                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                                .onEnded { value in
                                    if value.translation.width < -20 {
                                        setTimeTo(hour: 0, minute: 0, second: 0)
                                    } else if value.translation.width > 20 {
                                        setTimeTo(hour: 23, minute: 59, second: 59)
                                    } else {
                                        withAnimation(.snappy) {
                                            isExpanded.toggle()
                                        }
                                    }
                                }
                        )
                )
                .onTapGesture(count: 1) {
                    updatePickerState(from: selection)
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .onTapGesture(count: 3) {
                    withAnimation {
                        isExpanded = false
                        selection = nil
                    }
                }
        }
    }
    
    @ViewBuilder
    private var timeWheels: some View {
        HStack(spacing: 0) {
            Picker("Hour", selection: $hour) {
                ForEach(0..<24) { i in
                    Text("\(i, specifier: "%02d")").tag(i)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            Picker("Minute", selection: $minute) {
                ForEach(0..<60) { i in
                    Text("\(i, specifier: "%02d")").tag(i)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            Picker("Second", selection: $second) {
                ForEach(0..<60) { i in
                    Text("\(i, specifier: "%02d")").tag(i)
                }
            }
            .pickerStyle(WheelPickerStyle())
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        .onChange(of: hour) { _, _ in updateDate() }
        .onChange(of: minute) { _, _ in updateDate() }
        .onChange(of: second) { _, _ in updateDate() }
        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
    }
    
    @ViewBuilder
    private var placeholder: some View {
        HStack {
            Spacer()
            Rectangle()
                .fill(placeholderColor)
                .frame(width: 80, height: 30)
                .overlay { Text("--:--:--")}
                .cornerRadius(placeholderCornerRadius)
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = Date()
                }
        }
    }

}
