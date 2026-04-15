import SwiftUI

// MARK: - GlowLift Logo
// Reusable glowing dumbbell mark. Drop anywhere in the app.

struct GlowLiftLogo: View {
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            // Outer ambient glow
            Circle()
                .fill(GlowTheme.Colors.purple.opacity(0.25))
                .frame(width: size * 1.6, height: size * 1.6)
                .blur(radius: size * 0.35)

            // Mid glow ring
            Circle()
                .fill(GlowTheme.Colors.purpleDim.opacity(0.35))
                .frame(width: size * 1.1, height: size * 1.1)
                .blur(radius: size * 0.15)

            // Icon background pill
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(
                    LinearGradient(
                        colors: [
                            GlowTheme.Colors.purpleDim,
                            GlowTheme.Colors.purple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: GlowTheme.Colors.purple.opacity(0.7), radius: size * 0.25)
                .shadow(color: GlowTheme.Colors.purple.opacity(0.4), radius: size * 0.5)

            // Dumbbell icon
            Image(systemName: "dumbbell.fill")
                .font(.system(size: size * 0.48, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: "#E0CFFF")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .white.opacity(0.6), radius: 4)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0A0A0F").ignoresSafeArea()
        VStack(spacing: 32) {
            GlowLiftLogo(size: 80)
            GlowLiftLogo(size: 48)
            GlowLiftLogo(size: 32)
        }
    }
}
