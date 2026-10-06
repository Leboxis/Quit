import XCTest
@testable import Quit

final class ExperienceTests: XCTestCase {
    func testV1BackupPreservesProgressAndReceivesDefaultAppearance() throws {
        var original = QuitData()
        original.profile.intention = "Retrouver mes soirées"
        original.completedLessons = [1, 4, 9]
        original.checkIns = [DailyCheckIn(date: Date(), emotion: .calm, energy: 2, stress: 1, urge: 3, aligned: true)]
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        json.removeValue(forKey: "experience")
        let migrated = try JSONDecoder().decode(QuitData.self, from: JSONSerialization.data(withJSONObject: json))
        try migrated.validate()
        XCTAssertEqual(migrated.profile.intention, original.profile.intention)
        XCTAssertEqual(migrated.completedLessons, original.completedLessons)
        XCTAssertEqual(migrated.checkIns.first?.id, original.checkIns.first?.id)
        XCTAssertEqual(migrated.experience, ExperiencePreferences())
    }

    func testPreferencesSurviveBackupRoundTrip() throws {
        var data = QuitData()
        data.experience.accent = .slate
        data.experience.appearance = .dark
        data.experience.reduceAnimations = true
        data.experience.haptics = false
        data.experience.observationDuration = .threeMinutes
        let restored = try JSONDecoder().decode(QuitData.self, from: JSONEncoder().encode(data))
        XCTAssertEqual(restored.experience, data.experience)
    }

    func testPartialPreferencesUseDefaultsForMissingKeys() throws {
        let preferences = try JSONDecoder().decode(ExperiencePreferences.self, from: Data("{\"accent\":\"sand\"}".utf8))
        XCTAssertEqual(preferences.accent, .sand)
        XCTAssertEqual(preferences.appearance, .system)
        XCTAssertEqual(preferences.observationDuration.seconds, 90)
        XCTAssertTrue(preferences.haptics)
    }

    func testUnknownThemeAndUnsupportedDurationAreRejected() {
        XCTAssertThrowsError(try JSONDecoder().decode(ExperiencePreferences.self, from: Data("{\"accent\":\"unknown\"}".utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode(ExperiencePreferences.self, from: Data("{\"observationDuration\":17}".utf8)))
    }
}
