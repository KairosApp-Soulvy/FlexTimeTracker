import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0
    @State private var weeklyHours: Double = 40.0
    @State private var weekStart: Int = 2
    @State private var policyType: Int = 0 // 0=rolling90, 1=quarterly, 2=never
    
    var body: some View {
        TabView(selection: $page) {
            // Page 1: Welcome
            welcomePage.tag(0)
            // Page 2: Set up work week
            setupPage.tag(1)
            // Page 3: Ready
            readyPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
    
    // MARK: - Page 1
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("FlexTime")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Text("Track your overtime.\nBank it. Use it. Don't lose it.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                withAnimation { page = 1 }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .padding()
    }
    
    // MARK: - Page 2
    
    private var setupPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Set Up Your Week")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                // Weekly hours
                VStack(spacing: 8) {
                    Text("Target hours per week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(String(format: "%.1f", weeklyHours))h")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                        .monospacedDigit()
                    
                    HStack(spacing: 8) {
                        ForEach([35.0, 37.5, 40.0, 45.0], id: \.self) { hours in
                            Button(hours == 37.5 ? "37.5" : "\(Int(hours))") {
                                weeklyHours = hours
                            }
                            .buttonStyle(.bordered)
                            .tint(weeklyHours == hours ? .blue : .secondary)
                            .controlSize(.small)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Week start
                VStack(spacing: 8) {
                    Text("Week starts on")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $weekStart) {
                        Text("Monday").tag(2)
                        Text("Sunday").tag(1)
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Expiration
                VStack(spacing: 8) {
                    Text("Flex time expires after")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $policyType) {
                        Text("90 days").tag(0)
                        Text("Each quarter").tag(1)
                        Text("Never").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                // Save settings
                AppSettings.weeklyTargetHours = weeklyHours
                AppSettings.weekStartDay = weekStart
                switch policyType {
                case 0: ExpirationPolicy.current = .rolling(days: 90)
                case 1: ExpirationPolicy.current = .quarterly
                default: ExpirationPolicy.current = .never
                }
                withAnimation { page = 2 }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .padding()
    }
    
    // MARK: - Page 3
    
    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                FeatureRow(icon: "play.fill", color: .green, text: "Clock in when you start working")
                FeatureRow(icon: "stop.fill", color: .red, text: "Clock out when you're done")
                FeatureRow(icon: "banknote", color: .blue, text: "Track your banked flex time")
                FeatureRow(icon: "bell.fill", color: .orange, text: "Get alerts before time expires")
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            Button {
                isComplete = true
            } label: {
                Text("Start Tracking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}
