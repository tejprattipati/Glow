import Foundation
import SwiftData

// MARK: - Special Circumstance Type
enum SpecialCircumstanceType: String, Codable, CaseIterable {
    case illness    = "Illness"
    case travel     = "Travel"
    case examWeek   = "Exam / Study"
    case injury     = "Injury"
    case deload     = "Deload Week"
    case personal   = "Personal"
    case other      = "Other"

    var sfSymbol: String {
        switch self {
        case .illness:   return "cross.circle.fill"
        case .travel:    return "airplane.circle.fill"
        case .examWeek:  return "book.circle.fill"
        case .injury:    return "bandage.fill"
        case .deload:    return "arrow.down.circle.fill"
        case .personal:  return "person.circle.fill"
        case .other:     return "questionmark.circle.fill"
        }
    }

    var breaksStreak: Bool {
        switch self {
        case .illness, .travel, .examWeek, .injury, .deload:
            return false
        case .personal, .other:
            return false   // by default, special days don't break streak
        }
    }
}

// MARK: - Special Circumstance Day
@Model
final class SpecialCircumstanceDay {
    var id: UUID
    var date: Date
    var circumstanceType: String
    var notes: String
    var countedAgainstStreak: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        circumstanceType: SpecialCircumstanceType,
        notes: String = "",
        countedAgainstStreak: Bool = false
    ) {
        self.id = id
        self.date = date
        self.circumstanceType = circumstanceType.rawValue
        self.notes = notes
        self.countedAgainstStreak = countedAgainstStreak
    }

    var type: SpecialCircumstanceType {
        SpecialCircumstanceType(rawValue: circumstanceType) ?? .other
    }
}

// MARK: - Streak State
@Model
final class StreakState {
    var id: UUID

    // Current training flow streak (consecutive workouts completed without long gaps)
    var currentFlowStreak: Int
    var longestFlowStreak: Int

    // Calendar streak (consecutive calendar days trained)
    var currentCalendarStreak: Int
    var longestCalendarStreak: Int

    // Totals
    var totalSessionsAllTime: Int
    var totalSessionsThisMonth: Int

    // Dates
    var lastTrainedDate: Date?
    var streakStartDate: Date?

    // Max allowed rest days before breaking flow streak
    var maxRestDaysBeforeBreak: Int

    var updatedAt: Date

    init() {
        self.id = UUID()
        self.currentFlowStreak = 0
        self.longestFlowStreak = 0
        self.currentCalendarStreak = 0
        self.longestCalendarStreak = 0
        self.totalSessionsAllTime = 0
        self.totalSessionsThisMonth = 0
        self.lastTrainedDate = nil
        self.streakStartDate = nil
        self.maxRestDaysBeforeBreak = 3
        self.updatedAt = Date()
    }

    var streakStatus: StreakStatus {
        guard let last = lastTrainedDate else { return .noData }
        let daysSince = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        if daysSince == 0 { return .trainedToday }
        if daysSince <= maxRestDaysBeforeBreak { return .active }
        return .broken
    }

    var streakStatusDescription: String {
        switch streakStatus {
        case .noData:       return "Start your first session!"
        case .trainedToday: return "Trained today — great work!"
        case .active:       return "Active — keep it going!"
        case .broken:       return "Streak broken — restart today!"
        }
    }
}

enum StreakStatus {
    case noData, trainedToday, active, broken
}
