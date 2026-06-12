import Foundation

/// Хранилище Истории матчей: один JSON-файл на матч в каталоге `history/`.
///
/// Имя файла — таймштамп `endedAt` (zero-padded) + `id`: сортировка по имени без чтения содержимого,
/// уникальность по матчу. Коммит идемпотентен по `id` (старые файлы того же матча удаляются),
/// так что повторный коммит (например, дозапись сводки) не плодит дублей.
/// См. ADR `docs/adr/0001-match-history-storage.md`.
struct HistoryStore {
    static let shared = HistoryStore()

    private let dir: URL

    init() {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dir = base.appendingPathComponent("history", isDirectory: true)
    }

    /// Записать матч в Историю (создать или перезаписать запись с тем же `id`).
    func commit(_ record: MatchRecord) {
        ensureDir()
        removeFiles(withID: record.id)
        let url = dir.appendingPathComponent(fileName(for: record))
        do {
            let data = try JSONEncoder().encode(record)
            try data.write(to: url, options: .atomic)
        } catch {
            // Персистентность — не критичный путь; не роняем приложение из-за ошибки записи.
            print("HistoryStore commit error: \(error)")
        }
    }

    /// Все записи, новые сверху.
    func list() -> [MatchRecord] {
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? Data(contentsOf: $0) }
            .compactMap { try? JSONDecoder().decode(MatchRecord.self, from: $0) }
            .sorted { $0.sortDate > $1.sortDate }
    }

    /// Удалить запись по матчу.
    func delete(_ record: MatchRecord) {
        removeFiles(withID: record.id)
    }

    // MARK: - Приватное

    private func ensureDir() {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private func fileName(for record: MatchRecord) -> String {
        // 12 цифр секунд эпохи хватает до ~33000 года; нулевой паддинг → лексикографическая сортировка = хронологическая.
        let ts = Int(record.sortDate.timeIntervalSince1970)
        return String(format: "%012d-%@.json", ts, record.id.uuidString)
    }

    private func removeFiles(withID id: UUID) {
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent.contains(id.uuidString) {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
