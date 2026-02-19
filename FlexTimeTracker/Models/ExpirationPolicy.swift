import Foundation

enum ExpirationPolicy: Codable, Equatable {
    case rolling(days: Int)  // Each chunk expires X days after earned
    case quarterly           // All time resets at end of quarter
    case annualCap           // Resets at end of calendar year
    case never               // No expiration
    
    var displayName: String {
        switch self {
        case .rolling(let days): return "\(days)-day window"
        case .quarterly: return "Quarterly reset"
        case .annualCap: return "Annual reset"
        case .never: return "Never expires"
        }
    }
    
    var description: String {
        switch self {
        case .rolling(let days):
            return "Each chunk of overtime expires \(days) days after it was earned"
        case .quarterly:
            return "All banked time resets at the end of each quarter"
        case .annualCap:
            return "All banked time resets at the end of each calendar year"
        case .never:
            return "Banked time never expires"
        }
    }
    
    // Persistence helpers
    private static let key = "flexExpirationPolicy"
    
    static var current: ExpirationPolicy {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let policy = try? JSONDecoder().decode(ExpirationPolicy.self, from: data)
            else { return .rolling(days: 90) }
            return policy
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }
}
