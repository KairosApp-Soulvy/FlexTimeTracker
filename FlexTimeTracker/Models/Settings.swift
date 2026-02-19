import Foundation

enum SettingsKeys {
    static let weeklyTarget = "weeklyTargetHours"
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
}
