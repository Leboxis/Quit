import SwiftUI

struct JourneyView: View {
    @Environment(\.quitAccent) private var accent
    @Environment(AppStore.self) private var store
    var body: some View {
        ScreenContent {
            Text("Six semaines de petits gestes. Avance à ton rythme, sans obligation quotidienne.")
                .foregroundStyle(QuitTheme.secondary)
            if LessonCatalog.lessons.isEmpty {
                ContentUnavailableView("Exercices indisponibles", systemImage: "book.closed", description: Text("Les contenus n'ont pas pu être chargés. Réinstalle la dernière version sans supprimer tes données."))
            } else {
                QuitCard(tinted: true) {
                    Text("\(store.data.completedLessons.count) / 42").font(.system(.largeTitle, design: .rounded))
                    Text("Exercices explorés").foregroundStyle(QuitTheme.secondary)
                    ProgressView(value: Double(store.data.completedLessons.count), total: 42).tint(accent.color)
                }
                ForEach(1...6, id: \.self) { week in
                    NavigationLink {
                        WeekView(week: week)
                    } label: {
                        QuitCard {
                            HStack(alignment: .top) {
                                Text(String(format: "%02d", week)).font(.system(.title2, design: .rounded)).foregroundStyle(accent.color)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(LessonCatalog.weekTitles[week - 1]).font(.headline)
                                    Text(LessonCatalog.weekDescriptions[week - 1]).font(.subheadline).foregroundStyle(QuitTheme.secondary)
                                    Text("\(completed(week)) / 7 exercices · 2 à 5 min").font(.caption).foregroundStyle(QuitTheme.secondary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(QuitTheme.secondary)
                            }
                        }
                    }.buttonStyle(.plain)
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
            ForEach(LessonCatalog.lessons.filter { $0.week == week }) { lesson in
                NavigationLink { LessonView(lesson: lesson) } label: {
                    QuitCard {
                        QuietRow(title: lesson.title, detail: "Exercice \((lesson.id - 1) % 7 + 1) · 2 à 5 min",
                                 symbol: store.data.completedLessons.contains(lesson.id) ? "checkmark.circle" : "circle")
                    }
                }.buttonStyle(.plain)
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
            ContourArtwork().frame(height: 90)
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
