//
//  FullTimePickerSheetView.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.06.2025.
//

import SwiftUI

struct FullTimePicker: View {
    let label: String
    @Binding var selection: Date
    @State private var isExpanded = false
    
    @State private var hour: Int = 0
    @State private var minute: Int = 0
    @State private var second: Int = 0
    
    @State private var selectedDateOnly: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                Spacer()
                DatePicker(
                    "",
                    selection: $selectedDateOnly,
                    displayedComponents: .date
                )
                .labelsHidden()
                .onChange(of: selectedDateOnly) { _, newDate in
                    mergeDateOnly(newDate)
                }
                
                Text(DateFormatter.timeOnly.string(from: selection))
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
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
            }
            .animation(nil, value: isExpanded)
            
            if isExpanded {
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
        }
        .padding(.vertical, -6)
        .onAppear {
            updatePickerState(from: selection)
            selectedDateOnly = Calendar.current.startOfDay(for: selection)
        }
    }
    
    private func mergeDateOnly(_ newDate: Date) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: newDate)
        let oldComponents = calendar.dateComponents([.hour, .minute, .second], from: selection)
        
        components.hour = oldComponents.hour
        components.minute = oldComponents.minute
        components.second = oldComponents.second
        
        if let mergedDate = calendar.date(from: components) {
            selection = mergedDate
        }
    }
    
    private func updatePickerState(from date: Date) {
        let calendar = Calendar.current
        hour = calendar.component(.hour, from: date)
        minute = calendar.component(.minute, from: date)
        second = calendar.component(.second, from: date)
    }
    
    private func updateDate() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selection)
        
        components.hour = hour
        components.minute = minute
        components.second = second
        
        if let newDate = calendar.date(from: components), newDate != selection {
            selection = newDate
        }
    }
    
    private func setTimeToNow() {
        let now = Date()
        let calendar = Calendar.current
        
        var components = calendar.dateComponents([.year, .month, .day], from: selection)
        let nowComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        
        components.hour = nowComponents.hour
        components.minute = nowComponents.minute
        components.second = nowComponents.second
        
        if let newDate = calendar.date(from: components) {
            selection = newDate
            updatePickerState(from: newDate)
        }
    }
    
    private func setTimeTo(hour: Int, minute: Int, second: Int) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selection)
        components.hour = hour
        components.minute = minute
        components.second = second
        if let newDate = calendar.date(from: components) {
            selection = newDate
            updatePickerState(from: newDate)
        }
    }
}
