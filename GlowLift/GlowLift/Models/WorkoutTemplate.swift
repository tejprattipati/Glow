import Foundation
import SwiftData

// MARK: - Workout Type (the six-day split)
enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case pushA  = "Push A"
    case pullA  = "Pull A"
    case legsA  = "Legs A"
    case pushB  = "Push B"
    case pullB  = "Pull B"
    case legsB  = "Legs B"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .pushA: return "💪"
        case .pullA: return "🔙"
        case .legsA: return "🦵"
        case .pushB: return "🏋️"
        case .pullB: return "🧲"
        case .legsB: return "⚡"
        }
    }

    var colorHex: String {
        switch self {
        case .pushA:  return "#A855F7"
        case .pullA:  return "#818CF8"
        case .legsA:  return "#34D399"
        case .pushB:  return "#E879F9"
        case .pullB:  return "#60A5FA"
        case .legsB:  return "#FBBF24"
        }
    }

    var sequenceIndex: Int {
        switch self {
        case .pushA: return 0
        case .pullA: return 1
        case .legsA: return 2
        case .pushB: return 3
        case .pullB: return 4
        case .legsB: return 5
        }
    }

    var next: WorkoutType {
        let all = WorkoutType.allCases
        let nextIndex = (sequenceIndex + 1) % all.count
        return all[nextIndex]
    }

    var focus: String {
        switch self {
        case .pushA:  return "Chest Emphasis"
        case .pullA:  return "Lat + Upper Back"
        case .legsA:  return "Quad Focus"
        case .pushB:  return "Upper Chest / Shoulder"
        case .pullB:  return "Back Thickness"
        case .legsB:  return "Squat Pattern"
        }
    }
}

// MARK: - Workout Exercise Template (exercise in a template)
@Model
final class WorkoutExerciseTemplate {
    var id: UUID
    var exerciseName: String
    var exerciseCategory: String
    var orderIndex: Int
    var defaultSets: Int
    var defaultReps: String        // e.g. "8-12"
    var defaultWeight: Double
    var restSeconds: Int
    var notes: String

    @Relationship(deleteRule: .nullify)
    var workout: WorkoutTemplate?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        exerciseCategory: ExerciseCategory,
        orderIndex: Int,
        defaultSets: Int = 3,
        defaultReps: String = "8-12",
        defaultWeight: Double = 0,
        restSeconds: Int? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.exerciseCategory = exerciseCategory.rawValue
        self.orderIndex = orderIndex
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
        self.restSeconds = restSeconds ?? exerciseCategory.defaultRestSeconds
        self.notes = notes
    }

    var category: ExerciseCategory {
        ExerciseCategory(rawValue: exerciseCategory) ?? .other
    }
}

// MARK: - Workout Template
@Model
final class WorkoutTemplate {
    var id: UUID
    var workoutType: String           // WorkoutType.rawValue
    var name: String
    var notes: String
    var isEdited: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExerciseTemplate.workout)
    var exercises: [WorkoutExerciseTemplate]

    init(
        id: UUID = UUID(),
        workoutType: WorkoutType,
        name: String? = nil,
        notes: String = "",
        exercises: [WorkoutExerciseTemplate] = []
    ) {
        self.id = id
        self.workoutType = workoutType.rawValue
        self.name = name ?? workoutType.rawValue
        self.notes = notes
        self.isEdited = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.exercises = exercises
    }

    var type: WorkoutType {
        WorkoutType(rawValue: workoutType) ?? .pushA
    }

    var sortedExercises: [WorkoutExerciseTemplate] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}
