import SwiftUI

struct SettingsView: View {
    @State private var weeklyTarget: Double = AppSettings.weeklyTargetHours
    @State private var weekStartDay: Int = AppSettings.weekStartDay
    @State private var policyType: PolicyType = SettingsView.currentPolicyType()
    @State private var rollingDays: Int = SettingsView.currentRollingDays()
    @State private var notificationsEnabled: Bool = UserDefaults.standard.object(forKey: "flexExpirationReminders") == nil ? true : UserDefaults.standard.bool(forKey: "flexExpirationReminders")
    
    enum PolicyType: String, CaseIterable {
        case rolling = "Rolling Window"
        case quarterly = "Quarterly Reset"
        case annual = "Annual Reset"
        case never = "Never Expires"
    }
    
    private let weekDays = [
        (2, "Monday"),
        (1, "Sunday"),
        (7, "Saturday"),
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Hours with stepper for precision
                    HStack {
                        Text("Hours per week")
                        Spacer()
                        Text("\(String(format: "%.1f", weeklyTarget))h")
                            .foregroundStyle(.blue)
                            .monospacedDigit()
                    }
                    Stepper("", value: $weeklyTarget, in: 10...80, step: 0.5)
                        .labelsHidden()
                        .onChange(of: weeklyTarget) { _, newValue in
                            AppSettings.weeklyTargetHours = newValue
                        }
                    
                    // Common presets
                    HStack(spacing: 8) {
                        ForEach([35.0, 37.5, 40.0, 45.0], id: \.self) { hours in
                            Button(hours == 37.5 ? "37.5h" : "\(Int(hours))h") {
                                weeklyTarget = hours
                                AppSettings.weeklyTargetHours = hours
                            }
                            .buttonStyle(.bordered)
                            .tint(weeklyTarget == hours ? .blue : .secondary)
                            .controlSize(.small)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Picker("Week starts on", selection: $weekStartDay) {
                        ForEach(weekDays, id: \.0) { day in
                            Text(day.1).tag(day.0)
                        }
                    }
                    .onChange(of: weekStartDay) { _, newValue in
                        AppSettings.weekStartDay = newValue
                    }
                } header: {
                    Text("Work Schedule")
                }
                
                Section {
                    Picker("Policy", selection: $policyType) {
                        ForEach(PolicyType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: policyType) { _, _ in savePolicy() }
                    
                    if policyType == .rolling {
                        Stepper(value: $rollingDays, in: 7...365, step: 1) {
                            HStack {
                                Text("Expires after")
                                Spacer()
                                Text("\(rollingDays) days")
                                    .foregroundStyle(.blue)
                                    .monospacedDigit()
                            }
                        }
                        .onChange(of: rollingDays) { _, _ in savePolicy() }
                        
                        // Quick presets
                        HStack(spacing: 8) {
                            ForEach([30, 60, 90, 120], id: \.self) { days in
                                Button("\(days)d") {
                                    rollingDays = days
                                    savePolicy()
                                }
                                .buttonStyle(.bordered)
                                .tint(rollingDays == days ? .blue : .secondary)
                                .controlSize(.small)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("Expiration Policy")
                } footer: {
                    Text(currentPolicy.description)
                }
                
                Section {
                    Toggle("Expiration Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "flexExpirationReminders")
                            if newValue {
                                ExpirationNotificationService.requestPermission()
                            }
                        }
                    
                    if notificationsEnabled {
                        Text("You'll get alerts 7 days and 1 day before flex time expires")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Notifications")
                }
                
                Section {
                    NavigationLink("Manage Projects") {
                        ProjectsView()
                    }
                } header: {
                    Text("Projects")
                } footer: {
                    Text("Group time entries by project, shoot, or client.")
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.2.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Storage")
                        Spacer()
                        Text("Local only")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private var currentPolicy: ExpirationPolicy {
        switch policyType {
        case .rolling: return .rolling(days: rollingDays)
        case .quarterly: return .quarterly
        case .annual: return .annualCap
        case .never: return .never
        }
    }
    
    private func savePolicy() {
        ExpirationPolicy.current = currentPolicy
    }
    
    private static func currentPolicyType() -> PolicyType {
        switch ExpirationPolicy.current {
        case .rolling: return .rolling
        case .quarterly: return .quarterly
        case .annualCap: return .annual
        case .never: return .never
        }
    }
    
    private static func currentRollingDays() -> Int {
        if case .rolling(let days) = ExpirationPolicy.current {
            return days
        }
        return 90
    }
}
