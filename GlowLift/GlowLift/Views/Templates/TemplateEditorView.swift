import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var context
    @Query private var templates: [WorkoutTemplate]
    @State private var selectedTemplate: WorkoutTemplate?

    private var sortedTemplates: [WorkoutTemplate] {
        templates.sorted { $0.type.sequenceIndex < $1.type.sequenceIndex }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: GlowTheme.Spacing.sm) {
                        infoCard
                        ForEach(sortedTemplates) { template in
                            templateRow(template)
                        }
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, GlowTheme.Spacing.md)
                    .padding(.top, GlowTheme.Spacing.md)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedTemplate) { template in
                TemplateDetailEditor(template: template)
            }
        }
    }

    private var infoCard: some View {
        GlowCard(glowColor: GlowTheme.Colors.accentBlue, glowIntensity: 0.4) {
            HStack(spacing: GlowTheme.Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(GlowTheme.Colors.accentBlue)
                Text("Tap any template to edit exercises inline. Drag to reorder.")
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.textSecondary)
            }
        }
    }

    private func templateRow(_ template: WorkoutTemplate) -> some View {
        Button(action: { selectedTemplate = template }) {
            GlowCard(glowColor: Color(hex: template.type.colorHex), glowIntensity: 0.35) {
                HStack(spacing: GlowTheme.Spacing.md) {
                    Text(template.type.emoji)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(GlowTheme.Fonts.subheadline())
                            .foregroundColor(.white)
                        Text("\(template.exercises.count) exercises · \(template.type.focus)")
                            .font(GlowTheme.Fonts.caption())
                            .foregroundColor(GlowTheme.Colors.textSecondary)
                    }
                    Spacer()
                    if template.isEdited {
                        Text("Edited")
                            .font(GlowTheme.Fonts.caption(10))
                            .foregroundColor(GlowTheme.Colors.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(GlowTheme.Colors.accent.opacity(0.15)))
                    }
                    Image(systemName: "chevron.right")
                        .foregroundColor(GlowTheme.Colors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Detail Editor
struct TemplateDetailEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var template: WorkoutTemplate
    @State private var showAddExercise = false
    @State private var newExerciseName = ""
    @State private var newExerciseCategory = ExerciseCategory.other
    @State private var editMode: EditMode = .inactive

    private var sortedExercises: [WorkoutExerciseTemplate] {
        template.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        ZStack {
            GlowTheme.Colors.gradientBackground.ignoresSafeArea()
            listContent
        }
        .navigationTitle(template.type.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .environment(\.editMode, $editMode)
        .toolbar { detailToolbar }
        .sheet(isPresented: $showAddExercise) { addExerciseSheet }
    }

    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: GlowTheme.Spacing.md) {
                Button(editMode == .active ? "Done" : "Reorder") {
                    withAnimation { editMode = editMode == .active ? .inactive : .active }
                }
                .foregroundColor(GlowTheme.Colors.purple)
                Button("Save") { saveChanges() }
                    .foregroundColor(GlowTheme.Colors.purple)
                    .fontWeight(.semibold)
            }
        }
    }

    private var listContent: some View {
        List {
            nameSection
            exercisesSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private var nameSection: some View {
        Section {
            GlowCard(glowColor: Color(hex: template.type.colorHex), glowIntensity: 0.5) {
                VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                    Text("TEMPLATE NAME")
                        .font(GlowTheme.Fonts.caption(10))
                        .foregroundColor(GlowTheme.Colors.textTertiary)
                        .tracking(1)
                    TextField("Name", text: $template.name)
                        .font(GlowTheme.Fonts.headline())
                        .foregroundColor(.white)
                        .padding(GlowTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: GlowTheme.Radius.sm)
                                .fill(GlowTheme.Colors.surfaceElevated)
                        )
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        }
    }

    private var exercisesSection: some View {
        Section {
            ForEach(sortedExercises) { exercise in
                TemplateExerciseRow(exercise: exercise, onDelete: {
                    template.exercises.removeAll { $0.id == exercise.id }
                    context.delete(exercise)
                    template.isEdited = true
                    try? context.save()
                })
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }
            .onMove { source, dest in
                reorder(from: source, to: dest)
            }
            .onDelete { indexSet in
                deleteExercises(at: indexSet)
            }

            addExerciseButton
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        } header: {
            HStack {
                Text("EXERCISES (\(template.exercises.count))")
                    .font(GlowTheme.Fonts.caption(10))
                    .foregroundColor(GlowTheme.Colors.textTertiary)
                    .tracking(1)
                Spacer()
            }
            .padding(.bottom, 4)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
        }
    }

    private var addExerciseButton: some View {
        Button(action: { showAddExercise = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(GlowTheme.Colors.purple)
                Text("Add Exercise")
                    .font(GlowTheme.Fonts.subheadline())
                    .foregroundColor(GlowTheme.Colors.purple)
            }
            .frame(maxWidth: .infinity)
            .padding(GlowTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                    .fill(GlowTheme.Colors.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: GlowTheme.Radius.md)
                            .stroke(GlowTheme.Colors.purple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var addExerciseSheet: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()
                VStack(spacing: GlowTheme.Spacing.lg) {
                    GlowCard(glowIntensity: 0.4) {
                        VStack(alignment: .leading, spacing: GlowTheme.Spacing.md) {
                            Text("Exercise Name")
                                .font(GlowTheme.Fonts.caption())
                                .foregroundColor(GlowTheme.Colors.textTertiary)
                            TextField("e.g. Incline DB Press", text: $newExerciseName)
                                .font(GlowTheme.Fonts.subheadline())
                                .foregroundColor(.white)
                                .padding(GlowTheme.Spacing.sm)
                                .background(RoundedRectangle(cornerRadius: GlowTheme.Radius.sm).fill(GlowTheme.Colors.surfaceElevated))
                        }
                    }
                    GlowCard(glowIntensity: 0.3) {
                        VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                            Text("Category")
                                .font(GlowTheme.Fonts.caption())
                                .foregroundColor(GlowTheme.Colors.textTertiary)
                            Picker("Category", selection: $newExerciseCategory) {
                                ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 150)
                        }
                    }
                    GlowButton(title: "Add Exercise", icon: "plus") { addExercise() }
                        .disabled(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                    Spacer()
                }
                .padding(GlowTheme.Spacing.md)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddExercise = false }
                        .foregroundColor(GlowTheme.Colors.textSecondary)
                }
            }
        }
    }

    private func addExercise() {
        let name = newExerciseName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let idx = template.exercises.count
        let ex = WorkoutExerciseTemplate(
            exerciseName: name,
            exerciseCategory: newExerciseCategory,
            orderIndex: idx
        )
        ex.workout = template
        template.exercises.append(ex)
        template.isEdited = true
        newExerciseName = ""
        showAddExercise = false
        try? context.save()
    }

    private func reorder(from source: IndexSet, to dest: Int) {
        var sorted = sortedExercises
        sorted.move(fromOffsets: source, toOffset: dest)
        for (i, ex) in sorted.enumerated() { ex.orderIndex = i }
        template.isEdited = true
        try? context.save()
    }

    private func deleteExercises(at indexSet: IndexSet) {
        let sorted = sortedExercises
        for i in indexSet {
            let ex = sorted[i]
            template.exercises.removeAll { $0.id == ex.id }
            context.delete(ex)
        }
        template.isEdited = true
        try? context.save()
    }

    private func saveChanges() {
        template.isEdited = true
        template.updatedAt = Date()
        try? context.save()
        dismiss()
    }
}

// MARK: - Template Exercise Row (inline editing)
struct TemplateExerciseRow: View {
    @Bindable var exercise: WorkoutExerciseTemplate
    @State private var isExpanded = false
    let onDelete: () -> Void

    var body: some View {
        GlowCard(glowIntensity: isExpanded ? 0.4 : 0.2) {
            rowContent
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    @ViewBuilder
    private var rowContent: some View {
        VStack(spacing: GlowTheme.Spacing.sm) {
            rowHeader
            if isExpanded {
                Divider().background(GlowTheme.Colors.textMuted.opacity(0.3))
                editFields
            }
        }
    }

    private var rowHeader: some View {
        HStack(spacing: GlowTheme.Spacing.md) {
            ExerciseIcon(category: exercise.category, size: 36)
            headerText
            Spacer()
            headerButtons
        }
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.exerciseName)
                .font(GlowTheme.Fonts.subheadline())
                .foregroundColor(.white)
            Text("\(exercise.category.rawValue) · \(exercise.restSeconds)s rest")
                .font(GlowTheme.Fonts.caption(11))
                .foregroundColor(GlowTheme.Colors.textTertiary)
        }
    }

    private var headerButtons: some View {
        HStack(spacing: GlowTheme.Spacing.sm) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                Image(systemName: isExpanded ? "chevron.up" : "pencil")
                    .foregroundColor(isExpanded ? GlowTheme.Colors.textTertiary : GlowTheme.Colors.purple)
                    .font(.system(size: 13))
            }
        }
    }

    @ViewBuilder
    private var editFields: some View {
        VStack(spacing: GlowTheme.Spacing.md) {
            nameField
            categoryPicker
            restTimeStepper
            deleteButton
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Name")
                .font(GlowTheme.Fonts.caption(11))
                .foregroundColor(GlowTheme.Colors.textTertiary)
            TextField("Exercise name", text: $exercise.exerciseName)
                .font(GlowTheme.Fonts.subheadline())
                .foregroundColor(.white)
                .padding(GlowTheme.Spacing.sm)
                .background(RoundedRectangle(cornerRadius: GlowTheme.Radius.sm).fill(GlowTheme.Colors.surfaceElevated))
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Category")
                .font(GlowTheme.Fonts.caption(11))
                .foregroundColor(GlowTheme.Colors.textTertiary)
            categoryPickerMenu
        }
    }

    private var categoryPickerMenu: some View {
        Menu {
            ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                Button(cat.rawValue) {
                    exercise.exerciseCategory = cat.rawValue
                    exercise.restSeconds = cat.defaultRestSeconds
                }
            }
        } label: {
            HStack {
                ExerciseIcon(category: exercise.category, size: 24)
                Text(exercise.category.rawValue)
                    .font(GlowTheme.Fonts.subheadline(14))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11))
                    .foregroundColor(GlowTheme.Colors.textTertiary)
            }
            .padding(GlowTheme.Spacing.sm)
            .background(RoundedRectangle(cornerRadius: GlowTheme.Radius.sm).fill(GlowTheme.Colors.surfaceElevated))
        }
    }

    private var restTimeStepper: some View {
        HStack {
            Text("Rest time")
                .font(GlowTheme.Fonts.caption(11))
                .foregroundColor(GlowTheme.Colors.textTertiary)
            Spacer()
            Stepper("\(exercise.restSeconds)s", value: $exercise.restSeconds, in: 30...300, step: 15)
                .font(GlowTheme.Fonts.subheadline(14))
                .foregroundColor(.white)
                .labelsHidden()
            Text("\(exercise.restSeconds)s")
                .font(GlowTheme.Fonts.subheadline(14))
                .foregroundColor(GlowTheme.Colors.purple)
                .frame(width: 44)
        }
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Label("Remove Exercise", systemImage: "trash")
                .font(GlowTheme.Fonts.caption(13))
                .foregroundColor(GlowTheme.Colors.error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GlowTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: GlowTheme.Radius.sm)
                        .fill(GlowTheme.Colors.error.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: GlowTheme.Radius.sm)
                                .stroke(GlowTheme.Colors.error.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
