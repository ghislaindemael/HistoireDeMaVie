import SwiftUI

struct FoodDetailsEditView: View {
    @Binding var metadata: ActivityDetails?
    
    @State private var showingAddCourse = false
    @State private var emptyCourses: Set<CourseType> = []
    
    @State private var selectedCourseToEdit: CourseType? = nil
    
    private var foodDetailsBinding: Binding<FoodDetails> {
        Binding<FoodDetails>(
            get: {
                return metadata?.food ?? FoodDetails()
            },
            set: { newFoodDetails in
                if metadata == nil {
                    metadata = ActivityDetails()
                }
                metadata?.food = newFoodDetails
            }
        )
    }
    
    private var activeCourses: [CourseType] {
        let items = foodDetailsBinding.wrappedValue.consumedItems
        let filledCourses = Set(items.compactMap { $0.course })
        return CourseType.allCases.filter { filledCourses.contains($0) || emptyCourses.contains($0) }
    }
    
    var body: some View {
        Section("General Notes") {
            TextField("Meal notes, restaurant name...", text: Binding(
                get: { foodDetailsBinding.wrappedValue.generalNotes ?? "" },
                set: { foodDetailsBinding.wrappedValue.generalNotes = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(1...3)
        }
        
        Section("Courses") {
            if !activeCourses.isEmpty {
                ForEach(activeCourses) { course in
                    let itemsInCourse = foodDetailsBinding.wrappedValue.consumedItems.filter { $0.course == course }
                    
                    Button {
                        selectedCourseToEdit = course
                    } label: {
                        HStack {
                            Text(course.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(itemsInCourse.count) items")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .imageScale(.small)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            emptyCourses.remove(course)
                            foodDetailsBinding.wrappedValue.consumedItems.removeAll { $0.course == course }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            FoodClipboardManager.copy(course: itemsInCourse)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .tint(.blue)
                    }
                }
            }
            
            Button(action: { showingAddCourse = true }) {
                Label("Add Course", systemImage: "plus.rectangle.on.folder")
            }
            .confirmationDialog("Add Course", isPresented: $showingAddCourse) {
                ForEach(CourseType.allCases) { course in
                    if !activeCourses.contains(course) {
                        Button(course.rawValue) {
                            emptyCourses.insert(course)
                            // Wait slightly to let the dialog dismiss cleanly
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedCourseToEdit = course
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: Binding<CourseType?>(
                get: { selectedCourseToEdit },
                set: { selectedCourseToEdit = $0 }
            )) { course in
                CourseEditorSheet(course: course, consumedItems: Binding(
                    get: { foodDetailsBinding.wrappedValue.consumedItems },
                    set: { foodDetailsBinding.wrappedValue.consumedItems = $0 }
                ))
            }
            if FoodClipboardManager.hasCourse {
                Button(action: {
                    if let pastedItems = FoodClipboardManager.getCourseWithNewIDs() {
                        foodDetailsBinding.wrappedValue.consumedItems.append(contentsOf: pastedItems)
                    }
                }) {
                    Label("Paste Course", systemImage: "doc.on.clipboard")
                }
            }
        }
    }
}
