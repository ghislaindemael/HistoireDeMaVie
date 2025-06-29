//
//  Person.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import Foundation
import SwiftData

@Model
final class Person {
    @Attribute(.unique) var id: Int
    var slug: String
    var name: String
    var familyName: String
    var surname: String?
    var birthdate: Date?
    var cache: Bool
    
    init(
        id: Int,
        slug: String,
        name: String,
        familyName: String,
        surname: String?,
        birthdate: Date?,
        cache: Bool
    ) {
        self.id = id;
        self.slug = slug;
        self.name = name;
        self.familyName = familyName;
        self.surname = surname;
        self.birthdate = birthdate;
        self.cache = cache;
    }
    
    init(fromDTO personDTO: PersonDTO) {
        self.id = personDTO.id ?? -1;
        self.slug = personDTO.slug;
        self.name = personDTO.name;
        self.familyName = personDTO.familyName;
        self.surname = personDTO.surname;
        self.birthdate = personDTO.birthdate;
        self.cache = personDTO.cache;
    }
    
    var fullName: String {
        var str = "\(familyName) \(name)"
        if let surname = surname, !surname.isEmpty {
            str += " (\(surname))"
        }
        return str
    }
    
}

// MARK: - DTOs for Network
struct PersonDTO: Codable, Identifiable, Sendable {
    var id: Int?
    var slug: String
    var name: String
    var familyName: String
    var surname: String?
    var birthdate: Date?
    var cache: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, slug, name, surname, birthdate, cache
        case familyName = "family_name"
    }
    
    
}

struct NewPersonPayload: Codable, Sendable {
    var slug: String
    var name: String
    var familyName: String
    var surname: String?
    var birthdate: Date?
    var cache: Bool
    
    enum CodingKeys: String, CodingKey {
        case slug, name, surname, birthdate, cache
        case familyName = "family_name"
    }
    
    init() {
        self.slug = ""
        self.name = ""
        self.familyName = ""
        self.surname = ""
        self.birthdate = nil
        self.cache = true
    }
}
