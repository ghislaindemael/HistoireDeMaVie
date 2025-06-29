//
//  ISO8601+Extensions.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import Foundation

extension ISO8601DateFormatter {
    static let justDate: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}
