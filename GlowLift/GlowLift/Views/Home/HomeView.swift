import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.completedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var streakStates: [StreakState]
    @Query private var preferences: [UserPreferences]
    @ObservedObject private var timerManager = RestTimerManager.shared

    @State private var showWorkoutPicker = false
    @State private var selectedSession: WorkoutSession?
    @State private var activeSession: WorkoutSession?

    private var lastSession: WorkoutSession? {
        sessions.first { $0.isCompleted }
    }

    private var inProgressSession: WorkoutSession? {
        sessions.first { !$0.isCompleted }
    }

    private var suggestedNext: WorkoutType {
        WorkoutSequencer.suggestedNext(after: lastSession)
    }

    private var streak: StreakState? { streakStates.first }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                GlowTheme.Colors.gradientBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GlowTheme.Spacing.lg) {
                        headerSection
                        streakSection
                        suggestedWorkoutSection
                        if let inProgress = inProgressSession {
                            resumeSessionBanner(inProgress)
                        }
                        recentSessionsSection
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, GlowTheme.Spacing.md)
                    .padding(.top, GlowTheme.Spacing.md)
                }

                // Floating timer
                VStack {
                    FloatingRestTimerBar(timer: timerManager)
                    Spacer()
                }
            }
            .navigationTitle("GlowLift")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showWorkoutPicker) {
                WorkoutSelectionView(activeSession: $activeSession)
            }
            .navigationDestination(item: $activeSession) { session in
                ActiveWorkoutView(session: session)
            }
        }
        .onAppear { refreshStreak() }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.textTertiary)
                Text("Ready to train?")
                    .font(GlowTheme.Fonts.display(28))
                    .foregroundColor(GlowTheme.Colors.textPrimary)
            }
            Spacer()
            GlowLiftLogo(size: 48)
        }
    }

    // MARK: - Streak
    private var streakSection: some View {
        GlowCard(glowColor: GlowTheme.Colors.purple, glowIntensity: 0.7) {
            HStack(spacing: GlowTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(GlowTheme.Colors.accent)
                        Text("Streak")
                            .font(GlowTheme.Fonts.subheadline())
                            .foregroundColor(GlowTheme.Colors.textPrimary)
                    }
                    Text(streak?.streakStatusDescription ?? "Start your first session!")
                        .font(GlowTheme.Fonts.caption())
                        .foregroundColor(GlowTheme.Colors.textSecondary)
                }
                Spacer()
                HStack(spacing: GlowTheme.Spacing.md) {
                    StatChip(
                        value: "\(streak?.currentFlowStreak ?? 0)",
                        label: "Flow",
                        color: GlowTheme.Colors.accent
                    )
                    StatChip(
                        value: "\(streak?.totalSessionsThisMonth ?? 0)",
                        label: "Month",
                        color: GlowTheme.Colors.accentBlue
                    )
                }
            }
        }
    }

    // MARK: - Suggested Workout
    private var suggestedWorkoutSection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.Spacing.md) {
            SectionHeader(title: "Next Workout")

            GlowCard(glowColor: Color(hex: suggestedNext.colorHex), glowIntensity: 0.8) {
                VStack(alignment: .leading, spacing: GlowTheme.Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(suggestedNext.emoji)
                                    .font(.title2)
                                Text(suggestedNext.rawValue)
                                    .font(GlowTheme.Fonts.headline(22))
                                    .foregroundColor(.white)
                            }
                            Text(suggestedNext.focus)
                                .font(GlowTheme.Fonts.subheadline(14))
                                .foregroundColor(GlowTheme.Colors.textSecondary)
                        }
                        Spacer()
                        if let last = lastSession {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Last trained")
                                    .font(GlowTheme.Fonts.caption(11))
                                    .foregroundColor(GlowTheme.Colors.textTertiary)
                                Text(relativeDate(last.completedAt ?? last.startedAt))
                                    .font(GlowTheme.Fonts.caption(12))
                                    .foregroundColor(GlowTheme.Colors.textSecondary)
                            }
                        }
                    }

                    HStack(spacing: GlowTheme.Spacing.sm) {
                        GlowButton(title: "Start \(suggestedNext.rawValue)", icon: "play.fill") {
                            startSuggestedWorkout()
                        }
                        // Icon-only choose button — avoids two-line text wrap
                        Button(action: { showWorkoutPicker = true }) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(GlowTheme.Colors.purple)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                                        .fill(GlowTheme.Colors.surfaceElevated)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                                                .stroke(GlowTheme.Colors.purple.opacity(0.35), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(GlowPressStyle())
                    }
                }
            }
        }
    }

    // MARK: - Resume Banner
    private func resumeSessionBanner(_ session: WorkoutSession) -> some View {
        GlowCard(glowColor: GlowTheme.Colors.warning, glowIntensity: 0.9) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(GlowTheme.Colors.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Session In Progress")
                        .font(GlowTheme.Fonts.subheadline())
                        .foregroundColor(.white)
                    Text(session.workoutName)
                        .font(GlowTheme.Fonts.caption())
                        .foregroundColor(GlowTheme.Colors.textSecondary)
                }
                Spacer()
                Button("Resume") { activeSession = session }
                    .font(GlowTheme.Fonts.subheadline())
                    .foregroundColor(GlowTheme.Colors.warning)
            }
        }
    }

    // MARK: - Recent Sessions
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.Spacing.md) {
            SectionHeader(title: "Recent Sessions")
            let completed = sessions.filter { $0.isCompleted }.prefix(5)
            if completed.isEmpty {
                emptySessionsHint
            } else {
                ForEach(Array(completed)) { session in
                    sessionRow(session)
                }
            }
        }
    }

    private func sessionRow(_ session: WorkoutSession) -> some View {
        GlowCard(padding: GlowTheme.Spacing.md, glowIntensity: 0.3) {
            HStack {
                Text(session.type.emoji)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.workoutName)
                        .font(GlowTheme.Fonts.subheadline())
                        .foregroundColor(GlowTheme.Colors.textPrimary)
                    Text("\(session.totalSets) sets · \(session.durationDisplay)")
                        .font(GlowTheme.Fonts.caption())
                        .foregroundColor(GlowTheme.Colors.textSecondary)
                }
                Spacer()
                Text(session.completedAt.map { relativeDate($0) } ?? "")
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.textTertiary)
            }
        }
    }

    private var emptySessionsHint: some View {
        GlowCard(glowIntensity: 0.2) {
            VStack(spacing: GlowTheme.Spacing.sm) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title)
                    .foregroundColor(GlowTheme.Colors.purpleDim)
                Text("No sessions yet")
                    .font(GlowTheme.Fonts.subheadline())
                    .foregroundColor(GlowTheme.Colors.textSecondary)
                Text("Start your first workout to see history here.")
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, GlowTheme.Spacing.md)
        }
    }

    // MARK: - Helpers
    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func startSuggestedWorkout() {
        guard let template = WorkoutSequencer.template(for: suggestedNext, context: context) else { return }
        let session = WorkoutSequencer.createSession(from: template, context: context)
        activeSession = session
    }

    private func refreshStreak() {
        guard let state = streak, let prefs = preferences.first else { return }
        let allSessions = Array(sessions)
        let specialDays: [SpecialCircumstanceDay] = (try? context.fetch(FetchDescriptor<SpecialCircumstanceDay>())) ?? []
        StreakEngine.recalculate(sessions: allSessions, specialDays: specialDays, preferences: prefs, streakState: state)
        try? context.save()
    }
}
