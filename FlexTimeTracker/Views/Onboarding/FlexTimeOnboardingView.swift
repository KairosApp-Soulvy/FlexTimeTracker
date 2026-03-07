import SwiftUI

// MARK: - Onboarding Data Model

struct OnboardingAnswers {
    var policyType: ExpirationPolicy = .rolling(days: 90)
    var hoursPerPeriod: Double = 40.0
    var flexUsages: Set<FlexUsageReason> = []
    var weekStartDay: Int = 2 // Monday
}

enum FlexUsageReason: String, CaseIterable, Identifiable {
    case appointments = "appointments"
    case family = "family"
    case personal = "personal"
    case mentalHealth = "mentalHealth"
    case errands = "errands"
    case fitness = "fitness"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .appointments: return "Appointments"
        case .family: return "Family Time"
        case .personal: return "Personal Days"
        case .mentalHealth: return "Mental Health"
        case .errands: return "Errands & Tasks"
        case .fitness: return "Fitness & Wellness"
        }
    }
    
    var icon: String {
        switch self {
        case .appointments: return "calendar.badge.clock"
        case .family: return "figure.2.and.child.holdinghands"
        case .personal: return "sun.max.fill"
        case .mentalHealth: return "brain.head.profile"
        case .errands: return "cart.fill"
        case .fitness: return "figure.run"
        }
    }
    
    var color: Color {
        switch self {
        case .appointments: return .blue
        case .family: return .purple
        case .personal: return .orange
        case .mentalHealth: return .teal
        case .errands: return .green
        case .fitness: return .red
        }
    }
}

// MARK: - Main Onboarding View

struct FlexTimeOnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    @State private var answers = OnboardingAnswers()
    @State private var direction: Edge = .trailing
    
    private let totalPages = 7
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress dots
                if currentPage > 0 && currentPage < 6 {
                    ProgressDotsView(current: currentPage - 1, total: 5)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }
                
                // Pages
                Group {
                    switch currentPage {
                    case 0: WelcomeScreen(onContinue: { advanceTo(1) })
                    case 1: PolicyQuestionScreen(answers: $answers, onContinue: { advanceTo(2) })
                    case 2: HoursQuestionScreen(answers: $answers, onContinue: { advanceTo(3) })
                    case 3: UsageQuestionScreen(answers: $answers, onContinue: { advanceTo(4) })
                    case 4: WeekStartScreen(answers: $answers, onContinue: { advanceTo(5) })
                    case 5: BuildingScreen(answers: answers, onComplete: { advanceTo(6) })
                    case 6: ValuePreviewScreen(answers: answers, onContinue: { completeOnboarding() })
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentPage)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentPage)
    }
    
    private func advanceTo(_ page: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentPage = page
        }
    }
    
    private func completeOnboarding() {
        // Save all settings
        AppSettings.weeklyTargetHours = answers.hoursPerPeriod
        AppSettings.weekStartDay = answers.weekStartDay
        answers.policyType.saveToCurrent()
        
        // Save usage reasons
        let reasons = answers.flexUsages.map { $0.rawValue }
        UserDefaults.standard.set(reasons, forKey: "flexUsageReasons")
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isComplete = true
        }
    }
}

// MARK: - Progress Dots

struct ProgressDotsView: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Color.blue : Color.blue.opacity(0.2))
                    .frame(width: index == current ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
            }
        }
    }
}

// MARK: - Screen 1: Welcome

struct WelcomeScreen: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var pulseIcon = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.15), .blue.opacity(0.0)],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseIcon ? 1.05 : 1.0)
                
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating, value: pulseIcon)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            Spacer().frame(height: 32)
            
            // Title
            Text("Take Control of\nYour Flex Time")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
            
            Spacer().frame(height: 16)
            
            // Subtitle
            Text("Never lose earned time again.\nTrack, bank, and use every hour you've worked.")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
            
            Spacer().frame(height: 24)
            
            // Social proof
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("Trusted by employees who value their time")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 10)
            
            Spacer()
            
            // CTA
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onContinue()
            }) {
                Text("Let's Get Started")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            Spacer().frame(height: 50)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1)) {
                pulseIcon = true
            }
        }
    }
}

// MARK: - Screen 2: Policy Type

struct PolicyQuestionScreen: View {
    @Binding var answers: OnboardingAnswers
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var selectedIndex: Int? = nil
    
    private let options: [(ExpirationPolicy, String, String, String)] = [
        (.rolling(days: 90), "90-Day Window", "Time expires 90 days after earned", "clock.arrow.circlepath"),
        (.quarterly, "Quarterly Reset", "Balance resets each quarter", "calendar.badge.clock"),
        (.annualCap, "Annual Reset", "Balance resets each year", "calendar"),
        (.never, "Never Expires", "Your time is always yours", "infinity"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)
            
            Text("What's your flex\ntime policy?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
            
            Spacer().frame(height: 8)
            
            Text("We'll track expirations so you never lose time")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 28)
            
            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    OptionCard(
                        title: option.1,
                        subtitle: option.2,
                        icon: option.3,
                        isSelected: selectedIndex == index,
                        delay: Double(index) * 0.08
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: showContent)
                    .onTapGesture {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedIndex = index
                            answers.policyType = option.0
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            OnboardingCTAButton(title: "Continue", enabled: selectedIndex != nil) {
                onContinue()
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - Screen 3: Hours Per Period

struct HoursQuestionScreen: View {
    @Binding var answers: OnboardingAnswers
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var selectedPreset: Double? = nil
    
    private let presets: [(Double, String)] = [
        (35, "35h"),
        (37.5, "37.5h"),
        (40, "40h"),
        (45, "45h"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)
            
            Text("How many hours\nper week?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
            
            Spacer().frame(height: 8)
            
            Text("Your standard work week — overtime gets banked")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 36)
            
            // Big number display
            Text("\(String(format: answers.hoursPerPeriod.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", answers.hoursPerPeriod))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
                .contentTransition(.numericText())
                .opacity(showContent ? 1 : 0)
            
            Text("hours / week")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 32)
            
            // Preset cards
            HStack(spacing: 12) {
                ForEach(Array(presets.enumerated()), id: \.offset) { index, preset in
                    PresetCard(
                        label: preset.1,
                        isSelected: answers.hoursPerPeriod == preset.0
                    )
                    .onTapGesture {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            answers.hoursPerPeriod = preset.0
                            selectedPreset = preset.0
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.06), value: showContent)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer().frame(height: 20)
            
            // Slider for fine-tuning
            VStack(spacing: 4) {
                Slider(value: $answers.hoursPerPeriod, in: 20...60, step: 0.5)
                    .tint(.blue)
                    .padding(.horizontal, 32)
                
                HStack {
                    Text("20h")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("60h")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 36)
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            OnboardingCTAButton(title: "Continue", enabled: true) {
                onContinue()
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - Screen 4: Usage Reasons (multi-select)

struct UsageQuestionScreen: View {
    @Binding var answers: OnboardingAnswers
    let onContinue: () -> Void
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)
            
            Text("What do you use\nflex time for?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
            
            Spacer().frame(height: 8)
            
            Text("Select all that apply — we'll personalize your experience")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 28)
            
            // 2-column grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(FlexUsageReason.allCases.enumerated()), id: \.element.id) { index, reason in
                    UsageCard(
                        reason: reason,
                        isSelected: answers.flexUsages.contains(reason)
                    )
                    .onTapGesture {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            if answers.flexUsages.contains(reason) {
                                answers.flexUsages.remove(reason)
                            } else {
                                answers.flexUsages.insert(reason)
                            }
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.06), value: showContent)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            OnboardingCTAButton(title: "Continue", enabled: !answers.flexUsages.isEmpty) {
                onContinue()
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - Screen 5: Week Start Day

struct WeekStartScreen: View {
    @Binding var answers: OnboardingAnswers
    let onContinue: () -> Void
    @State private var showContent = false
    
    private let options: [(Int, String, String)] = [
        (2, "Monday", "Most common for work weeks"),
        (1, "Sunday", "Traditional calendar week"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)
            
            Text("When does your\nwork week start?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
            
            Spacer().frame(height: 8)
            
            Text("We'll calculate your weekly hours accordingly")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 36)
            
            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    OptionCard(
                        title: option.1,
                        subtitle: option.2,
                        icon: option.0 == 2 ? "m.circle.fill" : "s.circle.fill",
                        isSelected: answers.weekStartDay == option.0,
                        delay: Double(index) * 0.08
                    )
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: showContent)
                    .onTapGesture {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            answers.weekStartDay = option.0
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            OnboardingCTAButton(title: "Continue", enabled: true) {
                onContinue()
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - Screen 6: Building Your Plan

struct BuildingScreen: View {
    let answers: OnboardingAnswers
    let onComplete: () -> Void
    
    @State private var progress: Double = 0
    @State private var completedSteps: Set<Int> = []
    @State private var currentStep = 0
    @State private var showContent = false
    
    private var steps: [(String, String)] {
        [
            ("Configuring \(answers.policyType.displayName.lowercased())", "clock.arrow.circlepath"),
            ("Setting \(String(format: answers.hoursPerPeriod.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", answers.hoursPerPeriod))h weekly target", "target"),
            ("Personalizing for your schedule", "person.crop.circle.badge.checkmark"),
            ("Setting up expiration alerts", "bell.badge"),
            ("Building your dashboard", "chart.bar.fill"),
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 6)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [.blue, .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(progress * 360))
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 28)
            
            Text("Setting up your\npersonalized tracker...")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 32)
            
            // Checklist
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(completedSteps.contains(index) ? Color.green : Color(.systemGray5))
                                .frame(width: 28, height: 28)
                            
                            if completedSteps.contains(index) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .transition(.scale.combined(with: .opacity))
                            } else if currentStep == index {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                        
                        Text(step.0)
                            .font(.system(size: 16, weight: completedSteps.contains(index) ? .medium : .regular, design: .rounded))
                            .foregroundStyle(completedSteps.contains(index) ? .primary : .secondary)
                    }
                    .opacity(showContent && index <= currentStep + 1 ? 1 : 0.3)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: completedSteps)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            startBuildingAnimation()
        }
    }
    
    private func startBuildingAnimation() {
        for i in 0..<steps.count {
            let delay = Double(i) * 0.5 + 0.3
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    currentStep = i
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.35) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    completedSteps.insert(i)
                    progress = Double(i + 1) / Double(steps.count)
                }
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        
        // Auto-advance after build completes
        let totalTime = Double(steps.count) * 0.5 + 0.3 + 0.7
        DispatchQueue.main.asyncAfter(deadline: .now() + totalTime) {
            onComplete()
        }
    }
}

// MARK: - Screen 7: Value Preview

struct ValuePreviewScreen: View {
    let answers: OnboardingAnswers
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var animateChart = false
    
    private var projectedMonthlyFlex: Double {
        // Assume ~2-4 hours of flex per week on average
        return 12.0
    }
    
    private var expirationText: String {
        switch answers.policyType {
        case .rolling(let days):
            return "Tracked with \(days)-day alerts"
        case .quarterly:
            return "Reset reminders each quarter"
        case .annualCap:
            return "Annual tracking enabled"
        case .never:
            return "Unlimited accumulation"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)
            
            Text("Your FlexTime\nDashboard")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
            
            Spacer().frame(height: 8)
            
            Text("Here's what we've set up for you")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 24)
            
            // Preview card
            VStack(spacing: 16) {
                // Balance preview
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Flex Balance")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("0.0h")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Weekly Target")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("\(String(format: answers.hoursPerPeriod.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", answers.hoursPerPeriod))h")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                    }
                }
                
                Divider()
                
                // Mini bar chart preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Projected Weekly Balance")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(0..<7, id: \.self) { day in
                            let height: CGFloat = [0.3, 0.5, 0.7, 0.4, 0.6, 0.2, 0.1][day]
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: animateChart ? 50 * height : 0)
                                .frame(maxWidth: .infinity)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(day) * 0.08),
                                    value: animateChart
                                )
                        }
                    }
                    .frame(height: 50)
                    
                    HStack {
                        ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, day in
                            Text(day)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                Divider()
                
                // Info rows
                HStack(spacing: 20) {
                    InfoBadge(icon: "clock.arrow.circlepath", text: expirationText, color: .orange)
                    InfoBadge(icon: "bell.badge", text: "Smart alerts on", color: .purple)
                }
            }
            .padding(20)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            
            Spacer().frame(height: 20)
            
            // Usage tags
            if !answers.flexUsages.isEmpty {
                VStack(spacing: 8) {
                    Text("Personalized for")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(Array(answers.flexUsages), id: \.self) { usage in
                            HStack(spacing: 4) {
                                Image(systemName: usage.icon)
                                    .font(.system(size: 11))
                                Text(usage.title)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(usage.color.opacity(0.1))
                            .foregroundStyle(usage.color)
                            .clipShape(Capsule())
                        }
                    }
                }
                .opacity(showContent ? 1 : 0)
            }
            
            Spacer()
            
            OnboardingCTAButton(title: "Start Tracking", enabled: true) {
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
                onContinue()
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer().frame(height: 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateChart = true
            }
        }
    }
}

// MARK: - Reusable Components

struct OptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? .blue : .secondary)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.blue)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

struct PresetCard: View {
    let label: String
    let isSelected: Bool
    
    var body: some View {
        Text(label)
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? .blue : .primary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

struct UsageCard: View {
    let reason: FlexUsageReason
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: reason.icon)
                .font(.system(size: 28))
                .foregroundStyle(isSelected ? reason.color : .secondary)
            
            Text(reason.title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? reason.color.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? reason.color.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
    }
}

struct InfoBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

struct OnboardingCTAButton: View {
    let title: String
    let enabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: enabled ? [.blue, .blue.opacity(0.8)] : [.gray.opacity(0.4), .gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!enabled)
        .padding(.horizontal, 32)
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - ExpirationPolicy Extension

extension ExpirationPolicy {
    func saveToCurrent() {
        ExpirationPolicy.current = self
    }
}
