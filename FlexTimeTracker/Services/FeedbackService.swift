import Foundation
import UIKit

// MARK: - FeedbackService

/// Reusable feedback service that creates GitHub Issues via REST API.
/// Drop this file into any iOS app — no dependencies required.
final class FeedbackService: Sendable {
    
    // MARK: - Configuration
    
    /// Replace with a fine-grained PAT that has Issues write access
    private static let token = "GITHUB_FEEDBACK_TOKEN"
    
    /// The GitHub repo (owner/name) to file issues against.
    let repository: String
    
    init(repository: String) {
        self.repository = repository
    }
    
    // MARK: - Types
    
    enum Category: String, CaseIterable, Identifiable {
        case bug = "Bug 🐛"
        case feature = "Feature 💡"
        case other = "Other 💬"
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .bug: return "bug"
            case .feature: return "enhancement"
            case .other: return "feedback"
            }
        }
        
        var emoji: String {
            switch self {
            case .bug: return "🐛"
            case .feature: return "💡"
            case .other: return "💬"
            }
        }
    }
    
    struct FeedbackResult {
        let success: Bool
        let issueURL: String?
        let error: String?
    }
    
    // MARK: - Device Info
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
    
    private var iosVersion: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }
    
    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buf in
            guard let base = buf.baseAddress?.assumingMemoryBound(to: CChar.self) else { return "Unknown" }
            return String(cString: base)
        }
    }
    
    // MARK: - Submit Feedback
    
    func submit(
        category: Category,
        message: String,
        screenshotData: Data? = nil
    ) async -> FeedbackResult {
        
        let title = "\(category.emoji) \(category == .bug ? "Bug Report" : category == .feature ? "Feature Request" : "Feedback")"
        
        var body = """
        ## \(category.rawValue)
        
        \(message)
        
        ---
        **Device Info**
        - App Version: \(appVersion)
        - iOS Version: \(iosVersion)
        - Device: \(deviceModel)
        - Date: \(ISO8601DateFormatter().string(from: Date()))
        """
        
        if let screenshotData {
            let base64 = screenshotData.base64EncodedString()
            body += "\n\n---\n**Screenshot**\n\n![screenshot](data:image/png;base64,\(base64))"
        }
        
        let payload: [String: Any] = [
            "title": title,
            "body": body,
            "labels": [category.label]
        ]
        
        guard let url = URL(string: "https://api.github.com/repos/\(repository)/issues") else {
            return FeedbackResult(success: false, issueURL: nil, error: "Invalid repository URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Self.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return FeedbackResult(success: false, issueURL: nil, error: "Invalid response")
            }
            
            if httpResponse.statusCode == 201 {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let issueURL = json?["html_url"] as? String
                return FeedbackResult(success: true, issueURL: issueURL, error: nil)
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                return FeedbackResult(success: false, issueURL: nil, error: "HTTP \(httpResponse.statusCode): \(errorBody)")
            }
        } catch {
            return FeedbackResult(success: false, issueURL: nil, error: error.localizedDescription)
        }
    }
}
