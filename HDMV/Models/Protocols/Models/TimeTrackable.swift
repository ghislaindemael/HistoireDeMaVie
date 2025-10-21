//
//  TimeTrackable.swift
//  HDMV
//
//  Created by Ghislain Demael on 21.10.2025.
//

import Foundation

protocol TimeTrackable {
    var time_start: Date { get }
    var time_end: Date? { get }
}
