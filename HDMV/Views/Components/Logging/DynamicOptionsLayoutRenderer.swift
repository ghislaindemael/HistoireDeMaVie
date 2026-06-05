//
//  DynamicOptionsLayoutRenderer.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

class DynamicOptionsLayoutEngine {
    let instance: ActivityInstance
    var consumedSlugs = Set<String>()
    
    init(instance: ActivityInstance) {
        self.instance = instance
    }
    
    func renderAll() -> AnyView {
        guard let mappings = instance.activity?.optionMappings.sorted(by: { $0.priority < $1.priority }) else {
            return AnyView(EmptyView())
        }
        
        var views = [AnyView]()
        
        // Find all slugs that are handled by any custom layout
        var slugsHandledByLayouts = Set<String>()
        for mapping in mappings {
            if let layout = mapping.option?.config?.layoutNode {
                slugsHandledByLayouts.formUnion(layout.referencedSlugs)
            }
        }
        
        for mapping in mappings {
            if consumedSlugs.contains(mapping.optionSlug) { continue }
            
            if let layout = mapping.option?.config?.layoutNode {
                consumedSlugs.formUnion(layout.referencedSlugs)
                consumedSlugs.insert(mapping.optionSlug)
                
                views.append(render(node: layout))
            } else {
                if slugsHandledByLayouts.contains(mapping.optionSlug) {
                    continue // Skip rendering default pill, it will be handled by a layout node later!
                }
                
                views.append(AnyView(defaultPill(for: mapping)))
                consumedSlugs.insert(mapping.optionSlug)
            }
        }
        
        if views.isEmpty {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<views.count, id: \.self) { i in
                    views[i]
                }
            }
        )
    }
    
    func render(node: ActivityLayoutNode) -> AnyView {
        switch node {
        case .hStack(let spacing, let children):
            let childViews = children.map { render(node: $0) }
            return AnyView(HStack(spacing: spacing) {
                ForEach(0..<childViews.count, id: \.self) { i in childViews[i] }
            })
            
        case .vStack(let alignment, let spacing, let children):
            let align: HorizontalAlignment = {
                switch alignment {
                case "leading": return .leading
                case "trailing": return .trailing
                default: return .center
                }
            }()
            let childViews = children.map { render(node: $0) }
            return AnyView(VStack(alignment: align, spacing: spacing) {
                ForEach(0..<childViews.count, id: \.self) { i in childViews[i] }
            })
            
        case .text(let value, let colorHex, let fontStyle):
            let t = Text(value).font(font(for: fontStyle))
            if let c = color(for: colorHex) {
                return AnyView(t.foregroundStyle(c))
            }
            return AnyView(t)
            
        case .optionLabel(let slug, let colorHex, let fontStyle):
            if let label = getLabel(for: slug) {
                consumedSlugs.insert(slug)
                let t = Text(label).font(font(for: fontStyle))
                if let c = color(for: colorHex) {
                    return AnyView(t.foregroundStyle(c))
                }
                return AnyView(t)
            }
            return AnyView(EmptyView())
            
        case .optionIcon(let slug, let colorHex, let size):
            if let icon = getIcon(for: slug) {
                consumedSlugs.insert(slug)
                let img = Image(systemName: icon).font(.system(size: size ?? 14))
                if let c = color(for: colorHex) {
                    return AnyView(img.foregroundStyle(c))
                }
                return AnyView(img)
            }
            return AnyView(EmptyView())
            
        case .formattedValue(let slug, let format, let colorHex, let fontStyle):
            if let valueString = getValue(for: slug) {
                consumedSlugs.insert(slug)
                let formatted = applyFormat(value: valueString, format: format)
                let t = Text(formatted).font(font(for: fontStyle))
                if let c = color(for: colorHex) {
                    return AnyView(t.foregroundStyle(c))
                }
                return AnyView(t)
            }
            return AnyView(EmptyView())
            
        case .conditional(let condition, let child):
            if evaluate(condition: condition) {
                return render(node: child)
            }
            return AnyView(EmptyView())
            
        case .pill(let child, let colorHex, let fullWidth):
            let childView = render(node: child)
            return AnyView(
                HStack {
                    childView
                    if fullWidth == true {
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background((color(for: colorHex) ?? Color.teal).opacity(0.2))
                .foregroundStyle(color(for: colorHex) ?? Color.teal)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
            
        case .spacer:
            return AnyView(Spacer())
            
        case .unrenderedOptions:
            // Find mappings that are not consumed yet
            let unrendered = instance.activity?.optionMappings
                .sorted(by: { $0.priority < $1.priority })
                .filter { !consumedSlugs.contains($0.optionSlug) } ?? []
            
            let views = unrendered.map { mapping -> AnyView in
                consumedSlugs.insert(mapping.optionSlug)
                return AnyView(defaultPill(for: mapping))
            }
            
            return AnyView(HStack(spacing: 8) {
                ForEach(0..<views.count, id: \.self) { i in views[i] }
            })
        }
    }
    
    // MARK: - Default Pill
    
    private func defaultPill(for mapping: DataActivityOptionMapping) -> some View {
        let slug = mapping.optionSlug
        let label = getLabel(for: slug) ?? ""
        let icon = getIcon(for: slug)
        
        let val = getValue(for: slug) ?? ""
        let def = mapping.option?.config?.defaultValue ?? ""
        if val == def || val.isEmpty {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                }
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer() // Full width
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.teal.opacity(0.2))
            .foregroundStyle(Color.teal)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        )
    }
    
    // MARK: - Helpers
    
    private func font(for style: String?) -> Font {
        switch style {
        case "headline": return .headline
        case "subheadline": return .subheadline
        case "caption": return .caption
        case "title": return .title
        case "title2": return .title2
        case "title3": return .title3
        case "body": return .body
        default: return .body
        }
    }
    
    private func color(for hex: String?) -> Color? {
        guard let hex = hex else { return nil }
        // Simple hex parser (assumes #RRGGBB)
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return nil
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return Color(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0
        )
    }
    
    private func getValue(for slug: String) -> String? {
        return instance.decodedActivityDetails?.options?[slug]
    }
    
    private func getLabel(for slug: String) -> String? {
        let val = getValue(for: slug) ?? ""
        
        // Find the mapped option config to see if we should resolve a label
        if let mapping = instance.activity?.optionMappings.first(where: { $0.optionSlug == slug }),
           let option = mapping.option {
            
            if val.isEmpty {
                return option.config?.defaultValue ?? option.name
            }
            
            if option.type == .dropdown, let choices = option.config?.choices {
                let selections = val.components(separatedBy: ",")
                var labels = [String]()
                for sel in selections {
                    if let c = choices.first(where: { $0.slug == sel }) {
                        labels.append(c.label)
                    } else {
                        labels.append(sel)
                    }
                }
                return labels.joined(separator: ", ")
            }
            return val
        }
        
        return val.isEmpty ? nil : val
    }
    
    private func getIcon(for slug: String) -> String? {
        guard let mapping = instance.activity?.optionMappings.first(where: { $0.optionSlug == slug }),
              let option = mapping.option else { return nil }
        
        let val = getValue(for: slug) ?? option.config?.defaultValue ?? ""
        
        if option.type == .dropdown, let choices = option.config?.choices, let choice = choices.first(where: { $0.slug == val }) {
            return choice.icon
        }
        return nil
    }
    
    private func applyFormat(value: String, format: ValueFormat) -> String {
        switch format {
        case .decimal(let places, let suffix):
            if let d = Double(value) {
                let formatted = String(format: "%.\(places)f", d)
                if let suf = suffix {
                    return "\(formatted) \(suf)"
                }
                return formatted
            }
            return value
        case .date(let style):
            // Fallback for simple dates
            return value
        }
    }
    
    // MARK: - Logic
    
    private func evaluate(condition: LayoutCondition) -> Bool {
        switch condition {
        case .optionSelected(let slug):
            let val = getValue(for: slug) ?? ""
            return !val.isEmpty
            
        case .optionMissing(let slug):
            let val = getValue(for: slug) ?? ""
            return val.isEmpty
            
        case .optionNotDefault(let slug):
            let val = getValue(for: slug) ?? ""
            guard let mapping = instance.activity?.optionMappings.first(where: { $0.optionSlug == slug }),
                  let option = mapping.option else { return false }
            
            let def = option.config?.defaultValue ?? ""
            return !val.isEmpty && val != def
            
        case .optionEquals(let slug, let expected):
            let val = getValue(for: slug) ?? ""
            return val == expected
            
        case .and(let conditions):
            return conditions.allSatisfy { evaluate(condition: $0) }
            
        case .or(let conditions):
            return conditions.contains { evaluate(condition: $0) }
            
        case .not(let cond):
            return !evaluate(condition: cond)
        }
    }
}
