//
//  RelationResolver.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.10.2025.
//

import SwiftData
import SwiftUI

enum RelationResolver {
    private static weak var _context: ModelContext?

    static var context: ModelContext? { _context }

    static func setContext(_ ctx: ModelContext) {
        _context = ctx
    }
    
    static func resolve<T>(relationship rel: T?, rid: Int?) -> T? where T: PersistentModel & SyncableModel {
        if let object = rel { return object }
        
        guard let theRid = rid, let ctx = context else { return nil }
        let descriptor = FetchDescriptor<T>(predicate: #Predicate { $0.rid == theRid })
        return try? ctx.fetch(descriptor).first
    }
}


extension ActivityInstance {
    var activity: Activity? {
        get {
            let resolvedActivity = RelationResolver.resolve(relationship: relActivity, rid: activityRid)
            if relActivity == nil, let fetchedActivity = resolvedActivity {
                self.relActivity = fetchedActivity
            }            
            return resolvedActivity
        }
        set {
            relActivity = newValue
        }
    }
}

extension PersonInteraction {
    var person: Person? {
        get {
            RelationResolver.resolve(relationship: relPerson, rid: personRid)
        }
        set {
            relPerson = newValue
        }
    }
}
