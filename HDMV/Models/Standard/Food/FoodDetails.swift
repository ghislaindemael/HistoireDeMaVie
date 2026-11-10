import Foundation



struct ComposedFood: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    
    // Core Identity: Either a Database Node or Raw Text
    var foodItemRid: Int?
    var sourceActivityRid: Int? // Link to a batch cooking activity!
    var rawText: String?
    var details: String?
    
    // Properties
    var course: CourseType?
    var options: [String: String]? // [Slug: Value]
    
    // Quantity
    var quantity: Double?
    var unit: String?
    
    // Snapshots (Highly Recommended for History)
    var totalGrams: Double?
    var snapshottedMacros: DataFoodItemMacros?
    
    // Recursive Composition (for template explosion or complex items)
    var children: [ComposedFood]?
}

struct FoodDetails: Codable, Hashable {
    var consumedItems: [ComposedFood] = []
    
    var generalNotes: String?
    var appliedRecipeRids: [Int]?
    var courseNotes: [String: String]? // [CourseType.rawValue: Note]
    
    var hasAnyCourseNotes: Bool {
        guard let courseNotes else { return false }
        return courseNotes.values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    func note(for course: CourseType) -> String? {
        courseNotes?[course.rawValue]
    }
    
    mutating func setNote(_ note: String?, for course: CourseType) {
        if var notes = courseNotes {
            if let note = note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                notes[course.rawValue] = note
            } else {
                notes.removeValue(forKey: course.rawValue)
            }
            courseNotes = notes.isEmpty ? nil : notes
        } else if let note = note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            courseNotes = [course.rawValue: note]
        }
    }
}
