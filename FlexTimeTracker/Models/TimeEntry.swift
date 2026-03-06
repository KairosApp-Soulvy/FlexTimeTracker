import Foundation
import SwiftData

@Model
final class TimeEntry {
    var clockIn: Date
    var clockOut: Date?
    var note: String
    var project: Project?
    var isManualEntry: Bool
    
    init(clockIn: Date = .now, clockOut: Date? = nil, note: String = "", project: Project? = nil, isManualEntry: Bool = false) {
        self.clockIn = clockIn
        self.clockOut = clockOut
        self.note = note
        self.project = project
        self.isManualEntry = isManualEntry
    }
    
    var duration: TimeInterval {
        guard let clockOut else { return max(0, Date.now.timeIntervalSince(clockIn)) }
        return max(0, clockOut.timeIntervalSince(clockIn))
    }
    
    var isActive: Bool {
        clockOut == nil
    }
    
    var durationFormatted: String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
}
