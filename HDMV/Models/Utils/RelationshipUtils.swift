//
//  RelationshipUtils.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.11.2025.
//

internal func assignRelation<T: SyncableModel>(
    _ object: T?,
    to property: inout T?,
    rid: inout Int?,
    clearRidIfNil: Bool = false
) {
    if property !== object {
        property = object
        rid = object?.rid ?? (clearRidIfNil ? nil : rid)
    }
}


func resolve<T: SyncableModel, M: SyncableModel>(
    _ models: [T],
    using cache: [Int: M],
    keyPath: ReferenceWritableKeyPath<T, M?>,
    ridPath: KeyPath<T, Int?>
) {
    for model in models {
        if model[keyPath: keyPath] == nil, let rid = model[keyPath: ridPath] {
            model[keyPath: keyPath] = cache[rid]
        }
    }
}
