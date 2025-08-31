//
//  TimableModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 31.08.2025.
//


import Foundation
import SwiftData

protocol TimableModel: PersistentModel {
    var time_start: Date { get set }
    var time_end: Date? { get set }
}
