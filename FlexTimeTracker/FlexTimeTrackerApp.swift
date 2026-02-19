import SwiftUI
import SwiftData

@main
struct FlexTimeTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TimeEntry.self, FlexTimeUsage.self, FlexBank.self])
    }
}
