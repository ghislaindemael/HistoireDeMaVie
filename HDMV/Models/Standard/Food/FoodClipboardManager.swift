import Foundation
import UIKit

struct FoodClipboardManager {
    static let coursePrefix = "HDMV_COURSE:"
    static let foodPrefix = "HDMV_FOOD:"
    
    // MARK: - Copying
    
    static func copy(course: [ComposedFood]) {
        if let data = try? JSONEncoder().encode(course),
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
    
    // MARK: - Pasting (with ID regeneration)
    
    static func getCourseWithNewIDs() -> [ComposedFood]? {
        guard let string = UIPasteboard.general.string, string.hasPrefix(coursePrefix) else { return nil }
        let json = String(string.dropFirst(coursePrefix.count))
        guard let data = json.data(using: .utf8) else { return nil }
        guard let items = try? JSONDecoder().decode([ComposedFood].self, from: data) else { return nil }
        
        return items.map { regenerateIDs(for: $0) }
    }
    
    static func getFoodWithNewIDs() -> ComposedFood? {
        guard let string = UIPasteboard.general.string, string.hasPrefix(foodPrefix) else { return nil }
        let json = String(string.dropFirst(foodPrefix.count))
        guard let data = json.data(using: .utf8) else { return nil }
        guard let item = try? JSONDecoder().decode(ComposedFood.self, from: data) else { return nil }
        
        return regenerateIDs(for: item)
    }
    
    // MARK: - Helpers
    
    static var hasCourse: Bool {
        return UIPasteboard.general.string?.hasPrefix(coursePrefix) == true
    }
    
    static var hasFood: Bool {
        return UIPasteboard.general.string?.hasPrefix(foodPrefix) == true
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
