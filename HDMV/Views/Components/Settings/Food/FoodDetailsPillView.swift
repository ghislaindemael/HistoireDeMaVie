import SwiftUI

struct FoodDetailsPillView: View {
    let foodDetails: FoodDetails?
    let isMissingRequiredDetails: Bool
    let isMissingOptionalDetails: Bool
    let themeColor: Color
    
    init(
        foodDetails: FoodDetails?,
        isMissingRequiredDetails: Bool = false,
        isMissingOptionalDetails: Bool = false,
        themeColor: Color = .yellow
    ) {
        self.foodDetails = foodDetails
        self.isMissingRequiredDetails = isMissingRequiredDetails
        self.isMissingOptionalDetails = isMissingOptionalDetails
        self.themeColor = themeColor
    }
    
    private var alertColor: Color {
        if isMissingRequiredDetails { return .red }
        if isMissingOptionalDetails { return .orange }
        return themeColor
    }
    
    var body: some View {
        let items = foodDetails?.consumedItems ?? []
        let grouped = Dictionary(grouping: items) { $0.course ?? .divers }
        let coursesWithNotes = CourseType.allCases.filter { foodDetails?.note(for: $0) != nil }
        let allActiveCourses = CourseType.allCases.filter { grouped.keys.contains($0) || coursesWithNotes.contains($0) }
        let hasContent = !items.isEmpty || !allActiveCourses.isEmpty
        let hasGeneralNotes = foodDetails?.generalNotes?.isEmpty == false
        
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 4) {
                Image(systemName: "fork.knife")
                    .foregroundColor(alertColor)
                    .frame(width: 20)
                    .padding(.top, 2)
                
                if hasContent || hasGeneralNotes {
                    Rectangle()
                        .fill(alertColor)
                        .frame(width: 2)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if let notes = foodDetails?.generalNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.headline)
                        .foregroundColor(themeColor)
                } else if !hasContent && !hasGeneralNotes {
                    Text("Food not logged.")
                        .foregroundColor(alertColor)
                        .fontWeight((isMissingRequiredDetails || isMissingOptionalDetails) ? .bold : .regular)
                        .font(.headline)
                }
                
                if !allActiveCourses.isEmpty {
                    ForEach(allActiveCourses, id: \.self) { course in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.rawValue)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(themeColor)
                                .textCase(.uppercase)
                            
                            if let courseNote = foodDetails?.note(for: course), !courseNote.isEmpty {
                                Text(courseNote)
                                    .font(.callout)
                                    .foregroundColor(themeColor.opacity(0.85))
                            }
                            
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
                .fill((isMissingRequiredDetails || isMissingOptionalDetails) ? alertColor.opacity(0.1) : themeColor.opacity(0.15))
        )
    }
    
    private func formatFoodItem(_ item: ComposedFood) -> String {
        var text = item.rawText ?? "Unknown Food"
        if let details = item.details, !details.isEmpty {
            text += " (\(details))"
        }
        return text
    }
}
