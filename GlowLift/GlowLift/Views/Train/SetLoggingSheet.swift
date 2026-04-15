import SwiftUI
import SwiftData

struct SetLoggingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let exercise: ExerciseSession
    let session: WorkoutSession
    let onSetLogged: (Double, Int) -> Void

    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var notes: String = ""

    @FocusState private var weightFocused: Bool

    private var lastExerciseSession: ExerciseSession? {
        WorkoutSequencer.lastExerciseSession(named: exercise.exerciseName, context: context)
    }
    private var lastTopSet: SetEntry? { lastExerciseSession?.topSet }
    private var previousSetInSession: SetEntry? { exercise.sortedSets.last }
    private var nextSetNumber: Int { exercise.sortedSets.count + 1 }
    private var canLog: Bool { !(reps.isEmpty) }

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()
                scrollContent
            }
            .navigationTitle("Set \(nextSetNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { toolbarItems }
        }
        .onAppear {
            prefillFromLastSet()
            weightFocused = true
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .foregroundColor(GlowTheme.Colors.textSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Log Set") { logSet() }
                .font(GlowTheme.Fonts.subheadline())
                .foregroundColor(GlowTheme.Colors.purple)
                .disabled(!canLog)
        }
    }

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: GlowTheme.Spacing.lg) {
                exerciseHeader
                lastPerformanceRow
                setEntryForm
                quickFillButtons
                currentSetsSection
                Spacer(minLength: 60)
            }
            .padding(.horizontal, GlowTheme.Spacing.md)
            .padding(.top, GlowTheme.Spacing.md)
        }
    }

    // MARK: - Header
    private var exerciseHeader: some View {
        HStack(spacing: GlowTheme.Spacing.md) {
            ExerciseIcon(category: exercise.category, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseName)
                    .font(GlowTheme.Fonts.headline())
                    .foregroundColor(.white)
                Text("Set \(nextSetNumber)")
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.textTertiary)
            }
            Spacer()
        }
    }

    // MARK: - Last Performance
    @ViewBuilder
    private var lastPerformanceRow: some View {
        if let last = lastExerciseSession, let top = lastTopSet {
            GlowCard(glowColor: GlowTheme.Colors.accentBlue, glowIntensity: 0.4) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(GlowTheme.Colors.accentBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last session")
                            .font(GlowTheme.Fonts.caption(11))
                            .foregroundColor(GlowTheme.Colors.textTertiary)
                        Text(last.displaySummary)
                            .font(GlowTheme.Fonts.subheadline())
                            .foregroundColor(GlowTheme.Colors.textPrimary)
                        Text("Top set: \(top.displayString)")
                            .font(GlowTheme.Fonts.caption(12))
                            .foregroundColor(GlowTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Button("Match") {
                        weight = top.formattedWeight
                        reps = "\(top.reps)"
                    }
                    .font(GlowTheme.Fonts.caption(12))
                    .foregroundColor(GlowTheme.Colors.accentBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(GlowTheme.Colors.accentBlue.opacity(0.4), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Entry Form
    private var setEntryForm: some View {
        GlowCard(glowColor: GlowTheme.Colors.purple, glowIntensity: 0.6) {
            VStack(spacing: GlowTheme.Spacing.md) {
                weightRepsRow
                notesField
                logButton
            }
        }
    }

    private var weightRepsRow: some View {
        HStack(spacing: GlowTheme.Spacing.lg) {
            weightField
            repsField
        }
    }

    private var weightField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WEIGHT (lbs)")
                .font(GlowTheme.Fonts.caption(10))
                .foregroundColor(GlowTheme.Colors.textTertiary)
                .tracking(1)
            TextField("0", text: $weight)
                .keyboardType(.decimalPad)
                .font(GlowTheme.Fonts.display(36))
                .foregroundColor(.white)
                .focused($weightFocused)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(GlowTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                        .fill(GlowTheme.Colors.surfaceElevated)
                )
        }
    }

    private var repsField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("REPS")
                .font(GlowTheme.Fonts.caption(10))
                .foregroundColor(GlowTheme.Colors.textTertiary)
                .tracking(1)
            TextField("0", text: $reps)
                .keyboardType(.numberPad)
                .font(GlowTheme.Fonts.display(36))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(GlowTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                        .fill(GlowTheme.Colors.surfaceElevated)
                )
        }
    }

    private var notesField: some View {
        TextField("Notes (optional)", text: $notes)
            .font(GlowTheme.Fonts.body())
            .foregroundColor(GlowTheme.Colors.textSecondary)
            .padding(GlowTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: GlowTheme.Radius.sm)
                    .fill(GlowTheme.Colors.surfaceElevated)
            )
    }

    private var logButton: some View {
        GlowButton(title: "Log Set \(nextSetNumber)", icon: "checkmark") {
            logSet()
        }
        .disabled(!canLog)
    }

    // MARK: - Quick Fill
    // Avoid complex if-let chains inside view builder by pre-computing values
    private var quickFillButtons: some View {
        VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
            Text("QUICK FILL")
                .font(GlowTheme.Fonts.caption(10))
                .foregroundColor(GlowTheme.Colors.textTertiary)
                .tracking(1.2)
                .padding(.horizontal, GlowTheme.Spacing.sm)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: GlowTheme.Spacing.sm) {
                    quickFillChips
                }
                .padding(.horizontal, GlowTheme.Spacing.sm)
            }
        }
    }

    @ViewBuilder
    private var quickFillChips: some View {
        if let prev = previousSetInSession {
            quickFillChip(
                label: "Same as last set",
                sub: "\(prev.formattedWeight) × \(prev.reps)",
                action: { weight = prev.formattedWeight; reps = "\(prev.reps)" }
            )
        }
        if let last = lastTopSet {
            quickFillChip(
                label: "Last workout",
                sub: "\(last.formattedWeight) × \(last.reps)",
                action: { weight = last.formattedWeight; reps = "\(last.reps)" }
            )
        }
        weightAdjustChips
    }

    @ViewBuilder
    private var weightAdjustChips: some View {
        if let w = Double(weight), w > 0 {
            quickFillChip(label: "+5 lbs", sub: "\(Int(w + 5))") {
                weight = String(format: "%.1f", w + 5)
            }
            quickFillChip(label: "-5 lbs", sub: "\(Int(max(0, w - 5)))") {
                weight = String(format: "%.1f", max(0, w - 5))
            }
        }
    }

    private func quickFillChip(label: String, sub: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label)
                    .font(GlowTheme.Fonts.caption(11))
                    .foregroundColor(GlowTheme.Colors.textPrimary)
                Text(sub)
                    .font(GlowTheme.Fonts.caption(10))
                    .foregroundColor(GlowTheme.Colors.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: GlowTheme.Radius.sm)
                    .fill(GlowTheme.Colors.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: GlowTheme.Radius.sm)
                            .stroke(GlowTheme.Colors.purple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Current Sets
    @ViewBuilder
    private var currentSetsSection: some View {
        if !exercise.sortedSets.isEmpty {
            VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                SectionHeader(title: "This Session")
                GlowCard(glowIntensity: 0.2) {
                    sessionSetsList
                }
            }
        }
    }

    private var sessionSetsList: some View {
        VStack(spacing: 4) {
            ForEach(exercise.sortedSets) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(GlowTheme.Fonts.caption())
                        .foregroundColor(GlowTheme.Colors.textTertiary)
                        .frame(width: 46, alignment: .leading)
                    Text(set.displayString)
                        .font(GlowTheme.Fonts.subheadline(14))
                        .foregroundColor(GlowTheme.Colors.textPrimary)
                    Spacer()
                    Text("\(Int(set.volume)) vol")
                        .font(GlowTheme.Fonts.caption(11))
                        .foregroundColor(GlowTheme.Colors.textMuted)
                }
                .padding(.vertical, 3)
            }
        }
    }

    // MARK: - Actions
    private func prefillFromLastSet() {
        if let prev = previousSetInSession {
            weight = prev.formattedWeight
            reps = "\(prev.reps)"
        } else if let last = lastTopSet {
            weight = last.formattedWeight
            reps = "\(last.reps)"
        }
    }

    private func logSet() {
        let w = Double(weight) ?? 0
        guard let r = Int(reps), r > 0 else { return }
        onSetLogged(w, r)
        dismiss()
    }
}
