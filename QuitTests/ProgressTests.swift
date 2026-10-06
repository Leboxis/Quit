import XCTest
@testable import Quit

final class ProgressTests: XCTestCase {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "Europe/Paris")!
        return result
    }
    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    func testUnknownDaysAreNeverCountedAsAligned() {
        let now = date("2026-10-05T12:00:00Z")
        var data = QuitData()
        data.profile.startedAt = date("2026-10-01T12:00:00Z")
        data.checkIns = [DailyCheckIn(date: now, emotion: .calm, energy: 2, stress: 1, urge: 3, aligned: true)]
        let stats = ProgressSnapshot(data: data, now: now, calendar: calendar)
        XCTAssertEqual(stats.alignedDays, 1)
        XCTAssertEqual(stats.observedDays, 1)
        XCTAssertEqual(stats.unknownDays, 4)
    }

    func testEpisodeOverridesCheckInWithoutErasingOtherProgress() {
        let now = date("2026-10-05T12:00:00Z")
        var data = QuitData()
        data.profile.startedAt = date("2026-10-01T12:00:00Z")
        data.checkIns = [DailyCheckIn(date: now, emotion: .calm, energy: 2, stress: 1, urge: 3, aligned: true),
                         DailyCheckIn(date: date("2026-10-04T12:00:00Z"), emotion: .calm, energy: 2, stress: 1, urge: 2, aligned: true)]
        data.episodes = [Episode(date: now, emotion: .tired, context: .bed, trigger: .habit),
                         Episode(date: now, emotion: .lonely, context: .bed, trigger: .scrolling)]
        let stats = ProgressSnapshot(data: data, now: now, calendar: calendar)
        XCTAssertEqual(stats.episodeCount, 2)
        XCTAssertEqual(stats.episodeDays, 1)
        XCTAssertEqual(stats.alignedDays, 1)
        XCTAssertEqual(stats.unknownDays, 3)
    }

    func testThirtyDayWindowExcludesFutureAndOldRecords() {
        let now = date("2026-10-05T12:00:00Z")
        var data = QuitData()
        data.profile.startedAt = date("2026-01-01T12:00:00Z")
        data.episodes = [Episode(date: date("2026-09-05T12:00:00Z"), emotion: .tired, context: .bed, trigger: .habit),
                         Episode(date: date("2026-09-06T12:00:00Z"), emotion: .tired, context: .bed, trigger: .habit),
                         Episode(date: date("2026-10-06T12:00:00Z"), emotion: .tired, context: .bed, trigger: .habit)]
        let stats = ProgressSnapshot(data: data, now: now, calendar: calendar)
        XCTAssertEqual(stats.episodeCount, 1)
        XCTAssertEqual(stats.unknownDays, 29)
    }

    func testLocalDayUsesCalendarRatherThanUTC() {
        let now = date("2026-10-05T23:30:00Z")
        var data = QuitData()
        data.profile.startedAt = date("2026-10-05T10:00:00Z")
        data.checkIns = [DailyCheckIn(date: date("2026-10-05T22:30:00Z"), emotion: .calm, energy: 2, stress: 1, urge: 2, aligned: true)]
        XCTAssertEqual(ProgressSnapshot(data: data, now: now, calendar: calendar).alignedDays, 1)
        XCTAssertEqual(ProgressSnapshot(data: data, now: now, calendar: calendar).unknownDays, 1)
    }

    func testUrgeResultsUsePairedMeasurementsAndKnownOutcomes() {
        let now = date("2026-10-05T12:00:00Z")
        var data = QuitData()
        data.profile.startedAt = now
        data.urges = [UrgeSession(date: now, initial: 8, final: 4, strategy: .walk, outcome: .passed, emotion: .stressed),
                      UrgeSession(date: now, initial: 6, final: 7, strategy: .observe, outcome: .ongoing, emotion: .bored)]
        let stats = ProgressSnapshot(data: data, now: now, calendar: calendar)
        XCTAssertEqual(stats.passedUrges, 1)
        XCTAssertEqual(stats.averageReduction!, 1.5, accuracy: 0.001)
        XCTAssertEqual(stats.strategies.count, 2)
        XCTAssertEqual(stats.strategies.first?.strategy, .walk)
    }

    func testRecoveryUsesOnlyExplicitReturnsToPlan() {
        let now = date("2026-10-05T12:00:00Z")
        var data = QuitData()
        data.profile.startedAt = now.addingTimeInterval(-86400)
        var episode = Episode(date: now.addingTimeInterval(-3600), emotion: .tired, context: .bed, trigger: .habit)
        episode.recoveredAt = now
        data.episodes = [episode, Episode(date: now, emotion: .tired, context: .bed, trigger: .habit)]
        XCTAssertEqual(ProgressSnapshot(data: data, now: now, calendar: calendar).averageRecoveryHours!, 1, accuracy: 0.001)
    }

    func testImportRejectsInvalidIntensityAndFutureSchema() throws {
        var data = QuitData()
        data.urges = [UrgeSession(date: Date(), initial: 11, final: 4, strategy: .walk, outcome: .passed, emotion: .calm)]
        XCTAssertThrowsError(try data.validate())
        data = QuitData()
        data.schemaVersion = 999
        XCTAssertThrowsError(try data.validate())
    }

    func testImportRejectsDuplicateIDsAndInvalidRecoveryDates() throws {
        var data = QuitData()
        let item = Episode(date: Date(), emotion: .tired, context: .bed, trigger: .habit)
        data.episodes = [item, item]
        XCTAssertThrowsError(try data.validate())
        var invalid = item
        invalid.recoveredAt = item.date.addingTimeInterval(-1)
        data.episodes = [invalid]
        XCTAssertThrowsError(try data.validate())
    }

    func testDataRoundTripPreservesProgress() throws {
        var data = QuitData()
        data.completedLessons = [1, 5, 8]
        data.plans = [IfThenPlan(condition: "Téléphone au lit", action: "Le poser dans la cuisine")]
        let restored = try JSONDecoder().decode(QuitData.self, from: JSONEncoder().encode(data))
        try restored.validate()
        XCTAssertEqual(restored.completedLessons, data.completedLessons)
        XCTAssertEqual(restored.plans.first?.action, data.plans.first?.action)
    }

    func testBundledCourseContainsAllFortyTwoCompleteLessons() {
        XCTAssertEqual(LessonCatalog.lessons.map(\.id), Array(1...42))
        XCTAssertTrue(LessonCatalog.lessons.allSatisfy { !$0.body.isEmpty && !$0.prompt.isEmpty && !$0.action.isEmpty })
    }

    func testTriggersAreRankedAndSensitiveSlotsLimitedToThree() {
        let now = date("2026-10-05T12:00:00Z")
        var data = QuitData()
        data.profile.startedAt = date("2026-10-01T12:00:00Z")
        data.episodes = [Episode(date: now, emotion: .tired, context: .bed, trigger: .habit),
                         Episode(date: now, emotion: .tired, context: .bed, trigger: .habit),
                         Episode(date: now, emotion: .lonely, context: .desk, trigger: .scrolling)]
        let stats = ProgressSnapshot(data: data, now: now, calendar: calendar)
        XCTAssertEqual(stats.triggers.first?.trigger, .habit)
        XCTAssertEqual(stats.triggers.first?.count, 2)
        XCTAssertLessThanOrEqual(stats.topSensitive.count, 3)
    }

    func testInsufficientDataFlagAndMedianRecovery() {
        let now = date("2026-10-05T12:00:00Z")
        var empty = QuitData()
        empty.profile.startedAt = date("2026-10-01T12:00:00Z")
        XCTAssertTrue(ProgressSnapshot(data: empty, now: now, calendar: calendar).insufficientData)
        var episode = Episode(date: now.addingTimeInterval(-7200), emotion: .tired, context: .bed, trigger: .habit)
        episode.recoveredAt = now.addingTimeInterval(-3600)
        var data = QuitData()
        data.profile.startedAt = date("2026-10-01T12:00:00Z")
        data.episodes = [episode]
        data.checkIns = (0..<7).map { i in
            DailyCheckIn(date: date("2026-10-0\(1 + (i % 5))T12:00:00Z"), emotion: .calm, energy: 2, stress: 1, urge: 2, aligned: true)
        }
        let stats = ProgressSnapshot(data: data, now: now, calendar: calendar)
        XCTAssertFalse(stats.insufficientData)
        XCTAssertEqual(stats.recoveryCount, 1)
        XCTAssertEqual(stats.medianRecoveryHours!, 1, accuracy: 0.001)
    }
}
