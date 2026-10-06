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
        for tab in ["Aujourd'hui", "Parcours", "Comprendre", "Aide"] {
            XCTAssertTrue(app.tabBars.buttons[tab].exists)
            app.tabBars.buttons[tab].tap()
            let sos = app.buttons["sos.open"]
            XCTAssertTrue(sos.waitForExistence(timeout: 5))
            XCTAssertTrue(sos.isHittable, "Le SOS doit être accessible depuis chaque onglet")
            XCTAssertGreaterThanOrEqual(sos.frame.height, 44)
            capture(app, name: "Lisibilite-\(tab)-Brume-Sombre")
            sos.tap()
            XCTAssertTrue(app.buttons["sos.start"].waitForExistence(timeout: 5))
            app.buttons["sos.close"].tap()
        }
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

    func testEpisodeAnalysisCanBeSavedEditedAndResumed() {
        let app = application()
        app.launch()
        if app.buttons["onboarding.next"].waitForExistence(timeout: 5) {
            app.buttons["onboarding.next"].tap()
            app.textFields["onboarding.intention"].tap()
            app.textFields["onboarding.intention"].typeText("Retrouver mes soirees")
            app.buttons["onboarding.next"].tap()
            app.buttons["onboarding.next"].tap()
        }
        app.tabBars.buttons["Aujourd'hui"].tap()
        reveal(app.buttons["episode.open"], in: app)
        app.buttons["episode.open"].tap()
        choose("Au lit", in: "episode.context", app: app)
        choose("Fatigué", in: "episode.emotion", app: app)
        capture(app, name: "V3-Contexte")
        app.buttons["episode.next"].tap()
        choose("Habitude", in: "episode.trigger", app: app)
        app.buttons["episode.suggestion"].tap()
        capture(app, name: "V3-Interruption")
        app.buttons["episode.next"].tap()
        reveal(app.switches["episode.keepPlan"], in: app)
        app.switches["episode.keepPlan"].tap()
        capture(app, name: "V3-Regle")
        app.buttons["episode.save"].tap()
        XCTAssertTrue(app.buttons["episode.resume"].waitForExistence(timeout: 5))
        app.buttons["episode.resume"].tap()
        app.tabBars.buttons["Comprendre"].tap()
        reveal(app.buttons["journal.open"], in: app)
        app.buttons["journal.open"].tap()
        let episode = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "journal.episode.")).firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 5))
        let episodeIdentifier = episode.identifier
        episode.tap()
        XCTAssertTrue(app.staticTexts["Plan repris"].exists)
        let editID = episodeIdentifier.replacingOccurrences(of: "journal.episode.", with: "journal.edit.")
        app.buttons[editID].tap()
        app.buttons["episode.next"].tap()
        app.buttons["episode.next"].tap()
        // Multiline SwiftUI fields may be exposed as a text field or a text view.
        let action = app.descendants(matching: .any)["episode.plan"].firstMatch
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        XCTAssertTrue((action.value as? String ?? "").contains("hors de la chambre"))
        app.buttons["episode.save"].tap()
        XCTAssertTrue(app.buttons["episode.finish"].waitForExistence(timeout: 5))
        app.buttons["episode.finish"].tap()
        XCTAssertTrue(app.descendants(matching: .any)[episodeIdentifier].firstMatch.exists)
        capture(app, name: "V3-Journal-Compact")
        app.terminate()
        app.launch()
        app.tabBars.buttons["Comprendre"].tap()
        reveal(app.buttons["journal.open"], in: app)
        app.buttons["journal.open"].tap()
        XCTAssertTrue(app.descendants(matching: .any)[episodeIdentifier].firstMatch.waitForExistence(timeout: 5))
    }

    func testCheckInCalendarAndFocusedPathShareExistingProgress() {
        let app = application()
        app.launch()
        if app.buttons["onboarding.next"].waitForExistence(timeout: 5) {
            app.buttons["onboarding.next"].tap()
            reveal(app.buttons["onboarding.next"], in: app)
            app.buttons["onboarding.next"].tap()
            reveal(app.buttons["onboarding.next"], in: app)
            app.buttons["onboarding.next"].tap()
        }
        XCTAssertTrue(app.buttons["checkin.open"].waitForExistence(timeout: 5))
        let day = app.staticTexts["today.journeyDay"]
        XCTAssertTrue(day.exists)
        XCTAssertEqual(day.frame.midX, app.frame.midX, accuracy: 4)
        XCTAssertFalse(app.staticTexts["Un geste pour aujourd'hui"].exists)
        app.buttons["today.intention"].tap()
        XCTAssertTrue(app.staticTexts["Retrouver de la liberté dans mes choix."].exists)
        app.buttons["today.intention"].tap()
        app.buttons["checkin.help"].tap()
        XCTAssertTrue(app.navigationBars["Le check-in"].waitForExistence(timeout: 5))
        app.buttons["Terminé"].tap()
        app.buttons["checkin.open"].tap()
        app.buttons["checkin.save"].tap()
        app.buttons["checkin.history"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["checkin.summary"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Objectif : pas encore de réponse"].exists)
        capture(app, name: "Check-ins-Calendrier-Incertain")
        app.tabBars.buttons["Parcours"].tap()
        app.buttons["journey.path.urges"].tap()
        app.buttons["journey.continue"].tap()
        reveal(app.buttons["lesson.save"], in: app)
        app.buttons["lesson.save"].tap()
        XCTAssertTrue(app.buttons["lesson.save"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.tabBars.buttons["Parcours"].tap()
        app.buttons["journey.path.urges"].tap()
        XCTAssertTrue(app.staticTexts["1 / 7"].waitForExistence(timeout: 5))
        capture(app, name: "Parcours-Cible-Progression")
        app.navigationBars["Traverser une envie"].buttons["Parcours"].tap()
        app.buttons["journey.path.foundations"].tap()
        XCTAssertTrue(app.staticTexts["1 / 42"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Aujourd'hui"].tap()
        app.buttons["checkin.history"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["checkin.summary"].firstMatch.waitForExistence(timeout: 5))
    }

    func testV4V5V6ShortcutsAndRecommendationsAreReachable() {
        let app = application()
        app.launch()
        if app.buttons["onboarding.next"].waitForExistence(timeout: 5) {
            app.buttons["onboarding.next"].tap()
            app.buttons["onboarding.next"].tap()
            app.buttons["onboarding.next"].tap()
        }
        XCTAssertTrue(app.buttons["today.sos"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Parcours"].tap()
        XCTAssertTrue(app.buttons["journey.recommended"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["journey.weekly"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Comprendre"].tap()
        XCTAssertTrue(app.buttons["journal.open"].waitForExistence(timeout: 5))
    }

    private func choose(_ title: String, in identifier: String, app: XCUIApplication) {        let picker = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        let option = app.buttons[title].firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
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
