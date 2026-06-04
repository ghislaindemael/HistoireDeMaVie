//
//  DebugViews.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.09.2025.
//

import SwiftUI

protocol DebugViewable {
    associatedtype DebugView: View
    @ViewBuilder var debugView: DebugView { get }
}

extension DebugViewable {
    var erasedDebugView: AnyView { AnyView(debugView) }
}
