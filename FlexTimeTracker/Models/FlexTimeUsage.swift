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
        if hours == Double(Int(hours)) {
            return "\(Int(hours))h"
        }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
