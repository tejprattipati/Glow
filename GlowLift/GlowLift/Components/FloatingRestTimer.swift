import SwiftUI

// MARK: - Floating Rest Timer Overlay
// Shown as a sticky pill at the top of the screen during any tab.

struct FloatingRestTimerBar: View {
    @ObservedObject var timer: RestTimerManager
    @State private var expanded = false

    var body: some View {
        if timer.isVisible {
            VStack(spacing: 0) {
                // Pill bar
                Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { expanded.toggle() } }) {
                    HStack(spacing: GlowTheme.Spacing.sm) {
                        Image(systemName: timer.isRunning && !timer.isPaused ? "timer" : timer.completedOnce ? "checkmark.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(timerColor)

                        Text(timer.completedOnce ? "Rest Complete!" : timer.displayTime)
                            .font(GlowTheme.Fonts.mono(16))
                            .foregroundColor(timerColor)
                            .glowEffect(color: timerColor, radius: 8, intensity: 0.8)

                        if !timer.completedOnce {
                            // Mini progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(GlowTheme.Colors.textMuted.opacity(0.3))
                                    Capsule()
                                        .fill(timerColor)
                                        .frame(width: geo.size.width * CGFloat(timer.progress))
                                        .animation(.linear(duration: 0.3), value: timer.progress)
                                }
                            }
                            .frame(height: 4)
                        }

                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(GlowTheme.Colors.textTertiary)
                    }
                    .padding(.horizontal, GlowTheme.Spacing.md)
                    .padding(.vertical, GlowTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(GlowTheme.Colors.surface)
                            .overlay(
                                Capsule()
                                    .stroke(timerColor.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .shadow(color: timerColor.opacity(0.3), radius: 8)
                }
                .padding(.horizontal, GlowTheme.Spacing.md)
                .padding(.top, GlowTheme.Spacing.sm)

                // Expanded controls
                if expanded {
                    expandedControls
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    @ViewBuilder
    private var expandedControls: some View {
        GlowCard(padding: GlowTheme.Spacing.md, glowColor: timerColor) {
            VStack(spacing: GlowTheme.Spacing.md) {
                // Big time display
                Text(timer.completedOnce ? "Done!" : timer.displayTime)
                    .font(GlowTheme.Fonts.mono(48))
                    .foregroundColor(timerColor)
                    .glowEffect(color: timerColor, radius: 16, intensity: 1.0)

                // Presets
                HStack(spacing: GlowTheme.Spacing.sm) {
                    ForEach(Array(zip(RestTimerManager.presets, RestTimerManager.presetLabels)), id: \.0) { sec, label in
                        Button(action: { timer.start(seconds: sec) }) {
                            Text(label)
                                .font(GlowTheme.Fonts.caption(13))
                                .foregroundColor(GlowTheme.Colors.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: GlowTheme.Radius.sm)
                                        .fill(timer.totalSeconds == sec ? timerColor.opacity(0.25) : GlowTheme.Colors.surfaceElevated)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: GlowTheme.Radius.sm)
                                                .stroke(timer.totalSeconds == sec ? timerColor.opacity(0.6) : Color.clear, lineWidth: 1)
                                        )
                                )
                        }
                    }
                }

                // Control buttons
                HStack(spacing: GlowTheme.Spacing.md) {
                    // Restart
                    timerButton(icon: "arrow.counterclockwise", label: "Restart") {
                        timer.restart()
                    }
                    // Pause/Resume
                    timerButton(icon: timer.isPaused ? "play.fill" : "pause.fill",
                               label: timer.isPaused ? "Resume" : "Pause") {
                        timer.togglePause()
                    }
                    // Skip
                    timerButton(icon: "forward.fill", label: "Skip") {
                        timer.skip()
                        expanded = false
                    }
                    // Dismiss
                    timerButton(icon: "xmark", label: "Dismiss") {
                        timer.dismiss()
                        expanded = false
                    }
                }
            }
        }
        .padding(.horizontal, GlowTheme.Spacing.md)
        .padding(.top, GlowTheme.Spacing.sm)
    }

    private func timerButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(GlowTheme.Fonts.caption(10))
            }
            .foregroundColor(GlowTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, GlowTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: GlowTheme.Radius.sm)
                    .fill(GlowTheme.Colors.surfaceElevated)
            )
        }
    }

    private var timerColor: Color {
        if timer.completedOnce { return GlowTheme.Colors.success }
        let ratio = Double(timer.remainingSeconds) / max(Double(timer.totalSeconds), 1)
        if ratio > 0.5 { return GlowTheme.Colors.purple }
        if ratio > 0.25 { return GlowTheme.Colors.warning }
        return GlowTheme.Colors.error
    }
}
