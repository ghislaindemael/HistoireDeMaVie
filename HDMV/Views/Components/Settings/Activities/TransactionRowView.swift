//
//  TransactionRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//


import SwiftUI
import SwiftData

struct TransactionRowView: View {
    @Environment(\.modelContext) private var modelContext
    let transaction: Transaction
    let selectedDate: Date
    let showParentBadge: Bool
    
    init(
        transaction: Transaction,
        selectedDate: Date = .now,
        showParentBadge: Bool = false
    ) {
        self.transaction = transaction
        self.selectedDate = selectedDate
        self.showParentBadge = showParentBadge
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
                        let tz = transaction.resolvedStartTimeZone(in: modelContext)
                        HStack(spacing: 4) {
                            Text("Executed:")
                            DateDisplayView(
                                date: execDate,
                                selectedDate: selectedDate,
                                timeZone: tz
                            )
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else {
                        DateRangeDisplayView(
                            startDate: transaction.transactionTime,
                            endDate: transaction.timeEnd,
                            selectedDate: selectedDate,
                            startTimeZone: transaction.resolvedStartTimeZone(in: modelContext),
                            endTimeZone: transaction.resolvedEndTimeZone(in: modelContext)
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
            
            if showParentBadge {
                if let parent = transaction.parentInstance {
                    HStack(spacing: 8) {
                        Label(parent.activity?.name ?? "Activity", systemImage: parent.activity?.icon ?? "flowchart.fill")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackground)
                            .cornerRadius(4)
                    }
                    .padding(.bottom, 2)
                } else if let parentTrip = transaction.parentTrip {
                    HStack(spacing: 8) {
                        Label(parentTrip.vehicle?.name ?? "Trip", systemImage: parentTrip.vehicle?.icon ?? "car.fill")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondaryBackground)
                            .cornerRadius(4)
                    }
                    .padding(.bottom, 2)
                }
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
            
            LinkedFilesPillView(transaction: transaction)
            
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
        }
    }
}
