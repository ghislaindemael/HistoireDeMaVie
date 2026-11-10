import SwiftUI

struct FoodDetailsEditView: View {
    @Binding var metadata: LogDetails?
    
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
                    metadata = LogDetails()
                }
                metadata?.food = newFoodDetails
            }
        )
    }
    
    private var activeCourses: [CourseType] {
        let details = foodDetailsBinding.wrappedValue
        let items = details.consumedItems
        let filledCourses = Set(items.compactMap { $0.course })
        let coursesWithNotes = Set(CourseType.allCases.filter { details.note(for: $0) != nil })
        return CourseType.allCases.filter { filledCourses.contains($0) || emptyCourses.contains($0) || coursesWithNotes.contains($0) }
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
                    let courseNote = foodDetailsBinding.wrappedValue.note(for: course)
                    
                    Button {
                        selectedCourseToEdit = course
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(course.rawValue)
                                    .foregroundColor(.primary)
                                
                                if let courseNote = courseNote, !courseNote.isEmpty {
                                    Text(courseNote)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
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
                            foodDetailsBinding.wrappedValue.setNote(nil, for: course)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            FoodClipboardManager.copy(course: itemsInCourse, note: courseNote)
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
            ), onDismiss: {
                emptyCourses = emptyCourses.filter { course in
                    let hasItems = foodDetailsBinding.wrappedValue.consumedItems.contains { $0.course == course }
                    let hasNote = foodDetailsBinding.wrappedValue.note(for: course) != nil
                    return hasItems || hasNote
                }
            }) { course in
                CourseEditorSheet(
                    course: course,
                    note: Binding(
                        get: { foodDetailsBinding.wrappedValue.note(for: course) },
                        set: { foodDetailsBinding.wrappedValue.setNote($0, for: course) }
                    ),
                    consumedItems: Binding(
                        get: { foodDetailsBinding.wrappedValue.consumedItems },
                        set: { foodDetailsBinding.wrappedValue.consumedItems = $0 }
                    )
                )
            }
            if FoodClipboardManager.hasCourse {
                Button(action: {
                    if let pasted = FoodClipboardManager.getCourseWithNewIDs() {
                        foodDetailsBinding.wrappedValue.consumedItems.append(contentsOf: pasted.items)
                        if let targetCourse = pasted.items.first?.course, let pastedNote = pasted.note {
                            if foodDetailsBinding.wrappedValue.note(for: targetCourse) == nil {
                                foodDetailsBinding.wrappedValue.setNote(pastedNote, for: targetCourse)
                            }
                        }
                    }
                }) {
                    Label("Paste Course", systemImage: "doc.on.clipboard")
                }
            }
        }
    }
}
