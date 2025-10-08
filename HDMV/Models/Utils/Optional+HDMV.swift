//
//  Optional+HDMV.swift
//  HDMV
//
//  Created by Ghislain Demael on 08.10.2025.
//


extension Optional where Wrapped == String {
    var bound: String {
        get { self ?? "" }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}
