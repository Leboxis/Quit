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
        // Build a real payload, then strip V4/V5/V6 keys: this is exactly what a V1/V2/V3 backup looks like.
        var data = QuitData()
        data.profile.intention = "Legacy"
        let encoded = try JSONEncoder().encode(data)
        var dict = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        for key in ["favoriteStrategies", "usefulStrategies", "sosPlan", "pace", "weeklyReviews"] {
            dict.removeValue(forKey: key)
        }
        let legacy = try JSONSerialization.data(withJSONObject: dict)
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
