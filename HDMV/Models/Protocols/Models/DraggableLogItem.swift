import Foundation
import SwiftData

// A universal, Codable payload for any draggable item in your hierarchy.
enum DraggableLogItem: Codable, Transferable {
    case activity(PersistentIdentifier)
    case tripLeg(PersistentIdentifier)
    case interaction(PersistentIdentifier)
    
    // This tells the system how to handle the drag-and-drop data.
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}