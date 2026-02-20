import SwiftUI
import SwiftData

@main
struct FlexTimeTrackerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        CrashReporter.shared.install()
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView(isComplete: $hasCompletedOnboarding)
            }
        }
        .modelContainer(for: [TimeEntry.self, FlexTimeUsage.self, FlexBank.self, Project.self])
    }
}
