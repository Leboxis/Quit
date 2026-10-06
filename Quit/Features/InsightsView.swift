import Charts
import SwiftUI

struct InsightsView: View {
    @Environment(\.quitAccent) private var accent
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var body: some View {
        let stats = ProgressSnapshot(data: store.data)
        ScreenContent {
            Text("Tes repères sur les 30 derniers jours, à partir de tes saisies.")
                .font(.subheadline).foregroundStyle(QuitTheme.secondary)
            if stats.observedDays == 0 && stats.urges.isEmpty && stats.episodes.isEmpty {
                ContentUnavailableView("Tes repères se construisent", systemImage: "chart.xyaxis.line",
                                       description: Text("Un check-in, une envie ou un épisode suffit pour commencer. Aucune journée sans saisie n'est déduite comme réussie."))
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
                QuitSectionTitle(title: "Mon journal", symbol: "book.closed", tone: .reflection)
                if let hours = stats.averageRecoveryHours {
                    Text("\(hours.formatted(.number.precision(.fractionLength(1)))) h en moyenne")
                        .font(.title2.weight(.medium))
                    Text("Pour revenir à ton plan, sur \(stats.episodes.filter { $0.recoveredAt != nil }.count) retours renseignés.")
                        .font(.footnote).foregroundStyle(QuitTheme.secondary)
                } else {
                    Text("Après un épisode, note le moment où tu reprends ton plan. Ce progrès compte aussi.")
                        .foregroundStyle(QuitTheme.secondary)
                }
                NavigationLink { JournalView() } label: {
                    QuietRow(title: "Ouvrir mon journal", detail: "Check-ins, envies et épisodes", symbol: "book.closed", tone: .reflection)
                }.buttonStyle(.plain)
                    .accessibilityIdentifier("journal.open")
            }
        }.navigationTitle("Comprendre")
    }

    private func dayOverview(_ stats: ProgressSnapshot) -> some View {
        QuitCard(tinted: true) {
            QuitSectionTitle(title: "Mes journées", symbol: "calendar")
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 20))
            layout {
                dayMetric(stats.alignedDays, title: "Alignées", color: accent.color)
                dayMetric(stats.observedDays, title: "Bilans", color: QuitTheme.text)
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
                legend("Aligné", color: accent.color, symbol: "checkmark")
                legend("Épisode", color: QuitTheme.amber, symbol: "circle")
                legend("Sans bilan", color: QuitTheme.border, symbol: nil)
            }.font(.caption)
            Text("\(stats.episodeCount) épisodes détaillés · \(stats.episodeDays) jours avec écart ou objectif non atteint")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }
    }

    private func urgeOverview(_ stats: ProgressSnapshot) -> some View {
        QuitCard {
            QuitSectionTitle(title: "Mes envies", symbol: "water.waves", tone: .reflection)
            Text("\(stats.passedUrges) envies traversées").font(.title2.weight(.medium))
            Text("Sur \(stats.urges.count) \(stats.urges.count == 1 ? "session enregistrée" : "sessions enregistrées"). Les sessions encore en cours ne comptent pas comme traversées.")
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
        VStack(alignment: .leading, spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
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
        switch state { case .aligned: accent.color; case .episode: QuitTheme.amber; case .unknown: QuitTheme.border }
    }
    private func dayLabel(_ state: DayRecord.State) -> String {
        switch state { case .aligned: "Aligné"; case .episode: "Écart ou objectif non atteint"; case .unknown: "Sans bilan" }
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
    private let buckets = ["Matin", "Après-midi", "Soir", "Nuit"]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mes moments sensibles").font(.headline)
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
            Text("Chaque nombre indique les signaux enregistrés ; un tiret indique aucune saisie. Matin 6–12 h, après-midi 12–18 h, soir 18–24 h, nuit 0–6 h. Ce n'est pas une prédiction de risque.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }
    }
}
