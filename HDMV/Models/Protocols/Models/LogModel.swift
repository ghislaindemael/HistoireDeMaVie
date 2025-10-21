//
//  LogModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 16.10.2025.
//

import Foundation
import SwiftData

protocol LogModel: Identifiable, TimeTrackable, SyncableModel {
    var id: PersistentIdentifier { get }
    var time_start: Date { get }
}

extension ActivityInstance: LogModel {}
extension Trip: LogModel {}
extension Interaction: LogModel {}
