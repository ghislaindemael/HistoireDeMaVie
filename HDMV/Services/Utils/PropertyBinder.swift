//
//  PropertyBinder.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import Foundation
import Combine

/// A generic helper class that subscribes to a publisher and assigns its
/// values to a property on a given object.
/// This object holds the subscription, keeping it alive.
final class PropertyBinder<Root: AnyObject, Value> {
    private var cancellable: AnyCancellable?
    
    init(
        for object: Root,
        keyPath: ReferenceWritableKeyPath<Root, Value>,
        from publisher: AnyPublisher<Value, Never>
    ) {
        self.cancellable = publisher
            .sink { [weak object] value in
                object?[keyPath: keyPath] = value
            }
    }
}

@MainActor
extension PropertyBinder where Value == Bool {
    /// A convenience initializer specifically for binding network status.
    convenience init(
        syncingNetworkStatusTo keyPath: ReferenceWritableKeyPath<Root, Bool>,
        on object: Root
    ) {
        self.init(
            for: object,
            keyPath: keyPath,
            from: NetworkMonitor.shared.$isConnected.eraseToAnyPublisher()
        )
    }
}
