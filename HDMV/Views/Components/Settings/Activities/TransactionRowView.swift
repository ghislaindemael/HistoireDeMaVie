//
//  TransactionRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//


import SwiftUI
import SwiftData

struct TransactionRowView: View {
    let transaction: Transaction
    let selectedDate: Date
    init(
        transaction: Transaction,
        selectedDate: Date = .now
    ) {
        self.transaction = transaction
        self.selectedDate = selectedDate
    }
    
    var body: some View {
        Group {
            if transaction.isDeleted || transaction.modelContext == nil {
                EmptyView()
            } else {
                VStack(spacing: 0) {
                    basicsSection
                    detailsSection
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primaryBackground)
                )
            }
        }
    }
    
    // MARK: - Basics Section (Type & Amount)
    @ViewBuilder
    private var basicsSection: some View {
        HStack(alignment: .top) {
            // 1. Icon & Type
            HStack(spacing: 8) {
                IconView(
                    iconString: transaction.type?.icon ?? "dollarsign.circle",
                    size: 30,
                    tint: transaction.type == nil ? .red : .primary
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.type?.name ?? "Uncategorized")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(transaction.type != nil ? Color.primary : Color.red)
                    
                    if let execDate = transaction.executionDate {
                        Text("Executed: \(execDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        DateRangeDisplayView(
                            startDate: transaction.transactionTime,
                            endDate: transaction.timeEnd,
                            selectedDate: selectedDate
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                SyncStatusIndicator(status: transaction.syncStatus)
                
                if let amount = transaction.amount, let currency = transaction.currency {
                    let isIncome = amount > 0
                    
                    Text("\(isIncome ? "+" : "")\(amount.formatted()) \(currency)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(isIncome ? .green : .primary)
                } else {
                    Text("Amount Unset")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.red)
                }
                
                if let source = transaction.sourceAccount {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right.circle")
                        Text(source.name)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                }
                
                if let target = transaction.targetAccount {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down.left.circle")
                        Text(target.name)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Details Section (Context & Notes)
    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            let hasPayer = transaction.payer != nil
            let hasParent = transaction.parentInstance != nil
            
            if hasPayer || hasParent {
                HStack(spacing: 8) {
                    if let payer = transaction.payer {
                        Label(payer.fullName, systemImage: "person.fill")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackground)
                            .cornerRadius(4)
                    }
                    
                    if let parent = transaction.parentInstance {
                        Label(parent.activity?.name ?? "Activity", systemImage: parent.activity?.icon ?? "flowchart.fill")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackground)
                            .cornerRadius(4)
                    }
                }
                .padding(.bottom, 2)
            }
            
            if let details = transaction.details, !details.isEmpty {
                Text(details)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondaryBackground)
                    )
                    .foregroundColor(Color.primary)
                    .font(.body)
            }
            
            LifeContextsDisplayView(contextRids: transaction.contextRids)
            
            optionsPillsView
        }
    }
    
    // MARK: - Options Pills View
    @ViewBuilder
    private var optionsPillsView: some View {
        let engine = DynamicOptionsLayoutEngine(transaction: transaction)
        let layoutView = engine.renderAll()
        
        VStack(alignment: .leading, spacing: 4) {
            layoutView
            missingRequiredOptionsWarnings
        }
    }
    
    @ViewBuilder
    private var missingRequiredOptionsWarnings: some View {
        let missing = transaction.type?.optionMappings.filter { mapping in
            !mapping.isDeleted && mapping.required && (transaction.decodedLogDetails?.options?[mapping.optionSlug] == nil || transaction.decodedLogDetails?.options?[mapping.optionSlug]?.isEmpty == true)
        } ?? []
        
        if !missing.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(missing, id: \.id) { mapping in
                    MissingDetailWarningView(
                        message: "Missing \(mapping.option?.name ?? mapping.optionSlug)",
                        iconName: "exclamationmark.triangle.fill",
                        isRequired: true
                    )
                }
            }
        }
    }
}
