import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.completedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var streakStates: [StreakState]

    @State private var selectedExercise: String = ""
    @State private var chartMetric: ChartMetric = .topSetWeight

    enum ChartMetric: String, CaseIterable {
        case topSetWeight = "Top Set"
        case totalVolume  = "Volume"
        case setCount     = "Sets"
    }

    private var completedSessions: [WorkoutSession] {
        sessions.filter { $0.isCompleted }
    }

    private var streak: StreakState? { streakStates.first }

    // All exercise names that have been logged
    private var loggedExercises: [String] {
        var names = Set<String>()
        for session in completedSessions {
            for ex in session.exercises where !ex.sets.isEmpty {
                names.insert(ex.exerciseName)
            }
        }
        return Array(names).sorted()
    }

    // Data points for the selected exercise
    private var chartData: [(Date, Double)] {
        guard !selectedExercise.isEmpty else { return [] }
        var points: [(Date, Double)] = []
        for session in completedSessions.reversed() {
            guard let date = session.completedAt else { continue }
            for ex in session.exercises where ex.exerciseName == selectedExercise {
                switch chartMetric {
                case .topSetWeight:
                    if let top = ex.topSet { points.append((date, top.weight)) }
                case .totalVolume:
                    points.append((date, ex.totalVolume))
                case .setCount:
                    points.append((date, Double(ex.setCount)))
                }
            }
        }
        return points
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GlowTheme.Spacing.lg) {
                        overallStats
                        workoutDistribution
                        exerciseProgressSection
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, GlowTheme.Spacing.md)
                    .padding(.top, GlowTheme.Spacing.md)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            if selectedExercise.isEmpty { selectedExercise = loggedExercises.first ?? "" }
        }
    }

    // MARK: - Overall Stats
    private var overallStats: some View {
        VStack(alignment: .leading, spacing: GlowTheme.Spacing.md) {
            SectionHeader(title: "Overview")
            GlowCard(glowColor: GlowTheme.Colors.purple, glowIntensity: 0.6) {
                HStack(spacing: GlowTheme.Spacing.md) {
                    StatChip(value: "\(completedSessions.count)", label: "Total Sessions", color: GlowTheme.Colors.purple)
                    StatChip(value: "\(streak?.currentFlowStreak ?? 0)", label: "Flow Streak", color: GlowTheme.Colors.accent)
                    let totalSets = completedSessions.reduce(0) { $0 + $1.totalSets }
                    StatChip(value: "\(totalSets)", label: "Total Sets", color: GlowTheme.Colors.accentBlue)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Workout Distribution
    private var workoutDistribution: some View {
        VStack(alignment: .leading, spacing: GlowTheme.Spacing.md) {
            SectionHeader(title: "Workout Mix")
            GlowCard(glowIntensity: 0.3) {
                VStack(spacing: GlowTheme.Spacing.sm) {
                    ForEach(WorkoutType.allCases) { type in
                        let count = completedSessions.filter { $0.workoutType == type.rawValue }.count
                        let total = max(completedSessions.count, 1)
                        let ratio = Double(count) / Double(total)
                        HStack(spacing: GlowTheme.Spacing.sm) {
                            Text(type.emoji)
                            Text(type.rawValue)
                                .font(GlowTheme.Fonts.caption())
                                .foregroundColor(GlowTheme.Colors.textSecondary)
                                .frame(width: 70, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(GlowTheme.Colors.textMuted.opacity(0.2))
                                    Capsule()
                                        .fill(Color(hex: type.colorHex))
                                        .frame(width: geo.size.width * CGFloat(ratio))
                                }
                            }
                            .frame(height: 6)
                            Text("\(count)")
                                .font(GlowTheme.Fonts.caption(12))
                                .foregroundColor(GlowTheme.Colors.textTertiary)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Exercise Progress
    @ViewBuilder
    private var exerciseProgressSection: some View {
        VStack(alignment: .leading, spacing: GlowTheme.Spacing.md) {
            SectionHeader(title: "Exercise Progress")

            if loggedExercises.isEmpty {
                GlowCard(glowIntensity: 0.2) {
                    Text("Log some workouts to see progress charts.")
                        .font(GlowTheme.Fonts.body())
                        .foregroundColor(GlowTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, GlowTheme.Spacing.md)
                }
            } else {
                // Exercise picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: GlowTheme.Spacing.sm) {
                        ForEach(loggedExercises, id: \.self) { ex in
                            Button(action: { selectedExercise = ex }) {
                                Text(ex)
                                    .font(GlowTheme.Fonts.caption(12))
                                    .lineLimit(1)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule()
                                            .fill(selectedExercise == ex
                                                  ? GlowTheme.Colors.purple.opacity(0.3)
                                                  : GlowTheme.Colors.surfaceElevated)
                                            .overlay(
                                                Capsule()
                                                    .stroke(selectedExercise == ex
                                                            ? GlowTheme.Colors.purple
                                                            : Color.clear, lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(selectedExercise == ex ? GlowTheme.Colors.purpleLight : GlowTheme.Colors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, GlowTheme.Spacing.sm)
                }

                // Metric picker
                Picker("Metric", selection: $chartMetric) {
                    ForEach(ChartMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .tint(GlowTheme.Colors.purple)

                // Chart
                if chartData.isEmpty {
                    GlowCard(glowIntensity: 0.1) {
                        Text("No data for \(selectedExercise) yet.")
                            .font(GlowTheme.Fonts.body())
                            .foregroundColor(GlowTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                } else {
                    GlowCard(glowColor: GlowTheme.Colors.purple, glowIntensity: 0.5) {
                        VStack(alignment: .leading, spacing: GlowTheme.Spacing.sm) {
                            Text(selectedExercise)
                                .font(GlowTheme.Fonts.subheadline())
                                .foregroundColor(.white)

                            Chart {
                                ForEach(chartData, id: \.0) { point in
                                    LineMark(
                                        x: .value("Date", point.0),
                                        y: .value(chartMetric.rawValue, point.1)
                                    )
                                    .foregroundStyle(GlowTheme.Colors.gradientAccent)
                                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                                    PointMark(
                                        x: .value("Date", point.0),
                                        y: .value(chartMetric.rawValue, point.1)
                                    )
                                    .foregroundStyle(GlowTheme.Colors.purpleLight)
                                    .symbolSize(36)

                                    AreaMark(
                                        x: .value("Date", point.0),
                                        y: .value(chartMetric.rawValue, point.1)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [GlowTheme.Colors.purple.opacity(0.3), .clear],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                                }
                            }
                            .frame(height: 180)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) {
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                        .foregroundStyle(GlowTheme.Colors.textTertiary)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisValueLabel()
                                        .foregroundStyle(GlowTheme.Colors.textTertiary)
                                    AxisGridLine()
                                        .foregroundStyle(GlowTheme.Colors.textMuted.opacity(0.2))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
