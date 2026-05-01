import ActivityKit
import Foundation

struct RestTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endDate: Date
        var totalSeconds: Int
        var isPaused: Bool
        var pausedRemaining: Int

        var pausedTimeDisplay: String {
            let m = pausedRemaining / 60
            let s = pausedRemaining % 60
            return String(format: "%d:%02d", m, s)
        }
    }
}
