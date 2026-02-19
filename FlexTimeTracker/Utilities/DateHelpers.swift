import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var startOfWeek: Date {
        let cal = Calendar.current
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: components) ?? self
    }
    
    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek) ?? self
    }
    
    var shortDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }
    
    var shortTime: String {
        formatted(date: .omitted, time: .shortened)
    }
    
    var dayName: String {
        formatted(.dateTime.weekday(.abbreviated))
    }
    
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

extension TimeInterval {
    var hoursMinutes: String {
        let totalMinutes = Int(self) / 60
        let h = totalMinutes / 60
        let m = abs(totalMinutes % 60)
        if self < 0 {
            return String(format: "-%dh %02dm", abs(h), m)
        }
        return String(format: "%dh %02dm", h, m)
    }
    
    var hours: Double {
        self / 3600.0
    }
}
