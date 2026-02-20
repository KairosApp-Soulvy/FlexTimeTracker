import SwiftUI
import SwiftData

struct EditEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: TimeEntry
    @Query(filter: #Predicate<Project> { !$0.isArchived }, sort: \Project.name) private var activeProjects: [Project]
    
    @State private var clockIn: Date
    @State private var clockOut: Date
    @State private var hasClockOut: Bool
    @State private var note: String
    @State private var selectedProject: Project?
    @State private var showingDeleteConfirm = false
    
    init(entry: TimeEntry) {
        self.entry = entry
        _clockIn = State(initialValue: entry.clockIn)
        _clockOut = State(initialValue: entry.clockOut ?? Date())
        _hasClockOut = State(initialValue: entry.clockOut != nil)
        _note = State(initialValue: entry.note)
        _selectedProject = State(initialValue: entry.project)
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
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Entry", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.clockIn = clockIn
                        entry.clockOut = hasClockOut ? clockOut : nil
                        entry.note = note
                        entry.project = selectedProject
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Delete this entry?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(entry)
                    dismiss()
                }
            }
        }
    }
}
