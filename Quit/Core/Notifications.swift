import Foundation
import UserNotifications

@MainActor
enum ReminderService {
    static let identifier = "quit.daily.checkin"

    static func configure(hour: Int, minute: Int) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let allowed = try await center.requestAuthorization(options: [.alert, .sound])
        guard allowed else { return false }
        let content = UNMutableNotificationContent()
        content.title = "Petit check-in"
        content.body = "Un instant pour toi."
        // Discreet content and no sound by default.
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        return true
    }

    static func cancel() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
