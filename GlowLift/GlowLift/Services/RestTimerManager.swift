import Foundation
import Combine
import UserNotifications
import UIKit
import ActivityKit

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
    private var liveActivity: Activity<RestTimerAttributes>?

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
        startLiveActivity(seconds: seconds)
    }

    func restart() {
        start(seconds: totalSeconds)
    }

    // MARK: - Pause / Resume
    func togglePause() {
        if isPaused { resume() } else { pause() }
    }

    func pause() {
        guard isRunning && !isPaused else { return }
        pausedRemaining = remainingSeconds
        isPaused = true
        timer?.cancel()
        cancelNotification()
        updateLiveActivity(paused: true)
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
        updateLiveActivity(paused: false, newEndDate: Date().addingTimeInterval(TimeInterval(rem)))
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
        endLiveActivity()
    }

    func dismiss() {
        stop()
        isVisible = false
        completedOnce = false
    }

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
        isVisible = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Display
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
        if ratio > 0.5 { return "#4ADE80" }
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

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Live Activity
    private func startLiveActivity(seconds: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let endDate = Date().addingTimeInterval(TimeInterval(seconds))
        let state = RestTimerAttributes.ContentState(
            endDate: endDate,
            totalSeconds: seconds,
            isPaused: false,
            pausedRemaining: seconds
        )
        let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(10))
        liveActivity = try? Activity.request(attributes: RestTimerAttributes(), content: content)
    }

    private func updateLiveActivity(paused: Bool, newEndDate: Date? = nil) {
        guard let activity = liveActivity else { return }
        let end = newEndDate ?? activity.content.state.endDate
        let state = RestTimerAttributes.ContentState(
            endDate: end,
            totalSeconds: totalSeconds,
            isPaused: paused,
            pausedRemaining: remainingSeconds
        )
        let content = ActivityContent(state: state, staleDate: nil)
        Task { await activity.update(content) }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        let state = activity.content.state
        let content = ActivityContent(state: state, staleDate: nil)
        Task {
            await activity.end(content, dismissalPolicy: .immediate)
            liveActivity = nil
        }
    }
}
