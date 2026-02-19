import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.clockIn, order: .reverse) private var allEntries: [TimeEntry]
    @Query(filter: #Predicate<Project> { !$0.isArchived }, sort: \Project.name) private var activeProjects: [Project]
    @State private var showingAddSheet = false
    @State private var selectedDate = Date()
    @State private var clockInProject: Project?
    @State private var showingProjectPicker = false
    
    private var entriesForSelectedDate: [TimeEntry] {
        allEntries.filter { $0.clockIn.isSameDay(as: selectedDate) }
            .sorted { $0.clockIn < $1.clockIn }
    }
    
    private var activeEntry: TimeEntry? {
        allEntries.first { $0.isActive }
    }
    
    private var totalForDay: TimeInterval {
        entriesForSelectedDate.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Quick clock section
                Section {
                    if let active = activeEntry {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("Clocked in")
                                        .font(.headline)
                                    if let project = active.project {
                                        ProjectBadge(project: project)
                                    }
                                }
                                Text("since \(active.clockIn.shortTime)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Clock Out") {
                                active.clockOut = .now
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    } else {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Not clocked in")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Clock In") {
                                    let entry = TimeEntry(project: clockInProject)
                                    modelContext.insert(entry)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                            
                            if !activeProjects.isEmpty {
                                HStack {
                                    Text("Project:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ProjectChip(name: "General", color: .gray, isSelected: clockInProject == nil) {
                                                clockInProject = nil
                                            }
                                            ForEach(activeProjects) { project in
                                                ProjectChip(name: project.name, color: project.color, isSelected: clockInProject?.persistentModelID == project.persistentModelID) {
                                                    clockInProject = project
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Date picker
                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                
                // Day total
                Section {
                    HStack {
                        Text("Day Total")
                            .font(.headline)
                        Spacer()
                        Text(totalForDay.hoursMinutes)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                            .contentTransition(.numericText())
                    }
                }
                
                // Entries
                Section("Entries") {
                    if entriesForSelectedDate.isEmpty {
                        Text("No entries for this day")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(entriesForSelectedDate) { entry in
                            EntryRow(entry: entry)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("FlexTime")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEntryView(initialDate: selectedDate)
            }
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        let entries = entriesForSelectedDate
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}

// MARK: - Project UI Components

struct ProjectBadge: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(project.color)
                .frame(width: 8, height: 8)
            Text(project.name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(project.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct ProjectChip: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .clipShape(Capsule())
            .overlay {
                if isSelected {
                    Capsule()
                        .strokeBorder(color, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct EntryRow: View {
    @Bindable var entry: TimeEntry
    @State private var showingEdit = false
    
    var body: some View {
        Button {
            showingEdit = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text(entry.clockIn.shortTime)
                                .fontWeight(.medium)
                            if let out = entry.clockOut {
                                Text("→")
                                    .foregroundStyle(.secondary)
                                Text(out.shortTime)
                                    .fontWeight(.medium)
                            } else {
                                Text("→ now")
                                    .foregroundStyle(.green)
                            }
                        }
                        if let project = entry.project {
                            ProjectBadge(project: project)
                        }
                    }
                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(entry.durationFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(.primary)
        .sheet(isPresented: $showingEdit) {
            EditEntryView(entry: entry)
        }
    }
}
