import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.completedAt, order: .reverse) private var sessions: [WorkoutSession]
    @State private var selectedSession: WorkoutSession?
    @State private var searchText = ""

    private var completedSessions: [WorkoutSession] {
        sessions.filter { $0.isCompleted }
    }

    private var filteredSessions: [WorkoutSession] {
        if searchText.isEmpty { return completedSessions }
        return completedSessions.filter {
            $0.workoutName.localizedCaseInsensitiveContains(searchText) ||
            $0.workoutType.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedSessions: [(String, [WorkoutSession])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var groups: [String: [WorkoutSession]] = [:]
        for s in filteredSessions {
            let key = s.completedAt.map { formatter.string(from: $0) } ?? "Unknown"
            groups[key, default: []].append(s)
        }
        return groups.sorted { a, b in
            let df = DateFormatter(); df.dateFormat = "MMMM yyyy"
            let da = df.date(from: a.key) ?? .distantPast
            let db = df.date(from: b.key) ?? .distantPast
            return da > db
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()

                if completedSessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search workouts")
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var sessionList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: GlowTheme.Spacing.lg) {
                // Summary stats
                summaryRow
                // Sessions grouped by month
                ForEach(groupedSessions, id: \.0) { month, sessions in
                    VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                        SectionHeader(title: month)
                        ForEach(sessions) { session in
                            SessionCard(session: session)
                                .onTapGesture { selectedSession = session }
                        }
                    }
                }
                Spacer(minLength: 80)
            }
            .padding(.horizontal, GlowTheme.Spacing.md)
            .padding(.top, GlowTheme.Spacing.md)
        }
    }

    private var summaryRow: some View {
        HStack(spacing: GlowTheme.Spacing.sm) {
            StatChip(value: "\(completedSessions.count)", label: "Total", color: GlowTheme.Colors.purple)
            let thisMonth = completedSessions.filter {
                guard let d = $0.completedAt else { return false }
                return Calendar.current.isDate(d, equalTo: Date(), toGranularity: .month)
            }.count
            StatChip(value: "\(thisMonth)", label: "This Month", color: GlowTheme.Colors.accentBlue)
            let totalSets = completedSessions.reduce(0) { $0 + $1.totalSets }
            StatChip(value: "\(totalSets)", label: "Total Sets", color: GlowTheme.Colors.accent)
        }
    }

    private var emptyState: some View {
        VStack(spacing: GlowTheme.Spacing.lg) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundColor(GlowTheme.Colors.purpleDim)
                .glowEffect(radius: 16)
            Text("No History Yet")
                .font(GlowTheme.Fonts.headline())
                .foregroundColor(GlowTheme.Colors.textPrimary)
            Text("Complete your first workout to see it here.")
                .font(GlowTheme.Fonts.body())
                .foregroundColor(GlowTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Session Card
struct SessionCard: View {
    let session: WorkoutSession

    var body: some View {
        GlowCard(glowColor: Color(hex: session.type.colorHex), glowIntensity: 0.3) {
            HStack(spacing: GlowTheme.Spacing.md) {
                // Color indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: session.type.colorHex))
                    .frame(width: 4, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.type.emoji)
                        Text(session.workoutName)
                            .font(GlowTheme.Fonts.subheadline())
                            .foregroundColor(.white)
                    }
                    Text("\(session.exerciseCount) exercises · \(session.totalSets) sets · \(session.durationDisplay)")
                        .font(GlowTheme.Fonts.caption())
                        .foregroundColor(GlowTheme.Colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let date = session.completedAt {
                        Text(date, style: .date)
                            .font(GlowTheme.Fonts.caption(11))
                            .foregroundColor(GlowTheme.Colors.textTertiary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(GlowTheme.Colors.textMuted)
                }
            }
        }
    }
}

// MARK: - Session Detail View
struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GlowTheme.Spacing.lg) {
                        sessionHeader
                        ForEach(session.sortedExercises) { exercise in
                            exerciseDetail(exercise)
                        }
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, GlowTheme.Spacing.md)
                    .padding(.top, GlowTheme.Spacing.md)
                }
            }
            .navigationTitle(session.workoutName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GlowTheme.Colors.purple)
                }
            }
        }
    }

    private var sessionHeader: some View {
        GlowCard(glowColor: Color(hex: session.type.colorHex), glowIntensity: 0.6) {
            VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                HStack {
                    Text(session.type.emoji + " " + session.workoutName)
                        .font(GlowTheme.Fonts.headline())
                        .foregroundColor(.white)
                    Spacer()
                }
                if let date = session.completedAt {
                    Text(date, style: .date)
                        .font(GlowTheme.Fonts.caption())
                        .foregroundColor(GlowTheme.Colors.textSecondary)
                }
                HStack(spacing: GlowTheme.Spacing.md) {
                    StatChip(value: "\(session.exerciseCount)", label: "Exercises", color: Color(hex: session.type.colorHex))
                    StatChip(value: "\(session.totalSets)", label: "Sets", color: GlowTheme.Colors.purple)
                    StatChip(value: session.durationDisplay, label: "Duration", color: GlowTheme.Colors.accentBlue)
                }
            }
        }
    }

    private func exerciseDetail(_ exercise: ExerciseSession) -> some View {
        GlowCard(glowIntensity: 0.2) {
            VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                ExerciseRowHeader(name: exercise.exerciseName, category: exercise.category)
                Divider().background(GlowTheme.Colors.textMuted.opacity(0.2))
                ForEach(exercise.sortedSets) { set in
                    HStack {
                        Text("Set \(set.setNumber)")
                            .font(GlowTheme.Fonts.caption())
                            .foregroundColor(GlowTheme.Colors.textTertiary)
                            .frame(width: 46, alignment: .leading)
                        Text(set.displayString)
                            .font(GlowTheme.Fonts.subheadline(14))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(set.volume)) vol")
                            .font(GlowTheme.Fonts.caption(11))
                            .foregroundColor(GlowTheme.Colors.textMuted)
                    }
                }
            }
        }
    }
}
