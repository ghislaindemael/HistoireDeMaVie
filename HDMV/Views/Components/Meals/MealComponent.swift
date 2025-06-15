import SwiftUI

struct MealComponent: View {
    @Binding var meal: Meal
    
    var onUpdate: () -> Void
    var onRetry: () -> Void
    var onEndNow: () -> Void
    
    // This state now controls the entire component's edit mode
    @State private var isEditing = false
    
    
    @State private var snapshot: Meal?
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text(meal.mealType?.name ?? "Unknown Meal")
                    .font(.title3.bold())
                    .foregroundColor(.accentColor)
                Spacer()
                HStack {
                    if !isEditing {
                        SyncStatusButton(status: meal.syncStatus)
                    }
                    toggleEditButton
                }
                .font(.title)
            }
            
            if isEditing {
                MealEditorView(
                    meal: $meal
                )
            } else {
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock")
                        Text("\(formattedTime(meal.timeStart))")
                        if let timeEnd = meal.timeEnd {
                            Image(systemName: "arrow.right")
                            Text(formattedTime(timeEnd))
                        } else {
                            Button(action: onEndNow)
                            {
                                Text("End now")
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    if !meal.content.isEmpty {
                        Text(meal.content)
                            .foregroundColor(.primary)
                    }
                    
                    
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        
    }
    
    // MARK: - Helper Functions
    
    private func startEditing() {
        // --- UPDATED ---
        // 1. Take a snapshot of the current data BEFORE entering edit mode.
        self.snapshot = Meal(
            id: -1,
            date: meal.date,
            timeStart: meal.timeStart,
            timeEnd: meal.timeEnd,
            content: meal.content,
            mealTypeId: meal.mealTypeId
        )
        self.meal.syncStatus = .local
        
        // 2. Set editing mode to true to build the view
        self.isEditing = true
        
    }
    
    
    private func saveChanges() {
        
        // 1. Safely unwrap the snapshot we took earlier.
        guard let original = snapshot else {
            
            self.isEditing = false
            self.meal.syncStatus = .synced
            return
        }
        
        // 2. Compare the original snapshot with the new values.
        let hasChanges = (
            original.mealTypeId != meal.mealTypeId ||
            original.timeStart != meal.timeStart ||
            original.timeEnd != meal.timeEnd ||
            original.content != meal.content
        )
        
        
        // 5. Exit edit mode and clear the snapshot.
        self.isEditing = false
        self.snapshot = nil
        
        if hasChanges {
            onUpdate()
        } else {
            self.meal.syncStatus = .synced
        }
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
    private var toggleEditButton: some View {
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
    
    private func formattedTime(_ timeString: String) -> String { String(timeString.prefix(5)) }
    
    
}
