import SwiftUI

struct SettingsView: View {
    @State private var weeklyTarget: Double = AppSettings.weeklyTargetHours
    @State private var policyType: PolicyType = SettingsView.currentPolicyType()
    @State private var rollingDays: Int = SettingsView.currentRollingDays()
    
    enum PolicyType: String, CaseIterable {
        case rolling = "Rolling Window"
        case quarterly = "Quarterly Reset"
        case annual = "Annual Reset"
        case never = "Never Expires"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Weekly Target") {
                    HStack {
                        Text("Hours per week")
                        Spacer()
                        Text("\(String(format: "%.1f", weeklyTarget))h")
                            .foregroundStyle(.blue)
                            .monospacedDigit()
                    }
                    Slider(value: $weeklyTarget, in: 10...60, step: 0.5)
                        .onChange(of: weeklyTarget) { _, newValue in
                            AppSettings.weeklyTargetHours = newValue
                        }
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
                    Toggle("Expiration Reminders", isOn: .init(
                        get: { UserDefaults.standard.bool(forKey: "flexExpirationReminders") != false },
                        set: {
                            UserDefaults.standard.set($0, forKey: "flexExpirationReminders")
                            if $0 {
                                ExpirationNotificationService.requestPermission()
                            }
                        }
                    ))
                    
                    if UserDefaults.standard.bool(forKey: "flexExpirationReminders") != false {
                        Text("You'll get alerts 7 days and 1 day before flex time expires")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Notifications")
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1.0")
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
