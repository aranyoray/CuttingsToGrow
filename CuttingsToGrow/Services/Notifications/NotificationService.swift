import Foundation
import UserNotifications

/// Local reminders that keep cuttings alive:
/// - a repeating **water-change** nudge every 3 days (water-propagated cuttings),
/// - a one-time **root-check** nudge at the species' expected rooting time.
///
/// Everything is keyed to the cutting's `id`, so a reminder can be cancelled
/// cleanly when the cutting is deleted or becomes rooted. All local — no server,
/// no account.
///
/// In DEBUG builds the intervals are compressed to seconds so a reminder actually
/// fires during a live demo; release builds use the real 3-day / N-day timing.
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: Timing (compressed in DEBUG so you can film a notification firing)

    #if DEBUG
    private let waterInterval: TimeInterval = 60 // repeating trigger minimum
    private func rootInterval(days: Int) -> TimeInterval { 25 }
    #else
    private let waterInterval: TimeInterval = 3 * 24 * 3600
    private func rootInterval(days: Int) -> TimeInterval { TimeInterval(days) * 24 * 3600 }
    #endif

    // MARK: Authorization

    /// Ask for permission. Safe to call repeatedly; iOS only prompts once.
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: Scheduling

    /// Schedule (or reschedule) the repeating water-change reminder. No-op for
    /// non-water cuttings.
    func scheduleWaterReminder(for cutting: Cutting) {
        guard cutting.medium == .water else { return }
        let content = UNMutableNotificationContent()
        content.title = "Time to change the water 💧"
        content.body = "\(cutting.displayName) needs fresh water to prevent rot."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: waterInterval, repeats: true)
        add(id: Self.waterID(cutting.id), content: content, trigger: trigger)
    }

    /// Schedule a one-time nudge at the species' expected rooting time.
    func scheduleRootCheckReminder(for cutting: Cutting, species: PlantSpecies) {
        guard let days = species.rootTimeDays(in: cutting.medium)
                ?? species.rootTimeSoilDays
                ?? species.rootTimeWaterDays,
              days > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Root check! 🌱"
        content.body = "\(cutting.displayName) may have roots by now — snap a photo to update its progress."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: rootInterval(days: days), repeats: false)
        add(id: Self.rootID(cutting.id), content: content, trigger: trigger)
    }

    /// Schedule both reminders appropriate to a freshly-created cutting.
    func scheduleReminders(for cutting: Cutting, species: PlantSpecies?) {
        scheduleWaterReminder(for: cutting)
        if let species { scheduleRootCheckReminder(for: cutting, species: species) }
    }

    // MARK: Cancellation

    func cancelReminders(for cutting: Cutting) {
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.waterID(cutting.id), Self.rootID(cutting.id)]
        )
    }

    func cancelWaterReminder(for cutting: Cutting) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.waterID(cutting.id)])
    }

    // MARK: Helpers

    private static func waterID(_ id: UUID) -> String { "water-\(id.uuidString)" }
    private static func rootID(_ id: UUID) -> String { "root-\(id.uuidString)" }

    private func add(id: String, content: UNMutableNotificationContent, trigger: UNNotificationTrigger) {
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
