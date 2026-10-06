import Foundation
import UserNotifications

enum ReminderStatus: Equatable {
    case disabled, permissionRequired, denied, notScheduled, scheduled, quiet

    var message: String {
        switch self {
        case .disabled: "Rappel désactivé."
        case .permissionRequired: "Autorisation nécessaire. Active le rappel pour la demander."
        case .denied: "Notifications refusées dans iOS. Autorise-les dans les réglages iOS si cette installation le permet."
        case .notScheduled: "Aucun rappel programmé à cette heure. Réactive-le si tu le souhaites."
        case .scheduled: "Rappel programmé. Sa réception dépend des réglages iOS et de ton installation."
        case .quiet: "Rappel programmé ; les alertes peuvent rester discrètes. Vérifie les réglages de notifications iOS."
        }
    }

    static func resolve(enabled: Bool, authorization: UNAuthorizationStatus,
                        matchingRequest: Bool, alertsEnabled: Bool) -> Self {
        if authorization == .denied { return .denied }
        guard enabled else { return .disabled }
        switch authorization {
        case .denied: return .denied
        case .notDetermined: return .permissionRequired
        case .authorized, .provisional, .ephemeral:
            guard matchingRequest else { return .notScheduled }
            return authorization == .provisional || !alertsEnabled ? .quiet : .scheduled
        @unknown default: return .permissionRequired
        }
    }
}

@MainActor
enum ReminderService {
    static let identifier = "quit.daily.checkin"

    static func status(for profile: UserProfile) async -> ReminderStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let requests = await center.pendingNotificationRequests()
        let matchingRequest = requests.contains { matches($0, hour: profile.reminderHour, minute: profile.reminderMinute) }
        return ReminderStatus.resolve(enabled: profile.reminderEnabled, authorization: settings.authorizationStatus,
                                      matchingRequest: matchingRequest, alertsEnabled: settings.alertSetting == .enabled)
    }

    static func matches(_ request: UNNotificationRequest, hour: Int, minute: Int) -> Bool {
        guard request.identifier == identifier,
              let trigger = request.trigger as? UNCalendarNotificationTrigger else { return false }
        return trigger.repeats && trigger.dateComponents.hour == hour && trigger.dateComponents.minute == minute
    }

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
