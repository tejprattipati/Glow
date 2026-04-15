import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var timerManager = RestTimerManager.shared

    var session: WorkoutSession

    @State private var activeExerciseIndex: Int = 0
    @State private var showFinishAlert = false
    @State private var elapsedSeconds: Int = 0
    @State private var elapsedTimer: Timer?
    @State private var showAddSet = false
    @State private var selectedExercise: ExerciseSession?

    private var sortedExercises: [ExerciseSession] {
        session.sortedExercises
    }

    private var currentExercise: ExerciseSession? {
        guard activeExerciseIndex < sortedExercises.count else { return nil }
        return sortedExercises[activeExerciseIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GlowTheme.Spacing.lg) {
                        workoutHeader
                        exerciseList
                        finishButton
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, GlowTheme.Spacing.md)
                    .padding(.top, GlowTheme.Spacing.sm)
                }

                VStack {
                    FloatingRestTimerBar(timer: timerManager)
                    Spacer()
                }
            }
            .navigationTitle(session.workoutName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showFinishAlert = true }) {
                        Image(systemName: "xmark")
                            .foregroundColor(GlowTheme.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(elapsedDisplay)
                        .font(GlowTheme.Fonts.mono(14))
                        .foregroundColor(GlowTheme.Colors.textTertiary)
                }
            }
            .alert("Finish Workout?", isPresented: $showFinishAlert) {
                Button("Save & Finish") { finishWorkout() }
                Button("Discard", role: .destructive) { discardAndDismiss() }
                Button("Keep Training", role: .cancel) {}
            } message: {
                Text("You've logged \(session.totalSets) sets.")
            }
            .sheet(item: $selectedExercise) { exercise in
                SetLoggingSheet(
                    exercise: exercise,
                    session: session,
                    onSetLogged: { weight, reps in
                        logSet(exercise: exercise, weight: weight, reps: reps)
                    }
                )
            }
        }
        .onAppear { startElapsedTimer() }
        .onDisappear { elapsedTimer?.invalidate() }
    }

    // MARK: - Header
    private var workoutHeader: some View {
        GlowCard(glowColor: Color(hex: session.type.colorHex), glowIntensity: 0.6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.type.emoji)
                        Text(session.type.rawValue)
                            .font(GlowTheme.Fonts.caption(11))
                            .foregroundColor(GlowTheme.Colors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                    Text(session.workoutName)
                        .font(GlowTheme.Fonts.headline())
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    StatChip(value: "\(session.totalSets)", label: "Sets", color: Color(hex: session.type.colorHex))
                    Text("\(sortedExercises.filter { $0.isCompleted }.count)/\(sortedExercises.count) done")
                        .font(GlowTheme.Fonts.caption(11))
                        .foregroundColor(GlowTheme.Colors.textTertiary)
                }
            }
        }
    }

    // MARK: - Exercise List
    private var exerciseList: some View {
        VStack(spacing: GlowTheme.Spacing.sm) {
            SectionHeader(title: "Exercises")
            ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                exerciseCardRow(exercise, index: index)
            }
        }
    }

    @ViewBuilder
    private func exerciseCardRow(_ exercise: ExerciseSession, index: Int) -> some View {
        ExerciseCard(
            exercise: exercise,
            isActive: index == activeExerciseIndex,
            context: context,
            onAddSet: {
                activeExerciseIndex = index
                selectedExercise = exercise
            },
            onStartTimer: { seconds in
                timerManager.start(seconds: seconds)
            },
            onMarkComplete: {
                withAnimation {
                    exercise.isCompleted = true
                    exercise.completedAt = Date()
                    let count = sortedExercises.count
                    if index < count - 1 {
                        activeExerciseIndex = index + 1
                    }
                    try? context.save()
                }
            }
        )
    }

    // MARK: - Finish
    private var finishButton: some View {
        GlowButton(title: "Finish Workout", icon: "checkmark.circle.fill") {
            showFinishAlert = true
        }
        .glowEffect(color: GlowTheme.Colors.success, radius: 12, intensity: 0.8)
    }

    // MARK: - Helpers
    private var elapsedDisplay: String {
        let m = elapsedSeconds / 60
        let h = m / 60
        let rm = m % 60
        if h > 0 { return "\(h)h \(rm)m" }
        return "\(m)m"
    }

    private func startElapsedTimer() {
        let start = session.startedAt
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            elapsedSeconds = Int(Date().timeIntervalSince(start))
        }
        elapsedSeconds = Int(Date().timeIntervalSince(start))
    }

    private func logSet(exercise: ExerciseSession, weight: Double, reps: Int) {
        let nextNum = exercise.sortedSets.count + 1
        let entry = SetEntry(setNumber: nextNum, weight: weight, reps: reps)
        entry.exerciseSession = exercise
        exercise.sets.append(entry)
        try? context.save()

        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Auto-start rest timer
        let restSeconds = exercise.sets.isEmpty ? 120 : exercise.category.defaultRestSeconds
        timerManager.start(seconds: restSeconds)
    }

    private func finishWorkout() {
        session.completedAt = Date()
        session.isCompleted = true
        try? context.save()
        dismiss()
    }

    private func discardAndDismiss() {
        context.delete(session)
        try? context.save()
        dismiss()
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    var exercise: ExerciseSession
    let isActive: Bool
    let context: ModelContext
    let onAddSet: () -> Void
    let onStartTimer: (Int) -> Void
    let onMarkComplete: () -> Void

    @State private var isExpanded = true

    private var lastSession: ExerciseSession? {
        WorkoutSequencer.lastExerciseSession(named: exercise.exerciseName, context: context)
    }

    var body: some View {
        let accentColor = isActive ? GlowTheme.Colors.purple : (exercise.isCompleted ? GlowTheme.Colors.success : GlowTheme.Colors.textMuted)

        GlowCard(glowColor: accentColor, glowIntensity: isActive ? 0.8 : 0.2, showBorder: isActive) {
            VStack(spacing: GlowTheme.Spacing.sm) {
                // Header row
                HStack {
                    ExerciseIcon(category: exercise.category, size: 38)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.exerciseName)
                            .font(GlowTheme.Fonts.subheadline())
                            .foregroundColor(.white)
                        if let last = lastSession, let topSet = last.topSet {
                            Text("Last: \(topSet.displayString) · \(last.setCount) sets")
                                .font(GlowTheme.Fonts.caption(11))
                                .foregroundColor(GlowTheme.Colors.textTertiary)
                        }
                    }

                    Spacer()

                    HStack(spacing: GlowTheme.Spacing.sm) {
                        if exercise.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(GlowTheme.Colors.success)
                        }
                        Button(action: { withAnimation { isExpanded.toggle() } }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(GlowTheme.Colors.textTertiary)
                                .font(.system(size: 12))
                        }
                    }
                }

                if isExpanded {
                    Divider().background(GlowTheme.Colors.textMuted.opacity(0.3))

                    // Sets list
                    if !exercise.sortedSets.isEmpty {
                        VStack(spacing: 4) {
                            ForEach(exercise.sortedSets) { set in
                                SetRow(set: set, onDelete: {
                                    exercise.sets.removeAll { $0.id == set.id }
                                    try? context.save()
                                })
                            }
                        }
                    }

                    // Action buttons
                    HStack(spacing: GlowTheme.Spacing.sm) {
                        // Add set
                        Button(action: onAddSet) {
                            Label("+ Set", systemImage: "plus")
                                .font(GlowTheme.Fonts.subheadline(14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(GlowTheme.Colors.purpleDim))
                        }

                        // Rest timer
                        Button(action: { onStartTimer(exercise.category.defaultRestSeconds) }) {
                            Label("\(exercise.category.defaultRestSeconds / 60):\(String(format: "%02d", exercise.category.defaultRestSeconds % 60))", systemImage: "timer")
                                .font(GlowTheme.Fonts.caption(12))
                                .foregroundColor(GlowTheme.Colors.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(GlowTheme.Colors.surfaceElevated)
                                )
                        }

                        Spacer()

                        // Done
                        if !exercise.isCompleted {
                            Button(action: onMarkComplete) {
                                Text("Done")
                                    .font(GlowTheme.Fonts.caption(12))
                                    .foregroundColor(GlowTheme.Colors.success)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .stroke(GlowTheme.Colors.success.opacity(0.4), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Set Row
struct SetRow: View {
    let set: SetEntry
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text("Set \(set.setNumber)")
                .font(GlowTheme.Fonts.caption(12))
                .foregroundColor(GlowTheme.Colors.textTertiary)
                .frame(width: 44, alignment: .leading)

            Text(set.displayString)
                .font(GlowTheme.Fonts.subheadline(14))
                .foregroundColor(GlowTheme.Colors.textPrimary)

            Spacer()

            Text("\(Int(set.volume)) vol")
                .font(GlowTheme.Fonts.caption(11))
                .foregroundColor(GlowTheme.Colors.textMuted)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(GlowTheme.Colors.textMuted)
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
    }
}
