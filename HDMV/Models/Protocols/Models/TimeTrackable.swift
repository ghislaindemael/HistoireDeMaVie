//
//  TimeTrackable.swift
//  HDMV
//
//  Created by Ghislain Demael on 21.10.2025.
//

import Foundation

protocol TimeTrackable {
    var timeStart: Date { get set }
    var timeEnd: Date? { get set }
    var timed: Bool { get set }
    var percentage: Int { get set }
}
