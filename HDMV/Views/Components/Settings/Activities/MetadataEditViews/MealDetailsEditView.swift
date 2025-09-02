//
//  MealDetailsEditView.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI

struct MealDetailsEditView: View {
    @Binding var metadata: ActivityDetails?
    
    private var mealContent: Binding<String> {
        Binding<String>(
            get: {
                metadata?.meal?.mealContent ?? ""
            },
            set: { newValue in
                if metadata == nil {
                    metadata = ActivityDetails(type: .meal)
                }
                if metadata?.meal == nil {
                    metadata?.meal = MealDetails(mealContent: newValue)
                } else {
                    metadata?.meal?.mealContent = newValue
                }
            }
        )
    }
    
    var body: some View {
        TextField("Meal Content", text: mealContent)
            .lineLimit(3...)
    }
}
