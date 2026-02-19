import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    var name: String
    var colorHex: String
    var createdAt: Date
    var isArchived: Bool
    
    @Relationship(inverse: \TimeEntry.project) var entries: [TimeEntry]?
    
    init(name: String, colorHex: String = Project.randomColorHex(), createdAt: Date = .now, isArchived: Bool = false) {
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    var totalSeconds: TimeInterval {
        (entries ?? []).filter { $0.clockOut != nil }.reduce(0) { $0 + $1.duration }
    }
    
    var overtimeSeconds: TimeInterval {
        // Sum of overtime from weeks where this project had entries
        // Simplified: just show total hours for the project
        totalSeconds
    }
    
    static let availableColors: [(name: String, hex: String)] = [
        ("Blue", "007AFF"),
        ("Green", "34C759"),
        ("Orange", "FF9500"),
        ("Red", "FF3B30"),
        ("Purple", "AF52DE"),
        ("Teal", "5AC8FA"),
        ("Pink", "FF2D55"),
        ("Indigo", "5856D6"),
        ("Mint", "00C7BE"),
        ("Yellow", "FFCC00"),
    ]
    
    static func randomColorHex() -> String {
        availableColors.randomElement()?.hex ?? "007AFF"
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
