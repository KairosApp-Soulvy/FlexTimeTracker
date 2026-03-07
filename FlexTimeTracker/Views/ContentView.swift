import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "clock.fill")
                }
                .accessibilityLabel("Today's time entries")
            
            WeekView()
                .tabItem {
                    Label("Week", systemImage: "calendar")
                }
                .accessibilityLabel("Weekly time summary")
            
            FlexBalanceView()
                .tabItem {
                    Label("Balance", systemImage: "banknote")
                }
                .accessibilityLabel("Flex time balance")
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .accessibilityLabel("App settings")
        }
    }
}
