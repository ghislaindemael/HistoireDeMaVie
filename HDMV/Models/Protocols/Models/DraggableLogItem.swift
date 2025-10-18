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
