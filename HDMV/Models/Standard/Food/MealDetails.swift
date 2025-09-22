//
//  MealDetails.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.09.2025.
//


import Foundation
import SwiftUI

struct MealDetails: Codable, Hashable {
    var brut: String?
    var aperitif: String?
    var entree: String?
    var plat: String?
    var fromage: String?
    var fruits: String?
    var dessert: String?
    var cafe: String?
    var divers: String?
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case aperitif, brut, entree, plat, fromage,fruits, dessert, cafe, divers
        case mealContent
    }
    
    init() {}
        
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try? decoder.singleValueContainer()
        
        let hasModernKey = CodingKeys.allCases.contains { key in
            guard key != CodingKeys.mealContent else { return false }
            return container.contains(key)
        }
        
        if hasModernKey {
            self.brut = try container.decodeIfPresent(String.self, forKey: .brut)
            self.aperitif = try container.decodeIfPresent(String.self, forKey: .aperitif)
            self.entree = try container.decodeIfPresent(String.self, forKey: .entree)
            self.plat = try container.decodeIfPresent(String.self, forKey: .plat)
            self.fromage = try container.decodeIfPresent(String.self, forKey: .fromage)
            self.fruits = try container.decodeIfPresent(String.self, forKey: .fruits)
            self.dessert = try container.decodeIfPresent(String.self, forKey: .dessert)
            self.cafe = try container.decodeIfPresent(String.self, forKey: .cafe)
            self.divers = try container.decodeIfPresent(String.self, forKey: .divers)
        }
        else if let oldContent = try? container.decodeIfPresent(String.self, forKey: .mealContent) {
            self.brut = oldContent
            self.aperitif = nil
            self.entree = nil
            self.plat = nil
            self.fromage = nil
            self.dessert = nil
            self.cafe = nil
            self.divers = nil
        }
        else if let brutContent = try? singleValueContainer?.decode(String.self) {
            self.brut = brutContent
            self.aperitif = nil
            self.entree = nil
            self.plat = nil
            self.fromage = nil
            self.dessert = nil
            self.cafe = nil
            self.divers = nil
        }
        else {
            self.brut = nil
            self.aperitif = nil
            self.entree = nil
            self.plat = nil
            self.fromage = nil
            self.dessert = nil
            self.cafe = nil
            self.divers = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.brut, forKey: .brut)
        try container.encodeIfPresent(self.aperitif, forKey: .aperitif)
        try container.encodeIfPresent(self.entree, forKey: .entree)
        try container.encodeIfPresent(self.plat, forKey: .plat)
        try container.encodeIfPresent(self.fromage, forKey: .fromage)
        try container.encodeIfPresent(self.fruits, forKey: .fruits)
        try container.encodeIfPresent(self.dessert, forKey: .dessert)
        try container.encodeIfPresent(self.cafe, forKey: .cafe)
        try container.encodeIfPresent(self.divers, forKey: .divers)
    }
    
}

extension MealDetails {
    
    var displayText: String {
        if let brutContent = self.brut, !brutContent.isEmpty {
            return brutContent
        }
        
        let components: [(String, String?)] = [
            ("Apéritif", self.aperitif),
            ("Entrée", self.entree),
            ("Plat", self.plat),
            ("Fromage", self.fromage),
            ("Fruits", self.fruits),
            ("Dessert", self.dessert),
            ("Café", self.cafe),
            ("Divers", self.divers)
        ]
        
        let validComponents = components.compactMap { (label, value) -> String? in
            guard let value = value, !value.isEmpty else { return nil }
            return "\(label): \(value)"
        }
        
        if validComponents.isEmpty {
            return "Please fill in the details."
        }
        
        return validComponents.joined(separator: "\n")
    }
}

extension Binding where Value == MealDetails {
    
    /// Provides a direct binding to a specific course's string property.
    /// Example: $mealDetails[.plat]
    subscript(course: CourseType) -> Binding<String> {
        return Binding<String>(
            get: {
                switch course {
                    case .aperitif: return self.wrappedValue.aperitif ?? ""
                    case .brut:     return self.wrappedValue.brut ?? ""
                    case .entree:   return self.wrappedValue.entree ?? ""
                    case .plat:     return self.wrappedValue.plat ?? ""
                    case .fromage:  return self.wrappedValue.fromage ?? ""
                    case .dessert:  return self.wrappedValue.dessert ?? ""
                    case .fruits:   return self.wrappedValue.fruits ?? ""
                    case .cafe:     return self.wrappedValue.cafe ?? ""
                    case .divers:   return self.wrappedValue.divers ?? ""
                }
            },
            set: { newValue in
                let valueToSave = newValue.isEmpty ? nil : newValue
                switch course {
                    case .aperitif: self.wrappedValue.aperitif = valueToSave
                    case .brut:     self.wrappedValue.brut = valueToSave
                    case .entree:   self.wrappedValue.entree = valueToSave
                    case .plat:     self.wrappedValue.plat = valueToSave
                    case .fromage:  self.wrappedValue.fromage = valueToSave
                    case .fruits:   self.wrappedValue.fruits = valueToSave
                    case .dessert:  self.wrappedValue.dessert = valueToSave
                    case .cafe:     self.wrappedValue.cafe = valueToSave
                    case .divers:   self.wrappedValue.divers = valueToSave
                }
            }
        )
    }
}
