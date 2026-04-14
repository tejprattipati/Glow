import Foundation
import SwiftData

// MARK: - Streak Engine
// Manages both flow streak and calendar streak with special-circumstance support.

final class StreakEngine {

    // Recalculates streak state from session history + special circumstance days.
    static func recalculate(
        sessions: [WorkoutSession],
        specialDays: [SpecialCircumstanceDay],
        preferences: UserPreferences,
        streakState: StreakState
    ) {
        let completed = sessions
            .filter { $0.isCompleted }
            .compactMap { $0.completedAt }
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted()

        guard !completed.isEmpty else {
            streakState.currentFlowStreak = 0
            streakState.currentCalendarStreak = 0
            streakState.lastTrainedDate = nil
            streakState.updatedAt = Date()
            return
        }

        let specialDates = Set(
            specialDays
                .filter { !$0.countedAgainstStreak }
                .map { Calendar.current.startOfDay(for: $0.date) }
        )

        let maxRest = preferences.maxRestDaysBeforeBreak
        let today = Calendar.current.startOfDay(for: Date())

        // Flow streak: each session counts as +1; gaps beyond maxRest break it
        var flowStreak = 0
        var calStreak = 0
        var longestFlow = 0
        var longestCal = 0

        // Calculate current flow streak (working backwards from last session)
        var flowCount = 0
        var prevDate: Date? = nil

        for date in completed.reversed() {
            if let prev = prevDate {
                let gap = Calendar.current.dateComponents([.day], from: date, to: prev).day ?? 0
                // Check if any special days cover the gap
                let gapFilled = specialDates.contains { d in
                    d > date && d < prev
                }
                let effectiveGap = gapFilled ? 1 : gap
                if effectiveGap > maxRest + 1 {
                    break
                }
            }
            flowCount += 1
            prevDate = date
        }
        flowStreak = flowCount

        // Check if the streak is still alive (not too many days since last session)
        if let last = completed.last {
            let daysSince = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 0
            let gapCovered = specialDates.contains { d in
                d > last && d <= today
            }
            if daysSince > maxRest && !gapCovered {
                flowStreak = 0
            }
        }

        // Calendar streak: consecutive calendar days with a session
        var calCount = 0
        var currentDate = today
        while true {
            if completed.contains(currentDate) {
                calCount += 1
            } else if specialDates.contains(currentDate) {
                // special day: skip without breaking
            } else {
                break
            }
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        }
        calStreak = calCount

        // Longest streaks
        longestFlow = max(streakState.longestFlowStreak, flowStreak)
        longestCal  = max(streakState.longestCalendarStreak, calStreak)

        // Total sessions
        let allSessions = sessions.filter { $0.isCompleted }
        let thisMonthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: today))!
        let thisMonth = allSessions.filter {
            guard let d = $0.completedAt else { return false }
            return d >= thisMonthStart
        }.count

        streakState.currentFlowStreak     = flowStreak
        streakState.currentCalendarStreak = calStreak
        streakState.longestFlowStreak     = longestFlow
        streakState.longestCalendarStreak = longestCal
        streakState.totalSessionsAllTime  = allSessions.count
        streakState.totalSessionsThisMonth = thisMonth
        streakState.lastTrainedDate       = completed.last
        streakState.maxRestDaysBeforeBreak = maxRest
        streakState.updatedAt             = Date()

        if flowStreak > 0 && streakState.streakStartDate == nil {
            // Estimate streak start
            streakState.streakStartDate = completed.last
        }
    }

    // Returns a human-readable explanation for the current streak status
    static func streakExplanation(
        state: StreakState,
        specialDays: [SpecialCircumstanceDay]
    ) -> String {
        let status = state.streakStatus
        switch status {
        case .noData:
            return "Complete your first workout to start your streak."
        case .trainedToday:
            return "You trained today! Flow streak: \(state.currentFlowStreak) session\(state.currentFlowStreak == 1 ? "" : "s") in a row."
        case .active:
            guard let last = state.lastTrainedDate else { return "" }
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            let remaining = state.maxRestDaysBeforeBreak - days
            return "Last trained \(days) day\(days == 1 ? "" : "s") ago. \(remaining) rest day\(remaining == 1 ? "" : "s") remaining before streak breaks."
        case .broken:
            return "Streak broken. Log today's session to start a new one!"
        }
    }
}
