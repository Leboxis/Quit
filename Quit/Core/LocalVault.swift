import Foundation

struct LocalVault {
    let directory: URL
    var url: URL { directory.appendingPathComponent("quit-v1.json") }

    init(directory: URL? = nil) {
        self.directory = directory ?? URL.applicationSupportDirectory.appendingPathComponent("Quit", isDirectory: true)
    }

    func load() throws -> QuitData? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let bytes = try Data(contentsOf: url)
        guard bytes.count <= 10 * 1024 * 1024 else { throw DataError.tooLarge }
        let data = try JSONDecoder().decode(QuitData.self, from: bytes)
        try data.validate()
        return data
    }

    func save(_ data: QuitData) throws {
        try data.validate()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.protectionKey: FileProtectionType.complete])
        var protectedDirectory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try protectedDirectory.setResourceValues(values)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let bytes = try encoder.encode(data)
        guard bytes.count <= 10 * 1024 * 1024 else { throw DataError.tooLarge }
        try bytes.write(to: url, options: [.atomic, .completeFileProtection])
    }
}
