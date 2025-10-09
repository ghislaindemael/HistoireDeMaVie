//
//  InitializableWithModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.10.2025.
//


protocol InitializableWithModel {
    associatedtype Model
    init?(from model: Model)
}
