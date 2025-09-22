//
//  CourseType.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.09.2025.
//


enum CourseType: String, Codable, CaseIterable, Identifiable {
    case brut = "Brut"
    case aperitif = "Apéritif"
    case entree = "Entrée"
    case plat = "Plat Principal"
    case fromage = "Fromage"
    case dessert = "Dessert"
    case fruits = "Fruits"
    case cafe = "Café & Digestif"
    case divers = "Divers / Notes"
    
    var id: String { self.rawValue }
}
