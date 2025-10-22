//
//  EditorProtocol.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.10.2025.
//

import SwiftData

protocol EditorProtocol<Model> {
    associatedtype Model: EditableModel
    
    init(from model: Model)    
    func apply(to model: Model)
}
