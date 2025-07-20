//
//  MealRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.07.2025.
//

import SwiftUI
import SwiftData

struct MealRowView: View {
    let meal: Meal
    let mealType: MealType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let mealType = meal.mealType {
                    Image(systemName: "fork.knife")
                    Text(mealType.name)
                } else {
                    Text("Mealtype not set")
                        .bold()
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                SyncStatusIndicator(status: meal.syncStatus)
            }

            
            HStack {
                Text(DateFormatter.timeOnly.string(from: meal.time_start))
                Image(systemName: "arrow.right")
                if let time_end = meal.time_end {
                    Text(DateFormatter.timeOnly.string(from: time_end))
                }
            }
            
            if let content = meal.content, !content.isEmpty {
                Text(content)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(uiColor: .tertiarySystemBackground))
                    )
                    .foregroundColor(.primary)
                    .font(.body)
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
