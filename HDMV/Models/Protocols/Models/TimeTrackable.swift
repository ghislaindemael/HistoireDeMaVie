//
//  TimeTrackable.swift
//  HDMV
//
//  Created by Ghislain Demael on 21.10.2025.
//

import Foundation

protocol TimeTrackable: TimeBound {
    var timed: Bool { get set }
    var percentage: Int { get set }
}
