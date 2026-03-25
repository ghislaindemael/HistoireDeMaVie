//
//  FullTimePicker.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.06.2025.
//


import SwiftUI
import UniformTypeIdentifiers

struct FullTimePicker: View {
    let label: String
    @Binding var selection: Date?
    let minimumDate: Date?
    
    private let placeholderColor = Color(.systemGray4)
    private let placeholderCornerRadius: CGFloat = 8
    
    @State private var isExpanded = false
    
    private let hourBase = 24
    private let minuteBase = 60
    
    @State private var hourVirtualIndex: Int = 24
    @State private var minuteVirtualIndex: Int = 60
    @State private var secondVirtualIndex: Int = 60
    @State private var selectedDateOnly: Date = Date()
    
    private var hour: Int { hourVirtualIndex % 24 }
    private var minute: Int { minuteVirtualIndex % 60 }
    private var second: Int { secondVirtualIndex % 60 }
    
    // MARK: - Initializers updated to accept minimumDate
    init(label: String, selection: Binding<Date?>, minimumDate: Date? = nil) {
        self.label = label
        self._selection = selection
        self.minimumDate = minimumDate
    }
    
    init(label: String, selection: Binding<Date>, minimumDate: Date? = nil) {
        self.label = label
        self._selection = Binding<Date?>(
            get: { selection.wrappedValue },
            set: { selection.wrappedValue = $0 ?? selection.wrappedValue }
        )
        self.minimumDate = minimumDate
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
            .animation(.snappy, value: isExpanded)
            
            if isExpanded && selection != nil {
                timeWheels
            }
        }
        .padding(.vertical, -6)
        .onAppear {
            updateComponentStates(from: selection)
        }
        .onChange(of: selection) { _, newDate in
            if !isExpanded {
                updateComponentStates(from: newDate)
            }
            if newDate == nil { isExpanded = false }
        }
    }
    
    // MARK: - State Management
    
    // Determines whether to use Date() or the minimumDate if Date() is in the past
    private var safeDefaultDate: Date {
        let now = Date()
        if let minDate = minimumDate, minDate > now {
            return minDate
        }
        return now
    }
    
    private func updateComponentStates(from date: Date?) {
        let calendar = Calendar.current
        let dateForComponents = date ?? Date()
        
        let actualHour = calendar.component(.hour, from: dateForComponents)
        let actualMinute = calendar.component(.minute, from: dateForComponents)
        let actualSecond = calendar.component(.second, from: dateForComponents)
        
        hourVirtualIndex = hourBase + actualHour
        minuteVirtualIndex = minuteBase + actualMinute
        secondVirtualIndex = minuteBase + actualSecond
        
        selectedDateOnly = calendar.startOfDay(for: dateForComponents)
    }
    
    private func updateDateFromWheels() {
        guard isExpanded, let existingDate = selection else { return }
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: existingDate)
        components.hour = hour
        components.minute = minute
        components.second = second
        
        if let newDate = calendar.date(from: components), newDate != existingDate {
            selection = newDate
        }
    }
    
    private func recenterWheelsIfNeeded() {
        DispatchQueue.main.async {
            if hourVirtualIndex < 24 || hourVirtualIndex >= 48 {
                hourVirtualIndex = 24 + (hourVirtualIndex % 24)
            }
            if minuteVirtualIndex < 60 || minuteVirtualIndex >= 120 {
                minuteVirtualIndex = 60 + (minuteVirtualIndex % 60)
            }
            if secondVirtualIndex < 60 || secondVirtualIndex >= 120 {
                secondVirtualIndex = 60 + (secondVirtualIndex % 60)
            }
        }
    }
    
    private func mergeDateOnly(_ newDateOnlyPart: Date) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: newDateOnlyPart)
        components.hour = hour
        components.minute = minute
        components.second = second
        
        if let mergedDate = calendar.date(from: components) {
            selection = mergedDate
        }
    }
    
    private func setTimeToNow() {
        // Uses the safe default so double-tapping "Now" doesn't put the time before the start time
        let targetDate = safeDefaultDate
        
        withAnimation {
            selection = targetDate
            updateComponentStates(from: targetDate)
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var nativeDatePicker: some View {
        // Restricts the calendar popup to hide days before the minimum date
        if let minDate = minimumDate {
            DatePicker("", selection: $selectedDateOnly, in: minDate..., displayedComponents: .date)
        } else {
            DatePicker("", selection: $selectedDateOnly, displayedComponents: .date)
        }
    }
    
    @ViewBuilder
    private var picker: some View {
        HStack {
            nativeDatePicker
                .labelsHidden()
                .onChange(of: selectedDateOnly) { _, newDate in
                    mergeDateOnly(newDate)
                }
            
            Text(DateFormatter.timeWithSeconds.string(from: selection!))
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(placeholderColor)))
                .fixedSize(horizontal: true, vertical: false)
                .contentShape(Rectangle())
                .contextMenu {
                    Button(action: copyTimeToClipboard) {
                        Label("Copy Date & Time", systemImage: "doc.on.doc")
                    }
                    if hasTimeInClipboard() {
                        Button(action: pasteTimeFromClipboard) {
                            Label("Paste Date & Time", systemImage: "clipboard")
                        }
                    }
                }
                .gesture(
                    TapGesture(count: 3)
                        .onEnded {
                            withAnimation {
                                isExpanded = false
                                selection = nil
                            }
                        }
                )
                .highPriorityGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            setTimeToNow()
                        }
                )
                .onTapGesture(count: 1) {
                    withAnimation { isExpanded.toggle() }
                }
        }
    }
    
    @ViewBuilder
    private var timeWheels: some View {
        HStack(spacing: 0) {
            Picker("Hour", selection: $hourVirtualIndex) {
                ForEach(0..<72, id: \.self) { i in
                    Text("\(i % 24, specifier: "%02d")").tag(i)
                }
            }
            .pickerStyle(.wheel)
            
            Picker("Minute", selection: $minuteVirtualIndex) {
                ForEach(0..<180, id: \.self) { i in
                    Text("\(i % 60, specifier: "%02d")").tag(i)
                }
            }
            .pickerStyle(.wheel)
            
            Picker("Second", selection: $secondVirtualIndex) {
                ForEach(0..<180, id: \.self) { i in
                    Text("\(i % 60, specifier: "%02d")").tag(i)
                }
            }
            .pickerStyle(.wheel)
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        .onChange(of: hourVirtualIndex) { _, _ in
            updateDateFromWheels()
            recenterWheelsIfNeeded()
        }
        .onChange(of: minuteVirtualIndex) { _, _ in
            updateDateFromWheels()
            recenterWheelsIfNeeded()
        }
        .onChange(of: secondVirtualIndex) { _, _ in
            updateDateFromWheels()
            recenterWheelsIfNeeded()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
    }
    
    @ViewBuilder
    private var placeholder: some View {
        HStack {
            Spacer()
            Rectangle()
                .fill(placeholderColor)
                .frame(width: 80, height: 30)
                .overlay { Text("--:--:--") }
                .cornerRadius(placeholderCornerRadius)
                .contentShape(Rectangle())
                .contextMenu {
                    if hasTimeInClipboard() {
                        Button(action: pasteTimeFromClipboard) {
                            Label("Paste Date & Time", systemImage: "clipboard")
                        }
                    }
                }
                .onTapGesture {
                    selection = safeDefaultDate
                    updateComponentStates(from: safeDefaultDate)
                    withAnimation { isExpanded = true }
                }
        }
    }
    
    // MARK: - Copy / Paste Logic
    
    private var clipboardFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }
    
    private func copyTimeToClipboard() {
        guard let date = selection else { return }
        UIPasteboard.general.string = clipboardFormatter.string(from: date)
    }
    
    private func hasTimeInClipboard() -> Bool {
        return UIPasteboard.general.hasStrings
    }
    
    private func pasteTimeFromClipboard() {
        guard let string = UIPasteboard.general.string,
              let newDate = clipboardFormatter.date(from: string) else {
            return
        }
        
        withAnimation {
            selection = newDate
            updateComponentStates(from: newDate)
        }
    }
}
