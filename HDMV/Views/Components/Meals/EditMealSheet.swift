import SwiftUI

struct EditMealSheet: View {
    let mealTypes: [MealType]
    var onSave: (Meal) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State var meal: Meal
    @State private var showEndTime: Bool
    @FocusState private var contentFocused: Bool
    
    init(
        mealTypes: [MealType],
        meal: Meal,
        onSave: @escaping (Meal) -> Void
    ) {
        self.mealTypes = mealTypes
        self.onSave = onSave
        
        _meal = State(initialValue: meal)
        _showEndTime = State(initialValue: meal.time_end != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    Picker("Meal Type", selection: Binding(
                        get: { meal.mealTypeId },
                        set: { newId in
                            meal.mealTypeId = newId
                            meal.mealType = mealTypes.first(where: { $0.id == newId })
                        })) {
                            Text("Please select a meal type").tag(0)
                            ForEach(mealTypes, id: \.id) { mealType in
                                Text(mealType.name).tag(mealType.id)
                            }
                        }
                    
                    FullTimePicker(label: "Start Time", selection: $meal.time_start)
                    
                    Toggle("End Time?", isOn: $showEndTime)
                    if showEndTime {
                        FullTimePicker(label: "End Time", selection: Binding(
                            get: { meal.time_end ?? Date() },
                            set: { meal.time_end = $0 }
                        ))
                    }
                }
                
                Section("Content") {
                    TextEditor(text: Binding(
                        get: { meal.content ?? "" },
                        set: { meal.content = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                    .focused($contentFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                contentFocused = false
                            }
                        }
                    }
                }
            }
            .onChange(of: showEndTime) {
                if !showEndTime {
                    meal.time_end = nil
                }
            }
            .navigationTitle(meal.id < 0 ? "New Meal" : "Edit Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(meal)
                        dismiss()
                    }
                    .disabled(meal.mealTypeId == 0)
                }
            }
        }
    }
}
