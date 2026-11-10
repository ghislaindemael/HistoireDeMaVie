import Foundation
import UIKit

struct FoodClipboardManager {
    static let coursePrefix = "HDMV_COURSE:"
    static let foodPrefix = "HDMV_FOOD:"
    static let servingSizesPrefix = "HDMV_SERVING_SIZES:"
    
    // MARK: - Copying
    
    struct CourseClipboardData: Codable {
        var items: [ComposedFood]
        var note: String?
    }
    
    static func copy(course: [ComposedFood], note: String? = nil) {
        let payload = CourseClipboardData(items: course, note: note)
        if let data = try? JSONEncoder().encode(payload),
           let json = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = coursePrefix + json
        }
    }
    
    static func copy(food: ComposedFood) {
        if let data = try? JSONEncoder().encode(food),
           let json = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = foodPrefix + json
        }
    }
    
    static func copy(servingSizes: [FoodServingSize]) {
        if let data = try? JSONEncoder().encode(servingSizes),
           let json = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = servingSizesPrefix + json
        }
    }
    
    // MARK: - Pasting (with ID regeneration)
    
    static func getCourseWithNewIDs() -> (items: [ComposedFood], note: String?)? {
        guard let string = UIPasteboard.general.string, string.hasPrefix(coursePrefix) else { return nil }
        let json = String(string.dropFirst(coursePrefix.count))
        guard let data = json.data(using: .utf8) else { return nil }
        
        if let payload = try? JSONDecoder().decode(CourseClipboardData.self, from: data) {
            return (items: payload.items.map { regenerateIDs(for: $0) }, note: payload.note)
        }
        
        if let items = try? JSONDecoder().decode([ComposedFood].self, from: data) {
            return (items: items.map { regenerateIDs(for: $0) }, note: nil)
        }
        
        return nil
    }
    
    static func getFoodWithNewIDs() -> ComposedFood? {
        guard let string = UIPasteboard.general.string, string.hasPrefix(foodPrefix) else { return nil }
        let json = String(string.dropFirst(foodPrefix.count))
        guard let data = json.data(using: .utf8) else { return nil }
        guard let item = try? JSONDecoder().decode(ComposedFood.self, from: data) else { return nil }
        
        return regenerateIDs(for: item)
    }
    
    static func getServingSizes() -> [FoodServingSize]? {
        guard let string = UIPasteboard.general.string, string.hasPrefix(servingSizesPrefix) else { return nil }
        let json = String(string.dropFirst(servingSizesPrefix.count))
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([FoodServingSize].self, from: data)
    }
    
    // MARK: - Helpers
    
    static var hasCourse: Bool {
        return UIPasteboard.general.string?.hasPrefix(coursePrefix) == true
    }
    
    static var hasFood: Bool {
        return UIPasteboard.general.string?.hasPrefix(foodPrefix) == true
    }
    
    static var hasServingSizes: Bool {
        return UIPasteboard.general.string?.hasPrefix(servingSizesPrefix) == true
    }
    
    private static func regenerateIDs(for food: ComposedFood) -> ComposedFood {
        var newFood = food
        newFood.id = UUID()
        if let children = newFood.children {
            newFood.children = children.map { regenerateIDs(for: $0) }
        }
        return newFood
    }
}
