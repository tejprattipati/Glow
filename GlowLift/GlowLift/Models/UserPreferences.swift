import Foundation
import SwiftData

// MARK: - Weight Unit
enum WeightUnit: String, Codable, CaseIterable {
    case lbs = "lbs"
    case kg  = "kg"

    var conversionToLbs: Double {
        switch self {
        case .lbs: return 1.0
        case .kg:  return 2.20462
        }
    }
}

// MARK: - User Preferences
@Model
final class UserPreferences {
    var id: UUID

    // Units
    var weightUnit: String        // WeightUnit.rawValue
    var defaultRestSeconds: Int

    // Streak behavior
    var maxRestDaysBeforeBreak: Int
    var specialCircumstanceDontBreakStreak: Bool

    // Haptics / sound
    var hapticsEnabled: Bool
    var soundEnabled: Bool

    // Claude API
    var claudeModel: String
    var claudeMaxTokens: Int

    // Appearance
    var showBodyweight: Bool

    var updatedAt: Date

    init() {
        self.id = UUID()
        self.weightUnit = WeightUnit.lbs.rawValue
        self.defaultRestSeconds = 120
        self.maxRestDaysBeforeBreak = 3
        self.specialCircumstanceDontBreakStreak = true
        self.hapticsEnabled = true
        self.soundEnabled = true
        self.claudeModel = "claude-opus-4-6"
        self.claudeMaxTokens = 1024
        self.showBodyweight = false
        self.updatedAt = Date()
    }

    var unit: WeightUnit {
        WeightUnit(rawValue: weightUnit) ?? .lbs
    }
}
