//
//  CachingComponent.swift
//  HDMV
//
//  Created by Ghislain Demael on 10.06.2025.
//

import SwiftUI

struct CachingComponent: View {
    
    @ObservedObject private var cachingService = CachingService.shared
    @State private var isExpanded: Bool = false
    @State private var isLoading = false
    @State private var lastUpdated: Date?
    @State private var errorMessage: String?
    
    init(expanded: Bool = false) {
        _isExpanded = State(initialValue: expanded)
    }

    var body: some View {
        DisclosureGroup("Data Caching", isExpanded: $isExpanded) {
            VStack(spacing: 10) {
                HStack {
                    Text("Cached Meal Types:")
                    Spacer()
                    Text("\(cachingService.cachedMealTypes.count)")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Cached Vehicle Types:")
                    Spacer()
                    Text("\(cachingService.cachedVehicleTypes.count)")
                        .fontWeight(.bold)
                }
                
                if let lastUpdated = lastUpdated {
                    HStack {
                        Text("Last Updated:")
                        Spacer()
                        Text(lastUpdated, style: .time)
                            .fontWeight(.bold)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button {
                    Task {
                        await recacheData()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        Text("Recache Data")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(isLoading)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 1)
        )
        
    }

    private func recacheData() async {
        isLoading = true
        errorMessage = nil
        do {
            try await cachingService.cacheMealTypes()
            try await cachingService.cacheVehiclesTypes()
            lastUpdated = Date()
        } catch {
            errorMessage = "Failed to recache: \(error.localizedDescription)"
            print("Error recaching data: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    CachingComponent(expanded: true)
}
