import Foundation
import SwiftData

// MARK: - Exercise Category
enum ExerciseCategory: String, Codable, CaseIterable {
    case chestPress     = "Chest Press"
    case inclinePress   = "Incline Press"
    case fly            = "Fly"
    case shoulderPress  = "Shoulder Press"
    case lateralRaise   = "Lateral Raise"
    case triceps        = "Triceps"
    case pulldown       = "Pulldown"
    case row            = "Row"
    case rearDelt       = "Rear Delt"
    case curl           = "Curl"
    case legPress       = "Leg Press"
    case squat          = "Squat"
    case legCurl        = "Leg Curl"
    case rdl            = "RDL / Hip Hinge"
    case calfRaise      = "Calf Raise"
    case abs            = "Abs"
    case shrug          = "Shrug"
    case other          = "Other"

    var sfSymbol: String {
        switch self {
        case .chestPress:    return "figure.strengthtraining.traditional"
        case .inclinePress:  return "arrow.up.right.circle.fill"
        case .fly:           return "arrow.left.and.right.circle.fill"
        case .shoulderPress: return "arrow.up.circle.fill"
        case .lateralRaise:  return "arrow.up.and.down.and.arrow.left.and.right"
        case .triceps:       return "hand.point.up.left.fill"
        case .pulldown:      return "arrow.down.circle.fill"
        case .row:           return "arrow.backward.circle.fill"
        case .rearDelt:      return "arrow.left.circle.fill"
        case .curl:          return "figure.arms.open"
        case .legPress:      return "figure.walk"
        case .squat:         return "figure.squat"
        case .legCurl:       return "figure.flexibility"
        case .rdl:           return "figure.cooldown"
        case .calfRaise:     return "figure.step.training"
        case .abs:           return "figure.core.training"
        case .shrug:         return "figure.mind.and.body"
        case .other:         return "dumbbell.fill"
        }
    }

    var defaultRestSeconds: Int {
        switch self {
        case .chestPress, .inclinePress, .shoulderPress, .legPress, .squat, .rdl:
            return 180
        case .fly, .lateralRaise, .rearDelt, .curl, .triceps:
            return 90
        case .pulldown, .row:
            return 120
        case .legCurl, .calfRaise:
            return 90
        case .abs, .shrug, .other:
            return 60
        }
    }
}

// MARK: - Exercise Definition
@Model
final class ExerciseDefinition {
    var id: UUID
    var name: String
    var category: String       // ExerciseCategory.rawValue
    var notes: String
    var defaultRestSeconds: Int
    var isCustom: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        notes: String = "",
        defaultRestSeconds: Int? = nil,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category.rawValue
        self.notes = notes
        self.defaultRestSeconds = defaultRestSeconds ?? category.defaultRestSeconds
        self.isCustom = isCustom
        self.createdAt = Date()
    }

    var exerciseCategory: ExerciseCategory {
        ExerciseCategory(rawValue: category) ?? .other
    }

    var sfSymbol: String { exerciseCategory.sfSymbol }
}
