import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Start of week respecting user's preferred start day
    var startOfWeek: Date {
        var cal = Calendar.current
        cal.firstWeekday = AppSettings.weekStartDay // 1=Sun, 2=Mon
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: components) ?? self
    }
    
    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
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
    
    var compactDate: String {
        formatted(.dateTime.month(.abbreviated).day())
    }
    
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

extension TimeInterval {
    var hoursMinutesSeconds: String {
        let total = max(0, Int(self))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    
    var hoursMinutes: String {
        let totalMinutes = abs(Int(self)) / 60
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        let prefix = self < 0 ? "-" : ""
        return String(format: "%s%dh %02dm", prefix, h, m)
    }
    
    var hours: Double {
        self / 3600.0
    }
}
