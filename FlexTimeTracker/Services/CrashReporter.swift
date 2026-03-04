import Foundation
import UIKit

/// Lightweight crash reporter that captures crashes and stores them locally.
/// On next launch, crash logs are available for review/upload.
final class CrashReporter: @unchecked Sendable {
    static let shared = CrashReporter()
    
    private let crashLogKey = "pendingCrashLogs"
    private let lastCrashKey = "lastCrashLog"
    
    private init() {}
    
    // MARK: - Setup
    
    /// Call in AppDelegate/App init to install crash handlers
    func install() {
        // Capture uncaught Objective-C exceptions
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.saveCrash(
                name: exception.name.rawValue,
                reason: exception.reason ?? "Unknown",
                stackTrace: exception.callStackSymbols
            )
        }
        
        // Capture signals (SIGABRT, SIGSEGV, SIGBUS, etc.)
        for sig in [SIGABRT, SIGSEGV, SIGBUS, SIGFPE, SIGILL, SIGTRAP] {
            signal(sig) { signal in
                CrashReporter.shared.saveCrash(
                    name: "Signal \(signal)",
                    reason: CrashReporter.signalName(signal),
                    stackTrace: Thread.callStackSymbols
                )
                // Re-raise to let default handler terminate
                Darwin.signal(signal, SIG_DFL)
                Darwin.raise(signal)
            }
        }
        
        // Check for pending crash logs from last run
        checkForPendingCrashes()
    }
    
    // MARK: - Crash Capture
    
    private func saveCrash(name: String, reason: String, stackTrace: [String]) {
        let crash = CrashLog(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?",
            osVersion: UIDevice.current.systemVersion,
            deviceModel: deviceModel(),
            name: name,
            reason: reason,
            stackTrace: stackTrace,
            usedMemoryMB: usedMemoryMB(),
            freeDiskGB: freeDiskGB()
        )
        
        // Write synchronously (we're crashing)
        if let data = try? JSONEncoder().encode(crash) {
            UserDefaults.standard.set(data, forKey: lastCrashKey)
            UserDefaults.standard.synchronize()
            
            // Also append to pending list
            var pending = UserDefaults.standard.array(forKey: crashLogKey) as? [Data] ?? []
            pending.append(data)
            // Keep last 10
            if pending.count > 10 { pending = Array(pending.suffix(10)) }
            UserDefaults.standard.set(pending, forKey: crashLogKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    // MARK: - Pending Crash Check
    
    private func checkForPendingCrashes() {
        guard let pending = UserDefaults.standard.array(forKey: crashLogKey) as? [Data],
              !pending.isEmpty else { return }
        
        // Write to shared location for external monitoring
        writeCrashesToFile(pending)
    }
    
    /// Write crash logs to a file in the app's documents directory
    private func writeCrashesToFile(_ logs: [Data]) {
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let crashDir = docsDir.appendingPathComponent("CrashLogs")
        try? FileManager.default.createDirectory(at: crashDir, withIntermediateDirectories: true)
        
        for (i, data) in logs.enumerated() {
            if let crash = try? JSONDecoder().decode(CrashLog.self, from: data) {
                let filename = "crash_\(crash.timestamp.replacingOccurrences(of: ":", with: "-"))_\(i).json"
                let url = crashDir.appendingPathComponent(filename)
                try? data.write(to: url)
            }
        }
    }
    
    /// Get all pending crash logs
    func getPendingCrashes() -> [CrashLog] {
        guard let pending = UserDefaults.standard.array(forKey: crashLogKey) as? [Data] else { return [] }
        return pending.compactMap { try? JSONDecoder().decode(CrashLog.self, from: $0) }
    }
    
    /// Clear pending crashes after they've been reviewed
    func clearPendingCrashes() {
        UserDefaults.standard.removeObject(forKey: crashLogKey)
        UserDefaults.standard.removeObject(forKey: lastCrashKey)
    }
    
    /// Get most recent crash
    func getLastCrash() -> CrashLog? {
        guard let data = UserDefaults.standard.data(forKey: lastCrashKey) else { return nil }
        return try? JSONDecoder().decode(CrashLog.self, from: data)
    }
    
    // MARK: - Helpers
    
    private static func signalName(_ sig: Int32) -> String {
        switch sig {
        case SIGABRT: return "SIGABRT (Abort)"
        case SIGSEGV: return "SIGSEGV (Segmentation Fault)"
        case SIGBUS: return "SIGBUS (Bus Error)"
        case SIGFPE: return "SIGFPE (Floating Point Exception)"
        case SIGILL: return "SIGILL (Illegal Instruction)"
        case SIGTRAP: return "SIGTRAP (Trace Trap)"
        default: return "Signal \(sig)"
        }
    }
    
    private func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? "Unknown" : identifier
    }
    
    private func usedMemoryMB() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            return Int(info.resident_size / (1024 * 1024))
        }
        return -1
    }
    
    private func freeDiskGB() -> Double {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let free = attrs[.systemFreeSize] as? Int64 {
            return Double(free) / (1024 * 1024 * 1024)
        }
        return -1
    }
}

// MARK: - Crash Log Model

struct CrashLog: Codable {
    let timestamp: String
    let appVersion: String
    let buildNumber: String
    let osVersion: String
    let deviceModel: String
    let name: String
    let reason: String
    let stackTrace: [String]
    let usedMemoryMB: Int
    let freeDiskGB: Double
    
    var summary: String {
        """
        Crash: \(name) — \(reason)
        App: v\(appVersion) (\(buildNumber))
        OS: iOS \(osVersion), Device: \(deviceModel)
        Memory Used: \(usedMemoryMB)MB, Disk Free: \(String(format: "%.1f", freeDiskGB))GB
        Time: \(timestamp)
        Stack (\(stackTrace.count) frames):
        \(stackTrace.prefix(20).joined(separator: "\n"))
        """
    }
}
