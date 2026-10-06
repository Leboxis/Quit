import XCTest
@testable import Quit

final class CheckInHistoryTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Europe/Paris")!
        value.firstWeekday = 2
        return value
    }
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
    private func checkIn(_ date: Date, aligned: Bool? = nil) -> DailyCheckIn {
        DailyCheckIn(date: date, emotion: .tired, energy: 1, stress: 2, urge: 4, aligned: aligned)
    }

    func testUncertainCheckInIsPresentWithoutBeingCountedAsAligned() {
        let now = date("2026-10-06T12:00:00Z")
        let item = checkIn(now)
        let history = CheckInHistory(checkIns: [item], now: now, calendar: calendar)
        XCTAssertEqual(history.checkIn(on: now)?.id, item.id)
        XCTAssertNil(history.checkIn(on: now)?.aligned)
        XCTAssertNil(history.checkIn(on: date("2026-10-05T12:00:00Z")))
    }

    func testLatestCheckInWinsOnTheSameLocalDay() {
        let first = checkIn(date("2026-10-05T22:30:00Z"), aligned: true)
        let latest = checkIn(date("2026-10-06T12:00:00Z"), aligned: false)
        let history = CheckInHistory(checkIns: [latest, first], now: latest.date, calendar: calendar)
        XCTAssertEqual(history.checkIn(on: first.date)?.id, latest.id)
    }

    func testMonthDaysFollowLocalCalendarAcrossDaylightSaving() {
        let history = CheckInHistory(checkIns: [], now: date("2026-10-27T12:00:00Z"), calendar: calendar)
        let days = history.month(containing: history.today).days
        XCTAssertEqual(days.map { calendar.component(.day, from: $0) }, Array(1...31))
        XCTAssertTrue(days.allSatisfy { calendar.component(.hour, from: $0) == 0 })
    }

    func testMonthIncludesLeapDayAndUsesConfiguredFirstWeekday() {
        let now = date("2028-02-15T12:00:00Z")
        let month = CheckInHistory(checkIns: [], now: now, calendar: calendar).month(containing: now)
        XCTAssertEqual(month.days.count, 29)
        XCTAssertEqual(month.leadingEmptyDays, 1)
        XCTAssertEqual(calendar.component(.day, from: month.days.last!), 29)
    }

    func testOldCheckInsRemainAccessibleAndFutureRecordsAreExcluded() {
        let now = date("2026-10-06T12:00:00Z")
        let old = checkIn(date("2025-01-01T12:00:00Z"))
        let future = checkIn(date("2026-10-07T12:00:00Z"))
        let history = CheckInHistory(checkIns: [future, old], now: now, calendar: calendar)
        XCTAssertEqual(history.checkIn(on: old.date)?.id, old.id)
        XCTAssertNil(history.checkIn(on: future.date))
    }
}
