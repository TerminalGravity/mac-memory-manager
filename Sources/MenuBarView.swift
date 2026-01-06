import SwiftUI
import AppKit

// MARK: - Premium Menu Bar View

struct MenuBarView: View {
    @ObservedObject var monitor: MemoryMonitor
    @Environment(\.openWindow) private var openWindow
    @State private var hoveredGroup: String? = nil
    @State private var isCleaningUp = false
    @State private var cleanupResult: CleanupResult? = nil
    @State private var appearAnimation = false
    @State private var gaugeAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            // Hero Section - Memory Status
            heroSection
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Memory Breakdown
            if let stats = monitor.memoryStats {
                memoryBreakdownSection(stats: stats)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }

            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Process List
            processListSection
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Quick Actions (contextual)
            if monitor.claudeProcessCount > 3 || monitor.chromeProcessCount > 5 {
                quickActionsSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }

            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Footer
            footerSection
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
        }
        .frame(width: 340)
        .background(VibrancyBackground())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appearAnimation = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                gaugeAnimation = true
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Header row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Memory")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    if let machine = monitor.machineInfo {
                        Text("\(machine.chip) · \(machine.memoryGB) GB")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Refresh button
                Button(action: { monitor.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                        .rotationEffect(.degrees(monitor.isRefreshing ? 360 : 0))
                        .animation(
                            monitor.isRefreshing
                                ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                : .default,
                            value: monitor.isRefreshing
                        )
                }
                .buttonStyle(.plain)
            }

            // Main gauge and stats
            if let stats = monitor.memoryStats {
                HStack(spacing: 20) {
                    // Premium circular gauge
                    PremiumGauge(
                        percent: gaugeAnimation ? stats.usedPercentDouble : 0,
                        pressure: stats.pressureLevel
                    )
                    .frame(width: 88, height: 88)

                    // Stats column
                    VStack(alignment: .leading, spacing: 10) {
                        // Pressure indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(pressureColor(for: stats))
                                .frame(width: 8, height: 8)
                                .shadow(color: pressureColor(for: stats).opacity(0.5), radius: 3)

                            Text(stats.pressureLevel)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(pressureColor(for: stats))
                        }

                        // Memory values
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(formatGB(stats.usedMB))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Text("used")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Text("\(formatGB(stats.freeMB)) available")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        // Trend sparkline
                        if monitor.memoryHistory.count > 3 {
                            HStack(spacing: 6) {
                                MenuBarSparkline(
                                    data: Array(monitor.memoryHistory.suffix(20)),
                                    color: pressureColor(for: stats)
                                )
                                .frame(width: 44, height: 14)

                                trendBadge
                            }
                        }

                        // Swap warning
                        if stats.swapUsedMB > 500 {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.swap")
                                    .font(.system(size: 9, weight: .medium))
                                Text(formatGB(stats.swapUsedMB) + " swap")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(stats.swapUsedMB > 2000 ? .orange : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(stats.swapUsedMB > 2000 ? 0.12 : 0.06))
                            .cornerRadius(4)
                        }
                    }

                    Spacer(minLength: 0)
                }

                // Smart Cleanup Button
                if stats.usedPercent > 65 {
                    smartCleanupButton(stats: stats)
                        .padding(.top, 4)
                }
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : -10)
    }

    // MARK: - Premium Gauge

    private func pressureColor(for stats: MemoryStats) -> Color {
        if stats.usedPercent > 85 { return Color(hex: "FF3B30") }
        if stats.usedPercent > 70 { return Color(hex: "FF9500") }
        if stats.usedPercent > 50 { return Color(hex: "FFD60A") }
        return Color(hex: "34C759")
    }

    private var trendBadge: some View {
        let history = monitor.memoryHistory
        guard history.count >= 3 else { return AnyView(EmptyView()) }

        let recent = Array(history.suffix(5))
        let older = Array(history.suffix(10).prefix(5))
        let recentAvg = recent.reduce(0, +) / Double(max(recent.count, 1))
        let olderAvg = older.isEmpty ? recentAvg : older.reduce(0, +) / Double(older.count)
        let diff = recentAvg - olderAvg

        let (icon, color, text): (String, Color, String)
        if diff > 3 {
            (icon, color, text) = ("arrow.up", Color(hex: "FF9500"), "Rising")
        } else if diff < -3 {
            (icon, color, text) = ("arrow.down", Color(hex: "34C759"), "Falling")
        } else {
            (icon, color, text) = ("minus", .secondary, "Stable")
        }

        return AnyView(
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .bold))
                Text(text)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(4)
        )
    }

    // MARK: - Smart Cleanup Button

    private func smartCleanupButton(stats: MemoryStats) -> some View {
        Group {
            if let result = cleanupResult {
                // Success state
                HStack(spacing: 10) {
                    Image(systemName: result.freedMB > 0 ? "checkmark.circle.fill" : "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(result.freedMB > 0 ? Color(hex: "34C759") : .secondary)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(result.freedMB > 0 ? "Freed \(formatMemory(result.freedMB))" : "Memory optimized")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(result.killedCount) processes cleaned up")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "34C759").opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color(hex: "34C759").opacity(0.2), lineWidth: 1)
                        )
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            cleanupResult = nil
                        }
                    }
                }
            } else {
                // Button state
                Button(action: performSmartCleanup) {
                    HStack(spacing: 10) {
                        if isCleaningUp {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .medium))
                        }

                        Text("Optimize Memory")
                            .font(.system(size: 13, weight: .semibold))

                        Spacer()

                        Text("Safe")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        LinearGradient(
                            colors: stats.usedPercent > 85
                                ? [Color(hex: "FF3B30"), Color(hex: "FF6259")]
                                : stats.usedPercent > 75
                                    ? [Color(hex: "FF9500"), Color(hex: "FFB340")]
                                    : [Color(hex: "007AFF"), Color(hex: "5AC8FA")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(
                        color: (stats.usedPercent > 85 ? Color(hex: "FF3B30") : Color(hex: "007AFF")).opacity(0.25),
                        radius: 8,
                        y: 4
                    )
                }
                .buttonStyle(.plain)
                .disabled(isCleaningUp)
            }
        }
    }

    private func performSmartCleanup() {
        isCleaningUp = true
        cleanupResult = nil

        Task {
            let result = await monitor.smartCleanup()
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    cleanupResult = result
                    isCleaningUp = false
                }
            }
        }
    }

    // MARK: - Memory Breakdown

    private func memoryBreakdownSection(stats: MemoryStats) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Stacked bar
            GeometryReader { geo in
                HStack(spacing: 1) {
                    BreakdownSegment(
                        width: geo.size.width * CGFloat(stats.activeMB / stats.totalMB),
                        color: Color(hex: "FFD60A")
                    )
                    BreakdownSegment(
                        width: geo.size.width * CGFloat(stats.wiredMB / stats.totalMB),
                        color: Color(hex: "FF9F0A")
                    )
                    BreakdownSegment(
                        width: geo.size.width * CGFloat(stats.compressedMB / stats.totalMB),
                        color: Color(hex: "BF5AF2")
                    )
                    BreakdownSegment(
                        width: geo.size.width * CGFloat(stats.inactiveMB / stats.totalMB),
                        color: Color(hex: "64D2FF")
                    )
                    Spacer(minLength: 0)
                }
                .background(Color(hex: "34C759").opacity(0.3))
                .cornerRadius(4)
            }
            .frame(height: 10)

            // Legend
            HStack(spacing: 0) {
                BreakdownLabel(color: Color(hex: "FFD60A"), label: "App", value: formatGB(stats.activeMB))
                Spacer()
                BreakdownLabel(color: Color(hex: "FF9F0A"), label: "Wired", value: formatGB(stats.wiredMB))
                Spacer()
                BreakdownLabel(color: Color(hex: "BF5AF2"), label: "Compressed", value: formatGB(stats.compressedMB))
                Spacer()
                BreakdownLabel(color: Color(hex: "64D2FF"), label: "Cached", value: formatGB(stats.inactiveMB))
            }
        }
    }

    // MARK: - Process List

    private var processListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TOP PROCESSES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            ForEach(monitor.processGroups.prefix(5)) { group in
                ProcessRow(
                    group: group,
                    isHovered: hoveredGroup == group.id,
                    onHover: { hoveredGroup = $0 ? group.id : nil }
                )
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 8) {
            if monitor.claudeProcessCount > 3 {
                QuickAction(
                    icon: "terminal.fill",
                    label: "Claude",
                    count: monitor.claudeProcessCount,
                    color: .orange
                ) {
                    let _ = monitor.cleanupClaudeZombies()
                }
            }

            if monitor.chromeProcessCount > 5 {
                QuickAction(
                    icon: "globe",
                    label: "Chrome",
                    count: monitor.chromeProcessCount,
                    color: Color(hex: "4285F4")
                ) {
                    let _ = monitor.killChromeHelpers(keepTop: 3)
                }
            }

            Spacer()
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            PremiumFooterButton(
                icon: "macwindow",
                label: "Open Window",
                action: {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
            )

            Spacer()

            PremiumQuitButton()
        }
    }
}

// MARK: - Premium Footer Button

struct PremiumFooterButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isHovered ? Color(hex: "007AFF") : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isHovered ? Color(hex: "007AFF").opacity(0.1) : Color.primary.opacity(0.06))

                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    isHovered ? Color(hex: "007AFF").opacity(0.3) : Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .shadow(color: isHovered ? Color(hex: "007AFF").opacity(0.2) : Color.clear, radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Premium Quit Button

struct PremiumQuitButton: View {
    @State private var isHovered = false

    var body: some View {
        Button(action: { NSApp.terminate(nil) }) {
            Text("Quit")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(isHovered ? .red : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Helpers (Extension)

private extension MenuBarView {
    func formatGB(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }

    private func formatMemory(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}

// MARK: - Premium Gauge Component

struct PremiumGauge: View {
    let percent: Double
    let pressure: String

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3

    private var gaugeColor: Color {
        if percent > 85 { return Color(hex: "FF3B30") }
        if percent > 70 { return Color(hex: "FF9500") }
        if percent > 50 { return Color(hex: "FFD60A") }
        return Color(hex: "34C759")
    }

    var body: some View {
        ZStack {
            // Outer glow for high pressure
            if percent > 70 {
                Circle()
                    .fill(gaugeColor.opacity(glowOpacity * 0.4))
                    .blur(radius: 12)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulseScale = 1.1
                            glowOpacity = 0.7
                        }
                    }
            }

            // Background ring with inset effect
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.black.opacity(0.1), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 10
                )

            // Track
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: 8)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: percent / 100)
                .stroke(
                    AngularGradient(
                        colors: [
                            gaugeColor.opacity(0.5),
                            gaugeColor,
                            gaugeColor.opacity(0.9)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: gaugeColor.opacity(0.5), radius: 6)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: percent)

            // Shimmer effect
            Circle()
                .trim(from: max(0, percent / 100 - 0.1), to: percent / 100)
                .stroke(
                    Color.white.opacity(0.4),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 1)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: percent)

            // Center content
            VStack(spacing: -2) {
                Text("\(Int(percent))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [gaugeColor, gaugeColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: gaugeColor.opacity(0.3), radius: 4, y: 1)
                Text("%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(gaugeColor.opacity(0.6))
            }
        }
    }
}

// MARK: - Menu Bar Sparkline

struct MenuBarSparkline: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
                let minVal = max((data.min() ?? 0) - 5, 0)
                let maxVal = min((data.max() ?? 100) + 5, 100)
                let range = max(maxVal - minVal, 1)

                ZStack {
                    // Fill
                    Path { path in
                        let stepWidth = geo.size.width / CGFloat(max(data.count - 1, 1))
                        path.move(to: CGPoint(x: 0, y: geo.size.height))

                        for (i, value) in data.enumerated() {
                            let x = CGFloat(i) * stepWidth
                            let y = geo.size.height * (1 - (value - minVal) / range)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }

                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        let stepWidth = geo.size.width / CGFloat(max(data.count - 1, 1))

                        for (i, value) in data.enumerated() {
                            let x = CGFloat(i) * stepWidth
                            let y = geo.size.height * (1 - (value - minVal) / range)

                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}

// MARK: - Breakdown Components

struct BreakdownSegment: View {
    let width: CGFloat
    let color: Color

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: max(0, width))
    }
}

struct BreakdownLabel: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Process Row

struct ProcessRow: View {
    let group: ProcessGroup
    let isHovered: Bool
    let onHover: (Bool) -> Void

    private var iconColor: Color {
        switch group.name {
        case "Claude": return .orange
        case "Chrome": return Color(hex: "4285F4")
        case "Safari": return Color(hex: "007AFF")
        case "Xcode": return Color(hex: "147EFB")
        case "Docker": return Color(hex: "2496ED")
        case "Cursor": return Color(hex: "007ACC")
        case "Electron": return Color(hex: "47848F")
        case "VS Code": return Color(hex: "007ACC")
        case "Finder": return Color(hex: "4DB6F3")
        case "Terminal": return Color(hex: "2D3436")
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Premium icon with glow
            ZStack {
                if isHovered {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 26, height: 26)
                        .blur(radius: 3)
                }

                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.18), iconColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)

                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(iconColor.opacity(isHovered ? 0.35 : 0.15), lineWidth: 1)
                    .frame(width: 24, height: 24)

                Image(systemName: group.icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            .scaleEffect(isHovered ? 1.08 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)

            // Name with highlight
            Text(group.name)
                .font(.system(size: 12, weight: isHovered ? .semibold : .medium, design: .rounded))
                .foregroundColor(isHovered ? iconColor : .primary)
                .lineLimit(1)
                .animation(.easeInOut(duration: 0.15), value: isHovered)

            // Process count badge
            if group.processCount > 1 {
                Text("×\(group.processCount)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(isHovered ? .white.opacity(0.9) : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isHovered ? iconColor.opacity(0.8) : Color.secondary.opacity(0.1))
                    )
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
            }

            Spacer()

            // Memory with visual indicator
            HStack(spacing: 6) {
                // Mini memory bar
                if isHovered {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(memoryColor(group.totalMemoryMB))
                        .frame(width: min(30, CGFloat(group.totalMemoryMB / 100)), height: 4)
                        .transition(.scale.combined(with: .opacity))
                }

                Text(formatMemory(group.totalMemoryMB))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(memoryColor(group.totalMemoryMB))
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? iconColor.opacity(0.06) : Color.clear)
                .padding(.horizontal, 12)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
        .onHover { onHover($0) }
    }

    private func memoryColor(_ mb: Double) -> Color {
        if mb > 2000 { return Color(hex: "FF3B30") }
        if mb > 1500 { return Color(hex: "FF9500") }
        if mb > 800 { return Color(hex: "FFD60A") }
        return .secondary
    }

    private func formatMemory(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}

// MARK: - Quick Action Button

struct QuickAction: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .medium))
                Text("Clean \(label)")
                    .font(.system(size: 10, weight: .medium))
                Text("(\(count))")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(color.opacity(0.7))
            }
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? color.opacity(0.15) : color.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Vibrancy Background

struct VibrancyBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
