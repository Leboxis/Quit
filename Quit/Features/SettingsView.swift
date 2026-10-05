import LocalAuthentication
import SwiftUI
import UniformTypeIdentifiers

struct QuitBackup: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var bytes: Data
    init(bytes: Data) { self.bytes = bytes }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, data.count <= 10 * 1024 * 1024 else { throw DataError.tooLarge }
        bytes = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: bytes) }
}

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var importURL: URL?
    @State private var confirmImport = false
    @State private var confirmErase = false
    @State private var backup = QuitBackup(bytes: Data())
    @State private var name = ""
    @State private var intention = ""
    @State private var goal: Goal = .stop
    @State private var reminderDate = Date()
    @State private var busy = false
    @State private var notice: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Mon parcours") {
                    TextField("Prénom ou pseudonyme", text: $name)
                        .onChange(of: name) { _, value in name = String(value.prefix(100)) }
                    TextField("Mon intention", text: $intention, axis: .vertical).lineLimit(2...4)
                        .onChange(of: intention) { _, value in intention = String(value.prefix(2000)) }
                    Picker("Objectif", selection: $goal) { ForEach(Goal.allCases) { Text($0.title).tag($0) } }
                    Button("Enregistrer mon intention") {
                        if store.update({ $0.profile.name = name; $0.profile.intention = intention; $0.profile.goal = goal }) { notice = "Ton intention est conservée." }
                    }
                }
                Section {
                    Toggle("Verrouiller à l'ouverture", isOn: Binding(get: { store.data.profile.biometricLock }, set: { value in
                        Task { await setLock(value) }
                    })).disabled(busy)
                    Label("Données sur cet appareil", systemImage: "lock.shield")
                    Text("Pas de serveur, publicité ni analytics. Le fichier est protégé par iOS et exclu des sauvegardes système. Crée une sauvegarde volontaire avant de supprimer ou de changer de conteneur.")
                        .font(.footnote).foregroundStyle(QuitTheme.secondary)
                } header: { Text("Confidentialité") } footer: {
                    Text("Le verrouillage utilise Face ID, Touch ID ou le code de l'appareil. Sa disponibilité dépend aussi de ton installation.")
                }
                Section {
                    DatePicker("Heure", selection: $reminderDate, displayedComponents: .hourAndMinute)
                    Button(store.data.profile.reminderEnabled ? "Actualiser le rappel" : "Activer un rappel discret") { Task { await configureReminder() } }
                        .disabled(busy)
                    if store.data.profile.reminderEnabled {
                        Button("Désactiver le rappel") {
                            if store.update({ $0.profile.reminderEnabled = false }) { ReminderService.cancel() }
                        }
                    }
                } header: { Text("Rappel facultatif") } footer: {
                    Text("« Petit check-in · Un instant pour toi. » Aucun terme sensible. Les notifications peuvent être indisponibles dans LiveContainer.")
                }
                Section {
                    Button("Exporter ma sauvegarde JSON") {
                        do { backup = QuitBackup(bytes: try store.exportData()); showExporter = true }
                        catch { notice = error.localizedDescription }
                    }
                    Button("Importer une sauvegarde JSON") { showImporter = true }
                    Button("Effacer toutes mes données", role: .destructive) { confirmErase = true }
                } header: { Text("Mes données") } footer: {
                    Text("L'export contient tes données personnelles en clair. Choisis un emplacement privé. L'import remplace le contenu actuel après confirmation.")
                }
                Section("À propos") {
                    NavigationLink("Sources et limites") { EvidenceView() }
                    Link("Code source de Quit", destination: URL(string: "https://github.com/Leboxis/Quit")!)
                    Link("Mises à jour", destination: URL(string: "https://github.com/Leboxis/Quit/releases")!)
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"))")
                        .foregroundStyle(QuitTheme.secondary)
                }
            }
            .scrollContentBackground(.hidden).background(QuitTheme.background)
            .navigationTitle("Réglages").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Terminé") { dismiss() } } }
            .onAppear {
                name = store.data.profile.name
                intention = store.data.profile.intention
                goal = store.data.profile.goal
                reminderDate = Calendar.current.date(bySettingHour: store.data.profile.reminderHour,
                                                       minute: store.data.profile.reminderMinute, second: 0, of: Date()) ?? Date()
            }
            .fileExporter(isPresented: $showExporter, document: backup, contentType: .json, defaultFilename: "Quit-sauvegarde") { result in
                if case .failure(let error) = result { notice = error.localizedDescription }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls): importURL = urls.first; confirmImport = importURL != nil
                case .failure(let error): notice = error.localizedDescription
                }
            }
            .confirmationDialog("Remplacer les données actuelles ?", isPresented: $confirmImport, titleVisibility: .visible) {
                Button("Importer et remplacer", role: .destructive) { importBackup() }
                Button("Annuler", role: .cancel) { importURL = nil }
            } message: { Text("Exporte d'abord une sauvegarde si tu veux conserver les données actuelles.") }
            .confirmationDialog("Effacer toutes les données de Quit ?", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("Tout effacer", role: .destructive) {
                    do { try store.eraseEverything(); ReminderService.cancel(); dismiss() }
                    catch { notice = error.localizedDescription }
                }
                Button("Annuler", role: .cancel) { }
            } message: { Text("L'intention, le journal, les plans et les réflexions seront supprimés de cet appareil.") }
            .alert("Quit", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("Compris") { notice = nil }
            } message: { Text(notice ?? "") }
        }
    }

    private func setLock(_ enabled: Bool) async {
        busy = true
        defer { busy = false }
        do {
            let context = LAContext()
            if try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Modifier la confidentialité de Quit") {
                store.update { $0.profile.biometricLock = enabled }
            }
        } catch { notice = "Le verrouillage n'a pas été modifié. " + error.localizedDescription }
    }

    private func configureReminder() async {
        busy = true
        defer { busy = false }
        let hour = Calendar.current.component(.hour, from: reminderDate)
        let minute = Calendar.current.component(.minute, from: reminderDate)
        do {
            if try await ReminderService.configure(hour: hour, minute: minute) {
                if !store.update({ $0.profile.reminderEnabled = true; $0.profile.reminderHour = hour; $0.profile.reminderMinute = minute }) { ReminderService.cancel() }
                else { notice = "Le rappel discret est activé." }
            } else { notice = "Notifications non autorisées. Tu peux les activer dans les réglages iOS si cette installation le permet." }
        } catch { notice = "Rappel indisponible. " + error.localizedDescription }
    }

    private func importBackup() {
        guard let url = importURL else { return }
        do {
            try readBackup(from: url, into: store)
            ReminderService.cancel()
            name = store.data.profile.name; intention = store.data.profile.intention; goal = store.data.profile.goal
            notice = "Sauvegarde importée. Réactive ton rappel si tu le souhaites."
        } catch { notice = "L'import n'a pas été effectué. " + error.localizedDescription }
        importURL = nil
    }
}

@MainActor
func readBackup(from url: URL, into store: AppStore) throws {
    let access = url.startAccessingSecurityScopedResource()
    defer { if access { url.stopAccessingSecurityScopedResource() } }
    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    guard size <= 10 * 1024 * 1024 else { throw DataError.tooLarge }
    try store.importData(Data(contentsOf: url))
}

struct StorageRecoveryView: View {
    let message: String
    @Environment(AppStore.self) private var store
    @State private var showImport = false
    @State private var showErase = false
    @State private var notice: String?
    var body: some View {
        NavigationStack {
            ScreenContent {
                ContentUnavailableView("Ta sauvegarde est conservée", systemImage: "lock.doc", description: Text(message))
                QuitPrimaryButton(title: "Réessayer") { store.reload() }
                Button("Restaurer depuis une sauvegarde JSON") { showImport = true }.frame(minHeight: 44)
                Button("Effacer et recommencer", role: .destructive) { showErase = true }.frame(minHeight: 44)
            }
            .fileImporter(isPresented: $showImport, allowedContentTypes: [.json]) { result in
                do { try readBackup(from: result.get(), into: store) }
                catch { notice = error.localizedDescription }
            }
            .confirmationDialog("Effacer la sauvegarde inaccessible ?", isPresented: $showErase, titleVisibility: .visible) {
                Button("Effacer définitivement", role: .destructive) {
                    do { try store.eraseEverything() } catch { notice = error.localizedDescription }
                }
            }
            .alert("Quit", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("Compris") { notice = nil }
            } message: { Text(notice ?? "") }
        }
    }
}
