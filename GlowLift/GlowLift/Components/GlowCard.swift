import SwiftUI

// MARK: - Glow Card Container
struct GlowCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = GlowTheme.Spacing.md
    var cornerRadius: CGFloat = GlowTheme.Radius.lg
    var glowColor: Color = GlowTheme.Colors.purple
    var glowIntensity: Double = 0.5
    var showBorder: Bool = true

    init(
        padding: CGFloat = GlowTheme.Spacing.md,
        cornerRadius: CGFloat = GlowTheme.Radius.lg,
        glowColor: Color = GlowTheme.Colors.purple,
        glowIntensity: Double = 0.5,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.glowColor = glowColor
        self.glowIntensity = glowIntensity
        self.showBorder = showBorder
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(GlowTheme.Colors.gradientCard)
            )
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        glowColor.opacity(0.5),
                                        glowColor.opacity(0.1),
                                        glowColor.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
            )
            .shadow(color: glowColor.opacity(0.15 * glowIntensity), radius: 12)
    }
}

// MARK: - Glow Button
struct GlowButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: GlowButtonStyle = .primary
    var isCompact: Bool = false

    enum GlowButtonStyle {
        case primary, secondary, ghost, destructive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: GlowTheme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(isCompact ? .body : .headline)
                }
                Text(title)
                    .font(isCompact ? GlowTheme.Fonts.subheadline() : GlowTheme.Fonts.headline())
            }
            .padding(.horizontal, isCompact ? GlowTheme.Spacing.md : GlowTheme.Spacing.lg)
            .padding(.vertical, isCompact ? GlowTheme.Spacing.sm : GlowTheme.Spacing.md)
            .frame(maxWidth: style == .primary ? .infinity : nil)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: GlowTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                    .stroke(borderColor, lineWidth: style == .ghost ? 1 : 0)
            )
        }
        .buttonStyle(GlowPressStyle())
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            GlowTheme.Colors.gradientPurple
        case .secondary:
            GlowTheme.Colors.surfaceElevated
        case .ghost:
            Color.clear
        case .destructive:
            Color(hex: "#7F1D1D").opacity(0.8)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:    return .white
        case .secondary:  return GlowTheme.Colors.purple
        case .ghost:      return GlowTheme.Colors.purple
        case .destructive: return GlowTheme.Colors.error
        }
    }

    private var borderColor: Color {
        switch style {
        case .ghost: return GlowTheme.Colors.purple.opacity(0.4)
        default:     return .clear
        }
    }
}

// MARK: - Press animation style
struct GlowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Stat Chip
struct StatChip: View {
    let value: String
    let label: String
    var color: Color = GlowTheme.Colors.purple

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(GlowTheme.Fonts.headline(22))
                .foregroundColor(color)
            Text(label)
                .font(GlowTheme.Fonts.caption())
                .foregroundColor(GlowTheme.Colors.textSecondary)
        }
        .padding(.horizontal, GlowTheme.Spacing.md)
        .padding(.vertical, GlowTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(GlowTheme.Fonts.caption())
                .foregroundColor(GlowTheme.Colors.textTertiary)
                .textCase(.uppercase)
                .tracking(1.2)
            Spacer()
            if let trailing {
                Button(action: { action?() }) {
                    Text(trailing)
                        .font(GlowTheme.Fonts.caption())
                        .foregroundColor(GlowTheme.Colors.purple)
                }
            }
        }
        .padding(.horizontal, GlowTheme.Spacing.sm)
    }
}
