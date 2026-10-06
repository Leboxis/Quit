import XCTest
@testable import Quit

final class V456ModelsTests: XCTestCase {
    func testNewFieldsRoundTrip() throws {
        var data = QuitData()
        data.favoriteStrategies = [.walk, .connect]
        data.usefulStrategies = [.move]
        data.sosPlan = SOSPersonalPlan(duration: .threeMinutes, strategies: [.walk, .move])
        data.pace = .daily
        data.weeklyReviews = [WeeklyReview(weekStart: Date(), text: "Une semaine calme")]
        try data.validate()
        let reloaded = try JSONDecoder().decode(QuitData.self, from: JSONEncoder().encode(data))
        XCTAssertEqual(reloaded.favoriteStrategies, [.walk, .connect])
        XCTAssertEqual(reloaded.usefulStrategies, [.move])
        XCTAssertEqual(reloaded.sosPlan?.strategies, [.walk, .move])
        XCTAssertEqual(reloaded.pace, .daily)
        XCTAssertEqual(reloaded.weeklyReviews.count, 1)
    }

    func testLegacyJSONWithoutNewFieldsDecodes() throws {
        let legacy = """
        {"schemaVersion":1,"profile":{"startedAt":946684800,"name":"","intention":"","goal":"stop","sensitiveHour":23,"contactName":"","contactPhone":"","biometricLock":false,"reminderEnabled":false,"reminderHour":21,"reminderMinute":0,"onboardingComplete":false},"checkIns":[],"urges":[],"episodes":[],"plans":[],"completedLessons":[],"reflections":{},"experience":{"accent":"sage","appearance":"system","reduceAnimations":false,"haptics":true,"observationDuration":90}}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(QuitData.self, from: legacy)
        XCTAssertEqual(decoded.favoriteStrategies, [])
        XCTAssertNil(decoded.sosPlan)
        XCTAssertEqual(decoded.pace, .free)
        XCTAssertEqual(decoded.weeklyReviews, [])
        XCTAssertNoThrow(try decoded.validate())
    }

    func testValidationRejectsTooManyFavorites() {
        var data = QuitData()
        data.favoriteStrategies = [.walk, .connect, .move, .observe]
        XCTAssertThrowsError(try data.validate())
    }

    func testValidationRejectsEmptySOSPlan() {
        var data = QuitData()
        data.sosPlan = SOSPersonalPlan(duration: .ninetySeconds, strategies: [])
        XCTAssertThrowsError(try data.validate())
    }
}
