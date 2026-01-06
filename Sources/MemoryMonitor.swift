import Foundation
import Combine
import UserNotifications

// MARK: - Data Models

struct AppProcess: Identifiable, Hashable {
    let id: Int32  // PID
    let name: String
    let memoryMB: Double
    let cpu: Double
    let user: String

    var displayName: String {
        if name.contains("/") {
            return (name as NSString).lastPathComponent
        }
        return name
    }

    var isClaude: Bool {
        name.lowercased().contains("claude")
    }

    var isChrome: Bool {
        name.lowercased().contains("chrome") || name.lowercased().contains("google chrome")
    }

    var isSafari: Bool {
        name.lowercased().contains("safari") || name.lowercased().contains("webkit")
    }

    var isXcode: Bool {
        name.lowercased().contains("xcode") || name.lowercased().contains("sourcekit")
    }

    var isDocker: Bool {
        name.lowercased().contains("docker")
    }

    var isSystem: Bool {
        user == "root" || user == "_windowserver" || user.hasPrefix("_")
    }

    var appFamily: String {
        if isClaude { return "Claude" }
        if isChrome { return "Chrome" }
        if isSafari { return "Safari" }
        if isXcode { return "Xcode" }
        if isDocker { return "Docker" }
        if displayName.contains("Helper") { return displayName.components(separatedBy: " Helper").first ?? "Other" }
        return displayName
    }

    var familyIcon: String {
        switch appFamily {
        case "Claude": return "terminal.fill"
        case "Chrome": return "globe"
        case "Safari": return "safari"
        case "Xcode": return "hammer.fill"
        case "Docker": return "shippingbox.fill"
        default: return "app.fill"
        }
    }
}

struct ProcessGroup: Identifiable {
    let id: String  // Family name
    let name: String
    let icon: String
    let processes: [AppProcess]
    let totalMemoryMB: Double
    let totalCPU: Double
    let color: String

    var processCount: Int { processes.count }

    static func group(from processes: [AppProcess]) -> [ProcessGroup] {
        let grouped = Dictionary(grouping: processes) { $0.appFamily }

        return grouped.map { family, procs in
            let sortedProcs = procs.sorted { $0.memoryMB > $1.memoryMB }
            let totalMem = procs.reduce(0) { $0 + $1.memoryMB }
            let totalCPU = procs.reduce(0) { $0 + $1.cpu }
            let icon = procs.first?.familyIcon ?? "app.fill"

            let color: String
            switch family {
            case "Claude": color = "orange"
            case "Chrome": color = "blue"
            case "Safari": color = "cyan"
            case "Xcode": color = "blue"
            case "Docker": color = "blue"
            default: color = "gray"
            }

            return ProcessGroup(
                id: family,
                name: family,
                icon: icon,
                processes: sortedProcs,
                totalMemoryMB: totalMem,
                totalCPU: totalCPU,
                color: color
            )
        }
        .sorted { $0.totalMemoryMB > $1.totalMemoryMB }
    }
}

struct MemoryStats {
    let totalMB: Double
    let usedMB: Double
    let freeMB: Double
    let wiredMB: Double
    let compressedMB: Double
    let swapUsedMB: Double
    let activeMB: Double
    let inactiveMB: Double

    var usedPercent: Int {
        Int((usedMB / totalMB) * 100)
    }

    var usedPercentDouble: Double {
        (usedMB / totalMB) * 100
    }

    var pressureLevel: String {
        if usedPercent > 85 { return "Critical" }
        if usedPercent > 70 { return "High" }
        if usedPercent > 50 { return "Moderate" }
        return "Normal"
    }

    var pressureDescription: String {
        if usedPercent > 90 { return "Memory critically low. Close apps or restart." }
        if usedPercent > 85 { return "Heavy pressure. Consider closing unused apps." }
        if usedPercent > 70 { return "Elevated usage. Monitor closely." }
        if usedPercent > 50 { return "Moderate usage. System running well." }
        return "Low usage. Plenty of headroom."
    }
}

struct CleanupResult {
    let killedCount: Int
    let freedMB: Double
    let skippedActive: Int
}

struct MachineInfo {
    let modelName: String
    let chip: String
    let memoryGB: Int
    let serialNumber: String

    static func fetch() -> MachineInfo {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        task.arguments = ["SPHardwareDataType"]

        let pipe = Pipe()
        task.standardOutput = pipe

        var modelName = "Mac"
        var chip = "Apple Silicon"
        var memoryGB = 16
        var serial = ""

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("Model Name:") {
                        modelName = trimmed.replacingOccurrences(of: "Model Name: ", with: "")
                    } else if trimmed.hasPrefix("Chip:") {
                        chip = trimmed.replacingOccurrences(of: "Chip: ", with: "")
                    } else if trimmed.hasPrefix("Memory:") {
                        let memStr = trimmed.replacingOccurrences(of: "Memory: ", with: "").replacingOccurrences(of: " GB", with: "")
                        memoryGB = Int(memStr) ?? 16
                    } else if trimmed.hasPrefix("Serial Number") {
                        serial = trimmed.components(separatedBy: ": ").last ?? ""
                    }
                }
            }
        } catch {
            print("Error fetching machine info: \(error)")
        }

        return MachineInfo(modelName: modelName, chip: chip, memoryGB: memoryGB, serialNumber: serial)
    }
}

// MARK: - Memory Monitor

@MainActor
class MemoryMonitor: ObservableObject {
    @Published var processes: [AppProcess] = []
    @Published var processGroups: [ProcessGroup] = []
    @Published var memoryStats: MemoryStats?
    @Published var machineInfo: MachineInfo?
    @Published var claudeProcessCount: Int = 0
    @Published var claudeMemoryMB: Double = 0
    @Published var chromeProcessCount: Int = 0
    @Published var chromeMemoryMB: Double = 0
    @Published var lastCleanupSaved: Double = 0
    @Published var isRefreshing = false
    @Published var memoryHistory: [Double] = []  // Rolling history of memory usage %
    @Published var lastRefreshTime: Date = Date()
    @Published var previousGroupMemory: [String: Double] = [:]  // Track memory trends per group

    private var timer: Timer?
    private let maxHistoryPoints = 60  // 5 minutes of history at 5s intervals
    private var lastAlertPercent: Int = 0  // Prevent repeated notifications

    func memoryTrend(for groupName: String) -> MemoryTrend {
        guard let previous = previousGroupMemory[groupName],
              let current = processGroups.first(where: { $0.name == groupName })?.totalMemoryMB else {
            return .stable
        }
        let diff = current - previous
        if diff > 50 { return .increasing }
        if diff < -50 { return .decreasing }
        return .stable
    }

    enum MemoryTrend {
        case increasing, decreasing, stable

        var icon: String {
            switch self {
            case .increasing: return "arrow.up.right"
            case .decreasing: return "arrow.down.right"
            case .stable: return ""
            }
        }

        var color: String {
            switch self {
            case .increasing: return "FF9500"
            case .decreasing: return "30D158"
            case .stable: return ""
            }
        }
    }

    var lastRefreshString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastRefreshTime, relativeTo: Date())
    }

    var memoryUsagePercent: String {
        guard let stats = memoryStats else { return "--%" }
        return "\(stats.usedPercent)%"
    }

    init() {
        machineInfo = MachineInfo.fetch()
        requestNotificationPermission()
        refresh()
        startAutoRefresh()
    }

    func startAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func refresh() {
        isRefreshing = true
        // Store previous group memory before refresh
        for group in processGroups {
            previousGroupMemory[group.name] = group.totalMemoryMB
        }
        Task {
            await fetchProcesses()
            await fetchMemoryStats()
            updateHistory()
            lastRefreshTime = Date()
            isRefreshing = false
        }
    }

    private func updateHistory() {
        guard let stats = memoryStats else { return }
        memoryHistory.append(stats.usedPercentDouble)
        if memoryHistory.count > maxHistoryPoints {
            memoryHistory.removeFirst()
        }
        checkMemoryPressure(stats: stats)
    }

    private func checkMemoryPressure(stats: MemoryStats) {
        let percent = stats.usedPercent

        // Only alert once when crossing thresholds
        if percent >= 90 && lastAlertPercent < 90 {
            sendNotification(
                title: "Critical Memory Pressure",
                body: "Memory usage is at \(percent)%. Consider closing some applications.",
                isCritical: true
            )
            lastAlertPercent = percent
        } else if percent >= 85 && lastAlertPercent < 85 {
            sendNotification(
                title: "High Memory Usage",
                body: "Memory usage is at \(percent)%. You may experience slowdowns.",
                isCritical: false
            )
            lastAlertPercent = percent
        } else if percent < 80 && lastAlertPercent >= 85 {
            // Reset when memory drops
            lastAlertPercent = percent
        }
    }

    private func sendNotification(title: String, body: String, isCritical: Bool) {
        // Only send if we have a valid bundle
        guard Bundle.main.bundleIdentifier != nil else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = "MEMORY_ALERT"
        if isCritical {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    func requestNotificationPermission() {
        // Only request if we have a valid bundle (not running from command line build)
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func fetchProcesses() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/ps")
                task.arguments = ["-axo", "pid,rss,%cpu,user,comm"]

                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = FileHandle.nullDevice

                do {
                    try task.run()

                    // Use timeout to prevent hanging
                    let deadline = DispatchTime.now() + .seconds(3)
                    let group = DispatchGroup()
                    group.enter()

                    DispatchQueue.global().async {
                        task.waitUntilExit()
                        group.leave()
                    }

                    let result = group.wait(timeout: deadline)
                    if result == .timedOut {
                        task.terminate()
                        continuation.resume()
                        return
                    }

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self?.parseProcessOutput(output)
                            continuation.resume()
                        }
                        return
                    }
                } catch {
                    print("Error fetching processes: \(error)")
                }
                continuation.resume()
            }
        }
    }

    private func parseProcessOutput(_ output: String) {
        var newProcesses: [AppProcess] = []
        var claudeCount = 0
        var claudeMem: Double = 0
        var chromeCount = 0
        var chromeMem: Double = 0

        let lines = output.components(separatedBy: "\n")
        for line in lines.dropFirst() {
            let parts = line.split(separator: " ", maxSplits: 4, omittingEmptySubsequences: true)
            guard parts.count >= 5,
                  let pid = Int32(parts[0]),
                  let rss = Double(parts[1]),
                  let cpu = Double(parts[2]) else { continue }

            let user = String(parts[3])
            let name = String(parts[4])
            let memMB = rss / 1024.0

            // Filter out tiny processes
            guard memMB > 1 else { continue }

            let process = AppProcess(
                id: pid,
                name: name,
                memoryMB: memMB,
                cpu: cpu,
                user: user
            )
            newProcesses.append(process)

            if process.isClaude {
                claudeCount += 1
                claudeMem += memMB
            }
            if process.isChrome {
                chromeCount += 1
                chromeMem += memMB
            }
        }

        // Sort by memory descending
        processes = newProcesses.sorted { $0.memoryMB > $1.memoryMB }
        processGroups = ProcessGroup.group(from: processes)
        claudeProcessCount = claudeCount
        claudeMemoryMB = claudeMem
        chromeProcessCount = chromeCount
        chromeMemoryMB = chromeMem
    }

    func fetchMemoryStats() async {
        let totalBytes = Foundation.ProcessInfo.processInfo.physicalMemory
        let totalMB = Double(totalBytes) / 1024.0 / 1024.0

        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/vm_stat")

                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = FileHandle.nullDevice

                do {
                    try task.run()

                    // Timeout protection
                    let deadline = DispatchTime.now() + .seconds(2)
                    let group = DispatchGroup()
                    group.enter()

                    DispatchQueue.global().async {
                        task.waitUntilExit()
                        group.leave()
                    }

                    if group.wait(timeout: deadline) == .timedOut {
                        task.terminate()
                        continuation.resume()
                        return
                    }

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            let stats = self?.parseVMStat(output, totalMB: totalMB)
                            self?.memoryStats = stats
                            continuation.resume()
                        }
                        return
                    }
                } catch {
                    print("Error fetching memory stats: \(error)")
                }
                continuation.resume()
            }
        }
    }

    private func parseVMStat(_ output: String, totalMB: Double) -> MemoryStats {
        var pagesFree: Double = 0
        var pagesActive: Double = 0
        var pagesInactive: Double = 0
        var pagesWired: Double = 0
        var pagesCompressed: Double = 0
        var pageSize: Double = 16384

        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if line.contains("page size of") {
                if let size = line.components(separatedBy: " ").compactMap({ Double($0) }).first {
                    pageSize = size
                }
            } else if line.contains("Pages free:") {
                pagesFree = extractNumber(from: line)
            } else if line.contains("Pages active:") {
                pagesActive = extractNumber(from: line)
            } else if line.contains("Pages inactive:") {
                pagesInactive = extractNumber(from: line)
            } else if line.contains("Pages wired down:") {
                pagesWired = extractNumber(from: line)
            } else if line.contains("Pages occupied by compressor:") {
                pagesCompressed = extractNumber(from: line)
            }
        }

        let pageSizeMB = pageSize / 1024.0 / 1024.0
        let freeMB = pagesFree * pageSizeMB
        let wiredMB = pagesWired * pageSizeMB
        let compressedMB = pagesCompressed * pageSizeMB
        let activeMB = pagesActive * pageSizeMB
        let inactiveMB = pagesInactive * pageSizeMB
        let usedMB = totalMB - freeMB

        // Fetch swap with quick timeout (non-blocking approach)
        var swapUsedMB: Double = 0
        let swapTask = Process()
        swapTask.executableURL = URL(fileURLWithPath: "/usr/sbin/sysctl")
        swapTask.arguments = ["vm.swapusage"]
        let swapPipe = Pipe()
        swapTask.standardOutput = swapPipe
        swapTask.standardError = FileHandle.nullDevice

        if let _ = try? swapTask.run() {
            let swapGroup = DispatchGroup()
            swapGroup.enter()
            DispatchQueue.global().async {
                swapTask.waitUntilExit()
                swapGroup.leave()
            }
            // Only wait 500ms for swap info - it's non-critical
            if swapGroup.wait(timeout: .now() + .milliseconds(500)) == .success {
                if let swapData = swapPipe.fileHandleForReading.readDataToEndOfFile() as Data?,
                   let swapOutput = String(data: swapData, encoding: .utf8) {
                    if let usedMatch = swapOutput.range(of: "used = ([0-9.]+)M", options: .regularExpression) {
                        let usedStr = swapOutput[usedMatch].replacingOccurrences(of: "used = ", with: "").replacingOccurrences(of: "M", with: "")
                        swapUsedMB = Double(usedStr) ?? 0
                    }
                }
            } else {
                swapTask.terminate()
            }
        }

        return MemoryStats(
            totalMB: totalMB,
            usedMB: usedMB,
            freeMB: freeMB,
            wiredMB: wiredMB,
            compressedMB: compressedMB,
            swapUsedMB: swapUsedMB,
            activeMB: activeMB,
            inactiveMB: inactiveMB
        )
    }

    private func extractNumber(from line: String) -> Double {
        let parts = line.components(separatedBy: ":")
        guard parts.count >= 2 else { return 0 }
        let numStr = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ".", with: "")
        return Double(numStr) ?? 0
    }

    func killProcess(_ pid: Int32) {
        kill(pid, SIGTERM)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refresh()
        }
    }

    func killProcessGroup(_ group: ProcessGroup, keepTop: Int = 0) -> Int {
        var killed = 0
        let toKeep = group.processes.prefix(keepTop).map { $0.id }

        for process in group.processes {
            if !toKeep.contains(process.id) {
                kill(process.id, SIGTERM)
                killed += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refresh()
        }

        return killed
    }

    func cleanupClaudeZombies() -> Int {
        let activeTerminalPIDs = processes
            .filter { $0.isClaude && $0.cpu > 1.0 }
            .map { $0.id }

        var killed = 0
        let beforeMem = claudeMemoryMB

        for process in processes where process.isClaude {
            if activeTerminalPIDs.contains(process.id) { continue }
            if process.name.contains("cli.js") { continue }
            if process.memoryMB < 100 && process.cpu < 0.5 {
                kill(process.id, SIGTERM)
                killed += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refresh()
            self.lastCleanupSaved = beforeMem - self.claudeMemoryMB
        }

        return killed
    }

    func killAllClaudeWorkers() -> Int {
        var killed = 0
        let beforeMem = claudeMemoryMB

        let mainSessionPIDs = processes
            .filter { $0.isClaude && $0.memoryMB > 150 }
            .prefix(3)
            .map { $0.id }

        for process in processes where process.isClaude {
            if !mainSessionPIDs.contains(process.id) {
                kill(process.id, SIGTERM)
                killed += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refresh()
            self.lastCleanupSaved = beforeMem - self.claudeMemoryMB
        }

        return killed
    }

    func killChromeHelpers(keepTop: Int = 3) -> Int {
        let chromeGroup = processGroups.first { $0.name == "Chrome" }
        guard let group = chromeGroup else { return 0 }
        return killProcessGroup(group, keepTop: keepTop)
    }

    /// Smart Cleanup: Safely frees memory without killing active apps
    /// - Skips processes with CPU activity (approximates "recently used")
    /// - Skips system processes
    /// - Skips the main process of each app family
    /// - Only kills idle helper processes and background workers
    func smartCleanup() async -> CleanupResult {
        let beforeMem = memoryStats?.usedMB ?? 0
        var killed = 0
        var skippedActive = 0

        // Protected apps that should never be killed
        let protectedApps = ["Finder", "Dock", "WindowServer", "loginwindow", "SystemUIServer",
                             "CoreServicesUIAgent", "Spotlight", "NotificationCenter"]

        // For each process group, keep the highest memory process (main app)
        // and only kill idle helpers
        for group in processGroups {
            // Skip system groups
            if group.name.hasPrefix("_") || group.name == "root" { continue }

            // Get processes sorted by memory (highest first)
            let procs = group.processes.sorted { $0.memoryMB > $1.memoryMB }

            // Always keep the top process (main app) and any with CPU activity
            for (index, process) in procs.enumerated() {
                // Skip protected system apps
                if protectedApps.contains(where: { process.name.contains($0) }) { continue }

                // Skip system users
                if process.isSystem { continue }

                // Always keep the main process (index 0 = highest memory = likely main app)
                if index == 0 { continue }

                // Keep browser tabs that might be active (keep top 5 Chrome/Safari)
                if (process.isChrome || process.isSafari) && index < 5 { continue }

                // CRITICAL: Skip any process with CPU activity (user is using it)
                if process.cpu > 0.1 {
                    skippedActive += 1
                    continue
                }

                // Skip small processes (not worth killing)
                if process.memoryMB < 50 { continue }

                // This process is idle and a helper - safe to kill
                kill(process.id, SIGTERM)
                killed += 1
            }
        }

        // Wait for processes to terminate
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Refresh to get new memory stats
        await fetchProcesses()
        await fetchMemoryStats()

        let afterMem = memoryStats?.usedMB ?? 0
        let freedMB = max(0, beforeMem - afterMem)

        return CleanupResult(killedCount: killed, freedMB: freedMB, skippedActive: skippedActive)
    }
}
