//
//  MealsPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 09.06.2025.
//

import SwiftUI

struct MealsPage: View {
    
    @StateObject private var viewModel = MealsViewModel()
    
    var body: some View {
        NavigationStack {
            
            VStack {
                DatePicker(
                    "Select a Date",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading Meals...")
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else if viewModel.meals.isEmpty {
                    Spacer()
                    Text("No meals recorded for this day.")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List($viewModel.meals) { $meal in
                        MealComponent(
                            meal: $meal,
                            onUpdate: { viewModel.mealWasUpdated($meal.wrappedValue) },
                            onRetry: { viewModel.retryUpload(for: $meal.wrappedValue) },
                            onEndNow: {
                                viewModel.endMealNow(for: $meal.wrappedValue)
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding([.bottom], 6)
                    }
                    
                }
            }
            .navigationTitle("My Meals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.isAddingMeal = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.isOnline {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isAddingMeal) {
            AddMealSheet(for: viewModel.selectedDate, onSave: viewModel.addMeal)
        }
        .task(id: viewModel.selectedDate) {
            await viewModel.fetchMealsForSelectedDate()
        }
    }
    
}

#Preview {
    MealsPage()
}
