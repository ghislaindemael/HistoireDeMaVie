//
//  Person.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import Foundation
import SwiftData

@Model
final class Person: CatalogueModel {
    @Attribute(.unique) var rid: Int?
    var slug: String?
    var name: String?
    var familyName: String?
    var surname: String?
    var birthdate: Date?
    var cache: Bool = true
    var archived: Bool = false
    @Attribute var syncStatusRaw: String = SyncStatus.undef.rawValue

    typealias Payload = PersonPayload
    typealias DTO = PersonDTO
    
    init(
        rid: Int? = nil,
        slug: String? = nil,
        name: String? = nil,
        familyName: String? = nil,
        surname: String? = nil,
        birthdate: Date? = nil,
        cache: Bool = true,
        archived: Bool = false,
        syncStatus: SyncStatus = .undef
    ) {
        self.rid = rid;
        self.slug = slug;
        self.name = name;
        self.familyName = familyName;
        self.surname = surname;
        self.birthdate = birthdate;
        self.cache = cache;
        self.archived = archived
        self.syncStatus = .local
    }
    
    convenience init(fromDto dto: DTO){
        self.init()
        self.rid = dto.id
        self.slug = dto.slug
        self.name = dto.name
        self.familyName = dto.family_name
        self.surname = dto.surname
        self.birthdate = dto.birthdate
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = .synced
    }
    
    func update(fromDto dto: DTO) {
        self.slug = dto.slug
        self.name = dto.name
        self.familyName = dto.family_name
        self.surname = dto.surname
        self.birthdate = dto.birthdate
        self.cache = dto.cache
        self.archived = dto.archived
        self.syncStatus = .synced
    }
    
    func isValid() -> Bool {
        return slug != nil && name != nil  && familyName != nil
    }
    
    var fullName: String {
        var str = "\(familyName ?? "TOSET") \(name ?? "TOSET")"
        if let surname = surname, !surname.isEmpty {
            str += " (\(surname))"
        }
        return str
    }
    
}

// MARK: - DTOs for Network
struct PersonDTO: Codable, Identifiable, Sendable {
    var id: Int
    var slug: String
    var name: String
    var family_name: String
    var surname: String?
    var birthdate: Date?
    var cache: Bool
    var archived: Bool
}

struct PersonPayload: Codable, Sendable, InitializableWithModel {
    var slug: String
    var name: String
    var family_name: String
    var surname: String?
    var birthdate: Date?
    var cache: Bool
    var archived: Bool
    
    typealias Model = Person
    
    init?(from person: Person) {
        guard person.isValid(),
              let name = person.name,
              let slug = person.slug,
              let familyName = person.familyName
        else { return nil }
        
        self.slug = slug
        self.name = name
        self.family_name = familyName
        self.surname = person.surname
        self.birthdate = person.birthdate
        self.cache = person.cache
        self.archived = person.archived
    }

}

struct PersonEditor: CachableModel {
    var slug: String?
    var name: String?
    var familyName: String?
    var surname: String?
    var birthdate: Date?
    var cache: Bool
    var archived: Bool
    
    init(from person: Person) {
        self.slug = person.slug
        self.name = person.name
        self.familyName = person.familyName
        self.surname = person.surname
        self.birthdate = person.birthdate
        self.cache = person.cache
        self.archived = person.archived
    }
    
    func apply(to person: Person) {
        person.slug = self.slug ?? person.slug
        person.name = self.name ?? person.name
        person.familyName = self.familyName ?? person.familyName
        person.surname = self.surname
        person.birthdate = self.birthdate
        person.cache = self.cache
        person.archived = self.archived
    }
}
