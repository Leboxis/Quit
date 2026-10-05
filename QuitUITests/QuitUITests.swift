import XCTest

@MainActor
final class QuitUITests: XCTestCase {
    func testOnboardingCheckInAndSOSCanBeCompleted() {
        let app = XCUIApplication()
        app.launch()
        if app.buttons["onboarding.next"].waitForExistence(timeout: 5) {
            app.buttons["onboarding.next"].tap()
            app.textFields["onboarding.intention"].tap()
            app.textFields["onboarding.intention"].typeText("Retrouver mes soirees")
            app.buttons["onboarding.next"].tap()
            app.buttons["onboarding.next"].tap()
        }
        XCTAssertTrue(app.buttons["checkin.open"].waitForExistence(timeout: 5))
        app.buttons["checkin.open"].tap()
        app.buttons["checkin.save"].tap()
        XCTAssertTrue(app.buttons["sos.open"].waitForExistence(timeout: 5))
        app.buttons["sos.open"].tap()
        app.buttons["sos.start"].tap()
        app.buttons["sos.pause.done"].tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["sos.observe.next"].waitForExistence(timeout: 5))
        app.buttons["sos.observe.next"].tap()
        app.swipeUp()
        app.buttons["sos.action.done"].tap()
        app.swipeUp()
        app.buttons["sos.save"].tap()
        XCTAssertTrue(app.buttons["sos.finish"].waitForExistence(timeout: 5))
        app.buttons["sos.finish"].tap()
        XCTAssertTrue(app.tabBars.buttons["Comprendre"].exists)
        app.tabBars.buttons["Comprendre"].tap()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Quit-Comprendre"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
