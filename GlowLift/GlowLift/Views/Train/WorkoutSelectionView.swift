import SwiftUI
import SwiftData

struct WorkoutSelectionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSession.completedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var templates: [WorkoutTemplate]
    @Binding var activeSession: WorkoutSession?

    private var lastSession: WorkoutSession? {
        sessions.first { $0.isCompleted }
    }

    private var suggested: WorkoutType {
        WorkoutSequencer.suggestedNext(after: lastSession)
    }

    private var sortedTemplates: [WorkoutTemplate] {
        templates.sorted { $0.type.sequenceIndex < $1.type.sequenceIndex }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()
                scrollContent
            }
            .navigationTitle("Choose Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(GlowTheme.Colors.purple)
                }
            }
        }
    }

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: GlowTheme.Spacing.lg) {
                suggestionHeader
                workoutGrid
                Spacer(minLength: 40)
            }
            .padding(.horizontal, GlowTheme.Spacing.md)
            .padding(.top, GlowTheme.Spacing.md)
        }
    }

    private var suggestionHeader: some View {
        GlowCard(glowColor: Color(hex: suggested.colorHex), glowIntensity: 0.9) {
            HStack {
                suggestionInfo
                Spacer()
                startSuggestedButton
            }
        }
    }

    private var suggestionInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SUGGESTED")
                .font(GlowTheme.Fonts.caption(10))
                .foregroundColor(GlowTheme.Colors.textTertiary)
                .tracking(1.5)
            HStack(spacing: 6) {
                Text(suggested.emoji)
                Text(suggested.rawValue)
                    .font(GlowTheme.Fonts.headline())
                    .foregroundColor(.white)
            }
            Text(suggested.focus)
                .font(GlowTheme.Fonts.caption())
                .foregroundColor(GlowTheme.Colors.textSecondary)
        }
    }

    private var startSuggestedButton: some View {
        Button(action: { startWorkout(type: suggested) }) {
            Label("Start", systemImage: "play.fill")
                .font(GlowTheme.Fonts.subheadline())
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(GlowTheme.Colors.gradientPurple))
        }
    }

    private var workoutGrid: some View {
        VStack(alignment: .leading, spacing: GlowTheme.Spacing.md) {
            SectionHeader(title: "All Workouts")
            ForEach(sortedTemplates) { template in
                WorkoutTemplateRow(
                    template: template,
                    isSuggested: template.type == suggested,
                    onTap: { startWorkout(type: template.type) }
                )
            }
        }
    }

    private func startWorkout(type: WorkoutType) {
        guard let template = WorkoutSequencer.template(for: type, context: context) else { return }
        let session = WorkoutSequencer.createSession(from: template, context: context)
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            activeSession = session
        }
    }
}

// MARK: - Extracted row to avoid complex closure in ForEach
struct WorkoutTemplateRow: View {
    let template: WorkoutTemplate
    let isSuggested: Bool
    let onTap: () -> Void

    private var color: Color { Color(hex: template.type.colorHex) }

    var body: some View {
        GlowCard(glowColor: color, glowIntensity: isSuggested ? 0.7 : 0.3) {
            rowContent
        }
        .onTapGesture { onTap() }
    }

    private var rowContent: some View {
        HStack(spacing: GlowTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 4, height: 44)
            rowLabels
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(GlowTheme.Colors.textTertiary)
        }
    }

    private var rowLabels: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(template.type.emoji)
                Text(template.name)
                    .font(GlowTheme.Fonts.subheadline())
                    .foregroundColor(.white)
                if isSuggested {
                    nextBadge
                }
            }
            Text("\(template.exercises.count) exercises · \(template.type.focus)")
                .font(GlowTheme.Fonts.caption())
                .foregroundColor(GlowTheme.Colors.textSecondary)
        }
    }

    private var nextBadge: some View {
        Text("NEXT")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.2)))
    }
}
