import SwiftUI
import SwiftData

struct WeekView: View {
    @Query(sort: \TimeEntry.clockIn) private var allEntries: [TimeEntry]
    @State private var weekOffset: Int = 0
    
    private var weekStart: Date {
        let today = Date()
        let start = today.startOfWeek
        return Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: start) ?? start
    }
    
    private var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }
    
    private var weekEntries: [TimeEntry] {
        let end = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        return allEntries.filter { $0.clockIn >= weekStart && $0.clockIn < end }
    }
    
    private var totalWeekSeconds: TimeInterval {
        weekEntries.reduce(0) { $0 + $1.duration }
    }
    
    private var targetSeconds: TimeInterval {
        AppSettings.weeklyTargetHours * 3600
    }
    
    private var remainingSeconds: TimeInterval {
        targetSeconds - totalWeekSeconds
    }
    
    private var daysInWeek: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) }
    }
    
    private func entriesFor(day: Date) -> [TimeEntry] {
        weekEntries.filter { $0.clockIn.isSameDay(as: day) }
    }
    
    private func totalFor(day: Date) -> TimeInterval {
        entriesFor(day: day).reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Week summary card
                Section {
                    VStack(spacing: 16) {
                        // Progress ring
                        let progress = min(totalWeekSeconds / targetSeconds, 1.0)
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    remainingSeconds <= 0 ? Color.green : Color.blue,
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: progress)
                            
                            VStack(spacing: 2) {
                                Text(totalWeekSeconds.hoursMinutes)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                Text("of \(String(format: "%.0f", AppSettings.weeklyTargetHours))h")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 140)
                        .padding(.top, 8)
                        
                        // Stats row
                        HStack(spacing: 0) {
                            StatBox(
                                title: "Worked",
                                value: totalWeekSeconds.hoursMinutes,
                                color: .blue
                            )
                            Divider().frame(height: 30)
                            StatBox(
                                title: remainingSeconds > 0 ? "Remaining" : "Overtime",
                                value: abs(remainingSeconds).hoursMinutes,
                                color: remainingSeconds > 0 ? .orange : .green
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Daily breakdown
                Section("Daily Breakdown") {
                    ForEach(daysInWeek, id: \.self) { day in
                        let dayTotal = totalFor(day: day)
                        let isToday = day.isSameDay(as: Date())
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text(day.dayName)
                                    .font(.headline)
                                    .foregroundStyle(isToday ? .blue : .primary)
                                Text(day.shortDate)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if dayTotal > 0 {
                                // Mini bar
                                let barWidth = min(CGFloat(dayTotal / (8 * 3600)) * 60, 60)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(isToday ? Color.blue : Color.blue.opacity(0.6))
                                    .frame(width: max(barWidth, 4), height: 8)
                                
                                Text(dayTotal.hoursMinutes)
                                    .font(.subheadline)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .frame(width: 70, alignment: .trailing)
                            } else {
                                Text("—")
                                    .foregroundStyle(.quaternary)
                                    .frame(width: 70, alignment: .trailing)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Week Summary")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        weekOffset -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if weekOffset != 0 {
                            Button("Today") {
                                weekOffset = 0
                            }
                            .font(.caption)
                        }
                        Button {
                            weekOffset += 1
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(weekOffset >= 0)
                    }
                }
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
