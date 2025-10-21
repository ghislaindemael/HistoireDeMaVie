//
//  Optional+HDMV.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//

import SwiftUI

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

extension Binding where Value == Int? {
    /// Provides a non-optional Binding<Double>, mapping nil to/from 0.
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
}
