import SwiftUI

struct GlowTheme {
    struct Colors {
        static let background       = Color(hex: "#080F0A")
        static let surface          = Color(hex: "#0D1510")
        static let surfaceElevated  = Color(hex: "#142018")
        static let surfaceCard      = Color(hex: "#10180E80")

        static let purple           = Color(hex: "#4ADE80")
        static let purpleLight      = Color(hex: "#86EFAC")
        static let purpleDim        = Color(hex: "#16A34A")
        static let purpleGlow       = Color(hex: "#4ADE80").opacity(0.35)
        static let purpleDeep       = Color(hex: "#052E16")

        static let accent            = Color(hex: "#34D399")
        static let accentBlue        = Color(hex: "#818CF8")

        static let textPrimary       = Color.white
        static let textSecondary     = Color(hex: "#A0C0A8")
        static let textTertiary      = Color(hex: "#608070")
        static let textMuted         = Color(hex: "#3A5040")

        static let success           = Color(hex: "#4ADE80")
        static let warning           = Color(hex: "#FBBF24")
        static let error             = Color(hex: "#F87171")
        static let info              = Color(hex: "#60A5FA")

        static let timerActive       = Color(hex: "#4ADE80")
        static let timerWarning      = Color(hex: "#FBBF24")
        static let timerCritical     = Color(hex: "#F87171")

        static let gradientPurple    = LinearGradient(
            colors: [Color(hex: "#16A34A"), Color(hex: "#4ADE80")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let gradientAccent    = LinearGradient(
            colors: [Color(hex: "#4ADE80"), Color(hex: "#86EFAC")],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let gradientBackground = LinearGradient(
            colors: [Color(hex: "#080F0A"), Color(hex: "#08120A")],
            startPoint: .top,
            endPoint: .bottom
        )
        static let gradientCard = LinearGradient(
            colors: [Color(hex: "#0D1F15"), Color(hex: "#080F0A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

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

    struct Spacing {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 24
        static let xl: CGFloat  = 32
        static let xxl: CGFloat = 48
    }

    struct Radius {
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 12
        static let lg: CGFloat  = 16
        static let xl: CGFloat  = 24
        static let pill: CGFloat = 100
    }
}

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
