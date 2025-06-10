import SwiftUI

struct MealComponent: View {
    @Binding var meal: Meal
    
    var onUpdate: () -> Void
    var onRetry: () -> Void
    
    // This state now controls the entire component's edit mode
    @State private var isEditing = false
    
    // State variables to hold the date values while editing
    @State private var editableTimeStart: Date = Date()
    @State private var editableTimeEnd: Date = Date()
    @State private var isTimeEndEnabled: Bool = false
    
    private struct MealSnapshot {
        var timeStart: String
        var timeEnd: String?
        var content: String
    }
    
    @State private var snapshot: MealSnapshot?
    
    private enum FocusField: Hashable {
        case content
    }
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // --- Header Row (unchanged) ---
            HStack {
                Text(meal.mealType?.name ?? "Unknown Meal")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Spacer()
                HStack {
                    if !isEditing {
                        uploadButton
                    }
                    syncStatusIndicator
                    editDoneButton
                }
                .font(.title)
            }
            
            // --- EDIT MODE ---
            if isEditing {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker("Start Time", selection: $editableTimeStart, displayedComponents: .hourAndMinute)
                        
                        Toggle(isOn: $isTimeEndEnabled) {
                            Text("Set End Time")
                        }
                        
                        if isTimeEndEnabled {
                            DatePicker("End Time", selection: $editableTimeEnd, displayedComponents: .hourAndMinute)
                        }
                        
                        TextEditor(text: $meal.content)
                            .frame(minHeight: 80)
                            .background(Color(.white))
                            .cornerRadius(8)
                            .focused($focusedField, equals: .content)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        focusedField = nil
                                    }
                                }
                            }
                        
                    }
                    .font(.subheadline)
                }
                
                // --- DISPLAY MODE ---
            } else {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Time display
                        HStack {
                            Image(systemName: "clock")
                            Text(formattedTime(meal.timeStart))
                            
                            if let timeEnd = meal.timeEnd {
                                Image(systemName: "arrow.right")
                                Text(formattedTime(timeEnd))
                            } else {
                                // This button remains for quick-ending a meal
                                Button(action: endMealNow) {
                                    Text("End now")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.blue).foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .font(.subheadline).foregroundColor(.secondary)
                        
                        // Content display
                        if !meal.content.isEmpty {
                            Text(meal.content)
                                .font(.body).foregroundColor(.primary)
                        }
                    }
   
                }
            }
        }
        .padding().background(Color(.systemGray5)).cornerRadius(10)
        
    }
    
    // MARK: - Helper Functions
    
    private func startEditing() {
        // --- UPDATED ---
        // 1. Take a snapshot of the current data BEFORE entering edit mode.
        self.snapshot = MealSnapshot(
            timeStart: meal.timeStart,
            timeEnd: meal.timeEnd,
            content: meal.content
        )
        self.meal.syncStatus = .local
        
        // 2. Populate the editable state variables as before.
        self.editableTimeStart = date(from: meal.timeStart)
        if let timeEndStr = meal.timeEnd {
            self.isTimeEndEnabled = true
            self.editableTimeEnd = date(from: timeEndStr)
        } else {
            self.isTimeEndEnabled = false
            self.editableTimeEnd = editableTimeStart.addingTimeInterval(15 * 60)
        }
        self.isEditing = true
    }
    
    
    private func saveChanges() {
        // --- UPDATED ---
        // 1. Get the new values from the UI state.
        let newTimeStart = timeFormatter.string(from: editableTimeStart)
        let newTimeEnd = isTimeEndEnabled ? timeFormatter.string(from: editableTimeEnd) : nil
        // Note: meal.content is already updated via its @Binding.
        
        // 2. Safely unwrap the snapshot we took earlier.
        guard let original = snapshot else {
            
            self.isEditing = false
            self.meal.syncStatus = .synced
            return
        }
        
        // 3. Compare the original snapshot with the new values.
        let hasChanges = (
            original.timeStart != newTimeStart ||
            original.timeEnd != newTimeEnd ||
            original.content != meal.content
        )
        
        // 4. Update the meal model regardless of changes (to reflect UI).
        meal.timeStart = newTimeStart
        meal.timeEnd = newTimeEnd
        
        // 5. Exit edit mode and clear the snapshot.
        self.isEditing = false
        self.snapshot = nil
        
        // 6. ONLY call onUpdate if there were actual changes.
        if hasChanges {
            onUpdate()
        } else {
            self.meal.syncStatus = .synced
        }
    }
    
    private func endMealNow() {
        meal.timeEnd = timeFormatter.string(from: Date())
        onUpdate()
    }
    
    private func date(from timeString: String) -> Date {
        let parsingFormatter = DateFormatter()
        parsingFormatter.dateFormat = "HH:mm:ss"
        return parsingFormatter.date(from: timeString) ?? Date()
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    @ViewBuilder
    private var editDoneButton: some View {
        Button(action: {
            if isEditing {
                saveChanges()
            } else {
                startEditing()
            }
        }) {
            Image(systemName: isEditing ? "icloud.and.arrow.up.fill" : "pencil.circle.fill")
                .foregroundStyle(isEditing ? Color.green : Color.accentColor)
        }
        .buttonStyle(.borderless)
    }
    
    @ViewBuilder
    private var syncStatusIndicator: some View {
        switch meal.syncStatus {
            case .synced:
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundColor(.green)
            case .syncing:
                ProgressView()
            case .local:
                Image(systemName: "icloud.slash")
            case .failed:
                Image(systemName: "xmark.icloud.fill")
                    .foregroundColor(.red)
                
        }
            
    }
    
    @ViewBuilder
    private var uploadButton: some View {
        switch meal.syncStatus {
            case .synced, .syncing:
                EmptyView()
            case .local, .failed:
                Button(action: {
                    onRetry()
                }) {
                    Label("Upload", systemImage: "icloud.and.arrow.up.fill")
                        .labelStyle(.iconOnly)
                }
                .foregroundStyle(.green)
        }
    }
    
    private func formattedTime(_ timeString: String) -> String { String(timeString.prefix(5)) }
    
    
}
