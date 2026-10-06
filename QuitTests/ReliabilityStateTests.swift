import SwiftUI
import UserNotifications
import XCTest
@testable import Quit

@MainActor
final class ReliabilityStateTests: XCTestCase {
    func testBackgroundDiscardsLateAuthenticationSuccess() throws {
        var lock = AppLockState()
        let request = try XCTUnwrap(lock.beginAuthentication())
        lock.sceneChanged(to: .background)
        XCTAssertFalse(lock.finishAuthentication(request, succeeded: true, phase: .active))
        XCTAssertFalse(lock.unlocked)
        XCTAssertFalse(lock.authenticating)
    }

    func testOldAuthenticationCannotFinishNewRequest() throws {
        var lock = AppLockState()
        let old = try XCTUnwrap(lock.beginAuthentication())
        lock.sceneChanged(to: .background)
        let current = try XCTUnwrap(lock.beginAuthentication())
        XCTAssertFalse(lock.finishAuthentication(old, succeeded: true, phase: .active))
        XCTAssertTrue(lock.authenticating)
        XCTAssertTrue(lock.finishAuthentication(current, succeeded: true, phase: .active))
        XCTAssertTrue(lock.unlocked)
    }

    func testSystemPromptCanFinishWhileInactive() throws {
        var lock = AppLockState()
        let request = try XCTUnwrap(lock.beginAuthentication())
        lock.sceneChanged(to: .inactive)
        XCTAssertTrue(lock.finishAuthentication(request, succeeded: true, phase: .inactive))
        XCTAssertFalse(lock.unlocked)
        lock.sceneChanged(to: .active)
        XCTAssertTrue(lock.unlocked)
        lock.sceneChanged(to: .inactive)
        XCTAssertFalse(lock.unlocked)
    }

    func testBackgroundAlsoDiscardsSuccessWaitingForActivation() throws {
        var lock = AppLockState()
        let request = try XCTUnwrap(lock.beginAuthentication())
        XCTAssertTrue(lock.finishAuthentication(request, succeeded: true, phase: .inactive))
        lock.sceneChanged(to: .background)
        lock.sceneChanged(to: .active)
        XCTAssertFalse(lock.unlocked)
    }

    func testFailureAllowsRetryAndDuplicateRequestsAreIgnored() throws {
        var lock = AppLockState()
        let request = try XCTUnwrap(lock.beginAuthentication())
        XCTAssertNil(lock.beginAuthentication())
        XCTAssertTrue(lock.finishAuthentication(request, succeeded: false, phase: .active))
        XCTAssertFalse(lock.unlocked)
        XCTAssertNotNil(lock.beginAuthentication())
    }

    func testRevokedPermissionNeverReportsScheduledReminder() {
        XCTAssertEqual(ReminderStatus.resolve(enabled: true, authorization: .denied,
                                              matchingRequest: true, alertsEnabled: true), .denied)
        XCTAssertEqual(ReminderStatus.resolve(enabled: false, authorization: .denied,
                                              matchingRequest: false, alertsEnabled: false), .denied)
    }

    func testMissingOrDifferentScheduleNeedsReactivation() {
        XCTAssertEqual(ReminderStatus.resolve(enabled: true, authorization: .authorized,
                                              matchingRequest: false, alertsEnabled: true), .notScheduled)
    }

    func testProvisionalOrDisabledAlertsAreReportedAsQuiet() {
        XCTAssertEqual(ReminderStatus.resolve(enabled: true, authorization: .provisional,
                                              matchingRequest: true, alertsEnabled: true), .quiet)
        XCTAssertEqual(ReminderStatus.resolve(enabled: true, authorization: .authorized,
                                              matchingRequest: true, alertsEnabled: false), .quiet)
    }

    func testReminderRequiresBothAuthorizationAndMatchingRequest() {
        XCTAssertEqual(ReminderStatus.resolve(enabled: true, authorization: .notDetermined,
                                              matchingRequest: true, alertsEnabled: true), .permissionRequired)
        XCTAssertEqual(ReminderStatus.resolve(enabled: true, authorization: .authorized,
                                              matchingRequest: true, alertsEnabled: true), .scheduled)
    }

    func testDisabledReminderStaysDisabledDespitePendingRequest() {
        XCTAssertEqual(ReminderStatus.resolve(enabled: false, authorization: .authorized,
                                              matchingRequest: true, alertsEnabled: true), .disabled)
    }

    func testScheduledRequestMustMatchIdentityRepeatingHourAndMinute() {
        let content = UNMutableNotificationContent()
        let daily = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 21, minute: 30), repeats: true)
        let request = UNNotificationRequest(identifier: ReminderService.identifier, content: content, trigger: daily)
        XCTAssertTrue(ReminderService.matches(request, hour: 21, minute: 30))
        XCTAssertFalse(ReminderService.matches(request, hour: 20, minute: 30))
        XCTAssertFalse(ReminderService.matches(request, hour: 21, minute: 0))
        XCTAssertFalse(ReminderService.matches(UNNotificationRequest(identifier: "another", content: content, trigger: daily),
                                              hour: 21, minute: 30))
        let once = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 21, minute: 30), repeats: false)
        XCTAssertFalse(ReminderService.matches(UNNotificationRequest(identifier: ReminderService.identifier, content: content, trigger: once),
                                              hour: 21, minute: 30))
        let interval = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        XCTAssertFalse(ReminderService.matches(UNNotificationRequest(identifier: ReminderService.identifier, content: content, trigger: interval),
                                              hour: 21, minute: 30))
    }
}
