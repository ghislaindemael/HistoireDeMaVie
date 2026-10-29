//
//  DynamicOptionsLayoutRenderer.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct DynamicOptionItem: Identifiable {
    var id: String { slug }
    let slug: String
    let priority: Int
    let required: Bool
    let option: DataLogOption?
    let layoutNode: ActivityLayoutNode?
    let replacesActivityName: Bool
    
    init(mapping: DataLogOptionMapping) {
        let opt = mapping.option
        self.slug = opt?.slug ?? mapping.optionSlug
        self.priority = mapping.priority
        self.required = mapping.required
        self.option = opt
        self.layoutNode = opt?.config?.layoutNode
        self.replacesActivityName = opt?.config?.replacesActivityName ?? false
    }
    
    init(option: DataLogOption) {
        self.slug = option.slug
        self.priority = option.config?.priority ?? 0
        self.required = option.config?.required ?? false
        self.option = option
        self.layoutNode = option.config?.layoutNode
        self.replacesActivityName = option.config?.replacesActivityName ?? false
    }
}

class DynamicOptionsLayoutEngine {
    let items: [DynamicOptionItem]
    let decodedOptions: [String: String]?
    let modelContext: ModelContext?
    var consumedSlugs = Set<String>()
    
    lazy var slugsHandledByLayouts: Set<String> = {
        var slugs = Set<String>()
        for item in items {
            if let layout = item.layoutNode {
                slugs.formUnion(layout.referencedSlugs)
                slugs.insert(item.slug)
                if let optSlug = item.option?.slug {
                    slugs.insert(optSlug)
                }
            }
        }
        return slugs
    }()
    
    init(items: [DynamicOptionItem], decodedOptions: [String: String]?, modelContext: ModelContext? = nil) {
        self.items = items
        self.decodedOptions = decodedOptions
        self.modelContext = modelContext
    }
    
    convenience init(
        mappings: [DataLogOptionMapping],
        globalOptions: [DataLogOption] = [],
        decodedOptions: [String: String]?,
        modelContext: ModelContext? = nil
    ) {
        let mappingItems = mappings.filter({ !$0.isDeleted && !$0.archived }).map { DynamicOptionItem(mapping: $0) }
        let globalItems = globalOptions.filter({ !$0.archived }).map { DynamicOptionItem(option: $0) }
        self.init(items: mappingItems + globalItems, decodedOptions: decodedOptions, modelContext: modelContext)
    }
    
    convenience init(instance: ActivityInstance) {
        self.init(
            mappings: instance.activity?.optionMappings ?? [],
            decodedOptions: instance.decodedLogDetails?.options,
            modelContext: instance.modelContext
        )
    }
    
    convenience init(transaction: Transaction) {
        var globals: [DataLogOption] = []
        if let context = transaction.modelContext {
            let descriptor = FetchDescriptor<DataLogOption>(
                predicate: #Predicate<DataLogOption> { !$0.archived }
            )
            if let opts = try? context.fetch(descriptor) {
                globals = opts.filter { $0.config?.isForTransaction == true }
            }
        }
        self.init(
            mappings: transaction.type?.optionMappings ?? [],
            globalOptions: globals,
            decodedOptions: transaction.decodedLogDetails?.options,
            modelContext: transaction.modelContext
        )
    }
    
    func renderAll() -> AnyView {
        var activeItems = [DynamicOptionItem]()
        var seenSlugs = Set<String>()
        var seenIds = Set<PersistentIdentifier>()
        
        for item in items.sorted(by: { $0.priority < $1.priority }) {
            let opt = item.option ?? getOption(for: item.slug)
            let primarySlug = opt?.slug ?? item.slug
            guard primarySlug.isNotUnset() && primarySlug != "!unset" && !primarySlug.isEmpty else {
                continue
            }
            if let opt = opt {
                if seenIds.contains(opt.persistentModelID) { continue }
                seenIds.insert(opt.persistentModelID)
            }
            
            if seenSlugs.contains(primarySlug) { continue }
            seenSlugs.insert(primarySlug)
            if !item.slug.isEmpty {
                seenSlugs.insert(item.slug)
            }
            activeItems.append(item)
        }
        
        var views = [AnyView]()
        
        // Consume any slug that replaces the activity name so it doesn't draw a pill
        for item in activeItems {
            let effectiveSlug = item.option?.slug ?? item.slug
            if item.replacesActivityName {
                markConsumed(slug: effectiveSlug)
            }
        }
        
        // Find all slugs that are handled by any custom layout
        for item in activeItems {
            let effectiveSlug = item.option?.slug ?? item.slug
            guard effectiveSlug.isNotUnset() && effectiveSlug != "!unset" && !effectiveSlug.isEmpty else {
                continue
            }
            if isConsumed(effectiveSlug) || isConsumed(item.slug) { continue }
            
            if let layout = item.layoutNode {
                for ref in layout.referencedSlugs {
                    markConsumed(slug: ref)
                }
                markConsumed(slug: effectiveSlug)
                views.append(render(node: layout))
            } else {
                if slugsHandledByLayouts.contains(effectiveSlug) || slugsHandledByLayouts.contains(item.slug) {
                    continue
                }
                
                let isLogged = getValue(for: effectiveSlug) != nil || getValue(for: item.slug) != nil
                let isRequired = item.required
                let shouldShow: Bool
                if isLogged {
                    shouldShow = true
                } else if isRequired {
                    shouldShow = true
                } else if SettingsStore.shared.appMode == .backfill {
                    shouldShow = true
                } else {
                    shouldShow = false
                }
                
                if shouldShow {
                    views.append(AnyView(defaultPill(forSlug: effectiveSlug, isLogged: isLogged, isRequired: isRequired)))
                }
                markConsumed(slug: effectiveSlug)
            }
        }
        
        // Handle any unmapped logged slugs that weren't consumed
        if let decoded = decodedOptions {
            let sortedUnmapped = decoded.keys.filter { !isConsumed($0) && !(decoded[$0]?.isEmpty ?? true) }.sorted()
            for slug in sortedUnmapped {
                views.append(AnyView(defaultPill(forSlug: slug, isLogged: true, isRequired: false)))
                markConsumed(slug: slug)
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
            let loggedSlugs = decodedOptions != nil ? Array(decodedOptions!.keys) : []
            let mappedSlugs = items.map { $0.slug }
            let allSlugs = Set(loggedSlugs).union(mappedSlugs).filter { !isConsumed($0) && !slugsHandledByLayouts.contains($0) }
            
            let unrenderedSlugs = allSlugs.sorted { s1, s2 in
                let p1 = items.first(where: { $0.slug == s1 })?.priority ?? 999
                let p2 = items.first(where: { $0.slug == s2 })?.priority ?? 999
                if p1 == p2 { return s1 < s2 }
                return p1 < p2
            }
            
            let views = unrenderedSlugs.compactMap { slug -> AnyView? in
                let isLogged = getValue(for: slug) != nil
                let item = items.first(where: { $0.slug == slug || $0.option?.slug == slug })
                let isRequired = item?.required == true
                
                let shouldShow: Bool
                if isLogged {
                    shouldShow = true
                } else {
                    if isRequired {
                        shouldShow = true
                    } else if SettingsStore.shared.appMode == .backfill && item != nil {
                        shouldShow = true
                    } else {
                        shouldShow = false
                    }
                }
                
                guard shouldShow else { return nil }
                
                markConsumed(slug: slug)
                return AnyView(defaultPill(forSlug: slug, isLogged: isLogged, isRequired: isRequired))
            }
            
            return AnyView(VStack(spacing: 4) {
                ForEach(0..<views.count, id: \.self) { i in views[i] }
            })
        }
    }
    
    // MARK: - Default Pill
    
    private func defaultPill(forSlug slug: String, isLogged: Bool, isRequired: Bool) -> some View {
        let label = getLabel(for: slug) ?? slug
        let icon = getIcon(for: slug)
        let option = getOption(for: slug)
        
        if isLogged {
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
                .background(Color.teal.opacity(0.15))
                .foregroundStyle(Color.teal)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
        } else {
            return AnyView(
                MissingDetailWarningView(
                    message: "Missing \(option?.name ?? label)",
                    iconName: icon ?? "exclamationmark.triangle.fill",
                    isRequired: isRequired
                )
            )
        }
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
    
    private func isConsumed(_ slug: String) -> Bool {
        consumedSlugs.contains(slug)
    }
    
    private func markConsumed(slug: String) {
        consumedSlugs.insert(slug)
        if let opt = getOption(for: slug) {
            consumedSlugs.insert(opt.slug)
        }
    }
    
    private func getValue(for slug: String) -> String? {
        guard let decoded = decodedOptions else { return nil }
        
        if let val = decoded[slug], !val.isEmpty {
            return val
        }
        
        if let option = getOption(for: slug) {
            if let val = decoded[option.slug], !val.isEmpty {
                return val
            }
        }
        
        return nil
    }
    
    private func getOption(for slug: String) -> DataLogOption? {
        if let item = items.first(where: {
            $0.slug == slug || $0.option?.slug == slug
        }), let option = item.option {
            return option
        }
        if let context = modelContext {
            let descriptor = FetchDescriptor<DataLogOption>(predicate: #Predicate<DataLogOption> { $0.slug == slug })
            if let opt = try? context.fetch(descriptor).first {
                return opt
            }
        }
        return nil
    }
    
    private func getLabel(for slug: String) -> String? {
        let val = getValue(for: slug) ?? ""
        
        // Find the option config to see if we should resolve a label
        if let option = getOption(for: slug) {
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
            
            if option.type != .boolean {
                return "\(option.name): \(val)"
            }
            
            return val
        }
        
        return val.isEmpty ? nil : val
    }
    
    private func getIcon(for slug: String) -> String? {
        guard let option = getOption(for: slug) else { return nil }
        
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
        case .date(_):
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
            guard let item = items.first(where: { $0.slug == slug || $0.option?.slug == slug }),
                  let option = item.option ?? getOption(for: slug) else { return false }
            
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
