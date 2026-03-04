import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Project> { !$0.isArchived }, sort: \Project.name) private var activeProjects: [Project]
    
    var initialDate: Date
    
    @State private var clockIn: Date
    @State private var clockOut: Date
    @State private var note: String = ""
    @State private var hasClockOut = true
    @State private var selectedProject: Project?
    
    init(initialDate: Date) {
        self.initialDate = initialDate
        let cal = Calendar.current
        let noon = cal.date(bySettingHour: 9, minute: 0, second: 0, of: initialDate) ?? initialDate
        let afternoon = cal.date(bySettingHour: 17, minute: 0, second: 0, of: initialDate) ?? initialDate
        _clockIn = State(initialValue: noon)
        _clockOut = State(initialValue: afternoon)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if !activeProjects.isEmpty {
                    Section("Project") {
                        Picker("Project", selection: $selectedProject) {
                            Text("General (no project)").tag(nil as Project?)
                            ForEach(activeProjects) { project in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(project.color)
                                        .frame(width: 10, height: 10)
                                    Text(project.name)
                                }
                                .tag(project as Project?)
                            }
                        }
                    }
                }
                
                Section("Clock In") {
                    DatePicker("Time", selection: $clockIn)
                }
                
                Section("Clock Out") {
                    Toggle("Has clock out", isOn: $hasClockOut)
                    if hasClockOut {
                        DatePicker("Time", selection: $clockOut)
                    }
                }
                
                Section("Note") {
                    TextField("e.g., Lunch break, WFH...", text: $note)
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = TimeEntry(
                            clockIn: clockIn,
                            clockOut: hasClockOut ? clockOut : nil,
                            note: note,
                            project: selectedProject
                        )
                        modelContext.insert(entry)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
