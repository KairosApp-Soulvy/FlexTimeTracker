import SwiftUI
import SwiftData

struct AddFlexUsageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    @State private var hours: Double = 1.0
    @State private var useFullDay = false
    @State private var note: String = ""
    
    private var dailyHours: Double {
        AppSettings.weeklyTargetHours / 5.0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("How Much") {
                    Toggle("Full day (\(String(format: "%.0f", dailyHours))h)", isOn: $useFullDay)
                    
                    if !useFullDay {
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
                }
                
                Section("Note") {
                    TextField("e.g., Doctor appointment, personal day...", text: $note)
                }
            }
            .navigationTitle("Use FlexTime")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let usage = FlexTimeUsage(
                            date: date,
                            hours: useFullDay ? dailyHours : hours,
                            note: note
                        )
                        modelContext.insert(usage)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
