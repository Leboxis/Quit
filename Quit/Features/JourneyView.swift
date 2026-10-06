import SwiftUI

struct JourneyView: View {
    @Environment(\.quitAccent) private var accent
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var weekNumberWidth = 30.0
    var body: some View {
        ScreenContent {
            Text("Six semaines de petits gestes. Avance à ton rythme, sans obligation quotidienne.")
                .font(.subheadline).foregroundStyle(QuitTheme.secondary)
            if LessonCatalog.lessons.isEmpty {
                ContentUnavailableView("Exercices indisponibles", systemImage: "book.closed", description: Text("Les contenus n'ont pas pu être chargés. Réinstalle la dernière version sans supprimer tes données."))
            } else {
                QuitCard(tinted: true) {
                    let layout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                        : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
                    layout {
                        Text("\(store.data.completedLessons.count) / 42")
                            .font(.system(.title, design: .rounded, weight: .medium)).monospacedDigit()
                        Text("Exercices explorés").font(.subheadline).foregroundStyle(QuitTheme.secondary)
                    }
                    ProgressView(value: Double(store.data.completedLessons.count), total: 42).tint(accent.color)
                        .accessibilityLabel("Exercices explorés")
                    if let next = LessonCatalog.lessons.first(where: { !store.data.completedLessons.contains($0.id) }) {
                        NavigationLink { LessonView(lesson: next) } label: {
                            QuietRow(title: "Continuer mon parcours", detail: next.title, symbol: "play.fill")
                        }.buttonStyle(.plain)
                    }
                }
                QuitCard {
                    QuitSectionTitle(title: "Les six semaines", symbol: "leaf")
                    ForEach(1...6, id: \.self) { week in
                        if week > 1 { Divider() }
                        NavigationLink {
                            WeekView(week: week)
                        } label: {
                            HStack(alignment: .top) {
                                Text(String(format: "%02d", week))
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(accent.color).frame(width: weekNumberWidth).frame(minHeight: 44)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LessonCatalog.weekTitles[week - 1]).font(.headline)
                                    Text("\(completed(week)) / 7 exercices · 2 à 5 min").font(.caption).foregroundStyle(QuitTheme.secondary)
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                                Image(systemName: completed(week) == 7 ? "checkmark.circle.fill" : "chevron.right")
                                    .font(.caption).foregroundStyle(accent.color).accessibilityHidden(true)
                            }
                            .frame(minHeight: 44).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }
            }
            Text("Des exercices inspirés de l'ACT, des TCC et de la prévention des rechutes. Ce programme autonome n'est pas un protocole de soin validé.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
        }.navigationTitle("Parcours")
    }
    private func completed(_ week: Int) -> Int {
        LessonCatalog.lessons.filter { $0.week == week && store.data.completedLessons.contains($0.id) }.count
    }
}

struct WeekView: View {
    let week: Int
    @Environment(AppStore.self) private var store
    var body: some View {
        ScreenContent {
            Text(LessonCatalog.weekDescriptions[week - 1]).foregroundStyle(QuitTheme.secondary)
            QuitCard {
                ForEach(LessonCatalog.lessons.filter { $0.week == week }) { lesson in
                    if lesson.id != (week - 1) * 7 + 1 { Divider() }
                    NavigationLink { LessonView(lesson: lesson) } label: {
                        QuietRow(title: lesson.title, detail: "Exercice \((lesson.id - 1) % 7 + 1) · 2 à 5 min",
                                 symbol: store.data.completedLessons.contains(lesson.id) ? "checkmark.circle" : "circle")
                    }.buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Semaine \(week)").navigationBarTitleDisplayMode(.inline)
    }
}

struct LessonView: View {
    let lesson: Lesson
    @Environment(AppStore.self) private var store
    @State private var reflection = ""
    @State private var saved = false
    var body: some View {
        ScreenContent {
            Text("SEMAINE \(lesson.week) · 2 À 5 MIN").font(.caption).tracking(1.5).foregroundStyle(QuitTheme.secondary)
            Text(lesson.title).font(.largeTitle.weight(.semibold))
            Text(lesson.body).font(.body).lineSpacing(5)
            QuitCard(tinted: true) {
                Text("Essaie maintenant").font(.headline)
                Text(lesson.action)
            }
            QuitCard {
                Text(lesson.prompt).font(.headline)
                TextField("Ma réflexion (facultative)", text: $reflection, axis: .vertical)
                    .lineLimit(4...10).accessibilityIdentifier("lesson.reflection")
                    .onChange(of: reflection) { _, value in reflection = String(value.prefix(5000)); saved = false }
            }
            QuitPrimaryButton(title: saved ? "Réflexion conservée" : "Garder cette réflexion", symbol: saved ? "checkmark" : "leaf") {
                saved = store.update {
                    $0.completedLessons.insert(lesson.id)
                    $0.reflections[String(lesson.id)] = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }.accessibilityIdentifier("lesson.save")
            NavigationLink("Sources et limites") { EvidenceView() }.font(.footnote).frame(minHeight: 44)
        }
        .navigationTitle("Exercice \(lesson.id)").navigationBarTitleDisplayMode(.inline)
        .onAppear { reflection = store.data.reflections[String(lesson.id)] ?? "" }
    }
}
