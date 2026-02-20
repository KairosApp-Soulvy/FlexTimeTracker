import SwiftUI
import SwiftData

struct FlexBalanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.clockIn) private var allEntries: [TimeEntry]
    @Query(sort: \FlexTimeUsage.date, order: .reverse) private var allUsages: [FlexTimeUsage]
    @Query(sort: \FlexBank.earnedDate) private var allBanks: [FlexBank]
    @Query(sort: \Project.name) private var allProjects: [Project]
    @State private var showingAddUsage = false
    @State private var needsSync = false
    
    private var policy: ExpirationPolicy { ExpirationPolicy.current }
    
    // MARK: - Computed Bank State
    
    /// Active (non-expired, non-empty) bank entries, oldest first
    private var activeBanks: [FlexBank] {
        allBanks.filter { !$0.isFullyUsed && !$0.isExpired(policy: policy) }
    }
    
    /// Total available balance
    private var availableSeconds: TimeInterval {
        activeBanks.reduce(0) { $0 + ($1.remainingHours * 3600) }
    }
    
    /// Total ever earned (including expired/used)
    private var totalEarnedSeconds: TimeInterval {
        allBanks.reduce(0) { $0 + ($1.originalHours * 3600) }
    }
    
    /// Total used
    private var totalUsedSeconds: TimeInterval {
        allUsages.reduce(0) { $0 + $1.duration }
    }
    
    /// Total expired
    private var expiredSeconds: TimeInterval {
        allBanks
            .filter { $0.isExpired(policy: policy) }
            .reduce(0) { $0 + ($1.remainingHours * 3600) }
    }
    
    private var projectBreakdown: [(name: String, color: Color, seconds: TimeInterval)] {
        let completed = allEntries.filter { $0.clockOut != nil }
        var results: [(name: String, color: Color, seconds: TimeInterval)] = []
        
        let withProject = Dictionary(grouping: completed.filter { $0.project != nil }) { $0.project!.persistentModelID }
        let withoutProject = completed.filter { $0.project == nil }
        
        if !withoutProject.isEmpty {
            let total = withoutProject.reduce(0) { $0 + $1.duration }
            results.append(("General", .gray, total))
        }
        
        for project in allProjects {
            if let entries = withProject[project.persistentModelID] {
                let total = entries.reduce(0) { $0 + $1.duration }
                results.append((project.name, project.color, total))
            }
        }
        
        return results.sorted { $0.seconds > $1.seconds }
    }
    
    /// Banks expiring within 14 days
    private var expiringSoon: [(FlexBank, Int)] {
        activeBanks.compactMap { bank in
            guard let days = bank.daysUntilExpiration(policy: policy),
                  days <= 14 else { return nil }
            return (bank, days)
        }
    }
    
    /// Total hours expiring within 14 days
    private var expiringSoonHours: Double {
        expiringSoon.reduce(0) { $0 + $1.0.remainingHours }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Expiring soon warning
                if !expiringSoon.isEmpty {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                let hours = String(format: "%.1f", expiringSoonHours)
                                Text("\(hours)h expiring soon")
                                    .font(.headline)
                                
                                let soonest = expiringSoon.map(\.1).min() ?? 0
                                Text(soonest <= 1 ? "Expires tomorrow!" : "Earliest in \(soonest) days")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Use Now") {
                                showingAddUsage = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Balance card
                Section {
                    VStack(spacing: 16) {
                        Text("Available FlexTime")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(availableSeconds.hoursMinutes)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(availableSeconds > 0 ? .green : (availableSeconds < 0 ? .red : .secondary))
                            .monospacedDigit()
                        
                        HStack(spacing: 20) {
                            StatColumn(value: totalEarnedSeconds.hoursMinutes, label: "Earned", color: .blue)
                            
                            Rectangle()
                                .fill(.quaternary)
                                .frame(width: 1, height: 30)
                            
                            StatColumn(value: totalUsedSeconds.hoursMinutes, label: "Used", color: .orange)
                            
                            if expiredSeconds > 0 {
                                Rectangle()
                                    .fill(.quaternary)
                                    .frame(width: 1, height: 30)
                                
                                StatColumn(value: expiredSeconds.hoursMinutes, label: "Expired", color: .red)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                
                // Per-project breakdown (only show when there's actual data with multiple sources)
                if projectBreakdown.count > 1 || (projectBreakdown.count == 1 && projectBreakdown[0].name != "General") {
                    Section {
                        ForEach(projectBreakdown, id: \.name) { item in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)
                                Text(item.name)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(item.seconds.hoursMinutes)
                                    .font(.subheadline)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        HStack {
                            Text("By Project")
                            Spacer()
                            NavigationLink {
                                ProjectsView()
                            } label: {
                                Text("Manage")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Banked overtime breakdown
                if !activeBanks.isEmpty {
                    Section {
                        ForEach(activeBanks) { bank in
                            BankRow(bank: bank, policy: policy)
                        }
                    } header: {
                        Text("Banked Overtime")
                    } footer: {
                        if policy != .never {
                            Text("Oldest time is used first (FIFO). \(policy.description).")
                        }
                    }
                }
                
                // Usage history
                Section {
                    if allUsages.isEmpty {
                        Text("No FlexTime used yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(allUsages) { usage in
                            UsageRow(usage: usage)
                        }
                        .onDelete(perform: deleteUsages)
                    }
                } header: {
                    Text("Usage History")
                }
            }
            .navigationTitle("FlexTime")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddUsage = true
                    } label: {
                        Label("Use FlexTime", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddUsage) {
                AddFlexUsageView()
            }
            .onAppear {
                syncBanksFromEntries()
                // Only schedule if permission already granted — don't prompt here
                ExpirationNotificationService.scheduleExpirationAlerts(banks: allBanks, policy: policy)
            }
        }
    }
    
    // MARK: - Sync
    
    /// Build/update FlexBank entries from TimeEntry overtime data
    private func syncBanksFromEntries() {
        let targetPerWeek = AppSettings.weeklyTargetHours * 3600
        let completedEntries = allEntries.filter { $0.clockOut != nil }
        
        // Group entries by week
        var weekTotals: [Date: TimeInterval] = [:]
        for entry in completedEntries {
            let weekStart = entry.clockIn.startOfWeek
            weekTotals[weekStart, default: 0] += entry.duration
        }
        
        // Current week start
        let currentWeekStart = Date().startOfWeek
        
        // Get existing bank week starts for quick lookup
        let existingWeeks = Set(allBanks.map { $0.weekStart.startOfDay })
        
        for (weekStart, total) in weekTotals {
            let overtime = total - targetPerWeek
            guard overtime > 0 else { continue }
            
            let overtimeHours = overtime / 3600.0
            let weekStartDay = weekStart.startOfDay
            
            if existingWeeks.contains(weekStartDay) {
                // Update existing bank
                if let bank = allBanks.first(where: { $0.weekStart.startOfDay == weekStartDay }) {
                    let usedHours = bank.originalHours - bank.remainingHours
                    bank.originalHours = overtimeHours
                    bank.remainingHours = max(0, overtimeHours - usedHours)
                }
            } else {
                // Create new bank entry
                let earnedDate = weekStart < currentWeekStart
                    ? Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
                    : Date()
                let bank = FlexBank(weekStart: weekStart, earnedDate: earnedDate, originalHours: overtimeHours)
                modelContext.insert(bank)
            }
        }
        
        try? modelContext.save()
    }
    
    private func deleteUsages(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(allUsages[index])
        }
        // Re-sync after deleting usage (to restore bank balances)
        // This is simplified — in production you'd track which bank each usage drew from
    }
}

// MARK: - Subviews

struct StatColumn: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct BankRow: View {
    let bank: FlexBank
    let policy: ExpirationPolicy
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Week of \(bank.weekStart.shortDate)")
                    .fontWeight(.medium)
                
                if let days = bank.daysUntilExpiration(policy: policy) {
                    Text(days <= 1 ? "Expires tomorrow" : "Expires in \(days) days")
                        .font(.caption)
                        .foregroundStyle(days <= 7 ? .orange : .secondary)
                } else if policy == .never {
                    Text("No expiration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(bank.remainingFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .monospacedDigit()
                
                if bank.remainingHours < bank.originalHours {
                    let orig = String(format: "%.1fh", bank.originalHours)
                    Text("of \(orig)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct UsageRow: View {
    let usage: FlexTimeUsage
    @State private var showingEdit = false
    
    var body: some View {
        Button {
            showingEdit = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(usage.date.shortDate)
                        .fontWeight(.medium)
                    if !usage.note.isEmpty {
                        Text(usage.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("-\(usage.hoursFormatted)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(.primary)
        .sheet(isPresented: $showingEdit) {
            EditFlexUsageView(usage: usage)
        }
    }
}
