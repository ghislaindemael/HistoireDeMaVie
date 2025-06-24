//
//  Binding.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.06.2025.
//

import SwiftUI

extension Binding {
    init?(unwrap binding: Binding<Value?>) {
        guard let wrappedValue = binding.wrappedValue else {
            return nil
        }
        self.init(
            get: { wrappedValue },
            set: { binding.wrappedValue = $0 }
        )
    }
}
