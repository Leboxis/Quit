import Charts
import SwiftUI

struct InsightsView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        let stats = ProgressSnapshot(data: store.data)
        ScreenContent {
            Text("30 derniers jours, ou depuis ton arrivée. Chaque mesure vient de ce que tu as enregistré.")
                .font(.subheadline).foregroundStyle(QuitTheme.secondary)
            if stats.observedDays == 0 && stats.urges.isEmpty && stats.episodes.isEmpty {
                ContentUnavailableView("Tes repères se construisent", systemImage: "chart.xyaxis.line",
                                       description: Text("Un check-in, une envie ou un épisode suffit pour commencer. Aucune journée sans saisie n'est déduite comme réussie."))
            }
            dayOverview(stats)
            if !stats.urges.isEmpty {
                urgeOverview(stats)
                strategyOverview(stats)
            }
            if !stats.emotions.isEmpty {
                emotionOverview(stats)
                HeatmapView(cells: stats.heatmap)
            }
            QuitCard {
                Text("Revenir à mon plan").font(.headline)
                if let hours = stats.averageRecoveryHours {
                    Text("\(hours.formatted(.number.precision(.fractionLength(1)))) h en moyenne")
                        .font(.title2.weight(.medium))
                    Text("Sur \(stats.episodes.filter { $0.recoveredAt != nil }.count) retours explicitement renseignés.")
                        .font(.footnote).foregroundStyle(QuitTheme.secondary)
                } else {
                    Text("Après un épisode, note le moment où tu reprends ton plan. Ce progrès compte aussi.")
                        .foregroundStyle(QuitTheme.secondary)
                }
                NavigationLink { JournalView() } label: { Label("Mon journal", systemImage: "book.closed").frame(minHeight: 44) }
            }
        }.navigationTitle("Comprendre")
    }

    private func dayOverview(_ stats: ProgressSnapshot) -> some View {
        QuitCard(tinted: true) {
            Text("\(stats.alignedDays)").font(.system(size: 52, weight: .medium, design: .rounded))
            Text("Journées alignées avec ton objectif").font(.headline)
            Text("\(stats.observedDays) jours au bilan renseigné · \(stats.unknownDays) sans bilan")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 10), spacing: 6) {
                ForEach(stats.days) { day in
                    RoundedRectangle(cornerRadius: 4).fill(dayColor(day.state)).frame(height: 19)
                        .overlay { if day.state == .episode { Image(systemName: "circle").font(.system(size: 8)).foregroundStyle(QuitTheme.text) } }
                        .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted) + ": " + dayLabel(day.state))
                }
            }
            HStack {
                legend("Aligné", color: QuitTheme.accent)
                legend("Épisode", color: QuitTheme.amber)
                legend("Sans bilan", color: QuitTheme.border)
            }.font(.caption)
            Text("\(stats.episodeCount) épisodes détaillés · \(stats.episodeDays) jours avec écart ou objectif non atteint")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }
    }

    private func urgeOverview(_ stats: ProgressSnapshot) -> some View {
        QuitCard {
            Text("\(stats.passedUrges) envies traversées").font(.title2.weight(.medium))
            Text("Sur \(stats.urges.count) sessions enregistrées. Les sessions encore en cours ne comptent pas comme traversées.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
            Chart(Array(stats.urges.suffix(30))) { session in
                LineMark(x: .value("Date", session.date), y: .value("Intensité", session.initial), series: .value("Mesure", "Avant"))
                    .foregroundStyle(by: .value("Mesure", "Avant"))
                LineMark(x: .value("Date", session.date), y: .value("Intensité", session.final), series: .value("Mesure", "Après"))
                    .foregroundStyle(by: .value("Mesure", "Après"))
                PointMark(x: .value("Date", session.date), y: .value("Intensité", session.final))
                    .foregroundStyle(QuitTheme.accent)
            }
            .chartYScale(domain: 0...10)
            .chartForegroundStyleScale(["Avant": QuitTheme.amber, "Après": QuitTheme.accent])
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) { AxisValueLabel(format: .dateTime.day().month()) } }
            .frame(height: 170)
            .accessibilityLabel("Intensité des 30 dernières envies, avant et après une action")
            if let reduction = stats.averageReduction {
                Text("Variation moyenne : \((-reduction).formatted(.number.precision(.fractionLength(1)))) points après une action.")
                    .font(.footnote).foregroundStyle(QuitTheme.secondary)
            }
        }
    }

    private func strategyOverview(_ stats: ProgressSnapshot) -> some View {
        QuitCard {
            Text("Ce qui semble t'aider").font(.headline)
            ForEach(stats.strategies) { result in
                VStack(alignment: .leading, spacing: 5) {
                    Label(result.strategy.title, systemImage: result.strategy.symbol).font(.subheadline.weight(.medium))
                    Text("\(result.count) observations · variation \((-result.reduction).formatted(.number.precision(.fractionLength(1)))) points")
                        .font(.footnote).foregroundStyle(QuitTheme.secondary)
                    if result.count < 3 { Text("Encore peu d'observations").font(.caption).foregroundStyle(QuitTheme.secondary) }
                }
            }
            Text("Associations descriptives : elles ne prouvent pas qu'une action cause la baisse de l'envie.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }
    }

    private func emotionOverview(_ stats: ProgressSnapshot) -> some View {
        QuitCard {
            Text("Ce que tu ressentais").font(.headline)
            ForEach(stats.emotions.prefix(4), id: \.emotion) { item in
                HStack {
                    Label(item.emotion.title, systemImage: item.emotion.symbol)
                    Spacer()
                    Text("\(item.count) signaux").foregroundStyle(QuitTheme.secondary)
                }.font(.subheadline)
            }
            Text("Envies et épisodes enregistrés. Un même moment peut donner lieu à deux signaux.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }
    }

    private func dayColor(_ state: DayRecord.State) -> Color {
        switch state { case .aligned: QuitTheme.accent; case .episode: QuitTheme.amber.opacity(0.5); case .unknown: QuitTheme.border }
    }
    private func dayLabel(_ state: DayRecord.State) -> String {
        switch state { case .aligned: "Aligné"; case .episode: "Écart ou objectif non atteint"; case .unknown: "Sans bilan" }
    }
    private func legend(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) { Circle().fill(color).frame(width: 7, height: 7); Text(title) }
    }
}

struct HeatmapView: View {
    let cells: [HeatCell]
    private let weekdays = [2, 3, 4, 5, 6, 7, 1]
    private let labels = ["L", "M", "M", "J", "V", "S", "D"]
    private let buckets = ["Matin", "Après-midi", "Soir", "Nuit"]
    var body: some View {
        QuitCard {
            Text("Mes moments sensibles").font(.headline)
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
                            RoundedRectangle(cornerRadius: 5)
                                .fill(count == 0 ? QuitTheme.accentSoft : QuitTheme.accent.opacity(min(1, 0.25 + Double(count) * 0.15)))
                                .frame(minWidth: 16, maxWidth: .infinity, minHeight: 22)
                                .accessibilityLabel("\(Calendar.current.weekdaySymbols[weekday - 1]), \(buckets[bucket]) : \(count) signaux")
                        }
                    }
                }
            }
            Text("Plus la teinte est foncée, plus tu as enregistré de signaux. Matin 6–12 h, après-midi 12–18 h, soir 18–24 h, nuit 0–6 h. Ce n'est pas une prédiction de risque.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }
    }
}
