//
//  MealDetailsEditView.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.08.2025.
//

import SwiftUI

struct MealDetailsEditView: View {
    @Binding var metadata: ActivityDetails?
    
    private var mealDetailsBinding: Binding<MealDetails> {
        Binding<MealDetails>(
            get: {
                return metadata?.meal ?? MealDetails()
            },
            set: { newMealDetails in
                
                if metadata == nil {
                    metadata = ActivityDetails()
                }
                
                metadata?.meal = newMealDetails
            }
        )
    }
    
    var body: some View {
        ForEach(CourseType.allCases) { course in
            TextField(course.rawValue, text: mealDetailsBinding[course], axis: .vertical)
                .lineLimit(1...3)
        }
    }
}
