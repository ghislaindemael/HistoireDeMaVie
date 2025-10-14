//
//  CachableModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 13.10.2025.
//

import SwiftData

protocol CachableModel {
    var cache: Bool { get set }
    var archived: Bool { get set }
}


