import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var context
    @Query private var templates: [WorkoutTemplate]
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showEditor = false

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
                Text("Edit your workout templates below. Changes take effect on your next session.")
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
    @State private var editingName: Bool = false
    @State private var showAddExercise = false
    @State private var newExerciseName = ""
    @State private var newExerciseCategory = ExerciseCategory.other

    var body: some View {
        ZStack {
            GlowTheme.Colors.gradientBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: GlowTheme.Spacing.lg) {
                    // Name editor
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

                    // Exercise list
                    VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                        SectionHeader(
                            title: "Exercises (\(template.exercises.count))",
                            trailing: "+ Add",
                            action: { showAddExercise = true }
                        )
                        ForEach(template.sortedExercises) { exercise in
                            exerciseRow(exercise)
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, GlowTheme.Spacing.md)
                .padding(.top, GlowTheme.Spacing.md)
            }
        }
        .navigationTitle(template.type.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveChanges() }
                    .foregroundColor(GlowTheme.Colors.purple)
            }
        }
        .sheet(isPresented: $showAddExercise) {
            addExerciseSheet
        }
    }

    private func exerciseRow(_ exercise: WorkoutExerciseTemplate) -> some View {
        GlowCard(glowIntensity: 0.2) {
            HStack(spacing: GlowTheme.Spacing.md) {
                ExerciseIcon(category: exercise.category, size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.exerciseName)
                        .font(GlowTheme.Fonts.subheadline())
                        .foregroundColor(.white)
                    Text("\(exercise.category.rawValue) · \(exercise.restSeconds)s rest")
                        .font(GlowTheme.Fonts.caption(11))
                        .foregroundColor(GlowTheme.Colors.textTertiary)
                }
                Spacer()

                // Delete
                Button(action: {
                    template.exercises.removeAll { $0.id == exercise.id }
                    context.delete(exercise)
                    template.isEdited = true
                    try? context.save()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(GlowTheme.Colors.error.opacity(0.7))
                }
            }
        }
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
                                    HStack {
                                        Image(systemName: cat.sfSymbol)
                                        Text(cat.rawValue)
                                    }.tag(cat)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 150)
                        }
                    }

                    GlowButton(title: "Add Exercise", icon: "plus") {
                        addExercise()
                    }
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

    private func saveChanges() {
        template.isEdited = true
        template.updatedAt = Date()
        try? context.save()
        dismiss()
    }
}
