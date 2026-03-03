import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.clockIn, order: .reverse) private var allEntries: [TimeEntry]
    @Query(filter: #Predicate<Project> { !$0.isArchived }, sort: \Project.name) private var activeProjects: [Project]
    @State private var showingAddSheet = false
    @State private var showingQuickAdd = false
    @State private var selectedDate = Date()
    @State private var clockInProject: Project?
    @State private var now = Date()
    
    // Live timer - updates every second when clocked in
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
                // Clock in/out card
                Section {
                    if let active = activeEntry {
                        // CLOCKED IN STATE
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 10, height: 10)
                                            .pulse()
                                        Text("Clocked In")
                                            .font(.headline)
                                            .foregroundStyle(.green)
                                        if let project = active.project {
                                            ProjectBadge(project: project)
                                        }
                                    }
                                    Text("since \(active.clockIn.shortTime)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            
                            // Live timer
                            let elapsed = max(0, now.timeIntervalSince(active.clockIn))
                            Text(elapsed.hoursMinutesSeconds)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                                .accessibilityLabel("Elapsed time: \(elapsed.hoursMinutesSeconds)")
                            
                            Button {
                                withAnimation {
                                    active.clockOut = .now
                                    try? modelContext.save()
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                Text("Clock Out")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .accessibilityLabel("Clock out")
                            .accessibilityHint("Stops the current time entry")
                        }
                        .padding(.vertical, 8)
                    } else {
                        // NOT CLOCKED IN STATE
                        VStack(spacing: 16) {
                            // Project picker (always visible when projects exist)
                            if !activeProjects.isEmpty {
                                HStack(spacing: 8) {
                                    Text("Project")
                                        .font(.subheadline)
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
                            
                            Button {
                                withAnimation {
                                    let entry = TimeEntry(project: clockInProject)
                                    modelContext.insert(entry)
                                    try? modelContext.save()
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                Label("Clock In", systemImage: "play.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .accessibilityLabel("Clock in")
                            .accessibilityHint("Starts tracking a new time entry")
                            
                            Button {
                                showingQuickAdd = true
                            } label: {
                                Label("Quick Add Flex Time", systemImage: "bolt.fill")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .accessibilityLabel("Quick add flex time")
                            .accessibilityHint("Manually add overtime hours")
                        }
                        .padding(.vertical, 8)
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
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .accessibilityLabel("Day total: \(totalForDay.hoursMinutes)")
                    }
                }
                
                // Entries
                Section {
                    if entriesForSelectedDate.isEmpty {
                        VStack(spacing: 6) {
                            Text("No time tracked")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Tap Clock In to start tracking!")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    } else {
                        ForEach(entriesForSelectedDate) { entry in
                            EntryRow(entry: entry, now: now)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                } header: {
                    Text("Entries")
                } footer: {
                    if !entriesForSelectedDate.isEmpty {
                        Text("Swipe left to delete an entry")
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
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddFlexView()
            }
            .onReceive(timer) { _ in
                if activeEntry != nil {
                    now = Date()
                }
            }
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        let entries = entriesForSelectedDate
        for index in offsets where index < entries.count {
            modelContext.delete(entries[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

extension View {
    func pulse() -> some View {
        modifier(PulseModifier())
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
    let now: Date
    
    var body: some View {
        Button {
            showingEdit = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if entry.isManualEntry {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
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
                                    .fontWeight(.medium)
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
                    .foregroundStyle(entry.isActive ? .green : .secondary)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(.primary)
        .sheet(isPresented: $showingEdit) {
            EditEntryView(entry: entry)
        }
    }
}
