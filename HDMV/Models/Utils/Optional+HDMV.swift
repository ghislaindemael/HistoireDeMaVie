//
//  Optional+HDMV.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//

import SwiftUI

extension String {
    func isNotUnset() -> Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.lowercased() != "unset"
    }
    
    func isUnset() -> Bool {
        return !isNotUnset()
    }
}

extension Optional where Wrapped == String {
    var bound: String {
        get { self ?? "" }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}

extension Optional where Wrapped == Bool {
    var isTrue: Bool {
        self ?? false
    }
}

extension Binding where Value == String? {
    func orEmpty() -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0 }
        )
    }
}

extension Binding where Value == Date? {
    func orNow() -> Binding<Date> {
        Binding<Date>(
            get: {
                self.wrappedValue ?? Date()
            },
            set: {
                self.wrappedValue = $0
            }
        )
    }
}

extension Binding where Value == Int {
    func toDouble() -> Binding<Double> {
        Binding<Double>(
            get: { Double(self.wrappedValue) },
            set: { self.wrappedValue = Int($0) }
        )
    }
}

extension Binding where Value == Int? {

    func or100Double() -> Binding<Double> {
        Binding<Double>(
            get: {
                Double(self.wrappedValue ?? 100)
            },
            set: {
                self.wrappedValue = Int($0)
            }
        )
    }
    
    func or0Double() -> Binding<Double> {
        Binding<Double>(
            get: {
                Double(self.wrappedValue ?? 0)
            },
            set: {
                self.wrappedValue = Int($0)
            }
        )
    }
}
