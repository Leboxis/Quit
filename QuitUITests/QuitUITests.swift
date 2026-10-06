import XCTest

@MainActor
final class QuitUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func application(largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["QUIT_UI_TEST_VAULT"] = UUID().uuidString
        if largeText { app.launchEnvironment["QUIT_UI_LARGE_TEXT"] = "1" }
        return app
    }

    func testOnboardingCheckInAndSOSCanBeCompleted() {
        let app = application()
        app.launch()
        if app.buttons["onboarding.next"].waitForExistence(timeout: 5) {
            app.buttons["onboarding.next"].tap()
            app.textFields["onboarding.intention"].tap()
            app.textFields["onboarding.intention"].typeText("Retrouver mes soirees")
            app.buttons["onboarding.next"].tap()
            app.buttons["onboarding.next"].tap()
        }
        XCTAssertTrue(app.buttons["checkin.open"].waitForExistence(timeout: 5))
        capture(app, name: "V2-Aujourd-hui-Sauge")
        app.buttons["settings.open"].tap()
        app.buttons["appearance.open"].tap()
        XCTAssertTrue(app.buttons["theme.sand"].waitForExistence(timeout: 5))
        reveal(app.buttons["theme.sand"], in: app)
        app.buttons["theme.sand"].tap()
        capture(app, name: "V2-Apparence-Sable")
        app.buttons["theme.slate"].tap()
        reveal(app.segmentedControls["appearance.mode"], in: app)
        app.segmentedControls["appearance.mode"].buttons["Sombre"].tap()
        reveal(app.switches["comfort.reduceMotion"], in: app)
        app.switches["comfort.reduceMotion"].tap()
        reveal(app.switches["comfort.haptics"], in: app)
        app.switches["comfort.haptics"].tap()
        reveal(app.segmentedControls["comfort.duration"], in: app)
        app.segmentedControls["comfort.duration"].buttons["3 min"].tap()
        capture(app, name: "V2-Confort-Sombre")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["settings.open"].waitForExistence(timeout: 5))
        app.buttons["settings.open"].tap()
        app.buttons["appearance.open"].tap()
        XCTAssertTrue(app.buttons["theme.slate"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["theme.slate"].isSelected)
        XCTAssertTrue(app.segmentedControls["appearance.mode"].buttons["Sombre"].isSelected)
        reveal(app.switches["comfort.reduceMotion"], in: app)
        XCTAssertEqual(app.switches["comfort.reduceMotion"].value as? String, "1")
        XCTAssertEqual(app.switches["comfort.haptics"].value as? String, "0")
        reveal(app.segmentedControls["comfort.duration"], in: app)
        XCTAssertTrue(app.segmentedControls["comfort.duration"].buttons["3 min"].isSelected)
        app.navigationBars["Apparence et confort"].buttons["Réglages"].tap()
        app.buttons["settings.done"].tap()
        capture(app, name: "V2-Aujourd-hui-Brume-Sombre")
        app.buttons["checkin.open"].tap()
        capture(app, name: "V2-Check-in")
        app.buttons["checkin.save"].tap()
        XCTAssertTrue(app.buttons["sos.open"].waitForExistence(timeout: 5))
        app.buttons["sos.open"].tap()
        XCTAssertTrue(app.segmentedControls["sos.duration"].buttons["3 min"].isSelected)
        app.buttons["sos.start"].tap()
        app.buttons["sos.pause.done"].tap()
        let timer = app.descendants(matching: .any)["sos.timer"].firstMatch
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        let seconds = Int((timer.value as? String ?? "").components(separatedBy: " ").first ?? "") ?? 0
        XCTAssertTrue((150...180).contains(seconds), "Le SOS doit utiliser la durée conservée de trois minutes")
        capture(app, name: "V2-SOS-Observer")
        XCTAssertTrue(app.buttons["sos.observe.next"].waitForExistence(timeout: 5))
        app.buttons["sos.observe.next"].tap()
        app.buttons["sos.action.done"].tap()
        app.buttons["sos.save"].tap()
        XCTAssertTrue(app.buttons["sos.finish"].waitForExistence(timeout: 5))
        app.buttons["sos.finish"].tap()
        XCTAssertTrue(app.tabBars.buttons["Comprendre"].exists)
        app.tabBars.buttons["Comprendre"].tap()
        capture(app, name: "V2-Comprendre")
    }

    func testLargestTextKeepsCheckInAndSOSUsableAfterBackground() throws {
        let app = application(largeText: true)
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 5))
        app.buttons["onboarding.next"].tap()
        reveal(app.buttons["onboarding.next"], in: app)
        app.buttons["onboarding.next"].tap()
        reveal(app.buttons["onboarding.next"], in: app)
        app.buttons["onboarding.next"].tap()
        XCTAssertTrue(app.buttons["checkin.open"].waitForExistence(timeout: 5))
        reveal(app.buttons["checkin.open"], in: app)
        app.buttons["checkin.open"].tap()
        let tired = app.buttons["emotion.tired"]
        reveal(tired, in: app)
        XCTAssertGreaterThanOrEqual(tired.frame.height, 44)
        tired.tap()
        capture(app, name: "V2.1-Check-in-AX5")
        XCTAssertTrue(app.buttons["checkin.save"].isHittable)
        app.buttons["checkin.save"].tap()
        app.buttons["sos.open"].tap()
        XCTAssertTrue(app.buttons["sos.start"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["sos.start"].isHittable)
        app.buttons["sos.start"].tap()
        app.buttons["sos.pause.done"].tap()
        let timer = app.descendants(matching: .any)["sos.timer"].firstMatch
        reveal(timer, in: app)
        let before = try XCTUnwrap(Int((timer.value as? String ?? "").components(separatedBy: " ").first ?? ""))
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)
        app.activate()
        // The timer may be below the initial scroll position after resuming.
        reveal(timer, in: app)
        let after = try XCTUnwrap(Int((timer.value as? String ?? "").components(separatedBy: " ").first ?? ""))
        XCTAssertLessThan(after, before, "L'échéance doit continuer en arrière-plan")
        XCTAssertGreaterThan(after, 0)
        XCTAssertTrue(app.buttons["sos.observe.next"].isHittable)
        capture(app, name: "V2.1-SOS-AX5-Retour")
        app.buttons["sos.observe.next"].tap()
        app.buttons["sos.action.done"].tap()
        app.buttons["sos.save"].tap()
        app.buttons["sos.finish"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["checkin.open"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onboarding.next"].exists, "Le parcours doit être conservé")
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        // Lazy grid choices need scrolling before they enter the accessibility tree.
        for _ in 0..<8 {
            if element.waitForExistence(timeout: 1) && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
