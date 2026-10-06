import XCTest
@testable import Quit

final class JourneyCatalogTests: XCTestCase {
    func testCoursesHaveDistinctIDsAndOnlyReferenceExistingLessons() {
        let paths = JourneyCatalog.paths
        XCTAssertEqual(Set(paths.map(\.id)).count, paths.count)
        XCTAssertEqual(paths.count, 4)
        let available = Set(LessonCatalog.lessons.map(\.id))
        for path in paths {
            XCTAssertFalse(path.lessonIDs.isEmpty)
            XCTAssertEqual(Set(path.lessonIDs).count, path.lessonIDs.count)
            XCTAssertTrue(Set(path.lessonIDs).isSubset(of: available))
            XCTAssertEqual(path.lessons.map(\.id), path.lessonIDs)
        }
    }

    func testFullCoursePreservesOriginalOrderAndAllSixWeeks() {
        let course = JourneyCatalog.paths.first { $0.id == "foundations" }!
        XCTAssertEqual(course.lessonIDs, Array(1...42))
        XCTAssertTrue(course.isFullCourse)
        XCTAssertEqual(Set(course.lessons.map(\.week)), Set(1...6))
    }

    func testFocusedCourseSharesCompletionWithoutChangingOriginalProgress() throws {
        let path = JourneyCatalog.paths.first { $0.id == "urges" }!
        var data = QuitData()
        data.completedLessons = [1, 15, 16, 35]
        data.reflections = ["15": "Changer de pièce"]
        XCTAssertEqual(path.completedCount(in: data.completedLessons), 2)
        XCTAssertEqual(path.nextLesson(in: data.completedLessons)?.id, 17)
        let restored = try JSONDecoder().decode(QuitData.self, from: JSONEncoder().encode(data))
        try restored.validate()
        XCTAssertEqual(restored.completedLessons, data.completedLessons)
        XCTAssertEqual(restored.reflections, data.reflections)
    }

    func testCompletedPathHasNoNextStep() {
        for path in JourneyCatalog.paths {
            XCTAssertNil(path.nextLesson(in: Set(path.lessonIDs)))
            XCTAssertEqual(path.completedCount(in: Set(path.lessonIDs)), path.lessonIDs.count)
        }
    }

    func testRecommendationPrefersRecoveryAfterEpisode() {
        var data = QuitData()
        data.profile.startedAt = Date().addingTimeInterval(-86400 * 5)
        data.episodes = [Episode(date: Date(), emotion: .tired, context: .desk, trigger: .habit)]
        XCTAssertEqual(JourneyCatalog.recommendation(for: data).path.id, "recovery")
    }

    func testRecommendationSuggestsUrgesForScrollingTrigger() {
        var data = QuitData()
        data.profile.startedAt = Date().addingTimeInterval(-86400 * 5)
        data.episodes = []
        // Simulate scrolling-heavy history via episodes with scrolling trigger but no recovery needed?
        // Use urges-independent path: empty episodes falls to foundations, so add scrolling episode then complete recovery.
        data.episodes = [Episode(date: Date(), emotion: .bored, context: .desk, trigger: .scrolling)]
        data.completedLessons = Set(36...42)
        XCTAssertEqual(JourneyCatalog.recommendation(for: data).path.id, "urges")
    }
}
