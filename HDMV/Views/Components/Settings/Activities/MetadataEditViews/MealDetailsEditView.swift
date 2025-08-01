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
                if case .meal(let details) = metadata {
                    return details.mealContent
                }
                return "" // Default value
            },
            set: { newValue in
                self.metadata = .meal(MealDetails(mealContent: newValue))
            }
        )
    }

    var body: some View {
        TextField("Meal Content", text: mealContent)
    }
}
