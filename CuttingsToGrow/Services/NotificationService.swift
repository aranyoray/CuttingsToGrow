import UserNotifications

/// Push reminders that keep cuttings alive: water changes every 3 days and a
/// root-check nudge at the species' expected rooting time.
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleWaterChangeReminder(for cutting: Cutting) {
        let content = UNMutableNotificationContent()
        content.title = "Time to change the water 💧"
        content.body = "\(cutting.nickname) needs fresh water to prevent rot."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3 * 24 * 3600, repeats: true)
        let request = UNNotificationRequest(
            identifier: "water-\(cutting.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleRootCheckReminder(for cutting: Cutting, species: PlantSpecies) {
        let days = cutting.medium == .water
            ? (species.waterRootDays?.lowerBound ?? species.soilRootDays.lowerBound)
            : species.soilRootDays.lowerBound

        let content = UNMutableNotificationContent()
        content.title = "Root check! 🌱"
        content.body = "\(cutting.nickname) may have roots by now — snap a photo to update its progress."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(days * 24 * 3600),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "root-\(cutting.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminders(for cutting: Cutting) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["water-\(cutting.id.uuidString)", "root-\(cutting.id.uuidString)"]
        )
    }
}
