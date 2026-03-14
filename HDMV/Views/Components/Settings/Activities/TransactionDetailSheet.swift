//
//  TransactionDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.02.2026.
//

import SwiftUI
import SwiftData

struct TransactionDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: TransactionDetailSheetViewModel
    
    // Formatter for currency input
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
        NavigationView {
            Form {
                Section("Basics") {
                    DatePicker("Date", selection: $viewModel.editor.timeStart, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Description", text: Binding(
                        get: { viewModel.editor.details ?? "" },
                        set: { viewModel.editor.details = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section("Amounts") {
                    HStack {
                        TextField("Amount", value: $viewModel.editor.amount, formatter: currencyFormatter)
                            .keyboardType(.decimalPad)
                            .font(.headline)
                        
                        Divider()
                        
                        TextField("CUR", text: Binding(
                            get: { viewModel.editor.currency ?? "CHF" },
                            set: { viewModel.editor.currency = $0.uppercased() }
                        ))
                        .frame(width: 60)
                        .textInputAutocapitalization(.characters)
                    }
                    
                    Toggle("Paid in Cash", isOn: $viewModel.editor.isCash)
                }
                
                Section("Context") {
                    Picker("Payer", selection: $viewModel.editor.payer) {
                        Text("Me").tag(nil as Person?)
                        ForEach(viewModel.availablePeople) { person in
                            Text(person.name).tag(person as Person?)
                        }
                    }
                    
                    HStack {
                        Text("My Share")
                        Spacer()
                        TextField("Full Amount", value: $viewModel.editor.myCost, formatter: currencyFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(viewModel.editor.myCost == nil ? .secondary : .primary)
                    }
                    .help("Leave empty if you paid for yourself (100%)")
                }
                
                // 4. CATEGORIZATION (Optional)
                /*
                Section("Category") {
                    // Your TransactionType Picker would go here
                }
                */
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
                }
            }
        }
    }
}
