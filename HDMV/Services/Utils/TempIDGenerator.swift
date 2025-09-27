//
//  TempIDGenerator.swift
//  HDMV
//
//  Created by Ghislain Demael on 27.09.2025.
//

import SwiftUI
import SwiftData

struct TempIDGenerator {
    
    static func generate<T>(for model: T.Type, in context: ModelContext) -> Int
    where T: PersistentModel, T: Identifiable, T.ID == Int {
        
        do {
            var descriptor = FetchDescriptor<T>()
            descriptor.predicate = #Predicate<T> { $0.id < 0 }
            descriptor.sortBy = [SortDescriptor(\.id, order: .forward)]
            descriptor.fetchLimit = 1
            
            let minID = try context.fetch(descriptor).first?.id ?? 0
            
            return minID - 1
            
        } catch {
            print("Failed to fetch minimum ID for \(String(describing: model)): \(error)")
            return Int.random(in: -999999 ... -1)
        }
    }
}
