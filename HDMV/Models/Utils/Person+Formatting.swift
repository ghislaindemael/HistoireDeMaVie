//
//  Person+Formatting.swift
//  HDMV
//
//  Created by Ghislain Demael on 27.03.2026.
//


import Foundation

extension Person {
    var formattedName: String {
        var parts: [String] = [name]
        if !familyName.isEmpty && familyName.isNotUnset() {
            parts.append(familyName)
        }
        return parts.joined(separator: " ")
    }
}

extension Collection where Element == Person {
    
    /// Formats an array of Person objects into a readable string (e.g., "Alice, Bob & 2 others")
    /// - Parameter emptyFallback: The text to display if the array is empty.
    func formattedNames(emptyFallback: String = "None") -> String {
        let names = self.map { $0.name }
        
        switch names.count {
        case 0:
            return emptyFallback
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) & \(names[1])"
        default:
            return "\(names[0]), \(names[1]) & \(names.count - 2) others"
        }
    }
}