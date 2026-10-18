import SwiftUI

struct FoodMacrosSummaryView: View {
    let macros: DataFoodItemMacros?
    
    var body: some View {
        if let macros = macros, macros.hasAnyValue {
            FlowLayout(spacing: 6) {
                if let cals = macros.calories {
                    MacroBubble(label: "Cal", value: "\(formatVal(cals)) kcal", color: .orange)
                }
                if let p = macros.protein {
                    MacroBubble(label: "P", value: "\(formatVal(p))g", color: .red)
                }
                if let c = macros.carbs {
                    MacroBubble(label: "C", value: "\(formatVal(c))g", color: .blue)
                }
                if let f = macros.fat {
                    MacroBubble(label: "F", value: "\(formatVal(f))g", color: .yellow)
                }
                if let fib = macros.fiber {
                    MacroBubble(label: "Fiber", value: "\(formatVal(fib))g", color: .green)
                }
                if let sug = macros.sugar {
                    MacroBubble(label: "Sugar", value: "\(formatVal(sug))g", color: .pink)
                }
                if let sat = macros.saturatedFat {
                    MacroBubble(label: "Sat", value: "\(formatVal(sat))g", color: .brown)
                }
                if let sod = macros.sodium {
                    MacroBubble(label: "Sodium", value: "\(formatVal(sod))mg", color: .purple)
                }
                if let alc = macros.alcohol {
                    MacroBubble(label: "Alcohol", value: "\(formatVal(alc))%", color: .indigo)
                }
            }
            .padding(.vertical, 4)
        } else {
            HStack {
                Text("Configure Macros")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    private func formatVal(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            return String(format: "%.1f", val)
        }
    }
}

struct MacroBubble: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
            Text(value)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

struct FoodMacrosEditView: View {
    @Binding var macros: DataFoodItemMacros?
    var subtitle: String? = nil
    
    private func binding(for keyPath: WritableKeyPath<DataFoodItemMacros, Double?>) -> Binding<Double?> {
        Binding<Double?>(
            get: { macros?[keyPath: keyPath] },
            set: { newValue in
                if macros == nil { macros = DataFoodItemMacros() }
                macros?[keyPath: keyPath] = newValue
            }
        )
    }
    
    var body: some View {
        Form {
            Section {
                macroRow(title: "Calories", unit: "kcal", keyPath: \.calories)
                macroRow(title: "Protein", unit: "g", keyPath: \.protein)
                macroRow(title: "Carbs", unit: "g", keyPath: \.carbs)
                macroRow(title: "Fat", unit: "g", keyPath: \.fat)
                macroRow(title: "Fiber", unit: "g", keyPath: \.fiber)
                macroRow(title: "Sugar", unit: "g", keyPath: \.sugar)
                macroRow(title: "Saturated Fat", unit: "g", keyPath: \.saturatedFat)
                macroRow(title: "Sodium", unit: "mg", keyPath: \.sodium)
                macroRow(title: "Alcohol", unit: "%", keyPath: \.alcohol)
            } header: {
                if let subtitle = subtitle {
                    Text(subtitle)
                }
            } footer: {
                if macros?.hasAnyValue == true {
                    Button(role: .destructive) {
                        macros = nil
                    } label: {
                        Text("Clear All Macros")
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Nutrition & Macros")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func macroRow(title: String, unit: String, keyPath: WritableKeyPath<DataFoodItemMacros, Double?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(unit, value: binding(for: keyPath), format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text(unit)
                .font(.callout)
                .foregroundColor(.secondary)
                .frame(minWidth: 35, alignment: .leading)
        }
    }
}
