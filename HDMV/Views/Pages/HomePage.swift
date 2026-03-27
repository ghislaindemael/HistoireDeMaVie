//
//  HomePage.swift
//  HDMV
//
//  Created by Ghislain Demael on 11.06.2025.
//

import SwiftUI
import SwiftData

struct HomePage: View {
    @EnvironmentObject private var appNavigator: AppNavigator
    
    @Query private var pendingTasks: [VaultTask]
    
    init() {
        let filter = #Predicate<VaultTask> { task in
            task.statusRaw == "todo" || task.statusRaw == "inProgress"
        }
        
        let sortDescriptors: [SortDescriptor<VaultTask>] = [
            SortDescriptor(\.priority, order: .reverse),
            SortDescriptor(\.createdAt, order: .reverse)
        ]
        
        _pendingTasks = Query(filter: filter, sort: sortDescriptors)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    Text("Welcome home, Ghislain")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // MARK: - Important Tasks Block
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Top Priorities", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            Spacer()
                            Button("See All") {
                                appNavigator.selectedTab = .tasks
                            }
                            .font(.subheadline)
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                        }
                        
                        if pendingTasks.isEmpty {
                            Text("All caught up!")
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(pendingTasks.prefix(3)) { task in
                                TaskRowView(task: task) {
                                    toggleTask(task)
                                }
                                .onTapGesture {
                                    appNavigator.selectedTab = .tasks
                                }
                            }
                        }
                        
                        
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
    
    

}
