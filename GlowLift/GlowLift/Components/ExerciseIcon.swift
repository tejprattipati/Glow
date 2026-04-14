import SwiftUI

// MARK: - Exercise Icon View
// Maps each ExerciseCategory to a styled SF Symbol badge.

struct ExerciseIcon: View {
    let category: ExerciseCategory
    var size: CGFloat = 36
    var showBackground: Bool = true

    private var color: Color {
        switch category {
        case .chestPress, .inclinePress, .fly:
            return Color(hex: "#A855F7")
        case .shoulderPress, .lateralRaise:
            return Color(hex: "#818CF8")
        case .triceps:
            return Color(hex: "#E879F9")
        case .pulldown, .row:
            return Color(hex: "#60A5FA")
        case .rearDelt, .shrug:
            return Color(hex: "#34D399")
        case .curl:
            return Color(hex: "#F472B6")
        case .legPress, .squat:
            return Color(hex: "#FBBF24")
        case .legCurl, .rdl:
            return Color(hex: "#FB923C")
        case .calfRaise:
            return Color(hex: "#A3E635")
        case .abs:
            return Color(hex: "#22D3EE")
        case .other:
            return Color(hex: "#94A3B8")
        }
    }

    var body: some View {
        ZStack {
            if showBackground {
                RoundedRectangle(cornerRadius: size * 0.28)
                    .fill(color.opacity(0.15))
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.28)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            }
            Image(systemName: category.sfSymbol)
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(width: showBackground ? size : size * 0.7,
               height: showBackground ? size : size * 0.7)
    }
}

// MARK: - Exercise Row (reusable)
struct ExerciseRowHeader: View {
    let name: String
    let category: ExerciseCategory
    var lastPerformance: String? = nil

    var body: some View {
        HStack(spacing: GlowTheme.Spacing.md) {
            ExerciseIcon(category: category, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(GlowTheme.Fonts.subheadline())
                    .foregroundColor(GlowTheme.Colors.textPrimary)
                if let last = lastPerformance {
                    Text("Last: \(last)")
                        .font(GlowTheme.Fonts.caption())
                        .foregroundColor(GlowTheme.Colors.textTertiary)
                }
            }
            Spacer()
        }
    }
}
