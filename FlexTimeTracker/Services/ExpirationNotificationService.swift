import Foundation
import UserNotifications

struct ExpirationNotificationService {
    
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
    
    /// Schedule notifications for expiring flex bank entries
    static func scheduleExpirationAlerts(banks: [FlexBank], policy: ExpirationPolicy) {
        let center = UNUserNotificationCenter.current()
        // Remove old expiration notifications
        center.removePendingNotificationRequests(withIdentifiers: ["flex-expire-7d", "flex-expire-1d"])
        
        guard policy != .never else { return }
        
        let activeBanks = banks.filter { !$0.isFullyUsed && !$0.isExpired(policy: policy) }
        
        // Find the next chunk to expire
        let sorted = activeBanks
            .compactMap { bank -> (FlexBank, Date)? in
                guard let exp = bank.expirationDate(policy: policy) else { return nil }
                return (bank, exp)
            }
            .sorted { $0.1 < $1.1 }
        
        guard let (nextBank, nextExpiry) = sorted.first else { return }
        
        // 7-day warning
        if let sevenBefore = Calendar.current.date(byAdding: .day, value: -7, to: nextExpiry),
           sevenBefore > Date() {
            let content = UNMutableNotificationContent()
            content.title = "FlexTime Expiring Soon"
            content.body = "\(nextBank.remainingFormatted) of flex time expires in 7 days. Use it or lose it!"
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: sevenBefore),
                repeats: false
            )
            center.add(UNNotificationRequest(identifier: "flex-expire-7d", content: content, trigger: trigger))
        }
        
        // 1-day warning
        if let oneBefore = Calendar.current.date(byAdding: .day, value: -1, to: nextExpiry),
           oneBefore > Date() {
            let content = UNMutableNotificationContent()
            content.title = "⚠️ FlexTime Expires Tomorrow"
            content.body = "\(nextBank.remainingFormatted) expires tomorrow! Take the time off."
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: oneBefore),
                repeats: false
            )
            center.add(UNNotificationRequest(identifier: "flex-expire-1d", content: content, trigger: trigger))
        }
    }
}
