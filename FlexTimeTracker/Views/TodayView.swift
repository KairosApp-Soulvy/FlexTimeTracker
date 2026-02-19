import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.clockIn, order: .reverse) private var allEntries: [TimeEntry]
    @State private var showingAddSheet = false
    @State private var selectedDate = Date()
    
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
                                Text("Clocked in")
                                    .font(.headline)
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
                        HStack {
                            Text("Not clocked in")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Clock In") {
                                let entry = TimeEntry()
                                modelContext.insert(entry)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
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

struct EntryRow: View {
    @Bindable var entry: TimeEntry
    @State private var showingEdit = false
    
    var body: some View {
        Button {
            showingEdit = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
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
