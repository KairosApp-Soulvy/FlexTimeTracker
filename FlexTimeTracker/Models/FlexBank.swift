import Foundation
import SwiftData

/// Represents a chunk of banked overtime from a specific week
@Model
final class FlexBank {
    /// The start of the week this overtime was earned
    var weekStart: Date
    /// When this overtime was "locked in" (end of that week)
    var earnedDate: Date
    /// Original overtime hours banked
    var originalHours: Double
    /// Hours remaining after usage (FIFO draws from oldest first)
    var remainingHours: Double
    
    init(weekStart: Date, earnedDate: Date, originalHours: Double) {
        self.weekStart = weekStart
        self.earnedDate = earnedDate
        self.originalHours = originalHours
        self.remainingHours = originalHours
    }
    
    /// Whether this bank entry has been fully consumed
    var isFullyUsed: Bool {
        remainingHours <= 0.001
    }
    
    /// Expiration date based on a rolling day policy (nil if never expires)
    func expirationDate(policy: ExpirationPolicy) -> Date? {
        switch policy {
        case .rolling(let days):
            return Calendar.current.date(byAdding: .day, value: days, to: earnedDate)
        case .quarterly:
            // End of the quarter containing earnedDate
            let cal = Calendar.current
            let month = cal.component(.month, from: earnedDate)
            let quarterEnd: Int
            switch month {
            case 1...3: quarterEnd = 3
            case 4...6: quarterEnd = 6
            case 7...9: quarterEnd = 9
            default: quarterEnd = 12
            }
            var comps = cal.dateComponents([.year], from: earnedDate)
            comps.month = quarterEnd + 1
            comps.day = 1
            return cal.date(from: comps)
        case .annualCap:
            // End of calendar year
            let cal = Calendar.current
            var comps = cal.dateComponents([.year], from: earnedDate)
            comps.year = (comps.year ?? 2026) + 1
            comps.month = 1
            comps.day = 1
            return cal.date(from: comps)
        case .never:
            return nil
        }
    }
    
    /// Whether this bank entry has expired
    func isExpired(policy: ExpirationPolicy) -> Bool {
        guard let exp = expirationDate(policy: policy) else { return false }
        return Date() >= exp
    }
    
    /// Days until expiration (nil if never expires or already expired)
    func daysUntilExpiration(policy: ExpirationPolicy) -> Int? {
        guard let exp = expirationDate(policy: policy) else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: exp).day ?? 0
        return max(0, days)
    }
    
    var remainingFormatted: String {
        if remainingHours == Double(Int(remainingHours)) {
            return "\(Int(remainingHours))h"
        }
        let h = Int(remainingHours)
        let m = Int((remainingHours - Double(h)) * 60)
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
