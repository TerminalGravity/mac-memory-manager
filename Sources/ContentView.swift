import SwiftUI

// MARK: - Design System

struct DesignSystem {
    // Apple-inspired color palette with Sonoma/Ventura vibes
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let criticalGradient = LinearGradient(
        colors: [Color(hex: "FF3B30"), Color(hex: "FF6B6B")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let warningGradient = LinearGradient(
        colors: [Color(hex: "FF9500"), Color(hex: "FFCC00")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let successGradient = LinearGradient(
        colors: [Color(hex: "34C759"), Color(hex: "30D158")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Premium gauge gradients
    static func gaugeGradient(for percent: Int) -> AngularGradient {
        if percent > 85 {
            return AngularGradient(
                colors: [Color(hex: "FF3B30").opacity(0.7), Color(hex: "FF6B6B"), Color(hex: "FF3B30")],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        }
        if percent > 70 {
            return AngularGradient(
                colors: [Color(hex: "FF9500").opacity(0.7), Color(hex: "FFCC00"), Color(hex: "FF9500")],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        }
        if percent > 50 {
            return AngularGradient(
                colors: [Color(hex: "FFD60A").opacity(0.7), Color(hex: "FFEE58"), Color(hex: "FFD60A")],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        }
        return AngularGradient(
            colors: [Color(hex: "30D158").opacity(0.7), Color(hex: "4ADE80"), Color(hex: "30D158")],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    // Memory type colors (Activity Monitor inspired)
    static let appMemoryColor = Color(hex: "FFD60A")      // Yellow - App Memory
    static let wiredColor = Color(hex: "FF9F0A")          // Orange - Wired
    static let compressedColor = Color(hex: "BF5AF2")     // Purple - Compressed
    static let cachedColor = Color(hex: "64D2FF")         // Cyan - Cached Files
    static let freeColor = Color(hex: "30D158")           // Green - Free

    // Glass/Frosted background
    static let glassBackground = Color(NSColor.windowBackgroundColor).opacity(0.7)
    static let elevatedSurface = Color(NSColor.controlBackgroundColor)

    static func pressureColor(for percent: Int) -> Color {
        if percent > 85 { return Color(hex: "FF3B30") }
        if percent > 70 { return Color(hex: "FF9500") }
        if percent > 50 { return Color(hex: "FFD60A") }
        return Color(hex: "30D158")
    }

    static func pressureGlow(for percent: Int) -> Color {
        pressureColor(for: percent).opacity(0.4)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Visual Effect Background

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Window Draggable Area

struct WindowDraggableArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = WindowDragView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class WindowDragView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

// MARK: - Content View

struct ContentView: View {
    @ObservedObject var monitor: MemoryMonitor
    @State private var searchText = ""
    @State private var expandedGroups: Set<String> = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var viewMode: ViewMode = .grouped
    @State private var hoveredGroup: String? = nil
    @State private var showCleanupConfirm = false
    @State private var isOptimizing = false
    @State private var optimizeResult: CleanupResult? = nil
    @FocusState private var isSearchFocused: Bool

    enum ViewMode: String, CaseIterable {
        case grouped = "Grouped"
        case all = "All Processes"
    }

    var filteredGroups: [ProcessGroup] {
        if searchText.isEmpty {
            return monitor.processGroups
        }
        return monitor.processGroups.filter { group in
            group.name.localizedCaseInsensitiveContains(searchText) ||
            group.processes.contains { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var filteredProcesses: [AppProcess] {
        if searchText.isEmpty {
            return Array(monitor.processes.prefix(100))
        }
        return monitor.processes.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Memory Dashboard
            memoryDashboard
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

            // Recommendations (if needed)
            if let stats = monitor.memoryStats, stats.usedPercent > 70 {
                recommendationsSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            Divider()
                .opacity(0.5)

            // Process List
            processListSection
        }
        .frame(minWidth: 800, minHeight: 750)
        .background(VisualEffectBackground())
        .alert("Memory Manager", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog("Clean Up Memory?", isPresented: $showCleanupConfirm, titleVisibility: .visible) {
            Button("Clean Claude Zombies") {
                let killed = monitor.cleanupClaudeZombies()
                alertMessage = "Cleaned \(killed) Claude processes, saved \(String(format: "%.0f MB", monitor.lastCleanupSaved))"
                showAlert = killed > 0
            }
            Button("Trim Chrome Helpers") {
                let killed = monitor.killChromeHelpers(keepTop: 3)
                alertMessage = "Closed \(killed) Chrome helper processes"
                showAlert = killed > 0
            }
            Button("Cancel", role: .cancel) { }
        }
        // Keyboard shortcuts via NSEvent monitor
        .focusable()
        .focused($isSearchFocused)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) {
                    switch event.charactersIgnoringModifiers {
                    case "r":
                        monitor.refresh()
                        return nil
                    case "k":
                        showCleanupConfirm = true
                        return nil
                    case "f":
                        isSearchFocused = true
                        return nil
                    default:
                        break
                    }
                }
                return event
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // App Icon with gradient (draggable)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignSystem.accentGradient)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, y: 4)

                Image(systemName: "memorychip.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            .overlay(WindowDraggableArea())

            VStack(alignment: .leading, spacing: 4) {
                Text("Memory Manager")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if let machine = monitor.machineInfo {
                    HStack(spacing: 8) {
                        Label(machine.modelName, systemImage: "laptopcomputer")
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.4))
                        Text(machine.chip)
                            .fontWeight(.semibold)
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("\(machine.memoryGB) GB Unified")
                            .foregroundColor(.secondary.opacity(0.9))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status Indicator
            if let stats = monitor.memoryStats {
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(stats.pressureLevel)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignSystem.pressureColor(for: stats.usedPercent))

                        Text("Memory Pressure")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Circle()
                        .fill(DesignSystem.pressureColor(for: stats.usedPercent))
                        .frame(width: 12, height: 12)
                        .shadow(color: DesignSystem.pressureColor(for: stats.usedPercent).opacity(0.5), radius: 4)
                }
            }

            // Keyboard shortcuts hint
            HStack(spacing: 4) {
                KeyboardShortcutHint(key: "⌘R", label: "Refresh")
                KeyboardShortcutHint(key: "⌘K", label: "Cleanup")
                KeyboardShortcutHint(key: "⌘F", label: "Search")
            }
            .opacity(0.6)

            Button(action: { monitor.refresh() }) {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(monitor.isRefreshing ? 360 : 0))
                        .animation(monitor.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: monitor.isRefreshing)
                }
            }
            .buttonStyle(.plain)
            .help("Refresh (⌘R)")
        }
    }

    // MARK: - Memory Dashboard

    private var memoryDashboard: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                // Large Memory Gauge
                if let stats = monitor.memoryStats {
                    PremiumMemoryGauge(stats: stats)
                        .frame(width: 180, height: 180)

                    // Memory Breakdown Panel
                    VStack(alignment: .leading, spacing: 16) {
                        Text("MEMORY COMPOSITION")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(1)

                        // Activity Monitor-style breakdown
                        ActivityMonitorBreakdown(stats: stats)

                        // Swap indicator
                        if stats.swapUsedMB > 100 {
                            SwapIndicator(swapMB: stats.swapUsedMB)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Quick Stats Cards
                    VStack(spacing: 12) {
                        QuickStatCard(
                            title: "Available",
                            value: formatGB(stats.freeMB + stats.inactiveMB),
                            subtitle: "Can be freed",
                            color: DesignSystem.freeColor,
                            icon: "checkmark.circle.fill"
                        )

                        QuickStatCard(
                            title: "App Memory",
                            value: formatGB(stats.activeMB),
                            subtitle: "In active use",
                            color: DesignSystem.appMemoryColor,
                            icon: "app.fill"
                        )

                        QuickStatCard(
                            title: "Compressed",
                            value: formatGB(stats.compressedMB),
                            subtitle: "Memory compressor",
                            color: DesignSystem.compressedColor,
                            icon: "arrow.down.right.and.arrow.up.left"
                        )
                    }
                    .frame(width: 160)
                }
            }

            // Memory History Graph
            if let stats = monitor.memoryStats {
                MemoryHistoryGraph(
                    history: monitor.memoryHistory,
                    currentPercent: stats.usedPercent
                )
            }

            // Hero Optimize Memory Button
            if let stats = monitor.memoryStats {
                HeroOptimizeButton(
                    stats: stats,
                    isOptimizing: isOptimizing,
                    result: optimizeResult,
                    onOptimize: {
                        isOptimizing = true
                        optimizeResult = nil
                        Task {
                            let result = await monitor.smartCleanup()
                            await MainActor.run {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    optimizeResult = result
                                    isOptimizing = false
                                }
                                // Clear result after 5 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    withAnimation { optimizeResult = nil }
                                }
                            }
                        }
                    }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
        )
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("RECOMMENDATIONS")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1)
                Spacer()
            }

            HStack(spacing: 12) {
                if monitor.claudeProcessCount > 5 {
                    RecommendationCard(
                        title: "Clean Claude Processes",
                        description: "\(monitor.claudeProcessCount) processes using \(formatMB(monitor.claudeMemoryMB))",
                        icon: "terminal.fill",
                        color: .orange,
                        action: {
                            let killed = monitor.cleanupClaudeZombies()
                            alertMessage = "Cleaned \(killed) Claude processes"
                            showAlert = killed > 0
                        }
                    )
                }

                if monitor.chromeProcessCount > 8 {
                    RecommendationCard(
                        title: "Trim Chrome Helpers",
                        description: "\(monitor.chromeProcessCount) helpers using \(formatMB(monitor.chromeMemoryMB))",
                        icon: "globe",
                        color: .blue,
                        action: {
                            let killed = monitor.killChromeHelpers(keepTop: 5)
                            alertMessage = "Closed \(killed) Chrome helpers"
                            showAlert = killed > 0
                        }
                    )
                }

                if let stats = monitor.memoryStats, stats.swapUsedMB > 2000 {
                    RecommendationCard(
                        title: "High Swap Usage",
                        description: "\(formatGB(stats.swapUsedMB)) using SSD storage",
                        icon: "arrow.triangle.swap",
                        color: .purple,
                        action: nil
                    )
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Process List Section

    private var processListSection: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))

                    TextField("Search processes...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )

                Picker("", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            // Column Headers
            HStack(spacing: 0) {
                Text("PROCESS")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("MEMORY")
                    .frame(width: 100, alignment: .trailing)
                Text("CPU")
                    .frame(width: 70, alignment: .trailing)
                Text("")
                    .frame(width: 40)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color(NSColor.separatorColor).opacity(0.1))

            // Process List
            ScrollView {
                LazyVStack(spacing: 0) {
                    if monitor.isRefreshing && monitor.processGroups.isEmpty {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading processes...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else if monitor.processGroups.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "memorychip")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No processes loaded")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("System may be under heavy pressure.\nTry clicking Refresh or use Optimize Memory above.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                            Button(action: { monitor.refresh() }) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else if viewMode == .grouped {
                        ForEach(filteredGroups) { group in
                            PremiumProcessGroupRow(
                                group: group,
                                isExpanded: expandedGroups.contains(group.id),
                                isHovered: hoveredGroup == group.id,
                                onToggle: { toggleGroup(group.id) },
                                onHover: { hoveredGroup = $0 ? group.id : nil },
                                onKillProcess: { pid in monitor.killProcess(pid) },
                                onKillGroup: {
                                    let killed = monitor.killProcessGroup(group, keepTop: 1)
                                    alertMessage = "Killed \(killed) \(group.name) processes"
                                    showAlert = killed > 0
                                }
                            )
                        }
                    } else {
                        ForEach(filteredProcesses) { process in
                            PremiumProcessRow(process: process) {
                                monitor.killProcess(process.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func toggleGroup(_ id: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if expandedGroups.contains(id) {
                expandedGroups.remove(id)
            } else {
                expandedGroups.insert(id)
            }
        }
    }

    private func formatMB(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }

    private func formatGB(_ mb: Double) -> String {
        return String(format: "%.1f GB", mb / 1024)
    }
}

// MARK: - Premium Memory Gauge

struct PremiumMemoryGauge: View {
    let stats: MemoryStats
    @State private var animatedPercent: Double = 0
    @State private var pulseOpacity: Double = 0.3

    var gaugeColor: Color {
        DesignSystem.pressureColor(for: stats.usedPercent)
    }

    var body: some View {
        ZStack {
            // Outer glow ring (pulsing when high)
            if stats.usedPercent > 70 {
                Circle()
                    .stroke(gaugeColor.opacity(pulseOpacity), lineWidth: 24)
                    .blur(radius: 8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulseOpacity = 0.6
                        }
                    }
            }

            // Background ring with depth
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 18
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

            // Secondary background track
            Circle()
                .stroke(Color.gray.opacity(0.08), lineWidth: 14)

            // Progress ring with angular gradient
            Circle()
                .trim(from: 0, to: animatedPercent / 100)
                .stroke(
                    DesignSystem.gaugeGradient(for: stats.usedPercent),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: gaugeColor.opacity(0.5), radius: 10, x: 0, y: 4)

            // Highlight cap at end of progress
            Circle()
                .trim(from: max(0, animatedPercent / 100 - 0.01), to: animatedPercent / 100)
                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .blur(radius: 1)

            // Inner frosted circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.08), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .padding(24)

            // Inner content
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(stats.usedPercent)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [gaugeColor, gaugeColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("%")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(gaugeColor.opacity(0.6))
                        .offset(y: -8)
                }

                Text(stats.pressureLevel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(gaugeColor)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text("\(String(format: "%.1f", stats.usedMB / 1024)) / \(String(format: "%.0f", stats.totalMB / 1024)) GB")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.top, 2)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedPercent = stats.usedPercentDouble
            }
        }
        .onChange(of: stats.usedPercent) { newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedPercent = Double(newValue)
            }
        }
        .help(stats.pressureDescription)
    }
}

// MARK: - Activity Monitor Breakdown

struct ActivityMonitorBreakdown: View {
    let stats: MemoryStats
    @State private var animatedStats: MemoryStats?
    @State private var animationProgress: Double = 0

    private var displayStats: MemoryStats {
        animatedStats ?? stats
    }

    var body: some View {
        VStack(spacing: 12) {
            // Stacked bar with animation
            GeometryReader { geo in
                HStack(spacing: 1) {
                    Rectangle()
                        .fill(DesignSystem.appMemoryColor)
                        .frame(width: max(0, geo.size.width * (displayStats.activeMB / displayStats.totalMB)))

                    Rectangle()
                        .fill(DesignSystem.wiredColor)
                        .frame(width: max(0, geo.size.width * (displayStats.wiredMB / displayStats.totalMB)))

                    Rectangle()
                        .fill(DesignSystem.compressedColor)
                        .frame(width: max(0, geo.size.width * (displayStats.compressedMB / displayStats.totalMB)))

                    Rectangle()
                        .fill(DesignSystem.cachedColor)
                        .frame(width: max(0, geo.size.width * (displayStats.inactiveMB / displayStats.totalMB)))

                    Rectangle()
                        .fill(DesignSystem.freeColor.opacity(0.5))
                }
                .cornerRadius(4)
            }
            .frame(height: 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stats.usedPercent)

            // Legend
            HStack(spacing: 16) {
                BreakdownLegend(color: DesignSystem.appMemoryColor, label: "App", value: stats.activeMB)
                BreakdownLegend(color: DesignSystem.wiredColor, label: "Wired", value: stats.wiredMB)
                BreakdownLegend(color: DesignSystem.compressedColor, label: "Compressed", value: stats.compressedMB)
                BreakdownLegend(color: DesignSystem.cachedColor, label: "Cached", value: stats.inactiveMB)
            }
        }
    }
}

struct BreakdownLegend: View {
    let color: Color
    let label: String
    let value: Double

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                Text(String(format: "%.1fG", value / 1024))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
        }
    }
}

// MARK: - Memory History Graph

struct MemoryHistoryGraph: View {
    let history: [Double]
    let currentPercent: Int

    var pressureColor: Color {
        DesignSystem.pressureColor(for: currentPercent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MEMORY PRESSURE")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(0.8)

                Spacer()

                Text("Last 5 min")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach([100, 75, 50, 25], id: \.self) { level in
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 1)
                            Spacer()
                        }
                    }

                    // Gradient fill
                    if history.count > 1 {
                        Path { path in
                            let stepWidth = geo.size.width / CGFloat(max(history.count - 1, 1))
                            path.move(to: CGPoint(x: 0, y: geo.size.height))

                            for (index, value) in history.enumerated() {
                                let x = CGFloat(index) * stepWidth
                                let y = geo.size.height * (1 - value / 100)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }

                            path.addLine(to: CGPoint(x: CGFloat(history.count - 1) * stepWidth, y: geo.size.height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [pressureColor.opacity(0.3), pressureColor.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Line
                        Path { path in
                            let stepWidth = geo.size.width / CGFloat(max(history.count - 1, 1))

                            for (index, value) in history.enumerated() {
                                let x = CGFloat(index) * stepWidth
                                let y = geo.size.height * (1 - value / 100)

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [pressureColor.opacity(0.6), pressureColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: pressureColor.opacity(0.4), radius: 4, y: 2)

                        // Current value dot
                        if let lastValue = history.last {
                            let x = geo.size.width
                            let y = geo.size.height * (1 - lastValue / 100)

                            Circle()
                                .fill(pressureColor)
                                .frame(width: 8, height: 8)
                                .shadow(color: pressureColor.opacity(0.6), radius: 4)
                                .position(x: x, y: y)
                        }
                    } else {
                        Text("Collecting data...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Threshold lines
                    Rectangle()
                        .fill(Color(hex: "FF3B30").opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -geo.size.height * 0.85)

                    Rectangle()
                        .fill(Color(hex: "FF9500").opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -geo.size.height * 0.70)
                }
            }
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.03))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Swap Indicator

struct SwapIndicator: View {
    let swapMB: Double

    var severity: Color {
        if swapMB > 4000 { return Color(hex: "FF3B30") }
        if swapMB > 2000 { return Color(hex: "FF9500") }
        return Color(hex: "FFD60A")
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.swap")
                .foregroundColor(severity)

            Text("Swap Used:")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            Text(String(format: "%.1f GB", swapMB / 1024))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(severity)

            if swapMB > 2000 {
                Text("• High disk I/O")
                    .font(.system(size: 10))
                    .foregroundColor(severity.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(severity.opacity(0.1))
        )
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    @State private var isHovered = false

    private var tooltipText: String {
        switch title {
        case "Available":
            return "Memory that can be freed immediately if apps need it. Includes inactive cached files."
        case "App Memory":
            return "Memory currently used by running applications and their processes."
        case "Compressed":
            return "Memory compressed by macOS to make room for more data without using swap."
        default:
            return subtitle
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(isHovered ? 0.25 : 0.15))
                .cornerRadius(6)
                .animation(.easeInOut(duration: 0.15), value: isHovered)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.7 : 0.5))
        )
        .onHover { isHovered = $0 }
        .help(tooltipText)
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .disabled(action == nil)
    }
}

// MARK: - Premium Process Group Row

struct PremiumProcessGroupRow: View {
    let group: ProcessGroup
    let isExpanded: Bool
    let isHovered: Bool
    let onToggle: () -> Void
    let onHover: (Bool) -> Void
    let onKillProcess: (Int32) -> Void
    let onKillGroup: () -> Void

    var groupColor: Color {
        switch group.name {
        case "Claude": return .orange
        case "Chrome": return Color(hex: "4285F4")
        case "Safari": return Color(hex: "007AFF")
        case "Xcode": return Color(hex: "147EFB")
        case "Docker": return Color(hex: "2496ED")
        default: return .secondary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Group Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Expand indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 16)

                    // App icon
                    Image(systemName: group.icon)
                        .font(.system(size: 14))
                        .foregroundColor(groupColor)
                        .frame(width: 24, height: 24)
                        .background(groupColor.opacity(0.15))
                        .cornerRadius(6)

                    // Name and count
                    Text(group.name)
                        .font(.system(size: 13, weight: .medium))

                    Text("\(group.processCount)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(4)

                    Spacer()

                    // Memory
                    Text(formatMemory(group.totalMemoryMB))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(group.totalMemoryMB > 1000 ? .orange : .primary)
                        .frame(width: 80, alignment: .trailing)

                    // CPU
                    if group.totalCPU > 1 {
                        Text(String(format: "%.1f%%", group.totalCPU))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    } else {
                        Text("")
                            .frame(width: 50)
                    }

                    // Kill button
                    if group.processCount > 1 {
                        Button(action: onKillGroup) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.red.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .help("Kill all except main process")
                        .frame(width: 24)
                    } else {
                        Spacer().frame(width: 24)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(isHovered || isExpanded ? Color.secondary.opacity(0.05) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { onHover($0) }

            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(group.processes) { process in
                        PremiumProcessRow(process: process) {
                            onKillProcess(process.id)
                        }
                        .padding(.leading, 52)
                    }
                }
                .background(Color.secondary.opacity(0.02))
            }

            Divider()
                .padding(.leading, isExpanded ? 24 : 60)
                .opacity(0.5)
        }
    }

    private func formatMemory(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}

// MARK: - Premium Process Row

struct PremiumProcessRow: View {
    let process: AppProcess
    let onKill: () -> Void

    @State private var isHovered = false
    @State private var showKill = false
    @State private var animatedMemory: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            // Process name with subtle background
            Text(process.displayName)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)

            // PID badge
            Text("PID \(process.id)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary.opacity(isHovered ? 0.8 : 0.6))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(isHovered ? 0.1 : 0.06))
                .cornerRadius(3)
                .animation(.easeInOut(duration: 0.15), value: isHovered)

            Spacer()

            // Mini memory bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(memoryColor)
                    .frame(width: min(40, 40 * process.memoryMB / 1000), height: 4)
            }

            // Memory value
            Text(formatMemory(process.memoryMB))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(memoryColor)
                .frame(width: 70, alignment: .trailing)

            // CPU
            if process.cpu > 0.5 {
                Text(String(format: "%.1f%%", process.cpu))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(process.cpu > 50 ? Color(hex: "FF3B30") : .secondary)
                    .frame(width: 45, alignment: .trailing)
            } else {
                Text("—")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.3))
                    .frame(width: 45, alignment: .trailing)
            }

            // Kill button (only show on hover)
            Button(action: onKill) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(showKill ? 0.8 : 0.3))
            }
            .buttonStyle(.plain)
            .frame(width: 20)
            .opacity(isHovered ? 1 : 0.3)
            .onHover { showKill = $0 }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.secondary.opacity(0.06) : Color.clear)
                .padding(.horizontal, 16)
        )
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
        .onHover { isHovered = $0 }
    }

    var memoryColor: Color {
        if process.memoryMB > 500 { return Color(hex: "FF3B30") }
        if process.memoryMB > 200 { return Color(hex: "FF9500") }
        if process.memoryMB > 100 { return Color(hex: "FFD60A") }
        return Color(hex: "30D158").opacity(0.8)
    }

    private func formatMemory(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}

// MARK: - Keyboard Shortcut Hint

struct KeyboardShortcutHint: View {
    let key: String
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.1))
                )

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
}

// MARK: - Hero Optimize Button

struct HeroOptimizeButton: View {
    let stats: MemoryStats
    let isOptimizing: Bool
    let result: CleanupResult?
    let onOptimize: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var showSuccessCheck = false

    private var shouldShow: Bool {
        // Show when memory is above 50% or there's a result to display
        stats.usedPercent > 50 || result != nil
    }

    private var buttonColor: Color {
        if result != nil { return Color(hex: "30D158") }
        if stats.usedPercent > 85 { return Color(hex: "FF3B30") }
        if stats.usedPercent > 70 { return Color(hex: "FF9500") }
        return Color(hex: "007AFF")
    }

    private var buttonGradient: LinearGradient {
        if result != nil {
            return LinearGradient(
                colors: [Color(hex: "30D158"), Color(hex: "34C759")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        if stats.usedPercent > 85 {
            return LinearGradient(
                colors: [Color(hex: "FF3B30"), Color(hex: "FF6B6B")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        if stats.usedPercent > 70 {
            return LinearGradient(
                colors: [Color(hex: "FF9500"), Color(hex: "FFCC00")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return LinearGradient(
            colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        if shouldShow {
            Button(action: {
                if !isOptimizing && result == nil {
                    onOptimize()
                }
            }) {
                HStack(spacing: 16) {
                    // Icon with animation
                    ZStack {
                        if isOptimizing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else if result != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .scaleEffect(showSuccessCheck ? 1.0 : 0.5)
                                .opacity(showSuccessCheck ? 1.0 : 0.0)
                        } else {
                            Image(systemName: "bolt.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 28, height: 28)

                    // Text content
                    VStack(alignment: .leading, spacing: 2) {
                        if isOptimizing {
                            Text("Optimizing Memory...")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        } else if let result = result {
                            Text(result.killedCount > 0 ? "Freed \(String(format: "%.0f MB", result.freedMB))" : "Memory Optimized")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Text(result.killedCount > 0 ? "Cleaned \(result.killedCount) processes" : "No cleanup needed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Optimize Memory")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Text(stats.usedPercent > 85 ? "Critical • Free up space now" :
                                 stats.usedPercent > 70 ? "High usage • Recommended" :
                                 "Clean idle processes")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    Spacer()

                    // Right indicator
                    if !isOptimizing && result == nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        // Glow effect for high memory
                        if stats.usedPercent > 70 && !isOptimizing && result == nil {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(buttonColor.opacity(glowOpacity))
                                .blur(radius: 12)
                                .scaleEffect(pulseScale)
                        }

                        // Main background
                        RoundedRectangle(cornerRadius: 12)
                            .fill(buttonGradient)
                            .shadow(color: buttonColor.opacity(0.4), radius: 8, y: 4)
                    }
                )
            }
            .buttonStyle(.plain)
            .scaleEffect(isOptimizing ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOptimizing)
            .onAppear {
                if stats.usedPercent > 70 {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseScale = 1.05
                        glowOpacity = 0.5
                    }
                }
            }
            .onChange(of: result != nil) { hasResult in
                if hasResult {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showSuccessCheck = true
                    }
                } else {
                    showSuccessCheck = false
                }
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
        }
    }
}

// MARK: - Mini Sparkline

struct MiniSparkline: View {
    let data: [Double]
    let color: Color
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
                Path { path in
                    let stepWidth = geo.size.width / CGFloat(max(data.count - 1, 1))
                    let minVal = data.min() ?? 0
                    let maxVal = data.max() ?? 100
                    let range = maxVal - minVal > 0 ? maxVal - minVal : 1

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepWidth
                        let y = geo.size.height * (1 - (value - minVal) / range)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
    }
}
