import Foundation

enum FoodUnitType: String, Codable, CaseIterable, Identifiable {
    case grams = "g"
    case ml = "ml"
    case units = "units"
    case slices = "slices"
    case cups = "cups"
    case tablespoons = "tablespoons"
    case teaspoons = "teaspoons"
    case portion = "portion"
    case pieces = "pieces"
    case unknown = ""
    
    var id: String { self.rawValue }
}

struct ComposedFood: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    
    // Core Identity: Either a Database Node or Raw Text
    var foodItemRid: Int?
    var rawText: String?
    
    // Properties
    var course: CourseType?
    var options: [String: String]? // [Slug: Value]
    
    // Quantity
    var quantity: Double?
    var unit: FoodUnitType?
    
    // Recursive Composition (for template explosion or complex items)
    var children: [ComposedFood]?
}

struct FoodDetails: Codable, Hashable {
    var consumedItems: [ComposedFood] = []
    
    var generalNotes: String?
    var appliedRecipeRids: [Int]?
}
