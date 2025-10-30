//
//  LogModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 16.10.2025.
//

import Foundation
import SwiftData

protocol LogModel: Identifiable, TimeBound, SyncableModel, EditableModel {
    var id: PersistentIdentifier { get }
}
