import Foundation

struct CheckInMonth {
    let start: Date
    let days: [Date]
    let leadingEmptyDays: Int
}

// A recorded check-in and an aligned day are different things.
// In particular, an uncertain check-in must still appear in the calendar.
struct CheckInHistory {
    let calendar: Calendar
    let today: Date
    private let records: [Date: DailyCheckIn]

    init(checkIns: [DailyCheckIn], now: Date = Date(), calendar: Calendar = .current) {
        self.calendar = calendar
        today = calendar.startOfDay(for: now)
        var latest: [Date: DailyCheckIn] = [:]
        for item in checkIns where item.date <= now {
            let day = calendar.startOfDay(for: item.date)
            if let previous = latest[day],
               previous.date > item.date || (previous.date == item.date && previous.id.uuidString > item.id.uuidString) {
                continue
            }
            latest[day] = item
        }
        records = latest
    }

    func checkIn(on day: Date) -> DailyCheckIn? {
        records[calendar.startOfDay(for: day)]
    }

    func month(containing date: Date) -> CheckInMonth {
        let start = calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 0
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let days = (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        return CheckInMonth(start: start, days: days, leadingEmptyDays: leading)
    }
}
