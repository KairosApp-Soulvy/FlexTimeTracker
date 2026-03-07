import Foundation
import SwiftData

@Model
final class FlexTimeUsage {
    var date: Date
    var hours: Double
    var note: String
    
    init(date: Date = .now, hours: Double = 1.0, note: String = "") {
        self.date = date
        self.hours = hours
        self.note = note
    }
    
    var duration: TimeInterval {
        hours * 3600
    }
    
    var hoursFormatted: String {
        let clamped = max(0, hours)
        if clamped == Double(Int(clamped)) {
            return "\(Int(clamped))h"
        }
        let h = Int(clamped)
        let m = Int((clamped - Double(h)) * 60)
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
