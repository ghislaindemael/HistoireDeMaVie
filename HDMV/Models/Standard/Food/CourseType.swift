//
//  CourseType.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.09.2025.
//


enum CourseType: String, Codable, CaseIterable, Identifiable {
    case aperitif = "Apéritif"
    case entree = "Entrée"
    case entree2 = "Seconde Entrée"
    case plat = "Plat principal"
    case plat2 = "Plat principal 2"
    case fromage = "Fromage"
    case dessert = "Dessert"
    case fruits = "Fruits"
    case cafe = "Café"
    case the = "Thé / Tisane"
    case digestif = "Digestif"
    case divers = "Divers / Notes"
    
    var id: String { self.rawValue }
}
