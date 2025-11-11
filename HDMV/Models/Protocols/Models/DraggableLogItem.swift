//
//  DraggableLogItem.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.10.2025.
//


import Foundation
import SwiftData
import SwiftUI

enum DraggableLogItem: Codable, Transferable {
    case activity(PersistentIdentifier)
    case trip(PersistentIdentifier)
    case interaction(PersistentIdentifier)
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

extension DraggableLogItem {
    var isActivity: Bool {
        if case .activity = self { return true }
        return false
    }
    
    var isTrip: Bool {
        if case .trip = self { return true }
        return false
    }
    
    var isInteraction: Bool {
        if case .interaction = self { return true }
        return false
    }
}
