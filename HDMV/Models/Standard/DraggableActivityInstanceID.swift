//
//  DraggableActivityInstanceID.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.10.2025.
//


import SwiftUI
import UniformTypeIdentifiers

struct DraggableActivityInstanceID: Codable, Transferable {
    let id: Int
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .draggableActivityInstanceID)
    }
}

extension UTType {
    static let draggableActivityInstanceID = UTType(exportedAs: "name.demael.hdmv.draggableactivityinstanceid")
}
