import Foundation

enum SettingsKeys {
    static let weeklyTarget = "weeklyTargetHours"
    static let weekStartDay = "weekStartDay"
}

struct AppSettings {
    static var weeklyTargetHours: Double {
        get {
            let val = UserDefaults.standard.double(forKey: SettingsKeys.weeklyTarget)
            return val > 0 ? val : 40.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsKeys.weeklyTarget)
        }
    }
    
    /// 1 = Sunday, 2 = Monday, 7 = Saturday
    static var weekStartDay: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: SettingsKeys.weekStartDay)
            return val > 0 ? val : 2 // Default Monday
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsKeys.weekStartDay)
        }
    }
    
    static var weekStartDayName: String {
        switch weekStartDay {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Monday"
        }
    }
}
