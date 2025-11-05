//
//  LinkedCity.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.11.2025.
//

import SwiftUI
import SwiftData

protocol LinkedCity {
    
    var cityRid: Int? { get set }
    
}

extension LinkedCity {
    func city(in context: ModelContext) -> City? {
        guard let cityRid = cityRid else { return nil }
        return try? context.fetch(FetchDescriptor<City>(
            predicate: #Predicate { $0.rid == cityRid }
        )).first
    }
}

extension Place: LinkedCity {}
