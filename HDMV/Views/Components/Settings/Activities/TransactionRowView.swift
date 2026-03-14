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
    
    let onQuickAction: (() -> Void)?
    
    init(
        transaction: Transaction,
        selectedDate: Date = .now,
        onQuickAction: (() -> Void)? = nil
    ) {
        self.transaction = transaction
        self.selectedDate = selectedDate
        self.onQuickAction = onQuickAction
    }
    
    var body: some View {
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
                
                if transaction.isCash {
                    HStack(spacing: 2) {
                        Image(systemName: "banknote")
                        Text("Cash")
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
            
            if let onQuickAction = onQuickAction {
                Button(action: onQuickAction) {
                    Text("Quick Action")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                .padding(.top, 4)
            }
        }
    }
}
