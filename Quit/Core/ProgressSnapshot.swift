import Foundation

struct StrategyResult: Identifiable {
    var id: Strategy { strategy }
    let strategy: Strategy
    let count: Int
    let reduction: Double
}

struct DayRecord: Identifiable {
    enum State { case aligned, episode, unknown }
    var id: Date { date }
    let date: Date
    let state: State
}

struct HeatCell: Identifiable {
    var id: Int { weekday * 4 + bucket }
    let weekday: Int
    let bucket: Int
    let count: Int
}

struct ProgressSnapshot {
    let days: [DayRecord]
    let urges: [UrgeSession]
    let episodes: [Episode]
    let strategies: [StrategyResult]
    let emotions: [(emotion: Emotion, count: Int)]
    let heatmap: [HeatCell]
    let triggers: [(trigger: Trigger, count: Int)]
    let topSensitive: [HeatCell]
    let medianRecoveryHours: Double?
    let recoveryCount: Int
    let insufficientData: Bool

    var alignedDays: Int { days.filter { $0.state == .aligned }.count }
    var episodeDays: Int { days.filter { $0.state == .episode }.count }
    var unknownDays: Int { days.filter { $0.state == .unknown }.count }
    var observedDays: Int { alignedDays + episodeDays }
    var episodeCount: Int { episodes.count }
    var passedUrges: Int { urges.filter { $0.outcome == .passed }.count }
    var averageReduction: Double? {
        guard !urges.isEmpty else { return nil }
        return Double(urges.reduce(0) { $0 + $1.initial - $1.final }) / Double(urges.count)
    }
    var averageRecoveryHours: Double? {
        let intervals = episodes.compactMap { episode in
            episode.recoveredAt.map { max(0, $0.timeIntervalSince(episode.date)) / 3600 }
        }
        guard !intervals.isEmpty else { return nil }
        return intervals.reduce(0, +) / Double(intervals.count)
    }

    init(data: QuitData, now: Date = Date(), calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        let boundary = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        let start = max(boundary, calendar.startOfDay(for: data.profile.startedAt))
        let relevantEpisodes = data.episodes.filter { $0.date >= start && $0.date <= now }.sorted { $0.date < $1.date }
        let relevantUrges = data.urges.filter { $0.date >= start && $0.date <= now }.sorted { $0.date < $1.date }
        let checkIns = data.checkIns.filter { $0.date >= start && $0.date <= now }
        var records: [DayRecord] = []
        var day = start
        while day <= today {
            let hasEpisode = relevantEpisodes.contains { calendar.isDate($0.date, inSameDayAs: day) }
            let latest = checkIns.filter { calendar.isDate($0.date, inSameDayAs: day) }.max { $0.date < $1.date }
            let state: DayRecord.State = hasEpisode || latest?.aligned == false ? .episode : latest?.aligned == true ? .aligned : .unknown
            records.append(DayRecord(date: day, state: state))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day), next > day else { break }
            day = next
        }
        days = records
        urges = relevantUrges
        episodes = relevantEpisodes
        strategies = Strategy.allCases.compactMap { strategy in
            let sessions = relevantUrges.filter { $0.strategy == strategy }
            guard !sessions.isEmpty else { return nil }
            return StrategyResult(strategy: strategy, count: sessions.count,
                                  reduction: Double(sessions.reduce(0) { $0 + $1.initial - $1.final }) / Double(sessions.count))
        }.sorted { $0.reduction == $1.reduction ? $0.strategy.rawValue < $1.strategy.rawValue : $0.reduction > $1.reduction }
        emotions = Emotion.allCases.map { emotion in
            (emotion: emotion, count: relevantUrges.filter { $0.emotion == emotion }.count + relevantEpisodes.filter { $0.emotion == emotion }.count)
        }.filter { $0.count > 0 }.sorted { $0.count > $1.count }
        let dates = relevantUrges.map(\.date) + relevantEpisodes.map(\.date)
        let cells = (0..<4).flatMap { bucket in
            (1...7).map { weekday in
                HeatCell(weekday: weekday, bucket: bucket, count: dates.filter {
                    calendar.component(.weekday, from: $0) == weekday && Self.bucket(for: calendar.component(.hour, from: $0)) == bucket
                }.count)
            }
        }
        heatmap = cells
        triggers = Trigger.allCases.map { trigger in
            (trigger: trigger, count: relevantEpisodes.filter { $0.trigger == trigger }.count)
        }.filter { $0.count > 0 }.sorted { $0.count > $1.count }
        topSensitive = cells.filter { $0.count > 0 }.sorted { $0.count > $1.count }.prefix(3).map { $0 }
        let intervals = relevantEpisodes.compactMap { episode in
            episode.recoveredAt.map { max(0, $0.timeIntervalSince(episode.date)) / 3600 }
        }.sorted()
        recoveryCount = intervals.count
        if intervals.isEmpty {
            medianRecoveryHours = nil
        } else if intervals.count % 2 == 1 {
            medianRecoveryHours = intervals[intervals.count / 2]
        } else {
            medianRecoveryHours = (intervals[intervals.count / 2 - 1] + intervals[intervals.count / 2]) / 2
        }
        let observed = records.filter { $0.state != .unknown }.count
        insufficientData = relevantUrges.count < 3 && relevantEpisodes.isEmpty && observed < 7
    }

    static func bucket(for hour: Int) -> Int {
        switch hour {
        case 6..<12: 0
        case 12..<18: 1
        case 18..<24: 2
        default: 3
        }
    }
}
