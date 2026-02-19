import SwiftUI
import SwiftData

struct EditFlexUsageView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var usage: FlexTimeUsage
    
    @State private var date: Date
    @State private var hours: Double
    @State private var note: String
    
    init(usage: FlexTimeUsage) {
        self.usage = usage
        _date = State(initialValue: usage.date)
        _hours = State(initialValue: usage.hours)
        _note = State(initialValue: usage.note)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Hours") {
                    HStack {
                        Text("Hours")
                        Spacer()
                        Text(String(format: "%.1f", hours))
                            .monospacedDigit()
                            .foregroundStyle(.blue)
                    }
                    Slider(value: $hours, in: 0.5...12, step: 0.5)
                        .tint(.blue)
                }
                
                Section("Note") {
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("Edit Usage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        usage.date = date
                        usage.hours = hours
                        usage.note = note
                        dismiss()
                    }
                }
            }
        }
    }
}
