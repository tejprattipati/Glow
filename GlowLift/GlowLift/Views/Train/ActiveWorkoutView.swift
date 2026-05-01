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
    @State private var selectedExercise: ExerciseSession?
    @State private var showAddExercise = false
    @State private var editingExercise: ExerciseSession?

    private var sortedExercises: [ExerciseSession] {
        session.sortedExercises
    }

    private var indexedExercises: [IndexedExercise] {
        sortedExercises.enumerated().map { offset, exercise in
            IndexedExercise(index: offset, exercise: exercise)
        }
    }

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(session.workoutName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
                .toolbar { toolbarItems }
                .alert("Finish Workout?", isPresented: $showFinishAlert, actions: finishAlertButtons, message: finishAlertMessage)
                .sheet(item: $selectedExercise, content: setLoggingSheet)
                .sheet(isPresented: $showAddExercise, content: addExerciseSheet)
                .sheet(item: $editingExercise, content: editExerciseSheet)
        }
        .onAppear { startElapsedTimer() }
        .onDisappear { elapsedTimer?.invalidate() }
    }

    private var mainContent: some View {
        ZStack(alignment: .top) {
            GlowTheme.Colors.gradientBackground.ignoresSafeArea()
            scrollContent
            VStack {
                FloatingRestTimerBar(timer: timerManager)
                Spacer()
            }
        }
    }

    private var scrollContent: some View {
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
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
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

    @ViewBuilder
    private func finishAlertButtons() -> some View {
        Button("Save & Finish") { finishWorkout() }
        Button("Discard", role: .destructive) { discardAndDismiss() }
        Button("Keep Training", role: .cancel) {}
    }

    private func finishAlertMessage() -> some View {
        Text("You've logged \(session.totalSets) sets.")
    }

    private func setLoggingSheet(for exercise: ExerciseSession) -> some View {
        SetLoggingSheet(
            exercise: exercise,
            session: session,
            onSetLogged: { weight, reps in logSet(exercise: exercise, weight: weight, reps: reps) }
        )
    }

    private func addExerciseSheet() -> some View {
        AddExerciseToSessionSheet { name, category in
            let idx = session.exercises.count
            let ex = ExerciseSession(exerciseName: name, exerciseCategory: category, orderIndex: idx)
            ex.workoutSession = session
            session.exercises.append(ex)
            try? context.save()
        }
    }

    private func editExerciseSheet(for exercise: ExerciseSession) -> some View {
        EditExerciseInSessionSheet(exercise: exercise) {
            try? context.save()
        }
    }

    // MARK: - Header
    private var workoutHeader: some View {
        GlowCard(glowColor: Color(hex: session.type.colorHex), glowIntensity: 0.6) {
            HStack {
                workoutHeaderLeading
                Spacer()
                workoutHeaderTrailing
            }
        }
    }

    private var workoutHeaderLeading: some View {
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
    }

    private var workoutHeaderTrailing: some View {
        VStack(alignment: .trailing, spacing: 4) {
            StatChip(
                value: "\(session.totalSets)",
                label: "Sets",
                color: Color(hex: session.type.colorHex)
            )
            let done = sortedExercises.filter { $0.isCompleted }.count
            let total = sortedExercises.count
            Text("\(done)/\(total) done")
                .font(GlowTheme.Fonts.caption(11))
                .foregroundColor(GlowTheme.Colors.textTertiary)
        }
    }

    // MARK: - Exercise List
    private var exerciseList: some View {
        VStack(spacing: GlowTheme.Spacing.sm) {
            SectionHeader(
                title: "Exercises",
                trailing: "+ Add",
                action: { showAddExercise = true }
            )
            ForEach(indexedExercises) { item in
                exerciseCardRow(item.exercise, index: item.index)
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
            onStartTimer: { seconds in timerManager.start(seconds: seconds) },
            onMarkComplete: { markComplete(exercise: exercise, index: index) },
            onEdit: { editingExercise = exercise },
            onDelete: {
                withAnimation {
                    session.exercises.removeAll { $0.id == exercise.id }
                    context.delete(exercise)
                    try? context.save()
                }
            }
        )
    }

    // MARK: - Finish Button
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
        elapsedSeconds = Int(Date().timeIntervalSince(start))
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            elapsedSeconds = Int(Date().timeIntervalSince(start))
        }
    }

    private func markComplete(exercise: ExerciseSession, index: Int) {
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

    private func logSet(exercise: ExerciseSession, weight: Double, reps: Int) {
        let nextNum = exercise.sortedSets.count + 1
        let entry = SetEntry(setNumber: nextNum, weight: weight, reps: reps)
        entry.exerciseSession = exercise
        exercise.sets.append(entry)
        try? context.save()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let restSecs = exercise.category.defaultRestSeconds
        timerManager.start(seconds: restSecs)
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

private struct IndexedExercise: Identifiable {
    let index: Int
    let exercise: ExerciseSession
    var id: PersistentIdentifier { exercise.id }
}

// MARK: - Add Exercise Sheet
struct AddExerciseToSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var category: ExerciseCategory = .other

    let onAdd: (String, ExerciseCategory) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()
                formContent
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { addSheetToolbar }
        }
    }

    @ToolbarContentBuilder
    private var addSheetToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .foregroundColor(GlowTheme.Colors.textSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Add") {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                onAdd(trimmed, category)
                dismiss()
            }
            .foregroundColor(GlowTheme.Colors.purple)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var formContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: GlowTheme.Spacing.lg) {
                nameCard
                categoryCard
                Spacer(minLength: 40)
            }
            .padding(GlowTheme.Spacing.md)
        }
    }

    private var nameCard: some View {
        GlowCard(glowColor: GlowTheme.Colors.purple, glowIntensity: 0.4) {
            VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                Text("Exercise Name")
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.textTertiary)
                TextField("e.g. Incline DB Press", text: $name)
                    .font(GlowTheme.Fonts.subheadline())
                    .foregroundColor(.white)
                    .padding(GlowTheme.Spacing.sm)
                    .background(RoundedRectangle(cornerRadius: GlowTheme.Radius.sm).fill(GlowTheme.Colors.surfaceElevated))
            }
        }
    }

    private var categoryCard: some View {
        GlowCard(glowIntensity: 0.3) {
            VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                Text("Category")
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.textTertiary)
                Picker("Category", selection: $category) {
                    ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
            }
        }
    }
}

// MARK: - Edit Exercise Sheet
struct EditExerciseInSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var exercise: ExerciseSession
    @State private var draftName: String = ""
    @State private var draftCategory: ExerciseCategory = .other

    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()
                editFormContent
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { editSheetToolbar }
        }
        .onAppear {
            draftName = exercise.exerciseName
            draftCategory = exercise.category
        }
    }

    @ToolbarContentBuilder
    private var editSheetToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .foregroundColor(GlowTheme.Colors.textSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { applyEdits() }
                .foregroundColor(GlowTheme.Colors.purple)
                .disabled(draftName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var editFormContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: GlowTheme.Spacing.lg) {
                editNameCard
                editCategoryCard
                Spacer(minLength: 40)
            }
            .padding(GlowTheme.Spacing.md)
        }
    }

    private var editNameCard: some View {
        GlowCard(glowColor: GlowTheme.Colors.purple, glowIntensity: 0.4) {
            VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                Text("Exercise Name")
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.textTertiary)
                TextField("Name", text: $draftName)
                    .font(GlowTheme.Fonts.subheadline())
                    .foregroundColor(.white)
                    .padding(GlowTheme.Spacing.sm)
                    .background(RoundedRectangle(cornerRadius: GlowTheme.Radius.sm).fill(GlowTheme.Colors.surfaceElevated))
            }
        }
    }

    private var editCategoryCard: some View {
        GlowCard(glowIntensity: 0.3) {
            VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                Text("Category (affects rest timer & icon)")
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.textTertiary)
                Picker("Category", selection: $draftCategory) {
                    ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
            }
        }
    }

    private func applyEdits() {
        let trimmed = draftName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        exercise.exerciseName = trimmed
        exercise.exerciseCategory = draftCategory.rawValue
        onSave()
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
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var isExpanded: Bool = true

    private var accentColor: Color {
        if isActive { return GlowTheme.Colors.purple }
        if exercise.isCompleted { return GlowTheme.Colors.success }
        return GlowTheme.Colors.textMuted
    }
    private var glowIntensity: Double { isActive ? 0.8 : 0.2 }

    private var lastPriorSession: ExerciseSession? {
        WorkoutSequencer.lastExerciseSession(named: exercise.exerciseName, context: context)
    }

    var body: some View {
        GlowCard(glowColor: accentColor, glowIntensity: glowIntensity, showBorder: isActive) {
            cardContent
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: GlowTheme.Spacing.sm) {
            headerRow
            if isExpanded {
                expandedSection
            }
        }
    }

    private var headerRow: some View {
        HStack {
            ExerciseIcon(category: exercise.category, size: 38)
            nameColumn
            Spacer()
            headerTrailing
        }
    }

    @ViewBuilder
    private var nameColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.exerciseName)
                .font(GlowTheme.Fonts.subheadline())
                .foregroundColor(.white)
            if let last = lastPriorSession, let top = last.topSet {
                Text("Last: \(top.displayString) · \(last.setCount) sets")
                    .font(GlowTheme.Fonts.caption(11))
                    .foregroundColor(GlowTheme.Colors.textTertiary)
            }
        }
    }

    @ViewBuilder
    private var headerTrailing: some View {
        HStack(spacing: GlowTheme.Spacing.sm) {
            if let edit = onEdit {
                Button(action: edit) {
                    Image(systemName: "pencil")
                        .foregroundColor(GlowTheme.Colors.textTertiary)
                        .font(.system(size: 13))
                }
            }
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

    @ViewBuilder
    private var expandedSection: some View {
        VStack(spacing: GlowTheme.Spacing.sm) {
            Divider().background(GlowTheme.Colors.textMuted.opacity(0.3))
            setsList
            actionRow
        }
    }

    @ViewBuilder
    private var setsList: some View {
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
    }

    private var actionRow: some View {
        HStack(spacing: GlowTheme.Spacing.sm) {
            addSetButton
            restTimerButton
            Spacer()
            deleteButtonIfNeeded
            if !exercise.isCompleted {
                doneButton
            }
        }
    }

    @ViewBuilder
    private var deleteButtonIfNeeded: some View {
        if let del = onDelete {
            Button(action: del) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(GlowTheme.Colors.error.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(GlowTheme.Colors.surfaceElevated))
            }
        }
    }

    private var addSetButton: some View {
        Button(action: onAddSet) {
            Label("+ Set", systemImage: "plus")
                .font(GlowTheme.Fonts.subheadline(14))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(GlowTheme.Colors.purpleDim))
        }
    }

    private var restTimerButton: some View {
        let secs = exercise.category.defaultRestSeconds
        let label = "\(secs / 60):\(String(format: "%02d", secs % 60))"
        return Button(action: { onStartTimer(secs) }) {
            Label(label, systemImage: "timer")
                .font(GlowTheme.Fonts.caption(12))
                .foregroundColor(GlowTheme.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(GlowTheme.Colors.surfaceElevated))
        }
    }

    private var doneButton: some View {
        Button(action: onMarkComplete) {
            Text("Done")
                .font(GlowTheme.Fonts.caption(12))
                .foregroundColor(GlowTheme.Colors.success)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().stroke(GlowTheme.Colors.success.opacity(0.4), lineWidth: 1))
        }
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
