//
//  MealEditorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 15.06.2025.
//


import SwiftUI

struct MealEditorView: View {
    
    @Binding var meal: Meal
        
    @FocusState private var isContentEditorFocused: Bool
    
    let mealTypes = CachingService.shared.cachedMealTypes
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Picker("Meal Type", selection: $meal.mealTypeId) {
                ForEach(mealTypes) { type in
                    Text(type.name).tag(type.id)
                }
            }
            .pickerStyle(.menu)
            .accentColor(.primary)
            .onChange(of: meal.mealTypeId) { _, newTypeId in
                if let newMealType = mealTypes.first(where: { $0.id == newTypeId }) {
                    meal.mealType = newMealType
                }
            }

            
            HStack {
                Text("Time")
                Spacer()
                DatePicker("Start Time", selection: timeStartBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Text("to")
                DatePicker("End Time", selection: timeEndBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            
            // --- Content Editor ---
            TextEditor(text: $meal.content)
                .focused($isContentEditorFocused)
                .frame(minHeight: 80)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
        .font(.subheadline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isContentEditorFocused = false
                }
            }
        }
    }
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    private var timeStartBinding: Binding<Date> {
        Binding<Date>(
            get: { Self.timeFormatter.date(from: meal.timeStart) ?? Date() },
            set: { newDate in
                meal.timeStart = Self.timeFormatter.string(from: newDate)
            }
        )
    }
    
    private var timeEndBinding: Binding<Date> {
        Binding<Date>(
            get: {
                if let timeEndStr = meal.timeEnd {
                    return Self.timeFormatter.date(from: timeEndStr) ?? Date()
                }
                return Date()
            },
            set: { newDate in
                meal.timeEnd = Self.timeFormatter.string(from: newDate)
            }
        )
    }
}
