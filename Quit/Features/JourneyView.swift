import SwiftUI

struct JourneyView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScreenContent {
            let reco = JourneyCatalog.recommendation(for: store.data)
            NavigationLink { JourneyPathView(path: reco.path) } label: {
                QuitCard(tinted: true) {
                    QuietRow(title: "Pour toi : \(reco.path.title)", detail: reco.reason, symbol: "sparkles",
                             tone: reco.path.id == "urges" ? .reflection : .preparation)
                }
            }.buttonStyle(.plain).accessibilityIdentifier("journey.recommended")
            ForEach(JourneyCatalog.paths) { path in
                NavigationLink { JourneyPathView(path: path) } label: {
                    QuitCard {
                        QuietRow(title: path.title, detail: path.subtitle, symbol: path.symbol,
                                 tone: path.isFullCourse ? nil : path.id == "urges" ? .reflection : .preparation)
                        HStack {
                            Text("\(path.completedCount(in: store.data.completedLessons)) / \(path.lessonIDs.count) étapes terminées")
                                .font(.caption).foregroundStyle(QuitTheme.secondary)
                            Spacer(minLength: 0)
                        }
                        ProgressView(value: Double(path.completedCount(in: store.data.completedLessons)), total: Double(path.lessonIDs.count))
                            .accessibilityLabel("Progression de \(path.title)")
                    }
                }.buttonStyle(.plain).accessibilityIdentifier("journey.path.\(path.id)")
            }
        }.navigationTitle("Parcours")
    }
}

struct JourneyPathView: View {
    let path: JourneyPath
    @Environment(\.quitAccent) private var accent
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var weekNumberWidth = 30.0
    var body: some View {
        ScreenContent {
            Text(path.overview)
                .font(.subheadline).foregroundStyle(QuitTheme.secondary)
            if path.lessons.count != path.lessonIDs.count {
                ContentUnavailableView("Exercices indisponibles", systemImage: "book.closed", description: Text("Les contenus n'ont pas pu être chargés. Réinstalle la dernière version sans supprimer tes données."))
            } else {
                QuitCard(tinted: true) {
                    let layout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                        : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
                    layout {
                        Text("\(path.completedCount(in: store.data.completedLessons)) / \(path.lessonIDs.count)")
                            .font(.system(.title, design: .rounded, weight: .medium)).monospacedDigit()
                        Text("Étapes terminées").font(.subheadline).foregroundStyle(QuitTheme.secondary)
                    }
                    ProgressView(value: Double(path.completedCount(in: store.data.completedLessons)), total: Double(path.lessonIDs.count)).tint(accent.color)
                        .accessibilityLabel("Étapes terminées")
                    if let next = path.nextLesson(in: store.data.completedLessons) {
                        NavigationLink {
                            LessonView(lesson: next, stepTitle: path.isFullCourse ? nil : "Étape \((path.lessonIDs.firstIndex(of: next.id) ?? 0) + 1) / \(path.lessonIDs.count)")
                        } label: {
                            QuietRow(title: "Continuer mon parcours", detail: next.title, symbol: "play.fill")
                        }.buttonStyle(.plain).accessibilityIdentifier("journey.continue")
                    } else {
                        Label("Parcours terminé", systemImage: "checkmark.circle").font(.headline)
                    }
                }
                if path.isFullCourse {
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
                } else {
                    QuitCard {
                        QuitSectionTitle(title: "Les étapes", symbol: "list.bullet")
                        ForEach(path.lessons) { lesson in
                            if lesson.id != path.lessonIDs.first { Divider() }
                            NavigationLink { LessonView(lesson: lesson, stepTitle: "Étape \((path.lessonIDs.firstIndex(of: lesson.id) ?? 0) + 1) / \(path.lessonIDs.count)") } label: {
                                QuietRow(title: lesson.title, detail: "Étape \((path.lessonIDs.firstIndex(of: lesson.id) ?? 0) + 1) · 2 à 5 min",
                                         symbol: store.data.completedLessons.contains(lesson.id) ? "checkmark.circle" : "circle")
                            }.buttonStyle(.plain).accessibilityIdentifier("journey.lesson.\(lesson.id)")
                        }
                    }
                }
            }
            Text("Les parcours partagent les mêmes exercices : une étape terminée reste acquise dans chacun.")
                .font(.footnote).foregroundStyle(QuitTheme.secondary)
            NavigationLink("Sources et limites") { EvidenceView() }.font(.footnote).frame(minHeight: 44)
        }.navigationTitle(path.title).navigationBarTitleDisplayMode(.inline)
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
    var stepTitle: String? = nil
    @Environment(AppStore.self) private var store
    @State private var reflection = ""
    @State private var saved = false
    var body: some View {
        ScreenContent {
            Text("\(stepTitle ?? "SEMAINE \(lesson.week)") · 2 À 5 MIN").font(.caption).tracking(1.5).foregroundStyle(QuitTheme.secondary)
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
        .navigationTitle(stepTitle ?? "Exercice \(lesson.id)").navigationBarTitleDisplayMode(.inline)
        .onAppear { reflection = store.data.reflections[String(lesson.id)] ?? "" }
    }
}
