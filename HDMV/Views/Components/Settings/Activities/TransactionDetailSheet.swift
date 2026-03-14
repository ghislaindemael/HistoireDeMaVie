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
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    init(transaction: Transaction, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: TransactionDetailSheetViewModel(
            model: transaction,
            modelContext: modelContext
        ))
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
                        TextField("Amount", value: $viewModel.editor.amount, formatter: currencyFormatter)
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
                        TextField("0.00", value: $viewModel.editor.realAmount, formatter: currencyFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("My Share (Cost)")
                        Spacer()
                        TextField("0.00", value: $viewModel.editor.myCost, formatter: currencyFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    .help("How much of this transaction actually comes out of your pocket.")
                }
                
                // MARK: - 5. Bank Clearance
                Section("Bank Reconciliation") {
                    HStack {
                        Text("Bank Amount")
                        Spacer()
                        TextField("0.00", value: $viewModel.editor.bankAmount, formatter: currencyFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Bank Currency")
                        Spacer()
                        TextField("CUR", text: Binding(
                            get: { viewModel.editor.bankCurrency ?? "" },
                            set: { viewModel.editor.bankCurrency = $0.isEmpty ? nil : $0.uppercased() }
                        ))
                        .textInputAutocapitalization(.characters)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
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
                        viewModel.onDone()
                        dismiss()
                    }
                    .disabled(viewModel.editor.amount == nil || viewModel.editor.type == nil)
                }
            }
        }
    }
}
