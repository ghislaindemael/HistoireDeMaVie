//
//  ExplicitNull.swift
//  HDMV
//
//  Created by Antigravity.
//

import Foundation

@propertyWrapper
struct ExplicitNull<T: Codable>: Codable {
    var wrappedValue: T?

    init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = wrappedValue {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = nil
        } else {
            wrappedValue = try container.decode(T.self)
        }
    }
}

// Ensure the key itself is not omitted by KeyedEncodingContainer
extension KeyedEncodingContainer {
    mutating func encode<T>(_ value: ExplicitNull<T>, forKey key: KeyedEncodingContainer<K>.Key) throws {
        try value.encode(to: superEncoder(forKey: key))
    }
}

extension KeyedDecodingContainer {
    func decode<T>(_ type: ExplicitNull<T>.Type, forKey key: Key) throws -> ExplicitNull<T> {
        if let value = try decodeIfPresent(ExplicitNull<T>.self, forKey: key) {
            return value
        }
        return ExplicitNull(wrappedValue: nil)
    }
}
