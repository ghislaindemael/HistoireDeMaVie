import SwiftUI
import SwiftData

struct TransactionDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: TransactionDetailSheetViewModel
    
    private var isStandardCurrency: Bool {
        let cur = viewModel.editor.currency ?? "CHF"
        return cur == "CHF" || cur == "EUR"
    }
    
    private var isStandardBankCurrency: Bool {
        let cur = viewModel.editor.bankCurrency ?? "CHF"
        return cur == "CHF" || cur == "EUR"
    }
    
    init(transaction: Transaction, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: TransactionDetailSheetViewModel(
            model: transaction,
            modelContext: modelContext
        ))
    }
    
    // MARK: - The Magic Fix for Disappearing Decimals
    private func decimalBinding(for value: Binding<Decimal?>) -> Binding<String> {
        Binding(
            get: {
                if let decimal = value.wrappedValue {
                    return NSDecimalNumber(decimal: decimal).stringValue
                }
                return ""
            },
            set: { newValue in
                let sanitized = newValue.replacingOccurrences(of: ",", with: ".")
                if sanitized.isEmpty {
                    value.wrappedValue = nil
                } else if let newDecimal = Decimal(string: sanitized) {
                    value.wrappedValue = newDecimal
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                
                // MARK: - 1. Time & Details
                Section("Basics") {
                    FullTimePicker(
                        label: "Transaction Date",
                        selection: $viewModel.editor.timeStart
                    )
                    
                    FullTimePicker(
                        label: "Execution Date",
                        selection: $viewModel.editor.executionDate
                    )
                    
                    TextField("Description / Notes", text: Binding(
                        get: { viewModel.editor.details ?? "" },
                        set: { viewModel.editor.details = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                }
                
                // MARK: - 2. Categorization & Context
                Section("Context") {
                    NavigationLink(destination: TransactionTypeSelectorView(
                        selectedType: $viewModel.editor.type
                    )) {
                        HStack {
                            Text("Category / Type")
                            Spacer()
                            if let activity = viewModel.editor.type {
                                Text(activity.name)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Required")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    PersonSelectorView(selectedPerson: $viewModel.editor.payer)
                }
                
                // MARK: - 3. Primary Amount
                Section("Primary Amount") {
                    
                    Picker("Type", selection: $viewModel.editor.isIncome) {
                        Text("Expense").tag(false)
                        Text("Income").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 4)
                    
                    HStack {
                        TextField("Amount", text: decimalBinding(for: $viewModel.editor.amount))
                            .keyboardType(.decimalPad)
                            .font(.headline)
                            .foregroundStyle(viewModel.editor.isIncome ? .green : .primary)
                        
                        Divider()
                        
                        Picker("Currency", selection: Binding(
                            get: { isStandardCurrency ? (viewModel.editor.currency ?? "CHF") : "Other" },
                            set: { newValue in
                                if newValue == "Other" {
                                    viewModel.editor.currency = ""
                                } else {
                                    viewModel.editor.currency = newValue
                                }
                            }
                        )) {
                            Text("CHF").tag("CHF")
                            Text("EUR").tag("EUR")
                            Text("Other").tag("Other")
                        }
                        .labelsHidden()
                        .frame(maxWidth: 100)
                    }
                    
                    if !isStandardCurrency {
                        HStack {
                            Text("Custom Currency:")
                                .foregroundStyle(.secondary)
                            TextField("e.g. USD", text: Binding(
                                get: { viewModel.editor.currency ?? "" },
                                set: { viewModel.editor.currency = $0.uppercased() }
                            ))
                            .textInputAutocapitalization(.characters)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Paid in Cash", isOn: $viewModel.editor.isCash)
                }
                
                // MARK: - 4. Advanced Accounting
                Section("Advanced Accounting") {
                    HStack {
                        Text("Real Amount")
                        Spacer()
                        TextField("0.00", text: decimalBinding(for: $viewModel.editor.realAmount))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("My Share (Cost)")
                        Spacer()
                        TextField("0.00", text: decimalBinding(for: $viewModel.editor.myCost))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    .help("How much of this transaction actually comes out of your pocket.")
                }
                
                // MARK: - 5. Bank Clearance
                Section("Bank Reconciliation") {
                    HStack {
                        TextField("Bank Amount", text: decimalBinding(for: $viewModel.editor.bankAmount))
                            .keyboardType(.decimalPad)
                        
                        Divider()
                        
                        Picker("Bank Currency", selection: Binding(
                            get: { isStandardBankCurrency ? (viewModel.editor.bankCurrency ?? "CHF") : "Other" },
                            set: { newValue in
                                if newValue == "Other" {
                                    viewModel.editor.bankCurrency = ""
                                } else {
                                    viewModel.editor.bankCurrency = newValue
                                }
                            }
                        )) {
                            Text("CHF").tag("CHF")
                            Text("EUR").tag("EUR")
                            Text("Other").tag("Other")
                        }
                        .labelsHidden()
                        .frame(maxWidth: 100)
                    }
                    
                    if !isStandardBankCurrency {
                        HStack {
                            Text("Custom Bank Cur:")
                                .foregroundStyle(.secondary)
                            TextField("e.g. USD", text: Binding(
                                get: { viewModel.editor.bankCurrency ?? "" },
                                set: { viewModel.editor.bankCurrency = $0.uppercased() }
                            ))
                            .textInputAutocapitalization(.characters)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        viewModel.onDone()
                        dismiss()
                    }
                }
            }
        }
    }
}
