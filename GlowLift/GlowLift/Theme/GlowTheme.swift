import SwiftUI

// MARK: - GlowLift Design System

struct GlowTheme {
    // MARK: Colors
    struct Colors {
        static let background       = Color(hex: "#0A0A0F")
        static let surface          = Color(hex: "#12121A")
        static let surfaceElevated  = Color(hex: "#1A1A26")
        static let surfaceCard      = Color(hex: "#16162080")

        static let purple           = Color(hex: "#A855F7")
        static let purpleLight      = Color(hex: "#C084FC")
        static let purpleDim        = Color(hex: "#7C3AED")
        static let purpleGlow       = Color(hex: "#A855F7").opacity(0.35)
        static let purpleDeep       = Color(hex: "#4C1D95")

        static let accent            = Color(hex: "#E879F9")
        static let accentBlue        = Color(hex: "#818CF8")

        static let textPrimary       = Color.white
        static let textSecondary     = Color(hex: "#A0A0C0")
        static let textTertiary      = Color(hex: "#6060A0")
        static let textMuted         = Color(hex: "#404060")

        static let success           = Color(hex: "#34D399")
        static let warning           = Color(hex: "#FBBF24")
        static let error             = Color(hex: "#F87171")
        static let info              = Color(hex: "#60A5FA")

        static let timerActive       = Color(hex: "#A855F7")
        static let timerWarning      = Color(hex: "#FBBF24")
        static let timerCritical     = Color(hex: "#F87171")

        static let gradientPurple    = LinearGradient(
            colors: [Color(hex: "#7C3AED"), Color(hex: "#A855F7")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let gradientAccent    = LinearGradient(
            colors: [Color(hex: "#A855F7"), Color(hex: "#E879F9")],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let gradientBackground = LinearGradient(
            colors: [Color(hex: "#0A0A0F"), Color(hex: "#0F0A1A")],
            startPoint: .top,
            endPoint: .bottom
        )
        static let gradientCard = LinearGradient(
            colors: [Color(hex: "#1A1A2E"), Color(hex: "#12121A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Typography
    struct Fonts {
        static func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .black, design: .rounded)
        }
        static func headline(_ size: CGFloat = 20) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        static func subheadline(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
        static func body(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .regular, design: .rounded)
        }
        static func caption(_ size: CGFloat = 12) -> Font {
            .system(size: size, weight: .medium, design: .rounded)
        }
        static func mono(_ size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .monospaced)
        }
        static func timerDisplay() -> Font {
            .system(size: 72, weight: .black, design: .monospaced)
        }
    }

    // MARK: Spacing
    struct Spacing {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 24
        static let xl: CGFloat  = 32
        static let xxl: CGFloat = 48
    }

    // MARK: Corner Radii
    struct Radius {
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 12
        static let lg: CGFloat  = 16
        static let xl: CGFloat  = 24
        static let pill: CGFloat = 100
    }
}

// MARK: - Color Hex Extension
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

// MARK: - Glow Modifiers
struct GlowEffect: ViewModifier {
    var color: Color = GlowTheme.Colors.purple
    var radius: CGFloat = 12
    var intensity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6 * intensity), radius: radius * 0.5)
            .shadow(color: color.opacity(0.3 * intensity), radius: radius)
            .shadow(color: color.opacity(0.15 * intensity), radius: radius * 2)
    }
}

struct PurpleGlowBorder: ViewModifier {
    var cornerRadius: CGFloat = GlowTheme.Radius.lg
    var width: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                GlowTheme.Colors.purple.opacity(0.6),
                                GlowTheme.Colors.purpleLight.opacity(0.2),
                                GlowTheme.Colors.purple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: width
                    )
            )
    }
}

extension View {
    func glowEffect(color: Color = GlowTheme.Colors.purple, radius: CGFloat = 12, intensity: Double = 1.0) -> some View {
        modifier(GlowEffect(color: color, radius: radius, intensity: intensity))
    }
    func purpleGlowBorder(cornerRadius: CGFloat = GlowTheme.Radius.lg, width: CGFloat = 1) -> some View {
        modifier(PurpleGlowBorder(cornerRadius: cornerRadius, width: width))
    }
}
