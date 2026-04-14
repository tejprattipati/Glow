import Foundation
import Combine
import UserNotifications
import UIKit

// MARK: - Rest Timer Manager
// Observable singleton managing the rest timer.
// Persists across tab changes via floating overlay.

@MainActor
final class RestTimerManager: ObservableObject {
    static let shared = RestTimerManager()

    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var totalSeconds: Int = 120
    @Published var remainingSeconds: Int = 120
    @Published var isVisible: Bool = false
    @Published var completedOnce: Bool = false

    private var timer: AnyCancellable?
    private var startDate: Date?
    private var pausedRemaining: Int?

    // Preset durations
    static let presets: [Int] = [60, 90, 120, 180]
    static let presetLabels: [String] = ["1:00", "1:30", "2:00", "3:00"]

    // MARK: - Start
    func start(seconds: Int) {
        stop()
        totalSeconds = seconds
        remainingSeconds = seconds
        isRunning = true
        isPaused = false
        isVisible = true
        completedOnce = false
        startDate = Date()

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.tick()
            }

        scheduleNotification(after: TimeInterval(seconds))
    }

    // MARK: - Restart
    func restart() {
        start(seconds: totalSeconds)
    }

    // MARK: - Pause / Resume
    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }

    func pause() {
        guard isRunning && !isPaused else { return }
        pausedRemaining = remainingSeconds
        isPaused = true
        timer?.cancel()
        cancelNotification()
    }

    func resume() {
        guard isPaused, let rem = pausedRemaining else { return }
        isPaused = false
        remainingSeconds = rem
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.tick()
            }
        scheduleNotification(after: TimeInterval(rem))
    }

    // MARK: - Skip / Stop
    func skip() {
        stop()
        isVisible = false
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
        isPaused = false
        cancelNotification()
    }

    func dismiss() {
        stop()
        isVisible = false
        completedOnce = false
    }

    // MARK: - Quick-add seconds
    func addTime(_ seconds: Int) {
        remainingSeconds = min(remainingSeconds + seconds, 600)
        cancelNotification()
        scheduleNotification(after: TimeInterval(remainingSeconds))
    }

    // MARK: - Tick
    private func tick() {
        guard isRunning && !isPaused else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            timerCompleted()
        }
    }

    private func timerCompleted() {
        stop()
        completedOnce = true
        isVisible = true   // keep visible so user sees it finished

        // Haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Display helpers
    var displayTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var progressColor: String {
        let ratio = Double(remainingSeconds) / Double(totalSeconds)
        if ratio > 0.5 { return "#A855F7" }
        if ratio > 0.25 { return "#FBBF24" }
        return "#F87171"
    }

    // MARK: - Notifications
    private func scheduleNotification(after seconds: TimeInterval) {
        cancelNotification()
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time to hit your next set!"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    }

    // MARK: - Permission request
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
