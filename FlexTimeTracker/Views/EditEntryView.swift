import SwiftUI
import SwiftData

struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: TimeEntry
    
    @State private var clockIn: Date
    @State private var clockOut: Date
    @State private var hasClockOut: Bool
    @State private var note: String
    
    init(entry: TimeEntry) {
        self.entry = entry
        _clockIn = State(initialValue: entry.clockIn)
        _clockOut = State(initialValue: entry.clockOut ?? Date())
        _hasClockOut = State(initialValue: entry.clockOut != nil)
        _note = State(initialValue: entry.note)
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
                        dismiss()
                    }
                }
            }
        }
    }
}
