import SwiftUI
import SwiftData

struct QuickAddFlexView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Project> { !$0.isArchived }, sort: \Project.name) private var activeProjects: [Project]
    
    @State private var hours: Double = 8
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var selectedProject: Project?
    
    private let presets: [Double] = [4, 8, 12, 16]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Hours") {
                    HStack(spacing: 10) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                hours = preset
                            } label: {
                                Text("\(Int(preset))h")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(hours == preset ? Color.accentColor : Color(.systemGray5))
                                    .foregroundStyle(hours == preset ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Stepper(value: $hours, in: 0.5...24, step: 0.5) {
                        Text("\(hours, specifier: hours.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f") hours")
                            .monospacedDigit()
                    }
                }
                
                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
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
                
                Section("Note") {
                    TextField("e.g., Weekend travel, On-call Saturday...", text: $note)
                }
            }
            .navigationTitle("Quick Add Flex Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let cal = Calendar.current
                        let startOfDay = cal.startOfDay(for: date)
                        let clockIn = cal.date(bySettingHour: 8, minute: 0, second: 0, of: startOfDay) ?? startOfDay
                        let clockOut = clockIn.addingTimeInterval(hours * 3600)
                        
                        let entry = TimeEntry(
                            clockIn: clockIn,
                            clockOut: clockOut,
                            note: note,
                            project: selectedProject,
                            isManualEntry: true
                        )
                        modelContext.insert(entry)
                        try? modelContext.save()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    }
                }
            }
        }
    }
}
