//
//  RelationResolver.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.10.2025.
//

import SwiftData

enum RelationResolver {
    private static weak var _context: ModelContext?

    static var context: ModelContext? { _context }

    static func setContext(_ ctx: ModelContext) {
        _context = ctx
    }
}
