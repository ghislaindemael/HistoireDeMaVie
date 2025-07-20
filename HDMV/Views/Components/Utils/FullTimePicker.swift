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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                Spacer()
                DatePicker(
                    "",
                    selection: $selection,
                    displayedComponents: .date
                )
                .labelsHidden()
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
                                setTimeTo(hour: 12, minute: 0, second: 0)
                            }
                            .exclusively(
                                before:
                                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                                    .onEnded { value in
                                        if value.translation.width < -20 {
                                            setTimeTo(hour: 0, minute: 0, second: 0)
                                        } else if value.translation.width > 20 {
                                            // swipe right
                                            setTimeTo(hour: 23, minute: 59, second: 59)
                                        } else {
                                            // treat as toggle if not enough drag
                                            withAnimation(.snappy) {
                                                isExpanded.toggle()
                                            }
                                        }
                                    }
                            )
                    )
                    .onTapGesture(count: 1) {
                        updatePickerState(from: selection)
                        withAnimation() {
                            isExpanded.toggle()
                        }
                    }

            }
            .animation(nil, value: isExpanded)
            
            // The picker wheels are shown only when the view is expanded
            if isExpanded {
                HStack(spacing: 0) {
                    // Hour Picker
                    Picker("Hour", selection: $hour) {
                        ForEach(0..<24) { i in
                            Text("\(i, specifier: "%02d")").tag(i)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    
                    // Minute Picker
                    Picker("Minute", selection: $minute) {
                        ForEach(0..<60) { i in
                            Text("\(i, specifier: "%02d")").tag(i)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    
                    // Second Picker
                    Picker("Second", selection: $second) {
                        ForEach(0..<60) { i in
                            Text("\(i, specifier: "%02d")").tag(i)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                // By setting a height on the HStack, we can control the vertical size of the picker wheels.
                // A smaller height means fewer items are visible at once.
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                // When any of the internal picker states change, update the external Date binding
                .onChange(of: hour) { _, _ in updateDate() }
                .onChange(of: minute) { _, _ in updateDate() }
                .onChange(of: second) { _, _ in updateDate() }
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                
            }
        }
        .padding(.vertical, -6)
        // When the external Date binding changes (e.g., from another part of the app),
        // update the internal picker states if the picker is expanded.
        .onChange(of: selection) { _, newDate in
            if isExpanded {
                updatePickerState(from: newDate)
            }
        }
        .onAppear {
            updatePickerState(from: selection)
        }
    }
    
    /// Updates the internal state variables (hour, minute, second) from a given Date.
    private func updatePickerState(from date: Date) {
        let calendar = Calendar.current
        hour = calendar.component(.hour, from: date)
        minute = calendar.component(.minute, from: date)
        second = calendar.component(.second, from: date)
    }
    
    /// Constructs a new Date from the picker values and updates the external binding.
    private func updateDate() {
        let calendar = Calendar.current
        // Get the year, month, and day from the original selection
        var components = calendar.dateComponents([.year, .month, .day], from: selection)
        
        // Set the new hour, minute, and second from the picker states
        components.hour = hour
        components.minute = minute
        components.second = second
        
        // Create the new date and update the binding
        if let newDate = calendar.date(from: components) {
            if newDate != selection {
                selection = newDate
            }
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
