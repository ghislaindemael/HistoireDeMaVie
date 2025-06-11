//
//  AddMealSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.06.2025.
//


import SwiftUI

struct AddMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    private let dateForMeal: Date
    
    // State for the new meal's properties
    @State private var selectedMealTypeId: Int?
    @State private var timeStart = Date()
    @State private var timeEnd: Date?
    @State private var content = ""
    @State private var showOtherMeals = false
    
    private enum FocusField: Hashable {
        case content
    }
    @FocusState private var focusedField: FocusField?
    
    // Access the cached meal types
    private let mainMealTypes: [MealType]
    private let otherMealTypes: [MealType]
    
    // Callback to pass the created meal back to the parent
    var onSave: (Meal) -> Void
    
    init(for date: Date, onSave: @escaping (Meal) -> Void) {
        self.dateForMeal = date
        self.onSave = onSave
        
        let allTypes = CachingService.shared.cachedMealTypes
        self.mainMealTypes = allTypes.filter { $0.isMain }
        self.otherMealTypes = allTypes.filter { !$0.isMain }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Type") {
                    // Display main meals as a grid
                    ForEach(mainMealTypes) { mealType in
                        Button(mealType.name) {
                            selectedMealTypeId = mealType.id
                        }
                        // Use the same .tint modifier as the "Other Meals" for a consistent look.
                        .tint(selectedMealTypeId == mealType.id ? .accentColor : .primary)
                    }
                    
                    // Toggle for other meals
                    DisclosureGroup("Other Meals", isExpanded: $showOtherMeals) {
                        ForEach(otherMealTypes) { mealType in
                            Button(mealType.name) {
                                selectedMealTypeId = mealType.id
                            }
                            .tint(selectedMealTypeId == mealType.id ? .accentColor : .primary)
                        }
                    }
                }
                
                Section("Time") {
                    DatePicker("Start Time", selection: $timeStart, displayedComponents: .hourAndMinute)
                    
                    // The toggle controls if timeEnd is nil or not
                    Toggle(isOn: .init(get: { timeEnd != nil }, set: { isOn in
                        timeEnd = isOn ? Date().addingTimeInterval(15 * 60) : nil
                    })) {
                        Text("Set End Time")
                    }
                    
                    if timeEnd != nil {
                        DatePicker("End Time", selection: .init(get: { timeEnd ?? Date() }, set: { timeEnd = $0 }), displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("Content") {
                    TextField("What did you eat?", text: $content, axis: .vertical)
                        .lineLimit(5...)
                        .focused($focusedField, equals: .content)
                }
            }
            .navigationTitle("Add New Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMeal()
                    }
                    .disabled(selectedMealTypeId == nil)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }
    
    private func saveMeal() {
        guard let mealTypeId = selectedMealTypeId else { return }
        let randomPositiveId = Int.random(in: 1...100000)
        let temporaryId = -randomPositiveId

        let newMeal = Meal(
            id: temporaryId,
            date: ISO8601DateFormatter.justDate.string(from: dateForMeal),
            timeStart: timeFormatter.string(from: timeStart),
            timeEnd: timeEnd != nil ? timeFormatter.string(from: timeEnd!) : nil,
            content: content,
            mealTypeId: mealTypeId,
            syncStatus: .local
        )
        
        onSave(newMeal)
        dismiss()
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
}
