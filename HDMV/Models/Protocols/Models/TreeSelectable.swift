//
//  TreeSelectable.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//


import Foundation

protocol TreeSelectable: Identifiable {
    var name: String { get }
    var icon: String? { get }
    var optionalChildren: [Self]? { get }
}

extension Activity: TreeSelectable {}
extension TransactionType: TreeSelectable {}
