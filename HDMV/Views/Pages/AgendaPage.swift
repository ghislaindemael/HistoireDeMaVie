//
//  AgendaPage.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.06.2025.
//


import SwiftUI

struct AgendaPage: View {
    @StateObject private var viewModel = AgendaViewModel()
    
    private enum FocusField: Hashable {
        case content
    }
    @FocusState private var focusedField: FocusField?
    
    
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
                    ProgressView("Loading...")
                    Spacer()
                } else {
                    
                    Form {
                        Section(header: Text("Day Summary")) {
                            TextEditor(text: $viewModel.daySummary)
                                .frame(minHeight: 80)
                                .focused($focusedField, equals: .content)
                        }
                        
                        Section(header: Text("Daily Mood")) {
                            VStack {
                                Slider(
                                    value: $viewModel.mood,
                                    in: 0...10,
                                    step: 1
                                )
                            }
                            
                            TextEditor(text: $viewModel.moodComments)
                                .frame(minHeight: 80)
                                .focused($focusedField, equals: .content)
                        }
                    }
                    
                }
            }
            .navigationTitle("Agenda")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    SyncStatusButton(
                        status: viewModel.syncStatus,
                        action: viewModel.saveChanges
                    )
                }
            }
            .onTapGesture {
                focusedField = nil
            }
            .task(id: viewModel.selectedDate) {
                await viewModel.fetchAgendaForSelectedDate()
            }
        }
        
        
    }
    
}

#Preview {
    AgendaPage()
    
}
