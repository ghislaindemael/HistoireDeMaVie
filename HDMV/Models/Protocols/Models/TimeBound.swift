//
//  TimeBound.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.10.2025.
//

import Foundation

protocol TimeBound {
    var timeStart: Date { get set }
    var timeEnd: Date? { get set }
}
