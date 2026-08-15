import Foundation



struct ComposedFood: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    
    // Core Identity: Either a Database Node or Raw Text
    var foodItemRid: Int?
    var sourceActivityRid: Int? // Link to a batch cooking activity!
    var rawText: String?
    
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
}
