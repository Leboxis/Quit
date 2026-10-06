import Charts
import SwiftUI

struct InsightsView: View {
    @Environment(\.quitAccent) private var accent
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showGuide = false
    var body: some View {
        let stats = ProgressSnapshot(data: store.data)
        let history = CheckInHistory(checkIns: store.data.checkIns)
        let hasCheckIns = stats.days.contains { history.checkIn(on: $0.date) != nil }
        ScreenContent {
            if !hasCheckIns && stats.observedDays == 0 && stats.urges.isEmpty && stats.episodes.isEmpty {
                ContentUnavailableView("Tes repères se construisent", systemImage: "chart.xyaxis.line",
                                       description: Text("Enregistre ton premier check-in pour voir ton suivi."))
            } else {
                dayOverview(stats)
                if !stats.urges.isEmpty {
                    urgeOverview(stats)
                }
                if !stats.emotions.isEmpty {
                    QuitCard {
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 16) {
                                emotionOverview(stats)
                                HeatmapView(cells: stats.heatmap)
                            }.padding(.top, 8)
                        } label: {
                            QuitSectionTitle(title: "Émotions et moments", symbol: "clock", tone: .reflection)
                        }
                    }
                }
                if !stats.strategies.isEmpty {
                    QuitCard {
                        DisclosureGroup {
                            strategyOverview(stats).padding(.top, 8)
                        } label: {
                            QuitSectionTitle(title: "Ce qui semble t'aider", symbol: "arrow.triangle.branch", tone: .preparation)
                        }
                    }
                }
            }
            QuitCard {
                QuitSectionTitle(title: "Mon historique", symbol: "book.closed", tone: .reflection)
                if let hours = stats.averageRecoveryHours {
                    Text("\(hours.formatted(.number.precision(.fractionLength(1)))) h en moyenne")
                        .font(.title2.weight(.medium))
                    Text("Retour au plan · \(stats.episodes.filter { $0.recoveredAt != nil }.count) retours")
                        .font(.footnote).foregroundStyle(QuitTheme.secondary)
                }
                NavigationLink { CheckInCalendarView() } label: {
                    QuietRow(title: "Calendrier des check-ins", symbol: "calendar", tone: .reflection)
                }.buttonStyle(.plain).accessibilityIdentifier("insights.calendar")
                Divider()
                NavigationLink { JournalView() } label: {
                    QuietRow(title: "Ouvrir mon journal", detail: "Check-ins, envies et épisodes", symbol: "book.closed", tone: .reflection)
                }.buttonStyle(.plain)
                    .accessibilityIdentifier("journal.open")
            }
        }.navigationTitle("Comprendre")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lire mes graphiques", systemImage: "info.circle") { showGuide = true }
                }
            }
            .sheet(isPresented: $showGuide) { InsightsGuideView() }
    }

    private func dayOverview(_ stats: ProgressSnapshot) -> some View {
        QuitCard(tinted: true) {
            QuitSectionTitle(title: "Mes journées · \(stats.days.count) jours", symbol: "calendar")
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 20))
            layout {
                dayMetric(stats.alignedDays, title: "Objectif respecté", color: accent.color)
                dayMetric(stats.observedDays, title: "Bilans connus", color: QuitTheme.text)
                dayMetric(stats.unknownDays, title: "Sans bilan", color: QuitTheme.secondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 10), spacing: 6) {
                ForEach(stats.days) { day in
                    RoundedRectangle(cornerRadius: 4).fill(dayColor(day.state)).frame(height: 19)
                        .overlay {
                            switch day.state {
                            case .aligned: Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(accent.foreground)
                            case .episode: Image(systemName: "circle").font(.system(size: 9, weight: .bold)).foregroundStyle(Color("OnAccent"))
                            case .unknown: EmptyView()
                            }
                        }
                        .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted) + ": " + dayLabel(day.state))
                }
            }
            let legendLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(spacing: 12))
            legendLayout {
                legend("Respecté", color: accent.color, symbol: "checkmark")
                legend("Non atteint", color: QuitTheme.amber, symbol: "circle")
                legend("Sans bilan", color: QuitTheme.border, symbol: nil)
            }.font(.caption)
        }
    }

    private func urgeOverview(_ stats: ProgressSnapshot) -> some View {
        QuitCard {
            QuitSectionTitle(title: "Mes envies", symbol: "water.waves", tone: .reflection)
            Text("\(stats.passedUrges) envies traversées").font(.title2.weight(.medium))
            Text("\(stats.urges.count) sessions enregistrées")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
            Chart(Array(stats.urges.suffix(30))) { session in
                LineMark(x: .value("Date", session.date), y: .value("Intensité", session.initial), series: .value("Mesure", "Avant"))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .foregroundStyle(by: .value("Mesure", "Avant"))
                PointMark(x: .value("Date", session.date), y: .value("Intensité", session.initial))
                    .symbol(.diamond).foregroundStyle(QuitTheme.amber)
                LineMark(x: .value("Date", session.date), y: .value("Intensité", session.final), series: .value("Mesure", "Après"))
                    .foregroundStyle(by: .value("Mesure", "Après"))
                PointMark(x: .value("Date", session.date), y: .value("Intensité", session.final))
                    .foregroundStyle(accent.color)
            }
            .chartYScale(domain: 0...10)
            .chartForegroundStyleScale(["Avant": QuitTheme.amber, "Après": accent.color])
            .chartYAxis { AxisMarks(values: [0, 5, 10]) }
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) { AxisValueLabel(format: .dateTime.day().month()) } }
            .frame(height: 170)
            .accessibilityLabel("Intensité des 30 dernières envies, avant et après une action")
            if let reduction = stats.averageReduction {
                Text("Évolution moyenne : \((-reduction).formatted(.number.precision(.fractionLength(1)))) points")
                    .font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
        }
    }

    private func strategyOverview(_ stats: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(stats.strategies) { result in
                VStack(alignment: .leading, spacing: 5) {
                    Label(result.strategy.title, systemImage: result.strategy.symbol).font(.subheadline.weight(.medium))
                    Text("\(result.count) essais · \((-result.reduction).formatted(.number.precision(.fractionLength(1)))) points en moyenne")
                        .font(.footnote).foregroundStyle(QuitTheme.secondary)
                    if result.count < 3 { Label("Peu de données", systemImage: "info.circle").font(.caption).foregroundStyle(QuitTheme.secondary) }
                }
            }
        }
    }

    private func emotionOverview(_ stats: ProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ce que tu ressentais").font(.headline)
            ForEach(stats.emotions.prefix(4), id: \.emotion) { item in
                HStack {
                    Label(item.emotion.title, systemImage: item.emotion.symbol)
                    Spacer()
                    Text("\(item.count) signaux").foregroundStyle(QuitTheme.secondary)
                }.font(.subheadline)
            }
        }
    }

    private func dayColor(_ state: DayRecord.State) -> Color {
        switch state { case .aligned: accent.color; case .episode: QuitTheme.amber; case .unknown: QuitTheme.border }
    }
    private func dayLabel(_ state: DayRecord.State) -> String {
        switch state { case .aligned: "Objectif respecté"; case .episode: "Écart ou objectif non atteint"; case .unknown: "Sans bilan" }
    }
    private func dayMetric(_ value: Int, title: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)").font(.system(.title, design: .rounded, weight: .medium))
                .monospacedDigit().foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(QuitTheme.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
    }
    private func legend(_ title: String, color: Color, symbol: String?) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 14, height: 14)
                .overlay {
                    if let symbol {
                        Image(systemName: symbol).font(.system(size: 8, weight: .bold)).foregroundStyle(Color("OnAccent"))
                    }
                }.accessibilityHidden(true)
            Text(title).fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct HeatmapView: View {
    let cells: [HeatCell]
    private let weekdays = [2, 3, 4, 5, 6, 7, 1]
    private let labels = ["L", "M", "M", "J", "V", "S", "D"]
    private let buckets = ["6–12 h", "12–18 h", "18–24 h", "0–6 h"]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Envies et épisodes par moment").font(.headline)
            ScrollView(.horizontal) {
                Grid(horizontalSpacing: 5, verticalSpacing: 8) {
                    GridRow {
                        Text("")
                        ForEach(weekdays, id: \.self) { weekday in Text(labels[weekdays.firstIndex(of: weekday)!]).font(.caption) }
                    }
                    ForEach(0..<4, id: \.self) { bucket in
                        GridRow {
                            Text(buckets[bucket]).font(.caption).foregroundStyle(QuitTheme.secondary)
                            ForEach(weekdays, id: \.self) { weekday in
                                let count = cells.first { $0.weekday == weekday && $0.bucket == bucket }?.count ?? 0
                                Text(count == 0 ? "–" : "\(count)")
                                    .font(.caption2.weight(.medium)).monospacedDigit()
                                    .foregroundStyle(count == 0 ? QuitTheme.text : Color("OnAccent"))
                                    .padding(.horizontal, 4).padding(.vertical, 4)
                                    .frame(minWidth: 20, maxWidth: .infinity, minHeight: 24)
                                    .background(count == 0 ? QuitTheme.border : QuitTone.reflection.color,
                                                in: RoundedRectangle(cornerRadius: 5))
                                    .accessibilityLabel("\(Calendar.current.weekdaySymbols[weekday - 1]), \(buckets[bucket]) : \(count) signaux")
                            }
                        }
                    }
                }
                .frame(minWidth: 260)
            }.accessibilityLabel("Signaux par jour et moment de la journée")
        }
    }
}
