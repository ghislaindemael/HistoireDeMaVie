//
//  ActivityLayoutNode.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import Foundation
import SwiftUI

indirect enum ActivityLayoutNode: Codable, Equatable {
    case hStack(spacing: CGFloat?, children: [ActivityLayoutNode])
    case vStack(alignment: String?, spacing: CGFloat?, children: [ActivityLayoutNode])
    case text(value: String, colorHex: String?, fontStyle: String?)
    case optionLabel(slug: String, colorHex: String?, fontStyle: String?)
    case optionIcon(slug: String, colorHex: String?, size: CGFloat?)
    case formattedValue(slug: String, format: ValueFormat, colorHex: String?, fontStyle: String?)
    case conditional(condition: LayoutCondition, child: ActivityLayoutNode)
    case pill(child: ActivityLayoutNode, colorHex: String?, fullWidth: Bool?)
    case spacer
    case unrenderedOptions
    
    var referencedSlugs: Set<String> {
        switch self {
        case .hStack(_, let children), .vStack(_, _, let children):
            return children.reduce(into: Set<String>()) { $0.formUnion($1.referencedSlugs) }
        case .text, .spacer, .unrenderedOptions:
            return []
        case .optionLabel(let slug, _, _), .optionIcon(let slug, _, _), .formattedValue(let slug, _, _, _):
            return [slug]
        case .conditional(let condition, let child):
            return condition.referencedSlugs.union(child.referencedSlugs)
        case .pill(let child, _, _):
            return child.referencedSlugs
        }
    }
}

indirect enum LayoutCondition: Codable, Equatable {
    case optionSelected(slug: String)
    case optionMissing(slug: String)
    case optionNotDefault(slug: String)
    case optionEquals(slug: String, value: String)
    case and([LayoutCondition])
    case or([LayoutCondition])
    case not(LayoutCondition)
    
    var referencedSlugs: Set<String> {
        switch self {
        case .optionSelected(let slug), .optionMissing(let slug), .optionNotDefault(let slug), .optionEquals(let slug, _):
            return [slug]
        case .and(let conditions), .or(let conditions):
            return conditions.reduce(into: Set<String>()) { $0.formUnion($1.referencedSlugs) }
        case .not(let condition):
            return condition.referencedSlugs
        }
    }
}

enum ValueFormat: Codable, Equatable {
    case decimal(places: Int, suffix: String?)
    case date(style: String)
}
