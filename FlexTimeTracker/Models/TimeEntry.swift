import Foundation
import SwiftData

@Model
final class TimeEntry {
    var clockIn: Date
    var clockOut: Date?
    var note: String
    var project: Project?
    
    init(clockIn: Date = .now, clockOut: Date? = nil, note: String = "", project: Project? = nil) {
        self.clockIn = clockIn
        self.clockOut = clockOut
        self.note = note
        self.project = project
    }
    
    var duration: TimeInterval {
        guard let clockOut else { return Date.now.timeIntervalSince(clockIn) }
        return clockOut.timeIntervalSince(clockIn)
    }
    
    var isActive: Bool {
        clockOut == nil
    }
    
    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
}
