import Foundation
import SwiftData

// MARK: - Set Entry
@Model
final class SetEntry {
    var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
    var notes: String
    var rir: Int?                 // Reps In Reserve
    var completedAt: Date
    var isWarmup: Bool

    @Relationship(deleteRule: .nullify)
    var exerciseSession: ExerciseSession?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double,
        reps: Int,
        notes: String = "",
        rir: Int? = nil,
        isWarmup: Bool = false
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.notes = notes
        self.rir = rir
        self.completedAt = Date()
        self.isWarmup = isWarmup
    }

    var volume: Double { weight * Double(reps) }

    var displayString: String {
        if weight > 0 {
            return "\(formattedWeight) × \(reps)"
        } else {
            return "\(reps) reps"
        }
    }

    var formattedWeight: String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(format: "%.1f", weight)
    }
}

// MARK: - Exercise Session (one exercise within a workout session)
@Model
final class ExerciseSession {
    var id: UUID
    var exerciseName: String
    var exerciseCategory: String
    var orderIndex: Int
    var isCompleted: Bool
    var notes: String
    var startedAt: Date?
    var completedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.exerciseSession)
    var sets: [SetEntry]

    @Relationship(deleteRule: .nullify)
    var workoutSession: WorkoutSession?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        exerciseCategory: ExerciseCategory = .other,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.exerciseCategory = exerciseCategory.rawValue
        self.orderIndex = orderIndex
        self.isCompleted = false
        self.notes = ""
        self.sets = []
    }

    var category: ExerciseCategory {
        ExerciseCategory(rawValue: exerciseCategory) ?? .other
    }

    var sortedSets: [SetEntry] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }

    var topSet: SetEntry? {
        sets.filter { !$0.isWarmup }.max { $0.weight < $1.weight }
    }

    var setCount: Int { sets.filter { !$0.isWarmup }.count }

    var displaySummary: String {
        guard let top = topSet else { return "\(sets.count) sets" }
        return "\(setCount) × \(top.displayString)"
    }
}

// MARK: - Workout Session
@Model
final class WorkoutSession {
    var id: UUID
    var workoutType: String           // WorkoutType.rawValue
    var workoutName: String
    var startedAt: Date
    var completedAt: Date?
    var isCompleted: Bool
    var notes: String
    var bodyweight: Double?           // optional bodyweight that day

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSession.workoutSession)
    var exercises: [ExerciseSession]

    init(
        id: UUID = UUID(),
        workoutType: WorkoutType,
        workoutName: String? = nil
    ) {
        self.id = id
        self.workoutType = workoutType.rawValue
        self.workoutName = workoutName ?? workoutType.rawValue
        self.startedAt = Date()
        self.isCompleted = false
        self.notes = ""
        self.exercises = []
    }

    var type: WorkoutType {
        WorkoutType(rawValue: workoutType) ?? .pushA
    }

    var duration: TimeInterval? {
        guard let end = completedAt else { return nil }
        return end.timeIntervalSince(startedAt)
    }

    var durationDisplay: String {
        guard let d = duration else { return "In progress" }
        let mins = Int(d) / 60
        let hrs = mins / 60
        let remainMins = mins % 60
        if hrs > 0 { return "\(hrs)h \(remainMins)m" }
        return "\(mins)m"
    }

    var sortedExercises: [ExerciseSession] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.setCount }
    }

    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.totalVolume }
    }

    var exerciseCount: Int { exercises.filter { $0.isCompleted || !$0.sets.isEmpty }.count }
}
