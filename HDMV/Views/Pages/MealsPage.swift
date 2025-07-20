//
//  MealsPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.07.2025.
//

import SwiftUI
import SwiftData

struct MealsPage: View {
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = MealsPageViewModel()
        
    @State private var editingMeal: Meal? = nil
    @State private var endingMealId: Int?
    
    var body: some View {
        NavigationStack {
            mealsListView
                .navigationTitle("Meals")
                .toolbar { toolbarContent }
                .task(id: viewModel.selectedDate) {
                    await viewModel.loadData()
                }
                .onAppear {
                    viewModel.setup(modelContext: modelContext)
                }
                .overlay {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                            .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .sheet(item: $editingMeal) { meal in
                    EditMealSheet(
                        mealTypes: viewModel.mealTypes,
                        meal: meal,
                        onSave: { updated in
                            viewModel.updateMealLocally(updated)
                            editingMeal = nil
                        },
                        
                    )
                }
        }
    }
    
    // MARK: - View Components
    
    /// A computed property for the main view content to help the compiler.
    private var mealsListView: some View {
        VStack(spacing: 12) {
            DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)
            
            List {
                ForEach(viewModel.allMeals) { meal in
                    viewForRow(for: meal )
                }
            }
        }
        
    }
    
    private func viewForRow(for meal: Meal) -> some View {
        VStack(spacing: 8) {
            MealRowView(
                meal: meal,
                mealType: viewModel.mealTypes.first(where: { $0.id == meal.mealTypeId })
            )
            .onTapGesture {
                editingMeal = meal
            }
            .padding(.top, meal.time_end == nil ? 6 : 0)
            .animation(nil, value: endingMealId)
            .zIndex(1)
            
            endMealButton(for: meal)
                .frame(maxHeight: meal.time_end == nil ? .infinity : 0)
                .opacity(meal.time_end == nil ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: meal.time_end)
                .scaleEffect(endingMealId == meal.id ? 0.01 : 1.0)
        }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func endMealButton(for meal: Meal) -> some View {
        
        Button("End Meal") {
            withAnimation {
                endingMealId = meal.id
            } completion: {
                let endedMeal = meal
                endedMeal.time_end = .now
                viewModel.updateMealLocally(endedMeal)
                endingMealId = nil
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.red)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .buttonStyle(.plain)
        
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                Task { await viewModel.loadData() }
            }) {
                Image(systemName: "icloud.and.arrow.down")
                Text("Refresh")
            }
            .accessibilityLabel("Reload meals")
        }
        
        if viewModel.hasUnsyncedChanges() {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    Task { await viewModel.syncChanges() }
                }) {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Save")
                }
                .accessibilityLabel("Sync changes")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
            } label: {
                HStack{
                    Text("New meal")
                    Image(systemName: "plus")
                }
            }
            .simultaneousGesture(LongPressGesture().onEnded { _ in
                viewModel.createNewMeal(at: viewModel.selectedDate)
            })
            .simultaneousGesture(TapGesture().onEnded {
                viewModel.createNewMeal()
            })
            
        }
        
    }
    
    
}
