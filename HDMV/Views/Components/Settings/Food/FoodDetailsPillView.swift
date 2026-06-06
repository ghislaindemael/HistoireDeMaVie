import SwiftUI

struct FoodDetailsPillView: View {
    let foodDetails: FoodDetails?
    let isMissingRequiredDetails: Bool
    let themeColor: Color
    
    init(
        foodDetails: FoodDetails?,
        isMissingRequiredDetails: Bool = false,
        themeColor: Color = .yellow
    ) {
        self.foodDetails = foodDetails
        self.isMissingRequiredDetails = isMissingRequiredDetails
        self.themeColor = themeColor
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 4) {
                Image(systemName: "fork.knife")
                    .foregroundColor(isMissingRequiredDetails ? .red : themeColor)
                    .frame(width: 20)
                    .padding(.top, 2)
                
                if (foodDetails?.consumedItems.isEmpty == false) {
                    Rectangle()
                        .fill(isMissingRequiredDetails ? Color.red : themeColor)
                        .frame(width: 2)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if let notes = foodDetails?.generalNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.headline)
                        .foregroundColor(themeColor)
                } else if foodDetails?.consumedItems.isEmpty != false {
                    Text("Food not logged.")
                        .foregroundColor(isMissingRequiredDetails ? .red : themeColor)
                        .fontWeight(isMissingRequiredDetails ? .bold : .regular)
                        .font(.headline)
                }
                
                if let items = foodDetails?.consumedItems, !items.isEmpty {
                    let grouped = Dictionary(grouping: items) { $0.course ?? .divers }
                    let sortedCourses = CourseType.allCases.filter { grouped.keys.contains($0) }
                    
                    ForEach(sortedCourses, id: \.self) { course in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.rawValue)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(themeColor)
                                .textCase(.uppercase)
                            
                            ForEach(grouped[course] ?? [], id: \.id) { item in
                                Text("• \(formatFoodItem(item))")
                                    .font(.body)
                                    .foregroundColor(themeColor)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isMissingRequiredDetails ? Color.red.opacity(0.1) : themeColor.opacity(0.15))
        )
    }
    
    private func formatFoodItem(_ item: ComposedFood) -> String {
        return item.rawText ?? "Unknown Food"
    }
}
