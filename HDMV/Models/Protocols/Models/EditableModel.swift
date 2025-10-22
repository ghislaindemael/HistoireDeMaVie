//
//  EditableModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.10.2025.
//

import SwiftData

protocol EditableModel: PersistentModel, Identifiable, SyncableModel {
    associatedtype Editor: EditorProtocol where Editor.Model == Self
}
