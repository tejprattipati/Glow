import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var preferencesQuery: [UserPreferences]
    @Query private var streakStates: [StreakState]
    @Query private var sessions: [WorkoutSession]

    @State private var showResetConfirm = false
    @State private var showSpecialDay = false
    @State private var specialDayType: SpecialCircumstanceType = .personal
    @State private var specialDayNotes = ""

    private var prefs: UserPreferences? { preferencesQuery.first }
    private var streak: StreakState? { streakStates.first }

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GlowTheme.Spacing.lg) {
                        if let prefs {
                            trainingSection(prefs)
                            streakSection(prefs)
                            claudeSection
                            hapticsSection(prefs)
                            specialDaySection
                            dangerSection
                        }
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, GlowTheme.Spacing.md)
                    .padding(.top, GlowTheme.Spacing.md)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Training
    private func trainingSection(_ prefs: UserPreferences) -> some View {
        settingsGroup(title: "Training") {
            settingRow(icon: "scalemass.fill", iconColor: GlowTheme.Colors.accentBlue, title: "Weight Unit") {
                Picker("", selection: Binding(
                    get: { prefs.unit },
                    set: { prefs.weightUnit = $0.rawValue; save() }
                )) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .tint(GlowTheme.Colors.purple)
            }

            settingRow(icon: "timer", iconColor: GlowTheme.Colors.purple, title: "Default Rest") {
                Picker("", selection: Binding(
                    get: { prefs.defaultRestSeconds },
                    set: { prefs.defaultRestSeconds = $0; save() }
                )) {
                    Text("60s").tag(60)
                    Text("90s").tag(90)
                    Text("2 min").tag(120)
                    Text("3 min").tag(180)
                }
                .pickerStyle(.menu)
                .tint(GlowTheme.Colors.purple)
            }
        }
    }

    // MARK: - Streak
    private func streakSection(_ prefs: UserPreferences) -> some View {
        settingsGroup(title: "Streak") {
            if let streak {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(GlowTheme.Colors.accent)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Flow Streak")
                            .font(GlowTheme.Fonts.subheadline())
                            .foregroundColor(.white)
                        Text("\(streak.currentFlowStreak) sessions · Longest: \(streak.longestFlowStreak)")
                            .font(GlowTheme.Fonts.caption())
                            .foregroundColor(GlowTheme.Colors.textSecondary)
                    }
                    Spacer()
                }

                Divider().background(GlowTheme.Colors.textMuted.opacity(0.2))
            }

            settingRow(icon: "moon.zzz.fill", iconColor: GlowTheme.Colors.accentBlue, title: "Max Rest Days") {
                Picker("", selection: Binding(
                    get: { prefs.maxRestDaysBeforeBreak },
                    set: { prefs.maxRestDaysBeforeBreak = $0; save() }
                )) {
                    Text("2 days").tag(2)
                    Text("3 days").tag(3)
                    Text("4 days").tag(4)
                    Text("5 days").tag(5)
                }
                .pickerStyle(.menu)
                .tint(GlowTheme.Colors.purple)
            }

            settingRow(icon: "shield.fill", iconColor: GlowTheme.Colors.success, title: "Special Days Don't Break Streak") {
                Toggle("", isOn: Binding(
                    get: { prefs.specialCircumstanceDontBreakStreak },
                    set: { prefs.specialCircumstanceDontBreakStreak = $0; save() }
                ))
                .tint(GlowTheme.Colors.purple)
            }
        }
    }

    // MARK: - Claude
    private var claudeSection: some View {
        settingsGroup(title: "AI Coach (Claude)") {
            settingRow(icon: "brain.head.profile", iconColor: GlowTheme.Colors.purple, title: "Model") {
                Text("claude-opus-4-6")
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.textTertiary)
            }
            settingRow(icon: "key.fill", iconColor: GlowTheme.Colors.accent, title: "API Key") {
                Text("Configured")
                    .font(GlowTheme.Fonts.caption())
                    .foregroundColor(GlowTheme.Colors.success)
            }
        }
    }

    // MARK: - Haptics
    private func hapticsSection(_ prefs: UserPreferences) -> some View {
        settingsGroup(title: "Haptics & Sound") {
            settingRow(icon: "hand.tap.fill", iconColor: GlowTheme.Colors.purple, title: "Haptics") {
                Toggle("", isOn: Binding(
                    get: { prefs.hapticsEnabled },
                    set: { prefs.hapticsEnabled = $0; save() }
                ))
                .tint(GlowTheme.Colors.purple)
            }
            settingRow(icon: "speaker.wave.2.fill", iconColor: GlowTheme.Colors.accentBlue, title: "Sound") {
                Toggle("", isOn: Binding(
                    get: { prefs.soundEnabled },
                    set: { prefs.soundEnabled = $0; save() }
                ))
                .tint(GlowTheme.Colors.purple)
            }
        }
    }

    // MARK: - Special Day
    private var specialDaySection: some View {
        settingsGroup(title: "Special Circumstances") {
            Button(action: { showSpecialDay = true }) {
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundColor(GlowTheme.Colors.warning)
                        .frame(width: 28)
                    Text("Log Special Day")
                        .font(GlowTheme.Fonts.subheadline())
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(GlowTheme.Colors.textTertiary)
                }
            }
        }
        .sheet(isPresented: $showSpecialDay) {
            specialDaySheet
        }
    }

    private var specialDaySheet: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()
                VStack(spacing: GlowTheme.Spacing.lg) {
                    GlowCard(glowIntensity: 0.3) {
                        VStack(alignment: .leading, spacing: GlowTheme.Spacing.md) {
                            Text("Type")
                                .font(GlowTheme.Fonts.caption())
                                .foregroundColor(GlowTheme.Colors.textTertiary)
                            Picker("Type", selection: $specialDayType) {
                                ForEach(SpecialCircumstanceType.allCases, id: \.self) { t in
                                    Label(t.rawValue, systemImage: t.sfSymbol).tag(t)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                    }
                    GlowCard(glowIntensity: 0.3) {
                        VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                            Text("Notes (optional)")
                                .font(GlowTheme.Fonts.caption())
                                .foregroundColor(GlowTheme.Colors.textTertiary)
                            TextField("e.g. Sick with cold", text: $specialDayNotes)
                                .font(GlowTheme.Fonts.body())
                                .foregroundColor(.white)
                                .padding(GlowTheme.Spacing.sm)
                                .background(RoundedRectangle(cornerRadius: GlowTheme.Radius.sm).fill(GlowTheme.Colors.surfaceElevated))
                        }
                    }
                    GlowButton(title: "Log Today as Special Day", icon: "checkmark") {
                        logSpecialDay()
                        showSpecialDay = false
                    }
                    Spacer()
                }
                .padding(GlowTheme.Spacing.md)
            }
            .navigationTitle("Special Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSpecialDay = false }
                        .foregroundColor(GlowTheme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Danger zone
    private var dangerSection: some View {
        settingsGroup(title: "Data") {
            Button(action: { showResetConfirm = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(GlowTheme.Colors.error)
                        .frame(width: 28)
                    Text("Reset All Data")
                        .font(GlowTheme.Fonts.subheadline())
                        .foregroundColor(GlowTheme.Colors.error)
                    Spacer()
                }
            }
        }
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all sessions and chat history. This cannot be undone.")
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
            SectionHeader(title: title)
            GlowCard(glowIntensity: 0.2) {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    private func settingRow<Trailing: View>(icon: String, iconColor: Color, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 28)
            Text(title)
                .font(GlowTheme.Fonts.subheadline())
                .foregroundColor(GlowTheme.Colors.textPrimary)
            Spacer()
            trailing()
        }
        .padding(.vertical, GlowTheme.Spacing.sm)
    }

    private func save() {
        try? context.save()
    }

    private func logSpecialDay() {
        let day = SpecialCircumstanceDay(
            circumstanceType: specialDayType,
            notes: specialDayNotes,
            countedAgainstStreak: false
        )
        context.insert(day)
        specialDayNotes = ""
        save()
    }

    private func resetAll() {
        for s in sessions { context.delete(s) }
        save()
    }
}
