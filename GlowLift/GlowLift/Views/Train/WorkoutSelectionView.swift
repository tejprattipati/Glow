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

    private var suggestionHeader: some View {
        GlowCard(glowColor: Color(hex: suggested.colorHex), glowIntensity: 0.9) {
            HStack {
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
                Spacer()
                Button(action: { startWorkout(type: suggested) }) {
                    Label("Start", systemImage: "play.fill")
                        .font(GlowTheme.Fonts.subheadline())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(GlowTheme.Colors.gradientPurple))
                }
            }
        }
    }

    private var workoutGrid: some View {
        VStack(alignment: .leading, spacing: GlowTheme.Spacing.md) {
            SectionHeader(title: "All Workouts")
            ForEach(sortedTemplates) { template in
                workoutCard(template)
            }
        }
    }

    private func workoutCard(_ template: WorkoutTemplate) -> some View {
        let isSuggested = template.type == suggested
        let color = Color(hex: template.type.colorHex)
        return GlowCard(glowColor: color, glowIntensity: isSuggested ? 0.7 : 0.3) {
            HStack(spacing: GlowTheme.Spacing.md) {
                // Color swatch
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 4, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(template.type.emoji)
                        Text(template.name)
                            .font(GlowTheme.Fonts.subheadline())
                            .foregroundColor(.white)
                        if isSuggested {
                            Text("NEXT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(color.opacity(0.2)))
                        }
                    }
                    Text("\(template.exercises.count) exercises · \(template.type.focus)")
                        .font(GlowTheme.Fonts.caption())
                        .foregroundColor(GlowTheme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(GlowTheme.Colors.textTertiary)
            }
        }
        .onTapGesture { startWorkout(type: template.type) }
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
